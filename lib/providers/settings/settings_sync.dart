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
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import 'preferences_backup.dart';

/// Keeps the user's preferences ([syncedPreferencesProvider]) in step with
/// the account, in `users/{uid}/settings/preferences` (`values`,
/// `updatedAt`), so they follow the user to the web and to a new phone.
///
/// - Signed in ([start]): the document is listened to in real time; its
///   values are applied on this device, the last change wins.
/// - The first device to sign in (no document on the server yet) uploads
///   its own preferences. A missing document read from the offline cache is
///   ignored, so device defaults never overwrite the account's.
/// - A local change is uploaded after [debounce] (several quick changes
///   become one write), only once the account's values are known.
/// - Signed out ([stop]): nothing is synced, local values stay.
class SettingsSync {
  SettingsSync(this._ref, {this.debounce = const Duration(milliseconds: 800)});

  final Ref _ref;
  final Duration debounce;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remote;
  ProviderSubscription<Map<String, Object>>? _local;
  Timer? _pending;
  String? _uid;

  /// The values the account is known to hold; null until the first server
  /// read, so nothing is uploaded before.
  Map<String, Object?>? _synced;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _ref
      .read(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('preferences');

  void start(String uid) {
    if (uid == _uid) return;
    stop();
    _uid = uid;
    _remote = _doc(uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          _onRemote,
          onError: (Object e) {
            if (kDebugMode) debugPrint('Settings sync failed: $e');
          },
        );
    _local = _ref.listen(
      syncedPreferencesProvider,
      (_, next) => _onLocal(next),
    );
  }

  void stop() {
    _remote?.cancel();
    _remote = null;
    _local?.close();
    _local = null;
    _pending?.cancel();
    _pending = null;
    _uid = null;
    _synced = null;
  }

  void _onRemote(DocumentSnapshot<Map<String, dynamic>> snap) {
    // Our own write coming back.
    if (snap.metadata.hasPendingWrites) return;
    final values = snap.data()?['values'];
    if (values is! Map) {
      if (snap.metadata.isFromCache) return;
      // First device on this account: its preferences become the account's.
      _synced = const {};
      _upload();
      return;
    }
    final remote = Map<String, Object?>.from(values);
    if (mapEquals(remote, _synced)) return;
    _synced = remote;
    // A local change waiting to be uploaded is newer: it wins.
    if (_pending?.isActive ?? false) return;
    _ref.read(preferencesBackupProvider).restore(remote, synced: true);
  }

  void _onLocal(Map<String, Object> current) {
    if (_uid == null || _synced == null || mapEquals(current, _synced)) {
      return;
    }
    _pending?.cancel();
    _pending = Timer(debounce, _upload);
  }

  Future<void> _upload() async {
    final uid = _uid;
    if (uid == null) return;
    final values = _ref.read(syncedPreferencesProvider);
    if (mapEquals(values, _synced)) return;
    _synced = values;
    try {
      await _doc(
        uid,
      ).set({'values': values, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (kDebugMode) debugPrint('Settings not synced: $e');
    }
  }
}

final settingsSyncProvider = Provider<SettingsSync>((ref) {
  final sync = SettingsSync(ref);
  ref.onDispose(sync.stop);
  return sync;
});
