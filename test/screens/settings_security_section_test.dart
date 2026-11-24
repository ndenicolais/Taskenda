import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/providers/crypto_provider.dart';
import 'package:taskenda/screens/settings/settings_security_section.dart';

import '../helpers/crypto.dart';
import '../helpers/l10n.dart';
import '../helpers/test_container.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpSection(WidgetTester tester) async {
    container = createTestContainer(
      FakeFirebaseFirestore(),
      uid: 'u1',
      overrides: cryptoOverrides(MemoryKeyStorage()),
    );
    container.listen(cryptoProvider, (_, _) {});
    await tester.runAsync(() async {
      await settledCrypto(container);
      await container.read(cryptoProvider.notifier).setup('passphrase');
    });
    container.read(cryptoProvider.notifier).acknowledgeRecoveryKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: testLocale,
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationsDelegates,
          home: Scaffold(body: SettingsSecuritySection()),
        ),
      ),
    );
  }

  testWidgets('shows both actions', (tester) async {
    await pumpSection(tester);
    expect(find.text(itL10n.settingsSecurityTitle), findsOneWidget);
    expect(find.text(itL10n.securityChangePassphrase), findsOneWidget);
    expect(find.text(itL10n.securityNewRecoveryKey), findsOneWidget);
  });

  testWidgets('change code: validation, then a wrong current code', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.text(itL10n.securityChangePassphrase));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.text(itL10n.commonSave));
    await tester.pump();
    expect(find.text(itL10n.cryptoPassphraseEmpty), findsOneWidget);
    expect(find.text(itL10n.cryptoPassphraseTooShort(8)), findsOneWidget);

    await tester.enterText(fields.at(0), 'wrong code');
    await tester.enterText(fields.at(1), 'new passphrase');
    await tester.enterText(fields.at(2), 'new passphrase');
    await tester.tap(find.text(itL10n.commonSave));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text(itL10n.cryptoUnlockWrong), findsOneWidget);
  });

  testWidgets('new recovery code is shown until the user saved it', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.text(itL10n.securityNewRecoveryKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'passphrase');
    await tester.tap(find.text(itL10n.cryptoContinue));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text(itL10n.cryptoRecoveryShowTitle), findsOneWidget);
    final done = find.widgetWithText(FilledButton, itL10n.commonDone);
    expect(tester.widget<FilledButton>(done).onPressed, isNull);
    await tester.tap(find.text(itL10n.cryptoRecoverySavedCheck));
    await tester.pump();
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.text(itL10n.cryptoRecoveryShowTitle), findsNothing);
  });
}
