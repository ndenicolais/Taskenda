// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/crypto/item_cipher.dart';
import '../core/crypto/item_codec.dart';
import '../models/label_model.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'crypto_provider.dart';
import 'sync_provider.dart';

/// SharedPreferences key where older versions kept the labels, only on the
/// device.
const legacyLabelsPrefsKey = 'custom_labels';

/// The user's labels, synced in `users/{uid}/labels` so they follow the
/// account to other devices. Renaming or deleting a label on the notes that
/// use it is up to `NotesNotifier.renameTag`/`deleteTag`.
class LabelsNotifier extends Notifier<List<LabelModel>>
    with FirestoreListMutations<LabelModel> {
  late String _uid;

  ItemCipher? _cipher;

  static const _collection = 'labels';
  static const _encryptedKeys = ['name'];

  @override
  List<LabelModel> build() {
    // Nothing loads until the keys are unlocked: as if signed out.
    _cipher = ref.watch(itemCipherProvider);
    _uid = _cipher == null ? '' : ref.watch(currentUidProvider);
    ref.watch(firestoreProvider);
    _load().ignore();
    return [];
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      db.collection('users').doc(_uid).collection('labels');

  static String _id(LabelModel l) => l.id;

  Future<LabelModel?> _parse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = Map<String, dynamic>.from(
        await _cipher!.decode(_collection, doc.id, doc.data()),
      );
      data['id'] = doc.id;
      return LabelModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('$_collection/${doc.id} unreadable: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _encode(LabelModel l) => _cipher!.encodeNamed(
    _collection,
    l.id,
    l.toJson(),
    contentKeys: _encryptedKeys,
  );

  /// Writes again, encrypted, the labels of [docs] still stored in clear.
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
      if (kDebugMode) debugPrint('Labels not encrypted yet: $e');
    }
  }

  /// Re-fetches all labels from Firestore, replacing local state.
  @override
  Future<void> reload() => _load(replace: true);

  Future<void> _load({bool replace = false}) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    // Cached labels first: get() alone waits for the server.
    final seeded =
        replace
            ? const <String, LabelModel>{}
            : await seedFromCache(_col, _parse, _id, () => uid != _uid);
    final snap = await _col.get();
    if (uid != _uid) return;
    final labels = await parseDocs(snap.docs, _parse);
    state = replace ? labels : reconcileInitialLoad(labels, seeded, _id);
    _encryptLegacy(snap.docs).ignore();
    // Shared by overlapping loads, so the labels aren't migrated twice.
    await (_migration ??= _migrateLocalLabels().whenComplete(
      () => _migration = null,
    ));
  }

  Future<void>? _migration;

  /// Moves the labels that older versions kept only on this device into
  /// Firestore, then forgets the local copy.
  Future<void> _migrateLocalLabels() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final local = prefs.getStringList(legacyLabelsPrefsKey);
    if (local == null) return;
    await addAll(local);
    await prefs.remove(legacyLabelsPrefsKey);
  }

  bool _exists(String name) => state.any((l) => l.name == name);

  /// Adds the labels in [names] that don't exist yet (trimmed, blanks
  /// skipped).
  Future<void> addAll(Iterable<String> names) async {
    final added = <LabelModel>[];
    for (final name in names.map((n) => n.trim())) {
      if (name.isEmpty || _exists(name) || added.any((l) => l.name == name)) {
        continue;
      }
      added.add(LabelModel(name: name));
    }
    if (added.isEmpty) return;
    await mutate(
      (current) => [...current, ...added],
      () => commitInChunks([
        for (final l in added)
          (WriteBatch b) async => b.set(_col.doc(l.id), await _encode(l)),
      ]),
    );
  }

  Future<void> add(String name) => addAll([name]);

  /// Renames [oldName] to [newName]; if a label called [newName] already
  /// exists the two are merged.
  Future<void> rename(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    final label = state.where((l) => l.name == oldName).firstOrNull;
    if (label == null) return add(trimmed);
    if (_exists(trimmed)) return delete(oldName);
    final updated = label.copyWith(name: trimmed);
    await mutate(
      (current) => current.map((l) => l.id == label.id ? updated : l).toList(),
      () async => _col.doc(label.id).set(await _encode(updated)),
    );
  }

  Future<void> delete(String name) async {
    final ids = state.where((l) => l.name == name).map((l) => l.id).toList();
    if (ids.isEmpty) return;
    await mutate(
      (current) => current.where((l) => l.name != name).toList(),
      () => commitInChunks([
        for (final id in ids) (WriteBatch b) => b.delete(_col.doc(id)),
      ]),
    );
  }
}

final labelsProvider = NotifierProvider<LabelsNotifier, List<LabelModel>>(
  LabelsNotifier.new,
);
