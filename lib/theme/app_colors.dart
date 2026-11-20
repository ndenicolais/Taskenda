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

/// Central color palette for the app. Widgets read colors from the theme
/// (`Theme.of(context).colorScheme`) or from here, never from literals.
class AppColors {
  AppColors._();

  static const Color white = Color(0xFFFFFFFF);

  // ─── Brand ──────────────────────────────────────────────────────────────────

  /// Indigo: primary color of the light theme, launcher icon background.
  static const Color primary = Color(0xFF5B5BD6);

  /// Amber: accent of notes, starred tasks, warnings.
  static const Color secondary = Color(0xFFF5A524);

  /// Text on light surfaces and on [secondary].
  static const Color ink = Color(0xFF1B1B2F);

  // ─── Light theme ────────────────────────────────────────────────────────────

  static const Color backgroundLight = Color(0xFFF6F6FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = ink;
  static const Color textSecondaryLight = Color(0xFF4A4A63);
  static const Color borderLight = Color(0xFFE4E4F0);

  /// Very light indigo: default event background, primary container.
  static const Color eventTint = Color(0xFFEEEEFB);

  // ─── Dark theme ─────────────────────────────────────────────────────────────

  static const Color backgroundDark = Color(0xFF15151F);
  static const Color surfaceDark = Color(0xFF1F1F2E);
  static const Color primaryDark = Color(0xFF8C8CF0);
  static const Color secondaryDark = secondary;
  static const Color textDark = Color(0xFFEDEDF5);
  static const Color textSecondaryDark = Color(0xFFA6A6BF);
  static const Color borderDark = Color(0xFF2E2E42);

  // ─── Status ─────────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = secondary;

  // ─── Categories ─────────────────────────────────────────────────────────────

  static const Color indigo = primary;
  static const Color amber = secondary;
  static const Color teal = Color(0xFF0F9D8A);
  static const Color coral = Color(0xFFF06A5A);
  static const Color blue = Color(0xFF3B9EE8);
  static const Color violet = Color(0xFFA855C7);

  /// Category / event colors, in order (charts, calendar kinds, swatches).
  static const List<Color> categories = [
    indigo,
    amber,
    teal,
    coral,
    blue,
    violet,
  ];

  /// Very light tint of each of [categories] (10% on white), for event and
  /// note backgrounds in the light theme. Same order as [categories].
  static const List<Color> categoryTintsLight = [
    eventTint,
    Color(0xFFFEF6E9),
    Color(0xFFE7F5F3),
    Color(0xFFFEF0EE),
    Color(0xFFEBF5FD),
    Color(0xFFF6EEF9),
  ];

  /// Dark tint of each of [categories] (22% on [surfaceDark]), for event and
  /// note backgrounds in the dark theme. Same order as [categories].
  static const List<Color> categoryTintsDark = [
    Color(0xFF2C2C53),
    Color(0xFF4E3C2C),
    Color(0xFF1B3B42),
    Color(0xFF4D3038),
    Color(0xFF253B57),
    Color(0xFF3D2B50),
  ];

  /// Light tint of any [color]: the precomputed one for a category, else
  /// 10% of [color] on white.
  static Color tintLight(Color color) {
    final i = categories.indexOf(color);
    if (i >= 0) return categoryTintsLight[i];
    return Color.alphaBlend(color.withValues(alpha: 0.10), surfaceLight);
  }

  /// Dark tint of any [color]: the precomputed one for a category, else
  /// 22% of [color] on [surfaceDark].
  static Color tintDark(Color color) {
    final i = categories.indexOf(color);
    if (i >= 0) return categoryTintsDark[i];
    return Color.alphaBlend(color.withValues(alpha: 0.22), surfaceDark);
  }

  // ─── Note swatches ──────────────────────────────────────────────────────────
  //
  // Same order in both lists, so a swatch maps to the one at the same index
  // in the other theme: 0 default, 1–6 the tints of [categories], 7 neutral.
  // Constants (not computed), so a color read back from Firestore as
  // `Color(int)` is equal to its swatch.

  /// Preset note colors offered in [ColorPickerWidget] for light theme notes.
  static const List<Color> noteSwatchesLight = [
    surfaceLight,
    ...categoryTintsLight,
    borderLight,
  ];

  /// Preset note colors offered in [ColorPickerWidget] for dark theme notes.
  static const List<Color> noteSwatchesDark = [
    surfaceDark,
    ...categoryTintsDark,
    borderDark,
  ];

  // ─── Colors saved by Noteep ─────────────────────────────────────────────────

  /// Swatches of the old palette (Noteep) → index in the new swatch lists.
  /// Old light swatches map into [noteSwatchesLight], old dark ones into
  /// [noteSwatchesDark].
  static const Map<int, int> _legacyLight = {
    0xFFFFFFFF: 0, // white
    0xFFFFF9C4: 2, // yellow → amber
    0xFFB2EBF2: 5, // cyan → blue
    0xFFDCEDC8: 3, // green → teal
    0xFFFFCCBC: 4, // orange → coral
    0xFFE1BEE7: 6, // lilac → violet
    0xFFCFD8DC: 7, // blue grey → neutral
    0xFFF8BBD9: 4, // pink → coral
  };
  static const Map<int, int> _legacyDark = {
    0xDD000000: 0, // black87
    0xFF212121: 7, // grey → neutral
    0xFF37474F: 5, // blue grey → blue
    0xFF4A148C: 6, // purple → violet
    0xFF1A237E: 1, // indigo → indigo
    0xFF880E4F: 4, // wine → coral
    0xFF1B5E20: 3, // green → teal
    0xFFBF360C: 2, // deep orange → amber
  };

  /// A color read from storage (`toARGB32()` of a note or event color):
  /// a swatch of the old palette becomes the matching new swatch, anything
  /// else (custom Material colors, new swatches) is returned unchanged.
  /// Applied when reading, so old data and Noteep backups need no rewrite.
  static Color fromStored(int argb) {
    final light = _legacyLight[argb];
    if (light != null) return noteSwatchesLight[light];
    final dark = _legacyDark[argb];
    if (dark != null) return noteSwatchesDark[dark];
    return Color(argb);
  }

  // ─── Contrast ───────────────────────────────────────────────────────────────

  /// WCAG relative-luminance contrast ratio between two colors (1–21).
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Picks black or white — whichever gives the higher WCAG contrast ratio
  /// against [background] — instead of a flat luminance threshold, which can
  /// pick the weaker option for mid-luminance/saturated swatches.
  static Color contrastingTextColor(Color background) {
    return contrastRatio(background, Colors.black87) >=
            contrastRatio(background, Colors.white)
        ? Colors.black87
        : Colors.white;
  }
}
