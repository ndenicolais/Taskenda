import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  late ProviderContainer container;

  setUp(() {
    db = FakeFirebaseFirestore();
    storage = MemoryKeyStorage();
  });

  Future<void> pumpGate(WidgetTester tester) async {
    container = createTestContainer(
      db,
      uid: 'u1',
      overrides: cryptoOverrides(storage),
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

  /// Runs [action] (real crypto, real async) and rebuilds.
  Future<void> run(WidgetTester tester, Future<void> Function() action) async {
    await tester.runAsync(action);
    await tester.pump();
  }

  testWidgets('setup validates the code, then shows the recovery key', (
    tester,
  ) async {
    await pumpGate(tester);
    expect(find.byType(CryptoSetupScreen), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'other');
    await tapVisible(tester, find.text(itL10n.cryptoSetupSubmit));
    expect(find.text(itL10n.cryptoPassphraseTooShort(8)), findsOneWidget);
    expect(find.text(itL10n.cryptoPassphraseMismatch), findsOneWidget);

    await tester.enterText(fields.at(0), 'long passphrase');
    await tester.enterText(fields.at(1), 'long passphrase');
    // The button only starts the work: let it finish outside fake time.
    await run(tester, () async {
      await container
          .read(cryptoProvider.notifier)
          .setup('long passphrase')
          .catchError((_) {});
    });
    expect(find.byType(RecoveryKeyScreen), findsOneWidget);
  });

  testWidgets('the recovery key screen needs the checkbox to continue', (
    tester,
  ) async {
    await pumpGate(tester);
    await run(
      tester,
      () => container.read(cryptoProvider.notifier).setup('long passphrase'),
    );
    final key =
        (container.read(cryptoProvider) as CryptoUnlocked).pendingRecoveryKey!;
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

  testWidgets('a locked device shows unlock, and recovery on request', (
    tester,
  ) async {
    // Keys created by another device.
    final other = createTestContainer(
      db,
      uid: 'u1',
      overrides: cryptoOverrides(MemoryKeyStorage()),
    );
    other.listen(cryptoProvider, (_, _) {});
    await tester.runAsync(() async {
      await settledCrypto(other);
      await other.read(cryptoProvider.notifier).setup('long passphrase');
    });

    await pumpGate(tester);
    expect(find.byType(CryptoUnlockScreen), findsOneWidget);
    expect(find.text(itL10n.cryptoUnlockTitle), findsOneWidget);

    await tapVisible(tester, find.text(itL10n.cryptoForgotPassphrase));
    expect(find.text(itL10n.cryptoRecoverTitle), findsOneWidget);
    expect(find.text(itL10n.cryptoNoRecoveryKey), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));

    await run(
      tester,
      () => container.read(cryptoProvider.notifier).unlock('long passphrase'),
    );
    expect(find.text('app'), findsOneWidget);
  });
}
