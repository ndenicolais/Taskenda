// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import 'crypto_service.dart';
import 'passkey_client.dart';

PasskeyClient createPasskeyClient() => _NativePasskeyClient();

/// Android: Credential Manager through the `passkeys` package (the
/// passkey is kept, and synced, by the user's password manager).
class _NativePasskeyClient implements PasskeyClient {
  final _authenticator = PasskeyAuthenticator();

  static String _challenge() =>
      PasskeyCodec.toBase64Url(CryptoService.randomBytes(32));

  @override
  Future<PasskeySecret> create({
    required String userId,
    required String userName,
    required String displayName,
    required Uint8List salt,
  }) async {
    final saltText = PasskeyCodec.toBase64Url(salt);
    final RegisterResponseType response;
    try {
      response = await _authenticator.register(
        RegisterRequestType(
          challenge: _challenge(),
          relyingParty: RelyingPartyType(
            name: 'Taskenda',
            id: passkeyRelyingPartyId,
          ),
          user: UserType(
            displayName: displayName,
            name: userName,
            id: PasskeyCodec.toBase64Url(utf8.encode(userId)),
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
          prf: saltText,
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
    final prf = response.clientExtensionResults?['prf'];
    if (prf is Map && prf['enabled'] == false) {
      throw const PasskeyUnavailableException('PRF not supported');
    }
    final secret = _secretOf(prf);
    if (secret != null) {
      return PasskeySecret(credentialId: response.id, secret: secret);
    }
    // Some providers give the secret only when the passkey is used.
    return get(salt: salt, credentialIds: [response.id]);
  }

  @override
  Future<PasskeySecret> get({
    required Uint8List salt,
    List<String> credentialIds = const [],
  }) async {
    final AuthenticateResponseType response;
    try {
      response = await _authenticator.authenticate(
        AuthenticateRequestType(
          relyingPartyId: passkeyRelyingPartyId,
          challenge: _challenge(),
          mediation: MediationType.Optional,
          preferImmediatelyAvailableCredentials: false,
          userVerification: 'required',
          allowCredentials: [
            for (final id in credentialIds)
              CredentialType(type: 'public-key', id: id, transports: const []),
          ],
          prf: PasskeyCodec.toBase64Url(salt),
        ),
      );
    } catch (e) {
      throw _mapError(e);
    }
    final secret = _secretOf(response.clientExtensionResults?['prf']);
    if (secret == null) {
      throw const PasskeyUnavailableException('No PRF secret');
    }
    return PasskeySecret(credentialId: response.id, secret: secret);
  }

  static Uint8List? _secretOf(Object? prf) {
    final results = prf is Map ? prf['results'] : null;
    final first = results is Map ? results['first'] : null;
    if (first is! String) return null;
    final secret = PasskeyCodec.fromBase64Url(first);
    return secret.length == CryptoService.prfLength ? secret : null;
  }

  static Exception _mapError(Object e) {
    if (kDebugMode) debugPrint('Passkey error: ${e.runtimeType}: $e');
    return switch (e) {
      PasskeyAuthCancelledException() ||
      TimeoutException() => const PasskeyCancelledException(),
      NoCredentialsAvailableException() => const PasskeyNotFoundException(),
      DeviceNotSupportedException() ||
      PasskeyUnsupportedException() ||
      NoCreateOptionException() ||
      MissingGoogleSignInException() ||
      SyncAccountNotAvailableException() ||
      DomainNotAssociatedException() => PasskeyUnavailableException(
        e.runtimeType.toString(),
      ),
      _ => PasskeyFailedException(e.toString()),
    };
  }
}
