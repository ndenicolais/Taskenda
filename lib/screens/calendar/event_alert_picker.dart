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
import '../../l10n/l10n.dart';
import '../../utils/event_alerts.dart';
import '../../widgets/shared/app_dialogs.dart';

/// The alert of a timed event in words: "Nessun avviso", "All'inizio",
/// "10 minuti prima", "1 ora prima", "1 giorno prima".
String eventAlertLabel(AppLocalizations l, int minutesBefore) {
  if (minutesBefore == noEventAlert) return l.eventAlertNone;
  if (minutesBefore <= 0) return l.eventAlertAtStart;
  if (minutesBefore % (24 * 60) == 0) {
    return l.eventAlertDaysBefore(minutesBefore ~/ (24 * 60));
  }
  if (minutesBefore % 60 == 0) {
    return l.eventAlertHoursBefore(minutesBefore ~/ 60);
  }
  return l.eventAlertMinutesBefore(minutesBefore);
}

/// Lets the user pick the alert of a timed event (none, at the start or
/// some time before). An imported value outside the usual choices is
/// listed too. Resolves to the minutes before, or null when dismissed.
Future<int?> showEventAlertPicker(BuildContext context, int current) {
  final options = [
    noEventAlert,
    ...eventAlertOffsets,
    if (current != noEventAlert && !eventAlertOffsets.contains(current))
      current,
  ]..sort();
  return showAppSheet<int>(
    context,
    isScrollControlled: true,
    builder:
        (ctx) => ListView(
          shrinkWrap: true,
          children: [
            for (final minutes in options)
              ListTile(
                title: Text(eventAlertLabel(ctx.l10n, minutes)),
                selected: minutes == current,
                onTap: () => Navigator.pop(ctx, minutes),
              ),
          ],
        ),
  );
}
