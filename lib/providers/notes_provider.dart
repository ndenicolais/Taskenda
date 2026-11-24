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
import '../core/crypto/item_cipher.dart';
import '../models/note_model.dart';
import '../utils/notification_service.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'crypto_provider.dart';
import 'reminders_actions.dart';
import 'shared_items.dart';
import 'sync_provider.dart';

// ─── Notes Notifier ───────────────────────────────────────────────────────────

/// Notes of the signed-in user ([currentUidProvider]), loaded once from
/// Firestore and then kept in memory with optimistic updates. Rebuilt (and
/// reloaded) when the user changes. The state also holds the notes shared
/// with this user, and shared notes are live (see [SharedItems]).
class NotesNotifier extends Notifier<List<NoteModel>>
    with FirestoreListMutations<NoteModel>, SharedItems<NoteModel> {
  late String _uid;

  /// Completes with `true` once the first fetch for the current user has
  /// succeeded, `false` if it failed or nobody is signed in. Recreated on
  /// every user change; used to resync reminders after sign-in.
  Future<bool> get initialLoad => _initialLoad.future;
  Completer<bool> _initialLoad = Completer<bool>();

  @override
  List<NoteModel> build() {
    // Nothing loads until the keys are unlocked: as if signed out.
    _cipher = ref.watch(itemCipherProvider);
    _uid = _cipher == null ? '' : ref.watch(currentUidProvider);
    ref.watch(firestoreProvider);
    _initialLoad = Completer<bool>();
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      cancelSharedListeners();
    });
    _load();
    return [];
  }

  /// Set when this build is torn down: a fetch still in flight must not
  /// touch `ref` any more.
  bool _disposed = false;

  @override
  String get sharingUid => _uid;

  @override
  String get sharedCollection => 'notes';

  @override
  String get sharedPrefsCollection => 'shared_note_prefs';

  @override
  bool get sharingDisposed => _disposed;

  @override
  NoteModel sharedFromJson(Map<String, dynamic> json) =>
      NoteModel.fromJson(json);

  @override
  List<String> get privateKeys => const ['audioNotes', 'tags'];

  ItemCipher? _cipher;

  @override
  ItemCipher get cipher => _cipher!;

  CollectionReference<Map<String, dynamic>> get _col => ownCollection;

  static String _id(NoteModel n) => n.id;

  Future<NoteModel?> _parse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = await decodeDoc(doc);
    return data == null ? null : NoteModel.fromJson(data);
  }

  void _onLoadError(Object? error) =>
      ref.read(notesLoadErrorProvider.notifier).set(error);

  void _onLoadDone() => ref.read(notesLoadingProvider.notifier).set(false);

  /// Re-fetches all notes from Firestore, replacing local state (e.g.
  /// pull-to-refresh after a sync error or edits from another device).
  @override
  Future<void> reload() => _load(replace: true);

  Future<void> _load({bool replace = false}) async {
    final uid = _uid;
    final ready = _initialLoad;
    if (uid.isEmpty) {
      if (!ready.isCompleted) ready.complete(false);
      return;
    }
    var ok = false;
    try {
      // A plain get() waits for the server even when the notes are cached:
      // show the cached ones first so the list is not empty meanwhile.
      var seeded = const <String, NoteModel>{};
      if (!replace) {
        seeded = await seedFromCache(
          _col,
          _parse,
          _id,
          () => uid != _uid || _disposed,
        );
        if (seeded.isNotEmpty) _onLoadDone();
      }
      final sharedWithMe = loadSharedWithMe(uid);
      final snap = await _col.get();
      final shared = await sharedWithMe;
      // The user changed (or the notifier was disposed) while this fetch
      // was in flight.
      if (uid != _uid || _disposed) {
        if (!ready.isCompleted) ready.complete(false);
        return;
      }
      final notes = [...await parseDocs(snap.docs, _parse), ...shared];
      if (replace) {
        state = notes;
      } else {
        // Reconcile instead of replace: a note added/edited locally while
        // this initial fetch was in flight must not be wiped out by it.
        state = reconcileInitialLoad(notes, seeded, _id);
      }
      _onLoadError(null);
      ok = true;
      startSharedListeners(uid);
      // Not awaited: offline the deletes stay queued and must not hold up
      // the loading flag.
      _purgeOldTrashFirestore().ignore();
      syncEncryption(snap.docs).ignore();
    } catch (e) {
      if (!_disposed) _onLoadError(e);
    } finally {
      if (!_disposed) _onLoadDone();
      if (!ready.isCompleted) ready.complete(ok);
    }
  }

  // ── Public mutations ──────────────────────────────────────────────────────

  /// Adds [note] at the top of the custom order.
  Future<void> addNote(NoteModel note) {
    final indices = state.map((n) => n.sortIndex).whereType<int>();
    note.sortIndex ??=
        indices.isEmpty ? 0 : indices.reduce((a, b) => a < b ? a : b) - 1;
    return mutate((current) => [note, ...current], () => saveItem(note));
  }

  /// Saves an edit of a note. Its place in the custom order stays the one in
  /// the state (only [reorderNotes] moves notes).
  Future<void> updateNote(NoteModel updated) {
    final note = withCurrentSharing(
      updated.copyWith(sortIndex: itemById(updated.id)?.sortIndex),
    );
    return mutate(
      (current) => current.map((n) => n.id == note.id ? note : n).toList(),
      () => saveItem(note),
    );
  }

  Future<void> deleteNote(String id) {
    final note = itemById(id);
    if (note != null) _syncReminder(note, removed: true).ignore();
    return mutate(
      (current) => current.where((n) => n.id != id).toList(),
      () => deleteItemDoc(id, note),
    );
  }

  /// Removes the current user from the collaborators of [noteId], a note
  /// another user shared with them: it disappears from their notes.
  Future<void> leaveNote(String noteId) => deleteNote(noteId);

  /// Cancels the reminder of [note] while it is in the trash or once
  /// [removed], schedules it again once restored. Not awaited by the callers:
  /// offline the Firestore write never completes, and the notification must
  /// change right away.
  Future<void> _syncReminder(NoteModel note, {bool removed = false}) async {
    if (kIsWeb) return;
    try {
      final notifications = ref.read(notificationServiceProvider);
      await notifications.cancelNotification(
        NotificationService.idForNote(note.id),
      );
      if (removed || note.deletedAt != null) return;
      await notifications.scheduleNoteReminder(note, askPermission: false);
    } catch (e) {
      if (kDebugMode) debugPrint('Note reminder sync failed: $e');
    }
  }

  Future<void> softDelete(String id) async {
    final updated = state
        .firstWhere((n) => n.id == id)
        .copyWith(deletedAt: DateTime.now(), isArchived: false);
    _syncReminder(updated).ignore();
    await mutate(
      (current) => current.map((n) => n.id == id ? updated : n).toList(),
      () => saveItem(updated),
    );
  }

  Future<void> restoreFromTrash(String id) async {
    final updated = state
        .firstWhere((n) => n.id == id)
        .copyWith(clearDeletedAt: true);
    _syncReminder(updated).ignore();
    await mutate(
      (current) => current.map((n) => n.id == id ? updated : n).toList(),
      () => saveItem(updated),
    );
  }

  Future<void> permanentlyDelete(String id) => deleteNote(id);

  Future<void> emptyTrash() async {
    final trashed = state.where((n) => n.deletedAt != null).toList();
    await mutate(
      (current) => current.where((n) => n.deletedAt == null).toList(),
      () => commitInChunks(
        trashed.map((n) => (WriteBatch b) => removeItem(b, n)).toList(),
      ),
    );
  }

  Future<void> _purgeOldTrashFirestore() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final expired =
        state
            .where((n) => n.deletedAt != null && n.deletedAt!.isBefore(cutoff))
            .toList();
    if (expired.isEmpty) return;
    await mutate(
      (current) =>
          current
              .where((n) => n.deletedAt == null || n.deletedAt!.isAfter(cutoff))
              .toList(),
      () => commitInChunks(
        expired.map((n) => (WriteBatch b) => removeItem(b, n)).toList(),
      ),
    );
  }

  void purgeOldTrash() {
    // Kept for API compatibility; async version runs on load.
    _purgeOldTrashFirestore();
  }

  Future<void> toggleArchive(String id) async {
    final updated = state
        .firstWhere((n) => n.id == id)
        .copyWith(isArchived: !state.firstWhere((n) => n.id == id).isArchived);
    await mutate(
      (current) => current.map((n) => n.id == id ? updated : n).toList(),
      () => saveItem(updated),
    );
  }

  Future<void> togglePin(String id) async {
    final updated = state
        .firstWhere((n) => n.id == id)
        .copyWith(isPinned: !state.firstWhere((n) => n.id == id).isPinned);
    await mutate(
      (current) => current.map((n) => n.id == id ? updated : n).toList(),
      () => saveItem(updated),
    );
  }

  /// Moves a note within [visibleNotes] (the displayed ones, in display
  /// order) and saves the resulting custom order: every note gets its
  /// position as [NoteModel.sortIndex], and only those whose position
  /// changed are written.
  Future<void> reorderNotes(
    List<NoteModel> visibleNotes,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) newIndex--;

    final ids = visibleNotes.map((n) => n.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);

    // The visible notes take, in their new order, the slots they hold in
    // the current custom order; the hidden ones (archived, filtered out)
    // keep theirs.
    final visibleSet = ids.toSet();
    final ordered = [...state]..sort(compareCustomOrder);
    var vi = 0;
    final newIds = [
      for (final n in ordered) visibleSet.contains(n.id) ? ids[vi++] : n.id,
    ];
    final byId = {for (final n in state) n.id: n};
    final updates = <String, NoteModel>{
      for (var i = 0; i < newIds.length; i++)
        if (byId[newIds[i]]!.sortIndex != i)
          newIds[i]: byId[newIds[i]]!.copyWith(sortIndex: i),
    };
    if (updates.isEmpty) return;
    await mutate(
      (current) => current.map((n) => updates[n.id] ?? n).toList(),
      () => commitInChunks(
        updates.values.map((n) => (WriteBatch b) => writeItem(b, n)).toList(),
      ),
    );
  }

  /// Renames a tag across all notes that have it. A note that already has
  /// [newTag] keeps it only once.
  Future<void> renameTag(String oldTag, String newTag) async {
    if (newTag.trim().isEmpty || oldTag == newTag) return;
    final affected = state.where((n) => n.tags.contains(oldTag)).toList();
    if (affected.isEmpty) return;
    final updates = {
      for (final n in affected)
        n.id: n.copyWith(
          tags:
              {
                for (final t in n.tags) t == oldTag ? newTag.trim() : t,
              }.toList(),
        ),
    };
    await mutate(
      (current) => current.map((n) => updates[n.id] ?? n).toList(),
      () => commitInChunks(
        updates.values.map((n) => (WriteBatch b) => writeItem(b, n)).toList(),
      ),
    );
  }

  /// Removes a tag from all notes that have it.
  Future<void> deleteTag(String tag) async {
    final affected = state.where((n) => n.tags.contains(tag)).toList();
    if (affected.isEmpty) return;
    final updates = {
      for (final n in affected)
        n.id: n.copyWith(tags: n.tags.where((t) => t != tag).toList()),
    };
    await mutate(
      (current) => current.map((n) => updates[n.id] ?? n).toList(),
      () => commitInChunks(
        updates.values.map((n) => (WriteBatch b) => writeItem(b, n)).toList(),
      ),
    );
  }

  /// Replaces the entire notes collection (used for full backup restore).
  /// Own notes missing from [notes] are deleted from Firestore too,
  /// otherwise they would reappear on the next load. Notes shared with this
  /// user are left alone, and own notes keep their collaborators (backups
  /// don't carry them).
  Future<void> replaceAll(List<NoteModel> notes) {
    final r = restoreKeepingShared(notes);
    return mutate(
      (_) => r.state,
      () => commitInChunks([
        for (final id in r.stale) (WriteBatch b) => b.delete(_col.doc(id)),
        for (final n in r.restored) (WriteBatch b) => writeItem(b, n),
      ]),
    );
  }

  /// Permanently removes all own notes; those shared with this user stay
  /// (they belong to someone else).
  Future<void> clearAll() {
    final ids = [
      for (final n in state)
        if (!n.isForeignTo(_uid)) n.id,
    ];
    return mutate(
      (current) => current.where((n) => n.isForeignTo(_uid)).toList(),
      () => commitInChunks(
        ids.map((id) => (WriteBatch b) => b.delete(_col.doc(id))).toList(),
      ),
    );
  }
}

