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
  });

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

final _Swatch _timedSwatch = _category(AppColors.indigo);
final _Swatch _taskSwatch = _category(AppColors.teal);
final _Swatch _birthdaySwatch = _category(birthdayColor);
final _Swatch _nameDaySwatch = _category(nameDayColor);
final _Swatch _allDaySwatch = _category(AppColors.violet);
final _Swatch _holidaySwatch = _category(AppColors.coral);

/// Tasks, birthdays, name days, all-day and timed events each get their own
/// category color; an event with a [CalendarEventModel.color] uses that one
/// instead (birthdays and name days keep their icon and festive gradient).
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
  if (custom != null) return _style(_customSwatch(custom), isDark, null);
  if (item.isAllDay) return _style(_allDaySwatch, isDark, null);
  return _style(_timedSwatch, isDark, null);
}

Color _festiveEnd(Color color, bool isDark) =>
    isDark ? AppColors.tintDark(color) : AppColors.tintLight(color);

/// A user-picked event color. A note swatch (picked in either theme) maps to
/// the swatch at the same position in the current theme, with its category
/// color as accent (neutral grey for the default and neutral swatches); any
/// other color is the accent itself, on its own light / dark tint.
_Swatch _customSwatch(Color color) {
  var i = AppColors.noteSwatchesLight.indexOf(color);
  if (i < 0) i = AppColors.noteSwatchesDark.indexOf(color);
  if (i < 0) return _category(color);
  final isCategory = i >= 1 && i <= AppColors.categories.length;
  return (
    light: AppColors.noteSwatchesLight[i],
    dark: AppColors.noteSwatchesDark[i],
    accent:
        isCategory ? AppColors.categories[i - 1] : AppColors.textSecondaryDark,
  );
}

CalendarItemStyle _style(
  _Swatch swatch,
  bool isDark,
  IconData? icon, {
  bool isDone = false,
  Color? festiveEnd,
}) {
  final opaque = isDark ? swatch.dark : swatch.light;
  return CalendarItemStyle(
    background: isDone ? opaque.withValues(alpha: 0.55) : opaque,
    foreground: AppColors.contrastingTextColor(opaque),
    accent: swatch.accent,
    icon: icon,
    isDone: isDone,
    festiveEnd: festiveEnd,
  );
}
