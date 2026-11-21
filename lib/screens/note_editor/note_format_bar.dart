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
import '../../l10n/l10n.dart';
import '../../utils/markdown_format.dart';

/// Formatting buttons shown above the keyboard while the note content is
/// being edited. Each one applies Markdown to the selection of
/// [controller]; [onChanged] then commits the new text. Counts as part of
/// the text field for taps, so pressing a button keeps the keyboard open.
class NoteFormatBar extends StatelessWidget {
  const NoteFormatBar({
    super.key,
    required this.controller,
    required this.color,
    required this.background,
    required this.onChanged,
    required this.onInsertLink,
  });

  final TextEditingController controller;

  /// Icon color, readable on [background].
  final Color color;
  final Color background;
  final VoidCallback onChanged;
  final VoidCallback onInsertLink;

  void _apply(TextEditingValue Function(TextEditingValue) edit) {
    controller.value = edit(controller.value);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget button(IconData icon, String tooltip, VoidCallback onPressed) =>
        IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          color: color,
          onPressed: onPressed,
        );
    return TextFieldTapRegion(
      child: Material(
        color: background,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color.withAlpha(40))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                button(
                  Icons.format_bold,
                  l10n.commonBold,
                  () => _apply((v) => toggleInlineFormat(v, InlineFormat.bold)),
                ),
                button(
                  Icons.format_italic,
                  l10n.commonItalic,
                  () =>
                      _apply((v) => toggleInlineFormat(v, InlineFormat.italic)),
                ),
                button(
                  Icons.format_strikethrough,
                  l10n.styleStrikethrough,
                  () => _apply(
                    (v) => toggleInlineFormat(v, InlineFormat.strikethrough),
                  ),
                ),
                button(
                  Icons.title,
                  l10n.editorFormatHeading,
                  () => _apply((v) => toggleLineFormat(v, LineFormat.heading)),
                ),
                button(
                  Icons.format_list_bulleted,
                  l10n.editorFormatBulleted,
                  () => _apply((v) => toggleLineFormat(v, LineFormat.bulleted)),
                ),
                button(
                  Icons.format_list_numbered,
                  l10n.editorFormatNumbered,
                  () => _apply((v) => toggleLineFormat(v, LineFormat.numbered)),
                ),
                button(
                  Icons.check_box_outlined,
                  l10n.editorFormatCheckbox,
                  () => _apply((v) => toggleLineFormat(v, LineFormat.checkbox)),
                ),
                button(Icons.add_link, l10n.editorInsertLink, onInsertLink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
