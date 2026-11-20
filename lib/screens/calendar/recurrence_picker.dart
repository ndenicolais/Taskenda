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
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../../models/calendar_model.dart';
import '../../theme/app_spacing.dart';
import '../../utils/recurrence.dart';
import '../../widgets/shared/app_dialogs.dart';

/// Name of [weekday] (1 = Monday … 7 = Sunday) in the app language, full
/// ("lunedì") or [short] ("lun").
String weekdayName(int weekday, {bool short = false}) =>
// 1 January 2024 is a Monday.
DateFormat(short ? 'E' : 'EEEE').format(DateTime(2024, 1, weekday));

/// "il secondo", "l'ultima"…: the ordinal of [week] (1–5, -1 = last) agreed
/// with [weekday] (Sunday is feminine in Italian).
String _ordinal(AppLocalizations l, int week, int weekday) =>
    l.recurrenceOrdinal(
      '${weekday == DateTime.sunday ? 'f' : 'm'}${week == -1 ? 'last' : week}',
    );

bool _isWorkdays(CalendarEventModel e) =>
    e.recurrence == RecurrenceType.weekly &&
    e.recurrenceInterval == 1 &&
    e.recurrenceWeekdays.length == 5 &&
    e.recurrenceWeekdays.every((d) => d <= DateTime.friday);

/// The recurrence of [event] in words: "Ogni 2 settimane: lun, mer, fino al
/// 31 dic 2026".
String describeRecurrence(AppLocalizations l, CalendarEventModel event) {
  final n = event.recurrenceInterval;
  final String base;
  switch (event.recurrence) {
    case RecurrenceType.none:
      return l.eventRecurrenceNone;
    case RecurrenceType.daily:
      base = l.recurrenceEveryDays(n);
    case RecurrenceType.weekly:
      base = l.recurrenceEveryWeeks(n);
    case RecurrenceType.monthly:
      base = l.recurrenceEveryMonths(n);
    case RecurrenceType.yearly:
      base = l.recurrenceEveryYears(n);
  }
  String? detail;
  if (event.recurrence == RecurrenceType.weekly &&
      event.recurrenceWeekdays.isNotEmpty &&
      event.hasCustomRecurrence) {
    detail = l.recurrenceOnWeekdays(
      event.recurrenceWeekdays
          .map((d) => weekdayName(d, short: true))
          .join(', '),
    );
  } else if (event.recurrence == RecurrenceType.monthly &&
      event.recurrenceMonthWeek != null) {
    final wd = event.startTime.weekday;
    detail = l.recurrenceMonthWeekday(
      _ordinal(l, event.recurrenceMonthWeek!, wd),
      weekdayName(wd),
    );
  }
  var text =
      _isWorkdays(event)
          ? l.recurrencePresetWorkdays
          : detail == null
          ? base
          : l.recurrenceRuleDetail(base, detail);
  final end = event.recurrenceEndDate;
  if (end != null) {
    text = l.recurrenceUntil(text, DateFormat.yMMMd().format(end));
  }
  return text;
}

/// [event] with a simple recurrence of [type] (interval 1, no weekdays or
/// week of the month); its end and excluded dates stay.
CalendarEventModel _simple(CalendarEventModel event, RecurrenceType type) =>
    event.copyWith(
      recurrence: type,
      recurrenceInterval: 1,
      recurrenceWeekdays: const [],
      clearRecurrenceMonthWeek: true,
    );

