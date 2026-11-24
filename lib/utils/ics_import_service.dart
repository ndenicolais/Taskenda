// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:timezone/timezone.dart' as tz;
import '../models/calendar_model.dart';
import 'recurrence.dart';

/// The events of an ICS file, and how many of their recurrences could only
/// be imported approximately (rules Taskenda can't represent, see
/// [IcsImportService.parse]).
class IcsImportResult {
  const IcsImportResult(this.events, {this.approximated = 0});
  final List<CalendarEventModel> events;
  final int approximated;
}

/// One VEVENT as read from the file, before the occurrences that replace
/// or cancel part of a series are matched to it.
class _ParsedEvent {
  _ParsedEvent({
    this.event,
    this.uid,
    this.recurrenceIdDay,
    this.approximated = false,
  });

  /// Null for a cancelled event or occurrence.
  final CalendarEventModel? event;
  final String? uid;

  /// The day of the series occurrence this VEVENT replaces or cancels.
  final DateTime? recurrenceIdDay;
  final bool approximated;
}

/// A recurrence rule as Taskenda stores it.
class _Rule {
  RecurrenceType type = RecurrenceType.none;
  int interval = 1;
  List<int> weekdays = [];
  int? monthWeek;
  DateTime? endDate;
  int? count;
  bool approximated = false;
}

class IcsImportService {
  /// Parses an ICS string and returns its events.
  static List<CalendarEventModel> parseIcs(String icsContent) =>
      parse(icsContent).events;

