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
import 'passkey_client.dart';

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

/// The passkey that was used isn't one of those that protect the keys
/// (e.g. one created before encryption was reset).
class UnknownPasskeyException extends CryptoException {
  const UnknownPasskeyException() : super('Unknown passkey');
}

/// The user's keys as stored in `users/{uid}/crypto/keys`: nothing in it can
/// be used without one of the passkeys or the recovery key.
///
/// `{v: 2, salt, passkeys: {<credential id>: {n, c}}, mk_recovery?, sk, pk}`:
/// the PRF salt asked to every passkey, the master key wrapped with each
/// passkey's secret and (optionally) with the recovery key, the private key
/// wrapped with the master key, and the public key (also in
/// `public_keys/{uid}`).
///
/// A version 1 bundle (from when an encryption code protected the keys) is
/// read with no passkey: only its recovery key opens it, then a passkey is
/// added and it is saved as version 2.
@immutable
class UserKeyBundle {
  const UserKeyBundle({
    required this.prfSalt,
    required this.passkeysWrapped,
    required this.recoveryWrapped,
    required this.privateKeyWrapped,
    required this.publicKey,
  });

  static const version = 2;
  static const _legacyVersion = 1;

  /// Null only in a version 1 bundle.
  final Uint8List? prfSalt;

  /// Wrapped master key by passkey credential id.
  final Map<String, EncryptedBlob> passkeysWrapped;

  /// Null when the user hasn't created a recovery key.
  final EncryptedBlob? recoveryWrapped;
  final EncryptedBlob privateKeyWrapped;
  final Uint8List publicKey;

  bool get hasPasskey => passkeysWrapped.isNotEmpty;
  bool get hasRecoveryKey => recoveryWrapped != null;

  UserKeyBundle _copyWith({
    Uint8List? prfSalt,
    Map<String, EncryptedBlob>? passkeysWrapped,
    EncryptedBlob? recoveryWrapped,
  }) => UserKeyBundle(
    prfSalt: prfSalt ?? this.prfSalt,
    passkeysWrapped: passkeysWrapped ?? this.passkeysWrapped,
    recoveryWrapped: recoveryWrapped ?? this.recoveryWrapped,
    privateKeyWrapped: privateKeyWrapped,
    publicKey: publicKey,
  );

  Map<String, dynamic> toJson() => {
    'v': version,
    if (prfSalt != null) 'salt': base64Encode(prfSalt!),
    'passkeys': {
      for (final e in passkeysWrapped.entries) e.key: e.value.toJson(),
    },
    if (recoveryWrapped != null) 'mk_recovery': recoveryWrapped!.toJson(),
    'sk': privateKeyWrapped.toJson(),
    'pk': base64Encode(publicKey),
  };

  factory UserKeyBundle.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    if ((v != version && v != _legacyVersion) || json['pk'] is! String) {
      throw const CryptoException('Unsupported key bundle');
    }
    final salt = json['salt'];
    final passkeys = json['passkeys'];
    final recovery = json['mk_recovery'];
    return UserKeyBundle(
      prfSalt: v == version && salt is String ? base64Decode(salt) : null,
      passkeysWrapped: {
        if (v == version && passkeys is Map)
          for (final e in passkeys.entries)
            e.key as String: EncryptedBlob.fromJson(e.value),
      },
      recoveryWrapped:
          recovery == null ? null : EncryptedBlob.fromJson(recovery),
      privateKeyWrapped: EncryptedBlob.fromJson(json['sk']),
      publicKey: base64Decode(json['pk'] as String),
    );
  }
}

/// Creates, unlocks and re-wraps a user's keys. Pure: talking to the
/// passkey, storing the bundle (Firestore) and the unlocked keys (device)
/// is up to the caller.
class UserKeyManager {
  UserKeyManager(this._crypto);

  final CryptoService _crypto;

  static String _aad(String uid, String part) => 'taskenda:v1:user:$uid:$part';

  static String _passkeyAad(String uid, String credentialId) =>
      _aad(uid, 'mk_passkey:$credentialId');

  /// A new random PRF salt, to ask the first passkey with.
  Uint8List newPrfSalt() => CryptoService.randomBytes(CryptoService.prfLength);

  /// New keys for [uid], protected by [passkey] (whose secret is for
  /// [prfSalt]). No recovery key yet: see [withNewRecoveryKey].
  Future<({UserKeyBundle bundle, UnlockedKeys keys})> create(
    String uid, {
    required Uint8List prfSalt,
    required PasskeySecret passkey,
  }) async {
    final masterKey = await _crypto.newSecretKey();
    final keyPair = await _crypto.newKeyPair();
    final publicKey = await _crypto.publicKeyBytes(keyPair);
    final bundle = UserKeyBundle(
      prfSalt: prfSalt,
      passkeysWrapped: {
        passkey.credentialId: await _wrapForPasskey(uid, masterKey, passkey),
      },
      recoveryWrapped: null,
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
    );
  }

  /// The keys of [bundle] opened with [passkey]; throws
  /// [UnknownPasskeyException] if it isn't one of the bundle's passkeys,
  /// [CryptoException] if its secret is wrong.
  Future<UnlockedKeys> unlockWithPasskey(
    String uid,
    UserKeyBundle bundle,
    PasskeySecret passkey,
  ) async {
    final wrapped = bundle.passkeysWrapped[passkey.credentialId];
    if (wrapped == null) throw const UnknownPasskeyException();
    final masterKey = await _crypto.unwrapKey(
      wrapped,
      await _crypto.derivePasskeyKek(passkey.secret),
      aad: _passkeyAad(uid, passkey.credentialId),
    );
    return _withKeyPair(uid, bundle, masterKey);
  }

  /// The keys of [bundle]; throws [CryptoException] if [recoveryKey] is
  /// not this account's (or the account has none).
  Future<UnlockedKeys> unlockWithRecoveryKey(
    String uid,
    UserKeyBundle bundle,
    Uint8List recoveryKey,
  ) async {
    final wrapped = bundle.recoveryWrapped;
    if (wrapped == null) throw const CryptoException('No recovery key');
    final masterKey = await _crypto.unwrapKey(
      wrapped,
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

  Future<EncryptedBlob> _wrapForPasskey(
    String uid,
    SecretKey masterKey,
    PasskeySecret passkey,
  ) async => _crypto.wrapKey(
    masterKey,
    await _crypto.derivePasskeyKek(passkey.secret),
    aad: _passkeyAad(uid, passkey.credentialId),
  );

  /// [bundle] also opened by [passkey], whose secret is for [prfSalt]: the
  /// bundle's salt, or a new one for a version 1 bundle. The master key
  /// doesn't change, so no data has to be encrypted again.
  Future<UserKeyBundle> withPasskey(
    String uid,
    UserKeyBundle bundle,
    UnlockedKeys keys, {
    required Uint8List prfSalt,
    required PasskeySecret passkey,
  }) async => bundle._copyWith(
    prfSalt: prfSalt,
    passkeysWrapped: {
      ...bundle.passkeysWrapped,
      passkey.credentialId: await _wrapForPasskey(uid, keys.masterKey, passkey),
    },
  );

  /// [bundle] with a new recovery key (the old one, if any, stops working).
  Future<({UserKeyBundle bundle, Uint8List recoveryKey})> withNewRecoveryKey(
    String uid,
    UserKeyBundle bundle,
    UnlockedKeys keys,
  ) async {
    final recoveryKey = _crypto.newRecoveryKey();
    return (
      bundle: bundle._copyWith(
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
