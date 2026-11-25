// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/changelog.dart';

/// Decides which changelog entries to show after an update.
class ChangelogService {
  static const prefsLastSeenBuild = 'last_seen_changelog_build';

  /// Entries of a build after the last seen one and not after [currentBuild],
  /// skipping those without items; records [currentBuild] as seen.
  ///
  /// With nothing recorded yet only the entry of [currentBuild] is shown: a
  /// fresh install and the first update that ships the dialog look the same,
  /// and showing nothing would hide the first changelog from every existing
  /// user. The same build or a downgrade shows and records nothing.
  static Future<List<ChangelogEntry>> pendingEntries(
    SharedPreferences prefs,
    int currentBuild, {
    List<ChangelogEntry>? entries,
  }) async {
    final all = entries ?? changelogEntries;
    final lastSeen = prefs.getInt(prefsLastSeenBuild);

    if (lastSeen != null && lastSeen >= currentBuild) return const [];
    await prefs.setInt(prefsLastSeenBuild, currentBuild);

    final from = lastSeen ?? currentBuild - 1;
    return all
        .where(
          (e) =>
              e.build > from && e.build <= currentBuild && e.items.isNotEmpty,
        )
        .toList();
  }
}
