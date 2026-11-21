// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/services.dart';

/// Inline Markdown markers applied by the note formatting bar.
enum InlineFormat {
  bold('**'),
  italic('_'),
  strikethrough('~~');

  const InlineFormat(this.marker);
  final String marker;
}

/// Line-level Markdown formats applied by the note formatting bar.
enum LineFormat { heading, bulleted, numbered, checkbox }

/// Every list or heading prefix a line can start with (indent kept apart).
final RegExp _linePrefix = RegExp(
  r'^(\s*)(#{1,6} |[-*+] \[[ xX]\] |[-*+] |\d+[.)] )?',
);

/// A task-list marker (`- [ ]`, `* [x]`, …) at the start of a line.
final RegExp _taskMarker = RegExp(
  r'^(\s*[-*+] \[)([ xX])(\] )',
  multiLine: true,
);

/// Wraps the selection in [format]'s marker, or removes it when the
/// selection is already wrapped (markers inside or right around it). An
/// empty selection inserts the pair with the cursor in between. An invalid
/// selection works at the end of the text.
TextEditingValue toggleInlineFormat(
  TextEditingValue value,
  InlineFormat format,
) {
  final m = format.marker;
  final text = value.text;
  final sel = _validSelection(value);
  final selected = text.substring(sel.start, sel.end);

  // Markers included in the selection: `**word**` selected.
  if (selected.length >= 2 * m.length &&
      selected.startsWith(m) &&
      selected.endsWith(m)) {
    final inner = selected.substring(m.length, selected.length - m.length);
    return TextEditingValue(
      text: text.replaceRange(sel.start, sel.end, inner),
      selection: TextSelection(
        baseOffset: sel.start,
        extentOffset: sel.start + inner.length,
      ),
    );
  }
  // Markers right around the selection: `word` selected in `**word**`.
  if (sel.start >= m.length &&
      sel.end + m.length <= text.length &&
      text.substring(sel.start - m.length, sel.start) == m &&
      text.substring(sel.end, sel.end + m.length) == m) {
    final newText = text
        .replaceRange(sel.end, sel.end + m.length, '')
        .replaceRange(sel.start - m.length, sel.start, '');
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start - m.length,
        extentOffset: sel.end - m.length,
      ),
    );
  }
  return TextEditingValue(
    text: text.replaceRange(sel.start, sel.end, '$m$selected$m'),
    selection: TextSelection(
      baseOffset: sel.start + m.length,
      extentOffset: sel.end + m.length,
    ),
  );
}

/// Applies [format] to every line touched by the selection: when all of
/// them already have it, it is removed; otherwise each line gets it,
/// replacing any other heading or list prefix. Numbered lines count up
/// from 1. The selection then spans the edited lines (a cursor stays a
/// cursor, at the end of its line).
TextEditingValue toggleLineFormat(TextEditingValue value, LineFormat format) {
  final text = value.text;
  final sel = _validSelection(value);
  final blockStart =
      sel.start == 0 ? 0 : text.lastIndexOf('\n', sel.start - 1) + 1;
  var blockEnd = text.indexOf('\n', sel.end);
  if (blockEnd < 0) blockEnd = text.length;

  final lines = text.substring(blockStart, blockEnd).split('\n');
  final remove = lines.every((l) => _hasFormat(l, format));
  var n = 0;
  final edited = [
    for (final line in lines)
      () {
        final match = _linePrefix.firstMatch(line)!;
        final indent = match.group(1)!;
        final body = line.substring(match.end);
        if (remove) return '$indent$body';
        n++;
        return '$indent${_prefixFor(format, n)}$body';
      }(),
  ].join('\n');

  final newText = text.replaceRange(blockStart, blockEnd, edited);
  final end = blockStart + edited.length;
  return TextEditingValue(
    text: newText,
    selection:
        sel.isCollapsed
            ? TextSelection.collapsed(offset: end)
            : TextSelection(baseOffset: blockStart, extentOffset: end),
  );
}

/// Ticks or unticks the task-list item number [index] (0-based, in text
/// order). Returns [text] unchanged when there is no such item.
String toggleTaskItem(String text, int index) {
  final matches = _taskMarker.allMatches(text).toList();
  if (index < 0 || index >= matches.length) return text;
  final m = matches[index];
  final checked = m.group(2) != ' ';
  final markStart = m.start + m.group(1)!.length;
  return text.replaceRange(markStart, markStart + 1, checked ? ' ' : 'x');
}

bool _hasFormat(String line, LineFormat format) {
  final prefix = _linePrefix.firstMatch(line)!.group(2) ?? '';
  return switch (format) {
    LineFormat.heading => prefix.startsWith('#'),
    LineFormat.checkbox => prefix.contains('['),
    LineFormat.bulleted => RegExp(r'^[-*+] $').hasMatch(prefix),
    LineFormat.numbered => RegExp(r'^\d').hasMatch(prefix),
  };
}

String _prefixFor(LineFormat format, int n) => switch (format) {
  LineFormat.heading => '## ',
  LineFormat.bulleted => '- ',
  LineFormat.numbered => '$n. ',
  LineFormat.checkbox => '- [ ] ',
};

TextSelection _validSelection(TextEditingValue value) {
  final sel = value.selection;
  final len = value.text.length;
  if (!sel.isValid || sel.start > len || sel.end > len) {
    return TextSelection.collapsed(offset: len);
  }
  return TextSelection(baseOffset: sel.start, extentOffset: sel.end);
}
