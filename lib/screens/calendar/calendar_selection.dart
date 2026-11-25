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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../models/calendar_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/calendar_selection_provider.dart';
import '../../widgets/shared/app_dialogs.dart';
import '../../widgets/shared/error_feedback.dart';

/// Gives a calendar card its tap and long-press handlers for the multiple
/// selection: a long press selects an own event, then taps toggle the
/// selection instead of opening ([onOpen]) until it is empty again.
class CalendarSelectableItem extends ConsumerWidget {
  const CalendarSelectableItem({
    super.key,
    required this.event,
    required this.onOpen,
    required this.builder,
  });

  final CalendarEventModel event;
  final VoidCallback onOpen;
  final Widget Function(
    BuildContext context,
    bool selected,
    VoidCallback onTap,
    VoidCallback? onLongPress,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(
      calendarSelectionProvider.select((s) => s.isNotEmpty),
    );
    final selected = ref.watch(
      calendarSelectionProvider.select((s) => s.contains(event.id)),
    );
    final selectable = isCalendarItemSelectable(
      event,
      ref.watch(currentUidProvider),
    );
    void toggle() =>
        ref.read(calendarSelectionProvider.notifier).toggle(event.id);
    return builder(
      context,
      selected,
      // While selecting, tasks, holidays and shared events do nothing.
      selecting ? (selectable ? toggle : () {}) : onOpen,
      selectable ? toggle : null,
    );
  }
}

/// App bar of the calendar while events are selected: count, "select all"
/// ([selectAllIds], only on the search results), delete and close.
class CalendarSelectionActions {
  const CalendarSelectionActions._();

  static Widget title(BuildContext context, int count) =>
      Text(context.l10n.calendarSelectedCount(count));

  static List<Widget> actions(
    BuildContext context,
    WidgetRef ref, {
    Iterable<String>? selectAllIds,
  }) {
    final notifier = ref.read(calendarSelectionProvider.notifier);
    return [
      if (selectAllIds != null)
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: context.l10n.commonSelectAll,
          onPressed: () => notifier.addAll(selectAllIds),
        ),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: context.l10n.commonDelete,
        onPressed: () => _deleteSelected(context, ref),
      ),
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: context.l10n.calendarCancelSelection,
        onPressed: notifier.clear,
      ),
    ];
  }

  /// Moves the selected events to the trash after a confirmation, with an
  /// undo. A recurring event goes with its whole series.
  static Future<void> _deleteSelected(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ids = ref.read(calendarSelectionProvider);
    if (ids.isEmpty) return;
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.calendarDeleteSelectedTitle(ids.length),
      message: context.l10n.calendarDeleteSelectedConfirm(ids.length),
      confirmLabel: context.l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final calendar = ref.read(calendarProvider.notifier);
    ref.read(calendarSelectionProvider.notifier).clear();
    notifyWithUndo(
      calendar.softDeleteMany(ids),
      context,
      message: context.l10n.calendarEventsTrashed(ids.length),
      onUndo: () => calendar.restoreManyFromTrash(ids),
    );
  }
}
