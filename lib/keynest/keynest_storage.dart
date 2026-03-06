import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class KeyNestStorage {
  static const _accountsKey = 'aegisauth.accounts.v1';
  static const _backupCodesKey = 'aegisauth.backup_codes.v1';
  static const _deviceLockKey = 'aegisauth.device_lock.v1';
  static const _backupIdKey = 'aegisauth.cloud_backup_id.v1';
  static const _deviceIdKey = 'aegisauth.device_id.v1';
  static const _fcmTokenKey = 'aegisauth.fcm_token.v1';
  static const _apnsTokenKey = 'aegisauth.apns_token.v1';
  static const _introDoneKey = 'aegisauth.intro_done.v1';
  static const _legacyAccountsKey = 'keynest.accounts.v1';
  static const _legacyBackupCodesKey = 'keynest.backup_codes.v1';
  static const _legacyDeviceLockKey = 'keynest.device_lock.v1';
  static const _legacyBackupIdKey = 'keynest.cloud_backup_id.v1';
  static const _legacyDeviceIdKey = 'keynest.device_id.v1';
  static const _legacyFcmTokenKey = 'keynest.fcm_token.v1';
  static const _legacyApnsTokenKey = 'keynest.apns_token.v1';
  static const _legacyIntroDoneKey = 'keynest.intro_done.v1';

  Future<List<VerificationAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_accountsKey);
    if ((raw == null || raw.trim().isEmpty) &&
        prefs.containsKey(_legacyAccountsKey)) {
      raw = prefs.getString(_legacyAccountsKey);
      if (raw != null && raw.trim().isNotEmpty) {
        await prefs.setString(_accountsKey, raw);
      }
    }
    if (raw == null || raw.trim().isEmpty) {
      return <VerificationAccount>[];
    }

    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((map) => VerificationAccount.fromJson(map))
          .where((item) => item.id.isNotEmpty && item.secret.isNotEmpty)
          .toList();
      return list;
    } catch (_) {
      return <VerificationAccount>[];
    }
  }

  Future<void> saveAccounts(List<VerificationAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(accounts.map((item) => item.toJson()).toList());
    await prefs.setString(_accountsKey, raw);
  }

  Future<List<String>> loadBackupCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_backupCodesKey);
    if (current != null) {
      return current;
    }
    final legacy = prefs.getStringList(_legacyBackupCodesKey) ?? <String>[];
    if (legacy.isNotEmpty) {
      await prefs.setStringList(_backupCodesKey, legacy);
    }
    return legacy;
  }

  Future<void> saveBackupCodes(List<String> backupCodes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_backupCodesKey, backupCodes);
  }

  Future<bool> loadDeviceLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_deviceLockKey)) {
      return prefs.getBool(_deviceLockKey) ?? true;
    }
    final legacy = prefs.getBool(_legacyDeviceLockKey);
    if (legacy != null) {
      await prefs.setBool(_deviceLockKey, legacy);
      return legacy;
    }
    return true;
  }

  Future<void> saveDeviceLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceLockKey, value);
  }

  Future<String?> loadCloudBackupId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_backupIdKey);
    if (current != null) {
      return current;
    }
    final legacy = prefs.getString(_legacyBackupIdKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_backupIdKey, legacy);
      return legacy;
    }
    return null;
  }

  Future<void> saveCloudBackupId(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupIdKey, backupId);
  }

  Future<String?> loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_deviceIdKey);
    if (current != null) {
      return current;
    }
    final legacy = prefs.getString(_legacyDeviceIdKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_deviceIdKey, legacy);
      return legacy;
    }
    return null;
  }

  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
  }

  Future<String?> loadFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_fcmTokenKey);
    if (current != null) {
      return current;
    }
    final legacy = prefs.getString(_legacyFcmTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_fcmTokenKey, legacy);
      return legacy;
    }
    return null;
  }

  Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> loadApnsToken() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_apnsTokenKey);
    if (current != null) {
      return current;
    }
    final legacy = prefs.getString(_legacyApnsTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_apnsTokenKey, legacy);
      return legacy;
    }
    return null;
  }

  Future<void> saveApnsToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apnsTokenKey, token);
  }

  Future<bool> loadIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_introDoneKey)) {
      return prefs.getBool(_introDoneKey) ?? false;
    }
    final legacy = prefs.getBool(_legacyIntroDoneKey);
    if (legacy != null) {
      await prefs.setBool(_introDoneKey, legacy);
      return legacy;
    }
    return false;
  }

  Future<void> saveIntroCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introDoneKey, value);
  }
}
