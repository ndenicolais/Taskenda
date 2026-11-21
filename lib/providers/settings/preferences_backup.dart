// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/backup_service.dart' show BackupFrequency;
import '../../utils/event_alerts.dart' show noEventAlert;
import '../calendar_provider.dart';
import 'backup_provider.dart';
import 'locale_provider.dart';
import 'theme_provider.dart';
import 'ui_provider.dart';

/// One preference carried by the full backup and synced with the account:
/// the provider holding it, how to turn its value into JSON and how to
/// apply a value read back.
class _BackedUpSetting {
  const _BackedUpSetting(
    this.source,
    this.toJson,
    this.write, {
    this.deviceOnly = false,
  });

  /// Watched by [syncedPreferencesProvider] to notice changes.
  final ProviderListenable<Object?> source;
  final Object Function(Object? value) toJson;

  /// Ignores values of the wrong type or no longer valid.
  final void Function(Ref ref, Object? value) write;

  /// In the full backup but not synced with the account: it only makes
  /// sense on the device it was set on (automatic backups are files there).
  final bool deviceOnly;

  Object read(Ref ref) => toJson(ref.read(source));
}

_BackedUpSetting _enumSetting<
  N extends PersistedEnumNotifier<T>,
  T extends Enum
>(NotifierProvider<N, T> provider, List<T> values) =>
    _BackedUpSetting(provider, (v) => (v as Enum).name, (ref, value) {
      for (final v in values) {
        if (v.name == value) {
          ref.read(provider.notifier).set(v);
          return;
        }
      }
    });

_BackedUpSetting _boolSetting(NotifierProvider<BoolSettingNotifier, bool> p) =>
    _BackedUpSetting(p, (v) => v as bool, (ref, value) {
      if (value is bool) ref.read(p.notifier).set(value);
    });

/// A time of day in minutes (0 – 1439).
_BackedUpSetting _minutesSetting(
  ProviderListenable<int> source,
  void Function(Ref ref, int value) set,
) => _BackedUpSetting(source, (v) => v as int, (ref, value) {
  if (value is int && value >= 0 && value < 24 * 60) set(ref, value);
});

/// The user's preferences included in the full backup under `settings` and
/// synced with the account ([SettingsSync]), keyed by stable names
/// independent of the SharedPreferences keys. Device bookkeeping
/// (onboarding seen, last backup time, last changelog seen, migration
/// flags) is left out of both.
class PreferencesBackup {
  PreferencesBackup(this._ref);

  final Ref _ref;

  static final Map<String, _BackedUpSetting> _settings = {
    'themeMode': _enumSetting(themeModeProvider, ThemeMode.values),
    'language': _enumSetting(appLanguageProvider, AppLanguage.values),
    'startSection': _enumSetting(startSectionProvider, StartSection.values),
    'notesLayout': _enumSetting(homeLayoutProvider, HomeLayout.values),
    'notesSortOrder': _enumSetting(sortOrderProvider, SortOrder.values),
    'notesFabMenu': _boolSetting(notesFabMenuProvider),
    'tasksSortOrder': _enumSetting(taskSortOrderProvider, SortOrder.values),
    'showCompletedTasks': _boolSetting(showCompletedTasksProvider),
    'groupTasksByPriority': _boolSetting(groupTasksByPriorityProvider),
    'calendarView': _enumSetting(
      calendarViewModeProvider,
      CalendarViewMode.values,
    ),
    'calendarShowTasks': _boolSetting(calendarShowTasksProvider),
    'calendarShowHolidays': _boolSetting(calendarShowHolidaysProvider),
    'calendarShowObservances': _boolSetting(calendarShowObservancesProvider),
    // The alerts scheduled on the device are rebuilt by the data restore
    // that follows (or by the reminders resync after a sign-in).
    'defaultAlertMinutes': _minutesSetting(
      defaultAlertTimeProvider,
      (ref, v) => ref.read(defaultAlertTimeProvider.notifier).set(v),
    ),
    'dayBeforeAlertMinutes': _minutesSetting(
      dayBeforeAlertTimeProvider,
      (ref, v) => ref.read(dayBeforeAlertTimeProvider.notifier).set(v),
    ),
    'eventAlertOffset': _BackedUpSetting(
      eventAlertOffsetProvider,
      (v) => v as int,
      (ref, value) {
        if (value is int && (value == noEventAlert || value >= 0)) {
          ref.read(eventAlertOffsetProvider.notifier).set(value);
        }
      },
    ),
    'autoBackupEnabled': _BackedUpSetting(
      backupSettingsProvider.select((s) => s.enabled),
      (v) => v as bool,
      (ref, value) {
        if (value is bool) {
          ref.read(backupSettingsProvider.notifier).setEnabled(value);
        }
      },
      deviceOnly: true,
    ),
    'autoBackupFrequency': _BackedUpSetting(
      backupSettingsProvider.select((s) => s.frequency),
      (v) => (v as BackupFrequency).name,
      (ref, value) {
        for (final f in BackupFrequency.values) {
          if (f.name == value) {
            ref.read(backupSettingsProvider.notifier).setFrequency(f);
          }
        }
      },
      deviceOnly: true,
    ),
  };

  /// The current value of every backed-up preference.
  Map<String, Object> export() => {
    for (final e in _settings.entries) e.key: e.value.read(_ref),
  };

  /// Applies the preferences found in [json]; unknown keys and invalid
  /// values are skipped, keeping the current value. [synced]: values from
  /// the account, which never carry the device-only ones.
  void restore(Map<String, dynamic> json, {bool synced = false}) {
    for (final e in _settings.entries) {
      if (synced && e.value.deviceOnly) continue;
      if (json.containsKey(e.key)) e.value.write(_ref, json[e.key]);
    }
  }
}

/// The preferences synced with the account (all but the device-only ones),
/// recomputed whenever one of them changes.
final syncedPreferencesProvider = Provider<Map<String, Object>>(
  (ref) => {
    for (final e in PreferencesBackup._settings.entries)
      if (!e.value.deviceOnly) e.key: e.value.toJson(ref.watch(e.value.source)),
  },
);

final preferencesBackupProvider = Provider<PreferencesBackup>(
  PreferencesBackup.new,
);
