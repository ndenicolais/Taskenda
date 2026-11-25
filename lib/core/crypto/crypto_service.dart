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

/// Thrown when data can't be decrypted: wrong key, data
/// tampered with or moved to another document (different AAD), or a
/// malformed blob.
class CryptoException implements Exception {
  const CryptoException(this.message);

  final String message;

  @override
  String toString() => 'CryptoException: $message';
}

/// AES-256-GCM ciphertext as stored in Firestore: `{n, c}`, both Base64,
/// where `c` is the ciphertext followed by the 16-byte MAC.
@immutable
class EncryptedBlob {
  const EncryptedBlob({required this.nonce, required this.cipherText});

  final Uint8List nonce;

  /// Ciphertext + MAC.
  final Uint8List cipherText;

  Map<String, dynamic> toJson() => {
    'n': base64Encode(nonce),
    'c': base64Encode(cipherText),
  };

  factory EncryptedBlob.fromJson(Object? json) {
    if (json is! Map || json['n'] is! String || json['c'] is! String) {
      throw const CryptoException('Malformed encrypted blob');
    }
    try {
      return EncryptedBlob(
        nonce: base64Decode(json['n'] as String),
        cipherText: base64Decode(json['c'] as String),
      );
    } on FormatException {
      throw const CryptoException('Malformed encrypted blob');
    }
  }
}

/// A secret key sealed for the owner of an X25519 public key: `{epk, n, c}`,
/// where `epk` is the sender's ephemeral public key.
@immutable
class SealedKey {
  const SealedKey({required this.ephemeralPublicKey, required this.blob});

  final Uint8List ephemeralPublicKey;
  final EncryptedBlob blob;

  Map<String, dynamic> toJson() => {
    'epk': base64Encode(ephemeralPublicKey),
    ...blob.toJson(),
  };

  factory SealedKey.fromJson(Object? json) {
    if (json is! Map || json['epk'] is! String) {
      throw const CryptoException('Malformed sealed key');
    }
    try {
      return SealedKey(
        ephemeralPublicKey: base64Decode(json['epk'] as String),
        blob: EncryptedBlob.fromJson(json),
      );
    } on FormatException {
      throw const CryptoException('Malformed sealed key');
    }
  }
}

/// The cryptographic primitives of Taskenda's end-to-end encryption, with
/// no Firebase or UI dependency (see `guides/E2EE_PLAN.md`):
///
/// - AES-256-GCM with a random 96-bit nonce and an AAD that binds every
///   ciphertext to where it is stored;
/// - HKDF-SHA256 from a passkey's PRF secret and from the recovery key;
/// - X25519 + HKDF-SHA256 + AES-256-GCM "sealed boxes" to hand item keys
///   to collaborators.
///
/// On Android and web, `cryptography_flutter` makes [Cryptography.instance]
/// use the platform implementations (Android crypto, WebCrypto).
class CryptoService {
  CryptoService({Cryptography? cryptography})
    : _c = cryptography ?? Cryptography.instance;

  final Cryptography _c;

  static const keyLength = 32;
  static const recoveryKeyLength = 32;

  static const _sealInfo = 'taskenda:v1:seal';
  static const _recoveryInfo = 'taskenda:v1:recovery';
  static const _passkeyInfo = 'taskenda:v1:passkey';

  /// Length of a passkey's PRF salt and of the secret it gives back.
  static const prfLength = 32;

  AesGcm get _aes => _c.aesGcm(secretKeyLength: keyLength);
  X25519 get _x25519 => _c.x25519();
  Hkdf get _hkdf => _c.hkdf(hmac: Hmac.sha256(), outputLength: keyLength);

  /// HKDF salt for the keys derived from an already random secret: HashLen
  /// zero bytes, what RFC 5869 uses for an empty salt (same keys), given
  /// explicitly because Android's native HMAC refuses an empty key.
  static final _zeroSalt = Uint8List(32);

  // ── Keys ──────────────────────────────────────────────────────────────────

  /// A random AES-256 key (master key, item key).
  Future<SecretKey> newSecretKey() => _aes.newSecretKey();

  /// A key from its raw bytes, e.g. read back from secure storage.
  SecretKey secretKeyFromBytes(List<int> bytes) {
    if (bytes.length != keyLength) {
      throw const CryptoException('Wrong key length');
    }
    return SecretKeyData(List<int>.of(bytes));
  }

