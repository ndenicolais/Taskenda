// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import '../l10n/app_localizations.dart';

enum RecurrenceType {
  none, // No recurrence
  daily, // Repeats every day
  weekly, // Repeats every week
  monthly, // Repeats every month
  yearly, // Repeats every year
}

RecurrenceType recurrenceTypeFromString(String value) {
  try {
    return RecurrenceType.values.firstWhere(
      (e) => e.toString() == 'RecurrenceType.$value',
    );
  } catch (_) {
    return RecurrenceType.none;
  }
}

extension RecurrenceTypeExtension on RecurrenceType {
  String label(AppLocalizations l) {
    switch (this) {
      case RecurrenceType.none:
        return l.eventRecurrenceNone;
      case RecurrenceType.daily:
        return l.eventRecurrenceDaily;
      case RecurrenceType.weekly:
        return l.eventRecurrenceWeekly;
      case RecurrenceType.monthly:
        return l.eventRecurrenceMonthly;
      case RecurrenceType.yearly:
        return l.eventRecurrenceYearly;
    }
  }

  String toShortString() {
    return toString().split('.').last;
  }
}

/// [from] moved one [type] step forward, keeping its time of day. A monthly
/// or yearly step that lands past the end of the month (e.g. 31 Jan → Feb)
/// falls on the month's last day.
DateTime nextRecurrence(DateTime from, RecurrenceType type) {
  DateTime at(int year, int month, int day) =>
      DateTime(year, month, day, from.hour, from.minute, from.second);
  DateTime addMonths(int months) {
    final target = DateTime(from.year, from.month + months);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return at(target.year, target.month, from.day.clamp(1, lastDay));
  }

  switch (type) {
    case RecurrenceType.none:
      return from;
    case RecurrenceType.daily:
      return at(from.year, from.month, from.day + 1);
    case RecurrenceType.weekly:
      return at(from.year, from.month, from.day + 7);
    case RecurrenceType.monthly:
      return addMonths(1);
    case RecurrenceType.yearly:
      return addMonths(12);
  }
}

/// `yyyy-MM-dd` of [d] (its date only), as stored for recurrence exceptions.
String dateOnlyKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Whole calendar days from [a] to [b] (dates only, DST-safe).
int calendarDaysBetween(DateTime a, DateTime b) =>
    DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Which week of its month [d] falls in for its weekday: 1 for the first
/// such weekday of the month … 5 for the fifth.
int weekOfMonth(DateTime d) => (d.day - 1) ~/ 7 + 1;

/// Whether [d] is the last such weekday of its month.
bool isLastWeekdayOfMonth(DateTime d) =>
    d.day + 7 > DateTime(d.year, d.month + 1, 0).day;

/// Whether a recurrence starting on [start] has an occurrence on [day].
///
/// - [interval]: every N days / weeks / months / years (1 = every).
/// - [weekdays] (weekly): the days it falls on (1 = Monday … 7 = Sunday);
///   empty = the weekday of [start]. Weeks start on Monday for [interval].
/// - [monthWeek] (monthly): null = the day of the month of [start]; 1–5 =
///   the weekday of [start] in that week of the month; -1 = the last one.
/// - [endDate]: last day with an occurrence (inclusive).
/// - [exceptions]: days left out.
///
/// [start] itself is always an occurrence (unless excluded), as in RFC 5545.
/// A day of the month the month doesn't have (31, 29 Feb) is skipped.
bool recurrenceOccursOn({
  required DateTime start,
  required DateTime day,
  RecurrenceType type = RecurrenceType.none,
  int interval = 1,
  List<int> weekdays = const [],
  int? monthWeek,
  DateTime? endDate,
  List<DateTime> exceptions = const [],
}) {
  final startDay = DateTime(start.year, start.month, start.day);
  final target = DateTime(day.year, day.month, day.day);
  if (startDay.isAfter(target)) return false;
  if (endDate != null &&
      target.isAfter(DateTime(endDate.year, endDate.month, endDate.day))) {
    return false;
  }
  for (final e in exceptions) {
    if (e.year == target.year &&
        e.month == target.month &&
        e.day == target.day) {
      return false;
    }
  }
  if (target == startDay) return true;

  final n = interval < 1 ? 1 : interval;
  switch (type) {
    case RecurrenceType.none:
      return false;
    case RecurrenceType.daily:
      return calendarDaysBetween(startDay, target) % n == 0;
    case RecurrenceType.weekly:
      final days = weekdays.isEmpty ? [start.weekday] : weekdays;
      if (!days.contains(target.weekday)) return false;
      if (n == 1) return true;
      final startMonday = DateTime(
        startDay.year,
        startDay.month,
        startDay.day - (start.weekday - 1),
      );
      final weeks = calendarDaysBetween(startMonday, target) ~/ 7;
      return weeks % n == 0;
    case RecurrenceType.monthly:
      final months =
          (target.year - start.year) * 12 + target.month - start.month;
      if (months % n != 0) return false;
      if (monthWeek == null) return target.day == start.day;
      if (target.weekday != start.weekday) return false;
      return monthWeek == -1
          ? isLastWeekdayOfMonth(target)
          : weekOfMonth(target) == monthWeek;
    case RecurrenceType.yearly:
      if ((target.year - start.year) % n != 0) return false;
      return target.month == start.month && target.day == start.day;
  }
}
