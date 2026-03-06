import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class OneTimeCodeService {
  static int remainingSeconds(DateTime now, {int period = 30}) {
    final safePeriod = period <= 0 ? 30 : period;
    final elapsed = now.millisecondsSinceEpoch ~/ 1000;
    final remain = safePeriod - (elapsed % safePeriod);
    return remain == 0 ? safePeriod : remain;
  }

  static String generateCode({
    required String secret,
    required DateTime now,
    int period = 30,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    final safePeriod = period <= 0 ? 30 : period;
    final safeDigits = digits.clamp(6, 8);
    final counter = (now.millisecondsSinceEpoch ~/ 1000) ~/ safePeriod;
    final key = _decodeBase32(secret);
    final message = _counterBytes(counter);
    final hash = _hmacDigest(
      key: key,
      message: message,
      algorithm: algorithm,
    );

    final offset = hash.last & 0x0F;
    final binary = ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);
    final modulo = _pow10(safeDigits);
    final otp = binary % modulo;

    return otp.toString().padLeft(safeDigits, '0');
  }

  static Uint8List _counterBytes(int counter) {
    final bytes = Uint8List(8);
    for (var i = 7; i >= 0; i--) {
      bytes[i] = counter & 0xFF;
      counter = counter >> 8;
    }
    return bytes;
  }

  static Uint8List _hmacDigest({
    required Uint8List key,
    required Uint8List message,
    required String algorithm,
  }) {
    final normalized = algorithm.toUpperCase().trim();
    final hmac = switch (normalized) {
      'SHA256' => Hmac(sha256, key),
      'SHA512' => Hmac(sha512, key),
      _ => Hmac(sha1, key),
    };
    return Uint8List.fromList(hmac.convert(message).bytes);
  }

  static int _pow10(int exponent) {
    var value = 1;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }

  static Uint8List _decodeBase32(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
    if (cleaned.isEmpty) {
      throw const FormatException('secret が空です');
    }

    var bits = 0;
    var buffer = 0;
    final output = <int>[];

    for (final codeUnit in cleaned.codeUnits) {
      final value = alphabet.indexOf(String.fromCharCode(codeUnit));
      if (value < 0) {
        throw const FormatException('secret は Base32 形式で入力してください');
      }
      buffer = (buffer << 5) | value;
      bits += 5;

      while (bits >= 8) {
        bits -= 8;
        output.add((buffer >> bits) & 0xFF);
      }
    }
    return Uint8List.fromList(output);
  }
}
