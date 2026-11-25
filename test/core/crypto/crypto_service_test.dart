import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';

void main() {
  final crypto = CryptoService();

  group('encrypt / decrypt', () {
    test('round-trips with the same key and AAD', () async {
      final key = await crypto.newSecretKey();
      final blob = await crypto.encrypt(utf8.encode('ciao'), key, aad: 'a');
      expect(utf8.decode(await crypto.decrypt(blob, key, aad: 'a')), 'ciao');
    });

    test('the ciphertext does not contain the clear text', () async {
      final key = await crypto.newSecretKey();
      final blob = await crypto.encrypt(
        utf8.encode('segreto segreto'),
        key,
        aad: 'a',
      );
      expect(
        utf8.decode(blob.cipherText, allowMalformed: true),
        isNot(contains('segreto')),
      );
    });

    test('a fresh nonce every time', () async {
      final key = await crypto.newSecretKey();
      final a = await crypto.encrypt([1, 2, 3], key, aad: 'a');
      final b = await crypto.encrypt([1, 2, 3], key, aad: 'a');
      expect(a.nonce, isNot(b.nonce));
      expect(a.cipherText, isNot(b.cipherText));
    });

    test('wrong key, wrong AAD or tampering fail', () async {
      final key = await crypto.newSecretKey();
      final other = await crypto.newSecretKey();
      final blob = await crypto.encrypt([1, 2, 3], key, aad: 'a');
      final tampered = EncryptedBlob(
        nonce: blob.nonce,
        cipherText: Uint8List.fromList(blob.cipherText)..[0] ^= 1,
      );

      expect(
        () => crypto.decrypt(blob, other, aad: 'a'),
        throwsA(isA<CryptoException>()),
      );
      expect(
        () => crypto.decrypt(blob, key, aad: 'b'),
        throwsA(isA<CryptoException>()),
      );
      expect(
        () => crypto.decrypt(tampered, key, aad: 'a'),
        throwsA(isA<CryptoException>()),
      );
    });

    test('a blob survives its Firestore JSON form', () async {
      final key = await crypto.newSecretKey();
      final blob = await crypto.encryptJson({'title': 'x'}, key, aad: 'a');
      final back = EncryptedBlob.fromJson(
        jsonDecode(jsonEncode(blob.toJson())),
      );
      expect(await crypto.decryptJson(back, key, aad: 'a'), {'title': 'x'});
    });

    test('a malformed blob is a CryptoException', () {
      expect(
        () => EncryptedBlob.fromJson({'n': 1}),
        throwsA(isA<CryptoException>()),
      );
      expect(
        () => EncryptedBlob.fromJson({'n': '!!', 'c': '??'}),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('key derivation', () {
    test('a passkey secret gives a stable KEK, another one does not', () async {
      final secret = CryptoService.randomBytes(CryptoService.prfLength);
      final a = await crypto.derivePasskeyKek(secret);
      final b = await crypto.derivePasskeyKek(Uint8List.fromList(secret));
      final c = await crypto.derivePasskeyKek(
        CryptoService.randomBytes(CryptoService.prfLength),
      );
      expect(await a.extractBytes(), await b.extractBytes());
      expect(await a.extractBytes(), isNot(await c.extractBytes()));
    });

    test('the explicit zero salt keeps the keys of an empty salt', () async {
      // Keys created before the explicit salt (needed by Android's native
      // HMAC) must still open.
      final secret = CryptoService.randomBytes(CryptoService.prfLength);
      final emptySalt = await Hkdf(
        hmac: Hmac.sha256(),
        outputLength: CryptoService.keyLength,
      ).deriveKey(
        secretKey: SecretKeyData(secret),
        info: utf8.encode('taskenda:v1:passkey'),
      );
      final kek = await crypto.derivePasskeyKek(secret);
      expect(await kek.extractBytes(), await emptySalt.extractBytes());
    });

    test('a passkey secret of the wrong length is refused', () {
      expect(
        () => crypto.derivePasskeyKek(Uint8List(16)),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('master key wrapping', () {
    test('the passkey KEK unwraps the master key, another does not', () async {
      final master = await crypto.newSecretKey();
      final secret = CryptoService.randomBytes(CryptoService.prfLength);
      final wrapped = await crypto.wrapKey(
        master,
        await crypto.derivePasskeyKek(secret),
        aad: 'mk',
      );

      final back = await crypto.unwrapKey(
        wrapped,
        await crypto.derivePasskeyKek(secret),
        aad: 'mk',
      );
      expect(await back.extractBytes(), await master.extractBytes());

      final wrongKek = await crypto.derivePasskeyKek(
        CryptoService.randomBytes(CryptoService.prfLength),
      );
      expect(
        () => crypto.unwrapKey(wrapped, wrongKek, aad: 'mk'),
        throwsA(isA<CryptoException>()),
      );
    });

    test('the recovery key unwraps its own copy of the master key', () async {
      final master = await crypto.newSecretKey();
      final recovery = crypto.newRecoveryKey();
      final wrapped = await crypto.wrapKey(
        master,
        await crypto.deriveRecoveryKek(recovery),
        aad: 'mk_recovery',
      );

      final typed =
          CryptoService.parseRecoveryKey(
            CryptoService.formatRecoveryKey(recovery).toLowerCase(),
          )!;
      final back = await crypto.unwrapKey(
        wrapped,
        await crypto.deriveRecoveryKek(typed),
        aad: 'mk_recovery',
      );
      expect(await back.extractBytes(), await master.extractBytes());
    });
  });

  group('key pairs and sealed keys', () {
    test('a private key restores the same key pair', () async {
      final pair = await crypto.newKeyPair();
      final restored = await crypto.keyPairFromPrivateBytes(
        await crypto.privateKeyBytes(pair),
      );
      expect(
        await crypto.publicKeyBytes(restored),
        await crypto.publicKeyBytes(pair),
      );
    });

    test('only the recipient opens a sealed key', () async {
      final alice = await crypto.newKeyPair();
      final bob = await crypto.newKeyPair();
      final itemKey = await crypto.newSecretKey();

      final sealed = await crypto.sealKey(
        itemKey,
        await crypto.publicKeyBytes(bob),
        aad: 'item',
      );
      final back = SealedKey.fromJson(jsonDecode(jsonEncode(sealed.toJson())));

      final opened = await crypto.openSealedKey(back, bob, aad: 'item');
      expect(await opened.extractBytes(), await itemKey.extractBytes());

      expect(
        () => crypto.openSealedKey(back, alice, aad: 'item'),
        throwsA(isA<CryptoException>()),
      );
      expect(
        () => crypto.openSealedKey(back, bob, aad: 'other'),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('recovery key format', () {
    test('13 dash-separated groups of Base32, parsed back loosely', () {
      final key = crypto.newRecoveryKey();
      final text = CryptoService.formatRecoveryKey(key);
      expect(text, matches(RegExp(r'^([A-Z2-7]{4}-){12}[A-Z2-7]{4}$')));

      final loose = ' ${text.toLowerCase().replaceAll('-', ' ')} ';
      expect(CryptoService.parseRecoveryKey(loose), key);
    });

    test('a known value', () {
      final key = Uint8List.fromList(List.filled(32, 0));
      expect(
        CryptoService.formatRecoveryKey(key),
        List.filled(13, 'AAAA').join('-'),
      );
    });

    test('typos, wrong length or non-zero padding are refused', () {
      final text = CryptoService.formatRecoveryKey(crypto.newRecoveryKey());
      expect(
        CryptoService.parseRecoveryKey(text.replaceRange(0, 1, '1')),
        isNull,
      );
      expect(CryptoService.parseRecoveryKey(text.substring(0, 20)), isNull);
      // 'AAAB' at the end sets a padding bit.
      expect(
        CryptoService.parseRecoveryKey(
          '${List.filled(12, 'AAAA').join('-')}-AAAB',
        ),
        isNull,
      );
    });
  });
}
