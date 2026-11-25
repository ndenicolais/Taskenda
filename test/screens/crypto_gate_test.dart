import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/passkey_client.dart';
import 'package:taskenda/providers/crypto_provider.dart';
import 'package:taskenda/screens/crypto/crypto_gate.dart';
import 'package:taskenda/screens/crypto/crypto_setup_screen.dart';
import 'package:taskenda/screens/crypto/crypto_unlock_screen.dart';
import 'package:taskenda/screens/crypto/recovery_key_screen.dart';

import '../helpers/crypto.dart';
import '../helpers/l10n.dart';
import '../helpers/test_container.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MemoryKeyStorage storage;
  late FakePasskeyClient passkeys;
  late ProviderContainer container;

  setUp(() {
    db = FakeFirebaseFirestore();
    storage = MemoryKeyStorage();
    passkeys = FakePasskeyClient();
  });

  Future<void> pumpGate(WidgetTester tester) async {
    container = createTestContainer(
      db,
      uid: 'u1',
      overrides: cryptoOverrides(storage, passkeys),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: testLocale,
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationsDelegates,
          home: CryptoGate(loading: Text('loading'), child: Text('app')),
        ),
      ),
    );
    await tester.runAsync(() => settledCrypto(container));
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  /// Taps [finder] and lets the work it starts (real crypto, real async)
  /// finish outside fake time, then rebuilds.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tapVisible(tester, finder);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  /// Keys created by another device; returns its recovery key if
  /// [withRecoveryKey].
  Future<String?> setUpElsewhere(
    WidgetTester tester, {
    bool withRecoveryKey = false,
  }) async {
    final other = createTestContainer(
      db,
      uid: 'u1',
      overrides: cryptoOverrides(MemoryKeyStorage(), passkeys),
    );
    other.listen(cryptoProvider, (_, _) {});
    String? recovery;
    await tester.runAsync(() async {
      await settledCrypto(other);
      final notifier = other.read(cryptoProvider.notifier);
      await notifier.setup();
      if (withRecoveryKey) {
        await notifier.createFirstRecoveryKey();
        recovery =
            (other.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey;
      }
    });
    return recovery;
  }

  testWidgets('setup: a cancelled passkey shows an error, then the offer', (
    tester,
  ) async {
    await pumpGate(tester);
    expect(find.byType(CryptoSetupScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    passkeys.nextError = const PasskeyCancelledException();
    await tapAndSettle(tester, find.text(itL10n.cryptoSetupSubmit));
    expect(find.text(itL10n.cryptoPasskeyCancelled), findsOneWidget);

    await tapAndSettle(tester, find.text(itL10n.cryptoSetupSubmit));
    expect(find.byType(RecoveryKeyOfferScreen), findsOneWidget);

    await tapVisible(tester, find.text(itL10n.cryptoRecoveryOfferLater));
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('setup on a device without passkeys explains why', (
    tester,
  ) async {
    await pumpGate(tester);
    passkeys.nextError = const PasskeyUnavailableException('no screen lock');
    await tapAndSettle(tester, find.text(itL10n.cryptoSetupSubmit));
    expect(find.text(itL10n.cryptoPasskeyUnavailable), findsOneWidget);
    expect(find.byType(CryptoSetupScreen), findsOneWidget);
  });

  testWidgets('the recovery key screen needs the checkbox to continue', (
    tester,
  ) async {
    await pumpGate(tester);
    await tapAndSettle(tester, find.text(itL10n.cryptoSetupSubmit));
    await tapAndSettle(tester, find.text(itL10n.cryptoRecoveryOfferCreate));
    final key =
        (container.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;
    expect(find.byType(RecoveryKeyScreen), findsOneWidget);
    expect(find.text(key), findsOneWidget);

    final continueButton = find.widgetWithText(
      FilledButton,
      itL10n.cryptoContinue,
    );
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tapVisible(tester, find.text(itL10n.cryptoRecoverySavedCheck));
    await tapVisible(tester, continueButton);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('a locked device unlocks with the passkey', (tester) async {
    await setUpElsewhere(tester);
    await pumpGate(tester);
    expect(find.byType(CryptoUnlockScreen), findsOneWidget);
    expect(find.text(itL10n.cryptoUnlockTitle), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    passkeys.nextError = const PasskeyNotFoundException();
    await tapAndSettle(tester, find.text(itL10n.cryptoUnlockSubmit));
    expect(find.text(itL10n.cryptoPasskeyNotFound), findsOneWidget);

    await tapAndSettle(tester, find.text(itL10n.cryptoUnlockSubmit));
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('lost passkey: the recovery key unlocks and adds a passkey', (
    tester,
  ) async {
    final recovery = await setUpElsewhere(tester, withRecoveryKey: true);
    await pumpGate(tester);

    await tapVisible(tester, find.text(itL10n.cryptoLostPasskey));
    expect(find.text(itL10n.cryptoRecoverTitle), findsOneWidget);
    expect(find.text(itL10n.cryptoBackToPasskey), findsOneWidget);
    expect(find.text(itL10n.cryptoNoRecoveryKey), findsOneWidget);

    await tapVisible(tester, find.text(itL10n.cryptoRecoverSubmit));
    expect(find.text(itL10n.cryptoRecoveryKeyInvalid), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), recovery!);
    await tapAndSettle(tester, find.text(itL10n.cryptoRecoverSubmit));
    expect(find.text('app'), findsOneWidget);
    expect(passkeys.creates, 2);
  });

  testWidgets('lost passkey without a recovery key asks to reset', (
    tester,
  ) async {
    await setUpElsewhere(tester);
    await pumpGate(tester);

    await tapVisible(tester, find.text(itL10n.cryptoLostPasskey));
    await tester.pumpAndSettle();
    expect(find.text(itL10n.cryptoResetTitle), findsOneWidget);
  });
}
