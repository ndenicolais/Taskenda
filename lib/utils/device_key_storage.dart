// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the unlocked encryption keys of a user are kept on this device, so
/// the encryption code isn't asked at every start:
///
/// - Android: always, in `flutter_secure_storage` (encrypted with a key in
///   the Android Keystore);
/// - web: in the tab's `sessionStorage` (gone when the tab is closed), or
///   in `localStorage` when the user ticks "Remember on this browser". The
///   web storage is only obfuscated, which is why it is opt-in.
class DeviceKeyStorage {
  DeviceKeyStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String uid) => 'taskenda_keys_$uid';

  static const _session = WebOptions(useSessionStorage: true);
  static const _local = WebOptions();

  Future<String?> read(String uid) async {
    if (!kIsWeb) return _storage.read(key: _key(uid));
    return await _storage.read(key: _key(uid), webOptions: _session) ??
        await _storage.read(key: _key(uid), webOptions: _local);
  }

  /// Saves [value]; on the web, [persistent] picks `localStorage` over
  /// `sessionStorage`.
  Future<void> write(
    String uid,
    String value, {
    bool persistent = false,
  }) async {
    if (!kIsWeb) return _storage.write(key: _key(uid), value: value);
    await delete(uid);
    await _storage.write(
      key: _key(uid),
      value: value,
      webOptions: persistent ? _local : _session,
    );
  }

  Future<void> delete(String uid) async {
    if (!kIsWeb) return _storage.delete(key: _key(uid));
    await _storage.delete(key: _key(uid), webOptions: _session);
    await _storage.delete(key: _key(uid), webOptions: _local);
  }
}
