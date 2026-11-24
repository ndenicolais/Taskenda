// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// When the keyboard is asked for again after focusing (see [_focus]).
const _keyboardRetries = [
  Duration.zero,
  Duration(milliseconds: 250),
  Duration(milliseconds: 600),
];

/// Focuses [node] (opening the keyboard) once the route of [context] has
/// finished its push transition: opening the keyboard while the page is
/// still sliding in makes both animations stutter. Call from `initState`.
///
/// Opened from a home screen widget the app may still be starting, or
/// coming back to the foreground: focus then waits for the app to be
/// resumed.
void focusAfterRouteTransition(BuildContext context, FocusNode node) {
  void focusWhenResumed() {
    if (!context.mounted) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      _focus(node);
      return;
    }
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        listener.dispose();
        if (context.mounted) _focus(node);
      },
    );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      focusWhenResumed();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      focusWhenResumed();
    }

    animation.addStatusListener(onStatus);
  });
}

/// Android can leave the keyboard closed (cursor shown, no keyboard) when
/// focus is given from code right after a route change, or while the
/// window is not focused yet on a cold start: the keyboard is asked for
/// again over the next frames ([_keyboardRetries]) while [node] keeps the
/// focus. Frame callbacks instead of timers, so nothing is left pending
/// once the page is gone.
void _focus(FocusNode node) {
  node.requestFocus();
  final scheduler = SchedulerBinding.instance;
  Duration? start;
  var next = 0;
  void onFrame(Duration timestamp) {
    start ??= timestamp;
    if (timestamp - start! >= _keyboardRetries[next]) {
      if (!node.hasFocus) return; // Focus moved on: stop asking.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      next++;
      if (next == _keyboardRetries.length) return;
    }
    scheduler.scheduleFrameCallback(onFrame);
  }

  // The first ask needs the input connection that the focus opens on the
  // next frame.
  scheduler.addPostFrameCallback(
    (_) => scheduler.scheduleFrameCallback(onFrame),
  );
  scheduler.scheduleFrame();
}
