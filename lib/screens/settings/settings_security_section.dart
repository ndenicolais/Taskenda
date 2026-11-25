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
import '../crypto/crypto_widgets.dart';
import '../crypto/recovery_key_screen.dart';

/// "Sicurezza" section: create or replace the recovery code, confirmed with
/// the passkey. Resetting encryption is only on the unlock screen, for who
/// lost both the passkey and the recovery code.
class SettingsSecuritySection extends ConsumerStatefulWidget {
  const SettingsSecuritySection({super.key});

  @override
  ConsumerState<SettingsSecuritySection> createState() =>
      _SettingsSecuritySectionState();
}

class _SettingsSecuritySectionState
    extends ConsumerState<SettingsSecuritySection> {
  bool _busy = false;

  Future<void> _newRecoveryKey() async {
    if (_busy) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final recoveryKey =
          await ref.read(cryptoProvider.notifier).regenerateRecoveryKey();
      if (!mounted) return;
      setState(() => _busy = false);
      await showRecoveryKeyDialog(context, recoveryKey);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            cryptoErrorMessage(l10n, e, wrongKey: l10n.commonGenericError),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          icon: Icons.key_outlined,
          title: l10n.securityNewRecoveryKey,
          subtitle: l10n.securityNewRecoveryKeySubtitle,
          onTap: _busy ? null : _newRecoveryKey,
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
