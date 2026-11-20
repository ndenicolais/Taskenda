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
import 'core_providers.dart';

/// Snapshot of Firestore writes not yet acknowledged by the server.
@immutable
class SyncStatus {
  const SyncStatus({this.queued = 0, this.failures = 0});

  /// Writes applied to the local cache but still waiting for the server
  /// (typically because the device is offline).
  final int queued;

  /// Total queued writes the server later rejected; only ever grows, so
  /// listeners can react to each new failure.
  final int failures;

  bool get hasQueued => queued > 0;

  SyncStatus copyWith({int? queued, int? failures}) => SyncStatus(
    queued: queued ?? this.queued,
    failures: failures ?? this.failures,
  );
}

/// Counts the Firestore writes that outlived [FirestoreListMutations.writeGrace]
/// and are now queued in the offline cache.
class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  /// Tracks [write] until it settles; [onFailure] runs if the server
  /// rejects it.
  void track(Future<void> write, {VoidCallback? onFailure}) {
    state = state.copyWith(queued: state.queued + 1);
    write.then(
      (_) {
        state = state.copyWith(queued: state.queued - 1);
      },
      onError: (Object _) {
        state = state.copyWith(
          queued: state.queued - 1,
          failures: state.failures + 1,
        );
        onFailure?.call();
      },
    );
  }
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

/// Optimistic-update helpers shared by the Firestore-backed list notifiers.
///
/// With offline persistence on, a Firestore write is applied to the local
/// cache immediately but its future only completes once the server
/// acknowledges it — never, while offline. [mutate] therefore waits at most
/// [writeGrace]: errors within that window roll the state back as before,
/// slower writes are handed to [syncStatusProvider] and stay queued in the
/// cache.
/// If the server later rejects one, Firestore reverts its cache and
/// [reload] re-reads it.
mixin FirestoreListMutations<T> on Notifier<List<T>> {
  /// How long a write may take before it is considered queued offline.
  static Duration writeGrace = const Duration(seconds: 3);

  FirebaseFirestore get db => ref.read(firestoreProvider);
  Future<void> reload();

  /// Reads [query] from the local cache only (no network wait) and merges
  /// it into the state, so a screen shows the last known data at once while
  /// the server fetch is in flight. [itemId] gives an item's document id;
  /// [isStale] is true once the user changed meanwhile. Returns the items
  /// shown, by id, to pass to [reconcileInitialLoad]; empty if the cache had
  /// nothing or failed.
  Future<Map<String, T>> seedFromCache(
    Query<Map<String, dynamic>> query,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) parse,
    String Function(T item) itemId,
    bool Function() isStale,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get(const GetOptions(source: Source.cache));
    } catch (_) {
      return const {};
    }
    if (isStale() || snap.docs.isEmpty) return const {};
    final seeded = {for (final doc in snap.docs) doc.id: parse(doc)};
    final existingIds = state.map(itemId).toSet();
    state = [
      ...state,
      ...seeded.values.where((e) => !existingIds.contains(itemId(e))),
    ];
    return seeded;
  }

  /// The state after the first server fetch, given the [seeded] cache items
  /// already shown: server items replace untouched seeded ones, while items
  /// added, edited or deleted locally since the seed keep their local
  /// version.
  List<T> reconcileInitialLoad(
    List<T> server,
    Map<String, T> seeded,
    String Function(T item) itemId,
  ) {
    final current = {for (final e in state) itemId(e): e};
    final serverIds = server.map(itemId).toSet();
    return [
      for (final e in server)
        if (current[itemId(e)] case final local?)
          identical(local, seeded[itemId(e)]) ? e : local
        else if (!seeded.containsKey(itemId(e)))
          e,
      for (final e in state)
        if (!serverIds.contains(itemId(e)) && !seeded.containsKey(itemId(e))) e,
    ];
  }

  /// Applies [apply] to state immediately, then runs [persist]; if it fails
  /// within [writeGrace] the state change is rolled back and the error is
  /// rethrown instead of being silently swallowed.
  Future<void> mutate(
    List<T> Function(List<T> current) apply,
    Future<void> Function() persist,
  ) async {
    final previous = state;
    state = apply(previous);
    final write = Future.sync(persist);
    try {
      if (await _settledWithin(write, writeGrace)) return;
    } catch (_) {
      state = previous;
      rethrow;
    }
    ref
        .read(syncStatusProvider.notifier)
        .track(write, onFailure: () => reload().ignore());
  }

  /// Commits Firestore batch writes in chunks of 500 (Firestore's per-batch
  /// operation limit). Chunks are committed together rather than one after
  /// the other, so offline they are all queued locally at once instead of
  /// each waiting for the previous one's server acknowledgement.
  Future<void> commitInChunks(List<void Function(WriteBatch batch)> ops) {
    final batches = <WriteBatch>[];
    for (var i = 0; i < ops.length; i += 500) {
      final batch = db.batch();
      for (final op in ops.skip(i).take(500)) {
        op(batch);
      }
      batches.add(batch);
    }
    return Future.wait(batches.map((b) => b.commit()));
  }

  /// True if [write] completed within [grace], false if it is still
  /// pending; rethrows if it failed within [grace].
  static Future<bool> _settledWithin(Future<void> write, Duration grace) {
    final result = Completer<bool>();
    final timer = Timer(grace, () {
      if (!result.isCompleted) result.complete(false);
    });
    write.then(
      (_) {
        timer.cancel();
        if (!result.isCompleted) result.complete(true);
      },
      onError: (Object e, StackTrace st) {
        timer.cancel();
        if (!result.isCompleted) result.completeError(e, st);
      },
    );
    return result.future;
  }
}
