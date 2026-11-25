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
import 'crypto_setup_screen.dart';
import 'crypto_unlock_screen.dart';
import 'crypto_widgets.dart';
import 'recovery_key_screen.dart';

/// Between sign-in and the app: shows [child] only once the user's
/// encryption keys are unlocked, and the setup, unlock or recovery-key
/// screens until then. [loading] is shown while the keys are looked up.
class CryptoGate extends ConsumerWidget {
  const CryptoGate({super.key, required this.child, required this.loading});

  final Widget child;
  final Widget loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(cryptoProvider)) {
      CryptoSignedOut() || CryptoChecking() => loading,
      CryptoNeedsSetup() => const CryptoSetupScreen(),
      CryptoLocked(:final bundle) => CryptoUnlockScreen(bundle: bundle),
      CryptoUnlocked(:final pendingRecoveryKey?) => RecoveryKeyScreen(
        recoveryKey: pendingRecoveryKey,
      ),
      CryptoUnlocked(offerRecoveryKey: true) => const RecoveryKeyOfferScreen(),
      CryptoUnlocked() => child,
      CryptoLoadFailed() => const _LoadFailedScreen(),
    };
  }
}

class _LoadFailedScreen extends ConsumerWidget {
  const _LoadFailedScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return CryptoScaffold(
      icon: Icons.cloud_off_outlined,
      title: l10n.cryptoLoadErrorTitle,
      message: l10n.cryptoLoadErrorBody,
      children: [
        CryptoSubmitButton(
          label: l10n.commonRetry,
          onPressed: () => ref.read(cryptoProvider.notifier).retry(),
        ),
      ],
    );
  }
}
