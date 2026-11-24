// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crypto/crypto_service.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crypto_provider.dart';
import '../../theme/app_font_sizes.dart';
import '../../theme/app_spacing.dart';

/// Layout shared by the encryption screens shown after sign-in: icon,
/// title and text on top, [children] below, and "Sign out" at the bottom
/// (to switch account without unlocking).
class CryptoScaffold extends ConsumerWidget {
  const CryptoScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.children,
    this.showSignOut = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> children;
  final bool showSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...children,
                  if (showSignOut) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed:
                          () =>
                              ref.read(authNotifierProvider.notifier).signOut(),
                      child: Text(context.l10n.navSignOut),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width primary button; a progress bar replaces it while [busy].
class CryptoSubmitButton extends StatelessWidget {
  const CryptoSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: LinearProgressIndicator(),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: AppFontSizes.lg)),
    );
  }
}

/// An error under a form, announced by screen readers.
class CryptoErrorText extends StatelessWidget {
  const CryptoErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

/// "Remember on this browser" (web only: on Android the keys are always
/// kept in the secure storage).
class RememberBrowserTile extends StatelessWidget {
  const RememberBrowserTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(context.l10n.cryptoRememberBrowser),
      subtitle: Text(context.l10n.cryptoRememberBrowserHint),
    );
  }
}

/// The message for an error thrown by [CryptoNotifier]; [wrongKey] is the
/// one for a [CryptoException] (wrong code or recovery key).
String cryptoErrorMessage(
  AppLocalizations l,
  Object error, {
  required String wrongKey,
}) => switch (error) {
  CryptoException() => wrongKey,
  InvalidRecoveryKeyException() => l.cryptoRecoveryKeyInvalid,
  CryptoOfflineException() => l.cryptoNeedsConnection,
  FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
    l.cryptoNeedsConnection,
  _ => l.commonGenericError,
};
