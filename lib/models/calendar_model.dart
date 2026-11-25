// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/painting.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import '../utils/event_alerts.dart';
import '../utils/italian_holidays.dart';
import '../utils/recurrence.dart';
import 'sharing.dart';
import 'task_model.dart';

class CalendarEventModel with Shareable<CalendarEventModel> {
  @override
  final String id;
  @override
  String title;
  String description;
  // Free-text place (address or name), opened in the maps app from the
  // event view. Empty when not set.
  String location;
  // Card fill chosen by the user; null keeps the color of the event kind
  // (see `calendarItemStyle`). A note swatch is shown as its counterpart
  // in the other theme.
  Color? color;
  DateTime startTime;
  // Equal to [startTime] for a timed event with a single time (no end).
  DateTime endTime;
  bool isAllDay;
  bool isBirthday;
  bool isNameDay;
  bool isPinned;
  bool isArchived;
  RecurrenceType recurrence;
  // If set, the recurrence stops producing occurrences after this date
  // (inclusive) — e.g. an imported ICS RRULE with UNTIL= or COUNT=.
  DateTime? recurrenceEndDate;
  // Repeats every [recurrenceInterval] days/weeks/months/years (1 = every).
  int recurrenceInterval;
  // Weekly only: the days of the week it falls on (DateTime.monday = 1 …
  // DateTime.sunday = 7), sorted; empty = the weekday of [startTime].
  List<int> recurrenceWeekdays;
  // Monthly only: null repeats on the day of the month of [startTime];
  // 1–5 on that week of the month (e.g. 2 = the second Tuesday when it
  // starts on a Tuesday), -1 on the last one.
  int? recurrenceMonthWeek;
  // Days left out of the recurrence (date only), e.g. an occurrence deleted
  // on its own, or moved / cancelled in the calendar it was imported from.
  List<DateTime> recurrenceExceptions;
  // Alerts of all-day events, repeated on every occurrence: on the day
  // itself and/or the day before, at the Settings time (09:00 by default).
  // Timed events use [alertMinutesBefore] instead. See
  // `utils/event_alerts.dart`.
  bool alertSameDay;
  bool alertDayBefore;
  // Timed events: minutes before the start of each occurrence the alert
  // fires (0 = at the start), or [noEventAlert] for none. Ignored by
  // all-day events.
  int alertMinutesBefore;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;
  @override
  DateTime? deletedAt;

  /// Changed only through the sharing methods of `CalendarNotifier`, never
  /// by [copyWith], and left out of [toJson] (so backups never carry it).
  @override
  final Sharing sharing;

  CalendarEventModel({
    String? id,
    this.title = '',
    this.description = '',
    this.location = '',
    this.color,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.isBirthday = false,
    this.isNameDay = false,
    this.isPinned = false,
    this.isArchived = false,
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.recurrenceInterval = 1,
    List<int>? recurrenceWeekdays,
    this.recurrenceMonthWeek,
    List<DateTime>? recurrenceExceptions,
    this.alertSameDay = false,
    this.alertDayBefore = false,
    this.alertMinutesBefore = 0,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.sharing = Sharing.none,
  }) : id = id ?? const Uuid().v4(),
       recurrenceWeekdays = recurrenceWeekdays ?? [],
       recurrenceExceptions = recurrenceExceptions ?? [],
       tags = tags ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get hasEndTime => !isAllDay && endTime.isAfter(startTime);

  /// Whether an occurrence alerts: a timed event unless its alert is
  /// [noEventAlert], an all-day one on its day only when chosen.
  bool get notifiesSameDay =>
      isAllDay ? alertSameDay : alertMinutesBefore != noEventAlert;

  /// Whether an occurrence alerts the day before (all-day events only).
  bool get notifiesDayBefore => isAllDay && alertDayBefore;

  bool get hasAlerts => notifiesSameDay || notifiesDayBefore;

  /// Whether an occurrence of this event (recurrence, its end and its
  /// exceptions included) falls on [day].
  bool occursOn(DateTime day) => recurrenceOccursOn(
    start: startTime,
    day: day,
    type: recurrence,
    interval: recurrenceInterval,
    weekdays: recurrenceWeekdays,
    monthWeek: recurrenceMonthWeek,
    endDate: recurrenceEndDate,
    exceptions: recurrenceExceptions,
  );

  /// Whether the recurrence goes beyond the simple "every day / week /
  /// month / year" (an interval, chosen weekdays or a week of the month).
  bool get hasCustomRecurrence =>
      recurrence != RecurrenceType.none &&
      (recurrenceInterval > 1 ||
          (recurrence == RecurrenceType.weekly &&
              recurrenceWeekdays.isNotEmpty &&
              !(recurrenceWeekdays.length == 1 &&
                  recurrenceWeekdays.first == startTime.weekday)) ||
          (recurrence == RecurrenceType.monthly &&
              recurrenceMonthWeek != null));

