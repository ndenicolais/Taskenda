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

/// Turns a model's JSON into an encrypted Firestore document and back.
///
/// Encrypted document layout (see `guides/E2EE_PLAN.md` §5):
///
/// ```
/// { ...clear fields,             // personal flags, dates, ids
///   e: 1,                        // schema version
///   enc:  {n, c},                // the shared content, as one JSON object
///   priv: {n, c},                // owner-only sensitive fields (optional)
///   keys: { <uid>: {t, …} },     // the item key, wrapped for each member
///   keyVer: 1 }                  // bumped on every key rotation
/// ```
///
/// Notes, tasks and events have their own item key; labels and task lists
/// are encrypted directly with the master key (they are never shared) and
/// have no `keys`. Each ciphertext is bound to its collection, document id
/// and field through the AAD, so it can't be moved elsewhere.
class ItemCodec {
  ItemCodec(this._crypto);

  final CryptoService _crypto;

  static const schemaVersion = 1;

  static const versionField = 'e';
  static const contentField = 'enc';
  static const privateField = 'priv';
  static const keysField = 'keys';
  static const keyVersionField = 'keyVer';

  /// Item key wrapped with the member's master key (the owner's entry).
  static const masterKeyEntry = 'mk';

  /// Item key sealed for the member's X25519 public key (collaborators).
  static const sealedKeyEntry = 'x25519';

  /// The fields that never go into a ciphertext: the codec's own.
  static const _codecFields = {
    versionField,
    contentField,
    privateField,
    keysField,
    keyVersionField,
  };

  static String aad(String collection, String id, String part) =>
      'taskenda:v1:$collection:$id:$part';

  /// True if [data] is a document written by this codec (false for
  /// documents still in clear, from before the migration).
  static bool isEncrypted(Map<String, dynamic> data) =>
      data[versionField] == schemaVersion;

  /// The [sharedKeys] of a model that go into [contentField]: all but
  /// `updatedAt`, which stays in clear for ordering and conflict checks.
  static List<String> contentKeys(List<String> sharedKeys) => [
    for (final k in sharedKeys)
      if (k != 'updatedAt') k,
  ];

  // ── Documents ─────────────────────────────────────────────────────────────

  /// The Firestore data for [json]: [contentKeys] encrypted in
  /// [contentField], [privateKeys] (if any) in [privateField], everything
  /// else in clear. A key absent from [json] is simply absent from the
  /// ciphertext. The caller adds [keysField] and [keyVersionField].
  Future<Map<String, dynamic>> encode({
    required String collection,
    required String id,
    required Map<String, dynamic> json,
    required List<String> contentKeys,
    List<String> privateKeys = const [],
    required SecretKey key,
  }) async {
    final encrypted = {...contentKeys, ...privateKeys};
    return {
      for (final e in json.entries)
        if (!encrypted.contains(e.key) && !_codecFields.contains(e.key))
          e.key: e.value,
      versionField: schemaVersion,
      contentField:
          (await encryptFields(
            collection: collection,
            id: id,
            json: json,
            keys: contentKeys,
            key: key,
          )).toJson(),
      if (privateKeys.isNotEmpty)
        privateField:
            (await _encryptPart(collection, id, privateField, {
              for (final k in privateKeys)
                if (json.containsKey(k)) k: json[k],
            }, key)).toJson(),
    };
  }

  /// The [keys] of [json] encrypted as the [contentField] blob: what a
  /// collaborator writes when they change a shared item.
  Future<EncryptedBlob> encryptFields({
    required String collection,
    required String id,
    required Map<String, dynamic> json,
    required List<String> keys,
    required SecretKey key,
  }) => _encryptPart(collection, id, contentField, {
    for (final k in keys)
      if (json.containsKey(k)) k: json[k],
  }, key);

  /// The model JSON of the Firestore [data]: its clear fields with the
  /// decrypted ones merged in, without the codec's fields. A document still
  /// in clear is returned unchanged.
  Future<Map<String, dynamic>> decode({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    required SecretKey key,
  }) async {
    if (!isEncrypted(data)) return data;
    final content = await _decryptPart(
      collection,
      id,
      contentField,
      data[contentField],
      key,
    );
    final private =
        data[privateField] == null
            ? const <String, dynamic>{}
            : await _decryptPart(
              collection,
              id,
              privateField,
              data[privateField],
              key,
            );
    return {
      for (final e in data.entries)
        if (!_codecFields.contains(e.key)) e.key: e.value,
      ...private,
      ...content,
    };
  }

  Future<EncryptedBlob> _encryptPart(
    String collection,
    String id,
    String part,
    Map<String, dynamic> json,
    SecretKey key,
  ) => _crypto.encryptJson(json, key, aad: aad(collection, id, part));

  Future<Map<String, dynamic>> _decryptPart(
    String collection,
    String id,
    String part,
    Object? blob,
    SecretKey key,
  ) => _crypto.decryptJson(
    EncryptedBlob.fromJson(blob),
    key,
    aad: aad(collection, id, part),
  );

  // ── Item keys ─────────────────────────────────────────────────────────────

  /// The [keysField] entry giving [uid] the [itemKey], wrapped with their
  /// [masterKey] (the owner).
  Future<Map<String, dynamic>> masterKeyEntryFor({
    required String collection,
    required String id,
    required String uid,
    required SecretKey itemKey,
    required SecretKey masterKey,
  }) async => {
    't': masterKeyEntry,
    ...(await _crypto.wrapKey(
      itemKey,
      masterKey,
      aad: aad(collection, id, 'key:$uid'),
    )).toJson(),
  };

  /// The [keysField] entry giving [uid] the [itemKey], sealed for their
  /// [publicKey] (a collaborator).
  Future<Map<String, dynamic>> sealedKeyEntryFor({
    required String collection,
    required String id,
    required String uid,
    required SecretKey itemKey,
    required List<int> publicKey,
  }) async => {
    't': sealedKeyEntry,
    ...(await _crypto.sealKey(
      itemKey,
      publicKey,
      aad: aad(collection, id, 'key:$uid'),
    )).toJson(),
  };

  /// The item key of the document [data] for [uid], from their entry in
  /// [keysField]: opened with [masterKey] or [keyPair] depending on its
  /// type. Throws [CryptoException] if there is no entry or it can't be
  /// opened.
  Future<SecretKey> openItemKey({
    required String collection,
    required String id,
    required String uid,
    required Map<String, dynamic> data,
    required SecretKey masterKey,
    required SimpleKeyPair keyPair,
  }) {
    final keys = data[keysField];
    final entry = keys is Map ? keys[uid] : null;
    if (entry is! Map) {
      throw const CryptoException('No item key for this user');
    }
    final entryAad = aad(collection, id, 'key:$uid');
    return switch (entry['t']) {
      masterKeyEntry => _crypto.unwrapKey(
        EncryptedBlob.fromJson(entry),
        masterKey,
        aad: entryAad,
      ),
      sealedKeyEntry => _crypto.openSealedKey(
        SealedKey.fromJson(entry),
        keyPair,
        aad: entryAad,
      ),
      _ => throw const CryptoException('Unknown item key type'),
    };
  }
}
