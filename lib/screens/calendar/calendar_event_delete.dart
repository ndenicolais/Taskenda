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

/// What deleting an occurrence of a recurring event removes.
enum EventDeleteScope { thisOccurrence, series }

/// Asks whether to delete only the occurrence opened or the whole series
/// (which goes to the trash). Null when cancelled.
Future<EventDeleteScope?> showRecurringEventDeleteDialog(
  BuildContext context,
) => showDialog<EventDeleteScope>(
  context: context,
  builder: (_) => const _RecurringEventDeleteDialog(),
);

class _RecurringEventDeleteDialog extends StatefulWidget {
  const _RecurringEventDeleteDialog();

  @override
  State<_RecurringEventDeleteDialog> createState() =>
      _RecurringEventDeleteDialogState();
}

class _RecurringEventDeleteDialogState
    extends State<_RecurringEventDeleteDialog> {
  EventDeleteScope _scope = EventDeleteScope.thisOccurrence;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.calendarDeleteRecurringTitle),
      contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
      content: RadioGroup<EventDeleteScope>(
        groupValue: _scope,
        onChanged: (v) {
          if (v != null) setState(() => _scope = v);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<EventDeleteScope>(
              title: Text(l10n.calendarDeleteThisOccurrence),
              value: EventDeleteScope.thisOccurrence,
            ),
            RadioListTile<EventDeleteScope>(
              title: Text(l10n.calendarDeleteWholeSeries),
              value: EventDeleteScope.series,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: () => Navigator.pop(context, _scope),
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}
