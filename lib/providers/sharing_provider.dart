// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_member.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

/// Profile of the signed-in user as stored on the items they share; null
/// when signed out. Tests override it.
final currentShareMemberProvider = Provider<ShareMember?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ShareMember(
    uid: user.uid,
    email: user.email ?? '',
    name: user.displayName ?? '',
  );
});

/// The `user_directory/{email}` collection: maps the (normalized) email of
/// every Taskenda user to their uid, so an item can be shared by email. The
/// security rules let anyone signed in read one entry by its exact email,
/// never list them, and only the owner write theirs.
class UserDirectory {
  UserDirectory(this._ref);

  final Ref _ref;

  CollectionReference<Map<String, dynamic>> get _col =>
      _ref.read(firestoreProvider).collection('user_directory');

  /// Creates or refreshes the entry of [me] (run after each sign-in).
  Future<void> register(ShareMember me) async {
    final email = normalizeEmail(me.email);
    if (email.isEmpty) return;
    await _col.doc(email).set({'uid': me.uid, 'email': email, 'name': me.name});
  }

  /// The user signed up with [email], or null if nobody uses Taskenda with it.
  Future<ShareMember?> lookup(String email) async {
    final key = normalizeEmail(email);
    if (key.isEmpty) return null;
    final snap = await _col.doc(key).get();
    final data = snap.data();
    final uid = data?['uid'] as String?;
    if (uid == null || uid.isEmpty) return null;
    return ShareMember(
      uid: uid,
      email: data!['email'] as String? ?? key,
      name: data['name'] as String? ?? '',
    );
  }

  /// Removes the entry of [me] (account deletion).
  Future<void> unregister(ShareMember me) async {
    final email = normalizeEmail(me.email);
    if (email.isEmpty) return;
    await _col.doc(email).delete();
  }
}

final userDirectoryProvider = Provider<UserDirectory>(UserDirectory.new);

/// Why [UserDirectory.lookup]-based sharing refused an email.
/// [noEncryption]: the user exists but has no public key yet (they haven't
/// set up end-to-end encryption), so nothing can be shared with them.
enum ShareError { notFound, self, alreadyAdded, noEncryption }

/// Thrown by the sharing methods of the data notifiers.
class ShareException implements Exception {
  const ShareException(this.error);

  final ShareError error;

  @override
  String toString() => 'ShareException($error)';
}
