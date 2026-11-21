import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/screens/calendar/calendar_event_style.dart';
import 'package:taskenda/theme/app_colors.dart';
import 'package:taskenda/theme/app_theme.dart';
import 'package:taskenda/utils/recurrence.dart';

CalendarEventModel _event(
  String title, {
  bool allDay = false,
  bool birthday = false,
  Color? color,
}) => CalendarEventModel(
  title: title,
  startTime: DateTime(2026, 11, 27, 19),
  endTime: DateTime(2026, 11, 27, 20),
  isAllDay: allDay || birthday,
  isBirthday: birthday,
  recurrence: birthday ? RecurrenceType.yearly : RecurrenceType.none,
  color: color,
);

void main() {
  final scheme = AppTheme.lightScheme;

  test('the automatic color depends only on the title', () {
    expect(
      autoEventSwatchIndex('Palestra', 'a'),
      autoEventSwatchIndex('  palestra ', 'b'),
    );
    // Stable across runs and platforms: a fixed FNV-1a value.
    expect(autoEventSwatchIndex('Palestra', ''), 756338323 % 9);
    final indexes = {
      for (final t in [
        'Palestra',
        'Dentista',
        'Riunione',
        'Cena',
        'Volo',
        'Ufficio',
      ])
        autoEventSwatchIndex(t, ''),
    };
    expect(indexes.length, greaterThan(1));
    expect(indexes.every((i) => i >= 0 && i < 9), isTrue);
  });

  test('plain events get an automatic color and a texture by kind', () {
    final timed = calendarItemStyle(_event('Palestra'), scheme);
    final i = autoEventSwatchIndex('Palestra', '');
    expect(timed.background, AppColors.pastelLight[i]);
    expect(timed.accent, AppColors.pastelDeep[i]);
    expect(timed.texture, EventTexture.dots);
    expect(
      calendarItemStyle(_event('Ferie', allDay: true), scheme).texture,
      EventTexture.stripes,
    );
  });

  test('a user color wins but keeps the texture; birthdays have none', () {
    final custom = calendarItemStyle(
      _event('Palestra', color: AppColors.coral),
      scheme,
    );
    expect(custom.accent, AppColors.coral);
    expect(custom.texture, EventTexture.dots);
    final birthday = calendarItemStyle(_event('Anna', birthday: true), scheme);
    expect(birthday.texture, isNull);
    expect(birthday.isFestive, isTrue);
  });
}
