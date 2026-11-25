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
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import 'crypto_service.dart';
import 'passkey_client.dart';

PasskeyClient createPasskeyClient() => _WebPasskeyClient();

@JS('navigator')
external JSObject get _navigator;

@JS('PublicKeyCredential')
external JSAny? get _publicKeyCredential;

/// Web: WebAuthn through `navigator.credentials`, without the `passkeys`
/// package's script. The relying party is the web app's domain, so it works
/// only on `taskenda21.web.app` (elsewhere the browser refuses it).
class _WebPasskeyClient implements PasskeyClient {
  static JSObject _object(Map<String, JSAny?> fields) {
    final o = JSObject();
    fields.forEach((k, v) => o.setProperty(k.toJS, v));
    return o;
  }

  static JSObject _prfExtension(Uint8List salt) => _object({
    'prf': _object({
      'eval': _object({'first': salt.toJS}),
    }),
  });

  static JSObject get _credentials {
    if (_publicKeyCredential == null) {
      throw const PasskeyUnavailableException('No WebAuthn');
    }
    final credentials = _navigator.getProperty<JSObject?>('credentials'.toJS);
    if (credentials == null) {
      throw const PasskeyUnavailableException('No credentials API');
    }
    return credentials;
  }

  @override
  Future<PasskeySecret> create({
    required String userId,
    required String userName,
    required String displayName,
    required Uint8List salt,
  }) async {
    final options = _object({
      'publicKey': _object({
        'challenge': CryptoService.randomBytes(32).toJS,
        'rp': _object({
          'name': 'Taskenda'.toJS,
          'id': passkeyRelyingPartyId.toJS,
        }),
        'user': _object({
          'id': Uint8List.fromList(utf8.encode(userId)).toJS,
          'name': userName.toJS,
          'displayName': displayName.toJS,
        }),
        'pubKeyCredParams':
            [
              _object({'type': 'public-key'.toJS, 'alg': (-7).toJS}),
              _object({'type': 'public-key'.toJS, 'alg': (-257).toJS}),
            ].toJS,
        'authenticatorSelection': _object({
          'residentKey': 'required'.toJS,
          'requireResidentKey': true.toJS,
          'userVerification': 'required'.toJS,
        }),
        'extensions': _prfExtension(salt),
      }),
    });
    final credential = await _call('create', options);
    final prf = _prfOf(credential);
    if (prf?.getProperty<JSAny?>('enabled'.toJS)?.dartify() == false) {
      throw const PasskeyUnavailableException('PRF not supported');
    }
    final id = _idOf(credential);
    final secret = _secretOf(prf);
    if (secret != null) return PasskeySecret(credentialId: id, secret: secret);
    // Most browsers give the secret only when the passkey is used.
    return get(salt: salt, credentialIds: [id]);
  }

  @override
  Future<PasskeySecret> get({
    required Uint8List salt,
    List<String> credentialIds = const [],
  }) async {
    final options = _object({
      'publicKey': _object({
        'challenge': CryptoService.randomBytes(32).toJS,
        'rpId': passkeyRelyingPartyId.toJS,
        'userVerification': 'required'.toJS,
        'allowCredentials':
            [
              for (final id in credentialIds)
                _object({
                  'type': 'public-key'.toJS,
                  'id': PasskeyCodec.fromBase64Url(id).toJS,
                }),
            ].toJS,
        'extensions': _prfExtension(salt),
      }),
    });
    final credential = await _call('get', options);
    final secret = _secretOf(_prfOf(credential));
    if (secret == null) {
      throw const PasskeyUnavailableException('No PRF secret');
    }
    return PasskeySecret(credentialId: _idOf(credential), secret: secret);
  }

  static Future<JSObject> _call(String method, JSObject options) async {
    final JSObject? credential;
    try {
      credential =
          await _credentials
              .callMethod<JSPromise<JSObject?>>(method.toJS, options)
              .toDart;
    } on PasskeyUnavailableException {
      rethrow;
    } catch (e) {
      throw _mapError(e);
    }
    if (credential == null) throw const PasskeyCancelledException();
    return credential;
  }

  static String _idOf(JSObject credential) =>
      credential.getProperty<JSString>('id'.toJS).toDart;

  static JSObject? _prfOf(JSObject credential) {
    final results = credential.callMethod<JSObject?>(
      'getClientExtensionResults'.toJS,
    );
    return results?.getProperty<JSObject?>('prf'.toJS);
  }

  static Uint8List? _secretOf(JSObject? prf) {
    final results = prf?.getProperty<JSObject?>('results'.toJS);
    final first = results?.getProperty<JSArrayBuffer?>('first'.toJS);
    if (first == null) return null;
    final secret = first.toDart.asUint8List();
    return secret.length == CryptoService.prfLength ? secret : null;
  }

  /// WebAuthn errors are `DOMException`s, told apart by their name.
  static Exception _mapError(Object e) {
    final text = e.toString();
    if (kDebugMode) debugPrint('Passkey error: $text');
    if (text.contains('NotAllowedError') || text.contains('AbortError')) {
      return const PasskeyCancelledException();
    }
    if (text.contains('NotSupportedError') ||
        text.contains('SecurityError') ||
        text.contains('InvalidStateError')) {
      return PasskeyUnavailableException(text);
    }
    return PasskeyFailedException(text);
  }
}
