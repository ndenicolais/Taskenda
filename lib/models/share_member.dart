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

/// A Taskenda user an item is shared with (or its owner), as stored on the
/// shared item so every member can show who is on it without extra reads.
@immutable
class ShareMember {
  const ShareMember({required this.uid, required this.email, this.name = ''});

  final String uid;
  final String email;
  final String name;

  /// [name] when known, otherwise [email].
  String get label => name.trim().isNotEmpty ? name.trim() : email;

  /// Profile fields only: the uid is the key of the map they are stored in.
  Map<String, dynamic> toProfileJson() => {'email': email, 'name': name};

  factory ShareMember.fromProfileJson(String uid, Map<String, dynamic> json) =>
      ShareMember(
        uid: uid,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is ShareMember &&
      other.uid == uid &&
      other.email == email &&
      other.name == name;

  @override
  int get hashCode => Object.hash(uid, email, name);
}

/// Normalized form of [email] used as the user-directory key.
String normalizeEmail(String email) => email.trim().toLowerCase();
