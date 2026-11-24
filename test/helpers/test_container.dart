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
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/providers/auth_provider.dart';
import 'package:taskenda/models/share_member.dart';
import 'package:taskenda/providers/core_providers.dart';
import 'package:taskenda/providers/crypto_provider.dart';
import 'package:taskenda/providers/sharing_provider.dart';

import 'crypto.dart';

/// Points the data notifiers at [db] for user [uid], bypassing Firebase
/// Auth and the real Firestore instance. The documents are kept in clear
/// ([PlainItemCipher]) unless [encrypted]: then [itemCipherProvider] is the
/// real one, and the test must unlock keys (see `cryptoOverrides`).
List<Override> firestoreOverrides(
  FirebaseFirestore db, {
  String uid = 'test-uid',
  bool encrypted = false,
}) => [
  if (!encrypted)
    itemCipherProvider.overrideWithValue(
      uid.isEmpty ? null : const PlainItemCipher(),
    ),
  firestoreProvider.overrideWithValue(db),
  currentUidProvider.overrideWithValue(uid),
  currentShareMemberProvider.overrideWithValue(
    ShareMember(uid: uid, email: '$uid@example.com', name: uid),
  ),
];

/// A [ProviderContainer] using [firestoreOverrides], disposed at the end of
/// the test.
ProviderContainer createTestContainer(
  FirebaseFirestore db, {
  String uid = 'test-uid',
  bool encrypted = false,
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      ...firestoreOverrides(db, uid: uid, encrypted: encrypted),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}
