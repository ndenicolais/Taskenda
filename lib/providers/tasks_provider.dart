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
import '../core/crypto/item_codec.dart';
import '../models/task_model.dart';
import '../models/task_list_model.dart';
import '../utils/notification_service.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'crypto_provider.dart';
import 'reminders_actions.dart';
import 'shared_items.dart';
import 'sync_provider.dart';
import 'settings/ui_provider.dart'; // For SortOrder

// ─── Tasks Notifier ───────────────────────────────────────────────────────────

/// Tasks of the signed-in user ([currentUidProvider]); same lifecycle as
/// `NotesNotifier`, including the tasks shared with this user (see
/// [SharedItems]).
class TasksNotifier extends Notifier<List<TaskModel>>
    with FirestoreListMutations<TaskModel>, SharedItems<TaskModel> {
  late String _uid;

  /// Completes with `true` once the first fetch for the current user has
  /// succeeded, `false` if it failed or nobody is signed in. Recreated on
  /// every user change; used to resync reminders after sign-in.
  Future<bool> get initialLoad => _initialLoad.future;
  Completer<bool> _initialLoad = Completer<bool>();

  @override
  List<TaskModel> build() {
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

  bool _disposed = false;

  @override
  String get sharingUid => _uid;

  @override
  String get sharedCollection => 'tasks';

  @override
  String get sharedPrefsCollection => 'shared_task_prefs';

  @override
  bool get sharingDisposed => _disposed;

  @override
  TaskModel sharedFromJson(Map<String, dynamic> json) =>
      TaskModel.fromJson(json);

  @override
  List<String> get privateKeys => const ['tags'];

  ItemCipher? _cipher;

  @override
  ItemCipher get cipher => _cipher!;

  CollectionReference<Map<String, dynamic>> get _col => ownCollection;

  static String _id(TaskModel t) => t.id;

  Future<TaskModel?> _parse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = await decodeDoc(doc);
    return data == null ? null : TaskModel.fromJson(data);
  }

  void _onLoadError(Object? error) =>
      ref.read(tasksLoadErrorProvider.notifier).set(error);

  void _onLoadDone() => ref.read(tasksLoadingProvider.notifier).set(false);

  /// Re-fetches all tasks from Firestore, replacing local state (e.g.
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
      // A plain get() waits for the server even when the tasks are cached:
      // show the cached ones first so lists and calendar are not empty
      // meanwhile.
      var seeded = const <String, TaskModel>{};
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
      final tasks = [...await parseDocs(snap.docs, _parse), ...shared];
      if (replace) {
        state = tasks;
      } else {
        // Reconcile instead of replace: any task added/edited locally while
        // this initial fetch was in flight must not be wiped out by it.
        state = reconcileInitialLoad(tasks, seeded, _id);
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

  Future<void> _saveDoc(TaskModel task) => saveItem(task);

  Future<void> _purgeOldTrashFirestore() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final expired =
        state
            .where((t) => t.deletedAt != null && t.deletedAt!.isBefore(cutoff))
            .toList();
    if (expired.isEmpty) return;
    await mutate(
      (current) =>
          current
              .where((t) => t.deletedAt == null || t.deletedAt!.isAfter(cutoff))
              .toList(),
      () => commitInChunks(
        expired.map((t) => (WriteBatch b) => removeItem(b, t)).toList(),
      ),
    );
  }

  void purgeOldTrash() {
    _purgeOldTrashFirestore();
  }

  Future<void> addTask(TaskModel task) =>
      mutate((current) => [task, ...current], () => _saveDoc(task));

  Future<void> updateTask(TaskModel updated) {
    final task = withCurrentSharing(updated);
    return mutate(
      (current) => current.map((t) => t.id == task.id ? task : t).toList(),
      () => _saveDoc(task),
    );
  }

  /// Removes the current user from the collaborators of [taskId], a task
  /// another user shared with them: it disappears from their tasks.
  Future<void> leaveTask(String taskId) => deleteTask(taskId);

  /// Keeps the due-time notification of [task] in line with its state:
  /// cancelled when it is trashed, completed or [removed], rescheduled
  /// otherwise. Not awaited by the callers: offline the Firestore write never
  /// completes, and the notification must change right away.
  Future<void> _syncReminder(TaskModel task, {bool removed = false}) async {
    if (kIsWeb) return;
    try {
      final notifications = ref.read(notificationServiceProvider);
      await notifications.cancelNotification(
        NotificationService.idForTask(task.id),
      );
      if (removed || task.deletedAt != null || task.isCompleted) return;
      await notifications.scheduleTaskReminder(task, askPermission: false);
    } catch (e) {
      if (kDebugMode) debugPrint('Task reminder sync failed: $e');
    }
  }

  Future<void> softDelete(String id) async {
    final updated = state
        .firstWhere((t) => t.id == id)
        .copyWith(deletedAt: DateTime.now(), isArchived: false);
    _syncReminder(updated).ignore();
    await mutate(
      (current) => current.map((t) => t.id == id ? updated : t).toList(),
      () => _saveDoc(updated),
    );
  }

  /// Removes only one occurrence of the recurring [task]: the one on [day]
  /// (e.g. opened from the calendar), or the current one, which moves it on
  /// to the next. Returns the updated task.
  Future<TaskModel> skipOccurrence(TaskModel task, {DateTime? day}) async {
    final next =
        day == null ? task.nextOccurrence() : task.withoutOccurrence(day);
    await updateTask(next);
    return next;
  }

  /// Splits the occurrence on [day] off the recurring task [id]: the series
  /// leaves it out (moving on to the next one if it was the current) and
  /// [single] (the edited occurrence, a new task) takes its place. One
  /// batched write; reminders of both rescheduled.
  Future<void> splitOccurrence(String id, DateTime day, TaskModel single) {
    final series = withCurrentSharing(
      state.firstWhere((t) => t.id == id).withoutOccurrence(day),
    );
    _syncReminder(series).ignore();
    _syncReminder(single).ignore();
    return mutate(
      (current) => [single, for (final t in current) t.id == id ? series : t],
      () => commitInChunks([
        (WriteBatch b) => writeItem(b, series),
        (WriteBatch b) => writeItem(b, single),
      ]),
    );
  }

  Future<void> restoreFromTrash(String id) async {
    final updated = state
        .firstWhere((t) => t.id == id)
        .copyWith(clearDeletedAt: true);
    _syncReminder(updated).ignore();
    await mutate(
      (current) => current.map((t) => t.id == id ? updated : t).toList(),
      () => _saveDoc(updated),
    );
  }

  Future<void> permanentlyDelete(String id) => deleteTask(id);

  Future<void> toggleArchive(String id) async {
    final updated = state
        .firstWhere((t) => t.id == id)
        .copyWith(isArchived: !state.firstWhere((t) => t.id == id).isArchived);
    await mutate(
      (current) => current.map((t) => t.id == id ? updated : t).toList(),
      () => _saveDoc(updated),
    );
  }

  Future<void> deleteTask(String id) {
    final task = itemById(id);
    if (task != null) _syncReminder(task, removed: true).ignore();
    return mutate(
      (current) => current.where((t) => t.id != id).toList(),
      () => deleteItemDoc(id, task),
    );
  }

  Future<void> toggleComplete(String id) async {
    final updated = state
        .firstWhere((t) => t.id == id)
        .copyWith(
          isCompleted: !state.firstWhere((t) => t.id == id).isCompleted,
        );
    _syncReminder(updated).ignore();
    await mutate(
      (current) => current.map((t) => t.id == id ? updated : t).toList(),
      () => _saveDoc(updated),
    );
  }

  Future<void> toggleSpecial(String id) async {
    final updated = state
        .firstWhere((t) => t.id == id)
        .copyWith(isSpecial: !state.firstWhere((t) => t.id == id).isSpecial);
    await mutate(
      (current) => current.map((t) => t.id == id ? updated : t).toList(),
      () => _saveDoc(updated),
    );
  }

  Future<void> moveToList(String taskId, String? listId) async {
    final updated = state
        .firstWhere((t) => t.id == taskId)
        .copyWith(listId: listId, clearListId: listId == null);
    await mutate(
      (current) => current.map((t) => t.id == taskId ? updated : t).toList(),
      () => _saveDoc(updated),
    );
  }

  /// Clears [listId] on every task that pointed at a now-deleted list, both
  /// locally and on Firestore, so tasks don't keep a dangling reference.
  Future<void> clearListReferences(String listId) async {
    final affected = state.where((t) => t.listId == listId).toList();
    if (affected.isEmpty) return;
    await mutate(
      (current) =>
          current
              .map(
                (t) => t.listId == listId ? t.copyWith(clearListId: true) : t,
              )
              .toList(),
      () => commitInChunks(
        affected
            .map(
              (t) =>
                  (WriteBatch b) => writeItem(b, t.copyWith(clearListId: true)),
            )
            .toList(),
      ),
    );
  }

  /// Replaces the entire tasks collection (used for full backup restore).
  /// Tasks missing from [tasks] are deleted from Firestore too, otherwise
  /// they would reappear on the next load.
  /// Saves several edited tasks at once (one batched write).
  Future<void> updateTasks(List<TaskModel> updated) {
    if (updated.isEmpty) return Future.value();
    final tasks = updated.map(withCurrentSharing).toList();
    final byId = {for (final t in tasks) t.id: t};
    return mutate(
      (current) => [for (final t in current) byId[t.id] ?? t],
      () => commitInChunks([
        for (final t in tasks) (WriteBatch b) => writeItem(b, t),
      ]),
    );
  }

  /// Own tasks missing from [tasks] are deleted from Firestore too; the
  /// tasks shared with this user are left alone, and own tasks keep their
  /// collaborators (backups don't carry them).
  Future<void> replaceAll(List<TaskModel> tasks) {
    final r = restoreKeepingShared(tasks);
    return mutate(
      (_) => r.state,
      () => commitInChunks([
        for (final id in r.stale) (WriteBatch b) => b.delete(_col.doc(id)),
        for (final t in r.restored) (WriteBatch b) => writeItem(b, t),
      ]),
    );
  }

  /// Permanently removes all own tasks; those shared with this user stay
  /// (they belong to someone else).
  Future<void> clearAll() {
    final ids = [
      for (final t in state)
        if (!t.isForeignTo(_uid)) t.id,
    ];
    return mutate(
      (current) => current.where((t) => t.isForeignTo(_uid)).toList(),
      () => commitInChunks(
        ids.map((id) => (WriteBatch b) => b.delete(_col.doc(id))).toList(),
      ),
    );
  }
}

