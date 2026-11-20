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
import 'share_member.dart';

/// Who an item (note, task or event) is shared with.
///
/// Stored on the item's document, never in `toJson()` (so backups and
/// exports don't carry it): `ownerId`, `owner` (`{email, name}`),
/// `collaborators` (uids, for the collection-group query and the security
/// rules) and `collaboratorProfiles` (uid → `{email, name}`, for display).
@immutable
class Sharing {
  const Sharing({this.ownerId, this.owner, this.collaborators = const []});

  /// An item that was never shared: the signed-in user's own.
  static const none = Sharing();

  /// Uid of the user whose `users/{uid}/<collection>` holds the item; set the
  /// first time it is shared.
  final String? ownerId;

  /// Profile of [ownerId], shown to collaborators.
  final ShareMember? owner;

  /// Users the owner shared the item with.
  final List<ShareMember> collaborators;

  factory Sharing.fromJson(Map<String, dynamic> json) {
    final ownerId = json['ownerId'] as String?;
    final owner = json['owner'];
    final uids = (json['collaborators'] as List<dynamic>?)?.cast<String>();
    final profiles = json['collaboratorProfiles'];
    if (ownerId == null && (uids == null || uids.isEmpty)) return none;
    return Sharing(
      ownerId: ownerId,
      owner:
          ownerId != null && owner is Map
              ? ShareMember.fromProfileJson(
                ownerId,
                Map<String, dynamic>.from(owner),
              )
              : null,
      collaborators: List.unmodifiable([
        for (final uid in uids ?? const <String>[])
          profiles is Map && profiles[uid] is Map
              ? ShareMember.fromProfileJson(
                uid,
                Map<String, dynamic>.from(profiles[uid] as Map),
              )
              : ShareMember(uid: uid, email: ''),
      ]),
    );
  }
}

/// An item that can be shared with other users. The owner keeps it in their
/// collection; collaborators may change only [sharedContentKeys] there, and
/// keep the rest (pin, archive, labels, trash…) in their own
/// `shared_<kind>_prefs` (see [personalJson]).
mixin Shareable<T extends Shareable<T>> {
  String get id;
  String get title;
  DateTime? get deletedAt;
  Sharing get sharing;
  Map<String, dynamic> toJson();

  /// Fields collaborators see and change in common.
  List<String> get sharedContentKeys;

  /// [toJson] keys omitted when null: deleted from the document when the
  /// item is updated instead of overwritten.
  List<String> get optionalKeys;

  /// Per-user fields, as a collaborator stores them in their prefs.
  Map<String, dynamic> personalJson();

  /// The item shared with the current user as they see it: their [prefs]
  /// (see [personalJson]) replace the owner's personal fields.
  T asSharedWithMe(Map<String, dynamic>? prefs);

  /// This item with [sharing] instead of its own.
  T withSharing(Sharing sharing);

  String? get ownerId => sharing.ownerId;
  ShareMember? get owner => sharing.owner;
  List<ShareMember> get collaborators => sharing.collaborators;

  /// True once the owner added at least one collaborator.
  bool get isShared => collaborators.isNotEmpty;

  /// True if this item belongs to another user and was shared with [uid].
  bool isForeignTo(String uid) => ownerId != null && ownerId != uid;

  /// Everyone on the item except [uid]: the owner (when it is not [uid])
  /// and the other collaborators.
  List<ShareMember> membersExcept(String uid) => [
    if (isForeignTo(uid) && owner != null) owner!,
    for (final c in collaborators)
      if (c.uid != uid) c,
  ];

  /// This item with the sharing of [other] (the same item, as known by the
  /// provider), so an edit made on a stale copy can't drop it.
  T withSharingOf(T other) => withSharing(other.sharing);

  /// The [sharedContentKeys] part of [toJson]; an absent optional field is
  /// null (to be deleted on the owner's document).
  Map<String, dynamic> sharedContentJson() {
    final json = toJson();
    return {for (final k in sharedContentKeys) k: json[k]};
  }
}
