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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../../providers/crypto_provider.dart';
import '../../theme/app_spacing.dart';
import 'crypto_widgets.dart';

/// Shows a new recovery key once (after setup or recovery): the user must
/// confirm they saved it before going on.
class RecoveryKeyScreen extends ConsumerStatefulWidget {
  const RecoveryKeyScreen({super.key, required this.recoveryKey});

  /// As text, e.g. `ABCD-EFGH-…`.
  final String recoveryKey;

  @override
  ConsumerState<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends ConsumerState<RecoveryKeyScreen> {
  bool _saved = false;

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.cryptoRecoveryCopied;
    await Clipboard.setData(ClipboardData(text: widget.recoveryKey));
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _share() => SharePlus.instance.share(
    ShareParams(text: widget.recoveryKey, subject: 'Taskenda'),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return CryptoScaffold(
      icon: Icons.key_outlined,
      title: l10n.cryptoRecoveryShowTitle,
      message: l10n.cryptoRecoveryShowBody,
      showSignOut: false,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            widget.recoveryKey,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.cryptoRecoveryCopy),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.commonShare),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        CheckboxListTile(
          value: _saved,
          onChanged: (v) => setState(() => _saved = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.cryptoRecoverySavedCheck),
        ),
        const SizedBox(height: AppSpacing.md),
        CryptoSubmitButton(
          label: l10n.cryptoContinue,
          onPressed:
              _saved
                  ? () =>
                      ref.read(cryptoProvider.notifier).acknowledgeRecoveryKey()
                  : null,
        ),
      ],
    );
  }
}