/// Lets the user pick the recurrence of [event] from the usual choices
/// (based on its start date, like Google Calendar) or a custom one.
/// Resolves to the updated event, or null when dismissed.
Future<CalendarEventModel?> showRecurrencePicker(
  BuildContext context,
  CalendarEventModel event,
) async {
  final l = context.l10n;
  final s = event.startTime;
  final week = weekOfMonth(s);
  final presets = <(String, CalendarEventModel)>[
    (l.eventRecurrenceNone, _simple(event, RecurrenceType.none)),
    (l.recurrenceEveryDays(1), _simple(event, RecurrenceType.daily)),
    (
      l.recurrencePresetWeekly(weekdayName(s.weekday)),
      _simple(event, RecurrenceType.weekly),
    ),
    (
      l.recurrencePresetWorkdays,
      _simple(
        event,
        RecurrenceType.weekly,
      ).copyWith(recurrenceWeekdays: const [1, 2, 3, 4, 5]),
    ),
    (
      l.recurrencePresetMonthlyDay(s.day),
      _simple(event, RecurrenceType.monthly),
    ),
    if (week <= 4)
      (
        l.recurrencePresetMonthlyWeekday(
          _ordinal(l, week, s.weekday),
          weekdayName(s.weekday),
        ),
        _simple(
          event,
          RecurrenceType.monthly,
        ).copyWith(recurrenceMonthWeek: week),
      ),
    if (isLastWeekdayOfMonth(s))
      (
        l.recurrencePresetMonthlyWeekday(
          _ordinal(l, -1, s.weekday),
          weekdayName(s.weekday),
        ),
        _simple(
          event,
          RecurrenceType.monthly,
        ).copyWith(recurrenceMonthWeek: -1),
      ),
    (
      l.recurrencePresetYearly(DateFormat.MMMMd().format(s)),
      _simple(event, RecurrenceType.yearly),
    ),
  ];
  bool same(CalendarEventModel a) =>
      a.recurrence == event.recurrence &&
      a.recurrenceInterval == event.recurrenceInterval &&
      a.recurrenceMonthWeek == event.recurrenceMonthWeek &&
      _sameDays(a, event);
  final matched = presets.indexWhere((p) => same(p.$2));

  final picked = await showAppSheet<Object>(
    context,
    isScrollControlled: true,
    builder:
        (ctx) => ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < presets.length; i++)
              ListTile(
                title: Text(presets[i].$1),
                selected: i == matched,
                onTap: () => Navigator.pop(ctx, presets[i].$2),
              ),
            ListTile(
              title: Text(ctx.l10n.recurrenceCustom),
              subtitle:
                  matched == -1
                      ? Text(describeRecurrence(ctx.l10n, event))
                      : null,
              selected: matched == -1,
              onTap: () => Navigator.pop(ctx, #custom),
            ),
          ],
        ),
  );
  if (picked is CalendarEventModel) return picked;
  if (picked == #custom && context.mounted) {
    return showAppSheet<CalendarEventModel>(
      context,
      isScrollControlled: true,
      builder: (_) => _CustomRecurrenceSheet(event: event),
    );
  }
  return null;
}

/// Weekdays of a weekly rule compared as effective days (empty = the start
/// weekday).
bool _sameDays(CalendarEventModel a, CalendarEventModel b) {
  List<int> days(CalendarEventModel e) =>
      e.recurrenceWeekdays.isEmpty
          ? [e.startTime.weekday]
          : e.recurrenceWeekdays;
  if (a.recurrence != RecurrenceType.weekly) return true;
  final x = days(a), y = days(b);
  return x.length == y.length && x.every(y.contains);
}

enum _EndMode { never, onDate, afterCount }

/// Every N days / weeks / months / years, weekdays of a weekly rule, day or
/// weekday of a monthly one, and the end (never, on a date, after N times).
class _CustomRecurrenceSheet extends StatefulWidget {
  const _CustomRecurrenceSheet({required this.event});
  final CalendarEventModel event;

  @override
  State<_CustomRecurrenceSheet> createState() => _CustomRecurrenceSheetState();
}

class _CustomRecurrenceSheetState extends State<_CustomRecurrenceSheet> {
  late RecurrenceType _type;
  late int _interval;
  late Set<int> _weekdays;
  int? _monthWeek;
  late _EndMode _endMode;
  late DateTime _endDate;
  int _count = 10;

