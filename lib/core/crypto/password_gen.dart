import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordGen {
  static String generate(String master, String appName, String salt) {
    final input  = '$master$salt${appName.toLowerCase().trim()}';
    final digest = sha256.convert(utf8.encode(input)).toString();
    return digest.substring(0, 16).toUpperCase();
  }
}
