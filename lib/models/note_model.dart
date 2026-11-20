// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import 'audio_note.dart';
import 'sharing.dart';

enum NoteType { note, checklist }

class ChecklistItem {
  final String id;
  String text;
  bool isChecked;

  ChecklistItem({String? id, required this.text, this.isChecked = false})
    : id = id ?? const Uuid().v4();

  ChecklistItem copyWith({String? text, bool? isChecked}) {
    return ChecklistItem(
      id: id,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isChecked': isChecked,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'] as String?,
    text: json['text'] as String,
    isChecked: json['isChecked'] as bool? ?? false,
  );
}

class NoteStyle {
  final String fontFamily;
  final double fontSize;
  final Color? backgroundColor;
  final Color? fontColor;
  final bool isBold;
  final bool isItalic;
  final bool isStrikethrough;
  final Color? titleFontColor;
  final String? titleFontFamily;
  final double? titleFontSize;
  final bool? titleIsBold;
  final bool? titleIsItalic;

  const NoteStyle({
    this.fontFamily = 'Inter',
    this.fontSize = 16.0,
    this.backgroundColor,
    this.fontColor,
    this.isBold = false,
    this.isItalic = false,
    this.isStrikethrough = false,
    this.titleFontColor,
    this.titleFontFamily,
    this.titleFontSize,
    this.titleIsBold,
    this.titleIsItalic,
  });

  NoteStyle copyWith({
    String? fontFamily,
    double? fontSize,
    Color? backgroundColor,
    Color? fontColor,
    bool? isBold,
    bool? isItalic,
    bool? isStrikethrough,
    Color? titleFontColor,
    String? titleFontFamily,
    double? titleFontSize,
    bool? titleIsBold,
    bool? titleIsItalic,
    bool clearTitleFontColor = false,
    bool clearTitleFontFamily = false,
    bool clearTitleFontSize = false,
    bool clearTitleIsBold = false,
    bool clearTitleIsItalic = false,
  }) {
    return NoteStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontColor: fontColor ?? this.fontColor,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      titleFontColor:
          clearTitleFontColor ? null : (titleFontColor ?? this.titleFontColor),
      titleFontFamily:
          clearTitleFontFamily
              ? null
              : (titleFontFamily ?? this.titleFontFamily),
      titleFontSize:
          clearTitleFontSize ? null : (titleFontSize ?? this.titleFontSize),
      titleIsBold: clearTitleIsBold ? null : (titleIsBold ?? this.titleIsBold),
      titleIsItalic:
          clearTitleIsItalic ? null : (titleIsItalic ?? this.titleIsItalic),
    );
  }

  Map<String, dynamic> toJson() => {
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
    if (fontColor != null) 'fontColor': fontColor!.toARGB32(),
    'isBold': isBold,
    'isItalic': isItalic,
    'isStrikethrough': isStrikethrough,
    if (titleFontColor != null) 'titleFontColor': titleFontColor!.toARGB32(),
    if (titleFontFamily != null) 'titleFontFamily': titleFontFamily,
    if (titleFontSize != null) 'titleFontSize': titleFontSize,
    if (titleIsBold != null) 'titleIsBold': titleIsBold,
    if (titleIsItalic != null) 'titleIsItalic': titleIsItalic,
  };

  factory NoteStyle.fromJson(Map<String, dynamic> json) => NoteStyle(
    fontFamily: json['fontFamily'] as String? ?? 'Exo 2',
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
    backgroundColor:
        json['backgroundColor'] != null
            ? AppColors.fromStored(json['backgroundColor'] as int)
            : null,
    fontColor:
        json['fontColor'] != null
            ? AppColors.fromStored(json['fontColor'] as int)
            : null,
    isBold: json['isBold'] as bool? ?? false,
    isItalic: json['isItalic'] as bool? ?? false,
    isStrikethrough: json['isStrikethrough'] as bool? ?? false,
    titleFontColor:
        json['titleFontColor'] != null
            ? AppColors.fromStored(json['titleFontColor'] as int)
            : null,
    titleFontFamily: json['titleFontFamily'] as String?,
    titleFontSize: (json['titleFontSize'] as num?)?.toDouble(),
    titleIsBold: json['titleIsBold'] as bool?,
    titleIsItalic: json['titleIsItalic'] as bool?,
  );
}

class NoteModel with Shareable<NoteModel> {
  @override
  final String id;
  @override
  String title;
  String content;
  NoteType type;
  NoteStyle style;
  List<ChecklistItem> checklistItems;
  List<AudioNote> audioNotes;
  bool isArchived;
  bool isPinned;
  DateTime? reminder;
  List<String> linkedNoteIds;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;
  @override
  DateTime? deletedAt;

  /// Position in the custom order (lower comes first); personal, like the
  /// pin. Null for notes never placed (older notes, notes just shared with
  /// this user): those come first, newest first.
  int? sortIndex;

  /// Changed only through the sharing methods of `NotesNotifier`, never by
  /// [copyWith], and left out of [toJson] (so backups never carry it).
  @override
  final Sharing sharing;