  /// The day of the [count]th occurrence of the series (excluded dates are
  /// counted too, as RFC 5545 does with COUNT), for an "ends after N times"
  /// recurrence. Gives up after 100 years.
  DateTime dayOfOccurrence(int count) {
    final s = startTime;
    final series = copyWith(recurrenceExceptions: const []);
    var found = 0;
    var day = DateTime(s.year, s.month, s.day);
    for (var i = 0; i < 36600; i++) {
      day = DateTime(s.year, s.month, s.day + i);
      if (series.occursOn(day) && ++found >= count) break;
    }
    return day;
  }

  /// This event without the occurrence on [day] (the rest of the series
  /// stays).
  CalendarEventModel withoutOccurrence(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (recurrenceExceptions.contains(d)) return this;
    return copyWith(
      recurrenceExceptions: [...recurrenceExceptions, d]..sort(),
      updatedAt: DateTime.now(),
    );
  }

  /// A new, non-recurring copy of this event (another id, not shared): an
  /// occurrence edited on its own, split off the series.
  CalendarEventModel asStandaloneCopy() {
    final now = DateTime.now().toIso8601String();
    return CalendarEventModel.fromJson({
      ...toJson(),
      'id': const Uuid().v4(),
      'createdAt': now,
      'updatedAt': now,
    }).copyWith(
      recurrence: RecurrenceType.none,
      clearRecurrenceEndDate: true,
      recurrenceInterval: 1,
      recurrenceWeekdays: [],
      clearRecurrenceMonthWeek: true,
      recurrenceExceptions: [],
    );
  }

  CalendarEventModel copyWith({
    String? title,
    String? description,
    String? location,
    Color? color,
    bool clearColor = false,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    bool? isBirthday,
    bool? isNameDay,
    bool? isPinned,
    bool? isArchived,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    int? recurrenceInterval,
    List<int>? recurrenceWeekdays,
    int? recurrenceMonthWeek,
    bool clearRecurrenceMonthWeek = false,
    List<DateTime>? recurrenceExceptions,
    bool? alertSameDay,
    bool? alertDayBefore,
    int? alertMinutesBefore,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return CalendarEventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      color: clearColor ? null : (color ?? this.color),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isBirthday: isBirthday ?? this.isBirthday,
      isNameDay: isNameDay ?? this.isNameDay,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate:
          clearRecurrenceEndDate
              ? null
              : (recurrenceEndDate ?? this.recurrenceEndDate),
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      recurrenceMonthWeek:
          clearRecurrenceMonthWeek
              ? null
              : (recurrenceMonthWeek ?? this.recurrenceMonthWeek),
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
      alertSameDay: alertSameDay ?? this.alertSameDay,
      alertDayBefore: alertDayBefore ?? this.alertDayBefore,
      alertMinutesBefore: alertMinutesBefore ?? this.alertMinutesBefore,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      sharing: sharing,
    );
  }

  // ─── Sharing ──────────────────────────────────────────────────────────────

  @override
  CalendarEventModel withSharing(Sharing sharing) => CalendarEventModel(
    id: id,
    title: title,
    description: description,
    location: location,
    color: color,
    startTime: startTime,
    endTime: endTime,
    isAllDay: isAllDay,
    isBirthday: isBirthday,
    isNameDay: isNameDay,
    isPinned: isPinned,
    isArchived: isArchived,
    recurrence: recurrence,
    recurrenceEndDate: recurrenceEndDate,
    recurrenceInterval: recurrenceInterval,
    recurrenceWeekdays: recurrenceWeekdays,
    recurrenceMonthWeek: recurrenceMonthWeek,
    recurrenceExceptions: recurrenceExceptions,
    alertSameDay: alertSameDay,
    alertDayBefore: alertDayBefore,
    alertMinutesBefore: alertMinutesBefore,
    tags: tags,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    sharing: sharing,
  );

  /// Fields a collaborator may change on the owner's document. Pin,
  /// archive, alerts, labels and trash stay personal.
  static const sharedKeys = [
    'title',
    'description',
    'location',
    'color',
    'startTime',
    'endTime',
    'isAllDay',
    'isBirthday',
    'isNameDay',
    'recurrence',
    'recurrenceEndDate',
    'recurrenceInterval',
    'recurrenceWeekdays',
    'recurrenceMonthWeek',
    'recurrenceExceptions',
    'updatedAt',
  ];

  @override
  List<String> get sharedContentKeys => sharedKeys;

  @override
  List<String> get optionalKeys => const [
    'location',
    'color',
    'recurrenceEndDate',
    'recurrenceInterval',
    'recurrenceWeekdays',
    'recurrenceMonthWeek',
    'recurrenceExceptions',
    'deletedAt',
  ];