  /// The calendar's display name (`X-WR-CALNAME`), or null if it has none.
  static String? calendarName(String icsContent) {
    final unfolded = icsContent.replaceAll(RegExp(r'\r\n[ \t]|\n[ \t]'), '');
    final match = RegExp(
      r'^X-WR-CALNAME(?:;[^:\r\n]*)?:(.*)$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(unfolded);
    final name = match == null ? '' : _unescape(match.group(1)!.trim());
    return name.isEmpty ? null : name;
  }

  /// Parses an ICS string (as exported by Google Calendar, Outlook, Apple…).
  ///
  /// Recurrences keep frequency, interval, weekdays, "Nth weekday of the
  /// month", end (`UNTIL` / `COUNT`) and excluded dates (`EXDATE`). An
  /// occurrence moved or edited in the source calendar (`RECURRENCE-ID`)
  /// becomes its own event and is left out of the series; a cancelled one
  /// is only left out. Rules beyond that (several weekdays in a monthly
  /// rule, `BYMONTH`, hourly…) are imported as the closest supported one and
  /// counted in [IcsImportResult.approximated].
  ///
  /// The first reminder of an event (`VALARM`, a popup one preferred)
  /// becomes its alert: minutes before the start for a timed event, day
  /// before / same day for an all-day one. A timed event without reminders
  /// gets [defaultAlertMinutes] (the Settings choice).
  static IcsImportResult parse(
    String icsContent, {
    int defaultAlertMinutes = 0,
  }) {
    // Unfold folded lines: a line that starts with SPACE or TAB is a
    // continuation of the previous line.
    final unfolded = icsContent.replaceAll(RegExp(r'\r\n[ \t]|\n[ \t]'), '');
    final lines = unfolded.split(RegExp(r'\r\n|\n'));

    final parsed = <_ParsedEvent>[];
    bool inEvent = false;
    // Depth of the components nested in the current VEVENT (VALARM, ...):
    // their properties (Google puts SUMMARY and DESCRIPTION in VALARM)
    // must not overwrite the event's own.
    int nested = 0;
    final props = <String, String>{};
    final propParams = <String, String>{};
    // Same as propParams but preserving original case, since TZID values
    // (e.g. "America/New_York") are case-sensitive IANA names.
    final rawPropParams = <String, String>{};
    // EXDATE can appear several times: (value, raw params) of each.
    final exdates = <(String, String)>[];
    // The VALARMs of the event: ACTION and TRIGGER (with its params).
    final alarms = <Map<String, String>>[];
    Map<String, String>? alarm;

    for (final line in lines) {
      final trimmed = line.trim();
      final upper = trimmed.toUpperCase();
      if (upper == 'BEGIN:VEVENT') {
        inEvent = true;
        nested = 0;
        props.clear();
        propParams.clear();
        rawPropParams.clear();
        exdates.clear();
        alarms.clear();
        alarm = null;
      } else if (upper == 'END:VEVENT') {
        if (inEvent) {
          final p = _buildEvent(
            props,
            propParams,
            rawPropParams,
            exdates,
            alarms,
            defaultAlertMinutes,
          );
          if (p != null) parsed.add(p);
        }
        inEvent = false;
      } else if (inEvent && upper.startsWith('BEGIN:')) {
        nested++;
        if (nested == 1 && upper == 'BEGIN:VALARM') alarm = {};
      } else if (inEvent && upper.startsWith('END:')) {
        if (nested == 1 && alarm != null) {
          alarms.add(alarm);
          alarm = null;
        }
        if (nested > 0) nested--;
      } else if (inEvent && nested == 1 && alarm != null) {
        final colonIdx = trimmed.indexOf(':');
        if (colonIdx == -1) continue;
        final keyPart = trimmed.substring(0, colonIdx).toUpperCase();
        final value = trimmed.substring(colonIdx + 1).trim().toUpperCase();
        if (keyPart == 'ACTION') alarm['ACTION'] = value;
        if (keyPart.startsWith('TRIGGER')) {
          alarm['TRIGGER'] = value;
          alarm['TRIGGER_PARAMS'] = keyPart;
        }
      } else if (inEvent && nested == 0 && trimmed.isNotEmpty) {
        final colonIdx = trimmed.indexOf(':');
        if (colonIdx == -1) continue;

        final keyPart = trimmed.substring(0, colonIdx);
        final value = trimmed.substring(colonIdx + 1);

        final semiIdx = keyPart.indexOf(';');
        final baseKey =
            (semiIdx == -1 ? keyPart : keyPart.substring(0, semiIdx))
                .toUpperCase();
        final rawParamStr = semiIdx == -1 ? '' : keyPart.substring(semiIdx + 1);

        if (baseKey == 'EXDATE') {
          exdates.add((value, rawParamStr));
          continue;
        }
        props[baseKey] = value;
        propParams[baseKey] = rawParamStr.toUpperCase();
        rawPropParams[baseKey] = rawParamStr;
      }
    }
    return _resolve(parsed);
  }

  /// Matches the occurrences that replace or cancel part of a series to it
  /// (the series leaves their day out) and drops repeated ids (a file can
  /// repeat an event: the first copy wins).
  static IcsImportResult _resolve(List<_ParsedEvent> parsed) {
    final series = <String, CalendarEventModel>{};
    for (final p in parsed) {
      final e = p.event;
      if (e != null && p.recurrenceIdDay == null && p.uid != null) {
        series.putIfAbsent(p.uid!, () => e);
      }
    }
    final excluded = <String, List<DateTime>>{};
    for (final p in parsed) {
      final day = p.recurrenceIdDay;
      if (day != null && p.uid != null && series.containsKey(p.uid)) {
        (excluded[p.uid!] ??= []).add(day);
      }
    }

    final events = <CalendarEventModel>[];
    final seenIds = <String>{};
    var approximated = 0;
    for (final p in parsed) {
      var e = p.event;
      if (e == null) continue;
      if (p.recurrenceIdDay == null && excluded.containsKey(p.uid)) {
        final days =
            {...e.recurrenceExceptions, ...excluded[p.uid]!}.toList()..sort();
        e = e.copyWith(recurrenceExceptions: days);
      }
      if (!seenIds.add(e.id)) continue;
      events.add(e);
      if (p.approximated) approximated++;
    }
    return IcsImportResult(events, approximated: approximated);
  }

  /// Extracts the TZID value (original case preserved) from a raw param
  /// string like "TZID=America/New_York" or "VALUE=DATE-TIME;TZID=Europe/Rome".
  static String? _extractTzid(String rawParamStr) {
    final match = RegExp(
      r'TZID=([^;:]+)',
      caseSensitive: false,
    ).firstMatch(rawParamStr);
    return match?.group(1);
  }

  /// The local day of a DATE or DATE-TIME [value] with its [rawParams].
  static DateTime? _parseDay(String value, String rawParams) {
    final v = value.trim();
    final isDate =
        rawParams.toUpperCase().contains('VALUE=DATE') &&
            !rawParams.toUpperCase().contains('VALUE=DATE-TIME') ||
        v.length == 8;
    final d = _parseIcsDate(v, isDate, tzid: _extractTzid(rawParams));
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static _ParsedEvent? _buildEvent(
    Map<String, String> props,
    Map<String, String> propParams,
    Map<String, String> rawPropParams,
    List<(String, String)> exdates,
    List<Map<String, String>> alarms,
    int defaultAlertMinutes,
  ) {
    final rawUid = props['UID']?.trim();
    final recurrenceIdValue = props['RECURRENCE-ID']?.trim();
    final recurrenceIdDay =
        recurrenceIdValue == null || recurrenceIdValue.isEmpty
            ? null
            : _parseDay(
              recurrenceIdValue,
              rawPropParams['RECURRENCE-ID'] ?? '',
            );

    // Cancelled events and occurrences are not events to add; a cancelled
    // occurrence still tells its series to leave that day out.
    if ((props['STATUS'] ?? '').trim().toUpperCase() == 'CANCELLED') {
      return recurrenceIdDay == null
          ? null
          : _ParsedEvent(uid: rawUid, recurrenceIdDay: recurrenceIdDay);
    }

    final summary = _unescape(props['SUMMARY'] ?? '');
    if (summary.isEmpty) return null;

    final dtstartValue = props['DTSTART'];
    if (dtstartValue == null) return null;

    final dtstartParams = propParams['DTSTART'] ?? '';
    final isAllDay =
        dtstartParams.contains('VALUE=DATE') || dtstartValue.length == 8;
    final dtstartTzid = _extractTzid(rawPropParams['DTSTART'] ?? '');

    final startTime = _parseIcsDate(dtstartValue, isAllDay, tzid: dtstartTzid);
    if (startTime == null) return null;

    DateTime endTime;
    final dtendValue = props['DTEND'];
    if (dtendValue != null) {
      final dtendParams = propParams['DTEND'] ?? '';
      final endIsAllDay =
          dtendParams.contains('VALUE=DATE') || dtendValue.length == 8;
      final dtendTzid = _extractTzid(rawPropParams['DTEND'] ?? '');
      endTime =
          _parseIcsDate(dtendValue, endIsAllDay, tzid: dtendTzid) ??
          startTime.add(
            isAllDay ? const Duration(days: 1) : const Duration(hours: 1),
          );
    } else {
      endTime = startTime.add(
        isAllDay ? const Duration(days: 1) : const Duration(hours: 1),
      );
    }

    // A moved or edited occurrence of a series shares the series' UID: it
    // gets its own id, otherwise it would overwrite the whole series.
    final uid =
        rawUid == null || recurrenceIdValue == null || recurrenceIdValue.isEmpty
            ? rawUid
            : '${rawUid}_$recurrenceIdValue';
    final description = _withoutGoogleNotice(
      _stripHtml(_unescape(props['DESCRIPTION'] ?? '')),
    );
    final location = _unescape(props['LOCATION'] ?? '').trim();

    // An occurrence that replaces one of a series is a single event.
    final rule =
        recurrenceIdDay == null
            ? _parseRule((props['RRULE'] ?? '').toUpperCase(), startTime)
            : _Rule();

    // Birthdays and name days: from CATEGORIES, or from the title of a
    // yearly all-day event ("Martina - compleanno", "Onomastico di Franco"),
    // which then keeps only the name.
    final categoriesRaw = (props['CATEGORIES'] ?? '').toUpperCase();
    final kind =
        isAllDay && rule.type == RecurrenceType.yearly
            ? specialKindFromTitle(summary)
            : null;
    final isBirthday =
        categoriesRaw.contains('BIRTHDAY') || kind?.birthday == true;
    final isNameDay = kind?.birthday == false;
    final title = kind?.name ?? summary;

    final exceptions =
        <DateTime>{
            if (rule.type != RecurrenceType.none)
              for (final (value, params) in exdates)
                for (final v in value.split(','))
                  if (_parseDay(v, params) case final d?) d,
          }.toList()
          ..sort();

    // Reminders as minutes before the start (negative: after it).
    final reminders = [
      for (final a in [
        ...alarms.where((a) => a['ACTION'] == 'DISPLAY'),
        ...alarms.where((a) => a['ACTION'] != 'DISPLAY'),
      ])
        if (_triggerMinutesBefore(a) case final m?) m,
    ];

    // When the event was created in the source calendar (Google exports
    // CREATED in UTC); without it, the time of the import.
    final createdValue = props['CREATED'];
    final createdAt =
        createdValue == null || createdValue.length < 15
            ? null
            : _parseIcsDate(createdValue, false);

    final event = CalendarEventModel(
      id: uid != null ? _sanitizeId(uid) : null,
      createdAt: createdAt,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      isBirthday: isBirthday,
      isNameDay: isNameDay,
      recurrence: rule.type,
      recurrenceInterval: rule.interval,
      recurrenceWeekdays: rule.weekdays,
      recurrenceMonthWeek: rule.monthWeek,
      recurrenceExceptions: exceptions,
      alertMinutesBefore:
          reminders.isEmpty
              ? defaultAlertMinutes
              : (reminders.first < 0 ? 0 : reminders.first),
      // A birthday or name day without reminders alerts the day before and
      // on the day, as when the kind is chosen in the editor.
      alertDayBefore:
          isAllDay &&
          (reminders.any((m) => m > 0) ||
              (reminders.isEmpty && (isBirthday || isNameDay))),
      alertSameDay:
          isAllDay &&
          (reminders.any((m) => m <= 0) ||
              (reminders.isEmpty && (isBirthday || isNameDay))),
    );
    final count = rule.count;
    return _ParsedEvent(
      event:
          count != null
              ? event.copyWith(recurrenceEndDate: event.dayOfOccurrence(count))
              : rule.endDate != null
              ? event.copyWith(recurrenceEndDate: rule.endDate)
              : event,
      uid: rawUid,
      recurrenceIdDay: recurrenceIdDay,
      approximated: rule.approximated,
    );
  }

  static const _kindWords =
      r'(compleanno|onomastico|birthday|name\s?day|nameday)';
  static final _kindSuffix = RegExp(
    '^(.+?)\\s*[-\u2013\u2014:|]\\s*$_kindWords\\s*[!.]*\$',
    caseSensitive: false,
  );
  static final _kindPrefix = RegExp(
    '^$_kindWords\\s*(?:di|of|[-\u2013\u2014:|])?\\s+(.+?)\\s*\$',
    caseSensitive: false,
  );
  static final _kindPossessive = RegExp(
    "^(.+?)'s\\s+(birthday|name\\s?day)\\s*\$",
    caseSensitive: false,
  );

  /// Whether [title] names a birthday or a name day of someone, and whose:
  /// "Martina - compleanno", "Franco – Onomastico", "Compleanno di Luca",
  /// "Anna's birthday". Null when it doesn't (e.g. "Buon compleanno!").
  static ({bool birthday, String name})? specialKindFromTitle(String title) {
    final t = title.trim();
    String? name;
    String? word;
    if (_kindSuffix.firstMatch(t) case final m?) {
      name = m.group(1);
      word = m.group(2);
    } else if (_kindPrefix.firstMatch(t) case final m?) {
      word = m.group(1);
      name = m.group(2);
    } else if (_kindPossessive.firstMatch(t) case final m?) {
      name = m.group(1);
      word = m.group(2);
    }
    name = name?.trim();
    if (name == null || name.isEmpty || word == null) return null;
    final w = word.toLowerCase();
    return (birthday: w == 'compleanno' || w == 'birthday', name: name);
  }

  /// Minutes before the start of a VALARM with a relative TRIGGER such as
  /// `-PT10M`, `-P0DT0H30M0S` or `-P1D` (negative when after the start);
  /// null for an absolute or end-related one.
  static int? _triggerMinutesBefore(Map<String, String> alarm) {
    final params = alarm['TRIGGER_PARAMS'] ?? '';
    if (params.contains('VALUE=DATE-TIME') || params.contains('RELATED=END')) {
      return null;
    }
    final m = RegExp(
      r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
    ).firstMatch(alarm['TRIGGER'] ?? '');
    if (m == null) return null;
    int part(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    final minutes =
        part(2) * 7 * 24 * 60 +
        part(3) * 24 * 60 +
        part(4) * 60 +
        part(5) +
        (part(6) >= 30 ? 1 : 0);
    return m.group(1) == '-' ? minutes : -minutes;
  }

  static const _weekdayCodes = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  /// Reads an RRULE (upper case) into what Taskenda can store, flagging
  /// what had to be approximated.
  static _Rule _parseRule(String rrule, DateTime start) {
    final rule = _Rule();
    if (rrule.isEmpty) return rule;
    final parts = <String, String>{
      for (final p in rrule.split(';'))
        if (p.contains('='))
          p.substring(0, p.indexOf('=')).trim(): p.substring(
            p.indexOf('=') + 1,
          ),
    };

    switch (parts['FREQ']) {
      case 'DAILY':
        rule.type = RecurrenceType.daily;
      case 'WEEKLY':
        rule.type = RecurrenceType.weekly;
      case 'MONTHLY':
        rule.type = RecurrenceType.monthly;
      case 'YEARLY':
        rule.type = RecurrenceType.yearly;
      case null:
        return rule;
      default:
        // HOURLY, MINUTELY, SECONDLY: nothing finer than a day.
        rule.type = RecurrenceType.daily;
        rule.approximated = true;
    }

    rule.interval = int.tryParse(parts['INTERVAL'] ?? '') ?? 1;
    if (rule.interval < 1) rule.interval = 1;

    // BYDAY entries: (ordinal or null, weekday).
    final byDay = <(int?, int)>[];
    for (final token in (parts['BYDAY'] ?? '').split(',')) {
      final m = RegExp(r'^([+-]?\d{1,2})?([A-Z]{2})$').firstMatch(token.trim());
      final wd = m == null ? null : _weekdayCodes[m.group(2)];
      if (wd == null) continue;
      byDay.add((m!.group(1) == null ? null : int.parse(m.group(1)!), wd));
    }
    final setPos = int.tryParse(parts['BYSETPOS'] ?? '');
    final byMonthDay = parts['BYMONTHDAY'];

    switch (rule.type) {
      case RecurrenceType.daily:
        // "Every weekday" can come as DAILY;BYDAY=MO,…,FR.
        if (byDay.isNotEmpty) {
          if (rule.interval == 1) {
            rule.type = RecurrenceType.weekly;
            rule.weekdays = {for (final d in byDay) d.$2}.toList()..sort();
          } else {
            rule.approximated = true;
          }
        }
      case RecurrenceType.weekly:
        if (byDay.isNotEmpty) {
          final days = {for (final d in byDay) d.$2}.toList()..sort();
          if (!(days.length == 1 && days.first == start.weekday)) {
            rule.weekdays = days;
          }
          // Taskenda counts the weeks of an interval from Monday: a
          // different week start only matters with Sunday among the days.
          final wkst = parts['WKST'];
          if (rule.interval > 1 &&
              wkst != null &&
              wkst != 'MO' &&
              days.length > 1 &&
              days.contains(DateTime.sunday)) {
            rule.approximated = true;
          }
        }
      case RecurrenceType.monthly:
        if (byDay.length == 1) {
          final (ordinal, weekday) = byDay.single;
          final week = ordinal ?? setPos;
          if (week != null && (week == -1 || (week >= 1 && week <= 5))) {
            rule.monthWeek = week;
            if (weekday != start.weekday) rule.approximated = true;
          } else {
            rule.approximated = true;
          }
        } else if (byDay.length > 1) {
          rule.approximated = true;
        }
        if (byMonthDay != null && byMonthDay.trim() != '${start.day}') {
          rule.approximated = true;
        }
      case RecurrenceType.yearly:
        final byMonth = parts['BYMONTH'];
        if (byDay.isNotEmpty ||
            (byMonth != null && byMonth.trim() != '${start.month}') ||
            (byMonthDay != null && byMonthDay.trim() != '${start.day}')) {
          rule.approximated = true;
        }
      case RecurrenceType.none:
        break;
    }

    for (final key in const [
      'BYYEARDAY',
      'BYWEEKNO',
      'BYHOUR',
      'BYMINUTE',
      'BYSECOND',
    ]) {
      if (parts.containsKey(key)) rule.approximated = true;
    }
    if (rule.type != RecurrenceType.yearly && parts.containsKey('BYMONTH')) {
      rule.approximated = true;
    }

    final until = parts['UNTIL'];
    if (until != null) {
      final d = _parseIcsDate(until, until.length == 8);
      if (d != null) rule.endDate = DateTime(d.year, d.month, d.day);
    } else {
      rule.count = int.tryParse(parts['COUNT'] ?? '');
    }
    return rule;
  }

  static DateTime? _parseIcsDate(String value, bool isAllDay, {String? tzid}) {
    try {
      if (isAllDay) {
        // Format: YYYYMMDD
        final y = int.parse(value.substring(0, 4));
        final m = int.parse(value.substring(4, 6));
        final d = int.parse(value.substring(6, 8));
        return DateTime(y, m, d);
      } else {
        // Format: YYYYMMDDTHHMMSSz or YYYYMMDDTHHMMSS
        final isUtc = value.endsWith('Z');
        final cleaned = value.replaceAll('Z', '');
        final y = int.parse(cleaned.substring(0, 4));
        final mo = int.parse(cleaned.substring(4, 6));
        final d = int.parse(cleaned.substring(6, 8));
        final h = int.parse(cleaned.substring(9, 11));
        final mi = int.parse(cleaned.substring(11, 13));
        final s = int.parse(cleaned.substring(13, 15));
        if (isUtc) {
          return DateTime.utc(y, mo, d, h, mi, s).toLocal();
        }
        if (tzid != null) {
          try {
            final location = tz.getLocation(tzid);
            // Plain local DateTime, not a TZDateTime: the latter depends on
            // tz.local and serialises with an offset that reloads as UTC.
            return DateTime.fromMillisecondsSinceEpoch(
              tz.TZDateTime(
                location,
                y,
                mo,
                d,
                h,
                mi,
                s,
              ).millisecondsSinceEpoch,
            );
          } catch (_) {
            // Unknown/unavailable TZID — fall back to treating it as local.
          }
        }
        return DateTime(y, mo, d, h, mi, s);
      }
    } catch (_) {
      return null;
    }
  }

  /// Unescape ICS text escape sequences.
  /// Single pass, so an escaped backslash followed by "n" (`\\n`) stays a
  /// literal backslash + n instead of turning into a newline.
  static String _unescape(String s) {
    return s.replaceAllMapped(RegExp(r'\\([\\;,nN])'), (m) {
      final c = m.group(1)!;
      return c == 'n' || c == 'N' ? '\n' : c;
    });
  }

  /// Strip HTML tags, convert <br> to newlines and decode the HTML entities
  /// (Google Calendar exports descriptions as HTML: "<3" arrives as
  /// "&lt;3"). Entities are decoded after the tags are stripped, so an
  /// encoded tag (`&lt;b&gt;`) stays as text.
  static String _stripHtml(String s) {
    return _decodeHtmlEntities(
      s
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), ''),
    ).trim();
  }

  static const _htmlEntities = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
  };

