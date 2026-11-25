// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:convert';

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/settings/ui_provider.dart';
import '../../theme/app_font_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../utils/focus_after_transition.dart';
import '../../utils/notification_service.dart';
import '../../utils/picker_defaults.dart';
import '../../utils/recurrence.dart';
import '../../widgets/shared/app_dialogs.dart';
import '../../widgets/shared/collaborators_sheet.dart';
import '../../widgets/shared/error_feedback.dart';
import '../../widgets/shared/date_time_picker_dialog.dart';
import 'calendar_event_delete.dart';
import 'calendar_event_details_section.dart';
import 'calendar_event_editor_bars.dart';
import 'calendar_location_field.dart';
import 'calendar_new_entry.dart';
import 'calendar_participants_tile.dart';

class CalendarEventEditorScreen extends ConsumerStatefulWidget {
  const CalendarEventEditorScreen({
    super.key,
    required this.event,
    this.occurrence,
  });
  final CalendarEventModel event;

  /// The day the event was opened from in the calendar: for a recurring
  /// event the editor shows that occurrence and, on leaving with changes,
  /// asks whether they apply to it only or to the whole series.
  final DateTime? occurrence;

  @override
  ConsumerState<CalendarEventEditorScreen> createState() =>
      _CalendarEventEditorScreenState();
}

