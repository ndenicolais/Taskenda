// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Markdown style sheet of a note: every element (headings, lists, quotes,
/// code, links) uses the note's font and text color from [base], so the
/// formatted view matches the note instead of the app theme.
MarkdownStyleSheet noteMarkdownStyleSheet(TextStyle base) {
  final color = base.color ?? Colors.black;
  final size = base.fontSize ?? 14;
  TextStyle heading(double scale) => base.copyWith(
    fontSize: size * scale,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  return MarkdownStyleSheet(
    p: base,
    h1: heading(1.6),
    h2: heading(1.35),
    h3: heading(1.2),
    h4: heading(1.1),
    h5: heading(1),
    h6: heading(1),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    em: const TextStyle(fontStyle: FontStyle.italic),
    del: TextStyle(
      decoration: TextDecoration.lineThrough,
      decorationColor: color,
    ),
    a: TextStyle(
      color: color,
      decoration: TextDecoration.underline,
      decorationColor: color,
    ),
    listBullet: base,
    tableBody: base,
    tableHead: base.copyWith(fontWeight: FontWeight.bold),
    blockquote: base.copyWith(
      color: color.withAlpha(190),
      fontStyle: FontStyle.italic,
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: color.withAlpha(90), width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12),
    code: base.copyWith(
      fontFamily: 'monospace',
      fontSize: size * 0.9,
      backgroundColor: color.withAlpha(25),
    ),
    codeblockDecoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: color.withAlpha(70))),
    ),
    blockSpacing: size * 0.6,
  );
}
