import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/models/note_model.dart';
import 'package:taskenda/models/task_list_model.dart';
import 'package:taskenda/models/task_model.dart';
import 'package:taskenda/providers/calendar_provider.dart';
import 'package:taskenda/providers/crypto_provider.dart';
import 'package:taskenda/providers/labels_provider.dart';
import 'package:taskenda/providers/notes_provider.dart';
import 'package:taskenda/providers/shared_items.dart';
import 'package:taskenda/providers/tasks_provider.dart';

import '../helpers/crypto.dart';
import '../helpers/test_container.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MemoryKeyStorage storage;

  setUp(() {
    db = FakeFirebaseFirestore();
    storage = MemoryKeyStorage();
  });

  /// A container for [uid] with real encryption, keys created (first time)
  /// or unlocked with the same passphrase.
  Future<ProviderContainer> unlocked({
    String uid = 'u1',
    MemoryKeyStorage? on,
    List<Override> overrides = const [],
  }) async {
    final c = createTestContainer(
      db,
      uid: uid,
      encrypted: true,
      overrides: [...cryptoOverrides(on ?? storage), ...overrides],
    );
    c.listen(cryptoProvider, (_, _) {});
    final state = await settledCrypto(c);
    final notifier = c.read(cryptoProvider.notifier);
    if (state is CryptoNeedsSetup) await notifier.setup('passphrase');
    if (state is CryptoLocked) await notifier.unlock('passphrase');
    return c;
  }

  Future<Map<String, dynamic>> raw(String path) async =>
      (await db.doc(path).get()).data()!;

  /// Waits until the document at [path] is encrypted (background writes).
  Future<Map<String, dynamic>> encrypted(String path) async {
    for (var i = 0; i < 200; i++) {
      final data = (await db.doc(path).get()).data();
      if (data?['e'] == 1) return data!;
      await Future<void>.delayed(Duration.zero);
    }
    return raw(path);
  }

  Future<List<NoteModel>> loadNotes(ProviderContainer c) async {
    c.read(notesProvider);
    expect(await c.read(notesProvider.notifier).initialLoad, isTrue);
    return c.read(notesProvider);
  }

  test('nothing loads while the keys are locked', () async {
    // Keys created on another device, none on this one.
    (await unlocked(on: MemoryKeyStorage())).dispose();
    final c = createTestContainer(
      db,
      uid: 'u1',
      encrypted: true,
      overrides: cryptoOverrides(storage),
    );
    c.listen(cryptoProvider, (_, _) {});
    expect(await settledCrypto(c), isA<CryptoLocked>());
    c.read(notesProvider);
    expect(await c.read(notesProvider.notifier).initialLoad, isFalse);
    expect(c.read(itemCipherProvider), isNull);
  });

  test('a note is stored encrypted and read back on another device', () async {
    final c = await unlocked();
    await loadNotes(c);
    final note = NoteModel(
      title: 'Diario segreto',
      content: 'Contenuto privato',
      tags: ['Lavoro riservato'],
      isPinned: true,
    );
    await c.read(notesProvider.notifier).addNote(note);

    final doc = await raw('users/u1/notes/${note.id}');
    final text = jsonEncode(doc);
    expect(doc['e'], 1);
    expect(text, isNot(contains('segreto')));
    expect(text, isNot(contains('privato')));
    expect(text, isNot(contains('riservato')));
    expect(doc['isPinned'], isTrue);
    expect((doc['keys'] as Map).keys, ['u1']);

    // Edited: same item key, still encrypted.
    await c
        .read(notesProvider.notifier)
        .updateNote(note.copyWith(title: 'Diario modificato'));
    expect(
      jsonEncode(await raw('users/u1/notes/${note.id}')),
      isNot(contains('modificato')),
    );

    final other = await unlocked(on: MemoryKeyStorage());
    final notes = await loadNotes(other);
    expect(notes.single.title, 'Diario modificato');
    expect(notes.single.content, 'Contenuto privato');
    expect(notes.single.tags, ['Lavoro riservato']);
    expect(notes.single.isPinned, isTrue);
  });

  test('notes written in clear are encrypted at the first load', () async {
    final legacy = NoteModel(title: 'Vecchia nota', content: 'in chiaro');
    await db.doc('users/u1/notes/${legacy.id}').set(legacy.toJson());

    final c = await unlocked();
    final notes = await loadNotes(c);
    expect(notes.single.title, 'Vecchia nota');

    final doc = await encrypted('users/u1/notes/${legacy.id}');
    expect(doc['e'], 1);
    expect(jsonEncode(doc), isNot(contains('Vecchia')));

    final again = await loadNotes(await unlocked(on: MemoryKeyStorage()));
    expect(again.single.content, 'in chiaro');
  });

  test('tasks and events are encrypted too', () async {
    final c = await unlocked();
    c
      ..read(tasksProvider)
      ..read(calendarProvider);
    await c.read(tasksProvider.notifier).initialLoad;
    await c.read(calendarProvider.notifier).initialLoad;

    final task = TaskModel(
      title: 'Pagare il medico',
      description: 'visita',
      dueDate: DateTime(2026, 12, 1, 9),
    );
    final event = CalendarEventModel(
      title: 'Colloquio',
      location: 'Via Roma 1',
      startTime: DateTime(2026, 12, 2, 10),
      endTime: DateTime(2026, 12, 2, 11),
    );
    await c.read(tasksProvider.notifier).addTask(task);
    await c.read(calendarProvider.notifier).addEvent(event);

    final taskDoc = jsonEncode(await raw('users/u1/tasks/${task.id}'));
    final eventDoc = jsonEncode(
      await raw('users/u1/calendar_events/${event.id}'),
    );
    expect(taskDoc, isNot(contains('medico')));
    expect(taskDoc, isNot(contains('2026-12-01')));
    expect(eventDoc, isNot(contains('Colloquio')));
    expect(eventDoc, isNot(contains('Roma')));

    final other = await unlocked(on: MemoryKeyStorage());
    other
      ..read(tasksProvider)
      ..read(calendarProvider);
    await other.read(tasksProvider.notifier).initialLoad;
    await other.read(calendarProvider.notifier).initialLoad;
    expect(other.read(tasksProvider).single.dueDate, task.dueDate);
    expect(other.read(calendarProvider).single.location, 'Via Roma 1');
  });

  test('label and task list names are encrypted', () async {
    final c = await unlocked();
    c
      ..read(labelsProvider)
      ..read(taskListsProvider);
    await pumpEventQueue();
    await c.read(labelsProvider.notifier).add('Salute');
    final list = TaskListModel(name: 'Spesa settimanale');
    await c.read(taskListsProvider.notifier).addList(list);

    final labels = await db.collection('users/u1/labels').get();
    expect(jsonEncode(labels.docs.single.data()), isNot(contains('Salute')));
    expect(
      jsonEncode(await raw('users/u1/task_lists/${list.id}')),
      isNot(contains('Spesa')),
    );

    final other = await unlocked(on: MemoryKeyStorage());
    other
      ..read(labelsProvider)
      ..read(taskListsProvider);
    for (var i = 0; i < 100 && other.read(labelsProvider).isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    for (var i = 0; i < 100 && other.read(taskListsProvider).isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(other.read(labelsProvider).single.name, 'Salute');
    expect(other.read(taskListsProvider).single.name, 'Spesa settimanale');
  });

  test('sharing writes the note in clear for the collaborator', () async {
    await db.doc('user_directory/bob@example.com').set({
      'uid': 'bob',
      'email': 'bob@example.com',
      'name': 'Bob',
    });
    final c = await unlocked();
    await loadNotes(c);
    final note = NoteModel(title: 'Spesa comune', content: 'latte');
    await c.read(notesProvider.notifier).addNote(note);
    expect((await raw('users/u1/notes/${note.id}'))['e'], 1);

    await c
        .read(notesProvider.notifier)
        .addCollaborator(note.id, 'bob@example.com');
    final shared = await raw('users/u1/notes/${note.id}');
    expect(shared['title'], 'Spesa comune');
    expect(shared.containsKey('e'), isFalse);
    expect(shared.containsKey('enc'), isFalse);
    expect(shared['collaborators'], ['bob']);

    // Bob reads it (in clear) with his own keys.
    final bob = await unlocked(
      uid: 'bob',
      on: MemoryKeyStorage(),
      overrides: [
        sharedWithMeQueryProvider.overrideWithValue(
          (collection, uid) => db
              .collection('users/u1/$collection')
              .where('collaborators', arrayContains: uid),
        ),
      ],
    );
    final bobNotes = await loadNotes(bob);
    expect(bobNotes.single.content, 'latte');
  });

  test('reset deletes the encrypted items, keeps those in clear', () async {
    final c = await unlocked();
    await loadNotes(c);
    final secret = NoteModel(title: 'Cifrata');
    await c.read(notesProvider.notifier).addNote(secret);
    final clear = NoteModel(title: 'Condivisa');
    await db.doc('users/u1/notes/${clear.id}').set({
      ...clear.toJson(),
      'ownerId': 'u1',
      'collaborators': ['bob'],
    });

    final other = createTestContainer(
      db,
      uid: 'u1',
      encrypted: true,
      overrides: cryptoOverrides(MemoryKeyStorage()),
    );
    other.listen(cryptoProvider, (_, _) {});
    await settledCrypto(other);
    await other.read(cryptoProvider.notifier).reset();

    expect((await db.doc('users/u1/notes/${secret.id}').get()).exists, isFalse);
    expect((await db.doc('users/u1/notes/${clear.id}').get()).exists, isTrue);
  });
}
