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

/// Overrides for [cryptoProvider]: encryption on, [storage] and a fast key
/// manager.
List<Override> cryptoOverrides(MemoryKeyStorage storage) => [
  e2eeEnabledProvider.overrideWithValue(true),
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

/// Documents in clear for the data notifier tests, which seed and read
/// plain model JSON: the same cipher as a build without encryption.
typedef PlainItemCipher = ClearItemCipher;
