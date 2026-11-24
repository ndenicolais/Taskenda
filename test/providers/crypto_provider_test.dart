import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/providers/crypto_provider.dart';

import '../helpers/crypto.dart';
import '../helpers/test_container.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MemoryKeyStorage storage;

  setUp(() {
    db = FakeFirebaseFirestore();
    storage = MemoryKeyStorage();
  });

  /// A container for user [uid] on a device with [storage].
  Future<(ProviderContainer, CryptoState)> start({
    String uid = 'u1',
    MemoryKeyStorage? on,
  }) async {
    final container = createTestContainer(
      db,
      uid: uid,
      overrides: cryptoOverrides(on ?? storage),
    );
    container.listen(cryptoProvider, (_, _) {});
    return (container, await settledCrypto(container));
  }

  Future<Map<String, dynamic>?> bundleDoc([String uid = 'u1']) async =>
      (await db.doc('users/$uid/crypto/keys').get()).data();

  Future<Map<String, dynamic>?> publicKeyDoc([String uid = 'u1']) async =>
      (await db.doc('public_keys/$uid').get()).data();

  test('signed out', () async {
    final (_, state) = await start(uid: '');
    expect(state, isA<CryptoSignedOut>());
  });

  test('a new account needs setup; setup stores the keys everywhere', () async {
    final (c, state) = await start();
    expect(state, isA<CryptoNeedsSetup>());

    await c.read(cryptoProvider.notifier).setup('passphrase');

    final unlocked = c.read(cryptoProvider) as CryptoUnlocked;
    expect(
      CryptoService.parseRecoveryKey(unlocked.pendingRecoveryKey!),
      isNotNull,
    );
    expect((await bundleDoc())!['v'], 1);
    expect((await publicKeyDoc())!['pk'], (await bundleDoc())!['pk']);
    expect(storage.values, contains('u1'));
    expect(storage.persistent, isFalse);
    expect(c.read(unlockedKeysProvider), isNotNull);

    c.read(cryptoProvider.notifier).acknowledgeRecoveryKey();
    expect(
      (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey,
      isNull,
    );
  });

  test('keys saved on the device unlock at the next start', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup('passphrase', remember: true);
    expect(storage.persistent, isTrue);
    c.dispose();

    final (_, state) = await start();
    expect(state, isA<CryptoUnlocked>());
    expect((state as CryptoUnlocked).pendingRecoveryKey, isNull);
  });

  test('another device is locked and unlocks with the passphrase', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup('passphrase');
    final publicKey =
        (first.read(cryptoProvider) as CryptoUnlocked).keys.publicKey;

    final otherDevice = MemoryKeyStorage();
    final (c, state) = await start(on: otherDevice);
    expect(state, isA<CryptoLocked>());

    await expectLater(
      c.read(cryptoProvider.notifier).unlock('wrong'),
      throwsA(isA<CryptoException>()),
    );
    expect(c.read(cryptoProvider), isA<CryptoLocked>());

    await c.read(cryptoProvider.notifier).unlock('passphrase');
    final unlocked = c.read(cryptoProvider) as CryptoUnlocked;
    expect(unlocked.keys.publicKey, publicKey);
    expect(unlocked.pendingRecoveryKey, isNull);
    expect(otherDevice.values, contains('u1'));
  });

  test('recovery sets a new passphrase and a new recovery key', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup('old passphrase');
    final oldRecovery =
        (first.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;

    final (c, _) = await start(on: MemoryKeyStorage());
    final notifier = c.read(cryptoProvider.notifier);
    await expectLater(
      notifier.recover('not a key', 'new passphrase'),
      throwsA(isA<InvalidRecoveryKeyException>()),
    );
    await notifier.recover(oldRecovery.toLowerCase(), 'new passphrase');
    final newRecovery =
        (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;
    expect(newRecovery, isNot(oldRecovery));

    // A third device: the old passphrase and recovery key no longer work.
    final (third, _) = await start(on: MemoryKeyStorage());
    final thirdNotifier = third.read(cryptoProvider.notifier);
    await expectLater(
      thirdNotifier.unlock('old passphrase'),
      throwsA(isA<CryptoException>()),
    );
    await expectLater(
      thirdNotifier.recover(oldRecovery, 'x passphrase'),
      throwsA(isA<CryptoException>()),
    );
    await thirdNotifier.unlock('new passphrase');
    expect(third.read(cryptoProvider), isA<CryptoUnlocked>());
  });

  test('reset deletes the keys and asks for setup again', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup('passphrase');

    final (c, _) = await start(on: MemoryKeyStorage());
    await c.read(cryptoProvider.notifier).reset();
    expect(c.read(cryptoProvider), isA<CryptoNeedsSetup>());
    expect(await bundleDoc(), isNull);
    expect(await publicKeyDoc(), isNull);
  });

  test('keys saved before a reset elsewhere are forgotten', () async {
    final (first, _) = await start();
    await first.read(cryptoProvider.notifier).setup('passphrase');
    first.dispose();

    // Another device resets encryption and sets it up again.
    final (other, _) = await start(on: MemoryKeyStorage());
    await other.read(cryptoProvider.notifier).reset();
    await other.read(cryptoProvider.notifier).setup('new passphrase');

    final (c, _) = await start();
    // Unlocked from storage at first, then the background check locks it.
    for (var i = 0; i < 50 && c.read(cryptoProvider) is! CryptoLocked; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(c.read(cryptoProvider), isA<CryptoLocked>());
    expect(storage.values, isNot(contains('u1')));
  });

  test('setup on a second device that raced the first locks instead', () async {
    final (a, _) = await start(on: MemoryKeyStorage());
    final (b, _) = await start(on: MemoryKeyStorage());
    await a.read(cryptoProvider.notifier).setup('passphrase A');
    final pkA = (await bundleDoc())!['pk'];

    await b.read(cryptoProvider.notifier).setup('passphrase B');
    expect(b.read(cryptoProvider), isA<CryptoLocked>());
    expect((await bundleDoc())!['pk'], pkA);
  });

  test('forget removes the keys from the device', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup('passphrase');
    await c.read(cryptoProvider.notifier).forget();
    expect(storage.values, isEmpty);
  });

  test('change the passphrase: the old one stops working', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup('old passphrase');
    final recovery =
        (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;
    final notifier = c.read(cryptoProvider.notifier);

    await expectLater(
      notifier.changePassphrase('wrong', 'new passphrase'),
      throwsA(isA<CryptoException>()),
    );
    await notifier.changePassphrase('old passphrase', 'new passphrase');
    expect(c.read(cryptoProvider), isA<CryptoUnlocked>());

    final (other, _) = await start(on: MemoryKeyStorage());
    final otherNotifier = other.read(cryptoProvider.notifier);
    await expectLater(
      otherNotifier.unlock('old passphrase'),
      throwsA(isA<CryptoException>()),
    );
    await otherNotifier.unlock('new passphrase');
    expect(other.read(cryptoProvider), isA<CryptoUnlocked>());

    // The recovery key is not affected.
    final (third, _) = await start(on: MemoryKeyStorage());
    await third.read(cryptoProvider.notifier).recover(recovery, 'third one');
    expect(third.read(cryptoProvider), isA<CryptoUnlocked>());
  });

  test('a new recovery key replaces the old one', () async {
    final (c, _) = await start();
    await c.read(cryptoProvider.notifier).setup('passphrase');
    final old = (c.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;
    c.read(cryptoProvider.notifier).acknowledgeRecoveryKey();

    await expectLater(
      c.read(cryptoProvider.notifier).regenerateRecoveryKey('wrong'),
      throwsA(isA<CryptoException>()),
    );
    final fresh = await c
        .read(cryptoProvider.notifier)
        .regenerateRecoveryKey('passphrase');
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
      otherNotifier.recover(old, 'new passphrase'),
      throwsA(isA<CryptoException>()),
    );
    await otherNotifier.recover(fresh, 'new passphrase');
    expect(other.read(cryptoProvider), isA<CryptoUnlocked>());
  });
}
