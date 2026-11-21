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
import '../core/routing/app_router.dart';
import '../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../providers/notes_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/calendar_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/markdown_text.dart';
import '../widgets/nav_scaffold.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_feedback.dart';
import '../widgets/shared/item_card.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(archivedNotesProvider);
    final tasks = ref.watch(archivedTasksProvider);
    final events = ref.watch(archivedEventsProvider);
    final notesLoadError = ref.watch(notesLoadErrorProvider);
    final tasksLoadError = ref.watch(tasksLoadErrorProvider);

    return NavScaffold(
      section: DrawerSection.archive,
      titleWidget: Text(context.l10n.navArchive),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: context.l10n.commonTabEvents),
                Tab(text: context.l10n.commonTabTasks),
                Tab(text: context.l10n.commonTabNotes),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _EventList(events: events),
                  _TaskList(tasks: tasks, loadError: tasksLoadError),
                  _NoteList(notes: notes, loadError: notesLoadError),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unarchive / move-to-trash actions of an archived item, both with Undo.
/// Trashing also clears the archived flag, so its Undo archives it again.
typedef _ArchiveActions =
    ({
      Future<void> Function() toggleArchive,
      Future<void> Function() trash,
      Future<void> Function() restoreFromTrash,
      String unarchivedMessage,
      String trashedMessage,
    });

class _NoteList extends ConsumerWidget {
  const _NoteList({required this.notes, this.loadError});
  final List<NoteModel> notes;
  final Object? loadError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notes.isEmpty) {
      return EmptyState(
        icon: loadError != null ? Icons.cloud_off : Icons.note_alt_outlined,
        message:
            loadError != null
                ? context.l10n.commonSyncError
                : context.l10n.archiveEmptyNotes,
        iconSize: 64,
      );
    }
    final notifier = ref.read(notesProvider.notifier);
    return ItemCardList(
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return _ArchivedRow(
          title: note.title,
          subtitle: markdownToPlainText(note.content),
          // Notes keep opening in the editor on tap, as before.
          onTap: () => AppNav.openNote(context, note),
          actions: (
            toggleArchive: () => notifier.toggleArchive(note.id),
            trash: () => notifier.softDelete(note.id),
            restoreFromTrash: () => notifier.restoreFromTrash(note.id),
            unarchivedMessage: context.l10n.noteUnarchived,
            trashedMessage: context.l10n.noteTrashed,
          ),
        );
      },
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks, this.loadError});
  final List<TaskModel> tasks;
  final Object? loadError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return EmptyState(
        icon: loadError != null ? Icons.cloud_off : Icons.task_alt,
        message:
            loadError != null
                ? context.l10n.commonSyncError
                : context.l10n.archiveEmptyTasks,
        iconSize: 64,
      );
    }
    final notifier = ref.read(tasksProvider.notifier);
    return ItemCardList(
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final task = tasks[i];
        return _ArchivedRow(
          title: task.title,
          subtitle: task.description,
          actions: (
            toggleArchive: () => notifier.toggleArchive(task.id),
            trash: () => notifier.softDelete(task.id),
            restoreFromTrash: () => notifier.restoreFromTrash(task.id),
            unarchivedMessage: context.l10n.tasksUnarchived,
            trashedMessage: context.l10n.tasksTrashed,
          ),
        );
      },
    );
  }
}

class _EventList extends ConsumerWidget {
  const _EventList({required this.events});
  final List<CalendarEventModel> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        message: context.l10n.archiveEmptyEvents,
        iconSize: 64,
      );
    }
    final notifier = ref.read(calendarProvider.notifier);
    return ItemCardList(
      itemCount: events.length,
      itemBuilder: (_, i) {
        final event = events[i];
        return _ArchivedRow(
          title: event.title,
          subtitle: event.description,
          actions: (
            toggleArchive: () => notifier.toggleArchive(event.id),
            trash: () => notifier.softDelete(event.id),
            restoreFromTrash: () => notifier.restoreFromTrash(event.id),
            unarchivedMessage: context.l10n.calendarEventUnarchived,
            trashedMessage: context.l10n.calendarEventTrashed,
          ),
        );
      },
    );
  }
}

/// An archived item: title, preview and a menu to unarchive it or move it
/// to the trash.
class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final _ArchiveActions actions;
  final VoidCallback? onTap;

  void _onSelected(BuildContext context, String value) {
    switch (value) {
      case 'unarchive':
        notifyWithUndo(
          actions.toggleArchive(),
          context,
          message: actions.unarchivedMessage,
          onUndo: actions.toggleArchive,
        );
      case 'trash':
        notifyWithUndo(
          actions.trash(),
          context,
          message: actions.trashedMessage,
          onUndo: () async {
            await actions.restoreFromTrash();
            await actions.toggleArchive(); // Back into the archive.
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return ItemCard(
      title: Text(
        title.isNotEmpty ? title : l10n.commonUntitledParens,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          subtitle.isEmpty
              ? null
              : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _onSelected(context, v),
        itemBuilder:
            (_) => [
              PopupMenuItem(
                value: 'unarchive',
                child: Row(
                  children: [
                    const Icon(Icons.unarchive_outlined),
                    const SizedBox(width: AppSpacing.md),
                    Text(l10n.commonUnarchive),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'trash',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: error),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      l10n.commonMoveToTrash,
                      style: TextStyle(color: error),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
  }
}
