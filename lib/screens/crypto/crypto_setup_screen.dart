// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/crypto_provider.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_forms.dart';
import 'crypto_validators.dart';
import 'crypto_widgets.dart';

/// First sign-in of an account without keys: the user picks the encryption
/// code. The recovery key is shown next (see `RecoveryKeyScreen`).
class CryptoSetupScreen extends ConsumerStatefulWidget {
  const CryptoSetupScreen({super.key});

  @override
  ConsumerState<CryptoSetupScreen> createState() => _CryptoSetupScreenState();
}

class _CryptoSetupScreenState extends ConsumerState<CryptoSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _remember = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(cryptoProvider.notifier)
          .setup(_passCtrl.text, remember: _remember);
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
    final theme = Theme.of(context);
    return CryptoScaffold(
      icon: Icons.shield_outlined,
      title: l10n.cryptoSetupTitle,
      message: l10n.cryptoSetupBody,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _passCtrl,
                label: l10n.cryptoPassphraseLabel,
                validator: (v) => validateNewPassphrase(l10n, v),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirmCtrl,
                label: l10n.cryptoPassphraseConfirmLabel,
                validator:
                    (v) =>
                        validatePassphraseConfirmation(l10n, v, _passCtrl.text),
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.cryptoSetupWarning,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: AppSpacing.sm),
          RememberBrowserTile(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) CryptoErrorText(_error!),
        CryptoSubmitButton(
          label: l10n.cryptoSetupSubmit,
          onPressed: _submit,
          busy: _busy,
        ),
      ],
    );
  }
}
