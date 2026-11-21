import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/models/task_model.dart';
import 'package:taskenda/utils/recurrence.dart';

void main() {
  // Every Friday at 19:00, from Friday 27 Nov 2026.
  TaskModel weekly() => TaskModel(
    title: 'Weekly',
    dueDate: DateTime(2026, 11, 27, 19),
    recurrence: RecurrenceType.weekly,
  );

  group('TaskModel.withoutOccurrence', () {
    test('a later occurrence is left out, the due date stays', () {
      final t = weekly().withoutOccurrence(DateTime(2027, 1, 1));
      expect(t.dueDate, DateTime(2026, 11, 27, 19));
      expect(t.recurrenceExceptions, [DateTime(2027, 1, 1)]);
      final event = TaskCalendarEvent(t);
      expect(event.occursOn(DateTime(2027, 1, 1)), isFalse);
      expect(event.occursOn(DateTime(2026, 11, 27)), isTrue);
      expect(event.occursOn(DateTime(2027, 1, 8)), isTrue);
    });

    test('the current occurrence moves the task on', () {
      final t = weekly().withoutOccurrence(DateTime(2026, 11, 27));
      expect(t.dueDate, DateTime(2026, 12, 4, 19));
      expect(t.recurrenceExceptions, isEmpty);
    });

    test('moving on skips the days left out and drops past ones', () {
      final t = weekly()
          .withoutOccurrence(DateTime(2026, 12, 4))
          .withoutOccurrence(DateTime(2027, 1, 1))
          .nextOccurrence();
      expect(t.dueDate, DateTime(2026, 12, 11, 19));
      expect(t.recurrenceExceptions, [DateTime(2027, 1, 1)]);
    });

    test('exceptions survive a JSON round trip', () {
      final t = weekly().withoutOccurrence(DateTime(2027, 1, 1));
      final back = TaskModel.fromJson(t.toJson());
      expect(back.recurrenceExceptions, [DateTime(2027, 1, 1)]);
      expect(weekly().toJson().containsKey('recurrenceExceptions'), isFalse);
    });
  });
}
