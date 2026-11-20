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
import 'italian_holidays.dart';

/// Name of [holiday] in the app language.
String holidayName(AppLocalizations l, ItalianHoliday holiday) =>
    switch (holiday) {
      ItalianHoliday.newYear => l.holidayNewYear,
      ItalianHoliday.epiphany => l.holidayEpiphany,
      ItalianHoliday.valentinesDay => l.holidayValentinesDay,
      ItalianHoliday.womensDay => l.holidayWomensDay,
      ItalianHoliday.fathersDay => l.holidayFathersDay,
      ItalianHoliday.easter => l.holidayEaster,
      ItalianHoliday.easterMonday => l.holidayEasterMonday,
      ItalianHoliday.liberationDay => l.holidayLiberationDay,
      ItalianHoliday.labourDay => l.holidayLabourDay,
      ItalianHoliday.mothersDay => l.holidayMothersDay,
      ItalianHoliday.republicDay => l.holidayRepublicDay,
      ItalianHoliday.assumption => l.holidayAssumption,
      ItalianHoliday.stFrancis => l.holidayStFrancis,
      ItalianHoliday.halloween => l.holidayHalloween,
      ItalianHoliday.allSaints => l.holidayAllSaints,
      ItalianHoliday.immaculateConception => l.holidayImmaculateConception,
      ItalianHoliday.christmas => l.holidayChristmas,
      ItalianHoliday.stStephen => l.holidayStStephen,
    };
