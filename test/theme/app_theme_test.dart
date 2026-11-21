// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/theme/app_colors.dart';
import 'package:taskenda/theme/app_font_sizes.dart';
import 'package:taskenda/theme/app_theme.dart';

void main() {
  for (final entry
      in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    group('AppTheme.${entry.key} textTheme', () {
      final t = entry.value.textTheme;

      test('type roles follow AppFontSizes', () {
        expect(t.headlineMedium?.fontSize, AppFontSizes.display);
        expect(t.headlineSmall?.fontSize, AppFontSizes.headline);
        expect(t.titleLarge?.fontSize, AppFontSizes.xxl);
        expect(t.titleMedium?.fontSize, AppFontSizes.lg);
        expect(t.titleSmall?.fontSize, AppFontSizes.md);
        expect(t.bodyLarge?.fontSize, AppFontSizes.lg);
        expect(t.bodyMedium?.fontSize, AppFontSizes.md);
        expect(t.bodySmall?.fontSize, AppFontSizes.sm);
        expect(t.labelLarge?.fontSize, AppFontSizes.md);
        expect(t.labelMedium?.fontSize, AppFontSizes.sm);
        expect(t.labelSmall?.fontSize, AppFontSizes.xs);
      });

      test('headings use Manrope 600–800, body and labels Inter 400–600', () {
        for (final style in [
          t.displaySmall,
          t.headlineMedium,
          t.titleLarge,
          t.titleMedium,
          t.titleSmall,
        ]) {
          expect(style?.fontFamily, 'Manrope');
          expect(style!.fontWeight!.value, inInclusiveRange(600, 800));
        }
        for (final style in [
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.labelSmall,
        ]) {
          expect(style?.fontFamily, 'Inter');
          expect(style!.fontWeight!.value, inInclusiveRange(400, 600));
        }
      });
    });
  }

  group('AppTheme color schemes use the brand colors exactly', () {
    test('light', () {
      final t = AppTheme.light;
      final cs = t.colorScheme;
      expect(cs.primary, AppColors.primary);
      expect(cs.onPrimary, AppColors.white);
      expect(cs.secondary, AppColors.secondary);
      expect(cs.onSecondary, AppColors.ink);
      expect(cs.surface, const Color(0xFFFFFFFF));
      expect(cs.onSurfaceVariant, const Color(0xFF4A4A63));
      expect(cs.outlineVariant, const Color(0xFFE4E4F0));
      expect(cs.error, const Color(0xFFDC2626));
      expect(t.scaffoldBackgroundColor, const Color(0xFFF6F6FB));
    });

    test('dark', () {
      final t = AppTheme.dark;
      final cs = t.colorScheme;
      expect(cs.primary, const Color(0xFF8C8CF0));
      expect(cs.onPrimary, const Color(0xFF15151F));
      expect(cs.secondary, const Color(0xFFF5A524));
      expect(cs.onSecondary, const Color(0xFF1B1B2F));
      expect(cs.surface, const Color(0xFF1F1F2E));
      expect(cs.onSurface, const Color(0xFFEDEDF5));
      expect(cs.onSurfaceVariant, const Color(0xFFA6A6BF));
      expect(cs.outlineVariant, const Color(0xFF2E2E42));
      expect(t.scaffoldBackgroundColor, const Color(0xFF15151F));
    });
  });

  group('AppColors.fromStored', () {
    test('maps Noteep swatches onto the pastel ones', () {
      expect(AppColors.fromStored(0xFFFFF9C4), AppColors.pastelLight[2]);
      expect(AppColors.fromStored(0xFFF8BBD9), AppColors.pastelLight[8]);
      expect(AppColors.fromStored(0xDD000000), AppColors.paletteBlack);
      expect(AppColors.fromStored(0xFF1A237E), AppColors.pastelDark[6]);
    });

    test('maps the category tints onto the pastel ones', () {
      expect(AppColors.fromStored(0xFFEEEEFB), AppColors.pastelLight[6]);
      expect(AppColors.fromStored(0xFFE7F5F3), AppColors.pastelLight[4]);
      expect(AppColors.fromStored(0xFF1F1F2E), AppColors.paletteBlack);
      expect(AppColors.fromStored(0xFF4D3038), AppColors.pastelDark[0]);
    });

    test('keeps any other color and round-trips the new swatches', () {
      expect(AppColors.fromStored(0xFF2196F3), const Color(0xFF2196F3));
      for (final c in [
        ...AppColors.noteSwatchesLight,
        ...AppColors.noteSwatchesDark,
        ...AppColors.textSwatchesLight,
        ...AppColors.textSwatchesDark,
      ]) {
        expect(AppColors.fromStored(c.toARGB32()), c);
      }
    });
  });
}
