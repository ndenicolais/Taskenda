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
import '../../models/calendar_model.dart';
import '../../theme/app_colors.dart';
import 'calendar_event_texture.dart';

export 'calendar_event_texture.dart' show EventTexture, EventTexturePainter;

/// Colors and icon of a calendar entry, shared by every calendar view so the
/// same kind of entry always looks the same (list cards, month and week chips).
class CalendarItemStyle {
  const CalendarItemStyle({
    required this.background,
    required this.foreground,
    required this.accent,
    this.icon,
    this.isDone = false,
    this.festiveEnd,
    this.texture,
  });

  /// Pattern behind plain events (not tasks, holidays, birthdays or name
  /// days): stripes when all-day, dots when timed. Drawn on the larger
  /// shapes only (list cards, day / week blocks).
  final EventTexture? texture;

  /// Color of the [texture]: the [accent], faded so text stays readable.
  Color textureColor(bool isDark) =>
      accent.withValues(alpha: isDark ? 0.10 : 0.07);

  /// Second gradient stop of birthdays and name days, whose list cards are
  /// larger and festive; null for every other kind.
  final Color? festiveEnd;

  bool get isFestive => festiveEnd != null;

  /// Card fill: very light tint of the category (dark tint in dark theme).
  final Color background;
  final Color foreground;

  /// Category color of the kind: side bar, small markers and icons drawn on
  /// the plain surface (where the tint would be barely visible).
  final Color accent;
  final IconData? icon;

  /// A completed task: shown faded and struck through.
  final bool isDone;

  TextDecoration? get decoration => isDone ? TextDecoration.lineThrough : null;

  /// Side bar in the [accent] color, drawn on the left edge of the entry.
  /// A non-uniform border can't have a radius: clip the rounded shape
  /// outside of it (Material clipBehavior or ClipRRect).
  Border sideBar(double width) =>
      Border(left: BorderSide(color: accent, width: width));
}

/// Accent of birthdays and name days (also their switches in the editor).
const birthdayColor = AppColors.blue;
const nameDayColor = AppColors.amber;

/// A kind of entry: its [accent] (category color, for the side bar and the
/// icons) and its background in each theme (very light / dark tint).
typedef _Swatch = ({Color light, Color dark, Color accent});

_Swatch _category(Color accent) => (
  light: AppColors.tintLight(accent),
  dark: AppColors.tintDark(accent),
  accent: accent,
);

final _Swatch _taskSwatch = _category(AppColors.teal);
final _Swatch _birthdaySwatch = _category(birthdayColor);
final _Swatch _nameDaySwatch = _category(nameDayColor);
final _Swatch _holidaySwatch = _category(AppColors.coral);

/// Tasks, birthdays, name days and holidays each get their own category
/// color. Other events get a color of the pastel palette picked from their
/// title ([autoEventSwatchIndex]: the same title, the same color) and a
/// [EventTexture] by kind. An event with a [CalendarEventModel.color] uses
/// that one instead (birthdays and name days keep their icon and festive
/// gradient).
CalendarItemStyle calendarItemStyle(
  CalendarEventModel item,
  ColorScheme colorScheme,
) {
  final isDark = colorScheme.brightness == Brightness.dark;
  if (item is TaskCalendarEvent) {
    // The task icon, not a checkbox: tapping opens the task, it does not
    // toggle it. Completion shows as faded, struck-through text.
    return _style(
      _taskSwatch,
      isDark,
      Icons.task_alt,
      isDone: item.task.isCompleted,
    );
  }
  if (item is HolidayCalendarEvent) {
    return item.holiday.isPublic
        ? _style(
          _holidaySwatch,
          isDark,
          Icons.flag,
          festiveEnd: _festiveEnd(AppColors.teal, isDark),
        )
        : _style(_holidaySwatch, isDark, Icons.favorite_border);
  }
  final custom = item.color;
  if (item.isBirthday) {
    return _style(
      custom != null ? _customSwatch(custom) : _birthdaySwatch,
      isDark,
      Icons.cake,
      festiveEnd: _festiveEnd(AppColors.violet, isDark),
    );
  }
  if (item.isNameDay) {
    return _style(
      custom != null ? _customSwatch(custom) : _nameDaySwatch,
      isDark,
      Icons.auto_awesome,
      festiveEnd: _festiveEnd(AppColors.coral, isDark),
    );
  }
  final texture = item.isAllDay ? EventTexture.stripes : EventTexture.dots;
  return _style(
    custom != null ? _customSwatch(custom) : _autoSwatch(item),
    isDark,
    null,
    texture: texture,
  );
}

/// Pastel families an event can get automatically: all but the grey one.
const _autoFamilies = 9;

/// Index (in the pastel families) of the automatic color of an event titled
/// [title]: FNV-1a of the trimmed, lower-case title, stable across runs and
/// platforms (unlike [String.hashCode]). An empty title falls back to
/// [fallback] (the id).
int autoEventSwatchIndex(String title, String fallback) {
  final key = title.trim().toLowerCase();
  var hash = 0x811c9dc5;
  for (final unit in (key.isEmpty ? fallback : key).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash % _autoFamilies;
}

_Swatch _autoSwatch(CalendarEventModel item) {
  final i = autoEventSwatchIndex(item.title, item.id);
  return (
    light: AppColors.pastelLight[i],
    dark: AppColors.pastelDark[i],
    accent: AppColors.pastelDeep[i],
  );
}

Color _festiveEnd(Color color, bool isDark) =>
    isDark ? AppColors.tintDark(color) : AppColors.tintLight(color);

/// A user-picked event color. A palette swatch (picked in either theme) maps
/// to the swatch at the same position in the current theme, with the deep
/// tone of its family as accent (blue-grey for white and black); any other
/// color is the accent itself, on its own light / dark tint.
_Swatch _customSwatch(Color color) {
  var i = AppColors.noteSwatchesLight.indexOf(color);
  if (i < 0) i = AppColors.noteSwatchesDark.indexOf(color);
  if (i < 0) return _category(color);
  return (
    light: AppColors.noteSwatchesLight[i],
    dark: AppColors.noteSwatchesDark[i],
    accent: AppColors.swatchAccent(i),
  );
}

CalendarItemStyle _style(
  _Swatch swatch,
  bool isDark,
  IconData? icon, {
  bool isDone = false,
  Color? festiveEnd,
  EventTexture? texture,
}) {
  final opaque = isDark ? swatch.dark : swatch.light;
  return CalendarItemStyle(
    background: isDone ? opaque.withValues(alpha: 0.55) : opaque,
    foreground: AppColors.contrastingTextColor(opaque),
    accent: swatch.accent,
    icon: icon,
    isDone: isDone,
    festiveEnd: festiveEnd,
    texture: texture,
  );
}
