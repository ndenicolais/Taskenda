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
import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';

/// App logo on an indigo rounded tile, matching the launcher icon
/// (`images/icons/logo.svg`). The image is the centre of the adaptive icon
/// foreground (`tool/icons/generate_icons.ps1`), so it already has the right
/// margin and needs no padding.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Image.asset(
        'assets/images/app_logo.png',
        semanticLabel: context.l10n.appLogoLabel,
      ),
    );
  }
}
