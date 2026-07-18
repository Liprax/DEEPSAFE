import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

class AesGcmCipher {
  static final _algo = AesGcm.with256bits();
  static const _nonceLength = 12;
  static const _tagLength = 16;

  static Future<Uint8List> encrypt(Uint8List data, String salt) async {
    final key = SecretKey(sha256.convert(utf8.encode(salt)).bytes);
    final nonce = _randomBytes(_nonceLength);
    final secretBox = await _algo.encrypt(
      data,
      secretKey: key,
      nonce: nonce,
    );
    return Uint8List.fromList(nonce + secretBox.cipherText + secretBox.mac.bytes);
  }

  static Future<Uint8List> decrypt(Uint8List data, String salt) async {
    if (data.length < _nonceLength + _tagLength) {
      throw Exception('Geçersiz şifreli veri.');
    }
    final key = SecretKey(sha256.convert(utf8.encode(salt)).bytes);
    final nonce = data.sublist(0, _nonceLength);
    final macBytes = data.sublist(data.length - _tagLength);
    final cipherText = data.sublist(_nonceLength, data.length - _tagLength);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final decrypted = await _algo.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(decrypted);
  }

  static Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }
}
