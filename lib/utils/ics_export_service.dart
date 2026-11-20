// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import '../models/calendar_model.dart';
import 'event_alerts.dart';
import 'recurrence.dart';
import '../l10n/l10n.dart';

class IcsExportService {
  /// Generates an ICS (iCalendar) string from a list of [CalendarEventModel].
  static String generateIcs(List<CalendarEventModel> events) {
    final buf = StringBuffer();
    buf.writeln('BEGIN:VCALENDAR');
    buf.writeln('VERSION:2.0');
    buf.writeln('PRODID:-//Taskenda//Taskenda Calendar//IT');
    buf.writeln('CALSCALE:GREGORIAN');
    buf.writeln('METHOD:PUBLISH');

    for (final event in events) {
      buf.writeln('BEGIN:VEVENT');
      buf.writeln('UID:${event.id}');

      final now = DateTime.now().toUtc();
      buf.writeln('DTSTAMP:${_formatDateTimeUtc(now)}');

      if (event.isAllDay) {
        buf.writeln('DTSTART;VALUE=DATE:${_formatDate(event.startTime)}');
        buf.writeln('DTEND;VALUE=DATE:${_formatDate(event.endTime)}');
      } else {
        buf.writeln('DTSTART:${_formatDateTimeUtc(event.startTime.toUtc())}');
        buf.writeln('DTEND:${_formatDateTimeUtc(event.endTime.toUtc())}');
      }

      if (event.recurrence != RecurrenceType.none) {
        buf.writeln('RRULE:${_rrule(event)}${_until(event)}');
        for (final day in event.recurrenceExceptions) {
          buf.writeln(_exdate(event, day));
        }
      }

      buf.writeln(
        'SUMMARY:${_escape(event.title.isEmpty ? currentL10n().commonUntitledParens : event.title)}',
      );

      if (event.description.isNotEmpty) {
        buf.writeln('DESCRIPTION:${_escape(event.description)}');
      }

      if (event.location.isNotEmpty) {
        buf.writeln('LOCATION:${_escape(event.location)}');
      }

      if (event.isBirthday) {
        buf.writeln('CATEGORIES:BIRTHDAY');
      }

      for (final trigger in _alarmTriggers(event)) {
        buf.writeln('BEGIN:VALARM');
        buf.writeln('ACTION:DISPLAY');
        buf.writeln(
          'DESCRIPTION:${_escape(event.title.isEmpty ? currentL10n().commonUntitledParens : event.title)}',
        );
        buf.writeln('TRIGGER:$trigger');
        buf.writeln('END:VALARM');
      }

      buf.writeln('END:VEVENT');
    }

    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  /// Formats a [DateTime] as `YYYYMMDDTHHMMSSz` (UTC).
  static String _formatDateTimeUtc(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$mo${d}T$h$mi${s}Z';
  }

  /// Formats a [DateTime] as `YYYYMMDD` (date-only, for all-day events).
  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$mo$d';
  }

  static const _weekdayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// The RRULE of [event] (without UNTIL): frequency, interval, weekdays
  /// of a weekly rule, weekday and week of a monthly one.
  static String _rrule(CalendarEventModel event) {
    final parts = <String>[
      switch (event.recurrence) {
        RecurrenceType.daily => 'FREQ=DAILY',
        RecurrenceType.weekly => 'FREQ=WEEKLY',
        RecurrenceType.monthly => 'FREQ=MONTHLY',
        RecurrenceType.yearly => 'FREQ=YEARLY',
        RecurrenceType.none => '',
      },
      if (event.recurrenceInterval > 1) 'INTERVAL=${event.recurrenceInterval}',
      if (event.recurrence == RecurrenceType.weekly &&
          event.recurrenceWeekdays.isNotEmpty)
        'BYDAY=${event.recurrenceWeekdays.map((d) => _weekdayCodes[d - 1]).join(',')}',
      if (event.recurrence == RecurrenceType.monthly &&
          event.recurrenceMonthWeek != null)
        'BYDAY=${event.recurrenceMonthWeek}'
            '${_weekdayCodes[event.startTime.weekday - 1]}',
    ];
    return parts.join(';');
  }

  /// The EXDATE line leaving out the occurrence of [event] on [day]: a date
  /// for all-day events, the occurrence time in UTC otherwise.
  static String _exdate(CalendarEventModel event, DateTime day) {
    if (event.isAllDay) return 'EXDATE;VALUE=DATE:${_formatDate(day)}';
    final s = event.startTime;
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      s.hour,
      s.minute,
      s.second,
    );
    return 'EXDATE:${_formatDateTimeUtc(at.toUtc())}';
  }

  /// TRIGGERs of the alerts of [event]: minutes before the start for a
  /// timed event; for an all-day one 15 h before (09:00 the day before) and
  /// 9 h after the start (09:00 on the day), the usual Google ones.
  static List<String> _alarmTriggers(CalendarEventModel event) {
    if (!event.isAllDay) {
      final m = event.alertMinutesBefore;
      if (m == noEventAlert) return const [];
      return [m == 0 ? 'PT0S' : '-PT${m}M'];
    }
    return [if (event.alertDayBefore) '-PT15H', if (event.alertSameDay) 'PT9H'];
  }

  /// Returns the `;UNTIL=` clause for a bounded recurrence, or ''. The end
  /// date is inclusive, so timed events use the end of that local day
  /// (in UTC, as RFC 5545 requires when DTSTART is UTC).
  static String _until(CalendarEventModel event) {
    final end = event.recurrenceEndDate;
    if (end == null) return '';
    if (event.isAllDay) return ';UNTIL=${_formatDate(end)}';
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return ';UNTIL=${_formatDateTimeUtc(endOfDay.toUtc())}';
  }

  /// Escapes special characters in ICS text values.
  static String _escape(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n');
  }
}
