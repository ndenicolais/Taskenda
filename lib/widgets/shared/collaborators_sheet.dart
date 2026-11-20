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
import '../../models/share_member.dart';
import '../../models/sharing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/sharing_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../screens/auth/login_validators.dart';
import '../../theme/app_font_sizes.dart';
import '../../theme/app_spacing.dart';
import 'app_dialogs.dart';
import 'collaborators_section.dart';

/// The kinds of items that can be shared.
enum ShareKind { note, task, event }

/// Opens [CollaboratorsSheet] for the [kind] item [itemId]; [onLeft] runs
/// once the user removed themselves (e.g. to close the item's screen).
Future<void> showCollaboratorsSheet(
  BuildContext context, {
  required ShareKind kind,
  required String itemId,
  required VoidCallback onLeft,
}) => showAppSheet(
  context,
  isScrollControlled: true,
  builder:
      (_) => CollaboratorsSheet(kind: kind, itemId: itemId, onLeft: onLeft),
);

/// Lists who is on a shared item. The owner can add collaborators by email
/// and remove them; a collaborator can remove themselves ([onLeft] then
/// runs, after the sheet closed).
class CollaboratorsSheet extends ConsumerStatefulWidget {
  const CollaboratorsSheet({
    super.key,
    required this.kind,
    required this.itemId,
    required this.onLeft,
  });

  final ShareKind kind;
  final String itemId;
  final VoidCallback onLeft;

  @override
  ConsumerState<CollaboratorsSheet> createState() => _CollaboratorsSheetState();
}

class _CollaboratorsSheetState extends ConsumerState<CollaboratorsSheet> {
  Shareable<dynamic>? _watchItem() => switch (widget.kind) {
    ShareKind.note => ref.watch(noteByIdProvider(widget.itemId)),
    ShareKind.task => ref.watch(taskByIdProvider(widget.itemId)),
    ShareKind.event => ref.watch(
      eventsByIdProvider.select((events) => events[widget.itemId]),
    ),
  };

  Future<ShareMember> _addCollaborator(String email) => switch (widget.kind) {
    ShareKind.note => ref
        .read(notesProvider.notifier)
        .addCollaborator(widget.itemId, email),
    ShareKind.task => ref
        .read(tasksProvider.notifier)
        .addCollaborator(widget.itemId, email),
    ShareKind.event => ref
        .read(calendarProvider.notifier)
        .addCollaborator(widget.itemId, email),
  };

  Future<void> _removeCollaborator(String uid) => switch (widget.kind) {
    ShareKind.note => ref
        .read(notesProvider.notifier)
        .removeCollaborator(widget.itemId, uid),
    ShareKind.task => ref
        .read(tasksProvider.notifier)
        .removeCollaborator(widget.itemId, uid),
    ShareKind.event => ref
        .read(calendarProvider.notifier)
        .removeCollaborator(widget.itemId, uid),
  };

  Future<void> _leaveItem() => switch (widget.kind) {
    ShareKind.note => ref.read(notesProvider.notifier).leaveNote(widget.itemId),
    ShareKind.task => ref.read(tasksProvider.notifier).leaveTask(widget.itemId),
    ShareKind.event => ref
        .read(calendarProvider.notifier)
        .leaveEvent(widget.itemId),
  };

  final _emailController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _shareErrorText(ShareError e) => switch (e) {
    ShareError.notFound => context.l10n.shareErrorNotFound,
    ShareError.self => context.l10n.shareErrorSelf,
    ShareError.alreadyAdded => context.l10n.shareErrorAlreadyAdded,
  };

  Future<void> _add() async {
    final email = _emailController.text.trim();
    final invalid = validateEmail(context.l10n, email);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      await _addCollaborator(email);
      _emailController.clear();
    } on ShareException catch (e) {
      if (mounted) error = _shareErrorText(e.error);
    } catch (_) {
      if (mounted) error = context.l10n.commonGenericError;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _remove(ShareMember member) async {
    try {
      await _removeCollaborator(member.uid);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.commonGenericError);
    }
  }

  Future<void> _leave() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.shareLeaveConfirmTitle,
      message: context.l10n.shareLeaveConfirmMessage,
      confirmLabel: context.l10n.shareLeaveConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final pending = _leaveItem();
    Navigator.pop(context);
    widget.onLeft();
    try {
      await pending;
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareLeft)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonGenericError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _watchItem();
    final uid = ref.watch(currentUidProvider);
    final me = ref.watch(currentShareMemberProvider);
    if (note == null) return const SizedBox.shrink();
    final isOwner = !note.isForeignTo(uid);
    final owner = isOwner ? me : note.owner;
    final l10n = context.l10n;
    final personalInfo = switch (widget.kind) {
      ShareKind.note => l10n.sharePersonalInfo,
      ShareKind.task => l10n.shareTaskPersonalInfo,
      ShareKind.event => l10n.shareEventPersonalInfo,
    };
    final outline = Theme.of(context).colorScheme.outline;

    String nameOf(ShareMember m) =>
        m.uid == uid ? l10n.shareYouSuffix(m.label) : m.label;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder:
          (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                l10n.shareCollaboratorsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (isOwner) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    hintText: l10n.shareEmailHint,
                    prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                    errorText: _error,
                    errorMaxLines: 2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    suffixIcon:
                        _busy
                            ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(Icons.send_outlined),
                              tooltip: l10n.shareAdd,
                              onPressed: _add,
                            ),
                  ),
                  onSubmitted: (_) => _add(),
                ),
                const SizedBox(height: AppSpacing.sm),
              ] else if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (owner != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MemberAvatar(member: owner),
                  title: Text(nameOf(owner)),
                  subtitle: Text(
                    owner.email.isEmpty
                        ? l10n.shareOwner
                        : '${owner.email} · ${l10n.shareOwner}',
                  ),
                ),
              for (final c in note.collaborators)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MemberAvatar(member: c),
                  title: Text(nameOf(c)),
                  subtitle: c.email.isEmpty ? null : Text(c.email),
                  trailing:
                      isOwner
                          ? IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l10n.shareRemoveTooltip,
                            onPressed: () => _remove(c),
                          )
                          : null,
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                personalInfo,
                style: TextStyle(fontSize: AppFontSizes.sm, color: outline),
              ),
              if (!isOwner) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.shareLeave),
                  onPressed: _leave,
                ),
              ],
            ],
          ),
    );
  }
}
