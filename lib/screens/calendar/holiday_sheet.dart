// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../../models/calendar_model.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/app_dialogs.dart';
import 'calendar_event_style.dart';

/// Name, date and kind of a holiday tapped in the calendar on [day]
/// (holidays can't be edited or deleted: they are turned off in Settings).
Future<void> showHolidaySheet(
  BuildContext context,
  HolidayCalendarEvent holiday,
  DateTime day,
) {
  final style = calendarItemStyle(holiday, Theme.of(context).colorScheme);
  return showAppSheet<void>(
    context,
    builder:
        (ctx) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(style.icon, color: style.accent),
            title: Text(
              holiday.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${DateFormat('EEEE d MMMM yyyy').format(day)}\n'
              '${holiday.holiday.isPublic ? ctx.l10n.calendarHolidayPublic : ctx.l10n.calendarHolidayObservance}',
            ),
            isThreeLine: true,
          ),
        ),
  );
}
