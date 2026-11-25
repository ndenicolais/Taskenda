import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskenda/core/constants/changelog.dart';
import 'package:taskenda/utils/changelog_service.dart';

ChangelogEntry _entry(int build, {bool empty = false}) => ChangelogEntry(
  build: build,
  date: DateTime(2026, 1, build),
  items: [if (!empty) ChangelogItem(ChangeType.added, (_) => '')],
);

// Newest first, as in changelog.dart.
final _entries = [_entry(3), _entry(2), _entry(1)];

Future<SharedPreferences> _prefs([int? lastSeen]) {
  SharedPreferences.setMockInitialValues({
    if (lastSeen != null) ChangelogService.prefsLastSeenBuild: lastSeen,
  });
  return SharedPreferences.getInstance();
}

Future<List<int>> _pending(
  SharedPreferences prefs,
  int current, {
  List<ChangelogEntry>? entries,
}) async {
  final pending = await ChangelogService.pendingEntries(
    prefs,
    current,
    entries: entries ?? _entries,
  );
  return pending.map((e) => e.build).toList();
}

void main() {
  test('nothing recorded: only the current entry, build recorded', () async {
    final prefs = await _prefs();

    expect(await _pending(prefs, 3), [3]);
    expect(prefs.getInt(ChangelogService.prefsLastSeenBuild), 3);
    expect(await _pending(prefs, 3), isEmpty);
  });

  test('nothing recorded and no entry for the current build', () async {
    final prefs = await _prefs();

    expect(await _pending(prefs, 4), isEmpty);
    expect(prefs.getInt(ChangelogService.prefsLastSeenBuild), 4);
  });

  test('shows only the entries after the last seen build', () async {
    final prefs = await _prefs(1);

    expect(await _pending(prefs, 3), [3, 2]);
  });

  test('a skipped build without an entry does not show everything', () async {
    final prefs = await _prefs(2);

    expect(await _pending(prefs, 4), [3]);
  });

  test('entries after the installed build are not shown', () async {
    final prefs = await _prefs(1);

    expect(await _pending(prefs, 2), [2]);
  });

  test('entries without items are skipped', () async {
    final prefs = await _prefs();

    expect(await _pending(prefs, 1, entries: [_entry(1, empty: true)]), []);
    expect(prefs.getInt(ChangelogService.prefsLastSeenBuild), 1);
  });

  test('downgrade shows nothing and keeps the higher build', () async {
    final prefs = await _prefs(3);

    expect(await _pending(prefs, 2), isEmpty);
    expect(prefs.getInt(ChangelogService.prefsLastSeenBuild), 3);
  });
}
