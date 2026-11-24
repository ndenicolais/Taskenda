import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/screens/note_editor/note_markdown_controller.dart';

void main() {
  /// The characters of [text] that have [flag], as a string.
  String withFlag(String text, int flag) {
    final flags = markdownLiveFlags(text);
    return [
      for (var i = 0; i < text.length; i++)
        if (flags[i] & flag != 0) text[i],
    ].join();
  }

  group('markdownLiveFlags', () {
    test('bold, italic and strikethrough with their markers', () {
      const text = 'a **bold** _it_ *em* ~~gone~~ __b__';
      expect(withFlag(text, MdFlag.bold), 'boldb');
      expect(withFlag(text, MdFlag.italic), 'item');
      expect(withFlag(text, MdFlag.strike), 'gone');
      expect(withFlag(text, MdFlag.marker), '****__**~~~~____');
    });

    test('underscores inside words are not italic', () {
      const text = 'snake_case_name and https://x.com/a_b_c';
      expect(withFlag(text, MdFlag.italic), '');
      expect(withFlag(text, MdFlag.marker), '');
    });

    test('headings: level, prefix hidden only with text', () {
      const text = '# Big\n## Mid\n#### Small\n## ';
      expect(withFlag(text, MdFlag.h1), '# Big');
      expect(withFlag(text, MdFlag.h2), '## Mid## ');
      expect(withFlag(text, MdFlag.h3), '#### Small');
      expect(withFlag(text, MdFlag.marker), '# ## #### ');
    });

    test('links show their text, code is left alone', () {
      const text = 'see [site](https://a.b) and `**no**`';
      expect(withFlag(text, MdFlag.link), 'site');
      expect(withFlag(text, MdFlag.code), '**no**');
      expect(withFlag(text, MdFlag.bold), '');
      expect(withFlag(text, MdFlag.marker), '[](https://a.b)``');
    });

    test('quotes and ticked tasks', () {
      const text = '> said\n- [x] done\n- [ ] todo';
      expect(withFlag(text, MdFlag.quote), 'said');
      expect(withFlag(text, MdFlag.done), 'done');
      expect(withFlag(text, MdFlag.marker), '> ');
    });
  });

  testWidgets('markers are hidden, and shown on the line being edited', (
    tester,
  ) async {
    final focus = FocusNode();
    final controller = NoteMarkdownController(
      text: '**a**\n**b**',
      focusNode: focus,
    );
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
            focusNode: focus,
            maxLines: null,
          ),
        ),
      ),
    );

    Color? colorOf(String run, int nth) {
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );
      return span.children!
          .cast<TextSpan>()
          .where((s) => s.text == run)
          .elementAt(nth)
          .style
          ?.color;
    }

    expect(colorOf('**', 0), Colors.transparent);
    focus.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    // First line edited: its markers show, the second line's stay hidden.
    expect(colorOf('**', 0), isNot(Colors.transparent));
    expect(colorOf('**', 2), Colors.transparent);
  });
}
