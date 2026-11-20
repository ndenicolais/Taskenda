// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Focuses [node] (opening the keyboard) once the route of [context] has
/// finished its push transition: opening the keyboard while the page is
/// still sliding in makes both animations stutter. Call from `initState`.
void focusAfterRouteTransition(BuildContext context, FocusNode node) {
  void focus() {
    node.requestFocus();
    // Android can leave the keyboard closed (cursor shown, no keyboard)
    // when focus is given from code right after a route change: ask for
    // it again once the input connection is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.hasFocus) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
    });
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      focus();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      if (context.mounted) focus();
    }

    animation.addStatusListener(onStatus);
  });
}
