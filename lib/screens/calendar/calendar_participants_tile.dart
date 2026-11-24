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

/// "Participants" row of the event editor, like the guests of Google
/// Calendar: who else is on the event, or a hint to invite someone by
/// email. Tapping it opens the collaborators sheet.
class CalendarParticipantsTile extends StatelessWidget {
  const CalendarParticipantsTile({
    super.key,
    required this.members,
    required this.onTap,
  });

  /// Everyone on the event except the current user.
  final List<ShareMember> members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.people_outline),
      title: Text(l10n.calendarParticipants),
      subtitle: Text(
        members.isEmpty
            ? l10n.calendarParticipantsAdd
            : members.map((m) => m.label).join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.person_add_alt_1_outlined),
      onTap: onTap,
    );
  }
}
