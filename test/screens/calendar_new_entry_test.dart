import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/routing/shared_text_launch_handler.dart';
import 'package:taskenda/providers/calendar_provider.dart';
import 'package:taskenda/screens/calendar/calendar_new_entry.dart';

void main() {
  group('newEntryDay', () {
    // Wednesday 25 November 2026.
    final now = DateTime(2026, 11, 25, 15, 30);

    DateTime day(
      CalendarViewMode mode, {
      DateTime? focusedDay,
      DateTime? focusedMonth,
      DateTime? scheduleTop,
    }) => newEntryDay(
      mode,
      focusedDay: focusedDay ?? now,
      focusedMonth: focusedMonth ?? DateTime(now.year, now.month),
      scheduleTop: scheduleTop,
      now: now,
    );

    test('day view uses the day shown', () {
      expect(
        day(CalendarViewMode.day, focusedDay: DateTime(2026, 12, 3, 9)),
        DateTime(2026, 12, 3),
      );
    });

    test('week view: today if in the week, else its Monday', () {
      expect(day(CalendarViewMode.week), DateTime(2026, 11, 25));
      expect(
        day(CalendarViewMode.week, focusedDay: DateTime(2026, 12, 4)),
        DateTime(2026, 11, 30),
      );
    });

    test('seven days view: today if in range, else the first day', () {
      expect(
        day(CalendarViewMode.sevenDays, focusedDay: DateTime(2026, 11, 20)),
        DateTime(2026, 11, 25),
      );
      expect(
        day(CalendarViewMode.sevenDays, focusedDay: DateTime(2026, 12, 10)),
        DateTime(2026, 12, 10),
      );
    });

    test('month view: today in the current month, else the 1st', () {
      expect(day(CalendarViewMode.month), DateTime(2026, 11, 25));
      expect(
        day(CalendarViewMode.month, focusedMonth: DateTime(2027, 2)),
        DateTime(2027, 2, 1),
      );
    });

    test('year view: today in the current year, else 1 January', () {
      expect(day(CalendarViewMode.year), DateTime(2026, 11, 25));
      expect(
        day(CalendarViewMode.year, focusedMonth: DateTime(2028, 6)),
        DateTime(2028),
      );
    });

    test('schedule: the day at the top, today without one', () {
      expect(day(CalendarViewMode.schedule), DateTime(2026, 11, 25));
      expect(
        day(CalendarViewMode.schedule, scheduleTop: DateTime(2027, 1, 8)),
        DateTime(2027, 1, 8),
      );
    });
  });

  group('SharedText', () {
    test('subject becomes the title, text the body', () {
      const shared = SharedText(
        subject: 'Article',
        text: 'https://example.com',
      );
      expect(shared.title, 'Article');
      expect(shared.body, 'https://example.com');
    });

    test('a short single line is the title', () {
      const shared = SharedText(text: 'Buy milk');
      expect(shared.title, 'Buy milk');
      expect(shared.body, '');
    });

    test('a long or multi-line text is the body', () {
      const shared = SharedText(text: 'Line one\nLine two');
      expect(shared.title, '');
      expect(shared.body, 'Line one\nLine two');
      final long = SharedText(text: 'a' * (SharedText.maxTitleLength + 1));
      expect(long.title, '');
    });

    test('fromMap trims and drops empty text', () {
      expect(SharedText.fromMap({'subject': ' ', 'text': ''}), isNull);
      expect(SharedText.fromMap(null), isNull);
      expect(
        SharedText.fromMap({'subject': '', 'text': ' hi '}),
        const SharedText(text: 'hi'),
      );
    });
  });
}
