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
import '../../widgets/shared/app_dialogs.dart';
import '../auth/login_forms.dart';
import 'crypto_validators.dart';
import 'crypto_widgets.dart';

/// Sign-in on a device without the keys: the user enters the encryption
/// code, or ("I forgot the code") the recovery key and a new code. Without
/// either, encryption can be reset.
class CryptoUnlockScreen extends ConsumerStatefulWidget {
  const CryptoUnlockScreen({super.key});

  @override
  ConsumerState<CryptoUnlockScreen> createState() => _CryptoUnlockScreenState();
}

class _CryptoUnlockScreenState extends ConsumerState<CryptoUnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _recoveryCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _recovering = false;
  bool _remember = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _recoveryCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() => setState(() {
    _recovering = !_recovering;
    _error = null;
  });

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final notifier = ref.read(cryptoProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_recovering) {
        await notifier.recover(
          _recoveryCtrl.text,
          _newPassCtrl.text,
          remember: _remember,
        );
      } else {
        await notifier.unlock(_passCtrl.text, remember: _remember);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cryptoErrorMessage(
          l10n,
          e,
          wrongKey:
              _recovering
                  ? l10n.cryptoRecoveryKeyWrong
                  : l10n.cryptoUnlockWrong,
        );
      });
    }
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.cryptoResetTitle,
      message: l10n.cryptoResetBody,
      confirmLabel: l10n.cryptoResetConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(cryptoProvider.notifier).reset();
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
      icon: _recovering ? Icons.key_outlined : Icons.lock_outline,
      title: _recovering ? l10n.cryptoRecoverTitle : l10n.cryptoUnlockTitle,
      message: _recovering ? l10n.cryptoRecoverBody : l10n.cryptoUnlockBody,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                _recovering
                    ? [
                      TextFormField(
                        controller: _recoveryCtrl,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.cryptoRecoveryKeyLabel,
                          hintText: 'XXXX-XXXX-…',
                          prefixIcon: const Icon(Icons.key_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? l10n.cryptoRecoveryKeyInvalid
                                    : null,
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _newPassCtrl,
                        label: l10n.cryptoNewPassphraseLabel,
                        validator: (v) => validateNewPassphrase(l10n, v),
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _confirmCtrl,
                        label: l10n.cryptoPassphraseConfirmLabel,
                        validator:
                            (v) => validatePassphraseConfirmation(
                              l10n,
                              v,
                              _newPassCtrl.text,
                            ),
                        onSubmitted: _submit,
                      ),
                    ]
                    : [
                      PasswordField(
                        controller: _passCtrl,
                        label: l10n.cryptoPassphraseLabel,
                        validator: (v) => validatePassphrase(l10n, v),
                        onSubmitted: _submit,
                      ),
                    ],
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
          label:
              _recovering ? l10n.cryptoRecoverSubmit : l10n.cryptoUnlockSubmit,
          onPressed: _submit,
          busy: _busy,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _busy ? null : _toggleMode,
          child: Text(
            _recovering ? l10n.cryptoBackToUnlock : l10n.cryptoForgotPassphrase,
          ),
        ),
        if (_recovering)
          TextButton(
            onPressed: _busy ? null : _reset,
            child: Text(l10n.cryptoNoRecoveryKey),
          ),
      ],
    );
  }
}
