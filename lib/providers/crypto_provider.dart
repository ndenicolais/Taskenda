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
import '../core/crypto/passkey_client.dart';
import '../core/crypto/user_keys.dart';
import '../utils/device_key_storage.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'sharing_provider.dart';

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

/// The account has no keys yet: the user must create a passkey.
class CryptoNeedsSetup extends CryptoState {
  const CryptoNeedsSetup();
}

/// The account has keys, this device doesn't: the user must unlock them.
class CryptoLocked extends CryptoState {
  const CryptoLocked(this.bundle);

  final UserKeyBundle bundle;
}

/// The keys are unlocked. [pendingRecoveryKey] is a new recovery key (as
/// text) still to be shown to the user; [offerRecoveryKey] (right after
/// setup) proposes to create one.
class CryptoUnlocked extends CryptoState {
  const CryptoUnlocked(
    this.keys, {
    this.pendingRecoveryKey,
    this.offerRecoveryKey = false,
  });

  final UnlockedKeys keys;
  final String? pendingRecoveryKey;
  final bool offerRecoveryKey;
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

/// Whether this build has end-to-end encryption: `--dart-define=E2EE=true`.
/// Off by default until "Skip" lets who can't create a passkey use the
/// app without it (guides/E2EE_PLAN.md): an app without it keeps working
/// like before
/// (documents in clear, no unlock screen), compatible with the devices
/// still on the previous version.
const e2eeBuildFlag = bool.fromEnvironment('E2EE');

/// [e2eeBuildFlag], overridden by the tests.
final e2eeEnabledProvider = Provider<bool>((ref) => e2eeBuildFlag);

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final userKeyManagerProvider = Provider<UserKeyManager>(
  (ref) => UserKeyManager(ref.watch(cryptoServiceProvider)),
);

/// Tests override it with a fake passkey.
final passkeyClientProvider = Provider<PasskeyClient>((ref) => PasskeyClient());

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
  if (!ref.watch(e2eeEnabledProvider)) {
    return uid.isEmpty ? null : const ClearItemCipher();
  }
  final keys = ref.watch(unlockedKeysProvider);
  if (uid.isEmpty || keys == null) return null;
  return EncryptingItemCipher(
    uid: uid,
    keys: keys,
    codec: ItemCodec(ref.watch(cryptoServiceProvider)),
  );
});

/// The users' public keys (`public_keys/{uid}`), to seal item keys for
/// collaborators.
class PublicKeyDirectory {
  PublicKeyDirectory(this._ref);

  final Ref _ref;

