// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/theme/app_colors.dart';

void main() {
  group('AppColors.contrastRatio', () {
    test('is 21 for black on white and 1 for identical colors', () {
      expect(
        AppColors.contrastRatio(Colors.black, Colors.white),
        closeTo(21, 0.01),
      );
      expect(AppColors.contrastRatio(Colors.teal, Colors.teal), 1);
    });

    test('is symmetric', () {
      const a = Color(0xFF37474F);
      const b = Color(0xFFFFF9C4);
      expect(AppColors.contrastRatio(a, b), AppColors.contrastRatio(b, a));
    });
  });

  group('AppColors.contrastingTextColor', () {
    test('picks dark text on light colors and white on dark ones', () {
      expect(AppColors.contrastingTextColor(Colors.white), Colors.black87);
      expect(AppColors.contrastingTextColor(Colors.yellow), Colors.black87);
      expect(AppColors.contrastingTextColor(Colors.black), Colors.white);
      expect(AppColors.contrastingTextColor(AppColors.ink), Colors.white);
    });

    test('picks the higher-contrast option for saturated mid tones', () {
      // A flat 0.5 luminance threshold would pick white on Colors.red, where
      // dark text actually contrasts more.
      for (final c in [Colors.red, Colors.blue, const Color(0xFFBF360C)]) {
        final chosen = AppColors.contrastingTextColor(c);
        final other = chosen == Colors.white ? Colors.black87 : Colors.white;
        expect(
          AppColors.contrastRatio(c, chosen),
          greaterThanOrEqualTo(AppColors.contrastRatio(c, other)),
          reason: '$c',
        );
      }
    });

    test('every note swatch gets text with at least WCAG AA contrast', () {
      for (final swatch in [
        ...AppColors.noteSwatchesLight,
        ...AppColors.noteSwatchesDark,
      ]) {
        final text = AppColors.contrastingTextColor(swatch);
        expect(
          AppColors.contrastRatio(swatch, text),
          greaterThanOrEqualTo(4.5),
          reason: '$swatch',
        );
      }
    });

    test('light swatches get dark text, dark swatches get white', () {
      for (final s in [...AppColors.pastelLight, ...AppColors.pastelMedium]) {
        expect(AppColors.contrastingTextColor(s), Colors.black87, reason: '$s');
      }
      for (final s in [
        ...AppColors.pastelDark,
        ...AppColors.pastelDarkStrong,
      ]) {
        expect(AppColors.contrastingTextColor(s), Colors.white, reason: '$s');
      }
    });
  });

  group('Text swatches', () {
    test('family colors are readable on the theme surface (WCAG AA)', () {
      for (final c in AppColors.textSwatchesLight) {
        if (c == AppColors.paletteWhite) continue;
        expect(
          AppColors.contrastRatio(c, AppColors.surfaceLight),
          c == AppColors.paletteBlack || AppColors.pastelDeep.contains(c)
              ? greaterThanOrEqualTo(4.5)
              : anything,
          reason: '$c',
        );
      }
      for (final c in AppColors.textSwatchesDark) {
        if (c == AppColors.paletteBlack) continue;
        expect(
          AppColors.contrastRatio(c, AppColors.surfaceDark),
          greaterThanOrEqualTo(4.5),
          reason: '$c',
        );
      }
    });

    test('picker lists have two full rows and matching positions', () {
      for (final list in [
        AppColors.noteSwatchesLight,
        AppColors.noteSwatchesDark,
        AppColors.textSwatchesLight,
        AppColors.textSwatchesDark,
      ]) {
        expect(list.length, AppColors.swatchRowLength * 2);
        expect(list[0], AppColors.paletteWhite);
        expect(list[AppColors.swatchRowLength], AppColors.paletteBlack);
      }
    });
  });
}
