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

import '../../theme/app_colors.dart';

/// The pastel palette as two rows of [AppColors.swatchRowLength] circles:
/// white + light shades, black + darker shades. Background or text colors
/// of the current theme, depending on [forText].
class ColorPickerWidget extends StatelessWidget {
  const ColorPickerWidget({
    super.key,
    required this.current,
    required this.onPick,
    this.isDark = false,
    this.forText = false,
  });

  final Color current;
  final ValueChanged<Color> onPick;
  final bool isDark;

  /// Text colors (readable on the theme's backgrounds) instead of
  /// background colors.
  final bool forText;

  static const double _maxSize = 36;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final swatches =
        forText
            ? (isDark
                ? AppColors.textSwatchesDark
                : AppColors.textSwatchesLight)
            : (isDark
                ? AppColors.noteSwatchesDark
                : AppColors.noteSwatchesLight);
    const perRow = AppColors.swatchRowLength;
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = (constraints.maxWidth - _gap * (perRow - 1)) / perRow;
        final size = fit.clamp(16.0, _maxSize);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row * perRow < swatches.length; row++) ...[
              if (row > 0) const SizedBox(height: _gap + 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = row * perRow; i < (row + 1) * perRow; i++) ...[
                    if (i > row * perRow) const SizedBox(width: _gap),
                    _Swatch(
                      color: swatches[i],
                      size: size,
                      selected: current == swatches[i],
                      selectedBorder: colorScheme.primary,
                      border: colorScheme.outlineVariant,
                      onTap: () => onPick(swatches[i]),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    required this.selected,
    required this.selectedBorder,
    required this.border,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool selected;
  final Color selectedBorder;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? selectedBorder : border,
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            if (selected) BoxShadow(color: color.withAlpha(102), blurRadius: 8),
          ],
        ),
      ),
    );
  }
}
