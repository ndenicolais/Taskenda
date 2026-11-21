// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/statistics.dart';
import 'calendar_provider.dart';
import 'notes_provider.dart';
import 'tasks_provider.dart';

/// The Statistics screen's figures, recomputed when notes, tasks or events
/// change (see [computeStatistics]).
final statisticsProvider = Provider<StatisticsData>(
  (ref) => computeStatistics(
    activeNotes: ref.watch(activeNotesProvider),
    archivedNotes: ref.watch(archivedNotesProvider),
    trashedNotes: ref.watch(trashedNotesProvider),
    activeTasks: ref.watch(activeTasksProvider),
    archivedTasks: ref.watch(archivedTasksProvider),
    trashedTasks: ref.watch(trashedTasksProvider),
    activeEvents: ref.watch(activeEventsProvider),
    archivedEvents: ref.watch(archivedEventsProvider),
    trashedEvents: ref.watch(trashedEventsProvider),
    now: DateTime.now(),
  ),
);
