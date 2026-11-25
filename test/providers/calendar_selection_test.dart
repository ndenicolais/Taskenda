// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/models/sharing.dart';
import 'package:taskenda/models/task_model.dart';
import 'package:taskenda/providers/calendar_provider.dart';
import 'package:taskenda/providers/calendar_selection_provider.dart';
import 'package:taskenda/providers/core_providers.dart';
import 'package:taskenda/utils/italian_holidays.dart';
import '../helpers/test_container.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = createTestContainer(
      FakeFirebaseFirestore(),
      uid: 'u',
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  CalendarEventModel event(String title) => CalendarEventModel(
    title: title,
    startTime: DateTime(2026, 3, 10, 9),
    endTime: DateTime(2026, 3, 10, 10),
  );

  test('toggle, addAll and clear the selection', () {
    container.listen(calendarSelectionProvider, (_, _) {});
    final selection = container.read(calendarSelectionProvider.notifier);

    selection.toggle('a');
    selection.addAll(['b', 'c']);
    expect(container.read(calendarSelectionProvider), {'a', 'b', 'c'});

    selection.toggle('a');
    expect(container.read(calendarSelectionProvider), {'b', 'c'});

    selection.clear();
    expect(container.read(calendarSelectionProvider), isEmpty);
  });

  test('only own events are selectable', () {
    expect(isCalendarItemSelectable(event('Mio'), 'u'), isTrue);
    expect(
      isCalendarItemSelectable(
        event('Altrui').withSharing(const Sharing(ownerId: 'x')),
        'u',
      ),
      isFalse,
    );
    expect(
      isCalendarItemSelectable(
        TaskCalendarEvent(TaskModel(title: 't', dueDate: DateTime(2026))),
        'u',
      ),
      isFalse,
    );
    expect(
      isCalendarItemSelectable(
        HolidayCalendarEvent(
          ItalianHoliday.values.first,
          title: 'h',
          year: 2026,
        ),
        'u',
      ),
      isFalse,
    );
  });

  test(
    'softDeleteMany trashes only the given events, undo restores them',
    () async {
      final calendar = container.read(calendarProvider.notifier);
      final a = event('A'), b = event('B'), c = event('C');
      for (final e in [a, b, c]) {
        await calendar.addEvent(e);
      }

      await calendar.softDeleteMany({a.id, b.id});
      expect(
        container.read(trashedEventsProvider).map((e) => e.id),
        unorderedEquals([a.id, b.id]),
      );
      expect(container.read(activeEventsProvider).single.id, c.id);

      await calendar.restoreManyFromTrash({a.id, b.id});
      expect(container.read(trashedEventsProvider), isEmpty);
      expect(container.read(activeEventsProvider), hasLength(3));
    },
  );
}
