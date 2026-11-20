// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/screens/calendar/calendar_utils.dart';
import 'package:taskenda/utils/recurrence.dart';

CalendarEventModel _event(
  DateTime start, {
  RecurrenceType recurrence = RecurrenceType.none,
  DateTime? until,
}) => CalendarEventModel(
  title: 'Evento',
  startTime: start,
  endTime: start.add(const Duration(hours: 1)),
  recurrence: recurrence,
  recurrenceEndDate: until,
);

void main() {
  group('recurrenceTypeFromString', () {
    test('round-trips every value through toShortString', () {
      for (final type in RecurrenceType.values) {
        expect(recurrenceTypeFromString(type.toShortString()), type);
      }
    });

    test('falls back to none for unknown or empty values', () {
      expect(recurrenceTypeFromString('hourly'), RecurrenceType.none);
      expect(recurrenceTypeFromString(''), RecurrenceType.none);
      expect(recurrenceTypeFromString('Daily'), RecurrenceType.none);
    });
  });

  group('calendarEventOccursOn', () {
    final start = DateTime(2026, 3, 10, 18, 30); // Tuesday

    test('non-recurring event occurs only on its start day', () {
      final e = _event(start);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 10)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 10, 23, 59)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 11)), isFalse);
      expect(calendarEventOccursOn(e, DateTime(2027, 3, 10)), isFalse);
    });

    test('never occurs before the start day, whatever the recurrence', () {
      for (final type in RecurrenceType.values) {
        final e = _event(start, recurrence: type);
        expect(
          calendarEventOccursOn(e, DateTime(2026, 3, 9)),
          isFalse,
          reason: type.name,
        );
      }
    });

    test('ignores the time of day on both sides', () {
      final e = _event(start, recurrence: RecurrenceType.daily);
      // Earlier time than the event's start, same day.
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 10, 0, 0)), isTrue);
    });

    test('daily occurs every day from the start', () {
      final e = _event(start, recurrence: RecurrenceType.daily);
      for (var i = 0; i < 400; i++) {
        expect(
          calendarEventOccursOn(e, DateTime(2026, 3, 10 + i)),
          isTrue,
          reason: 'day +$i',
        );
      }
    });

    test('weekly occurs on the same weekday only', () {
      final e = _event(start, recurrence: RecurrenceType.weekly);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 17)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 12, 29)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 18)), isFalse);
    });

    test('monthly occurs on the same day of month', () {
      final e = _event(start, recurrence: RecurrenceType.monthly);
      expect(calendarEventOccursOn(e, DateTime(2026, 4, 10)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2027, 1, 10)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 4, 11)), isFalse);
    });

    test('monthly on the 31st skips months without a 31st', () {
      final e = _event(
        DateTime(2026, 1, 31),
        recurrence: RecurrenceType.monthly,
      );
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 31)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 2, 28)), isFalse);
      expect(calendarEventOccursOn(e, DateTime(2026, 4, 30)), isFalse);
    });

    test('yearly occurs on the same month and day', () {
      final e = _event(start, recurrence: RecurrenceType.yearly);
      expect(calendarEventOccursOn(e, DateTime(2030, 3, 10)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2027, 4, 10)), isFalse);
      expect(calendarEventOccursOn(e, DateTime(2027, 3, 11)), isFalse);
    });

    test('yearly on Feb 29 occurs only in leap years', () {
      final e = _event(
        DateTime(2024, 2, 29),
        recurrence: RecurrenceType.yearly,
      );
      expect(calendarEventOccursOn(e, DateTime(2028, 2, 29)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2025, 2, 28)), isFalse);
      expect(calendarEventOccursOn(e, DateTime(2025, 3, 1)), isFalse);
    });

    test('recurrence end date is inclusive and ignores its time', () {
      final e = _event(
        start,
        recurrence: RecurrenceType.daily,
        until: DateTime(2026, 3, 20, 0, 0),
      );
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 20, 22, 0)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 21)), isFalse);
    });

    test('recurrence end date stops weekly occurrences', () {
      final e = _event(
        start,
        recurrence: RecurrenceType.weekly,
        until: DateTime(2026, 3, 24),
      );
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 24)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 3, 31)), isFalse);
    });
  });

  group('custom recurrences', () {
    List<DateTime> days(CalendarEventModel e, DateTime from, int n) => [
      for (var i = 0; i < n; i++)
        if (e.occursOn(DateTime(from.year, from.month, from.day + i)))
          DateTime(from.year, from.month, from.day + i),
    ];

    test('every 3 days', () {
      final e = CalendarEventModel(
        startTime: DateTime(2026, 3, 27, 9), // across the DST change
        endTime: DateTime(2026, 3, 27, 10),
        recurrence: RecurrenceType.daily,
        recurrenceInterval: 3,
      );
      expect(days(e, DateTime(2026, 3, 27), 10), [
        DateTime(2026, 3, 27),
        DateTime(2026, 3, 30),
        DateTime(2026, 4, 2),
        DateTime(2026, 4, 5),
      ]);
    });

    test('every 2 weeks on Monday and Wednesday', () {
      final e = CalendarEventModel(
        startTime: DateTime(2026, 11, 2, 10), // Monday
        endTime: DateTime(2026, 11, 2, 11),
        recurrence: RecurrenceType.weekly,
        recurrenceInterval: 2,
        recurrenceWeekdays: const [1, 3],
      );
      expect(days(e, DateTime(2026, 11, 1), 30), [
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 30),
      ]);
    });

    test('second Tuesday and last Friday of the month', () {
      final second = CalendarEventModel(
        startTime: DateTime(2026, 1, 13), // second Tuesday
        endTime: DateTime(2026, 1, 14),
        isAllDay: true,
        recurrence: RecurrenceType.monthly,
        recurrenceMonthWeek: 2,
      );
      expect(second.occursOn(DateTime(2026, 2, 10)), isTrue);
      expect(second.occursOn(DateTime(2026, 2, 13)), isFalse);
      expect(second.occursOn(DateTime(2026, 3, 10)), isTrue);
      final last = CalendarEventModel(
        startTime: DateTime(2026, 1, 30), // last Friday
        endTime: DateTime(2026, 1, 31),
        isAllDay: true,
        recurrence: RecurrenceType.monthly,
        recurrenceMonthWeek: -1,
      );
      expect(last.occursOn(DateTime(2026, 2, 27)), isTrue);
      expect(last.occursOn(DateTime(2026, 2, 20)), isFalse);
      expect(last.occursOn(DateTime(2026, 5, 29)), isTrue);
    });

    test('every 2 months and every 2 years', () {
      final monthly = CalendarEventModel(
        startTime: DateTime(2026, 1, 15),
        endTime: DateTime(2026, 1, 16),
        recurrence: RecurrenceType.monthly,
        recurrenceInterval: 2,
      );
      expect(monthly.occursOn(DateTime(2026, 2, 15)), isFalse);
      expect(monthly.occursOn(DateTime(2026, 3, 15)), isTrue);
      final yearly = CalendarEventModel(
        startTime: DateTime(2026, 6, 1),
        endTime: DateTime(2026, 6, 2),
        recurrence: RecurrenceType.yearly,
        recurrenceInterval: 2,
      );
      expect(yearly.occursOn(DateTime(2027, 6, 1)), isFalse);
      expect(yearly.occursOn(DateTime(2028, 6, 1)), isTrue);
    });

    test('excluded dates are skipped, withoutOccurrence adds one', () {
      final e = CalendarEventModel(
        startTime: DateTime(2026, 11, 2, 10),
        endTime: DateTime(2026, 11, 2, 11),
        recurrence: RecurrenceType.weekly,
      ).withoutOccurrence(DateTime(2026, 11, 9, 10));
      expect(e.recurrenceExceptions, [DateTime(2026, 11, 9)]);
      expect(e.occursOn(DateTime(2026, 11, 9)), isFalse);
      expect(e.occursOn(DateTime(2026, 11, 16)), isTrue);
    });

    test('dayOfOccurrence counts the occurrences of the rule', () {
      final e = CalendarEventModel(
        startTime: DateTime(2026, 11, 2, 10), // Monday
        endTime: DateTime(2026, 11, 2, 11),
        recurrence: RecurrenceType.weekly,
        recurrenceWeekdays: const [1, 3, 5],
      );
      // Mon 2, Wed 4, Fri 6, Mon 9, Wed 11.
      expect(e.dayOfOccurrence(5), DateTime(2026, 11, 11));
    });

    test('JSON round trip keeps the rule; defaults stay out', () {
      final e = CalendarEventModel(
        startTime: DateTime(2026, 11, 2, 10),
        endTime: DateTime(2026, 11, 2, 11),
        recurrence: RecurrenceType.weekly,
        recurrenceInterval: 2,
        recurrenceWeekdays: const [1, 3],
        recurrenceExceptions: [DateTime(2026, 11, 16)],
      );
      final json = e.toJson();
      expect(json['recurrenceExceptions'], ['2026-11-16']);
      expect(json.containsKey('recurrenceMonthWeek'), isFalse);
      final back = CalendarEventModel.fromJson(json);
      expect(back.recurrenceInterval, 2);
      expect(back.recurrenceWeekdays, [1, 3]);
      expect(back.recurrenceExceptions, [DateTime(2026, 11, 16)]);
      final plain =
          CalendarEventModel(
            startTime: DateTime(2026, 11, 2),
            endTime: DateTime(2026, 11, 3),
          ).toJson();
      expect(plain.containsKey('recurrenceInterval'), isFalse);
      expect(plain.containsKey('recurrenceWeekdays'), isFalse);
      expect(plain.containsKey('recurrenceExceptions'), isFalse);
    });
  });
}
