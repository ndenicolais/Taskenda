// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routing/notification_target.dart';
import '../l10n/l10n.dart';
import 'core_providers.dart';
import 'reminders_actions.dart';

/// Push notifications for sharing: when the owner adds a collaborator to a
/// note, task or event, the Cloud Function in `functions/` sends a message
/// to the devices of that collaborator.
///
/// Each device stores its FCM token in `users/{uid}/fcm_tokens/{token}`
/// (`token`, `lang` for the message language, `platform`, `updatedAt`),
/// removed at sign-out and with the account. In the background Android
/// shows the message by itself; in the foreground it is shown here with
/// `NotificationService.showShared`. Tapping it opens the item through
/// `NotificationService.pendingTarget`, like a reminder. Not on the web.
class PushMessaging {
  PushMessaging(this._ref) {
    if (kIsWeb) return;
    _subs
      ..add(FirebaseMessaging.onMessage.listen(_showInForeground))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
    _openInitialMessage();
  }

  /// The app was started by tapping a push.
  Future<void> _openInitialMessage() async {
    try {
      final m = await FirebaseMessaging.instance.getInitialMessage();
      if (m != null) _open(m);
    } catch (e) {
      _log('initial message', e);
    }
  }

  final Ref _ref;
  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<String>? _refreshSub;
  String _uid = '';
  String? _token;

  CollectionReference<Map<String, dynamic>> _tokens(String uid) => _ref
      .read(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('fcm_tokens');

  static void _log(String what, Object e) {
    if (kDebugMode) debugPrint('Push $what failed: $e');
  }

  /// Saves this device's token for [uid] (after each sign-in, also on a
  /// cold start) and keeps it current. Best effort: without a token the
  /// shared items still appear, just without a push.
  Future<void> register(String uid) async {
    if (kIsWeb || uid.isEmpty) return;
    _uid = uid;
    _askPermissionOnce().catchError((Object e) => _log('permission', e));
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || _uid != uid) return;
      await _save(uid, token);
      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        if (_uid.isNotEmpty) _save(_uid, t).catchError(_logRefresh);
      });
    } catch (e) {
      _log('registration', e);
    }
  }

  static void _logRefresh(Object e) => _log('token refresh', e);

  static const _kPermissionAskedKey = 'notification_permission_asked';

  /// The first time the home opens on this device (right after sign-up or
  /// sign-in), so pushes for shared items can be shown on Android 13+ even
  /// if the user never set a reminder. Asked only once: later the dialog
  /// comes from setting a reminder, or from the system settings.
  Future<void> _askPermissionOnce() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_kPermissionAskedKey) ?? false) return;
    await prefs.setBool(_kPermissionAskedKey, true);
    await _ref.read(notificationServiceProvider).requestPermissions();
  }

  Future<void> _save(String uid, String token) async {
    _token = token;
    await _tokens(uid).doc(token).set({
      'token': token,
      'lang': currentL10n().localeName,
      'platform': defaultTargetPlatform.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Run before signing out (the token document is the user's): this
  /// device stops receiving their pushes.
  Future<void> unregister() async {
    final uid = _uid;
    final token = _token;
    _uid = '';
    if (kIsWeb || uid.isEmpty || token == null) return;
    try {
      await _tokens(uid).doc(token).delete();
    } catch (e) {
      _log('unregistration', e);
    }
  }

  /// What the message opens: `data` carries `type` (note, task, event) and
  /// `id`.
  static NotificationTarget? _target(RemoteMessage m) =>
      NotificationTarget.parse('${m.data['type']}:${m.data['id']}');

  void _showInForeground(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    _ref
        .read(notificationServiceProvider)
        .showShared(
          title: n.title ?? '',
          body: n.body ?? '',
          target: _target(m),
        )
        .catchError((Object e) => _log('foreground display', e));
  }

  void _open(RemoteMessage m) {
    final target = _target(m);
    if (target != null) {
      _ref.read(notificationServiceProvider).pendingTarget.value = target;
    }
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _refreshSub?.cancel();
    _refreshSub = null;
  }
}

final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final push = PushMessaging(ref);
  ref.onDispose(push.dispose);
  return push;
});
