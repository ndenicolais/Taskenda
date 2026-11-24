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
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/crypto/item_cipher.dart';
import '../core/crypto/item_codec.dart';
import '../models/share_member.dart';
import '../models/sharing.dart';
import 'core_providers.dart';
import 'sharing_provider.dart';
import 'sync_provider.dart';

/// The items of [collection] shared with [uid]: a collection-group query on
/// `collaborators`. Tests override it, as the fake Firestore doesn't stream
/// changes of collection-group queries.
final sharedWithMeQueryProvider = Provider<
  Query<Map<String, dynamic>> Function(String collection, String uid)
>((ref) {
  final db = ref.watch(firestoreProvider);
  return (collection, uid) =>
      db.collectionGroup(collection).where('collaborators', arrayContains: uid);
});

/// Sharing support for a Firestore-backed list notifier (notes, tasks,
/// events), so the three share one implementation:
///
/// - the state also holds the items other users shared with this one: they
///   stay in the owner's collection, their [Shareable.sharedContentKeys] are
///   written there and their personal fields in this user's
///   [sharedPrefsCollection];
/// - deleting one of them for good removes this user from its collaborators
///   instead (the item stays with its owner);
/// - after the first load the shared items are live (see
///   [startSharedListeners]), unlike the rest of the state;
/// - the documents go through [cipher]: an item neither shared by nor with
///   this user is encrypted, the shared ones stay in clear until sharing is
///   end-to-end encrypted too (phase 4 of `guides/E2EE_PLAN.md`).
mixin SharedItems<T extends Shareable<T>> on FirestoreListMutations<T> {
  /// The signed-in user's uid.
  String get sharingUid;

  /// Collection of the items under `users/{uid}/`, e.g. `notes`.
  String get sharedCollection;

  /// Collection of the personal fields of the items shared with this user,
  /// e.g. `shared_note_prefs`.
  String get sharedPrefsCollection;

  /// True once the current build is torn down.
  bool get sharingDisposed;

  T sharedFromJson(Map<String, dynamic> json);

  /// Encrypts and decrypts the documents; set while the keys are unlocked
  /// (the notifiers load nothing otherwise).
  ItemCipher get cipher;

  /// [toJson] keys that are only the owner's but still sensitive (labels,
  /// audio notes), encrypted apart from the shared content.
  List<String> get privateKeys;

  final _sharedSubs = <StreamSubscription<Object?>>[];

  /// Live snapshots are decrypted (async) one after the other, in order.
  Future<void> _liveQueue = Future.value();

  /// The document data for an own [item] that isn't shared: encrypted.
  Future<Map<String, dynamic>> encodeItem(T item) => cipher.encodeItem(
    sharedCollection,
    item.id,
    item.toJson(),
    contentKeys: ItemCodec.contentKeys(item.sharedContentKeys),
    privateKeys: privateKeys,
  );

  /// The model JSON of a document of [sharedCollection] (decrypted), with
  /// its id; null if it can't be decrypted with this user's keys.
  Future<Map<String, dynamic>?> decodeDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = Map<String, dynamic>.from(
        await cipher.decode(sharedCollection, doc.id, doc.data()!),
      );
      data['id'] = doc.id;
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('$sharedCollection/${doc.id} unreadable: $e');
      return null;
    }
  }

  /// Writes again, encrypted, the own items of [docs] still stored in clear
  /// (written before end-to-end encryption) that aren't shared. Best effort,
  /// not awaited by the loads: it is retried at the next load.
  Future<void> encryptLegacyDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (!cipher.encrypts) return;
    final legacy = <T>[];
    for (final doc in docs) {
      if (ItemCodec.isEncrypted(doc.data())) continue;
      final item = itemById(doc.id);
      if (item != null && isPlainItem(item)) legacy.add(item);
    }
    if (legacy.isEmpty) return;
    try {
      await commitInChunks([
        for (final item in legacy) (WriteBatch b) => writeItem(b, item),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('$sharedCollection not encrypted yet: $e');
    }
  }

  CollectionReference<Map<String, dynamic>> get ownCollection =>
      db.collection('users').doc(sharingUid).collection(sharedCollection);

  CollectionReference<Map<String, dynamic>> get prefsCollection =>
      db.collection('users').doc(sharingUid).collection(sharedPrefsCollection);

  /// The Firestore document of [item]: in the owner's collection for an
  /// item shared with this user.
  DocumentReference<Map<String, dynamic>> docOf(T item) =>
      item.isForeignTo(sharingUid)
          ? db
              .collection('users')
              .doc(item.ownerId)
              .collection(sharedCollection)
              .doc(item.id)
          : ownCollection.doc(item.id);

  T? itemById(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// [item] with the sharing the state has for it: editors and undo
  /// histories work on copies that may predate a sharing change.
  T withCurrentSharing(T item) {
    final current = itemById(item.id);
    return current == null ? item : item.withSharingOf(current);
  }

  /// An item neither shared by nor with this user: one plain document.
  bool isPlainItem(T item) => !item.isShared && !item.isForeignTo(sharingUid);

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Adds to [b] the writes persisting [item]:
  /// - shared with this user: its shared content on the owner's document
  ///   (the only fields the rules let a collaborator change) and its
  ///   personal fields in [sharedPrefsCollection];
  /// - own and shared: an update leaving the sharing fields alone, so a
  ///   collaborator who left meanwhile is not added back; in clear, so
  ///   the encrypted fields of a document shared after it was encrypted
  ///   are removed;
  /// - any other: the whole document, encrypted.
  Future<void> writeItem(WriteBatch b, T item) async {
    if (item.isForeignTo(sharingUid)) {
      b.update(docOf(item), {
        for (final e in item.sharedContentJson().entries)
          e.key: e.value ?? FieldValue.delete(),
      });
      b.set(prefsCollection.doc(item.id), item.personalJson());
    } else if (item.isShared) {
      final json = item.toJson();
      b.update(ownCollection.doc(item.id), {
        ...json,
        for (final k in item.optionalKeys)
          if (!json.containsKey(k)) k: FieldValue.delete(),
        if (cipher.encrypts) ...ItemCipher.clearCodecFields,
      });
    } else {
      b.set(ownCollection.doc(item.id), await encodeItem(item));
    }
  }

  /// Adds to [b] the writes deleting [item] for good; for an item shared
  /// with this user, removes them from its collaborators instead.
  void removeItem(WriteBatch b, T item) {
    cipher.forget(sharedCollection, item.id);
    if (item.isForeignTo(sharingUid)) {
      b.update(docOf(item), _leaveData(sharingUid));
      b.delete(prefsCollection.doc(item.id));
    } else {
      b.delete(ownCollection.doc(item.id));
    }
  }

  static Map<String, Object> _leaveData(String uid) => {
    'collaborators': FieldValue.arrayRemove([uid]),
    'collaboratorProfiles.$uid': FieldValue.delete(),
  };

  Future<void> saveItem(T item) async {
    if (isPlainItem(item)) {
      await ownCollection.doc(item.id).set(await encodeItem(item));
      return;
    }
    final batch = db.batch();
    await writeItem(batch, item);
    await batch.commit();
  }

  /// [item] is read before the optimistic removal (null if unknown).
  Future<void> deleteItemDoc(String id, T? item) async {
    cipher.forget(sharedCollection, id);
    if (item == null || isPlainItem(item)) {
      await ownCollection.doc(id).delete();
      return;
    }
    final batch = db.batch();
    removeItem(batch, item);
    await batch.commit();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<T?> _parseShared(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String ownerId,
  ) async {
    final data = await decodeDoc(doc);
    if (data == null) return null;
    data['ownerId'] = ownerId;
    return sharedFromJson(data);
  }

  /// The items other users shared with [uid], with [uid]'s personal fields.
  /// Never throws: a failure (e.g. the index or the rules not deployed yet)
  /// just leaves them out, so the own items still load.
  Future<List<T>> loadSharedWithMe(String uid) async {
    try {
      final prefsCol = db
          .collection('users')
          .doc(uid)
          .collection(sharedPrefsCollection);
      final results = await Future.wait([
        ref.read(sharedWithMeQueryProvider)(sharedCollection, uid).get(),
        prefsCol.get(),
      ]);
      final prefs = {for (final d in results[1].docs) d.id: d.data()};
      final items = <T>[];
      final sharedIds = <String>{};
      for (final doc in results[0].docs) {
        final ownerId = doc.reference.parent.parent?.id;
        if (ownerId == null || ownerId == uid) continue;
        sharedIds.add(doc.id);
        final item = await _parseShared(doc, ownerId);
        // Trashed by the owner: gone for the collaborators too.
        if (item == null || item.deletedAt != null) continue;
        items.add(item.asSharedWithMe(prefs[doc.id]));
      }
      // Preferences of items their owner deleted or stopped sharing.
      final orphans = prefs.keys.where((id) => !sharedIds.contains(id));
      if (orphans.isNotEmpty) {
        commitInChunks([
          for (final id in orphans)
            (WriteBatch b) => b.delete(prefsCol.doc(id)),
        ]).ignore();
      }
      return items;
    } catch (e) {
      if (kDebugMode) debugPrint('Shared $sharedCollection not loaded: $e');
      return const [];
    }
  }

  // ── Live updates ──────────────────────────────────────────────────────────

  /// Keeps the shared items live: those shared with [uid] (new ones, edits,
  /// unsharing, owner's trash) and the own ones that were ever shared (to
  /// see the collaborators' edits). Call after the first load; started once
  /// per build, ended by [cancelSharedListeners].
  void startSharedListeners(String uid) {
    if (_sharedSubs.isNotEmpty) return;
    void onError(Object e) {
      if (kDebugMode) debugPrint('Shared $sharedCollection listener: $e');
    }

    // Snapshots are decrypted in order: a later one must not be applied
    // before an earlier one still being decrypted.
    void enqueue(Future<void> Function() handle) {
      _liveQueue = _liveQueue.then((_) => handle()).catchError(onError);
    }

    _sharedSubs
      ..add(
        ref
            .read(sharedWithMeQueryProvider)(sharedCollection, uid)
            .snapshots()
            .listen(
              (snap) => enqueue(() => _onSharedWithMe(uid, snap)),
              onError: onError,
            ),
      )
      ..add(
        ownCollection
            .where('ownerId', isEqualTo: uid)
            .snapshots()
            .listen(
              (snap) => enqueue(() => _onOwnShared(uid, snap)),
              onError: onError,
            ),
      );
  }

  void cancelSharedListeners() {
    for (final sub in _sharedSubs) {
      sub.cancel();
    }
    _sharedSubs.clear();
  }

  /// Applies [updates] (id → new item, or null to remove it) keeping the
  /// order; new items go first.
  void _applyLive(Map<String, T?> updates) {
    if (updates.isEmpty) return;
    final existing = {for (final item in state) item.id};
    state = [
      for (final e in updates.entries)
        if (e.value != null && !existing.contains(e.key)) e.value as T,
      for (final item in state)
        if (!updates.containsKey(item.id))
          item
        else if (updates[item.id] case final updated?)
          updated,
    ];
  }

  /// Same shared content and members: nothing to update (the first snapshot
  /// repeats what the load read, and an own write comes back acknowledged).
  static bool _sameShared(Shareable<dynamic> a, Shareable<dynamic> b) =>
      jsonEncode(a.sharedContentJson()) == jsonEncode(b.sharedContentJson()) &&
      listEquals(
        a.collaborators.map((c) => c.uid).toList(),
        b.collaborators.map((c) => c.uid).toList(),
      );

  Future<void> _onSharedWithMe(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    if (sharingDisposed || uid != sharingUid) return;
    final updates = <String, T?>{};
    for (final change in snap.docChanges) {
      final doc = change.doc;
      final ownerId = doc.reference.parent.parent?.id;
      if (ownerId == null || ownerId == uid) continue;
      final current = itemById(doc.id);
      if (current != null && !current.isForeignTo(uid)) continue;
      if (change.type == DocumentChangeType.removed) {
        // Unshared, deleted by the owner or left by this user.
        if (current != null) updates[doc.id] = null;
        continue;
      }
      // This user's own edit, already in the state.
      if (doc.metadata.hasPendingWrites) continue;
      final item = await _parseShared(doc, ownerId);
      if (item == null) continue;
      if (item.deletedAt != null) {
        if (current != null) updates[doc.id] = null;
        continue;
      }
      if (current != null && _sameShared(current, item)) continue;
      // Personal fields stay this user's (defaults for a new item).
      updates[doc.id] = item.asSharedWithMe(current?.personalJson());
    }
    if (sharingDisposed || uid != sharingUid) return;
    _applyLive(updates);
  }

  Future<void> _onOwnShared(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    if (sharingDisposed || uid != sharingUid) return;
    final updates = <String, T?>{};
    for (final change in snap.docChanges) {
      final doc = change.doc;
      final current = itemById(doc.id);
      if (change.type == DocumentChangeType.removed) {
        // Deleted from another device. A document also leaves this query
        // when an item no longer shared is saved as a plain one (without
        // `ownerId`): that item stays, like every unshared item, which is
        // not live.
        if (current != null && current.isShared) updates[doc.id] = null;
        continue;
      }
      if (doc.metadata.hasPendingWrites) continue;
      final data = await decodeDoc(doc);
      if (data == null) continue;
      final item = sharedFromJson(data);
      if (current != null &&
          _sameShared(current, item) &&
          jsonEncode(current.toJson()) == jsonEncode(item.toJson())) {
        continue;
      }
      updates[doc.id] = item;
    }
    if (sharingDisposed || uid != sharingUid) return;
    _applyLive(updates);
  }

  // ── Collaborators ─────────────────────────────────────────────────────────

  /// Shares the own item [id] with the Taskenda user signed up with [email].
  /// Throws [ShareException] if nobody uses Taskenda with that email, it is
  /// the current user's or they already are a collaborator.
  Future<ShareMember> addCollaborator(String id, String email) async {
    final me = ref.read(currentShareMemberProvider);
    final item = itemById(id);
    if (me == null || item == null || item.isForeignTo(sharingUid)) {
      throw StateError('Only the owner can share an item');
    }
    final key = normalizeEmail(email);
    if (key == normalizeEmail(me.email)) {
      throw const ShareException(ShareError.self);
    }
    if (item.collaborators.any((c) => normalizeEmail(c.email) == key)) {
      throw const ShareException(ShareError.alreadyAdded);
    }
    final member = await ref.read(userDirectoryProvider).lookup(key);
    if (member == null) throw const ShareException(ShareError.notFound);
    if (member.uid == sharingUid) throw const ShareException(ShareError.self);
    // Re-read: the item may have changed during the lookup.
    final current = itemById(id);
    if (current == null) throw StateError('Item deleted meanwhile');
    if (current.collaborators.any((c) => c.uid == member.uid)) {
      throw const ShareException(ShareError.alreadyAdded);
    }
    final uid = sharingUid;
    final updated = current.withSharing(
      Sharing(
        ownerId: uid,
        owner: me,
        collaborators: [...current.collaborators, member],
      ),
    );
    await mutate(
      (list) => [for (final i in list) i.id == id ? updated : i],
      () => ownCollection.doc(id).update({
        // Shared items are in clear for now: the content is written again
        // without the encrypted fields.
        if (cipher.encrypts && !current.isShared) ...{
          ...current.toJson(),
          ...ItemCipher.clearCodecFields,
        },
        'ownerId': uid,
        'owner': me.toProfileJson(),
        'collaborators': FieldValue.arrayUnion([member.uid]),
        'collaboratorProfiles.${member.uid}': member.toProfileJson(),
      }),
    );
    return member;
  }

  /// Stops sharing the own item [id] with [collaboratorUid].
  Future<void> removeCollaborator(String id, String collaboratorUid) async {
    final item = itemById(id);
    if (item == null || item.isForeignTo(sharingUid) || item.ownerId == null) {
      throw StateError('Only the owner can unshare an item');
    }
    final updated = item.withSharing(
      Sharing(
        ownerId: item.ownerId,
        owner: item.owner,
        collaborators: [
          for (final c in item.collaborators)
            if (c.uid != collaboratorUid) c,
        ],
      ),
    );
    await mutate(
      (list) => [for (final i in list) i.id == id ? updated : i],
      () => ownCollection.doc(id).update(_leaveData(collaboratorUid)),
    );
  }

  /// [items] restored from a backup: the own ones keep their collaborators
  /// (backups don't carry them). Returns the new state, the ids of own items
  /// to delete and the restored items to write.
  ({List<T> state, List<String> stale, List<T> restored}) restoreKeepingShared(
    List<T> items,
  ) {
    final uid = sharingUid;
    final restored = items.map(withCurrentSharing).toList();
    final keep = {for (final i in restored) i.id};
    return (
      state: [
        ...restored,
        for (final i in state)
          if (!keep.contains(i.id) && i.isForeignTo(uid)) i,
      ],
      stale: [
        for (final i in state)
          if (!keep.contains(i.id) && !i.isForeignTo(uid)) i.id,
      ],
      restored: restored,
    );
  }
}

/// The signed-in user's own items among [items] (without those shared with
/// them): what backups and exports contain.
List<T> ownItems<T extends Shareable<T>>(List<T> items, String uid) => [
  for (final i in items)
    if (!i.isForeignTo(uid)) i,
];
