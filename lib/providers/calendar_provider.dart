// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n.dart';
import '../core/crypto/item_cipher.dart';
import '../models/calendar_model.dart';
import '../utils/holiday_names.dart';
import '../utils/italian_holidays.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'crypto_provider.dart';
import 'reminders_actions.dart';
import 'settings/locale_provider.dart';
import 'settings/ui_provider.dart';
import 'shared_items.dart';
import 'sync_provider.dart';
import 'tasks_provider.dart';

// ─── Calendar Notifier ────────────────────────────────────────────────────────

/// Calendar events of the signed-in user; same lifecycle as
/// `NotesNotifier`, including the events shared with this user (see
/// [SharedItems]).
class CalendarNotifier extends Notifier<List<CalendarEventModel>>
    with
        FirestoreListMutations<CalendarEventModel>,
        SharedItems<CalendarEventModel> {
  late String _uid;

  /// Completes with `true` once the first fetch for the current user has
  /// succeeded, `false` if it failed or nobody is signed in. Recreated on
  /// every user change; used to resync reminders after sign-in.
  Future<bool> get initialLoad => _initialLoad.future;
  Completer<bool> _initialLoad = Completer<bool>();

  /// Completes once the cached events of the current user are in the state
  /// (or there is nothing to wait for). Recreated on every user change.
  Future<void> get cacheSeeded => _cacheSeeded.future;
  Completer<void> _cacheSeeded = Completer<void>();

  void _markCacheSeeded() {
    if (!_cacheSeeded.isCompleted) _cacheSeeded.complete();
  }

  @override
  List<CalendarEventModel> build() {
    // Nothing loads until the keys are unlocked: as if signed out.
    _cipher = ref.watch(itemCipherProvider);
    _uid = _cipher == null ? '' : ref.watch(currentUidProvider);
    ref.watch(firestoreProvider);
    _initialLoad = Completer<bool>();
    _cacheSeeded = Completer<void>();
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      cancelSharedListeners();
    });
    _load().ignore();
    return [];
  }

  bool _disposed = false;

  @override
  String get sharingUid => _uid;

  @override
  String get sharedCollection => 'calendar_events';

  @override
  String get sharedPrefsCollection => 'shared_event_prefs';

  @override
  bool get sharingDisposed => _disposed;

  @override
  CalendarEventModel sharedFromJson(Map<String, dynamic> json) =>
      CalendarEventModel.fromJson(json);

  @override
  List<String> get privateKeys => const ['tags'];

  ItemCipher? _cipher;

  @override
  ItemCipher get cipher => _cipher!;

  CollectionReference<Map<String, dynamic>> get _col => ownCollection;

  /// Re-fetches all events from Firestore, replacing local state.
  @override
  Future<void> reload() => _load(replace: true);

  Future<void> _load({bool replace = false}) async {
    final uid = _uid;
    final ready = _initialLoad;
    if (uid.isEmpty) {
      if (!ready.isCompleted) ready.complete(false);
      _markCacheSeeded();
      return;
    }
    // A plain get() waits for the server even when the events are cached:
    // show the cached ones first so the calendar is not empty meanwhile.
    final seeded =
        replace
            ? const <String, CalendarEventModel>{}
            : await seedFromCache(
              _col,
              _parse,
              _id,
              () => uid != _uid || _disposed,
            );
    _markCacheSeeded();
    final sharedWithMe = loadSharedWithMe(uid);
    final QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _col.get();
    } catch (_) {
      if (!ready.isCompleted) ready.complete(false);
      rethrow;
    }
    final shared = await sharedWithMe;
    // The user changed (or the notifier was disposed) while this fetch was
    // in flight.
    if (uid != _uid || _disposed) {
      if (!ready.isCompleted) ready.complete(false);
      return;
    }
    final events = [...await parseDocs(snap.docs, _parse), ...shared];
    startSharedListeners(uid);
    if (replace) {
      state = events;
      return;
    }
    // Reconcile instead of replace: an event added or edited locally while
    // this initial fetch was in flight must not be wiped out by it.
    state = reconcileInitialLoad(events, seeded, _id);
    if (!ready.isCompleted) ready.complete(true);
    // Not awaited: offline the deletes stay queued.
    _purgeOldTrashFirestore().ignore();
    syncEncryption(snap.docs).ignore();
  }

  static String _id(CalendarEventModel e) => e.id;

  Future<CalendarEventModel?> _parse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = await decodeDoc(doc);
    return data == null ? null : CalendarEventModel.fromJson(data);
  }

  Future<void> _saveDoc(CalendarEventModel event) => saveItem(event);

  Future<void> _purgeOldTrashFirestore() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final expired =
        state
            .where((e) => e.deletedAt != null && e.deletedAt!.isBefore(cutoff))
            .toList();
    if (expired.isEmpty) return;
    await mutate(
      (current) =>
          current
              .where((e) => e.deletedAt == null || e.deletedAt!.isAfter(cutoff))
              .toList(),
      () => commitInChunks(
        expired.map((e) => (WriteBatch b) => removeItem(b, e)).toList(),
      ),
    );
  }

  void purgeOldTrash() {
    _purgeOldTrashFirestore();
  }

  Future<void> addEvent(CalendarEventModel event) =>
      mutate((current) => [event, ...current], () => _saveDoc(event));

  Future<void> updateEvent(CalendarEventModel updated) {
    final event = withCurrentSharing(updated);
    return mutate(
      (current) => current.map((e) => e.id == event.id ? event : e).toList(),
      () => _saveDoc(event),
    );
  }

  /// Removes the current user from the collaborators of [eventId], an event
  /// another user shared with them: it disappears from their calendar.
  Future<void> leaveEvent(String eventId) => permanentlyDelete(eventId);

  /// Keeps the alerts of [event] in line with its state: cancelled while it
  /// is in the trash or once [removed], rescheduled when restored
  /// (`scheduleEventAlerts` cancels first and skips trashed events). Not
  /// awaited by the callers: offline the Firestore write never completes,
  /// and the notifications must change right away.
  Future<void> _syncAlerts(
    CalendarEventModel event, {
    bool removed = false,
  }) async {
    if (kIsWeb) return;
    try {
      final notifications = ref.read(notificationServiceProvider);
      if (removed) {
        await notifications.cancelEventAlerts(event.id);
        return;
      }
      await notifications.scheduleEventAlerts(
        event,
        allDayMinutes: ref.read(defaultAlertTimeProvider),
        dayBeforeMinutes: ref.read(dayBeforeAlertTimeProvider),
        askPermission: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Event alerts sync failed: $e');
    }
  }

  /// Leaves the occurrence on [day] out of the recurring event [id] (the
  /// rest of the series stays) and reschedules its alerts.
  Future<void> excludeOccurrence(String id, DateTime day) {
    final updated = withCurrentSharing(
      state.firstWhere((e) => e.id == id).withoutOccurrence(day),
    );
    _syncAlerts(updated).ignore();
    return mutate(
      (current) => current.map((e) => e.id == id ? updated : e).toList(),
      () => _saveDoc(updated),
    );
  }

  /// Puts back [previous] (undo of [excludeOccurrence]) and reschedules its
  /// alerts.
  Future<void> restoreEvent(CalendarEventModel previous) {
    final event = withCurrentSharing(previous);
    _syncAlerts(event).ignore();
    return mutate(
      (current) => current.map((e) => e.id == event.id ? event : e).toList(),
      () => _saveDoc(event),
    );
  }

  Future<void> softDelete(String id) async {
    final updated = state
        .firstWhere((e) => e.id == id)
        .copyWith(deletedAt: DateTime.now(), isArchived: false);
    _syncAlerts(updated).ignore();
    await mutate(
      (current) => current.map((e) => e.id == id ? updated : e).toList(),
      () => _saveDoc(updated),
    );
  }

  /// Moves the events [ids] to the trash with one batched write (bulk
  /// delete from the calendar selection).
  Future<void> softDeleteMany(Set<String> ids) =>
      _setDeletedAt(ids, DateTime.now());

  /// Puts the events [ids] back from the trash (undo of [softDeleteMany]).
  Future<void> restoreManyFromTrash(Set<String> ids) =>
      _setDeletedAt(ids, null);

  Future<void> _setDeletedAt(Set<String> ids, DateTime? deletedAt) {
    final updated = [
      for (final e in state)
        if (ids.contains(e.id))
          withCurrentSharing(
            deletedAt == null
                ? e.copyWith(clearDeletedAt: true)
                : e.copyWith(deletedAt: deletedAt, isArchived: false),
          ),
    ];
    if (updated.isEmpty) return Future.value();
    for (final e in updated) {
      _syncAlerts(e).ignore();
    }
    final byId = {for (final e in updated) e.id: e};
    return mutate(
      (current) => [for (final e in current) byId[e.id] ?? e],
      () => commitInChunks([
        for (final e in updated) (WriteBatch b) => writeItem(b, e),
      ]),
    );
  }

  Future<void> restoreFromTrash(String id) async {
    final updated = state
        .firstWhere((e) => e.id == id)
        .copyWith(clearDeletedAt: true);
    _syncAlerts(updated).ignore();
    await mutate(
      (current) => current.map((e) => e.id == id ? updated : e).toList(),
      () => _saveDoc(updated),
    );
  }

  Future<void> permanentlyDelete(String id) {
    final event = itemById(id);
    if (event != null) _syncAlerts(event, removed: true).ignore();
    return mutate(
      (current) => current.where((e) => e.id != id).toList(),
      () => deleteItemDoc(id, event),
    );
  }

  Future<void> toggleArchive(String id) async {
    final updated = state
        .firstWhere((e) => e.id == id)
        .copyWith(isArchived: !state.firstWhere((e) => e.id == id).isArchived);
    await mutate(
      (current) => current.map((e) => e.id == id ? updated : e).toList(),
      () => _saveDoc(updated),
    );
  }

  Future<void> deleteEvent(String id) {
    final event = itemById(id);
    return mutate(
      (current) => current.where((e) => e.id != id).toList(),
      () => deleteItemDoc(id, event),
    );
  }

  /// Import events from an external source (e.g. ICS file), skipping
  /// events whose [id] already exists in the current state.
  Future<void> importEvents(List<CalendarEventModel> events) async {
    final existingIds = state.map((e) => e.id).toSet();
    // `add` also drops repeated ids within [events]: two writes to the same
    // document would keep only the last one.
    final newEvents = events.where((e) => existingIds.add(e.id)).toList();
    if (newEvents.isEmpty) return;
    await mutate(
      (current) => [...newEvents, ...current],
      () => commitInChunks(
        newEvents.map((e) => (WriteBatch b) => writeItem(b, e)).toList(),
      ),
    );
  }

  /// Permanently delete all own calendar events; those shared with this
  /// user stay (they belong to someone else).
  Future<void> clearAllEvents() {
    final ids = [
      for (final e in state)
        if (!e.isForeignTo(_uid)) e.id,
    ];
    return mutate(
      (current) => current.where((e) => e.isForeignTo(_uid)).toList(),
      () => commitInChunks(
        ids.map((id) => (WriteBatch b) => b.delete(_col.doc(id))).toList(),
      ),
    );
  }

  /// Replaces the entire calendar collection (used for full backup restore).
  /// Events missing from [events] are deleted from Firestore too, otherwise
  /// they would reappear on the next load.
  /// Saves several edited events at once (one batched write).
  Future<void> updateEvents(List<CalendarEventModel> updated) {
    if (updated.isEmpty) return Future.value();
    final events = updated.map(withCurrentSharing).toList();
    final byId = {for (final e in events) e.id: e};
    return mutate(
      (current) => [for (final e in current) byId[e.id] ?? e],
      () => commitInChunks([
        for (final e in events) (WriteBatch b) => writeItem(b, e),
      ]),
    );
  }

  /// The events shared with this user are left alone, and own events keep
  /// their collaborators (backups don't carry them).
  Future<void> replaceAll(List<CalendarEventModel> events) {
    final r = restoreKeepingShared(events);
    return mutate(
      (_) => r.state,
      () => commitInChunks([
        for (final id in r.stale) (WriteBatch b) => b.delete(_col.doc(id)),
        for (final e in r.restored) (WriteBatch b) => writeItem(b, e),
      ]),
    );
  }
}

