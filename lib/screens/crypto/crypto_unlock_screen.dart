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

import '../../core/crypto/user_keys.dart';
import '../../l10n/l10n.dart';
import '../../providers/crypto_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/app_dialogs.dart';
import 'crypto_widgets.dart';

/// Sign-in on a device without the keys: the user unlocks them with the
/// passkey, or ("I lost the passkey") with the recovery key, which then
/// creates a new passkey. Without either, encryption can be reset. An
/// account from before passkeys (no passkey in its bundle) starts with the
/// recovery key.
class CryptoUnlockScreen extends ConsumerStatefulWidget {
  const CryptoUnlockScreen({super.key, required this.bundle});

  final UserKeyBundle bundle;

  @override
  ConsumerState<CryptoUnlockScreen> createState() => _CryptoUnlockScreenState();
}

class _CryptoUnlockScreenState extends ConsumerState<CryptoUnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recoveryCtrl = TextEditingController();
  late bool _recovering = !widget.bundle.hasPasskey;
  bool _remember = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _recoveryCtrl.dispose();
    super.dispose();
  }

  void _setRecovering(bool value) => setState(() {
    _recovering = value;
    _error = null;
  });

  void _lostPasskey() {
    if (widget.bundle.hasRecoveryKey) {
      _setRecovering(true);
    } else {
      _reset();
    }
  }

  Future<void> _run(Future<void> Function() action, String wrongKey) async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cryptoErrorMessage(l10n, e, wrongKey: wrongKey);
      });
    }
  }

  void _unlock() => _run(
    () => ref
        .read(cryptoProvider.notifier)
        .unlockWithPasskey(remember: _remember),
    context.l10n.commonGenericError,
  );

  void _recover() {
    if (!_formKey.currentState!.validate()) return;
    _run(
      () => ref
          .read(cryptoProvider.notifier)
          .recover(_recoveryCtrl.text, remember: _remember),
      context.l10n.cryptoRecoveryKeyWrong,
    );
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
    await _run(
      () => ref.read(cryptoProvider.notifier).reset(),
      l10n.commonGenericError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CryptoScaffold(
      icon: _recovering ? Icons.key_outlined : Icons.fingerprint,
      title: _recovering ? l10n.cryptoRecoverTitle : l10n.cryptoUnlockTitle,
      message: _recovering ? l10n.cryptoRecoverBody : l10n.cryptoUnlockBody,
      children: [
        if (_recovering) ...[
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _recoveryCtrl,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _recover(),
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
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (kIsWeb)
          RememberBrowserTile(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) CryptoErrorText(_error!),
        CryptoSubmitButton(
          label:
              _recovering ? l10n.cryptoRecoverSubmit : l10n.cryptoUnlockSubmit,
          onPressed: _recovering ? _recover : _unlock,
          busy: _busy,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_recovering)
          TextButton(
            onPressed: _busy ? null : _lostPasskey,
            child: Text(l10n.cryptoLostPasskey),
          )
        else ...[
          if (widget.bundle.hasPasskey)
            TextButton(
              onPressed: _busy ? null : () => _setRecovering(false),
              child: Text(l10n.cryptoBackToPasskey),
            ),
          TextButton(
            onPressed: _busy ? null : _reset,
            child: Text(l10n.cryptoNoRecoveryKey),
          ),
        ],
      ],
    );
  }
}
