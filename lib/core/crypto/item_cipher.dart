// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:cryptography/cryptography.dart';

import 'crypto_service.dart';
import 'item_codec.dart';
import 'user_keys.dart';

/// What the data notifiers use to turn their models into Firestore
/// documents and back, once the user's keys are unlocked (see
/// `itemCipherProvider`).
///
/// A note, task or event has its own item key, wrapped in `keys.<uid>` for
/// each member: with the master key for the owner, sealed for the public
/// key of each collaborator. The key of a document is cached once it has
/// been read or written, by its version (`keyVer`).
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

  /// The whole document of an own item that isn't shared: [contentKeys] and
  /// [privateKeys] encrypted with its item key (a new one the first time),
  /// wrapped with the master key in `keys.<uid>`.
  Future<Map<String, dynamic>> encodeItem(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
  });

  /// The document for a label or task list (or a collaborator's personal
  /// fields): [contentKeys] encrypted with the master key, no item key.
  Future<Map<String, dynamic>> encodeNamed(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
  });

  /// The version of the item key known for [collection]/[id], null if the
  /// item was never read or written encrypted (a document in clear).
  int? keyVersion(String collection, String id);

  /// The encrypted fields (`e`, `enc`, `priv`) of [json] with the known
  /// item key, without `keys`: the owner's update of a shared item.
  Future<Map<String, dynamic>> encodeContent(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
  });

  /// The `enc` blob of [json] with the known item key: what a collaborator
  /// writes when they edit a shared item.
  Future<Map<String, dynamic>> encryptSharedContent(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
  });

  /// The `keys.<recipientUid>` entry giving the known item key to the owner
  /// of [publicKey].
  Future<Map<String, dynamic>> sealItemKey(
    String collection,
    String id, {
    required String recipientUid,
    required List<int> publicKey,
  });

  /// A new item key for [collection]/[id] (next version): the whole
  /// encrypted document, with `keys` for this user (the owner) and for each
  /// of [recipients] (uid → public key). Used when a collaborator is removed
  /// or left, and to encrypt a shared item still in clear.
  Future<Map<String, dynamic>> rotate(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
    required Map<String, List<int>> recipients,
  });

  /// Forgets what is cached for [collection]/[id] (deleted item).
  void forget(String collection, String id);
}

/// The [ItemCipher] of user [uid] with their unlocked [keys].
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
  /// this user's master-key entry for it (reused while the key is the same;
  /// null for a collaborator, whose entry is sealed).
  final _itemKeys =
      <String, ({SecretKey key, int version, Map<String, dynamic>? entry})>{};

  static const _firstKeyVersion = 1;

  @override
  bool get encrypts => true;

  static String _cacheKey(String collection, String id) => '$collection/$id';

  ({SecretKey key, int version, Map<String, dynamic>? entry}) _known(
    String collection,
    String id,
  ) {
    final cached = _itemKeys[_cacheKey(collection, id)];
    if (cached == null) {
      throw StateError('No item key for $collection/$id');
    }
    return cached;
  }

  @override
  int? keyVersion(String collection, String id) =>
      _itemKeys[_cacheKey(collection, id)]?.version;

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
      entry:
          entry is Map && entry['t'] == ItemCodec.masterKeyEntry
              ? Map<String, dynamic>.from(entry)
              : null,
    );
    return key;
  }

  Future<Map<String, dynamic>> _masterEntry(
    String collection,
    String id,
    SecretKey itemKey,
  ) => _codec.masterKeyEntryFor(
    collection: collection,
    id: id,
    uid: uid,
    itemKey: itemKey,
    masterKey: keys.masterKey,
  );

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
    if (cached == null || cached.entry == null) {
      final key = cached?.key ?? await _codec.newItemKey();
      cached = (
        key: key,
        version: cached?.version ?? _firstKeyVersion,
        entry: await _masterEntry(collection, id, key),
      );
      _itemKeys[cacheKey] = cached;
    }
    return {
      ...await encodeContent(
        collection,
        id,
        json,
        contentKeys: contentKeys,
        privateKeys: privateKeys,
      ),
      ItemCodec.keysField: {uid: cached.entry},
      ItemCodec.keyVersionField: cached.version,
    };
  }

  @override
  Future<Map<String, dynamic>> encodeContent(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
  }) => _codec.encode(
    collection: collection,
    id: id,
    json: json,
    contentKeys: contentKeys,
    privateKeys: privateKeys,
    key: _known(collection, id).key,
  );

  @override
  Future<Map<String, dynamic>> encryptSharedContent(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
  }) async =>
      (await _codec.encryptFields(
        collection: collection,
        id: id,
        json: json,
        keys: contentKeys,
        key: _known(collection, id).key,
      )).toJson();

  @override
  Future<Map<String, dynamic>> sealItemKey(
    String collection,
    String id, {
    required String recipientUid,
    required List<int> publicKey,
  }) => _codec.sealedKeyEntryFor(
    collection: collection,
    id: id,
    uid: recipientUid,
    itemKey: _known(collection, id).key,
    publicKey: publicKey,
  );

  @override
  Future<Map<String, dynamic>> rotate(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
    required Map<String, List<int>> recipients,
  }) async {
    final cacheKey = _cacheKey(collection, id);
    final previous = _itemKeys[cacheKey];
    final key = await _codec.newItemKey();
    final version = (previous?.version ?? 0) + 1;
    final ownerEntry = await _masterEntry(collection, id, key);
    _itemKeys[cacheKey] = (key: key, version: version, entry: ownerEntry);
    try {
      return {
        ...await encodeContent(
          collection,
          id,
          json,
          contentKeys: contentKeys,
          privateKeys: privateKeys,
        ),
        ItemCodec.keysField: {
          uid: ownerEntry,
          for (final r in recipients.entries)
            r.key: await sealItemKey(
              collection,
              id,
              recipientUid: r.key,
              publicKey: r.value,
            ),
        },
        ItemCodec.keyVersionField: version,
      };
    } catch (_) {
      // Not written: the document still has the previous key.
      if (previous == null) {
        _itemKeys.remove(cacheKey);
      } else {
        _itemKeys[cacheKey] = previous;
      }
      rethrow;
    }
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

/// Thrown when a collaborator has no public key yet (they haven't set up
/// encryption, e.g. an old app version): nothing can be sealed for them.
class MissingPublicKeyException extends CryptoException {
  const MissingPublicKeyException(this.uid) : super('No public key for $uid');

  final String uid;
}
