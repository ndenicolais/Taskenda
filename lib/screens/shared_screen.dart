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
import '../core/routing/app_router.dart';
import '../l10n/l10n.dart';
import '../models/sharing.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_lists_provider.dart';
import '../widgets/nav_scaffold.dart';
import '../widgets/note_card.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/item_card.dart';

/// Everything shared with the user or by them, in notes, tasks and events
/// tabs: those shared with them first.
class SharedScreen extends ConsumerWidget {
  const SharedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notes = ref.watch(sharedNotesProvider);
    final tasks = ref.watch(sharedTasksProvider);
    final events = ref.watch(sharedEventsProvider);

    return NavScaffold(
      section: DrawerSection.shared,
      titleWidget: Text(l10n.navShared),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.commonTabNotes),
                Tab(text: l10n.commonTabTasks),
                Tab(text: l10n.commonTabEvents),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  notes.isEmpty
                      ? const _Empty()
                      : ItemCardList(
                        itemCount: notes.length,
                        itemBuilder: (_, i) => NoteCard(note: notes[i]),
                      ),
                  _SharedList(
                    items: tasks,
                    onTap: (i) => AppNav.viewTask(context, tasks[i]),
                  ),
                  _SharedList(
                    items: events,
                    onTap: (i) => AppNav.viewEvent(context, events[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.people_outline,
    message: context.l10n.sharedEmpty,
    iconSize: 64,
  );
}

/// Tasks or events: title and who shares them.
class _SharedList extends ConsumerWidget {
  const _SharedList({required this.items, required this.onTap});

  final List<Shareable<dynamic>> items;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const _Empty();
    final uid = ref.watch(currentUidProvider);
    final l10n = context.l10n;
    return ItemCardList(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final foreign = item.isForeignTo(uid);
        final names = item.membersExcept(uid).map((m) => m.label).join(', ');
        return ItemCard(
          leading: Icon(
            foreign ? Icons.people_outline : Icons.person_add_alt_1_outlined,
          ),
          title: Text(
            item.title.isEmpty ? l10n.commonUntitled : item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            foreign ? l10n.sharedWithMeSection : l10n.sharedByMeSection,
          ),
          trailing:
              names.isEmpty
                  ? null
                  : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      names,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
          onTap: () => onTap(i),
        );
      },
    );
  }
}
