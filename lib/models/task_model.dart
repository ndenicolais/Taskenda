// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:uuid/uuid.dart';
import '../utils/recurrence.dart';
import 'sharing.dart';
import 'subtask_model.dart';

class TaskModel with Shareable<TaskModel> {
  @override
  final String id;
  @override
  String title;
  String description;
  bool isCompleted;
  DateTime? dueDate;
  bool isPinned;
  bool isSpecial;
  bool isArchived;
  String? listId;
  RecurrenceType recurrence;
  // Days left out of the recurrence (date only): occurrences after the
  // current one deleted on their own from the calendar.
  List<DateTime> recurrenceExceptions;
  List<String> tags;
  List<SubtaskModel> subtasks;
  final DateTime createdAt;
  DateTime updatedAt;
  @override
  DateTime? deletedAt;

  /// Changed only through the sharing methods of `TasksNotifier`, never by
  /// [copyWith], and left out of [toJson] (so backups never carry it).
  @override
  final Sharing sharing;

  TaskModel({
    String? id,
    this.title = '',
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
    this.isPinned = false,
    this.isSpecial = false,
    this.isArchived = false,
    this.listId,
    this.recurrence = RecurrenceType.none,
    List<DateTime>? recurrenceExceptions,
    List<String>? tags,
    List<SubtaskModel>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.sharing = Sharing.none,
  }) : id = id ?? const Uuid().v4(),
       recurrenceExceptions = recurrenceExceptions ?? [],
       tags = tags ?? [],
       subtasks = subtasks ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Whether [dueDate] carries a time of day; the date picker stores
  /// midnight when no time is picked. A due time is also when the task
  /// notifies (see `NotificationService.scheduleTaskReminder`).
  bool get hasDueTime =>
      dueDate != null && (dueDate!.hour != 0 || dueDate!.minute != 0);

  /// Whether this task repeats on a schedule (a recurrence needs a due date
  /// to step from).
  bool get isRecurring => recurrence != RecurrenceType.none && dueDate != null;

  bool _isException(DateTime d) => recurrenceExceptions.any(
    (e) => e.year == d.year && e.month == d.month && e.day == d.day,
  );

  /// This task moved on to its next occurrence: the due date steps forward
  /// by one recurrence (past the days left out) and the task is open again.
  /// Exceptions before the new due date are dropped.
  TaskModel nextOccurrence() {
    var next = nextRecurrence(dueDate!, recurrence);
    for (var i = 0; i < 1000 && _isException(next); i++) {
      next = nextRecurrence(next, recurrence);
    }
    final nextDay = DateTime(next.year, next.month, next.day);
    return copyWith(
      dueDate: next,
      recurrenceExceptions:
          recurrenceExceptions.where((e) => e.isAfter(nextDay)).toList(),
      isCompleted: false,
      updatedAt: DateTime.now(),
    );
  }

  /// The recurring task without its occurrence on [day]: the current one
  /// moves the task on to the next occurrence, a later one is left out.
  TaskModel withoutOccurrence(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    if (!d.isAfter(due)) return nextOccurrence();
    if (_isException(d)) return this;
    return copyWith(
      recurrenceExceptions: [...recurrenceExceptions, d]..sort(),
      updatedAt: DateTime.now(),
    );
  }

