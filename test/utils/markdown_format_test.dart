// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/utils/markdown_format.dart';

TextEditingValue _v(String text, int start, [int? end]) => TextEditingValue(
  text: text,
  selection: TextSelection(baseOffset: start, extentOffset: end ?? start),
);

void main() {
  group('toggleInlineFormat', () {
    test('wraps the selection and keeps it selected', () {
      final r = toggleInlineFormat(_v('a word b', 2, 6), InlineFormat.bold);
      expect(r.text, 'a **word** b');
      expect(r.selection, const TextSelection(baseOffset: 4, extentOffset: 8));
    });

    test('unwraps when the markers are around or inside the selection', () {
      final around = toggleInlineFormat(
        _v('a **word** b', 4, 8),
        InlineFormat.bold,
      );
      expect(around.text, 'a word b');
      expect(around.selection.textInside(around.text), 'word');

      final inside = toggleInlineFormat(
        _v('a ~~word~~ b', 2, 10),
        InlineFormat.strikethrough,
      );
      expect(inside.text, 'a word b');
      expect(inside.selection.textInside(inside.text), 'word');
    });

    test('a cursor inserts the pair with the cursor in between', () {
      final r = toggleInlineFormat(_v('ab', 1), InlineFormat.italic);
      expect(r.text, 'a__b');
      expect(r.selection, const TextSelection.collapsed(offset: 2));
    });

    test('an invalid selection works at the end', () {
      const value = TextEditingValue(text: 'ab');
      final r = toggleInlineFormat(value, InlineFormat.bold);
      expect(r.text, 'ab****');
      expect(r.selection, const TextSelection.collapsed(offset: 4));
    });
  });

  group('toggleLineFormat', () {
    test('adds the prefix to the cursor line', () {
      final r = toggleLineFormat(_v('one\ntwo', 5), LineFormat.bulleted);
      expect(r.text, 'one\n- two');
      expect(r.selection, const TextSelection.collapsed(offset: 9));
    });

    test('numbers every selected line and removes when all have it', () {
      final on = toggleLineFormat(_v('a\nb\nc', 0, 5), LineFormat.numbered);
      expect(on.text, '1. a\n2. b\n3. c');
      final off = toggleLineFormat(on, LineFormat.numbered);
      expect(off.text, 'a\nb\nc');
    });

    test('replaces another list or heading prefix', () {
      final r = toggleLineFormat(_v('- item', 3), LineFormat.checkbox);
      expect(r.text, '- [ ] item');
      final h = toggleLineFormat(_v('1. item', 0), LineFormat.heading);
      expect(h.text, '## item');
    });

    test('a checkbox line is not a bulleted line', () {
      final r = toggleLineFormat(_v('- [ ] item', 0), LineFormat.bulleted);
      expect(r.text, '- item');
    });

    test('keeps the indent', () {
      final r = toggleLineFormat(_v('  - item', 0), LineFormat.numbered);
      expect(r.text, '  1. item');
    });
  });

  group('toggleTaskItem', () {
    const text = 'x\n- [ ] one\n- [x] two\n* [ ] three';

    test('ticks and unticks the item at the index', () {
      expect(toggleTaskItem(text, 0), 'x\n- [x] one\n- [x] two\n* [ ] three');
      expect(toggleTaskItem(text, 1), 'x\n- [ ] one\n- [ ] two\n* [ ] three');
      expect(toggleTaskItem(text, 2), 'x\n- [ ] one\n- [x] two\n* [x] three');
    });

    test('leaves the text alone for a missing index', () {
      expect(toggleTaskItem(text, 3), text);
      expect(toggleTaskItem('no tasks', 0), 'no tasks');
    });
  });
}
