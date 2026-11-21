import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskenda/providers/core_providers.dart';
import 'package:taskenda/providers/settings/ui_provider.dart';
import 'package:taskenda/screens/onboarding_screen.dart';
import 'package:taskenda/screens/onboarding_wide.dart';

import '../helpers/l10n.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: OnboardingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a phone gets the carousel', (tester) async {
    await _pump(tester, const Size(400, 800));
    expect(find.byType(OnboardingWide), findsNothing);
    expect(find.byType(PageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [
    Size(900, 700),
    Size(1280, 800),
    Size(1920, 1080),
  ]) {
    testWidgets('a wide screen gets the landing page ($size)', (tester) async {
      await _pump(tester, size);
      expect(find.byType(OnboardingWide), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Benvenuto in Taskenda'), findsOneWidget);
      expect(find.text('Calendario · Attività · Note'), findsOneWidget);
      for (final title in [
        'Note',
        'Attività',
        'Calendario',
        'Notifiche e backup',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Inizia on the landing page marks the onboarding as seen', (
    tester,
  ) async {
    final container = await _pump(tester, const Size(1280, 800));
    await tester.tap(find.byIcon(Icons.arrow_forward));
    expect(container.read(onboardingSeenProvider), isTrue);
  });
}
