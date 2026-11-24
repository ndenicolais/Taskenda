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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/crypto_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/action_tile.dart';
import '../../widgets/shared/section_header.dart';
import '../auth/login_forms.dart';
import '../crypto/crypto_validators.dart';
import '../crypto/crypto_widgets.dart';
import '../crypto/recovery_key_screen.dart';

/// "Sicurezza" section: change the encryption code, replace the recovery
/// code. Both ask for the current code. Resetting encryption is only on the
/// unlock screen, for who lost both codes.
class SettingsSecuritySection extends ConsumerWidget {
  const SettingsSecuritySection({super.key});

  Future<void> _changePassphrase(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePassphraseDialog(),
    );
    if (changed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.securityPassphraseChanged),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _newRecoveryKey(BuildContext context) async {
    final recoveryKey = await showDialog<String>(
      context: context,
      builder: (_) => const _NewRecoveryKeyDialog(),
    );
    if (recoveryKey == null || !context.mounted) return;
    await showRecoveryKeyDialog(context, recoveryKey);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.settingsSecurityTitle),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            l10n.securityInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ActionTile(
          icon: Icons.lock_reset_outlined,
          title: l10n.securityChangePassphrase,
          subtitle: l10n.securityChangePassphraseSubtitle,
          onTap: () => _changePassphrase(context),
        ),
        ActionTile(
          icon: Icons.key_outlined,
          title: l10n.securityNewRecoveryKey,
          subtitle: l10n.securityNewRecoveryKeySubtitle,
          onTap: () => _newRecoveryKey(context),
        ),
      ],
    );
  }
}

/// Current code + new code + confirmation; pops `true` once changed.
class _ChangePassphraseDialog extends ConsumerStatefulWidget {
  const _ChangePassphraseDialog();

  @override
  ConsumerState<_ChangePassphraseDialog> createState() =>
      _ChangePassphraseDialogState();
}

class _ChangePassphraseDialogState
    extends ConsumerState<_ChangePassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
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
          .changePassphrase(_currentCtrl.text, _newCtrl.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cryptoErrorMessage(l10n, e, wrongKey: l10n.cryptoUnlockWrong);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.securityChangePassphrase),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _currentCtrl,
                label: l10n.securityCurrentPassphrase,
                validator: (v) => validatePassphrase(l10n, v),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _newCtrl,
                label: l10n.cryptoNewPassphraseLabel,
                validator: (v) => validateNewPassphrase(l10n, v),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirmCtrl,
                label: l10n.cryptoPassphraseConfirmLabel,
                validator:
                    (v) =>
                        validatePassphraseConfirmation(l10n, v, _newCtrl.text),
                onSubmitted: _submit,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                CryptoErrorText(_error!),
              ],
              if (_busy) ...[
                const SizedBox(height: AppSpacing.md),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Asks the current code, replaces the recovery key and pops it as text.
class _NewRecoveryKeyDialog extends ConsumerStatefulWidget {
  const _NewRecoveryKeyDialog();

  @override
  ConsumerState<_NewRecoveryKeyDialog> createState() =>
      _NewRecoveryKeyDialogState();
}

class _NewRecoveryKeyDialogState extends ConsumerState<_NewRecoveryKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
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
      final recoveryKey = await ref
          .read(cryptoProvider.notifier)
          .regenerateRecoveryKey(_currentCtrl.text);
      if (mounted) Navigator.pop(context, recoveryKey);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = cryptoErrorMessage(l10n, e, wrongKey: l10n.cryptoUnlockWrong);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.securityNewRecoveryKey),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.securityNewRecoveryKeySubtitle),
              const SizedBox(height: AppSpacing.lg),
              PasswordField(
                controller: _currentCtrl,
                label: l10n.securityCurrentPassphrase,
                validator: (v) => validatePassphrase(l10n, v),
                onSubmitted: _submit,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                CryptoErrorText(_error!),
              ],
              if (_busy) ...[
                const SizedBox(height: AppSpacing.md),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.cryptoContinue),
        ),
      ],
    );
  }
}
