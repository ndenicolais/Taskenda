// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/l10n/app_localizations.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/utils/holiday_names.dart';
import 'package:taskenda/utils/italian_holidays.dart';

import '../helpers/l10n.dart';

void main() {
  test('Easter Sunday', () {
    expect(easterSunday(2024), DateTime(2024, 3, 31));
    expect(easterSunday(2025), DateTime(2025, 4, 20));
    expect(easterSunday(2026), DateTime(2026, 4, 5));
    expect(easterSunday(2027), DateTime(2027, 3, 28));
    expect(easterSunday(2038), DateTime(2038, 4, 25));
  });

  test('movable days', () {
    expect(ItalianHoliday.easterMonday.dateIn(2026), DateTime(2026, 4, 6));
    expect(ItalianHoliday.mothersDay.dateIn(2026), DateTime(2026, 5, 10));
    expect(ItalianHoliday.mothersDay.dateIn(2027), DateTime(2027, 5, 9));
    // 1 May 2022 was a Sunday: the second Sunday is the 8th.
    expect(ItalianHoliday.mothersDay.dateIn(2022), DateTime(2022, 5, 8));
  });

  test('St Francis is a national holiday from 2026', () {
    expect(ItalianHoliday.stFrancis.dateIn(2025), isNull);
    expect(ItalianHoliday.stFrancis.occursOn(DateTime(2025, 10, 4)), isFalse);
    expect(ItalianHoliday.stFrancis.occursOn(DateTime(2026, 10, 4)), isTrue);
    final e = HolidayCalendarEvent(
      ItalianHoliday.stFrancis,
      title: 'San Francesco',
      year: 2024,
    );
    expect(e.startTime, DateTime(2026, 10, 4));
  });

  test('public holidays and observances', () {
    final public = ItalianHoliday.values.where((h) => h.isPublic).length;
    expect(public, 13);
    expect(ItalianHoliday.fathersDay.isPublic, isFalse);
    expect(ItalianHoliday.assumption.isPublic, isTrue);
  });

  test('a holiday entry occurs every year, without alerts', () {
    final easter = HolidayCalendarEvent(
      ItalianHoliday.easter,
      title: holidayName(itL10n, ItalianHoliday.easter),
      year: 2026,
    );
    expect(easter.title, 'Pasqua');
    expect(easter.occursOn(DateTime(2026, 4, 5)), isTrue);
    expect(easter.occursOn(DateTime(2027, 3, 28)), isTrue);
    expect(easter.occursOn(DateTime(2027, 4, 5)), isFalse);
    expect(easter.hasAlerts, isFalse);
    expect(easter.isAllDay, isTrue);
  });

  test('every holiday has a name in both languages', () {
    for (final h in ItalianHoliday.values) {
      expect(holidayName(itL10n, h), isNotEmpty);
      expect(
        holidayName(lookupAppLocalizations(const Locale('en')), h),
        isNotEmpty,
      );
    }
  });
}
