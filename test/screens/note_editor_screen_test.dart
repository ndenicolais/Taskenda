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
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/models/note_model.dart';
import 'package:taskenda/providers/notes_provider.dart';
import 'package:taskenda/screens/note_editor/note_editor_screen.dart';
import 'package:taskenda/screens/note_editor/note_format_bar.dart';
import '../helpers/test_container.dart';

import '../helpers/l10n.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;
  late NotesNotifier notifier;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    container = createTestContainer(firestore);
    notifier = container.read(notesProvider.notifier);
  });

  Widget wrap(NoteModel note) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: testLocale,
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationsDelegates,
        home: Builder(
          builder:
              (context) => ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteEditorScreen(note: note),
                      ),
                    ),
                child: const Text('open'),
              ),
        ),
      ),
    );
  }

  testWidgets('renders the existing note title and content', (tester) async {
    final note = NoteModel(title: 'My note', content: 'Some content');
    await notifier.addNote(note);

    await tester.pumpWidget(wrap(note));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('My note'), findsOneWidget);
    expect(find.text('Some content'), findsOneWidget);
  });

  testWidgets('editing the title and leaving the screen saves the change', (
    tester,
  ) async {
    final note = NoteModel(title: 'Old title');
    await notifier.addNote(note);

    await tester.pumpWidget(wrap(note));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'New title');
    await tester.pump();

    Navigator.pop(tester.element(find.byType(NoteEditorScreen)));
    await tester.pumpAndSettle();

    expect(notifier.state.single.title, 'New title');
  });

  testWidgets('pinning the note from the overflow menu persists the change', (
    tester,
  ) async {
    final note = NoteModel(title: 'Pin me');
    await notifier.addNote(note);

    await tester.pumpWidget(wrap(note));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fissa'));
    await tester.pumpAndSettle();

    expect(notifier.state.single.isPinned, isTrue);
  });

  group('formatted content', () {
    Future<void> open(WidgetTester tester, String content) async {
      final note = NoteModel(title: 'T', content: content);
      await notifier.addNote(note);
      await tester.pumpWidget(wrap(note));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens as text; the toggle shows the preview and back', (
      tester,
    ) async {
      await open(tester, '**bold** text');
      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.text('**bold** text'), findsOneWidget);

      await tester.tap(find.byTooltip('Anteprima'));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownBody), findsOneWidget);
      // A tap on the preview no longer switches to the text.
      await tester.tap(find.byType(MarkdownBody));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownBody), findsOneWidget);

      await tester.tap(find.byTooltip('Modifica testo'));
      await tester.pumpAndSettle();
      expect(find.byType(MarkdownBody), findsNothing);
    });

    testWidgets('the formatting bar edits the text', (tester) async {
      await open(tester, '**bold** text');
      await tester.tap(find.byType(TextField).last);
      await tester.pumpAndSettle();
      expect(find.byType(NoteFormatBar), findsOneWidget);

      final field = tester.widget<TextField>(find.byType(TextField).last);
      field.controller!.selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 13,
      );
      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();
      expect(field.controller!.text, '**bold** _text_');
      expect(find.byType(NoteFormatBar), findsOneWidget);
    });

    testWidgets('an empty note opens in the editable field', (tester) async {
      await open(tester, '');
      expect(find.byType(MarkdownBody), findsNothing);
    });

    testWidgets('ticking a box in the formatted view saves it', (tester) async {
      await open(tester, '- [ ] one\n- [ ] two');
      await tester.tap(find.byTooltip('Anteprima'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      Navigator.pop(tester.element(find.byType(NoteEditorScreen)));
      await tester.pumpAndSettle();
      expect(notifier.state.single.content, '- [ ] one\n- [x] two');
    });
  });
}