  NoteModel({
    String? id,
    this.title = '',
    this.content = '',
    this.type = NoteType.note,
    NoteStyle? style,
    List<ChecklistItem>? checklistItems,
    List<AudioNote>? audioNotes,
    this.isArchived = false,
    this.isPinned = false,
    this.reminder,
    List<String>? linkedNoteIds,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.sortIndex,
    this.sharing = Sharing.none,
  }) : id = id ?? const Uuid().v4(),
       style = style ?? const NoteStyle(),
       checklistItems = checklistItems ?? [],
       audioNotes = audioNotes ?? [],
       linkedNoteIds = linkedNoteIds ?? [],
       tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  NoteModel copyWith({
    String? title,
    String? content,
    NoteType? type,
    NoteStyle? style,
    List<ChecklistItem>? checklistItems,
    List<AudioNote>? audioNotes,
    bool? isArchived,
    bool? isPinned,
    DateTime? reminder,
    bool clearReminder = false,
    List<String>? linkedNoteIds,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? sortIndex,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      style: style ?? this.style,
      checklistItems: checklistItems ?? this.checklistItems,
      audioNotes: audioNotes ?? this.audioNotes,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      reminder: clearReminder ? null : (reminder ?? this.reminder),
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      sortIndex: sortIndex ?? this.sortIndex,
      sharing: sharing,
    );
  }

  // ─── Sharing ──────────────────────────────────────────────────────────────

  @override
  NoteModel withSharing(Sharing sharing) => NoteModel(
    id: id,
    title: title,
    content: content,
    type: type,
    style: style,
    checklistItems: checklistItems,
    audioNotes: audioNotes,
    isArchived: isArchived,
    isPinned: isPinned,
    reminder: reminder,
    linkedNoteIds: linkedNoteIds,
    tags: tags,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    sortIndex: sortIndex,
    sharing: sharing,
  );

  /// Fields a collaborator may change on the owner's document: everything
  /// they see in common. Audio notes (local files) and links to other notes
  /// stay the owner's.
  static const sharedKeys = [
    'title',
    'content',
    'type',
    'style',
    'checklistItems',
    'updatedAt',
  ];

  @override
  List<String> get sharedContentKeys => sharedKeys;

  @override
  List<String> get optionalKeys => const ['reminder', 'deletedAt'];

  /// Per-user fields of a shared note: what a collaborator stores in their
  /// own `shared_note_prefs/{noteId}`, as pin, archive, reminder, labels and
  /// trash and custom order are personal (like in Keep).
  @override
  Map<String, dynamic> personalJson() => {
    'isPinned': isPinned,
    'isArchived': isArchived,
    if (reminder != null) 'reminder': reminder!.toIso8601String(),
    'tags': tags,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (sortIndex != null) 'sortIndex': sortIndex,
  };

  /// A note shared with the current user, as they see it: their [prefs]
  /// (see [personalJson]) replace the owner's personal fields, and the
  /// owner's audio notes and links are hidden.
  @override
  NoteModel asSharedWithMe(Map<String, dynamic>? prefs) {
    final p = prefs ?? const <String, dynamic>{};
    return NoteModel(
      id: id,
      title: title,
      content: content,
      type: type,
      style: style,
      checklistItems: checklistItems,
      isArchived: p['isArchived'] as bool? ?? false,
      isPinned: p['isPinned'] as bool? ?? false,
      reminder:
          p['reminder'] != null
              ? DateTime.parse(p['reminder'] as String)
              : null,
      tags: (p['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt:
          p['deletedAt'] != null
              ? DateTime.parse(p['deletedAt'] as String)
              : null,
      sortIndex: (p['sortIndex'] as num?)?.toInt(),
      sharing: sharing,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type.name,
    'style': style.toJson(),
    'checklistItems': checklistItems.map((e) => e.toJson()).toList(),
    'audioNotes': audioNotes.map((e) => e.toJson()).toList(),
    'isArchived': isArchived,
    'isPinned': isPinned,
    if (reminder != null) 'reminder': reminder!.toIso8601String(),
    'linkedNoteIds': linkedNoteIds,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (sortIndex != null) 'sortIndex': sortIndex,
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    type: NoteType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => NoteType.note,
    ),
    style:
        json['style'] != null
            ? NoteStyle.fromJson(json['style'] as Map<String, dynamic>)
            : const NoteStyle(),
    checklistItems:
        (json['checklistItems'] as List<dynamic>?)
            ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    audioNotes:
        (json['audioNotes'] as List<dynamic>?)
            ?.map((e) => AudioNote.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    isArchived: json['isArchived'] as bool? ?? false,
    isPinned: json['isPinned'] as bool? ?? false,
    reminder:
        json['reminder'] != null
            ? DateTime.parse(json['reminder'] as String)
            : null,
    linkedNoteIds:
        (json['linkedNoteIds'] as List<dynamic>?)?.cast<String>() ?? [],
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt:
        json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
    updatedAt:
        json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
    deletedAt:
        json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
    sortIndex: (json['sortIndex'] as num?)?.toInt(),
    sharing: Sharing.fromJson(json),
  );
}
