// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'crypto_service.dart';

/// A user's keys once unlocked: the master key (wraps their item keys,
/// encrypts labels and lists) and the X25519 key pair (opens the item keys
/// collaborators seal for them).
@immutable
class UnlockedKeys {
  const UnlockedKeys({
    required this.masterKey,
    required this.keyPair,
    required this.publicKey,
  });

  final SecretKey masterKey;
  final SimpleKeyPair keyPair;
  final Uint8List publicKey;
}

/// The user's keys as stored in `users/{uid}/crypto/keys`: nothing in it can
/// be used without the passphrase or the recovery key.
///
/// `{v, kdf, mk_pass, mk_recovery, sk, pk}`: the master key wrapped with
/// the passphrase key and with the recovery key, the private key wrapped
/// with the master key, and the public key (also in `public_keys/{uid}`).
@immutable
class UserKeyBundle {
  const UserKeyBundle({
    required this.kdf,
    required this.passphraseWrapped,
    required this.recoveryWrapped,
    required this.privateKeyWrapped,
    required this.publicKey,
  });

  static const version = 1;

  final KdfParams kdf;
  final EncryptedBlob passphraseWrapped;
  final EncryptedBlob recoveryWrapped;
  final EncryptedBlob privateKeyWrapped;
  final Uint8List publicKey;

  UserKeyBundle copyWith({
    KdfParams? kdf,
    EncryptedBlob? passphraseWrapped,
    EncryptedBlob? recoveryWrapped,
  }) => UserKeyBundle(
    kdf: kdf ?? this.kdf,
    passphraseWrapped: passphraseWrapped ?? this.passphraseWrapped,
    recoveryWrapped: recoveryWrapped ?? this.recoveryWrapped,
    privateKeyWrapped: privateKeyWrapped,
    publicKey: publicKey,
  );

  Map<String, dynamic> toJson() => {
    'v': version,
    'kdf': kdf.toJson(),
    'mk_pass': passphraseWrapped.toJson(),
    'mk_recovery': recoveryWrapped.toJson(),
    'sk': privateKeyWrapped.toJson(),
    'pk': base64Encode(publicKey),
  };

  factory UserKeyBundle.fromJson(Map<String, dynamic> json) {
    if (json['v'] != version || json['pk'] is! String) {
      throw const CryptoException('Unsupported key bundle');
    }
    return UserKeyBundle(
      kdf: KdfParams.fromJson(json['kdf']),
      passphraseWrapped: EncryptedBlob.fromJson(json['mk_pass']),
      recoveryWrapped: EncryptedBlob.fromJson(json['mk_recovery']),
      privateKeyWrapped: EncryptedBlob.fromJson(json['sk']),
      publicKey: base64Decode(json['pk'] as String),
    );
  }
}

/// What [UserKeyManager.create] returns: the bundle to store, the keys,
/// and the recovery key to show to the user once.
typedef NewUserKeys =
    ({UserKeyBundle bundle, UnlockedKeys keys, Uint8List recoveryKey});

/// Creates, unlocks and re-wraps a user's keys. Pure: storing the bundle
/// (Firestore) and the unlocked keys (device) is up to the caller.
class UserKeyManager {
  UserKeyManager(this._crypto, {this.iterations = KdfParams.defaultIterations});

  final CryptoService _crypto;

  /// PBKDF2 iterations for new bundles; tests lower it.
  final int iterations;

  static String _aad(String uid, String part) => 'taskenda:v1:user:$uid:$part';

  /// New keys for [uid], protected by [passphrase] and a new recovery key.
  Future<NewUserKeys> create(String uid, String passphrase) async {
    final masterKey = await _crypto.newSecretKey();
    final keyPair = await _crypto.newKeyPair();
    final publicKey = await _crypto.publicKeyBytes(keyPair);
    final recoveryKey = _crypto.newRecoveryKey();
    final kdf = _crypto.newKdfParams(iterations: iterations);

    final bundle = UserKeyBundle(
      kdf: kdf,
      passphraseWrapped: await _crypto.wrapKey(
        masterKey,
        await _crypto.deriveKek(passphrase, kdf),
        aad: _aad(uid, 'mk_pass'),
      ),
      recoveryWrapped: await _crypto.wrapKey(
        masterKey,
        await _crypto.deriveRecoveryKek(recoveryKey),
        aad: _aad(uid, 'mk_recovery'),
      ),
      privateKeyWrapped: await _crypto.encrypt(
        await _crypto.privateKeyBytes(keyPair),
        masterKey,
        aad: _aad(uid, 'sk'),
      ),
      publicKey: publicKey,
    );
    return (
      bundle: bundle,
      keys: UnlockedKeys(
        masterKey: masterKey,
        keyPair: keyPair,
        publicKey: publicKey,
      ),
      recoveryKey: recoveryKey,
    );
  }

