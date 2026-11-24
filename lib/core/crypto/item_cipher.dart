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
import 'package:cryptography/cryptography.dart';

import 'item_codec.dart';
import 'user_keys.dart';

/// What the data notifiers use to turn their models into Firestore
/// documents and back, once the user's keys are unlocked (see
/// `itemCipherProvider`).
abstract class ItemCipher {
  /// False for a cipher that stores documents in clear (tests).
  bool get encrypts;

  /// The model JSON of the document [data] of [collection]/[id]: decrypted
  /// if it was encrypted, unchanged otherwise. Throws a `CryptoException` if
  /// it can't be decrypted with this user's keys.
  Future<Map<String, dynamic>> decode(
    String collection,
    String id,
    Map<String, dynamic> data,
  );

  /// The document for a note, task or event: [contentKeys] and
  /// [privateKeys] encrypted with the item's own key, which is wrapped with
  /// the master key in `keys.<uid>`.
  Future<Map<String, dynamic>> encodeItem(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
  });

  /// The document for a label or task list: [contentKeys] encrypted with
  /// the master key (never shared, so no item key).
  Future<Map<String, dynamic>> encodeNamed(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
  });

  /// Forgets what is cached for [collection]/[id] (deleted item).
  void forget(String collection, String id);

  /// Fields to delete when an item is written in clear over a document
  /// that may have been encrypted (an item being shared, until phase 4 of
  /// `guides/E2EE_PLAN.md` encrypts shared items too).
  static Map<String, Object> get clearCodecFields => {
    ItemCodec.versionField: FieldValue.delete(),
    ItemCodec.contentField: FieldValue.delete(),
    ItemCodec.privateField: FieldValue.delete(),
    ItemCodec.keysField: FieldValue.delete(),
    ItemCodec.keyVersionField: FieldValue.delete(),
  };
}

/// The [ItemCipher] of user [uid] with their unlocked [keys]. Item keys are
/// cached by document, so an item is encrypted again with the same key and
/// an unchanged key entry isn't unwrapped at every snapshot.
class EncryptingItemCipher implements ItemCipher {
  EncryptingItemCipher({
    required this.uid,
    required this.keys,
    required ItemCodec codec,
  }) : _codec = codec;

  final String uid;
  final UnlockedKeys keys;
  final ItemCodec _codec;

  /// `collection/id` → the item key, the key version it belongs to and
  /// this user's entry for it in `keys` (reused while the key is the same).
  final _itemKeys =
      <String, ({SecretKey key, int version, Map<String, dynamic>? entry})>{};

  static const _firstKeyVersion = 1;

  @override
  bool get encrypts => true;

  static String _cacheKey(String collection, String id) => '$collection/$id';

  @override
  Future<Map<String, dynamic>> decode(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!ItemCodec.isEncrypted(data)) return data;
    final key =
        data[ItemCodec.keysField] == null
            ? keys.masterKey
            : await _openItemKey(collection, id, data);
    return _codec.decode(collection: collection, id: id, data: data, key: key);
  }

  Future<SecretKey> _openItemKey(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final version =
        (data[ItemCodec.keyVersionField] as num?)?.toInt() ?? _firstKeyVersion;
    final cacheKey = _cacheKey(collection, id);
    final cached = _itemKeys[cacheKey];
    if (cached != null && cached.version == version) return cached.key;
    final key = await _codec.openItemKey(
      collection: collection,
      id: id,
      uid: uid,
      data: data,
      masterKey: keys.masterKey,
      keyPair: keys.keyPair,
    );
    final entry = (data[ItemCodec.keysField] as Map)[uid];
    _itemKeys[cacheKey] = (
      key: key,
      version: version,
      entry: entry is Map ? Map<String, dynamic>.from(entry) : null,
    );
    return key;
  }

  @override
  Future<Map<String, dynamic>> encodeItem(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
  }) async {
    final cacheKey = _cacheKey(collection, id);
    var cached = _itemKeys[cacheKey];
    if (cached == null) {
      cached = (
        key: await _codec.newItemKey(),
        version: _firstKeyVersion,
        entry: null,
      );
      _itemKeys[cacheKey] = cached;
    }
    var entry = cached.entry;
    if (entry == null || entry['t'] != ItemCodec.masterKeyEntry) {
      entry = await _codec.masterKeyEntryFor(
        collection: collection,
        id: id,
        uid: uid,
        itemKey: cached.key,
        masterKey: keys.masterKey,
      );
      _itemKeys[cacheKey] = (
        key: cached.key,
        version: cached.version,
        entry: entry,
      );
    }
    return {
      ...await _codec.encode(
        collection: collection,
        id: id,
        json: json,
        contentKeys: contentKeys,
        privateKeys: privateKeys,
        key: cached.key,
      ),
      ItemCodec.keysField: {uid: entry},
      ItemCodec.keyVersionField: cached.version,
    };
  }

  @override
  Future<Map<String, dynamic>> encodeNamed(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
  }) => _codec.encode(
    collection: collection,
    id: id,
    json: json,
    contentKeys: contentKeys,
    key: keys.masterKey,
  );

  @override
  void forget(String collection, String id) =>
      _itemKeys.remove(_cacheKey(collection, id));
}
