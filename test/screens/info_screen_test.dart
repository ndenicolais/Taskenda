import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/constants/app_info.dart';
import 'package:taskenda/core/constants/app_version.dart';
import 'package:taskenda/screens/info_screen.dart';

import '../helpers/l10n.dart';

Future<void> _pump(WidgetTester tester, {Size size = const Size(400, 2000)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    const MaterialApp(
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: InfoScreen(),
    ),
  );
}

void main() {
  testWidgets('shows identity, version, features, links and credits', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Taskenda'), findsOneWidget);
    expect(find.text('Versione $appVersion'), findsOneWidget);
    expect(find.text('FUNZIONALITÀ'), findsOneWidget);
    expect(find.text('Pagina del progetto'), findsOneWidget);
    expect(find.text('Condividi Taskenda'), findsOneWidget);
    expect(find.text('Codice sorgente'), findsOneWidget);
    expect(find.text('Realizzato da $developerName'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow on a narrow phone', (tester) async {
    await _pump(tester, size: const Size(320, 2400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the full width on a wide screen', (tester) async {
    await _pump(tester, size: const Size(1400, 1600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ListView)).width, 1400);
    // The four features share one row.
    final tops = [
      for (final e in find.byType(Card).evaluate().take(5))
        tester.getTopLeft(find.byWidget(e.widget)).dy,
    ];
    expect(tops.toSet().length, lessThan(tops.length));
  });

  testWidgets('opens the open source licenses page', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Licenze open source'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
