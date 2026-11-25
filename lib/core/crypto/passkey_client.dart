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

import 'passkey_client_stub.dart'
    if (dart.library.io) 'passkey_client_native.dart'
    if (dart.library.js_interop) 'passkey_client_web.dart'
    as platform;

/// Relying party of Taskenda's passkeys: the web app's domain, which hosts
/// `/.well-known/assetlinks.json` for the Android app.
const passkeyRelyingPartyId = 'taskenda21.web.app';

/// What a passkey gives back: its credential id (Base64URL) and the secret
/// of the WebAuthn PRF extension for the salt it was asked with. The same
/// passkey and salt always give the same secret.
@immutable
class PasskeySecret {
  const PasskeySecret({required this.credentialId, required this.secret});

  final String credentialId;
  final Uint8List secret;
}

/// The user closed the passkey dialog (or it timed out).
class PasskeyCancelledException implements Exception {
  const PasskeyCancelledException();
}

/// This device can't use a passkey with the PRF extension: no screen lock,
/// no passkey provider, an old Android or browser, or a provider without
/// PRF.
class PasskeyUnavailableException implements Exception {
  const PasskeyUnavailableException([this.detail]);

  final String? detail;

  @override
  String toString() => 'PasskeyUnavailableException: $detail';
}

/// There is no passkey of this account on the device.
class PasskeyNotFoundException implements Exception {
  const PasskeyNotFoundException();
}

/// Any other passkey error.
class PasskeyFailedException implements Exception {
  const PasskeyFailedException(this.detail);

  final String detail;

  @override
  String toString() => 'PasskeyFailedException: $detail';
}

/// Creates and uses the passkey that protects the encryption keys. No
/// server checks the WebAuthn signatures: only the PRF secret is used, so
/// the challenges are random bytes.
abstract class PasskeyClient {
  /// The platform implementation: Android (`passkeys` package) or web
  /// (WebAuthn through `navigator.credentials`).
  factory PasskeyClient() => platform.createPasskeyClient();

  /// Creates a passkey for the account and returns its PRF secret for
  /// [salt]; [userId] identifies the account (a new passkey replaces the
  /// previous one of the same account in the password manager).
  Future<PasskeySecret> create({
    required String userId,
    required String userName,
    required String displayName,
    required Uint8List salt,
  });

  /// Asks for one of [credentialIds] (any passkey of Taskenda if empty)
  /// and returns its PRF secret for [salt].
  Future<PasskeySecret> get({
    required Uint8List salt,
    List<String> credentialIds = const [],
  });
}

/// Helpers shared by the implementations.
abstract final class PasskeyCodec {
  static String toBase64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static Uint8List fromBase64Url(String s) =>
      base64Url.decode(s.padRight(s.length + (4 - s.length % 4) % 4, '='));
}
