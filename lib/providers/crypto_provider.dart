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
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crypto/crypto_service.dart';
import '../core/crypto/item_cipher.dart';
import '../core/crypto/item_codec.dart';
import '../core/crypto/user_keys.dart';
import '../utils/device_key_storage.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

/// Where the signed-in user is with end-to-end encryption.
sealed class CryptoState {
  const CryptoState();
}

/// Nobody is signed in.
class CryptoSignedOut extends CryptoState {
  const CryptoSignedOut();
}

/// Looking for the keys on the device and in Firestore.
class CryptoChecking extends CryptoState {
  const CryptoChecking();
}

/// The account has no keys yet: the user must pick an encryption code.
class CryptoNeedsSetup extends CryptoState {
  const CryptoNeedsSetup();
}

/// The account has keys, this device doesn't: the user must unlock them.
class CryptoLocked extends CryptoState {
  const CryptoLocked(this.bundle);

  final UserKeyBundle bundle;
}

/// The keys are unlocked. [pendingRecoveryKey] is a new recovery key (as
/// text) still to be shown to the user.
class CryptoUnlocked extends CryptoState {
  const CryptoUnlocked(this.keys, {this.pendingRecoveryKey});

  final UnlockedKeys keys;
  final String? pendingRecoveryKey;
}

/// The keys couldn't be looked up (typically offline on the first start
/// on this device): [CryptoNotifier.retry].
class CryptoLoadFailed extends CryptoState {
  const CryptoLoadFailed(this.error);

  final Object error;
}

/// The recovery key typed by the user isn't a well-formed key.
class InvalidRecoveryKeyException implements Exception {
  const InvalidRecoveryKeyException();
}

/// Firestore answered from the cache only, so it can't tell whether the
/// account has keys: setting up new ones could hide the real ones.
class CryptoOfflineException implements Exception {
  const CryptoOfflineException();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

/// Tests override it with fewer PBKDF2 iterations.
final userKeyManagerProvider = Provider<UserKeyManager>(
  (ref) => UserKeyManager(ref.watch(cryptoServiceProvider)),
);

/// Tests override it with an in-memory storage.
final deviceKeyStorageProvider = Provider<DeviceKeyStorage>(
  (ref) => DeviceKeyStorage(),
);

final cryptoProvider = NotifierProvider<CryptoNotifier, CryptoState>(
  CryptoNotifier.new,
);

/// The unlocked keys, or null while locked or signed out.
final unlockedKeysProvider = Provider<UnlockedKeys?>((ref) {
  final state = ref.watch(cryptoProvider);
  return state is CryptoUnlocked ? state.keys : null;
});

/// How the data notifiers encrypt and decrypt their documents; null while
/// the keys are locked or nobody is signed in, and the notifiers don't load
/// anything meanwhile. Tests override it with a cipher that keeps the
/// documents in clear.
final itemCipherProvider = Provider<ItemCipher?>((ref) {
  final uid = ref.watch(currentUidProvider);
  final keys = ref.watch(unlockedKeysProvider);
  if (uid.isEmpty || keys == null) return null;
  return EncryptingItemCipher(
    uid: uid,
    keys: keys,
    codec: ItemCodec(ref.watch(cryptoServiceProvider)),
  );
});

/// The collections under `users/{uid}/` whose documents are encrypted.
const encryptedCollections = [
  'notes',
  'tasks',
  'calendar_events',
  'labels',
  'task_lists',
];

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// The signed-in user's keys (see `guides/E2EE_PLAN.md` §6):
///
/// - `users/{uid}/crypto/keys`: the [UserKeyBundle], readable only by them;
/// - `public_keys/{uid}`: their public key, readable by every signed-in
///   user so items can be shared with them;
/// - the unlocked keys in [DeviceKeyStorage], so this device doesn't ask
///   for the code again until sign-out.
class CryptoNotifier extends Notifier<CryptoState> {
  String _uid = '';

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  UserKeyManager get _manager => ref.read(userKeyManagerProvider);
  DeviceKeyStorage get _storage => ref.read(deviceKeyStorageProvider);

