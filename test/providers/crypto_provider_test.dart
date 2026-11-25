import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/core/crypto/passkey_client.dart';
import 'package:taskenda/core/crypto/user_keys.dart';
import 'package:taskenda/providers/crypto_provider.dart';

import '../helpers/crypto.dart';
import '../helpers/test_container.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MemoryKeyStorage storage;
  late FakePasskeyClient passkeys;

  setUp(() {
    db = FakeFirebaseFirestore();
    storage = MemoryKeyStorage();
    passkeys = FakePasskeyClient();
  });

  /// A container for user [uid] on a device with [storage].
  Future<(ProviderContainer, CryptoState)> start({
    String uid = 'u1',
    MemoryKeyStorage? on,
  }) async {
    final container = createTestContainer(
      db,
      uid: uid,
      overrides: cryptoOverrides(on ?? storage, passkeys),
    );
    container.listen(cryptoProvider, (_, _) {});
    return (container, await settledCrypto(container));
  }

  Future<Map<String, dynamic>?> bundleDoc([String uid = 'u1']) async =>
      (await db.doc('users/$uid/crypto/keys').get()).data();

  Future<Map<String, dynamic>?> publicKeyDoc([String uid = 'u1']) async =>
      (await db.doc('public_keys/$uid').get()).data();

  /// Sets up the keys on a first device and returns the recovery key.
  Future<String> setUpWithRecoveryKey() async {
    final (c, _) = await start(on: MemoryKeyStorage());
    final notifier = c.read(cryptoProvider.notifier);
    await notifier.setup();
    await notifier.createFirstRecoveryKey();
    final recovery =
        (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;
    notifier.acknowledgeRecoveryKey();
    return recovery;
  }

  test('signed out', () async {
    final (_, state) = await start(uid: '');
    expect(state, isA<CryptoSignedOut>());
  });

  test('setup creates a passkey and stores the keys everywhere', () async {
    final (c, state) = await start();
    expect(state, isA<CryptoNeedsSetup>());

    await c.read(cryptoProvider.notifier).setup();

    final unlocked = c.read(cryptoProvider) as CryptoUnlocked;
    expect(unlocked.offerRecoveryKey, isTrue);
    expect(unlocked.pendingRecoveryKey, isNull);
    expect(passkeys.creates, 1);
    final bundle = (await bundleDoc())!;
    expect(bundle['v'], 2);
    expect(bundle['passkeys'], hasLength(1));
    expect(bundle, isNot(contains('mk_recovery')));
    expect((await publicKeyDoc())!['pk'], bundle['pk']);
    expect(storage.values, contains('u1'));
    expect(storage.persistent, isFalse);
    expect(c.read(unlockedKeysProvider), isNotNull);

    // "Later": no recovery key.
    c.read(cryptoProvider.notifier).acknowledgeRecoveryKey();
    expect((c.read(cryptoProvider) as CryptoUnlocked).offerRecoveryKey, false);
    expect(await bundleDoc(), isNot(contains('mk_recovery')));
  });

  test('a cancelled passkey leaves the account without keys', () async {
    final (c, _) = await start();
    passkeys.nextError = const PasskeyCancelledException();
    await expectLater(
      c.read(cryptoProvider.notifier).setup(),
      throwsA(isA<PasskeyCancelledException>()),
    );
    expect(c.read(cryptoProvider), isA<CryptoNeedsSetup>());
    expect(await bundleDoc(), isNull);
  });

  test('the first recovery key is shown once and stored', () async {
    final (c, _) = await start();
    final notifier = c.read(cryptoProvider.notifier);
    await notifier.setup();
    await notifier.createFirstRecoveryKey();

    final unlocked = c.read(cryptoProvider) as CryptoUnlocked;
    expect(
      CryptoService.parseRecoveryKey(unlocked.pendingRecoveryKey!),
      isNotNull,
    );
    expect(unlocked.offerRecoveryKey, isFalse);
    expect(await bundleDoc(), contains('mk_recovery'));

    notifier.acknowledgeRecoveryKey();
    expect(
      (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey,
      isNull,
    );
    await expectLater(notifier.createFirstRecoveryKey(), throwsStateError);
  });

  test('keys saved on the device unlock at the next start', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup(remember: true);
    expect(storage.persistent, isTrue);
    c.dispose();

    final (_, state) = await start();
    expect(state, isA<CryptoUnlocked>());
    expect((state as CryptoUnlocked).offerRecoveryKey, isFalse);
    expect(passkeys.gets, 0);
  });

  test('another device is locked and unlocks with the passkey', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup();
    final publicKey =
        (first.read(cryptoProvider) as CryptoUnlocked).keys.publicKey;

    final otherDevice = MemoryKeyStorage();
    final (c, state) = await start(on: otherDevice);
    expect(state, isA<CryptoLocked>());
    expect((state as CryptoLocked).bundle.hasPasskey, isTrue);

    passkeys.nextError = const PasskeyNotFoundException();
    await expectLater(
      c.read(cryptoProvider.notifier).unlockWithPasskey(),
      throwsA(isA<PasskeyNotFoundException>()),
    );
    expect(c.read(cryptoProvider), isA<CryptoLocked>());

    await c.read(cryptoProvider.notifier).unlockWithPasskey();
    final unlocked = c.read(cryptoProvider) as CryptoUnlocked;
    expect(unlocked.keys.publicKey, publicKey);
    expect(unlocked.offerRecoveryKey, isFalse);
    expect(otherDevice.values, contains('u1'));
  });

  test('a passkey that does not protect the keys is refused', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup();

    final (c, _) = await start(on: MemoryKeyStorage());
    passkeys.forcedCredentialId = 'old-passkey';
    await expectLater(
      c.read(cryptoProvider.notifier).unlockWithPasskey(),
      throwsA(isA<UnknownPasskeyException>()),
    );
    expect(c.read(cryptoProvider), isA<CryptoLocked>());
  });

  test('recovery creates a second passkey; both unlock', () async {
    final recovery = await setUpWithRecoveryKey();

    final (c, _) = await start(on: MemoryKeyStorage());
    final notifier = c.read(cryptoProvider.notifier);
    await expectLater(
      notifier.recover('not a key'),
      throwsA(isA<InvalidRecoveryKeyException>()),
    );
    await expectLater(
      notifier.recover(
        CryptoService.formatRecoveryKey(CryptoService().newRecoveryKey()),
      ),
      throwsA(isA<CryptoException>()),
    );
    // The passkey isn't created: still locked, nothing saved.
    passkeys.nextError = const PasskeyCancelledException();
    await expectLater(
      notifier.recover(recovery),
      throwsA(isA<PasskeyCancelledException>()),
    );
    expect(c.read(cryptoProvider), isA<CryptoLocked>());
    expect((await bundleDoc())!['passkeys'], hasLength(1));

    await notifier.recover(recovery.toLowerCase());
    expect(c.read(cryptoProvider), isA<CryptoUnlocked>());
    final ids = ((await bundleDoc())!['passkeys'] as Map).keys.toList();
    expect(ids, hasLength(2));

    for (final id in ids) {
      final (other, _) = await start(on: MemoryKeyStorage());
      passkeys.forcedCredentialId = id as String;
      await other.read(cryptoProvider.notifier).unlockWithPasskey();
      expect(other.read(cryptoProvider), isA<CryptoUnlocked>());
    }
    // The recovery key keeps working.
    passkeys.forcedCredentialId = null;
    final (third, _) = await start(on: MemoryKeyStorage());
    await third.read(cryptoProvider.notifier).recover(recovery);
    expect(third.read(cryptoProvider), isA<CryptoUnlocked>());
  });

  test('a bundle from before passkeys opens with the recovery key', () async {
    // A version 1 bundle: master key wrapped with a code and the recovery
    // key, no passkey.
    final crypto = CryptoService();
    final created = await UserKeyManager(crypto).create(
      'u1',
      prfSalt: crypto.newRecoveryKey(),
      passkey: await FakePasskeyClient.secretOf(
        'x',
        CryptoService.randomBytes(32),
      ),
    );
    final withRecovery = await UserKeyManager(
      crypto,
    ).withNewRecoveryKey('u1', created.bundle, created.keys);
    final v2 = withRecovery.bundle.toJson();
    await db.doc('users/u1/crypto/keys').set({
      'v': 1,
      'kdf': {'alg': 'pbkdf2-sha256', 'iter': 600000, 'salt': 'AAAA'},
      'mk_pass': v2['mk_recovery'],
      'mk_recovery': v2['mk_recovery'],
      'sk': v2['sk'],
      'pk': v2['pk'],
    });

    final (c, state) = await start();
    final bundle = (state as CryptoLocked).bundle;
    expect(bundle.hasPasskey, isFalse);
    expect(bundle.hasRecoveryKey, isTrue);

    await c
        .read(cryptoProvider.notifier)
        .recover(CryptoService.formatRecoveryKey(withRecovery.recoveryKey));
    final unlocked = c.read(cryptoProvider) as CryptoUnlocked;
    expect(unlocked.keys.publicKey, created.keys.publicKey);
    final saved = (await bundleDoc())!;
    expect(saved['v'], 2);
    expect(saved['passkeys'], hasLength(1));
    expect(saved, contains('salt'));
    expect(saved, isNot(contains('mk_pass')));
    expect(saved, isNot(contains('kdf')));

    final (other, _) = await start(on: MemoryKeyStorage());
    await other.read(cryptoProvider.notifier).unlockWithPasskey();
    expect(other.read(cryptoProvider), isA<CryptoUnlocked>());
  });

  test('reset deletes the keys and asks for setup again', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup();

    final (c, _) = await start(on: MemoryKeyStorage());
    await c.read(cryptoProvider.notifier).reset();
    expect(c.read(cryptoProvider), isA<CryptoNeedsSetup>());
    expect(await bundleDoc(), isNull);
    expect(await publicKeyDoc(), isNull);
  });

  test('keys saved before a reset elsewhere are forgotten', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup();
    first.dispose();

    // Another device resets encryption and sets it up again.
    final (other, _) = await start(on: MemoryKeyStorage());
    await other.read(cryptoProvider.notifier).reset();
    await other.read(cryptoProvider.notifier).setup();

    final (c, _) = await start();
    // Unlocked from storage at first, then the background check locks it.
    for (var i = 0; i < 50 && c.read(cryptoProvider) is! CryptoLocked; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(c.read(cryptoProvider), isA<CryptoLocked>());
    expect(storage.values, isNot(contains('u1')));
  });

  test('setup when another device already has keys locks instead', () async {
    final (a, _) = await start(on: MemoryKeyStorage());
    final (b, _) = await start(on: MemoryKeyStorage());
    await a.read(cryptoProvider.notifier).setup();
    final pkA = (await bundleDoc())!['pk'];

    await b.read(cryptoProvider.notifier).setup();
    expect(b.read(cryptoProvider), isA<CryptoLocked>());
    expect((await bundleDoc())!['pk'], pkA);
    // No passkey was created for nothing.
    expect(passkeys.creates, 1);
  });

  test('forget removes the keys from the device', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup();
    await c.read(cryptoProvider.notifier).forget();
    expect(storage.values, isEmpty);
  });

  test('a new recovery key, confirmed with the passkey, replaces the old '
      'one', () async {
    final old = await setUpWithRecoveryKey();
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).unlockWithPasskey();
    final notifier = c.read(cryptoProvider.notifier);

    passkeys.nextError = const PasskeyCancelledException();
    await expectLater(
      notifier.regenerateRecoveryKey(),
      throwsA(isA<PasskeyCancelledException>()),
    );
    final getsBefore = passkeys.gets;
    final fresh = await notifier.regenerateRecoveryKey();
    expect(passkeys.gets, getsBefore + 1);
    expect(fresh, isNot(old));
    expect(CryptoService.parseRecoveryKey(fresh), isNotNull);
    // Shown by the settings, not by the gate.
    expect(
      (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey,
      isNull,
    );

    final (other, _) = await start(on: MemoryKeyStorage());
    final otherNotifier = other.read(cryptoProvider.notifier);
    await expectLater(
      otherNotifier.recover(old),
      throwsA(isA<CryptoException>()),
    );
    await otherNotifier.recover(fresh);
    expect(other.read(cryptoProvider), isA<CryptoUnlocked>());
  });

  test('a recovery key can be created later from the settings', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup();
    c.read(cryptoProvider.notifier).acknowledgeRecoveryKey();

    final recovery =
        await c.read(cryptoProvider.notifier).regenerateRecoveryKey();
    final (other, _) = await start(on: MemoryKeyStorage());
    await other.read(cryptoProvider.notifier).recover(recovery);
    expect(other.read(cryptoProvider), isA<CryptoUnlocked>());
  });
}
