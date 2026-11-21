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

  // ─── Pastel palette ─────────────────────────────────────────────────────────
  //
  // Ten color families, same order in every list: red, peach, yellow, green,
  // mint, sky, indigo, violet, pink, grey. Constants (not computed), so a
  // color read back from Firestore as `Color(int)` is equal to its swatch.

  /// Pastel of each family, light shade: note backgrounds (light theme),
  /// text on dark backgrounds.
  static const List<Color> pastelLight = [
    Color(0xFFFBDADC),
    Color(0xFFFDE3CF),
    Color(0xFFFFF4C7),
    Color(0xFFDDF1D6),
    Color(0xFFD3F1EA),
    Color(0xFFD8EDFB),
    Color(0xFFDEDFF9),
    Color(0xFFEBDDF6),
    Color(0xFFFBDDED),
    Color(0xFFEDEDF2),
  ];

  /// Pastel of each family, medium shade.
  static const List<Color> pastelMedium = [
    Color(0xFFF5AFB4),
    Color(0xFFF8C29A),
    Color(0xFFFBE08E),
    Color(0xFFB2DEA3),
    Color(0xFF9DDCCD),
    Color(0xFFA6D1F2),
    Color(0xFFB3B6F0),
    Color(0xFFCDAFEA),
    Color(0xFFF3AFD3),
    Color(0xFFCDCDD7),
  ];

  /// Muted dark tone of each family: note backgrounds in the dark theme.
  static const List<Color> pastelDark = [
    Color(0xFF4A2B2F),
    Color(0xFF4B3426),
    Color(0xFF49412A),
    Color(0xFF2D4229),
    Color(0xFF23413B),
    Color(0xFF263C4F),
    Color(0xFF2D2E53),
    Color(0xFF3A2C4F),
    Color(0xFF4A2C3F),
    Color(0xFF2E2E3B),
  ];

  /// Second, stronger dark tone of each family (dark theme backgrounds).
  static const List<Color> pastelDarkStrong = [
    Color(0xFF6E3C42),
    Color(0xFF6E4A33),
    Color(0xFF6B5D33),
    Color(0xFF405E3A),
    Color(0xFF305D54),
    Color(0xFF315672),
    Color(0xFF3E4176),
    Color(0xFF543E72),
    Color(0xFF6E3D5A),
    Color(0xFF47475A),
  ];

  /// Deep tone of each family: text on light backgrounds (≥ 4.5:1 on white).
  static const List<Color> pastelDeep = [
    Color(0xFFB23A48),
    Color(0xFFB5582A),
    Color(0xFF8C6D12),
    Color(0xFF3F7A2E),
    Color(0xFF23766A),
    Color(0xFF2B6EA6),
    Color(0xFF4B4FC0),
    Color(0xFF7D45B0),
    Color(0xFFB23F7E),
    Color(0xFF5A5A6E),
  ];

  /// White and black of the palette.
  static const Color paletteWhite = white;
  static const Color paletteBlack = ink;

  /// Number of swatches in each picker row: white or black + the families.
  static const int swatchRowLength = 11;

  // Picker lists: two rows of [swatchRowLength], white + light shades, then
  // black + darker shades. Lists of the same kind share positions, so a
  // swatch maps to the one at the same index in the other theme.

  /// Note and event backgrounds offered in the light theme.
  static const List<Color> noteSwatchesLight = [
    paletteWhite,
    ...pastelLight,
    paletteBlack,
    ...pastelMedium,
  ];

  /// Note and event backgrounds offered in the dark theme.
  static const List<Color> noteSwatchesDark = [
    paletteWhite,
    ...pastelDark,
    paletteBlack,
    ...pastelDarkStrong,
  ];

  /// Text colors offered in the light theme: medium pastels and deep tones,
  /// since light pastels can't be read on light backgrounds.
  static const List<Color> textSwatchesLight = [
    paletteWhite,
    ...pastelMedium,
    paletteBlack,
    ...pastelDeep,
  ];

  /// Text colors offered in the dark theme: the pastels.
  static const List<Color> textSwatchesDark = [
    paletteWhite,
    ...pastelLight,
    paletteBlack,
    ...pastelMedium,
  ];

  /// Accent of a [noteSwatchesLight] / [noteSwatchesDark] position: the deep
  /// tone of its family, blue-grey for white and black.
  static Color swatchAccent(int index) {
    final family = index % swatchRowLength - 1;
    return family < 0 ? textSecondaryDark : pastelDeep[family];
  }

  // ─── Colors saved by older palettes ─────────────────────────────────────────

  /// Swatches of the earlier palettes (Noteep, then the category tints) →
  /// the matching pastel swatch.
  static const Map<int, Color> _legacy = {
    // Noteep, light theme.
    0xFFFFF9C4: Color(0xFFFFF4C7), // yellow
    0xFFB2EBF2: Color(0xFFD8EDFB), // cyan → sky
    0xFFDCEDC8: Color(0xFFDDF1D6), // green
    0xFFFFCCBC: Color(0xFFFDE3CF), // orange → peach
    0xFFE1BEE7: Color(0xFFEBDDF6), // lilac → violet
    0xFFCFD8DC: Color(0xFFEDEDF2), // blue grey → grey
    0xFFF8BBD9: Color(0xFFFBDDED), // pink
    // Noteep, dark theme.
    0xDD000000: paletteBlack, // black87
    0xFF212121: Color(0xFF2E2E3B), // grey
    0xFF37474F: Color(0xFF263C4F), // blue grey → sky
    0xFF4A148C: Color(0xFF3A2C4F), // purple → violet
    0xFF1A237E: Color(0xFF2D2E53), // indigo
    0xFF880E4F: Color(0xFF4A2C3F), // wine → pink
    0xFF1B5E20: Color(0xFF2D4229), // green
    0xFFBF360C: Color(0xFF4B3426), // deep orange → peach
    // Category tints, light theme.
    0xFFEEEEFB: Color(0xFFDEDFF9), // indigo
    0xFFFEF6E9: Color(0xFFFFF4C7), // amber → yellow
    0xFFE7F5F3: Color(0xFFD3F1EA), // teal → mint
    0xFFFEF0EE: Color(0xFFFBDADC), // coral → red
    0xFFEBF5FD: Color(0xFFD8EDFB), // blue → sky
    0xFFF6EEF9: Color(0xFFEBDDF6), // violet
    0xFFE4E4F0: Color(0xFFEDEDF2), // neutral → grey
    // Category tints, dark theme.
    0xFF1F1F2E: paletteBlack, // default surface
    0xFF2C2C53: Color(0xFF2D2E53), // indigo
    0xFF4E3C2C: Color(0xFF49412A), // amber → yellow
    0xFF1B3B42: Color(0xFF23413B), // teal → mint
    0xFF4D3038: Color(0xFF4A2B2F), // coral → red
    0xFF253B57: Color(0xFF263C4F), // blue → sky
    0xFF3D2B50: Color(0xFF3A2C4F), // violet
    0xFF2E2E42: Color(0xFF2E2E3B), // neutral → grey
  };

  /// A color read from storage (`toARGB32()` of a note or event color):
  /// a swatch of an earlier palette becomes the matching pastel swatch,
  /// anything else (custom colors, current swatches) is returned unchanged.
  /// Applied when reading, so old data and Noteep backups need no rewrite.
  static Color fromStored(int argb) => _legacy[argb] ?? Color(argb);

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