  /// The public key of [uid], null if they haven't set up encryption.
  Future<Uint8List?> publicKeyOf(String uid) async {
    final snap =
        await _ref
            .read(firestoreProvider)
            .collection('public_keys')
            .doc(uid)
            .get();
    final pk = snap.data()?['pk'];
    if (pk is! String) return null;
    try {
      final bytes = base64Decode(pk);
      return bytes.length == CryptoService.keyLength ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  /// The public keys of [uids]; throws [MissingPublicKeyException] for the
  /// first one without.
  Future<Map<String, List<int>>> publicKeysOf(Iterable<String> uids) async {
    final result = <String, List<int>>{};
    for (final uid in uids) {
      final pk = await publicKeyOf(uid);
      if (pk == null) throw MissingPublicKeyException(uid);
      result[uid] = pk;
    }
    return result;
  }
}

final publicKeyDirectoryProvider = Provider<PublicKeyDirectory>(
  PublicKeyDirectory.new,
);

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
///   for the passkey again until sign-out.
class CryptoNotifier extends Notifier<CryptoState> {
  String _uid = '';

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  UserKeyManager get _manager => ref.read(userKeyManagerProvider);
  DeviceKeyStorage get _storage => ref.read(deviceKeyStorageProvider);
  PasskeyClient get _passkeys => ref.read(passkeyClientProvider);

  DocumentReference<Map<String, dynamic>> _bundleDoc(String uid) =>
      _db.collection('users').doc(uid).collection('crypto').doc('keys');

  DocumentReference<Map<String, dynamic>> _publicKeyDoc(String uid) =>
      _db.collection('public_keys').doc(uid);

  @override
  CryptoState build() {
    // Without end-to-end encryption no keys are looked up.
    if (!ref.watch(e2eeEnabledProvider)) return const CryptoSignedOut();
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

  /// A new passkey of the signed-in account, asked with [prfSalt].
  Future<PasskeySecret> _createPasskey(String uid, Uint8List prfSalt) {
    final me = ref.read(currentShareMemberProvider);
    final email = me?.email ?? '';
    final name = me?.name ?? '';
    final userName = email.isEmpty ? 'Taskenda' : email;
    return _passkeys.create(
      userId: uid,
      userName: userName,
      displayName: name.isEmpty ? userName : name,
      salt: prfSalt,
    );
  }

  /// Creates the account's keys, protected by a new passkey. Needs a
  /// connection: the server is asked first whether keys exist (so no
  /// passkey is created for nothing offline), then a transaction makes sure
  /// no other device created them meanwhile (if one did, the state becomes
  /// [CryptoLocked]). [remember] keeps the keys in `localStorage` on the
  /// web. Throws the [PasskeyClient] exceptions.
  Future<void> setup({bool remember = false}) async {
    final uid = _uid;
    final bundleDoc = _bundleDoc(uid);
    final current = await bundleDoc.get(
      const GetOptions(source: Source.server),
    );
    if (current.data() case final data?) {
      _set(uid, CryptoLocked(UserKeyBundle.fromJson(data)));
      return;
    }
    final prfSalt = _manager.newPrfSalt();
    final passkey = await _createPasskey(uid, prfSalt);
    final created = await _manager.create(
      uid,
      prfSalt: prfSalt,
      passkey: passkey,
    );
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
    _set(uid, CryptoUnlocked(created.keys, offerRecoveryKey: true));
  }

  /// Asks for one of [bundle]'s passkeys and opens the keys with it.
  /// Throws the [PasskeyClient] exceptions, [UnknownPasskeyException] for a
  /// passkey that doesn't protect these keys.
  Future<UnlockedKeys> _openWithPasskey(
    String uid,
    UserKeyBundle bundle,
  ) async {
    final prfSalt = bundle.prfSalt;
    if (prfSalt == null || !bundle.hasPasskey) {
      throw StateError('No passkey for this account');
    }
    final passkey = await _passkeys.get(
      salt: prfSalt,
      credentialIds: bundle.passkeysWrapped.keys.toList(),
    );
    return _manager.unlockWithPasskey(uid, bundle, passkey);
  }

  /// Unlocks with one of the account's passkeys (see [_openWithPasskey]).
  Future<void> unlockWithPasskey({bool remember = false}) async {
    final uid = _uid;
    final keys = await _openWithPasskey(uid, _lockedBundle());
    await _remember(uid, keys, persistent: remember);
    _set(uid, CryptoUnlocked(keys));
    unawaited(_publishPublicKey(uid, keys.publicKey));
  }

  /// Unlocks with the recovery key, then creates a new passkey that will
  /// unlock the keys from now on (the recovery key keeps working). Throws
  /// [InvalidRecoveryKeyException] for a malformed key, [CryptoException]
  /// for another account's, the [PasskeyClient] exceptions if the passkey
  /// isn't created (the keys stay locked).
  Future<void> recover(String recoveryKeyText, {bool remember = false}) async {
    final uid = _uid;
    final bundle = _lockedBundle();
    final recoveryKey = CryptoService.parseRecoveryKey(recoveryKeyText);
    if (recoveryKey == null) throw const InvalidRecoveryKeyException();
    final keys = await _manager.unlockWithRecoveryKey(uid, bundle, recoveryKey);
    final prfSalt = bundle.prfSalt ?? _manager.newPrfSalt();
    final passkey = await _createPasskey(uid, prfSalt);
    final updated = await _manager.withPasskey(
      uid,
      bundle,
      keys,
      prfSalt: prfSalt,
      passkey: passkey,
    );
    await _saveBundle(uid, updated);
    await _remember(uid, keys, persistent: remember);
    _set(uid, CryptoUnlocked(keys));
    unawaited(_publishPublicKey(uid, keys.publicKey));
  }

  /// The account's bundle read from the server: settings changes need a
  /// connection, so a new recovery key can't stay queued unseen.
  Future<UserKeyBundle> _serverBundle(String uid) async {
    final snap = await _bundleDoc(
      uid,
    ).get(const GetOptions(source: Source.server));
    final data = snap.data();
    if (data == null) throw StateError('No keys for this account');
    return UserKeyBundle.fromJson(data);
  }

  /// Saves [bundle] (merged, so `createdAt` stays), dropping the fields of
  /// a version 1 bundle.
  Future<void> _saveBundle(String uid, UserKeyBundle bundle) =>
      _bundleDoc(uid).set({
        ...bundle.toJson(),
        'kdf': FieldValue.delete(),
        'mk_pass': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Right after setup: creates the first recovery key and shows it
  /// ([CryptoUnlocked.pendingRecoveryKey]). Needs a connection.
  Future<void> createFirstRecoveryKey() async {
    final uid = _uid;
    final current = state;
    if (current is! CryptoUnlocked || !current.offerRecoveryKey) {
      throw StateError('No recovery key to offer');
    }
    final renewed = await _manager.withNewRecoveryKey(
      uid,
      await _serverBundle(uid),
      current.keys,
    );
    await _saveBundle(uid, renewed.bundle);
    _set(
      uid,
      CryptoUnlocked(
        current.keys,
        pendingRecoveryKey: CryptoService.formatRecoveryKey(
          renewed.recoveryKey,
        ),
      ),
    );
  }

  /// From the settings: the user confirms with their passkey, then the
  /// recovery key is replaced (the old one, if any, stops working) and the
  /// new one returned as text, to show to the user.
  Future<String> regenerateRecoveryKey() async {
    final uid = _uid;
    final bundle = await _serverBundle(uid);
    final keys = await _openWithPasskey(uid, bundle);
    final renewed = await _manager.withNewRecoveryKey(uid, bundle, keys);
    await _saveBundle(uid, renewed.bundle);
    return CryptoService.formatRecoveryKey(renewed.recoveryKey);
  }

  /// The user has saved the recovery key shown after setup, or chose to
  /// create it later.
  void acknowledgeRecoveryKey() {
    final current = state;
    if (current is CryptoUnlocked &&
        (current.pendingRecoveryKey != null || current.offerRecoveryKey)) {
      state = CryptoUnlocked(current.keys);
    }
  }

  /// For a user who lost both the passkey and the recovery key: deletes what
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
      // Still unlocked for this session; the passkey is asked again next
      // time.
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
