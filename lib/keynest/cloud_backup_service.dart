import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class CloudBackupResult {
  CloudBackupResult({
    required this.backupId,
    required this.updatedAt,
    this.usedLocalFallback = false,
  });

  final String backupId;
  final DateTime updatedAt;
  final bool usedLocalFallback;
}

class CloudBackupLoadResult {
  CloudBackupLoadResult({
    required this.payload,
    this.usedLocalFallback = false,
  });

  final KeyNestBackupPayload payload;
  final bool usedLocalFallback;
}

class CloudBackupService {
  CloudBackupService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'KEYNEST_API_URL',
      defaultValue: 'http://localhost:3000',
    ),
  }) : _client = client ?? http.Client();

  static const int _kdfIterations = 210000;
  static const String _localShadowPrefix = 'aegisauth.cloud.shadow.v1.';

  final http.Client _client;
  final String baseUrl;

  Future<CloudBackupResult> saveBackup({
    required String passphrase,
    String? backupId,
    required KeyNestBackupPayload payload,
  }) async {
    if (passphrase.trim().length < 6) {
      throw Exception('合言葉は6文字以上にしてください');
    }

    final encrypted = await _encryptPayload(
      passphrase: passphrase,
      payload: payload,
    );

    final normalizedBackupId = backupId?.trim() ?? '';
    final fallbackBackupId =
        normalizedBackupId.isEmpty ? _generateBackupId() : normalizedBackupId;

    try {
      final uri = Uri.parse('$baseUrl/api/keynest/backup/save');
      final response = await _client.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'backupId': normalizedBackupId.isEmpty ? null : normalizedBackupId,
          'encryptedPayload': encrypted,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('クラウド保存に失敗しました (${response.statusCode})');
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final resolvedBackupId = (map['backupId'] as String?)?.trim();
      final backupIdValue = (resolvedBackupId?.isNotEmpty ?? false)
          ? resolvedBackupId!
          : fallbackBackupId;
      await _saveLocalShadow(backupIdValue, encrypted);
      return CloudBackupResult(
        backupId: backupIdValue,
        updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      await _saveLocalShadow(fallbackBackupId, encrypted);
      return CloudBackupResult(
        backupId: fallbackBackupId,
        updatedAt: DateTime.now(),
        usedLocalFallback: true,
      );
    }
  }

  Future<CloudBackupLoadResult> loadBackup({
    required String backupId,
    required String passphrase,
  }) async {
    if (backupId.trim().isEmpty) {
      throw Exception('バックアップIDを入力してください');
    }
    if (passphrase.trim().length < 6) {
      throw Exception('合言葉は6文字以上にしてください');
    }

    final normalizedBackupId = backupId.trim();

    try {
      final uri = Uri.parse('$baseUrl/api/keynest/backup/load');
      final response = await _client.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'backupId': normalizedBackupId}),
      );
      if (response.statusCode != 200) {
        throw Exception('クラウド復元に失敗しました (${response.statusCode})');
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final encrypted = (map['encryptedPayload'] as String?) ?? '';
      if (encrypted.isEmpty) {
        throw Exception('バックアップデータが空です');
      }

      await _saveLocalShadow(normalizedBackupId, encrypted);
      final payload = await _decryptPayload(
        passphrase: passphrase,
        encryptedPayload: encrypted,
      );
      return CloudBackupLoadResult(payload: payload);
    } catch (_) {
      final shadow = await _loadLocalShadow(normalizedBackupId);
      if (shadow == null || shadow.isEmpty) {
        rethrow;
      }
      final payload = await _decryptPayload(
        passphrase: passphrase,
        encryptedPayload: shadow,
      );
      return CloudBackupLoadResult(
        payload: payload,
        usedLocalFallback: true,
      );
    }
  }

  Future<String> _encryptPayload({
    required String passphrase,
    required KeyNestBackupPayload payload,
  }) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveKey(passphrase: passphrase, salt: salt);

    final algorithm = AesGcm.with256bits();
    final clearText = utf8.encode(jsonEncode(payload.toJson()));
    final secretBox = await algorithm.encrypt(
      clearText,
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'v': 2,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': _kdfIterations,
      'cipher': 'AES-256-GCM',
      'salt': _base64UrlEncode(salt),
      'nonce': _base64UrlEncode(secretBox.nonce),
      'mac': _base64UrlEncode(secretBox.mac.bytes),
      'data': _base64UrlEncode(secretBox.cipherText),
    });
  }

  Future<KeyNestBackupPayload> _decryptPayload({
    required String passphrase,
    required String encryptedPayload,
  }) async {
    final wrapper = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    final version = (wrapper['v'] as num?)?.toInt() ?? 1;

    if (version < 2) {
      throw Exception('古いバックアップ形式です。最新版で再保存してください');
    }

    final salt = _base64UrlDecode((wrapper['salt'] as String?) ?? '');
    final nonce = _base64UrlDecode((wrapper['nonce'] as String?) ?? '');
    final macBytes = _base64UrlDecode((wrapper['mac'] as String?) ?? '');
    final cipherText = _base64UrlDecode((wrapper['data'] as String?) ?? '');

    if (salt.isEmpty ||
        nonce.isEmpty ||
        macBytes.isEmpty ||
        cipherText.isEmpty) {
      throw Exception('バックアップ形式が不正です');
    }

    final secretKey = await _deriveKey(passphrase: passphrase, salt: salt);
    final algorithm = AesGcm.with256bits();

    try {
      final clearText = await algorithm.decrypt(
        SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        ),
        secretKey: secretKey,
      );

      final map = jsonDecode(utf8.decode(clearText)) as Map<String, dynamic>;
      return KeyNestBackupPayload.fromJson(map);
    } catch (_) {
      throw Exception('合言葉が違うか、バックアップが壊れています');
    }
  }

  Future<SecretKey> _deriveKey({
    required String passphrase,
    required List<int> salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _kdfIterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  String _base64UrlEncode(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  List<int> _base64UrlDecode(String encoded) {
    if (encoded.trim().isEmpty) {
      return <int>[];
    }
    final normalized = encoded.padRight((encoded.length + 3) ~/ 4 * 4, '=');
    return base64Url.decode(normalized);
  }

  Future<void> _saveLocalShadow(String backupId, String encryptedPayload) async {
    if (backupId.trim().isEmpty || encryptedPayload.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_localShadowPrefix${backupId.trim()}',
      encryptedPayload,
    );
  }

  Future<String?> _loadLocalShadow(String backupId) async {
    if (backupId.trim().isEmpty) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_localShadowPrefix${backupId.trim()}');
  }

  String _generateBackupId() {
    final random = Random.secure();
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final chars = List<String>.generate(10, (_) {
      return alphabet[random.nextInt(alphabet.length)];
    }).join();
    return 'AA-$chars';
  }
}
