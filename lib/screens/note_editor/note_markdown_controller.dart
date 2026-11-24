// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Formatting of one character of a note's Markdown text, as bit flags
/// (see [markdownLiveFlags]).
abstract final class MdFlag {
  static const bold = 1;
  static const italic = 2;
  static const strike = 4;
  static const code = 8;
  static const link = 16;

  /// Markdown syntax (`**`, `_`, `## `, `](url)`…): hidden, or dimmed on
  /// the line being edited.
  static const marker = 32;
  static const h1 = 64;
  static const h2 = 128;

  /// Headings of level 3 to 6.
  static const h3 = 256;
  static const quote = 512;

  /// The text of a ticked task line (`- [x] …`).
  static const done = 1024;
}

final _prefix = RegExp(r'^(\s*)(#{1,6} |[-*+] \[[ xX]\] |> )?');
final _code = RegExp(r'`([^`\n]+)`');
final _link = RegExp(r'\[([^\]\n]+)\]\(([^)\s]+)\)');
final _inline = <(RegExp, int)>[
  (RegExp(r'\*\*(?=\S)(.+?)(?<=\S)\*\*'), MdFlag.bold),
  (RegExp(r'__(?=\S)(.+?)(?<=\S)__'), MdFlag.bold),
  (RegExp(r'~~(?=\S)(.+?)(?<=\S)~~'), MdFlag.strike),
  (RegExp(r'(?<![*\w])\*(?=[^\s*])(.+?)(?<=[^\s*])\*(?![*\w])'), MdFlag.italic),
  (RegExp(r'(?<![_\w])_(?=[^\s_])(.+?)(?<=[^\s_])_(?![_\w])'), MdFlag.italic),
];

/// The [MdFlag]s of every character of [text]: headings, quotes and
/// ticked tasks per line; code, links, bold, italic and strikethrough
/// inside a line, with their syntax marked as [MdFlag.marker]. Nothing
/// inside inline code is formatted further.
Uint16List markdownLiveFlags(String text) {
  final flags = Uint16List(text.length);
  var lineStart = 0;
  while (lineStart <= text.length) {
    var lineEnd = text.indexOf('\n', lineStart);
    if (lineEnd < 0) lineEnd = text.length;
    _flagLine(text.substring(lineStart, lineEnd), flags, lineStart);
    lineStart = lineEnd + 1;
  }
  return flags;
}

void _flagLine(String line, Uint16List flags, int offset) {
  void mark(int start, int end, int flag) {
    for (var i = start; i < end; i++) {
      flags[offset + i] |= flag;
    }
  }

  final prefix = _prefix.firstMatch(line)!;
  final syntax = prefix.group(2);
  final contentStart = prefix.end;
  final hasContent = line.substring(contentStart).trim().isNotEmpty;
  if (syntax != null && syntax.startsWith('#')) {
    final level = syntax.length - 1;
    mark(
      0,
      line.length,
      level == 1
          ? MdFlag.h1
          : level == 2
          ? MdFlag.h2
          : MdFlag.h3,
    );
    // A heading still empty keeps its "## ": hidden, the line would vanish.
    if (hasContent) mark(prefix.start, contentStart, MdFlag.marker);
  } else if (syntax == '> ') {
    mark(contentStart, line.length, MdFlag.quote);
    if (hasContent) mark(prefix.start, contentStart, MdFlag.marker);
  } else if (syntax != null && !syntax.contains('[ ]')) {
    // A ticked task: the box stays, the text is struck through.
    mark(contentStart, line.length, MdFlag.done);
  }

  // Inline code first: its text is left as written.
  final codeRanges = <(int, int)>[];
  for (final m in _code.allMatches(line, contentStart)) {
    codeRanges.add((m.start, m.end));
    mark(m.start, m.start + 1, MdFlag.marker);
    mark(m.start + 1, m.end - 1, MdFlag.code);
    mark(m.end - 1, m.end, MdFlag.marker);
  }
  bool inCode(int start, int end) =>
      codeRanges.any((r) => start < r.$2 && end > r.$1);

  for (final m in _link.allMatches(line, contentStart)) {
    if (inCode(m.start, m.end)) continue;
    final textEnd = m.start + 1 + m.group(1)!.length;
    mark(m.start, m.start + 1, MdFlag.marker);
    mark(m.start + 1, textEnd, MdFlag.link);
    mark(textEnd, m.end, MdFlag.marker);
  }

  for (final (pattern, flag) in _inline) {
    for (final m in pattern.allMatches(line, contentStart)) {
      if (inCode(m.start, m.end)) continue;
      final width = (m.end - m.start - m.group(1)!.length) ~/ 2;
      // Its markers already belong to another format (`***`, a link).
      if (flags[offset + m.start] & MdFlag.marker != 0 ||
          flags[offset + m.end - 1] & MdFlag.marker != 0) {
        continue;
      }
      mark(m.start, m.start + width, MdFlag.marker);
      mark(m.start + width, m.end - width, flag);
      mark(m.end - width, m.end, MdFlag.marker);
    }
  }
}

