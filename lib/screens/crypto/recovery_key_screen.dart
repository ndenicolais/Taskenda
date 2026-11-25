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

/// Right after setup: proposes to create a recovery key, the only way back
/// in if the passkey is lost. "Later" goes to the app (it can be created
/// from Settings → Security).
class RecoveryKeyOfferScreen extends ConsumerStatefulWidget {
  const RecoveryKeyOfferScreen({super.key});

  @override
  ConsumerState<RecoveryKeyOfferScreen> createState() =>
      _RecoveryKeyOfferScreenState();
}

class _RecoveryKeyOfferScreenState
    extends ConsumerState<RecoveryKeyOfferScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(cryptoProvider.notifier).createFirstRecoveryKey();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cryptoErrorMessage(l10n, e, wrongKey: l10n.commonGenericError);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CryptoScaffold(
      icon: Icons.key_outlined,
      title: l10n.cryptoRecoveryOfferTitle,
      message: l10n.cryptoRecoveryOfferBody,
      showSignOut: false,
      children: [
        if (_error != null) CryptoErrorText(_error!),
        CryptoSubmitButton(
          label: l10n.cryptoRecoveryOfferCreate,
          onPressed: _create,
          busy: _busy,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed:
              _busy
                  ? null
                  : () =>
                      ref
                          .read(cryptoProvider.notifier)
                          .acknowledgeRecoveryKey(),
          child: Text(l10n.cryptoRecoveryOfferLater),
        ),
      ],
    );
  }
}

/// Shows a new recovery key once: the user must confirm they saved it
/// before going on.
class RecoveryKeyScreen extends ConsumerWidget {
  const RecoveryKeyScreen({super.key, required this.recoveryKey});

  /// As text, e.g. `ABCD-EFGH-…`.
  final String recoveryKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return CryptoScaffold(
      icon: Icons.key_outlined,
      title: l10n.cryptoRecoveryShowTitle,
      message: l10n.cryptoRecoveryShowBody,
      showSignOut: false,
      children: [
        RecoveryKeyPanel(
          recoveryKey: recoveryKey,
          doneLabel: l10n.cryptoContinue,
          onDone:
              () => ref.read(cryptoProvider.notifier).acknowledgeRecoveryKey(),
        ),
      ],
    );
  }
}

/// A new recovery key from the settings, in a dialog that can only be
/// closed once the user confirms they saved it.
Future<void> showRecoveryKeyDialog(BuildContext context, String recoveryKey) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l10n = ctx.l10n;
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l10n.cryptoRecoveryShowTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.cryptoRecoveryShowBody),
                const SizedBox(height: AppSpacing.lg),
                RecoveryKeyPanel(
                  recoveryKey: recoveryKey,
                  doneLabel: l10n.commonDone,
                  onDone: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The recovery key with copy and share buttons, the "I saved it" checkbox
/// and a button enabled only once it is ticked.
class RecoveryKeyPanel extends StatefulWidget {
  const RecoveryKeyPanel({
    super.key,
    required this.recoveryKey,
    required this.doneLabel,
    required this.onDone,
  });

  final String recoveryKey;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  State<RecoveryKeyPanel> createState() => _RecoveryKeyPanelState();
}

class _RecoveryKeyPanelState extends State<RecoveryKeyPanel> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.cryptoRecoveryCopy),
            ),
            OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.commonShare),
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
          label: widget.doneLabel,
          onPressed: _saved ? widget.onDone : null,
        ),
      ],
    );
  }
}
