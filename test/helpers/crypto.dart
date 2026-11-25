import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/core/crypto/item_cipher.dart';
import 'package:taskenda/core/crypto/passkey_client.dart';
import 'package:taskenda/providers/crypto_provider.dart';
import 'package:taskenda/utils/device_key_storage.dart';

/// [DeviceKeyStorage] in memory; [persistent] records the last write's flag.
class MemoryKeyStorage extends DeviceKeyStorage {
  final values = <String, String>{};
  bool? persistent;

  @override
  Future<String?> read(String uid) async => values[uid];

  @override
  Future<void> write(
    String uid,
    String value, {
    bool persistent = false,
  }) async {
    values[uid] = value;
    this.persistent = persistent;
  }

  @override
  Future<void> delete(String uid) async => values.remove(uid);
}

/// A passkey provider synced across every device of the test: a passkey's
/// PRF secret is HMAC-SHA256(credential id, salt), so any instance gives the
/// same secret for the same passkey. [nextError] is thrown by the next call
/// instead; [forcedCredentialId] is the passkey [get] answers with.
class FakePasskeyClient implements PasskeyClient {
  Exception? nextError;
  String? forcedCredentialId;
  int creates = 0;
  int gets = 0;

  void _throwIfAsked() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

  static Future<PasskeySecret> secretOf(String id, Uint8List salt) async {
    final mac = await Hmac.sha256().calculateMac(
      salt,
      secretKey: SecretKey(utf8.encode(id)),
    );
    return PasskeySecret(
      credentialId: id,
      secret: Uint8List.fromList(mac.bytes),
    );
  }

  @override
  Future<PasskeySecret> create({
    required String userId,
    required String userName,
    required String displayName,
    required Uint8List salt,
  }) async {
    _throwIfAsked();
    creates++;
    final id = PasskeyCodec.toBase64Url(CryptoService.randomBytes(16));
    return secretOf(id, salt);
  }

  @override
  Future<PasskeySecret> get({
    required Uint8List salt,
    List<String> credentialIds = const [],
  }) async {
    _throwIfAsked();
    gets++;
    final id =
        forcedCredentialId ??
        (credentialIds.isEmpty
            ? throw const PasskeyNotFoundException()
            : credentialIds.first);
    return secretOf(id, salt);
  }
}

/// Overrides for [cryptoProvider]: encryption on, [storage] and [passkeys]
/// (a new [FakePasskeyClient] if omitted).
List<Override> cryptoOverrides(
  MemoryKeyStorage storage, [
  FakePasskeyClient? passkeys,
]) => [
  e2eeEnabledProvider.overrideWithValue(true),
  deviceKeyStorageProvider.overrideWithValue(storage),
  passkeyClientProvider.overrideWithValue(passkeys ?? FakePasskeyClient()),
];

/// The [cryptoProvider] state once it is no longer [CryptoChecking].
Future<CryptoState> settledCrypto(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    final state = container.read(cryptoProvider);
    if (state is! CryptoChecking) return state;
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(cryptoProvider);
}

/// Documents in clear for the data notifier tests, which seed and read
/// plain model JSON: the same cipher as a build without encryption.
typedef PlainItemCipher = ClearItemCipher;
