import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskenda/providers/core_providers.dart';
import 'package:taskenda/providers/settings/backup_provider.dart';
import 'package:taskenda/providers/settings/locale_provider.dart';
import 'package:taskenda/providers/settings/settings_sync.dart';
import 'package:taskenda/providers/settings/theme_provider.dart';
import 'package:taskenda/providers/settings/ui_provider.dart';

const _uid = 'u1';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  /// A device: its own preferences, the shared account database.
  Future<ProviderContainer> device() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firestoreProvider.overrideWithValue(db),
        settingsSyncProvider.overrideWith(
          (ref) => SettingsSync(ref, debounce: Duration.zero),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  DocumentReference<Map<String, dynamic>> doc() => db
      .collection('users')
      .doc(_uid)
      .collection('settings')
      .doc('preferences');

  Future<Map<String, dynamic>?> remote() async =>
      (await doc().get()).data()?['values'] as Map<String, dynamic>?;

  test('the first device uploads its preferences', () async {
    final c = await device();
    c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    c.read(settingsSyncProvider).start(_uid);
    await pumpEventQueue();

    final values = await remote();
    expect(values?['themeMode'], 'dark');
    // Automatic backups are device-only.
    expect(values?.containsKey('autoBackupEnabled'), isFalse);
  });

  test('signing in applies the account preferences', () async {
    await doc().set({
      'values': {
        'themeMode': 'light',
        'language': 'en',
        'startSection': 'calendar',
        'autoBackupEnabled': false,
      },
    });
    final c = await device();
    c.read(backupSettingsProvider.notifier).setEnabled(true);
    c.read(settingsSyncProvider).start(_uid);
    await pumpEventQueue();

    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(c.read(appLanguageProvider), AppLanguage.en);
    expect(c.read(startSectionProvider), StartSection.calendar);
    expect(c.read(backupSettingsProvider).enabled, isTrue);
  });

  test('a change on one device reaches the other', () async {
    final phone = await device();
    phone.read(settingsSyncProvider).start(_uid);
    await pumpEventQueue();
    final web = await device();
    web.read(settingsSyncProvider).start(_uid);
    await pumpEventQueue();
    expect(web.read(themeModeProvider), isNot(ThemeMode.dark));

    phone.read(themeModeProvider.notifier).set(ThemeMode.dark);
    phone.read(notesFabMenuProvider.notifier).set(false);
    await pumpEventQueue();
    await Future<void>.delayed(Duration.zero);
    await pumpEventQueue();

    expect((await remote())?['themeMode'], 'dark');
    expect(web.read(themeModeProvider), ThemeMode.dark);
    expect(web.read(notesFabMenuProvider), isFalse);
  });

  test('nothing is uploaded after signing out', () async {
    final c = await device();
    final sync = c.read(settingsSyncProvider)..start(_uid);
    await pumpEventQueue();
    sync.stop();

    c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await pumpEventQueue();
    expect((await remote())?['themeMode'], isNot('dark'));
  });
}
