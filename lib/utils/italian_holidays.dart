// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

/// Italian national holidays (days off, law 260/1949 and later changes)
/// and the most common observances, in calendar order. Computed, never
/// stored: see `HolidayCalendarEvent`.
enum ItalianHoliday {
  newYear(true),
  epiphany(true),
  valentinesDay(false),
  womensDay(false),
  fathersDay(false),
  easter(true),
  easterMonday(true),
  liberationDay(true),
  labourDay(true),
  mothersDay(false),
  republicDay(true),
  assumption(true),
  stFrancis(true),
  halloween(false),
  allSaints(true),
  immaculateConception(true),
  christmas(true),
  stStephen(true);

  const ItalianHoliday(this.isPublic);

  /// A day off (national holiday); false for an observance.
  final bool isPublic;

  /// Its date in [year], or null when it didn't exist that year (St Francis
  /// is a national holiday again from 2026, law 151/2025).
  DateTime? dateIn(int year) {
    DateTime d(int month, int day) => DateTime(year, month, day);
    switch (this) {
      case newYear:
        return d(1, 1);
      case epiphany:
        return d(1, 6);
      case valentinesDay:
        return d(2, 14);
      case womensDay:
        return d(3, 8);
      case fathersDay:
        return d(3, 19);
      case easter:
        return easterSunday(year);
      case easterMonday:
        final e = easterSunday(year);
        return DateTime(e.year, e.month, e.day + 1);
      case liberationDay:
        return d(4, 25);
      case labourDay:
        return d(5, 1);
      case mothersDay:
        // Second Sunday of May.
        final first = d(5, 1);
        return d(5, 1 + (DateTime.sunday - first.weekday) % 7 + 7);
      case republicDay:
        return d(6, 2);
      case assumption:
        return d(8, 15);
      case stFrancis:
        return year >= 2026 ? d(10, 4) : null;
      case halloween:
        return d(10, 31);
      case allSaints:
        return d(11, 1);
      case immaculateConception:
        return d(12, 8);
      case christmas:
        return d(12, 25);
      case stStephen:
        return d(12, 26);
    }
  }

  /// Whether it falls on [day].
  bool occursOn(DateTime day) {
    final d = dateIn(day.year);
    return d != null && d.month == day.month && d.day == day.day;
  }
}

/// Easter Sunday of [year] in the Gregorian calendar (anonymous Gregorian
/// algorithm, a.k.a. Meeus/Jones/Butcher).
DateTime easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime(year, month, day);
}