/// The signed-in user's own events, without those shared with them: what
/// backups and exports contain.
final ownEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  return ownItems(ref.watch(calendarProvider), ref.watch(currentUidProvider));
});

final calendarProvider =
    NotifierProvider<CalendarNotifier, List<CalendarEventModel>>(
      CalendarNotifier.new,
    );

/// Every event by id, rebuilt once per change of [calendarProvider].
final eventsByIdProvider = Provider<Map<String, CalendarEventModel>>((ref) {
  return {for (final e in ref.watch(calendarProvider)) e.id: e};
});

final activeEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  final events = ref.watch(calendarProvider);
  return events.where((e) => !e.isArchived && e.deletedAt == null).toList();
});

final archivedEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  final events = ref.watch(calendarProvider);
  return events.where((e) => e.isArchived && e.deletedAt == null).toList();
});

final trashedEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  final events = ref.watch(calendarProvider);
  return events.where((e) => e.deletedAt != null).toList();
});

final calendarSearchQueryProvider = valueStateProvider<String>('');

enum CalendarViewMode { day, week, month, year, schedule, sevenDays }

/// The calendar view last picked, persisted on the device so it survives
/// section changes and app restarts.
class CalendarViewModeNotifier extends PersistedEnumNotifier<CalendarViewMode> {
  CalendarViewModeNotifier()
    : super(
        'calendar_view_mode',
        CalendarViewMode.values,
        CalendarViewMode.month,
      );
}

