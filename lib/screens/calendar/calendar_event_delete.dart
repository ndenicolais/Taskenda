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

/// What deleting or editing an occurrence of a recurring event applies to.
enum RecurringScope { thisOccurrence, series }

/// Asks whether to delete only the occurrence opened or the whole series
/// (which goes to the trash). Null when cancelled.
Future<RecurringScope?> showRecurringEventDeleteDialog(BuildContext context) =>
    showDialog<RecurringScope>(
      context: context,
      builder:
          (context) => _RecurringScopeDialog(
            title: context.l10n.calendarDeleteRecurringTitle,
            confirmLabel: context.l10n.commonDelete,
            destructive: true,
          ),
    );

/// Asks whether the changes made to the occurrence opened apply to it only
/// (split off the series as an event of its own) or to the whole series.
/// Null when cancelled.
Future<RecurringScope?> showRecurringEventEditDialog(BuildContext context) =>
    showDialog<RecurringScope>(
      context: context,
      builder:
          (context) => _RecurringScopeDialog(
            title: context.l10n.calendarEditRecurringTitle,
            confirmLabel: context.l10n.commonSave,
          ),
    );

class _RecurringScopeDialog extends StatefulWidget {
  const _RecurringScopeDialog({
    required this.title,
    required this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_RecurringScopeDialog> createState() => _RecurringScopeDialogState();
}

class _RecurringScopeDialogState extends State<_RecurringScopeDialog> {
  RecurringScope _scope = RecurringScope.thisOccurrence;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
      content: RadioGroup<RecurringScope>(
        groupValue: _scope,
        onChanged: (v) {
          if (v != null) setState(() => _scope = v);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<RecurringScope>(
              title: Text(l10n.calendarRecurringThisOccurrence),
              value: RecurringScope.thisOccurrence,
            ),
            RadioListTile<RecurringScope>(
              title: Text(l10n.calendarRecurringWholeSeries),
              value: RecurringScope.series,
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
          style:
              widget.destructive
                  ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                  : null,
          onPressed: () => Navigator.pop(context, _scope),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
