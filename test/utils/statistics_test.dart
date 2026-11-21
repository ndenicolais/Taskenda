import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/models/note_model.dart';
import 'package:taskenda/models/task_model.dart';
import 'package:taskenda/utils/recurrence.dart';
import 'package:taskenda/utils/statistics.dart';

void main() {
  // Wednesday 25 Nov 2026, 12:00: the week runs Mon 23 – Sun 29.
  final now = DateTime(2026, 11, 25, 12);

  StatisticsData compute({
    List<NoteModel> notes = const [],
    List<NoteModel> archivedNotes = const [],
    List<NoteModel> trashedNotes = const [],
    List<TaskModel> tasks = const [],
    List<CalendarEventModel> events = const [],
  }) => computeStatistics(
    activeNotes: notes,
    archivedNotes: archivedNotes,
    trashedNotes: trashedNotes,
    activeTasks: tasks,
    archivedTasks: const [],
    trashedTasks: const [],
    activeEvents: events,
    archivedEvents: const [],
    trashedEvents: const [],
    now: now,
  );

  test('tasks are split by due date and completion', () {
    final s = compute(
      tasks: [
        TaskModel(dueDate: DateTime(2026, 11, 24)), // yesterday
        TaskModel(dueDate: DateTime(2026, 11, 25, 9)), // today, past time
        TaskModel(dueDate: DateTime(2026, 11, 25)), // today, date only
        TaskModel(dueDate: DateTime(2026, 11, 25, 18)), // today, later
        TaskModel(dueDate: DateTime(2026, 11, 29)), // Sunday
        TaskModel(dueDate: DateTime(2026, 11, 30)), // next week
        TaskModel(), // no due date
        TaskModel(isCompleted: true),
      ],
    );
    expect(s.overdueTasks, 2);
    expect(s.dueTodayTasks, 2);
    expect(s.dueThisWeekTasks, 1);
    expect(s.noDueDateTasks, 1);
    expect(s.openTasks, 7);
    expect(s.completedTasks, 1);
    expect(s.completionRate, closeTo(1 / 8, 1e-9));
  });

  test('events this week count recurring occurrences', () {
    final s = compute(
      events: [
        CalendarEventModel(
          startTime: DateTime(2026, 11, 1, 9),
          endTime: DateTime(2026, 11, 1, 10),
          recurrence: RecurrenceType.daily,
        ),
        CalendarEventModel(
          startTime: DateTime(2026, 12, 2, 9),
          endTime: DateTime(2026, 12, 2, 10),
        ),
      ],
    );
    expect(s.eventsThisWeek, 7);
  });

  test('activity buckets items by week, skipping the trash', () {
    final s = compute(
      notes: [
        NoteModel(createdAt: DateTime(2026, 11, 23, 8), tags: ['work']),
        NoteModel(createdAt: DateTime(2026, 11, 16), tags: ['work', 'home']),
      ],
      archivedNotes: [NoteModel(createdAt: DateTime(2026, 11, 24))],
      trashedNotes: [NoteModel(createdAt: DateTime(2026, 11, 24))],
      tasks: [
        TaskModel(createdAt: DateTime(2026, 11, 23), tags: ['home']),
      ],
    );
    expect(s.weeks, hasLength(12));
    expect(s.weeks.last.weekStart, DateTime(2026, 11, 23));
    expect(s.weeks.last.notes, 2);
    expect(s.weeks.last.tasks, 1);
    expect(s.weeks[10].notes, 1);
    expect(s.createdThisWeek, 3);
    expect(s.mostActiveWeekday, DateTime.monday);
    expect(s.notes.trashed, 1);
    expect(s.topLabels.map((l) => (l.label, l.count)), [
      ('home', 2),
      ('work', 2),
    ]);
  });

  test('no items: no most active day, no labels', () {
    final s = compute();
    expect(s.mostActiveWeekday, isNull);
    expect(s.topLabels, isEmpty);
    expect(s.completionRate, 0);
    expect(s.weeks.every((w) => w.total == 0), isTrue);
  });
}