final calendarViewModeProvider =
    NotifierProvider<CalendarViewModeNotifier, CalendarViewMode>(
      CalendarViewModeNotifier.new,
    );

/// Whether tasks with a due date are shown in the calendar views (toggled
/// from the calendar app bar, persisted on the device).
final calendarShowTasksProvider = NotifierProvider<BoolSettingNotifier, bool>(
  () => BoolSettingNotifier('calendar_show_tasks', true),
);

/// Whether the Italian national holidays are shown in the calendar views
/// (Settings, on by default).
final calendarShowHolidaysProvider =
    NotifierProvider<BoolSettingNotifier, bool>(
      () => BoolSettingNotifier('calendar_show_holidays', true),
    );

/// Whether the observances (Festa della mamma, San Valentino…) are shown in
/// the calendar views (Settings, on by default).
final calendarShowObservancesProvider =
    NotifierProvider<BoolSettingNotifier, bool>(
      () => BoolSettingNotifier('calendar_show_observances', true),
    );

/// The holidays and observances switched on in Settings, as read-only
/// calendar entries named in the app language.
final calendarHolidayItemsProvider = Provider<List<CalendarEventModel>>((ref) {
  ref.watch(appLanguageProvider);
  final holidays = ref.watch(calendarShowHolidaysProvider);
  final observances = ref.watch(calendarShowObservancesProvider);
  final l10n = currentL10n();
  final year = DateTime.now().year;
  return [
    for (final h in ItalianHoliday.values)
      if (h.isPublic ? holidays : observances)
        HolidayCalendarEvent(h, title: holidayName(l10n, h), year: year),
  ];
});

