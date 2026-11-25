// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import '../../l10n/l10n.dart';

/// Kind of change, used to group the bullets of a version into sections.
/// The enum order is the order of the sections in the dialog.
enum ChangeType { added, improved, fixed, security }

class ChangelogItem {
  const ChangelogItem(this.type, this.textBuilder);

  final ChangeType type;

  /// A function of the strings, not a plain string, so [changelogEntries]
  /// needs no BuildContext and the dialog always shows the current language.
  final String Function(AppLocalizations l) textBuilder;
}

/// The changes of one release. The version name stays the same across
/// releases (`1.0.0`), so an entry is keyed on the build number
/// (`appBuildNumber`, the `+N` of `pubspec.yaml`) and shows its [date].
class ChangelogEntry {
  const ChangelogEntry({
    required this.build,
    required this.date,
    required this.items,
  });

  final int build;

  /// Release date, the entry title in the dialog (users never see the build).
  final DateTime date;
  final List<ChangelogItem> items;

  /// Items grouped by [ChangeType] in enum order; empty types are omitted.
  Map<ChangeType, List<ChangelogItem>> get sections => {
    for (final type in ChangeType.values)
      if (items.any((item) => item.type == type))
        type: items.where((item) => item.type == type).toList(),
  };
}

/// Newest build first; the top entry must match `appBuildNumber`. Bullet
/// texts are the `changelog_b<build>_<N>` keys of `lib/l10n/app_*.arb`.
final List<ChangelogEntry> changelogEntries = [
  // First release of Taskenda: no changes to list yet.
  ChangelogEntry(build: 1, date: DateTime(2026, 11, 25), items: const []),
];