  DocumentReference<Map<String, dynamic>> _bundleDoc(String uid) =>
      _db.collection('users').doc(uid).collection('crypto').doc('keys');

  DocumentReference<Map<String, dynamic>> _publicKeyDoc(String uid) =>
      _db.collection('public_keys').doc(uid);

  @override
  CryptoState build() {
    final uid = ref.watch(currentUidProvider);
    _uid = uid;
    if (uid.isEmpty) return const CryptoSignedOut();
    Future.microtask(() => _load(uid));
    return const CryptoChecking();
  }

  /// Sets [next] unless the user changed meanwhile.
  void _set(String uid, CryptoState next) {
    if (uid == _uid) state = next;
  }

  Future<void> _load(String uid) async {
    try {
      final stored = await _storage.read(uid);
      if (stored != null) {
        try {
          final keys = await _manager.importFromDevice(stored);
          _set(uid, CryptoUnlocked(keys));
          unawaited(_checkStoredKeys(uid, keys));
          return;
        } on CryptoException {
          await _storage.delete(uid);
        }
      }
      final bundle = await _fetchBundle(uid);
      _set(
        uid,
        bundle == null ? const CryptoNeedsSetup() : CryptoLocked(bundle),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Encryption keys not loaded: $e');
      _set(uid, CryptoLoadFailed(e));
    }
  }

  /// The account's bundle, null if it has none. Throws
  /// [CryptoOfflineException] when only the cache answered "none".
  Future<UserKeyBundle?> _fetchBundle(String uid) async {
    final snap = await _bundleDoc(uid).get();
    final data = snap.data();
    if (data == null) {
      if (snap.metadata.isFromCache) throw const CryptoOfflineException();
      return null;
    }
    return UserKeyBundle.fromJson(data);
  }

  /// The keys saved on this device may be stale (encryption reset from
  /// another device): if the account's public key is not theirs any more,
  /// forget them. Best effort, in the background.
  Future<void> _checkStoredKeys(String uid, UnlockedKeys keys) async {
    try {
      final bundle = await _fetchBundle(uid);
      if (bundle != null && listEquals(bundle.publicKey, keys.publicKey)) {
        return;
      }
      await _storage.delete(uid);
      _set(
        uid,
        bundle == null ? const CryptoNeedsSetup() : CryptoLocked(bundle),
      );
    } catch (_) {
      // Offline: checked again at the next start.
    }
  }

  Future<void> retry() async {
    final uid = _uid;
    if (uid.isEmpty) return;
    state = const CryptoChecking();
    await _load(uid);
  }

  /// Creates the account's keys, protected by [passphrase]. Needs a
  /// connection: a transaction makes sure no other device created them
  /// meanwhile (if one did, the state becomes [CryptoLocked]). [remember]
  /// keeps the keys in `localStorage` on the web.
  Future<void> setup(String passphrase, {bool remember = false}) async {
    final uid = _uid;
    final created = await _manager.create(uid, passphrase);
    final bundleDoc = _bundleDoc(uid);
    final existing = await _db.runTransaction<Map<String, dynamic>?>((
      tx,
    ) async {
      final snap = await tx.get(bundleDoc);
      if (snap.exists) return snap.data();
      tx.set(bundleDoc, {
        ...created.bundle.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(_publicKeyDoc(uid), _publicKeyData(created.keys.publicKey));
      return null;
    });
    if (existing != null) {
      _set(uid, CryptoLocked(UserKeyBundle.fromJson(existing)));
      return;
    }
    await _remember(uid, created.keys, persistent: remember);
    _set(
      uid,
      CryptoUnlocked(
        created.keys,
        pendingRecoveryKey: CryptoService.formatRecoveryKey(
          created.recoveryKey,
        ),
      ),
    );
  }

  /// Unlocks with the encryption code; throws [CryptoException] if it is
  /// wrong.
  Future<void> unlock(String passphrase, {bool remember = false}) async {
    final uid = _uid;
    final bundle = _lockedBundle();
    final keys = await _manager.unlockWithPassphrase(uid, bundle, passphrase);
    await _remember(uid, keys, persistent: remember);
    _set(uid, CryptoUnlocked(keys));
    unawaited(_publishPublicKey(uid, keys.publicKey));
  }

  /// Unlocks with the recovery key, then protects the keys with
  /// [newPassphrase] and a new recovery key (shown next). Throws
  /// [InvalidRecoveryKeyException] for a malformed key, [CryptoException]
  /// for another account's.
  Future<void> recover(
    String recoveryKeyText,
    String newPassphrase, {
    bool remember = false,
  }) async {
    final uid = _uid;
    final bundle = _lockedBundle();
    final recoveryKey = CryptoService.parseRecoveryKey(recoveryKeyText);
    if (recoveryKey == null) throw const InvalidRecoveryKeyException();
    final keys = await _manager.unlockWithRecoveryKey(uid, bundle, recoveryKey);
    final withPassphrase = await _manager.withPassphrase(
      uid,
      bundle,
      keys,
      newPassphrase,
    );
    final renewed = await _manager.withNewRecoveryKey(
      uid,
      withPassphrase,
      keys,
    );
    await _bundleDoc(uid).set({
      ...renewed.bundle.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _remember(uid, keys, persistent: remember);
    _set(
      uid,
      CryptoUnlocked(
        keys,
        pendingRecoveryKey: CryptoService.formatRecoveryKey(
          renewed.recoveryKey,
        ),
      ),
    );
    unawaited(_publishPublicKey(uid, keys.publicKey));
  }

  /// The user has saved the recovery key shown after setup or recovery.
  void acknowledgeRecoveryKey() {
    final current = state;
    if (current is CryptoUnlocked && current.pendingRecoveryKey != null) {
      state = CryptoUnlocked(current.keys);
    }
  }

  /// For a user who lost both the code and the recovery key: deletes what
  /// was encrypted with the old keys (it can't be read any more), then the
  /// keys, so new ones can be created. Items still in clear (shared ones)
  /// are kept. Needs a connection.
  Future<void> reset() async {
    final uid = _uid;
    final refs = <DocumentReference>[];
    for (final name in encryptedCollections) {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection(name)
          .where(ItemCodec.versionField, isEqualTo: ItemCodec.schemaVersion)
          .get(const GetOptions(source: Source.server));
      refs.addAll(snap.docs.map((d) => d.reference));
    }
    refs
      ..add(_bundleDoc(uid))
      ..add(_publicKeyDoc(uid));
    for (var i = 0; i < refs.length; i += 500) {
      final batch = _db.batch();
      for (final r in refs.skip(i).take(500)) {
        batch.delete(r);
      }
      await batch.commit();
    }
    await _storage.delete(uid);
    _set(uid, const CryptoNeedsSetup());
  }

  /// Removes the keys from this device (sign-out, account deletion).
  Future<void> forget() async {
    final uid = _uid;
    if (uid.isEmpty) return;
    try {
      await _storage.delete(uid);
    } catch (e) {
      if (kDebugMode) debugPrint('Stored keys not deleted: $e');
    }
  }

  UserKeyBundle _lockedBundle() {
    final current = state;
    if (current is! CryptoLocked) throw StateError('Keys are not locked');
    return current.bundle;
  }

  Future<void> _remember(
    String uid,
    UnlockedKeys keys, {
    required bool persistent,
  }) async {
    try {
      await _storage.write(
        uid,
        await _manager.exportForDevice(keys),
        persistent: persistent,
      );
    } catch (e) {
      // Still unlocked for this session; the code is asked again next time.
      if (kDebugMode) debugPrint('Keys not saved on the device: $e');
    }
  }

  static Map<String, dynamic> _publicKeyData(Uint8List publicKey) => {
    'pk': base64Encode(publicKey),
    'v': UserKeyBundle.version,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Rewrites `public_keys/{uid}`, in case an earlier write was lost.
  Future<void> _publishPublicKey(String uid, Uint8List publicKey) async {
    try {
      await _publicKeyDoc(uid).set(_publicKeyData(publicKey));
    } catch (e) {
      if (kDebugMode) debugPrint('Public key not published: $e');
    }
  }
}