/// Active tasks with a due date, as read-only calendar entries.
final calendarTaskItemsProvider = Provider<List<CalendarEventModel>>((ref) {
  return ref
      .watch(activeTasksProvider)
      .where(TaskCalendarEvent.isShown)
      .map(TaskCalendarEvent.new)
      .toList();
});

/// Done once the cached events are shown (see [CalendarNotifier.cacheSeeded]).
final calendarCacheSeededProvider = FutureProvider<void>((ref) {
  ref.watch(currentUidProvider);
  return ref.read(calendarProvider.notifier).cacheSeeded;
});

/// What the calendar views display: active events, the holidays switched on
/// and, when enabled, the tasks with a due date.
final calendarItemsProvider = Provider<List<CalendarEventModel>>((ref) {
  // Holidays are computed locally and the tasks' cache read is much smaller:
  // shown before the events, they appeared ahead of them (~0.8 s with 625
  // events), so the calendar filled in steps. Holding everything back until
  // the cached events are in makes it all appear together.
  if (!ref.watch(calendarCacheSeededProvider).hasValue) return const [];
  return [
    ...ref.watch(activeEventsProvider),
    ...ref.watch(calendarHolidayItemsProvider),
    if (ref.watch(calendarShowTasksProvider))
      ...ref.watch(calendarTaskItemsProvider),
  ];
});

final filteredCalendarEventsProvider = Provider<List<CalendarEventModel>>((
  ref,
) {
  final events = ref.watch(calendarItemsProvider);
  final query = ref.watch(calendarSearchQueryProvider);

  if (query.isEmpty) return events;

  return events
      .where(
        (e) =>
            e.title.toLowerCase().contains(query.toLowerCase()) ||
            e.description.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
});
