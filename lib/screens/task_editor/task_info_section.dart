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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_list_model.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_font_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../utils/recurrence.dart';

String recurrenceLabel(AppLocalizations l, RecurrenceType type) {
  switch (type) {
    case RecurrenceType.none:
      return l.recurrenceNone;
    case RecurrenceType.daily:
      return l.recurrenceDaily;
    case RecurrenceType.weekly:
      return l.recurrenceWeekly;
    case RecurrenceType.monthly:
      return l.recurrenceMonthly;
    case RecurrenceType.yearly:
      return l.recurrenceYearly;
  }
}

/// Shows the task's due date, recurrence and containing list. Each row
/// opens its picker on tap; without a due date a muted row offers to set
/// one, so the date is one tap away instead of in the bottom bar.
class TaskInfoSection extends StatelessWidget {
  const TaskInfoSection({
    super.key,
    required this.task,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.onPickRecurrence,
    required this.onPickList,
  });

  final TaskModel task;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;
  final VoidCallback onPickRecurrence;
  final VoidCallback onPickList;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final due = task.dueDate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          if (due != null)
            _InfoRow(
              // The alarm marks a due time, which notifies.
              icon: task.hasDueTime ? Icons.alarm : Icons.calendar_today,
              label: DateFormat(
                task.hasDueTime ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy',
              ).format(due),
              color: cs.primary,
              onTap: onPickDueDate,
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: cs.primary,
                tooltip: context.l10n.tasksRemoveDueDate,
                visualDensity: VisualDensity.compact,
                onPressed: onClearDueDate,
              ),
            )
          else
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: context.l10n.taskEditorDueDate,
              color: cs.onSurface.withAlpha(150),
              onTap: onPickDueDate,
            ),
          if (task.recurrence != RecurrenceType.none)
            _InfoRow(
              icon: Icons.repeat,
              label: recurrenceLabel(context.l10n, task.recurrence),
              color: cs.primary,
              onTap: onPickRecurrence,
            ),
          if (task.listId != null)
            Consumer(
              builder: (context, ref, _) {
                final lists = ref.watch(taskListsProvider);
                final listName =
                    lists
                        .firstWhere(
                          (l) => l.id == task.listId,
                          orElse:
                              () => TaskListModel(
                                id: '',
                                name: context.l10n.tasksUnknownList,
                              ),
                        )
                        .name;
                return _InfoRow(
                  icon: Icons.playlist_add_check,
                  label: listName,
                  color: cs.primary,
                  onTap: onPickList,
                );
              },
            ),
        ],
      ),
    );
  }
}

/// A tappable icon + label row with a comfortable touch target.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: AppFontSizes.sm),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
