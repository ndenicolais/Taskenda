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
import '../../models/share_member.dart';
import '../../theme/app_spacing.dart';

/// Who else is on a shared item, as chips: the owner (for an item shared
/// with the current user) and the collaborators. Tapping one opens the
/// collaborators sheet.
class CollaboratorsSection extends StatelessWidget {
  const CollaboratorsSection({
    super.key,
    required this.members,
    required this.onTap,
  });

  /// Everyone on the item except the current user.
  final List<ShareMember> members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Semantics(
        label: context.l10n.shareCollaboratorsTitle,
        container: true,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in members)
              ActionChip(
                avatar: MemberAvatar(member: m, radius: 10),
                label: Text(
                  m.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// A circle with the initial of [member].
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.radius = 18});

  final ShareMember member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final label = member.label.trim();
    return CircleAvatar(
      radius: radius,
      child: Text(
        label.isEmpty ? '?' : label.characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius),
      ),
    );
  }
}