  Future<Uint8List> secretKeyBytes(SecretKey key) async =>
      Uint8List.fromList(await key.extractBytes());

  /// The key-encryption key derived from a [recoveryKey] (already random,
  /// so no slow KDF is needed).
  Future<SecretKey> deriveRecoveryKek(Uint8List recoveryKey) {
    if (recoveryKey.length != recoveryKeyLength) {
      throw const CryptoException('Wrong recovery key length');
    }
    return _hkdf.deriveKey(
      secretKey: SecretKeyData(recoveryKey),
      nonce: _zeroSalt,
      info: utf8.encode(_recoveryInfo),
    );
  }

  /// The key-encryption key derived from a passkey's PRF [secret] (already
  /// random, so no slow KDF is needed).
  Future<SecretKey> derivePasskeyKek(Uint8List secret) {
    if (secret.length != prfLength) {
      throw const CryptoException('Wrong passkey secret length');
    }
    return _hkdf.deriveKey(
      secretKey: SecretKeyData(secret),
      nonce: _zeroSalt,
      info: utf8.encode(_passkeyInfo),
    );
  }

  /// A new X25519 key pair (one per user).
  Future<SimpleKeyPair> newKeyPair() => _x25519.newKeyPair();

  /// The key pair of a stored private key (its 32-byte seed).
  Future<SimpleKeyPair> keyPairFromPrivateBytes(List<int> bytes) {
    if (bytes.length != keyLength) {
      throw const CryptoException('Wrong private key length');
    }
    return _x25519.newKeyPairFromSeed(bytes);
  }

  Future<Uint8List> privateKeyBytes(SimpleKeyPair keyPair) async =>
      Uint8List.fromList(await keyPair.extractPrivateKeyBytes());

  Future<Uint8List> publicKeyBytes(SimpleKeyPair keyPair) async =>
      Uint8List.fromList((await keyPair.extractPublicKey()).bytes);

  // ── Symmetric encryption ──────────────────────────────────────────────────

