import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/passkey_client.dart';
import 'package:taskenda/providers/crypto_provider.dart';
import 'package:taskenda/screens/settings/settings_security_section.dart';

import '../helpers/crypto.dart';
import '../helpers/l10n.dart';
import '../helpers/test_container.dart';

void main() {
  late ProviderContainer container;
  late FakePasskeyClient passkeys;

  Future<void> pumpSection(WidgetTester tester) async {
    passkeys = FakePasskeyClient();
    container = createTestContainer(
      FakeFirebaseFirestore(),
      uid: 'u1',
      overrides: cryptoOverrides(MemoryKeyStorage(), passkeys),
    );
    container.listen(cryptoProvider, (_, _) {});
    await tester.runAsync(() async {
      await settledCrypto(container);
      await container.read(cryptoProvider.notifier).setup();
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

  Future<void> tapAndWait(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the recovery code action only', (tester) async {
    await pumpSection(tester);
    expect(find.text(itL10n.settingsSecurityTitle), findsOneWidget);
    expect(find.text(itL10n.securityNewRecoveryKey), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('a cancelled passkey shows a message and no code', (
    tester,
  ) async {
    await pumpSection(tester);
    passkeys.nextError = const PasskeyCancelledException();
    await tapAndWait(tester, itL10n.securityNewRecoveryKey);
    expect(find.text(itL10n.cryptoPasskeyCancelled), findsOneWidget);
    expect(find.text(itL10n.cryptoRecoveryShowTitle), findsNothing);
  });

  testWidgets('new recovery code is shown until the user saved it', (
    tester,
  ) async {
    await pumpSection(tester);
    await tapAndWait(tester, itL10n.securityNewRecoveryKey);

    expect(passkeys.gets, 1);
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
