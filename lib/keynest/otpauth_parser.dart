import 'package:flutter/foundation.dart';

import 'models.dart';

class OtpAuthParser {
  static VerificationAccount parseUri({
    required String raw,
    required String id,
  }) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'otpauth') {
      throw const FormatException('QRコードがotpauth形式ではありません');
    }
    if (uri.host.toLowerCase() != 'totp') {
      throw const FormatException('TOTP形式のみ対応しています');
    }

    final secret = (uri.queryParameters['secret'] ?? '').trim();
    if (secret.isEmpty) {
      throw const FormatException('secret が見つかりません');
    }

    final rawLabel = Uri.decodeComponent(uri.path).replaceFirst('/', '').trim();
    String issuerFromLabel = '';
    String account = rawLabel;
    if (rawLabel.contains(':')) {
      final parts = rawLabel.split(':');
      issuerFromLabel = parts.first.trim();
      account = parts.sublist(1).join(':').trim();
    }

    final issuer = (uri.queryParameters['issuer'] ?? issuerFromLabel).trim();
    final rawDigits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6;
    final digits = rawDigits.clamp(6, 8);
    final rawPeriod = int.tryParse(uri.queryParameters['period'] ?? '') ?? 30;
    final period = rawPeriod.clamp(15, 120);
    final algorithm =
        (uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase().trim();

    final normalizedIssuer = issuer.isEmpty ? 'KeyNest' : issuer;
    final normalizedAccount = account.isEmpty ? 'account@example.com' : account;

    return VerificationAccount(
      id: id,
      organization: normalizedIssuer,
      email: normalizedAccount,
      secret: secret,
      issuer: normalizedIssuer,
      digits: digits,
      period: period,
      algorithm: _safeAlgorithm(algorithm),
    );
  }

  static String _safeAlgorithm(String value) {
    switch (value) {
      case 'SHA1':
      case 'SHA256':
      case 'SHA512':
        return value;
      default:
        debugPrint('Unsupported algorithm: $value. fallback to SHA1');
        return 'SHA1';
    }
  }
}
