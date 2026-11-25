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
import 'crypto_widgets.dart';

/// First sign-in of an account without keys: the user creates the passkey
/// that protects them. Creating a recovery key is proposed next (see
/// `RecoveryKeyOfferScreen`).
class CryptoSetupScreen extends ConsumerStatefulWidget {
  const CryptoSetupScreen({super.key});

  @override
  ConsumerState<CryptoSetupScreen> createState() => _CryptoSetupScreenState();
}

class _CryptoSetupScreenState extends ConsumerState<CryptoSetupScreen> {
  bool _remember = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(cryptoProvider.notifier).setup(remember: _remember);
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
      icon: Icons.fingerprint,
      title: l10n.cryptoSetupTitle,
      message: l10n.cryptoSetupBody,
      children: [
        if (kIsWeb) ...[
          RememberBrowserTile(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
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