/// Set (or cleared) whenever the initial Firestore load in [TasksNotifier]
/// succeeds or fails, so the UI can tell a real sync error apart from a
/// genuinely empty task list.
final tasksLoadErrorProvider = valueStateProvider<Object?>(null);

/// True while the initial Firestore load in [TasksNotifier] is in flight,
/// so the UI can tell "still loading" apart from a genuinely empty list.
final tasksLoadingProvider = valueStateProvider<bool>(true);

final tasksProvider = NotifierProvider<TasksNotifier, List<TaskModel>>(
  TasksNotifier.new,
);

// ─── Task Lists Notifier ──────────────────────────────────────────────────────

class TaskListsNotifier extends Notifier<List<TaskListModel>>
    with FirestoreListMutations<TaskListModel> {
  late String _uid;

  ItemCipher? _cipher;

  static const _collection = 'task_lists';
  static const _encryptedKeys = ['name'];

  @override
  List<TaskListModel> build() {
    // Nothing loads until the keys are unlocked: as if signed out.
    _cipher = ref.watch(itemCipherProvider);
    _uid = _cipher == null ? '' : ref.watch(currentUidProvider);
    ref.watch(firestoreProvider);
    _load().ignore();
    return [];
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      db.collection('users').doc(_uid).collection('task_lists');

  /// Re-fetches all task lists from Firestore, replacing local state.
  @override
  Future<void> reload() => _load(replace: true);

  Future<void> _load({bool replace = false}) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    // Cached lists first: get() alone waits for the server.
    final seeded =
        replace
            ? const <String, TaskListModel>{}
            : await seedFromCache(_col, _parseList, _listId, () => uid != _uid);
    final snap = await _col.get();
    if (uid != _uid) return;
    final lists = await parseDocs(snap.docs, _parseList);
    state = replace ? lists : reconcileInitialLoad(lists, seeded, _listId);
    _encryptLegacy(snap.docs).ignore();
  }

  static String _listId(TaskListModel l) => l.id;

  Future<TaskListModel?> _parseList(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = Map<String, dynamic>.from(
        await _cipher!.decode(_collection, doc.id, doc.data()),
      );
      data['id'] = doc.id;
      return TaskListModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('$_collection/${doc.id} unreadable: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _encode(TaskListModel l) => _cipher!.encodeNamed(
    _collection,
    l.id,
    l.toJson(),
    contentKeys: _encryptedKeys,
  );

  /// Writes again, encrypted, the lists of [docs] still stored in clear.
  Future<void> _encryptLegacy(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (!_cipher!.encrypts) return;
    final legacy = [
      for (final l in state)
        if (docs.any((d) => d.id == l.id && !ItemCodec.isEncrypted(d.data())))
          l,
    ];
    if (legacy.isEmpty) return;
    try {
      await commitInChunks([
        for (final l in legacy)
          (WriteBatch b) async => b.set(_col.doc(l.id), await _encode(l)),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('Task lists not encrypted yet: $e');
    }
  }

  Future<void> addList(TaskListModel taskList) => mutate(
    (current) => [...current, taskList],
    () async => _col.doc(taskList.id).set(await _encode(taskList)),
  );

  Future<void> updateList(TaskListModel updated) => mutate(
    (current) => current.map((l) => l.id == updated.id ? updated : l).toList(),
    () async => _col.doc(updated.id).set(await _encode(updated)),
  );

  Future<void> deleteList(String id) async {
    await mutate(
      (current) => current.where((l) => l.id != id).toList(),
      () => _col.doc(id).delete(),
    );
    // Tasks pointing at this now-deleted list must not keep a dangling
    // listId, otherwise they become invisible in every filter/tab forever.
    await ref.read(tasksProvider.notifier).clearListReferences(id);
  }

  /// Replaces the entire task-lists collection (used for full backup restore).
  /// Lists missing from [lists] are deleted from Firestore too, otherwise
  /// they would reappear on the next load.
  Future<void> replaceAll(List<TaskListModel> lists) {
    final keep = {for (final l in lists) l.id};
    final stale = [
      for (final l in state)
        if (!keep.contains(l.id)) l.id,
    ];
    return mutate(
      (_) => lists,
      () => commitInChunks([
        for (final id in stale) (WriteBatch b) => b.delete(_col.doc(id)),
        for (final l in lists)
          (WriteBatch b) async => b.set(_col.doc(l.id), await _encode(l)),
      ]),
    );
  }

  /// Permanently removes all task lists.
  Future<void> clearAll() {
    final ids = state.map((l) => l.id).toList();
    return mutate(
      (_) => [],
      () => commitInChunks(
        ids.map((id) => (WriteBatch b) => b.delete(_col.doc(id))).toList(),
      ),
    );
  }
}

final taskListsProvider =
    NotifierProvider<TaskListsNotifier, List<TaskListModel>>(
      TaskListsNotifier.new,
    );

// ─── Filtered & Sorted Providers ─────────────────────────────────────────────

/// Every task by id, rebuilt once per change of [tasksProvider].
final tasksByIdProvider = Provider<Map<String, TaskModel>>((ref) {
  return {for (final t in ref.watch(tasksProvider)) t.id: t};
});

/// A single task, notifying only when that task changes (see
/// `noteByIdProvider`).
final taskByIdProvider = Provider.autoDispose.family<TaskModel?, String>((
  ref,
  id,
) {
  return ref.watch(tasksByIdProvider.select((tasks) => tasks[id]));
});

final activeTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final sort = ref.watch(taskSortOrderProvider);

  var filtered =
      tasks.where((t) => !t.isArchived && t.deletedAt == null).toList();

  _sortTasks(filtered, sort);
  return filtered;
});

final specialTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final sort = ref.watch(taskSortOrderProvider);

  var filtered =
      tasks
          .where((t) => t.isSpecial && !t.isArchived && t.deletedAt == null)
          .toList();

  _sortTasks(filtered, sort);
  return filtered;
});

final archivedTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final sort = ref.watch(taskSortOrderProvider);

  var filtered =
      tasks.where((t) => t.isArchived && t.deletedAt == null).toList();

  _sortTasks(filtered, sort);
  return filtered;
});

final trashedTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final sort = ref.watch(taskSortOrderProvider);

  var filtered = tasks.where((t) => t.deletedAt != null).toList();

  _sortTasks(filtered, sort);
  return filtered;
});

void _sortTasks(List<TaskModel> tasks, SortOrder sort) {
  switch (sort) {
    case SortOrder.createdNewest:
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortOrder.createdOldest:
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case SortOrder.modifiedNewest:
      tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case SortOrder.modifiedOldest:
      tasks.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case SortOrder.custom:
      break;
  }
}

final taskListTasksProvider = Provider.family<List<TaskModel>, String>((
  ref,
  listId,
) {
  final tasks = ref.watch(activeTasksProvider);
  final query = ref.watch(taskSearchQueryProvider).toLowerCase();
  var filtered = tasks.where((t) => t.listId == listId).toList();
  if (query.isNotEmpty) {
    filtered =
        filtered
            .where(
              (t) =>
                  t.title.toLowerCase().contains(query) ||
                  t.description.toLowerCase().contains(query),
            )
            .toList();
  }
  return filtered;
});

/// The signed-in user's own tasks, without those shared with them: what
/// backups and exports contain.
final ownTasksProvider = Provider<List<TaskModel>>((ref) {
  return ownItems(ref.watch(tasksProvider), ref.watch(currentUidProvider));
});
