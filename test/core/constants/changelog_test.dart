import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/constants/app_version.dart';
import 'package:taskenda/core/constants/changelog.dart';

void main() {
  test('sections follow the ChangeType order and skip empty types', () {
    String text(_) => '';
    final entry = ChangelogEntry(
      build: 1,
      date: DateTime(2026),
      items: [
        ChangelogItem(ChangeType.fixed, text),
        ChangelogItem(ChangeType.added, text),
        ChangelogItem(ChangeType.fixed, text),
      ],
    );

    expect(entry.sections.keys, [ChangeType.added, ChangeType.fixed]);
    expect(entry.sections[ChangeType.fixed], hasLength(2));
  });

  test('every changelog bullet in the ARB files is listed once', () {
    final source = File('lib/core/constants/changelog.dart').readAsStringSync();
    Set<String> bulletKeys(String locale) {
      final arb =
          jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      return arb.keys.where((k) => k.startsWith('changelog_b')).toSet();
    }

    final keys = bulletKeys('it');
    expect(
      bulletKeys('en'),
      keys,
      reason: 'it and en must have the same bullets',
    );
    for (final key in keys) {
      expect(
        'l.$key)'.allMatches(source),
        hasLength(1),
        reason: '$key must appear exactly once in changelogEntries',
      );
    }
    expect(
      changelogEntries.fold<int>(0, (sum, e) => sum + e.items.length),
      keys.length,
    );
  });

  test('the top entry matches the build in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*\S+\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml needs a +build suffix');
    expect(changelogEntries.first.build, int.parse(match!.group(1)!));
    expect(changelogEntries.first.build, appBuildNumber);
  });

  test('builds are unique and newest first', () {
    final builds = changelogEntries.map((e) => e.build).toList();
    expect(builds, [...builds]..sort((a, b) => b.compareTo(a)));
    expect(builds.toSet(), hasLength(builds.length));
  });
}
