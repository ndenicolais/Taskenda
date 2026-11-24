import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/core/crypto/user_keys.dart';

void main() {
  final crypto = CryptoService();
  final manager = UserKeyManager(crypto, iterations: 1000);

  Future<List<int>> masterBytes(UnlockedKeys k) => k.masterKey.extractBytes();

  UserKeyBundle stored(UserKeyBundle b) => UserKeyBundle.fromJson(
    jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>,
  );

  test('the passphrase unlocks the same keys, a wrong one does not', () async {
    final created = await manager.create('u1', 'passphrase');
    final bundle = stored(created.bundle);

    final keys = await manager.unlockWithPassphrase('u1', bundle, 'passphrase');
    expect(await masterBytes(keys), await masterBytes(created.keys));
    expect(await crypto.publicKeyBytes(keys.keyPair), created.keys.publicKey);

    expect(
      () => manager.unlockWithPassphrase('u1', bundle, 'wrong'),
      throwsA(isA<CryptoException>()),
    );
    // Another user's bundle: the AAD binds it to its uid.
    expect(
      () => manager.unlockWithPassphrase('u2', bundle, 'passphrase'),
      throwsA(isA<CryptoException>()),
    );
  });

  test('the bundle holds no key in clear', () async {
    final created = await manager.create('u1', 'passphrase');
    final raw = jsonEncode(created.bundle.toJson());
    expect(raw, isNot(contains(base64Encode(await masterBytes(created.keys)))));
    expect(
      raw,
      isNot(
        contains(
          base64Encode(await crypto.privateKeyBytes(created.keys.keyPair)),
        ),
      ),
    );
    expect(created.bundle.kdf.iterations, 1000);
  });

  test('the recovery key unlocks; a new one replaces it', () async {
    final created = await manager.create('u1', 'passphrase');
    final keys = await manager.unlockWithRecoveryKey(
      'u1',
      stored(created.bundle),
      created.recoveryKey,
    );
    expect(await masterBytes(keys), await masterBytes(created.keys));

    final renewed = await manager.withNewRecoveryKey(
      'u1',
      created.bundle,
      keys,
    );
    expect(
      () => manager.unlockWithRecoveryKey(
        'u1',
        renewed.bundle,
        created.recoveryKey,
      ),
      throwsA(isA<CryptoException>()),
    );
    final again = await manager.unlockWithRecoveryKey(
      'u1',
      renewed.bundle,
      renewed.recoveryKey,
    );
    expect(await masterBytes(again), await masterBytes(created.keys));
  });

  test('a new passphrase keeps the master key', () async {
    final created = await manager.create('u1', 'old passphrase');
    final changed = await manager.withPassphrase(
      'u1',
      created.bundle,
      created.keys,
      'new passphrase',
    );
    expect(changed.kdf.salt, isNot(created.bundle.kdf.salt));
    expect(
      () => manager.unlockWithPassphrase('u1', changed, 'old passphrase'),
      throwsA(isA<CryptoException>()),
    );
    final keys = await manager.unlockWithPassphrase(
      'u1',
      changed,
      'new passphrase',
    );
    expect(await masterBytes(keys), await masterBytes(created.keys));
    // The recovery key still works.
    await manager.unlockWithRecoveryKey('u1', changed, created.recoveryKey);
  });

  test('keys survive the device storage round trip', () async {
    final created = await manager.create('u1', 'passphrase');
    final back = await manager.importFromDevice(
      await manager.exportForDevice(created.keys),
    );
    expect(await masterBytes(back), await masterBytes(created.keys));
    expect(back.publicKey, created.keys.publicKey);

    expect(
      () => manager.importFromDevice('not json'),
      throwsA(isA<CryptoException>()),
    );
  });

  test('an unknown bundle version is refused', () async {
    final created = await manager.create('u1', 'passphrase');
    expect(
      () => UserKeyBundle.fromJson({...created.bundle.toJson(), 'v': 2}),
      throwsA(isA<CryptoException>()),
    );
  });
}