class _CalendarEventEditorScreenState
    extends ConsumerState<CalendarEventEditorScreen> {
  late CalendarEventModel _event;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late final List<String> _locationHistory;
  final _titleFocusNode = FocusNode();
  bool _isNew = false;
  bool _softDeleted = false;

  /// Start of the occurrence being edited (on the day it was opened from),
  /// or null when the editor works on the event as a whole.
  DateTime? _occurrenceStart;

  /// The occurrence as opened, to tell whether anything was changed.
  String _occurrenceBaseline = '';

  /// Set while the "this event / whole series" choice is open.
  bool _choosingScope = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    // Verifichiamo se l'evento esiste già nel provider
    _isNew = ref.read(calendarProvider).every((e) => e.id != _event.id);
    // A new timed event starts with the alert chosen in Settings.
    if (_isNew && !_event.isAllDay) {
      _event = _event.copyWith(
        alertMinutesBefore: ref.read(eventAlertOffsetProvider),
      );
    }
    final day = widget.occurrence;
    if (!_isNew && day != null && _event.recurrence != RecurrenceType.none) {
      final s = _event.startTime;
      final start = DateTime(day.year, day.month, day.day, s.hour, s.minute);
      _event = _event.copyWith(
        startTime: start,
        endTime: start.add(_event.endTime.difference(s)),
      );
      _occurrenceStart = start;
      _occurrenceBaseline = _contentKey(_event);
    }

    _titleController = TextEditingController(text: _event.title);
    _descriptionController = TextEditingController(text: _event.description);
    _locationController = TextEditingController(text: _event.location);
    _locationHistory = _otherLocations();

    // A new event starts with the cursor in the title.
    if (_isNew) focusAfterRouteTransition(context, _titleFocusNode);
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Locations of the other events, most recently edited first, offered
  /// as suggestions while typing.
  List<String> _otherLocations() {
    final events = [...ref.read(calendarProvider)]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return {
      for (final e in events)
        if (e.id != _event.id && e.location.isNotEmpty) e.location,
    }.toList();
  }

  bool _isEmpty() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    return title.isEmpty && description.isEmpty && location.isEmpty;
  }

  /// Switches this never-saved event to a new task, keeping what was typed.
  void _switchToTask() {
    _softDeleted = true; // Skips the save: the entry becomes a task.
    switchEventToTask(
      context,
      _event,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
  }

  /// Opens the participants (collaborators) sheet. Sharing needs the event
  /// on the server, so a new one is saved first, even if still empty.
  void _showParticipants() {
    _save(force: true);
    showCollaboratorsSheet(
      context,
      kind: ShareKind.event,
      itemId: _event.id,
      onLeft: () {
        _softDeleted = true; // Left the shared event: nothing to save.
        Navigator.maybePop(context);
      },
    );
  }

  /// [_event] with the text fields as typed.
  CalendarEventModel _edited() => _event.copyWith(
    title: _titleController.text.trim(),
    description: _descriptionController.text.trim(),
    location: _locationController.text.trim(),
  );

  /// What [e] stores, apart from the modification time.
  static String _contentKey(CalendarEventModel e) =>
      jsonEncode(e.copyWith(updatedAt: DateTime(2000)).toJson());

  static String _recurrenceKey(CalendarEventModel e) {
    final json = e.toJson();
    return jsonEncode([
      for (final k in const [
        'recurrence',
        'recurrenceEndDate',
        'recurrenceInterval',
        'recurrenceWeekdays',
        'recurrenceMonthWeek',
      ])
        json[k],
    ]);
  }

  /// [e], edited as the occurrence on [_occurrenceStart], back on the
  /// series: a date moved there moves the series start by as many days.
  CalendarEventModel _asSeries(CalendarEventModel e) {
    final occ = _occurrenceStart;
    if (occ == null) return e;
    final s = e.startTime;
    final days =
        DateTime.utc(
          s.year,
          s.month,
          s.day,
        ).difference(DateTime.utc(occ.year, occ.month, occ.day)).inDays;
    final first = widget.event.startTime;
    final start = DateTime(
      first.year,
      first.month,
      first.day + days,
      s.hour,
      s.minute,
    );
    return e.copyWith(
      startTime: start,
      endTime: start.add(e.endTime.difference(s)),
    );
  }

  /// Leaving the editor of an occurrence: unchanged it just closes, with
  /// changes it asks whether they apply to this event only (split off the
  /// series) or to the whole series. Cancelling stays in the editor.
  Future<void> _closeOccurrence() async {
    if (_choosingScope || _softDeleted) return;
    final edited = _edited();
    var scope = RecurringScope.series;
    if (_contentKey(edited) == _occurrenceBaseline) {
      _softDeleted = true; // Nothing changed: nothing to save.
    } else if (_recurrenceKey(edited) == _recurrenceKey(widget.event)) {
      _choosingScope = true;
      final picked = await showRecurringEventEditDialog(context);
      _choosingScope = false;
      if (picked == null || !mounted) return;
      scope = picked;
    }
    // A changed recurrence is about the series: no question asked.
    if (!_softDeleted) {
      if (scope == RecurringScope.thisOccurrence) {
        notifyOnError(
          ref
              .read(calendarProvider.notifier)
              .splitOccurrence(
                widget.event.id,
                _occurrenceStart!,
                edited.asStandaloneCopy(),
              ),
          context,
        );
      } else {
        _save();
      }
      _softDeleted = true; // Saved here: not again on pop.
    }
    Navigator.pop(context);
  }

  void _save({bool force = false}) {
    if (_softDeleted) return;
    if (_isNew && _isEmpty() && !force) return;

    final now = DateTime.now();
    final edited = _edited().copyWith(updatedAt: now);
    final updated = _asSeries(edited);

    final Future<void> pending;
    if (_isNew) {
      pending = ref.read(calendarProvider.notifier).addEvent(updated);
      _isNew = false;
    } else {
      pending = ref.read(calendarProvider.notifier).updateEvent(updated);
    }
    notifyOnError(pending, context);
    // An occurrence stays shown as such; what was saved is its new baseline.
    setState(() => _event = edited);
    if (_occurrenceStart != null) _occurrenceBaseline = _contentKey(edited);
    NotificationService.instance
        .scheduleEventAlerts(
          updated,
          allDayMinutes: ref.read(defaultAlertTimeProvider),
          dayBeforeMinutes: ref.read(dayBeforeAlertTimeProvider),
        )
        .ignore();
  }

  void _openDateTimePicker() async {
    final start = _event.startTime;
    final startTime = TimeOfDay.fromDateTime(start);
    // A new event for today does not start in the past.
    TimeOfDay offered(DateTime date) =>
        _isNew ? initialPickerTime(date, startTime) : startTime;
    final picked = await showDateTimePickerDialog(
      context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialTime: offered(start),
      defaultTime: offered,
      timeRequired: true,
      showTime: !_event.isAllDay,
    );
    if (picked == null || !mounted) return;

    if (_event.isAllDay) {
      final day = picked.combined;
      setState(
        () =>
            _event = _event.copyWith(
              startTime: day,
              endTime: day.add(const Duration(days: 1)),
            ),
      );
      return;
    }
    final newStart = picked.combined;
    final duration = _event.endTime.difference(_event.startTime);
    setState(
      () =>
          _event = _event.copyWith(
            startTime: newStart,
            endTime: newStart.add(duration),
          ),
    );
  }

  Future<void> _pickEndTime() async {
    final start = _event.startTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _event.hasEndTime
            ? _event.endTime
            : start.add(const Duration(hours: 1)),
      ),
    );
    if (selectedTime == null || !mounted) return;

    var end = DateTime(
      start.year,
      start.month,
      start.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    // An end earlier than the start means the event goes past midnight;
    // an end equal to the start means a single time (no end).
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    setState(() => _event = _event.copyWith(endTime: end));
  }

  void _clearEndTime() {
    setState(() => _event = _event.copyWith(endTime: _event.startTime));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.calendarDeleteEvent,
      message: context.l10n.calendarDeleteEventConfirm,
      confirmLabel: context.l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    // A never-saved event is not in the provider: nothing to trash.
    if (!_isNew) {
      final notifier = ref.read(calendarProvider.notifier);
      final id = _event.id;
      notifyWithUndo(
        notifier.softDelete(id),
        context,
        message: context.l10n.calendarEventTrashed,
        onUndo: () => notifier.restoreFromTrash(id),
      );
    }
    _softDeleted = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      // An occurrence of a recurring event asks before leaving with changes.
      canPop: _occurrenceStart == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _save();
        } else {
          _closeOccurrence();
        }
      },
      child: Scaffold(
        appBar: CalendarEventEditorAppBar(
          isArchived: _event.isArchived,
          onToggleArchive: () {
            setState(
              () => _event = _event.copyWith(isArchived: !_event.isArchived),
            );
            _save();
            Navigator.pop(context);
          },
          // Back saves too (PopScope): this is the explicit way.
          onSave: () => Navigator.maybePop(context),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Titolo (Obbligatorio)
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: AppFontSizes.headline,
                fontWeight: FontWeight.bold,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: context.l10n.calendarTitleHint,
                hintStyle: TextStyle(
                  fontSize: AppFontSizes.headline,
                  color: colorScheme.onSurface.withAlpha(100),
                ),
                border: InputBorder.none,
              ),
            ),
            if (_isNew)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: CalendarEntryTypeSelector(
                  selected: CalendarEntryType.event,
                  onChanged: (_) => _switchToTask(),
                ),
              ),
            CalendarEventDetailsSection(
              event: _event,
              locationField: CalendarLocationField(
                controller: _locationController,
                history: _locationHistory,
              ),
              participantsTile: CalendarParticipantsTile(
                members:
                    ref
                        .watch(eventsByIdProvider.select((m) => m[_event.id]))
                        ?.membersExcept(ref.watch(currentUidProvider)) ??
                    const [],
                onTap: _showParticipants,
              ),
              allDayAlertMinutes: ref.watch(defaultAlertTimeProvider),
              dayBeforeAlertMinutes: ref.watch(dayBeforeAlertTimeProvider),
              onPickDateTime: _openDateTimePicker,
              onPickEndTime: _pickEndTime,
              onClearEndTime: _clearEndTime,
              onChanged: (e) => setState(() => _event = e),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Descrizione (Opzionale)
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: AppFontSizes.lg),
              maxLines: null,
              minLines: 4,
              decoration: InputDecoration(
                hintText: context.l10n.calendarDescriptionHint,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withAlpha(100),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.commonLastModified(
                DateFormat('dd MMM, HH:mm').format(_event.updatedAt),
              ),
              style: TextStyle(
                fontSize: AppFontSizes.sm,
                color: colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CalendarEventEditorBottomBar(
          onDelete: _confirmDelete,
          onClose: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}
