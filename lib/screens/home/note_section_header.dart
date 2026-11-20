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
import '../../theme/app_spacing.dart';

/// Label over a group of Home notes: the pinned ones (with the pin icon,
/// which the cards no longer show) and, after them, the others.
class NoteSectionHeader extends StatelessWidget {
  const NoteSectionHeader.pinned({super.key}) : pinned = true;
  const NoteSectionHeader.others({super.key}) : pinned = false;

  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xs,
          top: pinned ? 0 : AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (pinned) ...[
              Icon(Icons.push_pin, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              pinned
                  ? context.l10n.homePinnedSection
                  : context.l10n.homeOthersSection,
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