  /// Encrypts [clearText] with [key]; [aad] must be given again to decrypt.
  Future<EncryptedBlob> encrypt(
    List<int> clearText,
    SecretKey key, {
    required String aad,
  }) async {
    final box = await _aes.encrypt(
      clearText,
      secretKey: key,
      aad: utf8.encode(aad),
    );
    return EncryptedBlob(
      nonce: Uint8List.fromList(box.nonce),
      cipherText: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
  }

  /// Decrypts [blob]; throws [CryptoException] if [key] or [aad] are wrong
  /// or the data was tampered with.
  Future<Uint8List> decrypt(
    EncryptedBlob blob,
    SecretKey key, {
    required String aad,
  }) async {
    const macLength = 16;
    final data = blob.cipherText;
    if (data.length < macLength) {
      throw const CryptoException('Malformed encrypted blob');
    }
    final box = SecretBox(
      data.sublist(0, data.length - macLength),
      nonce: blob.nonce,
      mac: Mac(data.sublist(data.length - macLength)),
    );
    try {
      return Uint8List.fromList(
        await _aes.decrypt(box, secretKey: key, aad: utf8.encode(aad)),
      );
    } on SecretBoxAuthenticationError {
      throw const CryptoException('Authentication failed');
    } on ArgumentError {
      throw const CryptoException('Malformed encrypted blob');
    }
  }

  Future<EncryptedBlob> encryptJson(
    Map<String, dynamic> json,
    SecretKey key, {
    required String aad,
  }) => encrypt(utf8.encode(jsonEncode(json)), key, aad: aad);

  Future<Map<String, dynamic>> decryptJson(
    EncryptedBlob blob,
    SecretKey key, {
    required String aad,
  }) async {
    final bytes = await decrypt(blob, key, aad: aad);
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map<String, dynamic>) return json;
    } on FormatException {
      // Falls through.
    }
    throw const CryptoException('Decrypted data is not a JSON object');
  }

  /// [key] encrypted with [wrappingKey] (master key, item key, private key).
  Future<EncryptedBlob> wrapKey(
    SecretKey key,
    SecretKey wrappingKey, {
    required String aad,
  }) async => encrypt(await key.extractBytes(), wrappingKey, aad: aad);

  Future<SecretKey> unwrapKey(
    EncryptedBlob blob,
    SecretKey wrappingKey, {
    required String aad,
  }) async => secretKeyFromBytes(await decrypt(blob, wrappingKey, aad: aad));

  // ── Sealed boxes ──────────────────────────────────────────────────────────

  /// [key] encrypted so that only the owner of [recipientPublicKey] can open
  /// it: X25519 with a one-off key pair, HKDF over the shared secret (salted
  /// with both public keys), then AES-256-GCM.
  Future<SealedKey> sealKey(
    SecretKey key,
    List<int> recipientPublicKey, {
    required String aad,
  }) async {
    final ephemeral = await newKeyPair();
    final epk = await publicKeyBytes(ephemeral);
    final wrapping = await _sealWrappingKey(
      ephemeral,
      remotePublicKey: recipientPublicKey,
      salt: [...epk, ...recipientPublicKey],
    );
    return SealedKey(
      ephemeralPublicKey: epk,
      blob: await wrapKey(key, wrapping, aad: aad),
    );
  }

  /// Opens a [SealedKey] addressed to [keyPair].
  Future<SecretKey> openSealedKey(
    SealedKey sealed,
    SimpleKeyPair keyPair, {
    required String aad,
  }) async {
    final ownPublic = await publicKeyBytes(keyPair);
    final wrapping = await _sealWrappingKey(
      keyPair,
      remotePublicKey: sealed.ephemeralPublicKey,
      salt: [...sealed.ephemeralPublicKey, ...ownPublic],
    );
    return unwrapKey(sealed.blob, wrapping, aad: aad);
  }

  Future<SecretKey> _sealWrappingKey(
    SimpleKeyPair keyPair, {
    required List<int> remotePublicKey,
    required List<int> salt,
  }) async {
    if (remotePublicKey.length != keyLength) {
      throw const CryptoException('Wrong public key length');
    }
    final shared = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(
        remotePublicKey,
        type: KeyPairType.x25519,
      ),
    );
    return _hkdf.deriveKey(
      secretKey: shared,
      nonce: salt,
      info: utf8.encode(_sealInfo),
    );
  }

  // ── Recovery key ──────────────────────────────────────────────────────────

  /// A new random recovery key.
  Uint8List newRecoveryKey() => randomBytes(recoveryKeyLength);

  /// [recoveryKey] as the user writes it down: Base32 (RFC 4648, no
  /// padding) in dash-separated groups of 4, e.g. `ABCD-EFGH-…` (13 groups).
  static String formatRecoveryKey(Uint8List recoveryKey) {
    final encoded = _base32Encode(recoveryKey);
    final groups = <String>[
      for (var i = 0; i < encoded.length; i += 4)
        encoded.substring(i, i + 4 > encoded.length ? encoded.length : i + 4),
    ];
    return groups.join('-');
  }

  /// The bytes of a recovery key typed by the user, ignoring case, spaces
  /// and dashes; null if it isn't a valid key.
  static Uint8List? parseRecoveryKey(String input) {
    final clean = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final bytes = _base32Decode(clean);
    if (bytes == null || bytes.length != recoveryKeyLength) return null;
    return bytes;
  }

  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String _base32Encode(Uint8List bytes) {
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final b in bytes) {
      buffer = (buffer << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(_base32Alphabet[(buffer >> bits) & 31]);
      }
    }
    if (bits > 0) out.write(_base32Alphabet[(buffer << (5 - bits)) & 31]);
    return out.toString();
  }

  static Uint8List? _base32Decode(String input) {
    final out = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final ch in input.split('')) {
      final value = _base32Alphabet.indexOf(ch);
      if (value < 0) return null;
      buffer = ((buffer << 5) | value) & 0xFFF;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xFF);
      }
    }
    // Leftover bits must be the zero padding written by _base32Encode.
    if (bits >= 5 || (buffer & ((1 << bits) - 1)) != 0) return null;
    return Uint8List.fromList(out);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// [length] cryptographically secure random bytes.
  static Uint8List randomBytes(int length) =>
      Uint8List.fromList(SecretKeyData.random(length: length).bytes);
}
