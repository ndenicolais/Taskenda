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
import '../../widgets/shared/section_header.dart';

/// "Calendar" preferences section: national holidays and observances.
class SettingsCalendarPrefsSection extends StatelessWidget {
  const SettingsCalendarPrefsSection({
    super.key,
    required this.showHolidays,
    required this.showObservances,
    required this.onToggleHolidays,
    required this.onToggleObservances,
  });

  final bool showHolidays;
  final bool showObservances;
  final VoidCallback onToggleHolidays;
  final VoidCallback onToggleObservances;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(context.l10n.settingsCalendarSection),
        SwitchListTile(
          title: Text(context.l10n.settingsShowHolidays),
          subtitle: Text(context.l10n.settingsShowHolidaysSubtitle),
          value: showHolidays,
          onChanged: (_) => onToggleHolidays(),
        ),
        SwitchListTile(
          title: Text(context.l10n.settingsShowObservances),
          subtitle: Text(context.l10n.settingsShowObservancesSubtitle),
          value: showObservances,
          onChanged: (_) => onToggleObservances(),
        ),
      ],
    );
  }
}
