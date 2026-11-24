import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/crypto/crypto_service.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

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
    test('PBKDF2-HMAC-SHA256 matches the known test vectors', () async {
      Future<String> derive(int iterations) async => _hex(
        await (await crypto.deriveKek(
          'password',
          KdfParams(
            salt: Uint8List.fromList(utf8.encode('salt')),
            iterations: iterations,
          ),
        )).extractBytes(),
      );

      expect(
        await derive(1),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        await derive(2),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('the same passphrase and params give the same KEK', () async {
      final params = crypto.newKdfParams(iterations: 1000);
      final a = await crypto.deriveKek('pass phrase', params);
      final b = await crypto.deriveKek('pass phrase', params);
      final c = await crypto.deriveKek('pass phrase!', params);
      expect(await a.extractBytes(), await b.extractBytes());
      expect(await a.extractBytes(), isNot(await c.extractBytes()));
    });

    test('KDF params round-trip and default to 600k PBKDF2', () {
      final params = crypto.newKdfParams();
      final back = KdfParams.fromJson(jsonDecode(jsonEncode(params.toJson())));
      expect(back.algorithm, KdfParams.pbkdf2Sha256);
      expect(back.iterations, 600000);
      expect(back.salt, params.salt);
      expect(params.salt, hasLength(CryptoService.saltLength));
    });

    test('an unknown KDF is refused', () {
      expect(
        () => crypto.deriveKek(
          'x',
          KdfParams(salt: Uint8List(16), algorithm: 'argon2id'),
        ),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('master key wrapping', () {
    test(
      'the passphrase unwraps the master key, a wrong one does not',
      () async {
        final params = crypto.newKdfParams(iterations: 1000);
        final master = await crypto.newSecretKey();
        final wrapped = await crypto.wrapKey(
          master,
          await crypto.deriveKek('right', params),
          aad: 'mk',
        );

        final back = await crypto.unwrapKey(
          wrapped,
          await crypto.deriveKek('right', params),
          aad: 'mk',
        );
        expect(await back.extractBytes(), await master.extractBytes());

        final wrongKek = await crypto.deriveKek('wrong', params);
        expect(
          () => crypto.unwrapKey(wrapped, wrongKek, aad: 'mk'),
          throwsA(isA<CryptoException>()),
        );
      },
    );

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