  /// Named ([_htmlEntities]) and numeric (`&#39;`, `&#x27;`) entities, in a
  /// single pass so `&amp;lt;` becomes the literal text `&lt;`. Unknown or
  /// invalid ones are kept as they are.
  static String _decodeHtmlEntities(String s) {
    return s.replaceAllMapped(
      RegExp(r'&(#[xX][0-9a-fA-F]{1,6}|#[0-9]{1,7}|[a-zA-Z]+);'),
      (m) {
        final entity = m.group(1)!;
        if (!entity.startsWith('#')) {
          return _htmlEntities[entity.toLowerCase()] ?? m.group(0)!;
        }
        final hex = entity.length > 1 && (entity[1] == 'x' || entity[1] == 'X');
        final code = int.tryParse(
          entity.substring(hex ? 2 : 1),
          radix: hex ? 16 : 10,
        );
        if (code == null || code == 0 || code > 0x10FFFF) return m.group(0)!;
        if (code >= 0xD800 && code <= 0xDFFF) return m.group(0)!;
        return String.fromCharCode(code);
      },
    );
  }

  /// Paragraphs Google Calendar adds to events it creates by itself (e.g.
  /// from a Gmail message), in the user's language: recognised by their
  /// closing link.
  static final _googleNoticeParagraph = RegExp(
    r'(https://g\.co/calendar|https://mail\.google\.com/mail\?extsrc=cal\S*)$',
  );

  /// Empty when [description] is only Google's automatic notice, which says
  /// nothing about the event; unchanged otherwise.
  static String _withoutGoogleNotice(String description) {
    if (description.isEmpty) return description;
    final paragraphs = description
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    return paragraphs.every(_googleNoticeParagraph.hasMatch) ? '' : description;
  }

  /// Sanitize a UID string for use as a model ID.
  static String _sanitizeId(String uid) {
    return uid.replaceAll(RegExp(r'[^\w\-@.]'), '_');
  }
}
