// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/foundation.dart';
import '../models/calendar_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import 'recurrence.dart';

/// How many items of a kind are active, archived and in the trash.
@immutable
class StateCounts {
  const StateCounts(this.active, this.archived, this.trashed);
  final int active;
  final int archived;
  final int trashed;
}

/// Items created in the week starting on [weekStart] (a Monday).
@immutable
class WeekActivity {
  const WeekActivity(this.weekStart, this.notes, this.tasks, this.events);
  final DateTime weekStart;
  final int notes;
  final int tasks;
  final int events;
  int get total => notes + tasks + events;
}

/// A label and how many notes, tasks and events carry it.
@immutable
class LabelUsage {
  const LabelUsage(this.label, this.count);
  final String label;
  final int count;
}

/// Everything the Statistics screen shows, computed by [computeStatistics].
@immutable
class StatisticsData {
  const StatisticsData({
    required this.notes,
    required this.tasks,
    required this.events,
    required this.openTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.dueTodayTasks,
    required this.dueThisWeekTasks,
    required this.noDueDateTasks,
    required this.eventsThisWeek,
    required this.createdThisWeek,
    required this.weeks,
    required this.mostActiveWeekday,
    required this.topLabels,
  });

  final StateCounts notes;
  final StateCounts tasks;
  final StateCounts events;

  /// Active tasks (not archived or trashed), open and completed.
  final int openTasks;
  final int completedTasks;

  /// Open tasks by due date: past due, due today (not past yet), due later
  /// this week (by Sunday), without a due date.
  final int overdueTasks;
  final int dueTodayTasks;
  final int dueThisWeekTasks;
  final int noDueDateTasks;

  /// Occurrences of active events from Monday to Sunday of this week.
  final int eventsThisWeek;

  /// Notes, tasks and events (not trashed) created since this Monday.
  final int createdThisWeek;

  /// Items created per week, oldest first; the last one is this week.
  final List<WeekActivity> weeks;

  /// Weekday (1 = Monday … 7 = Sunday) on which most items were created,
  /// null when there are none.
  final int? mostActiveWeekday;

  /// The most used labels, most used first.
  final List<LabelUsage> topLabels;

  /// Share of active tasks that are completed (0 when there are none).
  double get completionRate {
    final total = openTasks + completedTasks;
    return total == 0 ? 0 : completedTasks / total;
  }
}

/// Computes the statistics at [now]. Activity, weekday and labels count the
/// items not in the trash (active and archived).
StatisticsData computeStatistics({
  required List<NoteModel> activeNotes,
  required List<NoteModel> archivedNotes,
  required List<NoteModel> trashedNotes,
  required List<TaskModel> activeTasks,
  required List<TaskModel> archivedTasks,
  required List<TaskModel> trashedTasks,
  required List<CalendarEventModel> activeEvents,
  required List<CalendarEventModel> archivedEvents,
  required List<CalendarEventModel> trashedEvents,
  required DateTime now,
  int weekCount = 12,
  int topLabelCount = 5,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  // ─── Tasks ────────────────────────────────────────────────────────────────
  var open = 0, completed = 0, overdue = 0, dueToday = 0, dueWeek = 0;
  var noDue = 0;
  for (final t in activeTasks) {
    if (t.isCompleted) {
      completed++;
      continue;
    }
    open++;
    final due = t.dueDate;
    if (due == null) {
      noDue++;
      continue;
    }
    final day = dayOf(due);
    final past = t.hasDueTime ? due.isBefore(now) : day.isBefore(today);
    if (past) {
      overdue++;
    } else if (day == today) {
      dueToday++;
    } else if (day.isBefore(nextMonday)) {
      dueWeek++;
    }
  }

  // ─── Events this week ─────────────────────────────────────────────────────
  var eventsThisWeek = 0;
  for (var i = 0; i < 7; i++) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    for (final e in activeEvents) {
      if (e.occursOn(day)) eventsThisWeek++;
    }
  }

  // ─── Activity, weekday, labels ────────────────────────────────────────────
  final firstWeek = DateTime(
    monday.year,
    monday.month,
    monday.day - 7 * (weekCount - 1),
  );
  final perWeek = List.generate(weekCount, (_) => [0, 0, 0]);
  final perWeekday = List.filled(7, 0);
  final labels = <String, int>{};
  var createdThisWeek = 0;

  void count(DateTime createdAt, List<String> tags, int kind) {
    final day = dayOf(createdAt);
    final days = calendarDaysBetween(firstWeek, day);
    if (days >= 0 && days < weekCount * 7) perWeek[days ~/ 7][kind]++;
    if (!day.isBefore(monday)) createdThisWeek++;
    perWeekday[day.weekday - 1]++;
    for (final tag in tags.toSet()) {
      labels[tag] = (labels[tag] ?? 0) + 1;
    }
  }

  for (final n in [...activeNotes, ...archivedNotes]) {
    count(n.createdAt, n.tags, 0);
  }
  for (final t in [...activeTasks, ...archivedTasks]) {
    count(t.createdAt, t.tags, 1);
  }
  for (final e in [...activeEvents, ...archivedEvents]) {
    count(e.createdAt, e.tags, 2);
  }

  int? mostActive;
  for (var i = 0; i < 7; i++) {
    if (perWeekday[i] > 0 &&
        (mostActive == null || perWeekday[i] > perWeekday[mostActive - 1])) {
      mostActive = i + 1;
    }
  }

  final topLabels =
      (labels.entries.map((e) => LabelUsage(e.key, e.value)).toList()..sort(
            (a, b) =>
                a.count != b.count
                    ? b.count.compareTo(a.count)
                    : a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          ))
          .take(topLabelCount)
          .toList();

  return StatisticsData(
    notes: StateCounts(
      activeNotes.length,
      archivedNotes.length,
      trashedNotes.length,
    ),
    tasks: StateCounts(
      activeTasks.length,
      archivedTasks.length,
      trashedTasks.length,
    ),
    events: StateCounts(
      activeEvents.length,
      archivedEvents.length,
      trashedEvents.length,
    ),
    openTasks: open,
    completedTasks: completed,
    overdueTasks: overdue,
    dueTodayTasks: dueToday,
    dueThisWeekTasks: dueWeek,
    noDueDateTasks: noDue,
    eventsThisWeek: eventsThisWeek,
    createdThisWeek: createdThisWeek,
    weeks: [
      for (var i = 0; i < weekCount; i++)
        WeekActivity(
          DateTime(firstWeek.year, firstWeek.month, firstWeek.day + 7 * i),
          perWeek[i][0],
          perWeek[i][1],
          perWeek[i][2],
        ),
    ],
    mostActiveWeekday: mostActive,
    topLabels: topLabels,
  );
}