  /// The keys of [bundle]; throws [CryptoException] if [passphrase] is
  /// wrong.
  Future<UnlockedKeys> unlockWithPassphrase(
    String uid,
    UserKeyBundle bundle,
    String passphrase,
  ) async {
    final masterKey = await _crypto.unwrapKey(
      bundle.passphraseWrapped,
      await _crypto.deriveKek(passphrase, bundle.kdf),
      aad: _aad(uid, 'mk_pass'),
    );
    return _withKeyPair(uid, bundle, masterKey);
  }

  /// The keys of [bundle]; throws [CryptoException] if [recoveryKey] is
  /// not this account's.
  Future<UnlockedKeys> unlockWithRecoveryKey(
    String uid,
    UserKeyBundle bundle,
    Uint8List recoveryKey,
  ) async {
    final masterKey = await _crypto.unwrapKey(
      bundle.recoveryWrapped,
      await _crypto.deriveRecoveryKek(recoveryKey),
      aad: _aad(uid, 'mk_recovery'),
    );
    return _withKeyPair(uid, bundle, masterKey);
  }

  Future<UnlockedKeys> _withKeyPair(
    String uid,
    UserKeyBundle bundle,
    SecretKey masterKey,
  ) async {
    final keyPair = await _crypto.keyPairFromPrivateBytes(
      await _crypto.decrypt(
        bundle.privateKeyWrapped,
        masterKey,
        aad: _aad(uid, 'sk'),
      ),
    );
    return UnlockedKeys(
      masterKey: masterKey,
      keyPair: keyPair,
      publicKey: bundle.publicKey,
    );
  }

  /// [bundle] protected by [passphrase] instead (new salt): the master key
  /// doesn't change, so no data has to be encrypted again.
  Future<UserKeyBundle> withPassphrase(
    String uid,
    UserKeyBundle bundle,
    UnlockedKeys keys,
    String passphrase,
  ) async {
    final kdf = _crypto.newKdfParams(iterations: iterations);
    return bundle.copyWith(
      kdf: kdf,
      passphraseWrapped: await _crypto.wrapKey(
        keys.masterKey,
        await _crypto.deriveKek(passphrase, kdf),
        aad: _aad(uid, 'mk_pass'),
      ),
    );
  }

  /// [bundle] with a new recovery key (the old one stops working).
  Future<({UserKeyBundle bundle, Uint8List recoveryKey})> withNewRecoveryKey(
    String uid,
    UserKeyBundle bundle,
    UnlockedKeys keys,
  ) async {
    final recoveryKey = _crypto.newRecoveryKey();
    return (
      bundle: bundle.copyWith(
        recoveryWrapped: await _crypto.wrapKey(
          keys.masterKey,
          await _crypto.deriveRecoveryKek(recoveryKey),
          aad: _aad(uid, 'mk_recovery'),
        ),
      ),
      recoveryKey: recoveryKey,
    );
  }

  // ── Device storage ────────────────────────────────────────────────────────

  /// [keys] as a string for the device's secure storage.
  Future<String> exportForDevice(UnlockedKeys keys) async => jsonEncode({
    'mk': base64Encode(await _crypto.secretKeyBytes(keys.masterKey)),
    'sk': base64Encode(await _crypto.privateKeyBytes(keys.keyPair)),
  });

  /// The keys saved by [exportForDevice]; throws [CryptoException] if
  /// [stored] is malformed.
  Future<UnlockedKeys> importFromDevice(String stored) async {
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      final keyPair = await _crypto.keyPairFromPrivateBytes(
        base64Decode(json['sk'] as String),
      );
      return UnlockedKeys(
        masterKey: _crypto.secretKeyFromBytes(
          base64Decode(json['mk'] as String),
        ),
        keyPair: keyPair,
        publicKey: await _crypto.publicKeyBytes(keyPair),
      );
    } on CryptoException {
      rethrow;
    } catch (_) {
      throw const CryptoException('Malformed stored keys');
    }
  }
}
