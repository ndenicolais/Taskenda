import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';
import 'package:taskenda/core/crypto/item_codec.dart';
import 'package:taskenda/models/calendar_model.dart';
import 'package:taskenda/models/note_model.dart';
import 'package:taskenda/models/task_model.dart';

void main() {
  final crypto = CryptoService();
  final codec = ItemCodec(crypto);

  /// [data] after a trip through JSON, like a Firestore document.
  Map<String, dynamic> stored(Map<String, dynamic> data) =>
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>;

  group('documents', () {
    test(
      'a note round-trips; its text is not readable in the document',
      () async {
        final key = await crypto.newSecretKey();
        final note = NoteModel(
          title: 'Diario segreto',
          content: 'Il mio contenuto privato',
          checklistItems: [ChecklistItem(text: 'voce privata')],
          isPinned: true,
          tags: ['l1'],
        );

        final doc = stored(
          await codec.encode(
            collection: 'notes',
            id: note.id,
            json: note.toJson(),
            contentKeys: ItemCodec.contentKeys(NoteModel.sharedKeys),
            privateKeys: const ['audioNotes'],
            key: key,
          ),
        );

        final raw = jsonEncode(doc);
        expect(raw, isNot(contains('segreto')));
        expect(raw, isNot(contains('privat')));
        expect(doc['e'], 1);
        expect(doc.containsKey('title'), isFalse);
        expect(doc.containsKey('audioNotes'), isFalse);
        // Personal fields and updatedAt stay in clear.
        expect(doc['isPinned'], isTrue);
        expect(doc['tags'], ['l1']);
        expect(doc['updatedAt'], note.toJson()['updatedAt']);

        final json = await codec.decode(
          collection: 'notes',
          id: note.id,
          data: doc,
          key: key,
        );
        expect(json, note.toJson());
        expect(NoteModel.fromJson(json).title, 'Diario segreto');
      },
    );

    test('a task and an event round-trip, optional fields included', () async {
      final key = await crypto.newSecretKey();
      final task = TaskModel(
        title: 'Task',
        description: 'desc',
        dueDate: DateTime(2026, 12, 1, 9),
      );
      final event = CalendarEventModel(
        title: 'Evento',
        location: 'Roma',
        startTime: DateTime(2026, 12, 1, 9),
        endTime: DateTime(2026, 12, 1, 10),
      );

      for (final (collection, id, json, shared) in [
        ('tasks', task.id, task.toJson(), TaskModel.sharedKeys),
        (
          'calendar_events',
          event.id,
          event.toJson(),
          CalendarEventModel.sharedKeys,
        ),
      ]) {
        final doc = stored(
          await codec.encode(
            collection: collection,
            id: id,
            json: json,
            contentKeys: ItemCodec.contentKeys(shared),
            key: key,
          ),
        );
        expect(doc.containsKey('priv'), isFalse);
        expect(
          await codec.decode(
            collection: collection,
            id: id,
            data: doc,
            key: key,
          ),
          json,
        );
      }
    });

    test(
      'sharing fields stay in clear, codec fields are dropped on decode',
      () async {
        final key = await crypto.newSecretKey();
        final doc = stored({
          ...await codec.encode(
            collection: 'notes',
            id: 'n1',
            json: {'id': 'n1', 'title': 't', 'updatedAt': 'u'},
            contentKeys: const ['title'],
            key: key,
          ),
          'ownerId': 'a',
          'collaborators': ['b'],
          'keys': {'a': <String, dynamic>{}},
          'keyVer': 2,
        });
        final json = await codec.decode(
          collection: 'notes',
          id: 'n1',
          data: doc,
          key: key,
        );
        expect(json, {
          'id': 'n1',
          'title': 't',
          'updatedAt': 'u',
          'ownerId': 'a',
          'collaborators': ['b'],
        });
      },
    );

    test('a document still in clear is returned unchanged', () async {
      final legacy = {'id': 'n1', 'title': 'vecchia'};
      expect(ItemCodec.isEncrypted(legacy), isFalse);
      expect(
        await codec.decode(
          collection: 'notes',
          id: 'n1',
          data: legacy,
          key: await crypto.newSecretKey(),
        ),
        legacy,
      );
    });

    test('content moved to another document can not be decrypted', () async {
      final key = await crypto.newSecretKey();
      final doc = stored(
        await codec.encode(
          collection: 'notes',
          id: 'n1',
          json: {'title': 't'},
          contentKeys: const ['title'],
          key: key,
        ),
      );
      expect(
        () => codec.decode(collection: 'notes', id: 'n2', data: doc, key: key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('a collaborator edit (encryptFields) is read by the owner', () async {
      final key = await crypto.newSecretKey();
      final base = stored(
        await codec.encode(
          collection: 'notes',
          id: 'n1',
          json: {'title': 'old', 'content': 'c', 'isPinned': true},
          contentKeys: const ['title', 'content'],
          key: key,
        ),
      );
      final edit = await codec.encryptFields(
        collection: 'notes',
        id: 'n1',
        json: {'title': 'new', 'content': 'c2', 'isPinned': false},
        keys: const ['title', 'content'],
        key: key,
      );
      final updated = stored({...base, 'enc': edit.toJson()});

      expect(
        await codec.decode(
          collection: 'notes',
          id: 'n1',
          data: updated,
          key: key,
        ),
        {'title': 'new', 'content': 'c2', 'isPinned': true},
      );
    });
  });

  group('item keys', () {
    test(
      'owner opens with the master key, collaborator with their key pair',
      () async {
        final itemKey = await crypto.newSecretKey();
        final ownerMaster = await crypto.newSecretKey();
        final ownerPair = await crypto.newKeyPair();
        final collabMaster = await crypto.newSecretKey();
        final collabPair = await crypto.newKeyPair();

        final doc = stored({
          'keys': {
            'owner': await codec.masterKeyEntryFor(
              collection: 'notes',
              id: 'n1',
              uid: 'owner',
              itemKey: itemKey,
              masterKey: ownerMaster,
            ),
            'collab': await codec.sealedKeyEntryFor(
              collection: 'notes',
              id: 'n1',
              uid: 'collab',
              itemKey: itemKey,
              publicKey: await crypto.publicKeyBytes(collabPair),
            ),
          },
        });

        Future<List<int>> open(String uid, master, pair) async =>
            (await codec.openItemKey(
              collection: 'notes',
              id: 'n1',
              uid: uid,
              data: doc,
              masterKey: master,
              keyPair: pair,
            )).extractBytes();

        final expected = await itemKey.extractBytes();
        expect(await open('owner', ownerMaster, ownerPair), expected);
        expect(await open('collab', collabMaster, collabPair), expected);
      },
    );

    test('a missing entry or someone else\'s entry fails', () async {
      final itemKey = await crypto.newSecretKey();
      final master = await crypto.newSecretKey();
      final pair = await crypto.newKeyPair();
      final doc = stored({
        'keys': {
          'owner': await codec.masterKeyEntryFor(
            collection: 'notes',
            id: 'n1',
            uid: 'owner',
            itemKey: itemKey,
            masterKey: master,
          ),
        },
      });

      expect(
        () => codec.openItemKey(
          collection: 'notes',
          id: 'n1',
          uid: 'stranger',
          data: doc,
          masterKey: master,
          keyPair: pair,
        ),
        throwsA(isA<CryptoException>()),
      );
      // The owner's entry copied under another uid: the AAD doesn't match.
      final stolen = stored({
        'keys': {'thief': (doc['keys'] as Map)['owner']},
      });
      expect(
        () => codec.openItemKey(
          collection: 'notes',
          id: 'n1',
          uid: 'thief',
          data: stolen,
          masterKey: master,
          keyPair: pair,
        ),
        throwsA(isA<CryptoException>()),
      );
    });
  });
}
