// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

// PROTOTYPE (guides/E2EE_PLAN.md, "Passkey" prototype): a developer-only
// diagnostic, opened with a long press on the version in Info. It checks
// that a passkey with the WebAuthn PRF extension gives back the same secret
// on these devices. Its text is not localized on purpose: it is not for
// users and is removed once the prototype is over.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import '../../core/crypto/crypto_service.dart';
import '../../providers/sharing_provider.dart';
import '../../theme/app_spacing.dart';

/// Relying party of Taskenda's passkeys: the web app's domain, which hosts
/// `/.well-known/assetlinks.json` for the Android app.
const passkeyRelyingPartyId = 'taskenda21.web.app';

class PasskeyProbeScreen extends ConsumerStatefulWidget {
  const PasskeyProbeScreen({super.key});

  @override
  ConsumerState<PasskeyProbeScreen> createState() => _PasskeyProbeScreenState();
}

class _PasskeyProbeScreenState extends ConsumerState<PasskeyProbeScreen> {
  final _authenticator = PasskeyAuthenticator();
  final _log = <String>[];
  bool _busy = false;
  String? _firstFingerprint;

  /// Fixed PRF salt for the probe: the same salt must give the same secret.
  static final String _salt = _base64Url(
    Uint8List.fromList(utf8.encode('taskenda-prf-probe-v1-salt-32byt')),
  );

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static Uint8List _fromBase64Url(String s) =>
      base64Url.decode(s.padRight(s.length + (4 - s.length % 4) % 4, '='));

  String _challenge() => _base64Url(CryptoService.randomBytes(32));

  void _add(String line) {
    final t = TimeOfDay.now().format(context);
    setState(() => _log.insert(0, '[$t] $line'));
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _add('$label: ERROR ${e.runtimeType}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _availability() => _run('Availability', () async {
    final checker = _authenticator.getAvailability();
    if (kIsWeb) {
      final a = await checker.web();
      _add(
        'Web: passkeys=${a.hasPasskeySupport}, '
        'platform authenticator=${a.isUserVerifyingPlatformAuthenticatorAvailable}',
      );
    } else {
      final a = await checker.android();
      _add(
        'Android: passkeys=${a.hasPasskeySupport}, '
        'platform authenticator=${a.isUserVerifyingPlatformAuthenticatorAvailable}',
      );
    }
  });

  Future<void> _register() => _run('Register', () async {
    final me = ref.read(currentShareMemberProvider);
    if (me == null) throw StateError('Not signed in');
    final response = await _authenticator.register(
      RegisterRequestType(
        challenge: _challenge(),
        relyingParty: RelyingPartyType(
          name: 'Taskenda',
          id: passkeyRelyingPartyId,
        ),
        user: UserType(
          displayName: me.name.isEmpty ? me.email : me.name,
          name: me.email,
          id: _base64Url(utf8.encode(me.uid)),
        ),
        excludeCredentials: const [],
        authSelectionType: AuthenticatorSelectionType(
          requireResidentKey: true,
          residentKey: 'required',
          userVerification: 'required',
          authenticatorAttachment: 'platform',
        ),
        pubKeyCredParams: [
          PubKeyCredParamType(type: 'public-key', alg: -7),
          PubKeyCredParamType(type: 'public-key', alg: -257),
        ],
        prf: _salt,
      ),
    );
    // Only whether PRF is on and if a secret came back, never the secret.
    final prf = response.clientExtensionResults?['prf'];
    final enabled = prf is Map ? prf['enabled'] : null;
    final hasSecret = prf is Map && prf['results'] is Map;
    _add(
      'Passkey created (id ${response.id.substring(0, 8)}…), '
      'PRF enabled: $enabled, secret at creation: $hasSecret',
    );
  });

  Future<void> _authenticate() => _run('Authenticate', () async {
    final response = await _authenticator.authenticate(
      AuthenticateRequestType(
        relyingPartyId: passkeyRelyingPartyId,
        challenge: _challenge(),
        mediation: MediationType.Optional,
        preferImmediatelyAvailableCredentials: false,
        userVerification: 'required',
        prf: _salt,
      ),
    );
    final prf = response.clientExtensionResults?['prf'];
    final results = prf is Map ? prf['results'] : null;
    final first = results is Map ? results['first'] : null;
    if (first is! String) {
      _add('Signed in with the passkey, but NO PRF secret: $prf');
      return;
    }
    final secret = _fromBase64Url(first);
    final hash = await Sha256().hash(secret);
    final fingerprint =
        hash.bytes
            .take(6)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
    final same =
        _firstFingerprint == null
            ? 'first read'
            : (_firstFingerprint == fingerprint
                ? 'SAME as before ✅'
                : 'DIFFERENT ❌');
    _firstFingerprint ??= fingerprint;
    _add(
      'PRF secret: ${secret.length} bytes, fingerprint $fingerprint ($same)',
    );
  });

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return Scaffold(
      appBar: AppBar(title: const Text('Passkey PRF probe')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Relying party: $passkeyRelyingPartyId\n'
            '1. Check availability  2. Create the passkey  '
            '3. Read the secret twice (and on another device): '
            'the fingerprint must always be the same.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _availability,
                child: const Text('1. Availability'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _register,
                child: const Text('2. Create passkey'),
              ),
              FilledButton(
                onPressed: _busy ? null : _authenticate,
                child: const Text('3. Read secret'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final line in _log)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SelectableText(line, style: mono),
            ),
        ],
      ),
    );
  }
}