  /// A new, non-recurring copy of this task (another id, not shared): an
  /// occurrence edited on its own, split off the series.
  TaskModel asStandaloneCopy() {
    final now = DateTime.now().toIso8601String();
    return TaskModel.fromJson({
      ...toJson(),
      'id': const Uuid().v4(),
      'createdAt': now,
      'updatedAt': now,
    }).copyWith(recurrence: RecurrenceType.none, recurrenceExceptions: []);
  }

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isPinned,
    bool? isSpecial,
    bool? isArchived,
    String? listId,
    bool clearListId = false,
    RecurrenceType? recurrence,
    List<DateTime>? recurrenceExceptions,
    List<String>? tags,
    List<SubtaskModel>? subtasks,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isPinned: isPinned ?? this.isPinned,
      isSpecial: isSpecial ?? this.isSpecial,
      isArchived: isArchived ?? this.isArchived,
      listId: clearListId ? null : (listId ?? this.listId),
      recurrence: recurrence ?? this.recurrence,
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      sharing: sharing,
    );
  }

  // ─── Sharing ──────────────────────────────────────────────────────────────

  @override
  TaskModel withSharing(Sharing sharing) => TaskModel(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted,
    dueDate: dueDate,
    isPinned: isPinned,
    isSpecial: isSpecial,
    isArchived: isArchived,
    listId: listId,
    recurrence: recurrence,
    recurrenceExceptions: recurrenceExceptions,
    tags: tags,
    subtasks: subtasks,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    sharing: sharing,
  );

  /// Fields a collaborator may change on the owner's document. Pin, star,
  /// archive, list, labels and trash stay personal.
  static const sharedKeys = [
    'title',
    'description',
    'isCompleted',
    'dueDate',
    'recurrence',
    'recurrenceExceptions',
    'subtasks',
    'updatedAt',
  ];

  @override
  List<String> get sharedContentKeys => sharedKeys;

  @override
  List<String> get optionalKeys => const [
    'dueDate',
    'listId',
    'recurrenceExceptions',
    'deletedAt',
  ];

  /// Per-user fields, stored by a collaborator in `shared_task_prefs`.
  @override
  Map<String, dynamic> personalJson() => {
    'isPinned': isPinned,
    'isSpecial': isSpecial,
    'isArchived': isArchived,
    if (listId != null) 'listId': listId,
    'tags': tags,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  @override
  TaskModel asSharedWithMe(Map<String, dynamic>? prefs) {
    final p = prefs ?? const <String, dynamic>{};
    return TaskModel(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      dueDate: dueDate,
      isPinned: p['isPinned'] as bool? ?? false,
      isSpecial: p['isSpecial'] as bool? ?? false,
      isArchived: p['isArchived'] as bool? ?? false,
      listId: p['listId'] as String?,
      recurrence: recurrence,
      recurrenceExceptions: recurrenceExceptions,
      tags: (p['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      subtasks: subtasks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt:
          p['deletedAt'] != null
              ? DateTime.parse(p['deletedAt'] as String)
              : null,
      sharing: sharing,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    'isPinned': isPinned,
    'isSpecial': isSpecial,
    'isArchived': isArchived,
    if (listId != null) 'listId': listId,
    'recurrence': recurrence.toShortString(),
    if (recurrenceExceptions.isNotEmpty)
      'recurrenceExceptions': [
        for (final d in recurrenceExceptions) dateOnlyKey(d),
      ],
    'tags': tags,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  /// The due date of [json]. Older data had a separate `reminder`: when
  /// there is no due date, or a date-only one on the reminder's day, the
  /// reminder becomes the due date, so the task keeps its day and time.
  static DateTime? _dueDateFromJson(Map<String, dynamic> json) {
    final due =
        json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null;
    final reminder =
        json['reminder'] != null
            ? DateTime.parse(json['reminder'] as String)
            : null;
    if (reminder == null) return due;
    if (due == null) return reminder;
    final dateOnly = due.hour == 0 && due.minute == 0;
    final sameDay =
        due.year == reminder.year &&
        due.month == reminder.month &&
        due.day == reminder.day;
    return dateOnly && sameDay ? reminder : due;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
    dueDate: _dueDateFromJson(json),
    isPinned: json['isPinned'] as bool? ?? false,
    isSpecial: json['isSpecial'] as bool? ?? false,
    isArchived: json['isArchived'] as bool? ?? false,
    listId: json['listId'] as String?,
    recurrence: recurrenceTypeFromString(
      json['recurrence'] as String? ?? 'none',
    ),
    recurrenceExceptions:
        (json['recurrenceExceptions'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList(),
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [],
    subtasks:
        (json['subtasks'] as List<dynamic>?)
            ?.map((e) => SubtaskModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    deletedAt:
        json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
    sharing: Sharing.fromJson(json),
  );
}
