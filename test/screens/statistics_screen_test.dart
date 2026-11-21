import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/note_model.dart';
import 'package:taskenda/models/task_model.dart';
import 'package:taskenda/providers/statistics_provider.dart';
import 'package:taskenda/screens/statistics/statistics_screen.dart';
import 'package:taskenda/utils/statistics.dart';

import '../helpers/l10n.dart';

StatisticsData _stats({bool empty = false}) {
  final now = DateTime.now();
  return computeStatistics(
    activeNotes:
        empty
            ? const []
            : [
              for (var i = 0; i < 30; i++)
                NoteModel(
                  createdAt: now.subtract(Duration(days: i * 2)),
                  tags: ['etichetta con un nome molto lungo $i', 'lavoro'],
                ),
            ],
    archivedNotes: const [],
    trashedNotes: const [],
    activeTasks:
        empty
            ? const []
            : [
              TaskModel(dueDate: now.subtract(const Duration(days: 1))),
              TaskModel(isCompleted: true),
              TaskModel(),
            ],
    archivedTasks: const [],
    trashedTasks: const [],
    activeEvents: const [],
    archivedEvents: const [],
    trashedEvents: const [],
    now: now,
  );
}

Future<void> _pump(WidgetTester tester, StatisticsData stats, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [statisticsProvider.overrideWithValue(stats)],
      child: const MaterialApp(
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: StatisticsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows every block without overflow on a narrow phone', (
    tester,
  ) async {
    await _pump(tester, _stats(), const Size(320, 3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Panoramica'), findsOneWidget);
    expect(find.text('Attività'), findsOneWidget);
    expect(find.text('Etichette più usate'), findsOneWidget);
    expect(find.text('lavoro'), findsOneWidget);
    expect(find.text('Riepilogo'), findsOneWidget);
    expect(find.textContaining('Giorno più attivo'), findsOneWidget);
  });

  testWidgets('shows the empty states', (tester) async {
    await _pump(tester, _stats(empty: true), const Size(400, 3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nessun task presente'), findsOneWidget);
    expect(find.text('Nessuna etichetta usata'), findsOneWidget);
  });
}