/// Controller of a note's text that shows its Markdown already formatted
/// while editing (bold, italic, strikethrough, headings, quotes, code,
/// links, ticked tasks) instead of the raw `**`, `_`, `#`. The syntax is
/// hidden, except on the lines the cursor or selection is on while
/// [focusNode] has focus: there it shows dimmed, so it can be edited.
/// The text itself stays plain Markdown.
class NoteMarkdownController extends TextEditingController {
  NoteMarkdownController({super.text, this.focusNode});

  FocusNode? focusNode;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final text = this.text;
    if (text.isEmpty) return TextSpan(style: base, text: text);

    final flags = markdownLiveFlags(text);
    final (activeStart, activeEnd) = _activeRange(text);
    final composing =
        withComposing && value.isComposingRangeValid ? value.composing : null;

    final children = <TextSpan>[];
    var runStart = 0;
    int keyAt(int i) {
      var key = flags[i];
      // Markers show only on the active lines.
      if (key & MdFlag.marker != 0 && (i >= activeStart && i < activeEnd)) {
        key |= 1 << 14;
      }
      if (composing != null && i >= composing.start && i < composing.end) {
        key |= 1 << 15;
      }
      return key;
    }

    var runKey = keyAt(0);
    for (var i = 1; i <= text.length; i++) {
      final key = i < text.length ? keyAt(i) : -1;
      if (key == runKey) continue;
      children.add(
        TextSpan(
          text: text.substring(runStart, i),
          style: _styleFor(runKey, base),
        ),
      );
      runStart = i;
      runKey = key;
    }
    return TextSpan(style: base, children: children);
  }

  /// The text range of the lines touched by the selection, while editing.
  (int, int) _activeRange(String text) {
    final sel = selection;
    if (!(focusNode?.hasFocus ?? false) ||
        !sel.isValid ||
        sel.end > text.length) {
      return (0, 0);
    }
    final start =
        sel.start == 0 ? 0 : text.lastIndexOf('\n', sel.start - 1) + 1;
    var end = text.indexOf('\n', sel.end);
    if (end < 0) end = text.length;
    return (start, end);
  }

  TextStyle _styleFor(int key, TextStyle base) {
    final color = base.color ?? Colors.black;
    final size = base.fontSize ?? 16;
    var s = base;
    if (key & MdFlag.h1 != 0) {
      s = s.copyWith(fontSize: size * 1.6, fontWeight: FontWeight.bold);
    } else if (key & MdFlag.h2 != 0) {
      s = s.copyWith(fontSize: size * 1.35, fontWeight: FontWeight.bold);
    } else if (key & MdFlag.h3 != 0) {
      s = s.copyWith(fontSize: size * 1.2, fontWeight: FontWeight.bold);
    }
    if (key & MdFlag.bold != 0) s = s.copyWith(fontWeight: FontWeight.bold);
    if (key & (MdFlag.italic | MdFlag.quote) != 0) {
      s = s.copyWith(fontStyle: FontStyle.italic);
    }
    if (key & (MdFlag.quote | MdFlag.done) != 0) {
      s = s.copyWith(color: color.withAlpha(170));
    }
    if (key & MdFlag.code != 0) {
      s = s.copyWith(
        fontFamily: 'monospace',
        backgroundColor: color.withAlpha(25),
      );
    }
    final decorations = [
      if (key & (MdFlag.strike | MdFlag.done) != 0) TextDecoration.lineThrough,
      if (key & MdFlag.link != 0) TextDecoration.underline,
      if (key & (1 << 15) != 0) TextDecoration.underline,
    ];
    if (decorations.isNotEmpty) {
      s = s.copyWith(
        decoration: TextDecoration.combine(decorations),
        decorationColor: s.color,
      );
    }
    if (key & MdFlag.marker != 0) {
      s =
          key & (1 << 14) != 0
              // Being edited: shown, dimmed.
              ? s.copyWith(
                color: color.withAlpha(110),
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.normal,
                decoration: TextDecoration.none,
              )
              // Hidden: still in the text (the cursor steps over it).
              : s.copyWith(
                color: Colors.transparent,
                fontSize: 0.1,
                letterSpacing: 0,
                decoration: TextDecoration.none,
                backgroundColor: Colors.transparent,
              );
    }
    return s;
  }
}
