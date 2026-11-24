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
import 'package:taskenda/models/note_model.dart';
import 'package:taskenda/models/share_member.dart';
import 'package:taskenda/providers/notes_provider.dart';
import 'package:taskenda/providers/shared_items.dart';
import 'package:taskenda/providers/sharing_provider.dart';
import '../helpers/test_container.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer alice;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    alice = createTestContainer(firestore, uid: 'alice');
    // Bob signed in once: he is in the directory.
    await firestore.doc('user_directory/bob@example.com').set({
      'uid': 'bob',
      'email': 'bob@example.com',
      'name': 'Bob',
    });
  });

  Future<Map<String, dynamic>> aliceDoc(String id) async =>
      (await firestore.doc('users/alice/notes/$id').get()).data()!;

  /// The notes Alice shared with a user, as a plain collection query: the
  /// fake Firestore doesn't stream collection-group changes.
  Override aliceSharedQuery() => sharedWithMeQueryProvider.overrideWithValue(
    (collection, uid) => firestore
        .collection('users/alice/$collection')
        .where('collaborators', arrayContains: uid),
  );

  /// Bob's view, loaded from Firestore like after a sign-in.
  Future<ProviderContainer> bobContainer() async {
    final bob = createTestContainer(
      firestore,
      uid: 'bob',
      overrides: [aliceSharedQuery()],
    );
    bob.read(notesProvider);
    await bob.read(notesProvider.notifier).initialLoad;
    return bob;
  }

  Future<NoteModel> sharedNote() async {
    final note = NoteModel(title: 'Spesa', isPinned: true, tags: ['Casa']);
    await alice.read(notesProvider.notifier).addNote(note);
    await alice
        .read(notesProvider.notifier)
        .addCollaborator(note.id, ' Bob@Example.com ');
    return note;
  }

  group('UserDirectory', () {
    test('register stores the entry under the lowercase email', () async {
      await alice
          .read(userDirectoryProvider)
          .register(
            const ShareMember(uid: 'alice', email: 'Alice@Example.com'),
          );
      final data =
          (await firestore.doc('user_directory/alice@example.com').get())
              .data();
      expect(data!['uid'], 'alice');
    });

    test('lookup returns null for an unknown email', () async {
      final found = await alice
          .read(userDirectoryProvider)
          .lookup('nobody@example.com');
      expect(found, isNull);
    });
  });

  group('owner', () {
    test('addCollaborator stores uid and profile on the note', () async {
      final note = await sharedNote();

      final data = await aliceDoc(note.id);
      expect(data['ownerId'], 'alice');
      expect(data['collaborators'], ['bob']);
      expect(data['collaboratorProfiles']['bob']['name'], 'Bob');
      final inState = alice.read(notesProvider).single;
      expect(inState.collaborators.single.uid, 'bob');
      expect(inState.isShared, isTrue);
    });

    test('refuses unknown emails, self and duplicates', () async {
      final note = await sharedNote();
      final notifier = alice.read(notesProvider.notifier);

      Future<ShareError?> errorFor(String email) async {
        try {
          await notifier.addCollaborator(note.id, email);
          return null;
        } on ShareException catch (e) {
          return e.error;
        }
      }

      expect(await errorFor('nobody@example.com'), ShareError.notFound);
      expect(await errorFor('alice@example.com'), ShareError.self);
      expect(await errorFor('bob@example.com'), ShareError.alreadyAdded);
    });

    test('an edit from a stale copy keeps the collaborators', () async {
      final note = await sharedNote();
      // The editor's copy predates the sharing.
      await alice
          .read(notesProvider.notifier)
          .updateNote(note.copyWith(title: 'Spesa sabato'));

      final data = await aliceDoc(note.id);
      expect(data['title'], 'Spesa sabato');
      expect(data['collaborators'], ['bob']);
      expect(alice.read(notesProvider).single.isShared, isTrue);
    });

    test('removeCollaborator unshares the note', () async {
      final note = await sharedNote();
      await alice
          .read(notesProvider.notifier)
          .removeCollaborator(note.id, 'bob');

      final data = await aliceDoc(note.id);
      expect(data['collaborators'], isEmpty);
      expect((data['collaboratorProfiles'] as Map).containsKey('bob'), false);
      final bob = await bobContainer();
      expect(bob.read(notesProvider), isEmpty);
    });

    test('backups leave out shared notes and sharing fields', () async {
      final note = await sharedNote();
      final bob = await bobContainer();
      await bob.read(notesProvider.notifier).addNote(NoteModel(title: 'Mia'));

      final own = bob.read(ownNotesProvider);
      expect(own.map((n) => n.title), ['Mia']);
      expect(note.toJson().containsKey('collaborators'), isFalse);
    });
  });

  group('collaborator', () {
    test('sees the shared note without the owner personal fields', () async {
      final note = await sharedNote();
      final bob = await bobContainer();

      final seen = bob.read(notesProvider).single;
      expect(seen.id, note.id);
      expect(seen.title, 'Spesa');
      expect(seen.isForeignTo('bob'), isTrue);
      expect(seen.isPinned, isFalse);
      expect(seen.tags, isEmpty);
      expect(seen.owner?.uid, 'alice');
    });

    test('content edits reach the owner, personal ones stay his', () async {
      final note = await sharedNote();
      final bob = await bobContainer();
      final seen = bob.read(notesProvider).single;

      await bob
          .read(notesProvider.notifier)
          .updateNote(seen.copyWith(title: 'Spesa grande', isArchived: true));

      final data = await aliceDoc(note.id);
      expect(data['title'], 'Spesa grande');
      expect(data['isArchived'], isFalse);
      expect(data['isPinned'], isTrue);
      final prefs =
          (await firestore.doc('users/bob/shared_note_prefs/${note.id}').get())
              .data();
      expect(prefs!['isArchived'], isTrue);
      // Nothing copied into Bob's own notes.
      final copy = await firestore.doc('users/bob/notes/${note.id}').get();
      expect(copy.exists, isFalse);

      // Reloaded, Bob keeps his archive flag.
      final again = await bobContainer();
      expect(again.read(notesProvider).single.isArchived, isTrue);
    });

    test('deleting for good leaves the note instead', () async {
      final note = await sharedNote();
      final bob = await bobContainer();
      final notifier = bob.read(notesProvider.notifier);

      await notifier.softDelete(note.id);
      expect((await aliceDoc(note.id))['deletedAt'], isNull);
      await notifier.permanentlyDelete(note.id);

      expect(bob.read(notesProvider), isEmpty);
      final data = await aliceDoc(note.id);
      expect(data['title'], 'Spesa');
      expect(data['collaborators'], isEmpty);
    });

    test('a note trashed by the owner disappears', () async {
      final note = await sharedNote();
      await alice.read(notesProvider.notifier).softDelete(note.id);

      final bob = await bobContainer();
      expect(bob.read(notesProvider), isEmpty);
      expect((await aliceDoc(note.id))['collaborators'], ['bob']);
    });

    test('clearAll and restore leave shared notes alone', () async {
      await sharedNote();
      final bob = await bobContainer();
      final notifier = bob.read(notesProvider.notifier);

      await notifier.replaceAll([NoteModel(title: 'Dal backup')]);
      expect(bob.read(notesProvider).map((n) => n.title).toSet(), {
        'Dal backup',
        'Spesa',
      });

      await notifier.clearAll();
      expect(bob.read(notesProvider).single.title, 'Spesa');
    });
  });

  group('live updates', () {
    test('the collaborator sees owner edits and new shares', () async {
      final note = await sharedNote();
      final bob = await bobContainer();

      await alice
          .read(notesProvider.notifier)
          .updateNote(note.copyWith(title: 'Spesa sabato'));
      final second = NoteModel(title: 'Viaggio');
      await alice.read(notesProvider.notifier).addNote(second);
      await alice
          .read(notesProvider.notifier)
          .addCollaborator(second.id, 'bob@example.com');
      await pumpEventQueue();

      final titles = bob.read(notesProvider).map((n) => n.title).toSet();
      expect(titles, {'Spesa sabato', 'Viaggio'});
    });

    test('the collaborator keeps his personal fields on an edit', () async {
      final note = await sharedNote();
      final bob = await bobContainer();
      final seen = bob.read(notesProvider).single;
      await bob
          .read(notesProvider.notifier)
          .updateNote(seen.copyWith(isPinned: true));

      await alice
          .read(notesProvider.notifier)
          .updateNote(note.copyWith(title: 'Spesa grande'));
      await pumpEventQueue();

      final live = bob.read(notesProvider).single;
      expect(live.title, 'Spesa grande');
      expect(live.isPinned, isTrue);
    });

    test('the owner sees collaborator edits', () async {
      await alice.read(notesProvider.notifier).initialLoad;
      final note = await sharedNote();
      final bob = await bobContainer();

      await bob
          .read(notesProvider.notifier)
          .updateNote(bob.read(notesProvider).single.copyWith(title: 'Da Bob'));
      await pumpEventQueue();

      final live = alice.read(notesProvider).single;
      expect(live.id, note.id);
      expect(live.title, 'Da Bob');
      expect(live.isPinned, isTrue);
    });

    test('unsharing removes the note from the collaborator', () async {
      final note = await sharedNote();
      final bob = await bobContainer();

      await alice
          .read(notesProvider.notifier)
          .removeCollaborator(note.id, 'bob');
      await pumpEventQueue();

      expect(bob.read(notesProvider), isEmpty);
    });

    test('a note no longer shared stays for the owner after an edit', () async {
      await alice.read(notesProvider.notifier).initialLoad;
      final note = await sharedNote();
      final notifier = alice.read(notesProvider.notifier);
      await notifier.removeCollaborator(note.id, 'bob');
      await pumpEventQueue();

      // Saved as a plain note: it leaves the live query of shared notes.
      await notifier.updateNote(
        alice.read(notesProvider).single.copyWith(title: 'Dopo'),
      );
      await pumpEventQueue();

      expect(alice.read(notesProvider).single.title, 'Dopo');
    });
  });
}
