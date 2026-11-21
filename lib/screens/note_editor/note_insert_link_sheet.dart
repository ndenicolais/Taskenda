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
import '../../theme/app_spacing.dart';
import '../../utils/link_utils.dart';
import '../../widgets/shared/app_dialogs.dart';

/// Asks for a link's text and URL. Resolves to the Markdown link
/// (`[text](url)`) to insert, or `null` when cancelled. [initialText]
/// pre-fills the text field, e.g. with the current selection.
Future<String?> showInsertLinkSheet(
  BuildContext context, {
  String initialText = '',
}) {
  return showAppSheet<String>(
    context,
    isScrollControlled: true,
    builder: (_) => _InsertLinkSheet(initialText: initialText),
  );
}

class _InsertLinkSheet extends StatefulWidget {
  const _InsertLinkSheet({required this.initialText});

  final String initialText;

  @override
  State<_InsertLinkSheet> createState() => _InsertLinkSheetState();
}

class _InsertLinkSheetState extends State<_InsertLinkSheet> {
  late final _textController = TextEditingController(text: widget.initialText);
  final _urlController = TextEditingController();
  String? _urlError;

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = normalizeUrl(_urlController.text);
    if (url == null) {
      setState(() => _urlError = context.l10n.editorLinkInvalid);
      return;
    }
    Navigator.pop(context, buildMarkdownLink(_textController.text, url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormSheet(
      title: l10n.editorInsertLink,
      confirmLabel: l10n.editorLinkInsert,
      onConfirm: _submit,
      children: [
        TextField(
          controller: _textController,
          textCapitalization: TextCapitalization.sentences,
          autofocus: widget.initialText.isEmpty,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.editorLinkText),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _urlController,
          autofocus: widget.initialText.isNotEmpty,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.editorLinkAddress,
            hintText: 'https://...',
            errorText: _urlError,
          ),
          onChanged: (_) {
            if (_urlError != null) setState(() => _urlError = null);
          },
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
