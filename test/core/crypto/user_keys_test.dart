import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/core/crypto/user_keys.dart';

import '../../helpers/crypto.dart';

void main() {
  final crypto = CryptoService();
  final manager = UserKeyManager(crypto);

  Future<List<int>> masterBytes(UnlockedKeys k) => k.masterKey.extractBytes();

  UserKeyBundle stored(UserKeyBundle b) => UserKeyBundle.fromJson(
    jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>,
  );

  Future<({UserKeyBundle bundle, UnlockedKeys keys})> create([
    String id = 'passkey-1',
  ]) async {
    final salt = manager.newPrfSalt();
    return manager.create(
      'u1',
      prfSalt: salt,
      passkey: await FakePasskeyClient.secretOf(id, salt),
    );
  }

  test('the passkey unlocks the same keys, another one does not', () async {
    final created = await create();
    final bundle = stored(created.bundle);
    final salt = bundle.prfSalt!;

    final keys = await manager.unlockWithPasskey(
      'u1',
      bundle,
      await FakePasskeyClient.secretOf('passkey-1', salt),
    );
    expect(await masterBytes(keys), await masterBytes(created.keys));
    expect(await crypto.publicKeyBytes(keys.keyPair), created.keys.publicKey);

    expect(
      () async => manager.unlockWithPasskey(
        'u1',
        bundle,
        await FakePasskeyClient.secretOf('passkey-2', salt),
      ),
      throwsA(isA<UnknownPasskeyException>()),
    );
    // The right passkey asked with another salt: wrong secret.
    expect(
      () async => manager.unlockWithPasskey(
        'u1',
        bundle,
        await FakePasskeyClient.secretOf('passkey-1', manager.newPrfSalt()),
      ),
      throwsA(isA<CryptoException>()),
    );
    // Another user's bundle: the AAD binds it to its uid.
    expect(
      () async => manager.unlockWithPasskey(
        'u2',
        bundle,
        await FakePasskeyClient.secretOf('passkey-1', salt),
      ),
      throwsA(isA<CryptoException>()),
    );
  });

  test('the bundle holds no key in clear', () async {
    final created = await create();
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
    expect(created.bundle.hasRecoveryKey, isFalse);
  });

  test('the recovery key unlocks; a new one replaces it', () async {
    final created = await create();
    expect(
      () => manager.unlockWithRecoveryKey(
        'u1',
        created.bundle,
        crypto.newRecoveryKey(),
      ),
      throwsA(isA<CryptoException>()),
    );

    final first = await manager.withNewRecoveryKey(
      'u1',
      created.bundle,
      created.keys,
    );
    final keys = await manager.unlockWithRecoveryKey(
      'u1',
      stored(first.bundle),
      first.recoveryKey,
    );
    expect(await masterBytes(keys), await masterBytes(created.keys));

    final renewed = await manager.withNewRecoveryKey('u1', first.bundle, keys);
    expect(
      () => manager.unlockWithRecoveryKey(
        'u1',
        renewed.bundle,
        first.recoveryKey,
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

  test('a second passkey keeps the master key and the first one', () async {
    final created = await create();
    final salt = created.bundle.prfSalt!;
    final added = stored(
      await manager.withPasskey(
        'u1',
        created.bundle,
        created.keys,
        prfSalt: salt,
        passkey: await FakePasskeyClient.secretOf('passkey-2', salt),
      ),
    );
    expect(added.passkeysWrapped.keys, ['passkey-1', 'passkey-2']);
    for (final id in ['passkey-1', 'passkey-2']) {
      final keys = await manager.unlockWithPasskey(
        'u1',
        added,
        await FakePasskeyClient.secretOf(id, salt),
      );
      expect(await masterBytes(keys), await masterBytes(created.keys));
    }
  });

  test('keys survive the device storage round trip', () async {
    final created = await create();
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

  test(
    'a version 1 bundle has no passkey; unknown versions are refused',
    () async {
      final created = await create();
      final json = created.bundle.toJson();
      final legacy = UserKeyBundle.fromJson({
        'v': 1,
        'kdf': {'alg': 'pbkdf2-sha256', 'iter': 600000, 'salt': 'AAAA'},
        'mk_pass': json['sk'],
        'mk_recovery': json['sk'],
        'sk': json['sk'],
        'pk': json['pk'],
      });
      expect(legacy.hasPasskey, isFalse);
      expect(legacy.prfSalt, isNull);
      expect(legacy.hasRecoveryKey, isTrue);

      expect(
        () => UserKeyBundle.fromJson({...json, 'v': 3}),
        throwsA(isA<CryptoException>()),
      );
    },
  );
}