  /// Per-user fields, stored by a collaborator in `shared_event_prefs`.
  @override
  Map<String, dynamic> personalJson() => {
    'isPinned': isPinned,
    'isArchived': isArchived,
    'alertSameDay': alertSameDay,
    'alertDayBefore': alertDayBefore,
    'alertMinutesBefore': alertMinutesBefore,
    'tags': tags,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  @override
  CalendarEventModel asSharedWithMe(Map<String, dynamic>? prefs) {
    final p = prefs ?? const <String, dynamic>{};
    return CalendarEventModel(
      id: id,
      title: title,
      description: description,
      location: location,
      color: color,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      isBirthday: isBirthday,
      isNameDay: isNameDay,
      isPinned: p['isPinned'] as bool? ?? false,
      isArchived: p['isArchived'] as bool? ?? false,
      recurrence: recurrence,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceInterval: recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays,
      recurrenceMonthWeek: recurrenceMonthWeek,
      recurrenceExceptions: recurrenceExceptions,
      // Without prefs yet: the owner's alert choice as a starting point.
      alertSameDay: p['alertSameDay'] as bool? ?? alertSameDay,
      alertDayBefore: p['alertDayBefore'] as bool? ?? alertDayBefore,
      alertMinutesBefore:
          (p['alertMinutesBefore'] as num?)?.toInt() ?? alertMinutesBefore,
      tags: (p['tags'] as List<dynamic>?)?.cast<String>() ?? [],
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
    if (location.isNotEmpty) 'location': location,
    if (color != null) 'color': color!.toARGB32(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isAllDay': isAllDay,
    'isBirthday': isBirthday,
    'isNameDay': isNameDay,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'recurrence': recurrence.toShortString(),
    if (recurrenceEndDate != null)
      'recurrenceEndDate': recurrenceEndDate!.toIso8601String(),
    if (recurrenceInterval > 1) 'recurrenceInterval': recurrenceInterval,
    if (recurrenceWeekdays.isNotEmpty) 'recurrenceWeekdays': recurrenceWeekdays,
    if (recurrenceMonthWeek != null) 'recurrenceMonthWeek': recurrenceMonthWeek,
    if (recurrenceExceptions.isNotEmpty)
      'recurrenceExceptions': [
        for (final d in recurrenceExceptions) dateOnlyKey(d),
      ],
    'alertSameDay': alertSameDay,
    'alertDayBefore': alertDayBefore,
    'alertMinutesBefore': alertMinutesBefore,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      CalendarEventModel(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        location: json['location'] as String? ?? '',
        color:
            json['color'] != null
                ? AppColors.fromStored(json['color'] as int)
                : null,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        isAllDay: json['isAllDay'] as bool? ?? false,
        isBirthday: json['isBirthday'] as bool? ?? false,
        isNameDay: json['isNameDay'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        recurrence: recurrenceTypeFromString(
          json['recurrence'] as String? ?? 'none',
        ),
        recurrenceEndDate:
            json['recurrenceEndDate'] != null
                ? DateTime.parse(json['recurrenceEndDate'] as String)
                : null,
        recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt() ?? 1,
        recurrenceWeekdays:
            (json['recurrenceWeekdays'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList(),
        recurrenceMonthWeek: (json['recurrenceMonthWeek'] as num?)?.toInt(),
        recurrenceExceptions:
            (json['recurrenceExceptions'] as List<dynamic>?)
                ?.map((e) => DateTime.parse(e as String))
                .toList(),
        alertSameDay: json['alertSameDay'] as bool? ?? false,
        alertDayBefore: json['alertDayBefore'] as bool? ?? false,
        // Saved before the field existed: timed events alerted at the start.
        alertMinutesBefore: (json['alertMinutesBefore'] as num?)?.toInt() ?? 0,
        tags:
            (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
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

/// Read-only calendar entry built from a [TaskModel] with a due date, so
/// tasks can be listed in the calendar views next to events. It is placed
/// at the due time when the due date has one, else as an all-day entry on
/// the due date. Never persisted: tap opens the task view (see
/// `AppNav.openCalendarItem`).
class TaskCalendarEvent extends CalendarEventModel {
  TaskCalendarEvent(this.task)
    : super(
        id: 'task_${task.id}',
        title: task.title,
        description: task.description,
        startTime: task.dueDate!,
        endTime: task.dueDate!,
        isAllDay: !task.hasDueTime,
        recurrence: task.recurrence,
        recurrenceExceptions: task.recurrenceExceptions,
        tags: task.tags,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
      );

  final TaskModel task;

  /// Whether [task] can be shown in the calendar at all.
  static bool isShown(TaskModel task) => task.dueDate != null;
}

/// Read-only calendar entry for an Italian national holiday or observance
/// ([ItalianHoliday]), with its localized [title]. Never persisted, no
/// alerts: computed every year by [occursOn] (Easter moves), so one entry
/// covers all years. [startTime] is its date in [year], shown e.g. in
/// search results. Tap shows a small info sheet (see
/// `AppNav.openCalendarItem`).
class HolidayCalendarEvent extends CalendarEventModel {
  HolidayCalendarEvent(this.holiday, {required super.title, required int year})
    : super(
        id: 'holiday_${holiday.name}',
        startTime: _dateNear(holiday, year),
        endTime: _dateNear(holiday, year),
        isAllDay: true,
        alertMinutesBefore: noEventAlert,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      );

  final ItalianHoliday holiday;

  /// Its date in [year], or the next year it exists.
  static DateTime _dateNear(ItalianHoliday holiday, int year) {
    for (var y = year; y < year + 10; y++) {
      final d = holiday.dateIn(y);
      if (d != null) return d;
    }
    return DateTime(year);
  }

  @override
  bool occursOn(DateTime day) => holiday.occursOn(day);
}
