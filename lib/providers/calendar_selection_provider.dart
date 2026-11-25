// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_model.dart';
import 'auth_provider.dart';

/// Ids of the events selected in the calendar (long press on a card in the
/// schedule or in the search results). Empty means no selection mode;
/// leaving the calendar drops it (auto-dispose).
class CalendarSelectionNotifier extends AutoDisposeNotifier<Set<String>> {
  @override
  Set<String> build() {
    // A different account starts without a selection.
    ref.watch(currentUidProvider);
    return const {};
  }

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  /// Adds [ids] to the selection ("Seleziona tutti" on the search results).
  void addAll(Iterable<String> ids) => state = {...state, ...ids};

  void clear() => state = const {};
}

final calendarSelectionProvider =
    NotifierProvider.autoDispose<CalendarSelectionNotifier, Set<String>>(
      CalendarSelectionNotifier.new,
    );

/// Whether [event] can be selected for a bulk delete: an own event, not a
/// task, a holiday or an event someone else shared with [uid].
bool isCalendarItemSelectable(CalendarEventModel event, String uid) =>
    event is! TaskCalendarEvent &&
    event is! HolidayCalendarEvent &&
    !event.isForeignTo(uid);
