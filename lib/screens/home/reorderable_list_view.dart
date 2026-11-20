// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../providers/notes_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/note_card.dart';
import 'note_section_header.dart';
import 'note_swipe_actions.dart';

/// Home list layout of the notes in [noteIds]; like `ReorderableGridView`,
/// each row watches its own note. The first [pinnedCount] notes are the
/// pinned ones: they get their own header and reorder only among themselves,
/// as do the others.
class ReorderableListViewWidget extends StatelessWidget {
  const ReorderableListViewWidget({
    super.key,
    required this.noteIds,
    this.pinnedCount = 0,
    required this.onReorder,
  });

  final List<String> noteIds;
  final int pinnedCount;

  /// Global indices, legacy pre-removal `newIndex` (as
  /// `NotesNotifier.reorderNotes` expects).
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final othersCount = noteIds.length - pinnedCount;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              80,
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                if (pinnedCount > 0) ...[
                  const SliverToBoxAdapter(child: NoteSectionHeader.pinned()),
                  _section(0, pinnedCount),
                  if (othersCount > 0)
                    const SliverToBoxAdapter(child: NoteSectionHeader.others()),
                ],
                if (othersCount > 0) _section(pinnedCount, othersCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reorderable list of the [length] notes from global index [start].
  Widget _section(int start, int length) {
    void move(int from, int to) {
      // onReorderItem gives the post-removal index; onReorder expects the
      // legacy pre-removal one.
      onReorder(start + from, start + (to > from ? to + 1 : to));
    }

    return SliverReorderableList(
      itemCount: length,
      onReorderItem: move,
      proxyDecorator: _proxyDecorator,
      itemBuilder: (_, i) {
        final id = noteIds[start + i];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(id),
          index: i,
          child: Consumer(
            builder: (context, ref, _) {
              final note = ref.watch(noteByIdProvider(id));
              if (note == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NoteSwipeActions(
                  note: note,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: NoteCard(
                      note: note,
                      // Screen-reader alternative to drag & drop.
                      extraSemanticsActions: {
                        if (i > 0)
                          CustomSemanticsAction(
                                label: context.l10n.commonMoveEarlier,
                              ):
                              () => move(i, i - 1),
                        if (i < length - 1)
                          CustomSemanticsAction(
                                label: context.l10n.commonMoveLater,
                              ):
                              () => move(i, i + 1),
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Lifts the dragged card, like `ReorderableListView` does.
  static Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);
        return Material(
          elevation: lerpDouble(0, 6, t)!,
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }
}