/// Set (or cleared) whenever the initial Firestore load in [NotesNotifier]
/// succeeds or fails, so the UI can tell a real sync error apart from a
/// genuinely empty notes list.
final notesLoadErrorProvider = valueStateProvider<Object?>(null);

/// True while the initial Firestore load in [NotesNotifier] is in flight,
/// so the UI can tell "still loading" apart from a genuinely empty list.
final notesLoadingProvider = valueStateProvider<bool>(true);

/// The custom order of notes: by [NoteModel.sortIndex], with the notes
/// never placed (null) first, newest first.
int compareCustomOrder(NoteModel a, NoteModel b) {
  final ai = a.sortIndex, bi = b.sortIndex;
  if (ai == null && bi == null) return b.createdAt.compareTo(a.createdAt);
  if (ai == null) return -1;
  if (bi == null) return 1;
  return ai.compareTo(bi);
}

final notesProvider = NotifierProvider<NotesNotifier, List<NoteModel>>(
  NotesNotifier.new,
);

/// Every note by id, rebuilt once per change of [notesProvider].
final notesByIdProvider = Provider<Map<String, NoteModel>>((ref) {
  return {for (final n in ref.watch(notesProvider)) n.id: n};
});

/// A single note: notifies only when that note changes (unchanged notes
/// keep the same instance across mutations), so a card watching it is not
/// rebuilt by edits to other notes.
final noteByIdProvider = Provider.autoDispose.family<NoteModel?, String>((
  ref,
  id,
) {
  return ref.watch(notesByIdProvider.select((notes) => notes[id]));
});

final activeNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  return notes.where((n) => !n.isArchived && n.deletedAt == null).toList();
});

final archivedNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  return notes.where((n) => n.isArchived && n.deletedAt == null).toList();
});

final trashedNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  return notes.where((n) => n.deletedAt != null).toList();
});

/// The signed-in user's own notes, without those shared with them: what
/// backups and exports contain.
final ownNotesProvider = Provider<List<NoteModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ownItems(ref.watch(notesProvider), uid);
});