  DateTime get _start => widget.event.startTime;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _type =
        e.recurrence == RecurrenceType.none
            ? RecurrenceType.weekly
            : e.recurrence;
    _interval = e.recurrenceInterval;
    _weekdays = {
      if (e.recurrenceWeekdays.isEmpty) _start.weekday,
      ...e.recurrenceWeekdays,
    };
    _monthWeek = e.recurrenceMonthWeek;
    _endMode = e.recurrenceEndDate == null ? _EndMode.never : _EndMode.onDate;
    _endDate =
        e.recurrenceEndDate ??
        DateTime(_start.year, _start.month + 3, _start.day);
  }

  String _unit(AppLocalizations l, RecurrenceType t) => switch (t) {
    RecurrenceType.daily => l.recurrenceUnitDays(_interval),
    RecurrenceType.weekly => l.recurrenceUnitWeeks(_interval),
    RecurrenceType.monthly => l.recurrenceUnitMonths(_interval),
    _ => l.recurrenceUnitYears(_interval),
  };

  CalendarEventModel _result() {
    final weekdays = _weekdays.toList()..sort();
    var e = widget.event.copyWith(
      recurrence: _type,
      recurrenceInterval: _interval,
      // A single day equal to the start's is stored as "no weekdays".
      recurrenceWeekdays:
          _type == RecurrenceType.weekly &&
                  !(weekdays.length == 1 && weekdays.first == _start.weekday)
              ? weekdays
              : const [],
      recurrenceMonthWeek: _type == RecurrenceType.monthly ? _monthWeek : null,
      clearRecurrenceMonthWeek:
          _type != RecurrenceType.monthly || _monthWeek == null,
      clearRecurrenceEndDate: true,
    );
    switch (_endMode) {
      case _EndMode.never:
        break;
      case _EndMode.onDate:
        e = e.copyWith(recurrenceEndDate: _endDate);
      case _EndMode.afterCount:
        e = e.copyWith(recurrenceEndDate: e.dayOfOccurrence(_count));
    }
    return e;
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_start) ? _start : _endDate,
      firstDate: DateTime(_start.year, _start.month, _start.day),
      lastDate: DateTime(_start.year + 100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endMode = _EndMode.onDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final week = weekOfMonth(_start);
    final wd = _start.weekday;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.recurrenceCustomTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.recurrenceRepeatEvery, style: theme.textTheme.titleSmall),
            Row(
              children: [
                _Stepper(
                  value: _interval,
                  min: 1,
                  max: 99,
                  onChanged: (v) => setState(() => _interval = v),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButton<RecurrenceType>(
                    isExpanded: true,
                    value: _type,
                    items: [
                      for (final t in const [
                        RecurrenceType.daily,
                        RecurrenceType.weekly,
                        RecurrenceType.monthly,
                        RecurrenceType.yearly,
                      ])
                        DropdownMenuItem(value: t, child: Text(_unit(l, t))),
                    ],
                    onChanged: (t) {
                      if (t != null) setState(() => _type = t);
                    },
                  ),
                ),
              ],
            ),
            if (_type == RecurrenceType.weekly) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l.recurrenceRepeatOn, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(weekdayName(d, short: true)),
                      tooltip: weekdayName(d),
                      selected: _weekdays.contains(d),
                      showCheckmark: false,
                      onSelected:
                          (on) => setState(() {
                            // At least one day stays selected.
                            if (on) {
                              _weekdays.add(d);
                            } else if (_weekdays.length > 1) {
                              _weekdays.remove(d);
                            }
                          }),
                    ),
                ],
              ),
            ],
            if (_type == RecurrenceType.monthly) ...[
              const SizedBox(height: AppSpacing.md),
              RadioGroup<int?>(
                groupValue: _monthWeek,
                onChanged: (v) => setState(() => _monthWeek = v),
                child: Column(
                  children: [
                    RadioListTile<int?>(
                      contentPadding: EdgeInsets.zero,
                      value: null,
                      title: Text(l.recurrenceMonthDay(_start.day)),
                    ),
                    if (week <= 4)
                      RadioListTile<int?>(
                        contentPadding: EdgeInsets.zero,
                        value: week,
                        title: Text(
                          l.recurrenceMonthWeekday(
                            _ordinal(l, week, wd),
                            weekdayName(wd),
                          ),
                        ),
                      ),
                    if (isLastWeekdayOfMonth(_start))
                      RadioListTile<int?>(
                        contentPadding: EdgeInsets.zero,
                        value: -1,
                        title: Text(
                          l.recurrenceMonthWeekday(
                            _ordinal(l, -1, wd),
                            weekdayName(wd),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(l.recurrenceEnds, style: theme.textTheme.titleSmall),
            RadioGroup<_EndMode>(
              groupValue: _endMode,
              onChanged: (v) {
                if (v != null) setState(() => _endMode = v);
              },
              child: Column(
                children: [
                  RadioListTile<_EndMode>(
                    contentPadding: EdgeInsets.zero,
                    value: _EndMode.never,
                    title: Text(l.recurrenceEndsNever),
                  ),
                  RadioListTile<_EndMode>(
                    contentPadding: EdgeInsets.zero,
                    value: _EndMode.onDate,
                    title: Row(
                      children: [
                        Text(l.recurrenceEndsOn),
                        const SizedBox(width: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _pickEndDate,
                          child: Text(DateFormat.yMMMd().format(_endDate)),
                        ),
                      ],
                    ),
                  ),
                  RadioListTile<_EndMode>(
                    contentPadding: EdgeInsets.zero,
                    value: _EndMode.afterCount,
                    title: Row(
                      children: [
                        Text(l.recurrenceEndsAfter),
                        const SizedBox(width: AppSpacing.sm),
                        _Stepper(
                          value: _count,
                          min: 1,
                          max: 999,
                          onChanged:
                              (v) => setState(() {
                                _count = v;
                                _endMode = _EndMode.afterCount;
                              }),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: Text(l.recurrenceOccurrences(_count))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonCancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _result()),
                  child: Text(l.commonDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A number between [min] and [max] with − and + buttons.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          visualDensity: VisualDensity.compact,
          tooltip: '−',
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          visualDensity: VisualDensity.compact,
          tooltip: '+',
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
