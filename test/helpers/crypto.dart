import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/core/crypto/item_cipher.dart';
import 'package:taskenda/core/crypto/user_keys.dart';
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

/// Overrides for [cryptoProvider]: [storage] and a fast key manager.
List<Override> cryptoOverrides(MemoryKeyStorage storage) => [
  deviceKeyStorageProvider.overrideWithValue(storage),
  userKeyManagerProvider.overrideWithValue(
    UserKeyManager(CryptoService(), iterations: 1000),
  ),
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

/// An [ItemCipher] that stores documents in clear, so the data notifier
/// tests can read and seed Firestore documents as plain model JSON.
class PlainItemCipher implements ItemCipher {
  const PlainItemCipher();

  @override
  bool get encrypts => false;

  @override
  Future<Map<String, dynamic>> decode(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async => data;

  @override
  Future<Map<String, dynamic>> encodeItem(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
    List<String> privateKeys = const [],
  }) async => json;

  @override
  Future<Map<String, dynamic>> encodeNamed(
    String collection,
    String id,
    Map<String, dynamic> json, {
    required List<String> contentKeys,
  }) async => json;

  @override
  void forget(String collection, String id) {}
}
