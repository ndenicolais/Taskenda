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
import 'app_colors.dart';
import 'app_font_sizes.dart';
import 'app_radius.dart';

/// App-wide Material 3 themes built from the [AppColors] palette.
///
/// The color schemes are written out role by role (no `fromSeed`), so the
/// brand colors are used exactly:
/// Light → indigo primary on white surfaces over a lavender-grey background.
/// Dark  → soft indigo primary on deep blue-grey surfaces.
/// Amber is the secondary (accent) color in both.
class AppTheme {
  AppTheme._();

  /// Titles and headlines.
  static const headingFont = 'Manrope';

  /// Body text and labels.
  static const bodyFont = 'Inter';

  // ─── Color schemes ──────────────────────────────────────────────────────────

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.eventTint,
    onPrimaryContainer: AppColors.ink,
    secondary: AppColors.secondary,
    onSecondary: AppColors.ink,
    secondaryContainer: Color(0xFFFDF1DC),
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.teal,
    onTertiary: AppColors.white,
    tertiaryContainer: Color(0xFFE7F5F3),
    onTertiaryContainer: AppColors.ink,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: Color(0xFFFDE8E8),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    surfaceDim: Color(0xFFE9E9F2),
    surfaceBright: AppColors.surfaceLight,
    surfaceContainerLowest: AppColors.surfaceLight,
    surfaceContainerLow: Color(0xFFFBFBFE),
    surfaceContainer: AppColors.backgroundLight,
    surfaceContainerHigh: Color(0xFFF0F0F8),
    surfaceContainerHighest: Color(0xFFEAEAF4),
    outline: Color(0xFF9A9AB3),
    outlineVariant: AppColors.borderLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.textDark,
    inversePrimary: AppColors.primaryDark,
    // Flat surfaces: no indigo cast on elevated cards and sheets.
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.backgroundDark,
    primaryContainer: Color(0xFF3E3E64),
    onPrimaryContainer: AppColors.textDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.ink,
    secondaryContainer: Color(0xFF5B452B),
    onSecondaryContainer: AppColors.textDark,
    tertiary: AppColors.teal,
    onTertiary: AppColors.white,
    tertiaryContainer: Color(0xFF1B3B42),
    onTertiaryContainer: AppColors.textDark,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: Color(0xFF4A1D22),
    onErrorContainer: Color(0xFFFECACA),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    surfaceDim: AppColors.backgroundDark,
    surfaceBright: Color(0xFF34344A),
    surfaceContainerLowest: AppColors.backgroundDark,
    surfaceContainerLow: Color(0xFF1A1A27),
    surfaceContainer: AppColors.surfaceDark,
    surfaceContainerHigh: Color(0xFF262638),
    surfaceContainerHighest: AppColors.borderDark,
    outline: Color(0xFF6B6B85),
    outlineVariant: AppColors.borderDark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textDark,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.primary,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light =>
      _build(lightScheme, background: AppColors.backgroundLight);

  static ThemeData get dark =>
      _build(darkScheme, background: AppColors.backgroundDark);

  // ─── Typography ─────────────────────────────────────────────────────────────

  /// Material 3 type roles pinned to [AppFontSizes], so screens use
  /// `Theme.of(context).textTheme.*` instead of literal font sizes.
  /// Display, headline and title roles use [headingFont] (600–800), body and
  /// label roles use [bodyFont] (400–600).
  static TextTheme _textTheme(ColorScheme cs) {
    final base = ThemeData(brightness: cs.brightness).textTheme;
    TextStyle? heading(TextStyle? s, FontWeight w, [double? size]) =>
        s?.copyWith(fontFamily: headingFont, fontWeight: w, fontSize: size);
    TextStyle? body(TextStyle? s, FontWeight w, double size) =>
        s?.copyWith(fontFamily: bodyFont, fontWeight: w, fontSize: size);
    return base
        .copyWith(
          displayLarge: heading(base.displayLarge, FontWeight.w800),
          displayMedium: heading(base.displayMedium, FontWeight.w800),
          displaySmall: heading(base.displaySmall, FontWeight.w800),
          headlineLarge: heading(base.headlineLarge, FontWeight.w700),
          headlineMedium: heading(
            base.headlineMedium,
            FontWeight.w700,
            AppFontSizes.display,
          ),
          headlineSmall: heading(
            base.headlineSmall,
            FontWeight.w700,
            AppFontSizes.headline,
          ),
          titleLarge: heading(
            base.titleLarge,
            FontWeight.w700,
            AppFontSizes.xxl,
          ),
          titleMedium: heading(
            base.titleMedium,
            FontWeight.w600,
            AppFontSizes.lg,
          ),
          titleSmall: heading(
            base.titleSmall,
            FontWeight.w600,
            AppFontSizes.md,
          ),
          bodyLarge: body(base.bodyLarge, FontWeight.w400, AppFontSizes.lg),
          bodyMedium: body(base.bodyMedium, FontWeight.w400, AppFontSizes.md),
          bodySmall: body(base.bodySmall, FontWeight.w400, AppFontSizes.sm),
          labelLarge: body(base.labelLarge, FontWeight.w600, AppFontSizes.md),
          labelMedium: body(base.labelMedium, FontWeight.w500, AppFontSizes.sm),
          labelSmall: body(base.labelSmall, FontWeight.w500, AppFontSizes.xs),
        )
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
  }

  // ─── Shared builder ─────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme cs, {required Color background}) {
    final textTheme = _textTheme(cs);
    final labelSmall = TextStyle(
      fontFamily: bodyFont,
      fontSize: AppFontSizes.sm,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
    );
    final labelSelected = labelSmall.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w600,
    );
    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      fontFamily: bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: cs.outlineVariant,

      // AppBar: same color as the page, title in the heading font.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: cs.onSurface,
          fontSize: AppFontSizes.xl,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(backgroundColor: cs.surface),

      // NavigationBar (bottom) and NavigationRail (side): same look.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected)
                    ? cs.primary
                    : cs.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? labelSelected
                  : labelSmall,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        selectedIconTheme: IconThemeData(color: cs.primary),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        selectedLabelTextStyle: labelSelected,
        unselectedLabelTextStyle: labelSmall,
      ),

      // Cards: flat, white (or dark surface) with a thin border.
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Dialogs & bottom sheets: one shape app-wide, no per-call overrides
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),

      // Checkbox: indigo fill with the check in onPrimary.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? cs.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(cs.onPrimary),
        side: BorderSide(color: cs.outline, width: 1.5),
      ),

      // Text fields: outlined; only `border` is set, so fields that pass
      // `InputBorder.none` (editors, search bars) stay borderless.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelStyle: TextStyle(fontFamily: bodyFont, color: cs.onSurfaceVariant),
        hintStyle: TextStyle(fontFamily: bodyFont, color: cs.onSurfaceVariant),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: cs.surface,
        selectedColor: cs.primaryContainer,
        side: BorderSide(color: cs.outlineVariant),
        checkmarkColor: cs.primary,
        labelStyle: TextStyle(
          fontFamily: bodyFont,
          color: cs.onSurface,
          fontSize: AppFontSizes.xs,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Sliders (style editor)
      sliderTheme: SliderThemeData(activeTrackColor: cs.primary),
    );
  }
}
