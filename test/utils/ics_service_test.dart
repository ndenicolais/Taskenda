// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/screens/calendar/calendar_utils.dart';
import 'package:taskenda/utils/ics_export_service.dart';
import 'package:taskenda/utils/event_alerts.dart';
import 'package:taskenda/utils/ics_import_service.dart';
import 'package:taskenda/utils/recurrence.dart';
import 'package:timezone/data/latest.dart' as tz_data;

String _ics(List<String> eventLines) => [
  'BEGIN:VCALENDAR',
  'VERSION:2.0',
  'BEGIN:VEVENT',
  ...eventLines,
  'END:VEVENT',
  'END:VCALENDAR',
].join('\r\n');

CalendarEventModel _single(List<String> eventLines) {
  final events = IcsImportService.parseIcs(_ics(eventLines));
  expect(events, hasLength(1));
  return events.single;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('IcsImportService.parseIcs', () {
    test('parses an all-day event', () {
      final e = _single([
        'UID:abc-123',
        'SUMMARY:Ferie',
        'DTSTART;VALUE=DATE:20260810',
        'DTEND;VALUE=DATE:20260811',
      ]);
      expect(e.id, 'abc-123');
      expect(e.title, 'Ferie');
      expect(e.isAllDay, isTrue);
      expect(e.startTime, DateTime(2026, 8, 10));
      expect(e.endTime, DateTime(2026, 8, 11));
      expect(e.recurrence, RecurrenceType.none);
    });

    test('converts UTC times to local', () {
      final e = _single([
        'SUMMARY:Call',
        'DTSTART:20260115T090000Z',
        'DTEND:20260115T100000Z',
      ]);
      expect(e.isAllDay, isFalse);
      expect(e.startTime, DateTime.utc(2026, 1, 15, 9).toLocal());
      expect(e.endTime, DateTime.utc(2026, 1, 15, 10).toLocal());
    });

    test('honours TZID on DTSTART', () {
      final e = _single([
        'SUMMARY:NY meeting',
        'DTSTART;TZID=America/New_York:20260115T090000',
      ]);
      // 09:00 EST (UTC-5) is 14:00 UTC.
      expect(e.startTime, DateTime.utc(2026, 1, 15, 14).toLocal());
      expect(e.startTime.isUtc, isFalse);
    });

    test('defaults the end to +1h (timed) or +1 day (all-day)', () {
      final timed = _single(['SUMMARY:A', 'DTSTART:20260115T090000']);
      expect(timed.endTime, DateTime(2026, 1, 15, 10));
      final allDay = _single(['SUMMARY:B', 'DTSTART;VALUE=DATE:20260115']);
      expect(allDay.endTime, DateTime(2026, 1, 16));
    });

    test('skips events without summary or with an invalid start', () {
      expect(
        IcsImportService.parseIcs(_ics(['DTSTART:20260115T090000'])),
        isEmpty,
      );
      expect(
        IcsImportService.parseIcs(_ics(['SUMMARY:X', 'DTSTART:boh'])),
        isEmpty,
      );
      expect(IcsImportService.parseIcs(_ics(['SUMMARY:X'])), isEmpty);
    });

    test('unfolds continuation lines', () {
      final e = _single([
        'SUMMARY:Riunione di',
        '  progetto',
        'DTSTART;VALUE=DATE:20260115',
      ]);
      expect(e.title, 'Riunione di progetto');
    });

    test('unescapes text, including an escaped backslash before n', () {
      final e = _single([
        r'SUMMARY:Pane\, latte\; uova',
        r'DESCRIPTION:riga 1\nriga 2 C:\\new',
        'DTSTART;VALUE=DATE:20260115',
      ]);
      expect(e.title, 'Pane, latte; uova');
      expect(e.description, 'riga 1\nriga 2 C:\\new');
    });

    test('strips HTML from the description', () {
      final e = _single([
        'SUMMARY:X',
        'DESCRIPTION:<b>uno</b><br>due',
        'DTSTART;VALUE=DATE:20260115',
      ]);
      expect(e.description, 'uno\ndue');
    });

    test('flags birthdays from CATEGORIES', () {
      final e = _single([
        'SUMMARY:Mario',
        'CATEGORIES:BIRTHDAY',
        'DTSTART;VALUE=DATE:19900501',
        'RRULE:FREQ=YEARLY',
      ]);
      expect(e.isBirthday, isTrue);
      expect(e.recurrence, RecurrenceType.yearly);
      expect(e.recurrenceEndDate, isNull);
    });

    test('maps every RRULE frequency', () {
      const map = {
        'DAILY': RecurrenceType.daily,
        'WEEKLY': RecurrenceType.weekly,
        'MONTHLY': RecurrenceType.monthly,
        'YEARLY': RecurrenceType.yearly,
      };
      map.forEach((freq, type) {
        final e = _single([
          'SUMMARY:X',
          'DTSTART;VALUE=DATE:20260115',
          'RRULE:FREQ=$freq',
        ]);
        expect(e.recurrence, type, reason: freq);
      });
    });

    test('resolves UNTIL into an end date', () {
      final e = _single([
        'SUMMARY:X',
        'DTSTART;VALUE=DATE:20260115',
        'RRULE:FREQ=WEEKLY;UNTIL=20260312',
      ]);
      expect(e.recurrenceEndDate, DateTime(2026, 3, 12));
    });

    test('resolves COUNT into the date of the last occurrence', () {
      DateTime? endFor(String freq, int count) =>
          _single([
            'SUMMARY:X',
            'DTSTART;VALUE=DATE:20260131',
            'RRULE:FREQ=$freq;COUNT=$count',
          ]).recurrenceEndDate;

      expect(endFor('DAILY', 1), DateTime(2026, 1, 31));
      expect(endFor('DAILY', 3), DateTime(2026, 2, 2));
      expect(endFor('WEEKLY', 3), DateTime(2026, 2, 14));
      expect(endFor('YEARLY', 3), DateTime(2028, 1, 31));
    });

    test('COUNT keeps the last occurrence across a DST change', () {
      // Starts at local midnight; the range crosses the end of daylight
      // saving time in zones that observe it (last Sunday of October in
      // Europe, first Sunday of November in the US).
      final e = _single([
        'SUMMARY:X',
        'DTSTART;VALUE=DATE:20261020',
        'RRULE:FREQ=DAILY;COUNT=20',
      ]);
      expect(_day(e.recurrenceEndDate!), DateTime(2026, 11, 8));
      expect(calendarEventOccursOn(e, DateTime(2026, 11, 8)), isTrue);
      expect(calendarEventOccursOn(e, DateTime(2026, 11, 9)), isFalse);

      final w = _single([
        'SUMMARY:X',
        'DTSTART;VALUE=DATE:20261013',
        'RRULE:FREQ=WEEKLY;COUNT=5',
      ]);
      expect(_day(w.recurrenceEndDate!), DateTime(2026, 11, 10));
    });

    test('parses several events and ignores lines outside VEVENT', () {
      const ics =
          'BEGIN:VCALENDAR\r\n'
          'SUMMARY:fuori\r\n'
          'BEGIN:VEVENT\r\nSUMMARY:Uno\r\nDTSTART;VALUE=DATE:20260101\r\n'
          'END:VEVENT\r\n'
          'BEGIN:VEVENT\nSUMMARY:Due\nDTSTART;VALUE=DATE:20260102\n'
          'END:VEVENT\n'
          'END:VCALENDAR';
      final events = IcsImportService.parseIcs(ics);
      expect(events.map((e) => e.title), ['Uno', 'Due']);
    });
  });

  group('IcsExportService.generateIcs', () {
    test('writes all-day dates and an RRULE', () {
      final ics = IcsExportService.generateIcs([
        CalendarEventModel(
          id: 'id-1',
          title: 'Compleanno',
          startTime: DateTime(2026, 5, 1),
          endTime: DateTime(2026, 5, 2),
          isAllDay: true,
          isBirthday: true,
          recurrence: RecurrenceType.yearly,
        ),
      ]);
      expect(ics, contains('UID:id-1'));
      expect(ics, contains('DTSTART;VALUE=DATE:20260501'));
      expect(ics, contains('DTEND;VALUE=DATE:20260502'));
      expect(ics, contains('RRULE:FREQ=YEARLY'));
      expect(ics, contains('CATEGORIES:BIRTHDAY'));
    });

    test('uses a placeholder title for untitled events', () {
      // The placeholder is in the UI language.
      addTearDown(() => Intl.defaultLocale = null);
      Intl.defaultLocale = 'it';
      final ics = IcsExportService.generateIcs([
        CalendarEventModel(
          startTime: DateTime(2026, 5, 1),
          endTime: DateTime(2026, 5, 2),
          isAllDay: true,
        ),
      ]);
      expect(ics, contains('SUMMARY:(senza titolo)'));
    });

    test('writes timed events in UTC', () {
      final start = DateTime(2026, 1, 15, 9, 30);
      final ics = IcsExportService.generateIcs([
        CalendarEventModel(
          title: 'X',
          startTime: start,
          endTime: start.add(const Duration(hours: 1)),
        ),
      ]);
      final u = start.toUtc();
      final stamp =
          '${u.year}${'${u.month}'.padLeft(2, '0')}'
          '${'${u.day}'.padLeft(2, '0')}T'
          '${'${u.hour}'.padLeft(2, '0')}${'${u.minute}'.padLeft(2, '0')}00Z';
      expect(ics, contains('DTSTART:$stamp'));
    });
  });

  group('ICS round trip', () {
    CalendarEventModel roundTrip(CalendarEventModel e) {
      final events = IcsImportService.parseIcs(
        IcsExportService.generateIcs([e]),
      );
      expect(events, hasLength(1));
      return events.single;
    }

    test('preserves fields and special characters', () {
      final original = CalendarEventModel(
        id: 'rt-1',
        title: r'Spesa: pane, latte; C:\new',
        description: 'riga 1\nriga 2',
        startTime: DateTime(2026, 3, 10, 18, 30),
        endTime: DateTime(2026, 3, 10, 19, 30),
        recurrence: RecurrenceType.weekly,
      );
      final back = roundTrip(original);
      expect(back.id, original.id);
      expect(back.title, original.title);
      expect(back.description, original.description);
      expect(back.startTime, original.startTime);
      expect(back.endTime, original.endTime);
      expect(back.isAllDay, isFalse);
      expect(back.recurrence, RecurrenceType.weekly);
    });

    test('preserves the recurrence end date of all-day events', () {
      final back = roundTrip(
        CalendarEventModel(
          title: 'Corso',
          startTime: DateTime(2026, 3, 2),
          endTime: DateTime(2026, 3, 3),
          isAllDay: true,
          recurrence: RecurrenceType.weekly,
          recurrenceEndDate: DateTime(2026, 5, 25),
        ),
      );
      expect(back.recurrenceEndDate, isNotNull);
      expect(_day(back.recurrenceEndDate!), DateTime(2026, 5, 25));
    });

    test('preserves the recurrence end date of timed events', () {
      final back = roundTrip(
        CalendarEventModel(
          title: 'Palestra',
          startTime: DateTime(2026, 3, 2, 19),
          endTime: DateTime(2026, 3, 2, 20),
          recurrence: RecurrenceType.daily,
          recurrenceEndDate: DateTime(2026, 3, 20),
        ),
      );
      expect(back.recurrenceEndDate, isNotNull);
      expect(calendarEventOccursOn(back, DateTime(2026, 3, 20)), isTrue);
      expect(calendarEventOccursOn(back, DateTime(2026, 3, 21)), isFalse);
    });
  });

  group('IcsImportService.parseIcs (Google Calendar export)', () {
    List<String> vevent(List<String> lines) => [
      'BEGIN:VEVENT',
      ...lines,
      'END:VEVENT',
    ];
    List<CalendarEventModel> parse(List<List<String>> events) =>
        IcsImportService.parseIcs(
          [
            'BEGIN:VCALENDAR',
            'VERSION:2.0',
            for (final e in events) ...vevent(e),
            'END:VCALENDAR',
          ].join('\r\n'),
        );

    test('a VALARM does not overwrite the title and description', () {
      final e = _single([
        'UID:gym@google.com',
        'DTSTART;TZID=Europe/Rome:20261102T100000',
        'DESCRIPTION:Scheda A',
        'SUMMARY:Palestra',
        'BEGIN:VALARM',
        'ACTION:EMAIL',
        'DESCRIPTION:This is an event reminder',
        'SUMMARY:Alarm notification',
        'TRIGGER:-P0DT0H30M0S',
        'END:VALARM',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'DESCRIPTION:This is an event reminder',
        'TRIGGER:-P0DT0H10M0S',
        'END:VALARM',
        'LOCATION:Via Roma 1',
      ]);
      expect(e.title, 'Palestra');
      expect(e.description, 'Scheda A');
      // The popup reminder wins over the email one.
      expect(e.alertMinutesBefore, 10);
      // Properties after the VALARM still belong to the event.
      expect(e.location, 'Via Roma 1');
    });

    test('a moved occurrence keeps the series instead of replacing it', () {
      final events = parse([
        [
          'UID:gym@google.com',
          'DTSTART;TZID=Europe/Rome:20261102T100000',
          'RRULE:FREQ=WEEKLY',
          'SUMMARY:Palestra',
        ],
        [
          'UID:gym@google.com',
          'RECURRENCE-ID;TZID=Europe/Rome:20261116T100000',
          'DTSTART;TZID=Europe/Rome:20261116T120000',
          'SUMMARY:Palestra (spostata)',
        ],
      ]);
      expect(events, hasLength(2));
      expect(events.map((e) => e.id).toSet(), hasLength(2));
      final series = events.firstWhere((e) => e.id == 'gym@google.com');
      expect(series.recurrence, RecurrenceType.weekly);
      final moved = events.firstWhere((e) => e.id != 'gym@google.com');
      expect(moved.title, 'Palestra (spostata)');
      expect(moved.recurrence, RecurrenceType.none);
      expect(moved.startTime, DateTime(2026, 11, 16, 12));
    });

    test('cancelled events and occurrences are skipped', () {
      final events = parse([
        [
          'UID:gym@google.com',
          'DTSTART;TZID=Europe/Rome:20261102T100000',
          'RRULE:FREQ=WEEKLY',
          'SUMMARY:Palestra',
        ],
        [
          'UID:gym@google.com',
          'RECURRENCE-ID;TZID=Europe/Rome:20261130T100000',
          'DTSTART;TZID=Europe/Rome:20261130T100000',
          'STATUS:CANCELLED',
          'SUMMARY:Palestra',
        ],
        [
          'UID:dinner@google.com',
          'DTSTART:20261205T190000Z',
          'STATUS:CANCELLED',
          'SUMMARY:Cena',
        ],
      ]);
      expect(events.map((e) => e.id), ['gym@google.com']);
    });

    test('a repeated event is imported once', () {
      final event = [
        'UID:dup@google.com',
        'DTSTART;VALUE=DATE:20261201',
        'SUMMARY:Copia',
      ];
      expect(parse([event, event]), hasLength(1));
    });

    test('a moved occurrence is left out of its series', () {
      final events = parse([
        [
          'UID:gym@google.com',
          'RECURRENCE-ID;TZID=Europe/Rome:20261116T100000',
          'DTSTART;TZID=Europe/Rome:20261116T120000',
          'SUMMARY:Palestra (spostata)',
        ],
        [
          'UID:gym@google.com',
          'DTSTART;TZID=Europe/Rome:20261102T100000',
          'RRULE:FREQ=WEEKLY',
          'SUMMARY:Palestra',
        ],
        [
          'UID:gym@google.com',
          'RECURRENCE-ID;TZID=Europe/Rome:20261123T100000',
          'DTSTART;TZID=Europe/Rome:20261123T100000',
          'STATUS:CANCELLED',
          'SUMMARY:Palestra',
        ],
      ]);
      final series = events.firstWhere((e) => e.id == 'gym@google.com');
      expect(series.recurrenceExceptions, [
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 23),
      ]);
      expect(series.occursOn(DateTime(2026, 11, 16)), isFalse);
      expect(series.occursOn(DateTime(2026, 11, 30)), isTrue);
      expect(events, hasLength(2));
    });

    test('INTERVAL, BYDAY and EXDATE', () {
      final e = _single([
        'UID:x',
        'DTSTART;TZID=Europe/Rome:20261102T100000',
        'RRULE:FREQ=WEEKLY;WKST=MO;INTERVAL=2;BYDAY=MO,WE',
        'EXDATE;TZID=Europe/Rome:20261104T100000',
        'EXDATE;TZID=Europe/Rome:20261116T100000,20261118T100000',
        'SUMMARY:Corso',
      ]);
      expect(e.recurrence, RecurrenceType.weekly);
      expect(e.recurrenceInterval, 2);
      expect(e.recurrenceWeekdays, [1, 3]);
      expect(e.recurrenceExceptions, [
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 18),
      ]);
      expect(e.occursOn(DateTime(2026, 11, 30)), isTrue);
      expect(e.occursOn(DateTime(2026, 11, 9)), isFalse);
    });

    test('monthly on the Nth weekday, from BYDAY or BYSETPOS', () {
      final google = _single([
        'DTSTART;VALUE=DATE:20260113',
        'RRULE:FREQ=MONTHLY;BYDAY=2TU',
        'SUMMARY:Riunione',
      ]);
      expect(google.recurrenceMonthWeek, 2);
      final outlook = _single([
        'DTSTART;VALUE=DATE:20260130',
        'RRULE:FREQ=MONTHLY;BYDAY=FR;BYSETPOS=-1',
        'SUMMARY:Report',
      ]);
      expect(outlook.recurrenceMonthWeek, -1);
      expect(outlook.occursOn(DateTime(2026, 2, 27)), isTrue);
    });

    test('COUNT with weekdays ends on the right day', () {
      final e = _single([
        'DTSTART:20261102T090000Z',
        'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;COUNT=5',
        'SUMMARY:Allenamento',
      ]);
      expect(e.recurrenceEndDate, DateTime(2026, 11, 11));
    });

    test('unsupported rules are counted as approximated', () {
      final result = IcsImportService.parse(
        [
          'BEGIN:VCALENDAR',
          ...vevent([
            'UID:a',
            'DTSTART;VALUE=DATE:20261126',
            'RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=4TH',
            'SUMMARY:Thanksgiving',
          ]),
          ...vevent([
            'UID:b',
            'DTSTART;VALUE=DATE:20261102',
            'RRULE:FREQ=WEEKLY;BYDAY=MO',
            'SUMMARY:Ok',
          ]),
          'END:VCALENDAR',
        ].join('\r\n'),
      );
      expect(result.events, hasLength(2));
      expect(result.approximated, 1);
    });

    test('export and import keep the custom rule and excluded dates', () {
      final weekly = CalendarEventModel(
        id: 'round',
        title: 'Corso',
        startTime: DateTime(2026, 11, 2, 10),
        endTime: DateTime(2026, 11, 2, 11),
        recurrence: RecurrenceType.weekly,
        recurrenceInterval: 2,
        recurrenceWeekdays: const [1, 3],
        recurrenceExceptions: [DateTime(2026, 11, 4)],
      );
      final monthly = CalendarEventModel(
        id: 'm',
        title: 'Riunione',
        startTime: DateTime(2026, 1, 13),
        endTime: DateTime(2026, 1, 14),
        isAllDay: true,
        recurrence: RecurrenceType.monthly,
        recurrenceMonthWeek: 2,
        recurrenceExceptions: [DateTime(2026, 2, 10)],
      );
      final back = IcsImportService.parseIcs(
        IcsExportService.generateIcs([weekly, monthly]),
      );
      final b = back.firstWhere((e) => e.id == 'round');
      expect(b.recurrenceInterval, 2);
      expect(b.recurrenceWeekdays, [1, 3]);
      expect(b.recurrenceExceptions, [DateTime(2026, 11, 4)]);
      final m = back.firstWhere((e) => e.id == 'm');
      expect(m.recurrenceMonthWeek, 2);
      expect(m.recurrenceExceptions, [DateTime(2026, 2, 10)]);
    });
  });

  group('IcsImportService reminders', () {
    test('timed event without reminders gets the default', () {
      final e =
          IcsImportService.parse(
            _ics(['DTSTART:20261102T090000Z', 'SUMMARY:Senza']),
            defaultAlertMinutes: 15,
          ).events.single;
      expect(e.alertMinutesBefore, 15);
    });

    test('hours and days in the trigger', () {
      final e = _single([
        'DTSTART:20261102T090000Z',
        'SUMMARY:Volo',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'TRIGGER:-P1DT2H',
        'END:VALARM',
      ]);
      expect(e.alertMinutesBefore, 26 * 60);
    });

    test('all-day reminders become day before / same day', () {
      final e = _single([
        'DTSTART;VALUE=DATE:20261201',
        'SUMMARY:Compleanno',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'TRIGGER:-PT15H',
        'END:VALARM',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'TRIGGER:PT9H',
        'END:VALARM',
      ]);
      expect(e.alertDayBefore, isTrue);
      expect(e.alertSameDay, isTrue);
    });

    test('export and import keep the alerts', () {
      final back = IcsImportService.parseIcs(
        IcsExportService.generateIcs([
          CalendarEventModel(
            id: 't',
            title: 'Riunione',
            startTime: DateTime(2026, 11, 2, 10),
            endTime: DateTime(2026, 11, 2, 11),
            alertMinutesBefore: 30,
          ),
          CalendarEventModel(
            id: 'n',
            title: 'Silenzioso',
            startTime: DateTime(2026, 11, 2, 10),
            endTime: DateTime(2026, 11, 2, 11),
            alertMinutesBefore: noEventAlert,
          ),
          CalendarEventModel(
            id: 'a',
            title: 'Ferie',
            startTime: DateTime(2026, 8, 10),
            endTime: DateTime(2026, 8, 11),
            isAllDay: true,
            alertDayBefore: true,
          ),
        ]),
      );
      expect(back.firstWhere((e) => e.id == 't').alertMinutesBefore, 30);
      final a = back.firstWhere((e) => e.id == 'a');
      expect(a.alertDayBefore, isTrue);
      expect(a.alertSameDay, isFalse);
    });
  });

  group('birthdays and name days from the title', () {
    test('specialKindFromTitle', () {
      final k = IcsImportService.specialKindFromTitle;
      expect(k('Martina - compleanno'), (birthday: true, name: 'Martina'));
      expect(k('Mamma & Papà - Onomastico'), (
        birthday: false,
        name: 'Mamma & Papà',
      ));
      expect(k('Compleanno di Luca'), (birthday: true, name: 'Luca'));
      expect(k('Onomastico: Franco'), (birthday: false, name: 'Franco'));
      expect(k("Anna's birthday"), (birthday: true, name: 'Anna'));
      expect(k('Buon compleanno!'), isNull);
      expect(k('Festa del papà'), isNull);
      expect(k('Compleanno'), isNull);
    });

    test('a yearly all-day event becomes a birthday with both alerts', () {
      final e = _single([
        'DTSTART;VALUE=DATE:19960217',
        'RRULE:FREQ=YEARLY',
        'SUMMARY:Martina - compleanno',
      ]);
      expect(e.isBirthday, isTrue);
      expect(e.title, 'Martina');
      expect(e.alertDayBefore && e.alertSameDay, isTrue);
    });

    test('Google reminders win over the default alerts', () {
      final e = _single([
        'DTSTART;VALUE=DATE:20161019',
        'RRULE:FREQ=YEARLY',
        'SUMMARY:AmoreMio - Onomastico',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'TRIGGER:-P0DT7H0M0S',
        'END:VALARM',
      ]);
      expect(e.isNameDay, isTrue);
      expect(e.title, 'AmoreMio');
      expect(e.alertDayBefore, isTrue);
      expect(e.alertSameDay, isFalse);
    });

    test('not yearly or not all-day: left as it is', () {
      final once = _single([
        'DTSTART;VALUE=DATE:20261201',
        'SUMMARY:Martina - compleanno',
      ]);
      expect(once.isBirthday, isFalse);
      expect(once.title, 'Martina - compleanno');
      final other = _single([
        'DTSTART;VALUE=DATE:20170326',
        'RRULE:FREQ=YEARLY',
        'SUMMARY:Luna <3',
      ]);
      expect(other.isBirthday || other.isNameDay, isFalse);
    });
  });
}
