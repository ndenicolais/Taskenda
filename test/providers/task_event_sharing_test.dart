// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/models/subtask_model.dart';
import 'package:taskenda/models/task_model.dart';
import 'package:taskenda/providers/calendar_provider.dart';
import 'package:taskenda/providers/shared_items.dart';
import 'package:taskenda/providers/tasks_provider.dart';
import '../helpers/test_container.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer alice;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    alice = createTestContainer(firestore, uid: 'alice');
    await firestore.doc('user_directory/bob@example.com').set({
      'uid': 'bob',
      'email': 'bob@example.com',
      'name': 'Bob',
    });
  });

  Future<Map<String, dynamic>> aliceDoc(String path) async =>
      (await firestore.doc('users/alice/$path').get()).data()!;

  /// Bob's view, loaded like after a sign-in. The fake Firestore doesn't
  /// stream collection-group changes: Alice's collections stand in.
  Future<ProviderContainer> bobContainer() async {
    final bob = createTestContainer(
      firestore,
      uid: 'bob',
      overrides: [
        sharedWithMeQueryProvider.overrideWithValue(
          (collection, uid) => firestore
              .collection('users/alice/$collection')
              .where('collaborators', arrayContains: uid),
        ),
      ],
    );
    bob
      ..read(tasksProvider)
      ..read(calendarProvider);
    await bob.read(tasksProvider.notifier).initialLoad;
    await bob.read(calendarProvider.notifier).initialLoad;
    return bob;
  }

  group('tasks', () {
    Future<TaskModel> sharedTask() async {
      final task = TaskModel(
        title: 'Spesa',
        isSpecial: true,
        listId: 'casa',
        dueDate: DateTime(2026, 12, 1),
        subtasks: [SubtaskModel(title: 'Pane')],
      );
      await alice.read(tasksProvider.notifier).addTask(task);
      await alice
          .read(tasksProvider.notifier)
          .addCollaborator(task.id, 'bob@example.com');
      return task;
    }

    test('the collaborator sees the task without personal fields', () async {
      final task = await sharedTask();
      final bob = await bobContainer();

      final seen = bob.read(tasksProvider).single;
      expect(seen.id, task.id);
      expect(seen.subtasks.single.title, 'Pane');
      expect(seen.isSpecial, isFalse);
      expect(seen.listId, isNull);
      expect(seen.owner?.uid, 'alice');
    });

    test('completion and due date are shared, star and list are not', () async {
      final task = await sharedTask();
      final bob = await bobContainer();
      final seen = bob.read(tasksProvider).single;

      await bob
          .read(tasksProvider.notifier)
          .updateTask(
            seen.copyWith(
              isCompleted: true,
              clearDueDate: true,
              isSpecial: true,
              listId: 'mia',
            ),
          );

      final data = await aliceDoc('tasks/${task.id}');
      expect(data['isCompleted'], isTrue);
      expect(data.containsKey('dueDate'), isFalse);
      expect(data['listId'], 'casa');
      final prefs =
          (await firestore.doc('users/bob/shared_task_prefs/${task.id}').get())
              .data()!;
      expect(prefs['listId'], 'mia');
      expect(prefs['isSpecial'], isTrue);
    });

    test('the owner sees collaborator edits live', () async {
      await alice.read(tasksProvider.notifier).initialLoad;
      final task = await sharedTask();
      final bob = await bobContainer();

      await bob.read(tasksProvider.notifier).toggleComplete(task.id);
      await pumpEventQueue();

      final live = alice.read(tasksProvider).single;
      expect(live.isCompleted, isTrue);
      expect(live.isSpecial, isTrue);
    });

    test('deleting for good leaves the task', () async {
      final task = await sharedTask();
      final bob = await bobContainer();

      await bob.read(tasksProvider.notifier).leaveTask(task.id);

      expect(bob.read(tasksProvider), isEmpty);
      expect((await aliceDoc('tasks/${task.id}'))['collaborators'], isEmpty);
    });

    test('backups and clearAll leave shared tasks out', () async {
      await sharedTask();
      final bob = await bobContainer();
      await bob.read(tasksProvider.notifier).addTask(TaskModel(title: 'Mio'));

      expect(bob.read(ownTasksProvider).map((t) => t.title), ['Mio']);
      await bob.read(tasksProvider.notifier).clearAll();
      expect(bob.read(tasksProvider).single.title, 'Spesa');
    });
  });

  group('events', () {
    Future<CalendarEventModel> sharedEvent() async {
      final event = CalendarEventModel(
        title: 'Cena',
        location: 'Roma',
        startTime: DateTime(2026, 12, 5, 20),
        endTime: DateTime(2026, 12, 5, 22),
        isPinned: true,
        alertDayBefore: true,
      );
      await alice.read(calendarProvider.notifier).addEvent(event);
      await alice
          .read(calendarProvider.notifier)
          .addCollaborator(event.id, 'bob@example.com');
      return event;
    }

    test('the collaborator sees the event and edits shared fields', () async {
      final event = await sharedEvent();
      final bob = await bobContainer();
      final seen = bob.read(calendarProvider).single;
      expect(seen.isPinned, isFalse);
      expect(seen.location, 'Roma');

      await bob
          .read(calendarProvider.notifier)
          .updateEvent(
            seen.copyWith(location: '', isPinned: true, alertSameDay: true),
          );

      final data = await aliceDoc('calendar_events/${event.id}');
      expect(data.containsKey('location'), isFalse);
      expect(data['isPinned'], isTrue);
      expect(data['alertSameDay'], isFalse);
    });

    test('the collaborator sees owner edits live', () async {
      final event = await sharedEvent();
      final bob = await bobContainer();

      await alice
          .read(calendarProvider.notifier)
          .updateEvent(event.copyWith(title: 'Cena da Anna'));
      await pumpEventQueue();

      expect(bob.read(calendarProvider).single.title, 'Cena da Anna');
    });

    test('unsharing removes the event from the collaborator', () async {
      final event = await sharedEvent();
      final bob = await bobContainer();

      await alice
          .read(calendarProvider.notifier)
          .removeCollaborator(event.id, 'bob');
      await pumpEventQueue();

      expect(bob.read(calendarProvider), isEmpty);
      expect(bob.read(ownEventsProvider), isEmpty);
    });
  });
}
