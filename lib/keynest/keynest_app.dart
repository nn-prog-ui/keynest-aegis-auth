import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'device_auth_service_stub.dart'
    if (dart.library.io) 'device_auth_service_native.dart';
import 'cloud_backup_service.dart';
import 'keynest_storage.dart';
import 'models.dart';
import 'one_time_code_service.dart';
import 'otpauth_parser.dart';
import 'push_gateway_service.dart';
import 'push_notification_service.dart';
import 'qr_scan_screen.dart';

class AegisPalette {
  static const Color brand = Color(0xFF0B8F6D);
  static const Color brandSecondary = Color(0xFF0AA57D);
  static const Color brandSoft = Color(0xFFD7F2E8);
  static const Color brandOnDark = Color(0xFFDAF5EB);
  static const Color bg = Color(0xFFF4FBF8);
  static const Color border = Color(0xFFCDE5DC);
}

class AegisAuthApp extends StatelessWidget {
  const AegisAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AegisPalette.brand,
          secondary: AegisPalette.brandSecondary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AegisPalette.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AegisPalette.border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AegisPalette.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AegisPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AegisPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AegisPalette.brand, width: 1.5),
          ),
        ),
      ),
      home: const KeyNestHomeScreen(),
    );
  }
}

class KeyNestApp extends AegisAuthApp {
  const KeyNestApp({super.key});
}

class KeyNestHomeScreen extends StatefulWidget {
  const KeyNestHomeScreen({super.key});

  @override
  State<KeyNestHomeScreen> createState() => _KeyNestHomeScreenState();
}

class _KeyNestHomeScreenState extends State<KeyNestHomeScreen>
    with WidgetsBindingObserver {
  static const bool _temporarilyDisableDeviceLock = false;

  final KeyNestStorage _storage = KeyNestStorage();
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  final CloudBackupService _cloudBackupService = CloudBackupService();
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final PushGatewayService _pushGatewayService = PushGatewayService();
  final MobileScannerController _imageScannerController =
      MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );
  final Random _random = Random();

  List<VerificationAccount> _accounts = [];
  List<SignInRequest> _requests = [];
  List<String> _backupCodes = [];

  late final Timer _ticker;
  DateTime _now = DateTime.now();

  bool _deviceLockEnabled = true;
  bool _introCompleted = false;
  bool _isUnlocked = true;
  bool _isUnlocking = false;
  bool _isLoading = true;
  bool _isCloudProcessing = false;
  bool _isPushProcessing = false;
  bool _pushInitialized = false;
  bool _pushGranted = false;
  int _selectedTab = 0;
  DateTime? _ignoreLifecycleUntil;
  String? _cloudBackupId;
  String? _deviceId;
  String? _pushFcmToken;
  String? _pushApnsToken;
  String? _pushError;
  DateTime? _lastUnlockedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _requests = [
      SignInRequest(
        id: 'r1',
        organization: 'ATKO',
        location: 'Tokyo, JP',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        status: RequestStatus.pending,
      ),
    ];

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });

    unawaited(_loadLocalState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.cancel();
    unawaited(_pushNotificationService.dispose());
    _imageScannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_temporarilyDisableDeviceLock || !_deviceLockEnabled || _isUnlocking) {
      return;
    }

    final ignoreUntil = _ignoreLifecycleUntil;
    if (ignoreUntil != null && DateTime.now().isBefore(ignoreUntil)) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.resumed) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_isUnlocked && mounted) {
        setState(() {
          _isUnlocked = false;
        });
      }
    }
  }

  Future<void> _loadLocalState() async {
    final accounts = await _storage.loadAccounts();
    final backupCodes = await _storage.loadBackupCodes();
    final deviceLockEnabled = await _storage.loadDeviceLockEnabled();
    final cloudBackupId = await _storage.loadCloudBackupId();
    final storedDeviceId = await _storage.loadDeviceId();
    final storedFcmToken = await _storage.loadFcmToken();
    final storedApnsToken = await _storage.loadApnsToken();
    final introCompleted = await _storage.loadIntroCompleted();
    final resolvedDeviceId = storedDeviceId ?? _newDeviceId();
    final effectiveDeviceLockEnabled =
        _temporarilyDisableDeviceLock ? false : deviceLockEnabled;

    if (!mounted) return;

    setState(() {
      _accounts = accounts;
      _backupCodes = backupCodes;
      _deviceLockEnabled = effectiveDeviceLockEnabled;
      _introCompleted = introCompleted;
      _isUnlocked = !effectiveDeviceLockEnabled || !introCompleted;
      _cloudBackupId = cloudBackupId;
      _deviceId = resolvedDeviceId;
      _pushFcmToken = storedFcmToken;
      _pushApnsToken = storedApnsToken;
      _isLoading = false;
    });

    if (storedDeviceId == null) {
      await _storage.saveDeviceId(resolvedDeviceId);
    }

    await _initializePushNotifications();
    if (introCompleted && effectiveDeviceLockEnabled) {
      await _ensureUnlocked(force: true);
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  String _newDeviceId() {
    final number = 100000 + _random.nextInt(900000);
    return 'kn-device-$number-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _persistAccounts() async {
    await _storage.saveAccounts(_accounts);
  }

  Future<void> _persistBackupCodes() async {
    await _storage.saveBackupCodes(_backupCodes);
  }

  Future<void> _setDeviceLockEnabled(bool value) async {
    if (_temporarilyDisableDeviceLock) {
      _showSnack('デバイスロックは現在一時的に無効化されています');
      return;
    }
    if (value) {
      final unlocked = await _ensureUnlocked(
        force: true,
        reason: 'デバイス保護を有効化するため認証してください',
      );
      if (!unlocked) {
        _showSnack('認証できなかったため、デバイス保護を有効化できませんでした');
        return;
      }
    }

    setState(() {
      _deviceLockEnabled = value;
      if (!value) {
        _isUnlocked = true;
      }
    });
    await _storage.saveDeviceLockEnabled(value);
  }

  Future<bool> _ensureUnlocked({
    bool force = false,
    String reason = 'KeyNestを開くために認証してください',
  }) async {
    if (!_deviceLockEnabled) {
      if (!_isUnlocked && mounted) {
        setState(() {
          _isUnlocked = true;
        });
      }
      return true;
    }
    if (_isUnlocking) {
      return false;
    }
    if (!force && _isUnlocked) {
      return true;
    }

    final now = DateTime.now();
    if (!force &&
        _lastUnlockedAt != null &&
        now.difference(_lastUnlockedAt!) < const Duration(seconds: 20)) {
      return true;
    }

    _ignoreLifecycleUntil = DateTime.now().add(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isUnlocking = true;
      });
    }

    final available = await _deviceAuthService.isDeviceAuthAvailable();
    final unlocked = available
        ? await _deviceAuthService.authenticate(reason: reason)
        : true;

    if (!mounted) return unlocked;
    setState(() {
      _isUnlocking = false;
      _isUnlocked = unlocked;
      _ignoreLifecycleUntil = DateTime.now().add(const Duration(seconds: 3));
      if (unlocked) {
        _lastUnlockedAt = DateTime.now();
      }
    });
    return unlocked;
  }

  Widget _buildLockGate() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F7F1), Color(0xFFF8FCFA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AegisPalette.brand,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'KeyNest',
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 0.3,
                            fontWeight: FontWeight.w700,
                            color: AegisPalette.brand,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '保護されたアクセス',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'この端末のコードと承認リクエストを表示するには認証が必要です。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isUnlocking
                              ? null
                              : () {
                                  unawaited(_ensureUnlocked(force: true));
                                },
                          icon: _isUnlocking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.fingerprint_rounded),
                          label: Text(_isUnlocking ? '認証中...' : 'ロック解除'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeIntro() async {
    setState(() {
      _introCompleted = true;
    });
    await _storage.saveIntroCompleted(true);
    await _ensureUnlocked(force: true);
  }

  Widget _buildWelcomeGate() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFFAF6), Color(0xFFF6FBF9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AegisPalette.brand,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to KeyNest',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '組織アカウントの多要素認証を、このアプリで安全に管理できます。',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '主な機能',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('1. QR読み取りで認証アカウント登録'),
                        const SizedBox(height: 6),
                        const Text('2. ワンタイムコード (TOTP) の自動更新'),
                        const SizedBox(height: 6),
                        const Text('3. Push承認リクエストのApprove / Deny'),
                        const SizedBox(height: 6),
                        const Text('4. 暗号化クラウドバックアップ/復元'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _completeIntro,
                            child: const Text('Get started'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _platformName {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'unknown',
    };
  }

  Future<void> _initializePushNotifications() async {
    final snapshot = await _pushNotificationService.initialize(
      onForegroundMessage: (message) {
        _maybeAppendRequestFromPush(message.data);
        final title =
            message.notification?.title ?? message.data['title']?.toString();
        final body =
            message.notification?.body ?? message.data['body']?.toString();
        final text = [title, body].whereType<String>().join('\n').trim();
        if (text.isNotEmpty) {
          _showSnack('Push受信:\n$text');
        } else {
          _showSnack('Push通知を受信しました');
        }
      },
      onTokenRefresh: (token) {
        setState(() {
          _pushFcmToken = token;
        });
        unawaited(_storage.saveFcmToken(token));
        unawaited(_registerPushToken());
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _pushInitialized = snapshot.initialized;
      _pushGranted = snapshot.granted;
      _pushError = snapshot.errorMessage;
      if (snapshot.fcmToken != null && snapshot.fcmToken!.isNotEmpty) {
        _pushFcmToken = snapshot.fcmToken;
      }
      if (snapshot.apnsToken != null && snapshot.apnsToken!.isNotEmpty) {
        _pushApnsToken = snapshot.apnsToken;
      }
    });

    if (_pushFcmToken != null && _pushFcmToken!.isNotEmpty) {
      await _storage.saveFcmToken(_pushFcmToken!);
      if (_pushApnsToken != null && _pushApnsToken!.isNotEmpty) {
        await _storage.saveApnsToken(_pushApnsToken!);
      }
      await _registerPushToken();
    }
  }

  Future<void> _registerPushToken() async {
    if (_deviceId == null ||
        _deviceId!.isEmpty ||
        _pushFcmToken == null ||
        _pushFcmToken!.isEmpty) {
      return;
    }
    try {
      await _pushGatewayService.registerDevice(
        deviceId: _deviceId!,
        platform: _platformName,
        fcmToken: _pushFcmToken!,
        apnsToken: _pushApnsToken,
      );
    } catch (_) {}
  }

  Future<void> _sendPushTest() async {
    if (_deviceId == null || _deviceId!.isEmpty) {
      _showSnack('デバイスIDが未設定です');
      return;
    }
    setState(() {
      _isPushProcessing = true;
    });
    try {
      await _registerPushToken();
      await _pushGatewayService.sendTestPush(deviceId: _deviceId!);
      _showSnack('テスト通知を送信しました');
    } catch (error) {
      _showSnack('テスト通知に失敗しました: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPushProcessing = false;
        });
      }
    }
  }

  void _addMockRequest() {
    final id = 'r${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _requests.insert(
        0,
        SignInRequest(
          id: id,
          organization:
              _accounts.isNotEmpty ? _accounts.first.organization : 'Aegis',
          location: 'Remote device',
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _maybeAppendRequestFromPush(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase();
    if (type != 'signin_request' && type != 'approval_request') {
      return;
    }
    final requestId = data['requestId']?.toString().trim();
    if (requestId != null &&
        requestId.isNotEmpty &&
        _requests.any((item) => item.id == requestId)) {
      return;
    }
    final organization =
        data['organization']?.toString().trim().isNotEmpty == true
            ? data['organization']!.toString().trim()
            : (_accounts.isNotEmpty ? _accounts.first.organization : 'Aegis');
    final location = data['location']?.toString().trim().isNotEmpty == true
        ? data['location']!.toString().trim()
        : 'Unknown';
    final createdAt = DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final newRequest = SignInRequest(
      id: requestId == null || requestId.isEmpty ? _newId() : requestId,
      organization: organization,
      location: location,
      createdAt: createdAt,
      status: RequestStatus.pending,
    );
    if (!mounted) return;
    setState(() {
      _requests = [newRequest, ..._requests];
      _selectedTab = 1;
    });
  }

  void _updateRequestStatus(SignInRequest request, RequestStatus status) {
    setState(() {
      request.status = status;
    });
  }

  int get _safetyScore {
    var score = 40;
    if (_deviceLockEnabled) score += 25;
    if (_accounts.isNotEmpty) score += 20;
    if (_backupCodes.isNotEmpty) score += 10;
    if (_cloudBackupId != null && _cloudBackupId!.isNotEmpty) score += 5;
    return score.clamp(0, 100);
  }

  String get _safetyLabel {
    final score = _safetyScore;
    if (score >= 80) return 'とても良い';
    if (score >= 60) return '良い';
    return 'もう少し';
  }

  void _generateBackupCodes() {
    final codes = List<String>.generate(8, (_) {
      final value = 10000000 + _random.nextInt(90000000);
      return value.toString();
    });

    setState(() {
      _backupCodes = codes;
    });
    unawaited(_persistBackupCodes());
  }

  Future<void> _showBackupCodesSheet() async {
    if (_backupCodes.isEmpty) {
      _generateBackupCodes();
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '緊急用バックアップコード',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'スマホが使えないときにログインできる予備コードです。',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _backupCodes
                    .map(
                      (code) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _backupCodes.join('\n')),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('バックアップコードをコピーしました')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('すべてコピー'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddAccountMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded),
                  title: const Text('QRコードを読み取る'),
                  subtitle: const Text('otpauth形式を自動で登録'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _scanQrAndAdd();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_search_rounded),
                  title: const Text('QR画像から登録'),
                  subtitle: const Text('カメラ不可でも画像から読み取り'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickQrImageAndAdd();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_paste_search_rounded),
                  title: const Text('クリップボード自動登録'),
                  subtitle: const Text('貼り付け内容を自動判定して登録'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _registerFromClipboardAuto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('otpauthリンクを貼り付け'),
                  subtitle: const Text('コピー済みURLをそのまま登録'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _showOtpAuthPasteDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: const Text('手動で追加'),
                  subtitle: const Text('組織・メール・Base32シークレットを入力'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _showAddAccountSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scanQrAndAdd() async {
    try {
      final value = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const QrScanScreen()),
      );
      if (!mounted || value == null) return;
      await _registerFromOtpAuth(value);
    } catch (error) {
      if (!mounted) return;
      _showSnack('QR読み取りを開始できませんでした: $error');
    }
  }

  String? _detectOtpAuthCandidate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('otpauth://')) {
      return trimmed;
    }

    final match = RegExp(r'otpauth://\S+').firstMatch(trimmed);
    if (match != null) {
      return match.group(0);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      for (final value in uri.queryParameters.values) {
        final decoded = Uri.decodeComponent(value);
        if (decoded.startsWith('otpauth://')) {
          return decoded;
        }
      }
    }
    return null;
  }

  Future<void> _registerFromClipboardAuto() async {
    final clipboard = await Clipboard.getData('text/plain');
    final text = clipboard?.text ?? '';
    final candidate = _detectOtpAuthCandidate(text);
    if (candidate == null) {
      _showSnack('クリップボードにotpauthリンクが見つかりません');
      return;
    }
    await _registerFromOtpAuth(candidate);
  }

  Future<void> _pickQrImageAndAdd() async {
    if (kIsWeb) {
      _showSnack('Webでは画像QR解析に未対応です。リンク貼り付けをご利用ください');
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final path = picked.files.single.path;
    if (path == null || path.isEmpty) {
      _showSnack('画像パスを取得できませんでした');
      return;
    }

    try {
      final capture = await _imageScannerController.analyzeImage(path);
      String? raw;
      for (final barcode in capture?.barcodes ?? <Barcode>[]) {
        final value = barcode.rawValue?.trim();
        if (value != null && value.isNotEmpty) {
          raw = value;
          break;
        }
      }

      if (raw == null) {
        _showSnack('画像内のQRコードを検出できませんでした');
        return;
      }

      final candidate = _detectOtpAuthCandidate(raw);
      if (candidate == null) {
        _showSnack('QRは読み取れましたがotpauth形式ではありません');
        return;
      }

      await _registerFromOtpAuth(candidate);
    } catch (error) {
      _showSnack('画像QR読み取りに失敗しました: $error');
    }
  }

  Future<void> _showOtpAuthPasteDialog() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('otpauthリンクを貼り付け'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'otpauth://totp/Issuer:email?secret=...&issuer=Issuer',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                final raw = controller.text.trim();
                Navigator.of(context).pop();
                await _registerFromOtpAuth(raw);
              },
              child: const Text('登録'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerFromOtpAuth(String raw) async {
    try {
      final account = OtpAuthParser.parseUri(raw: raw, id: _newId());
      final _ = OneTimeCodeService.generateCode(
        secret: account.secret,
        now: DateTime.now(),
        period: account.period,
        digits: account.digits,
        algorithm: account.algorithm,
      );

      setState(() {
        _accounts = [account, ..._accounts];
      });
      await _persistAccounts();
      if (!mounted) return;
      _showSnack('QRからアカウントを登録しました');
    } catch (error) {
      _showSnack('登録に失敗しました: $error');
    }
  }

  Future<void> _showAddAccountSheet() async {
    final orgController = TextEditingController();
    final emailController = TextEditingController();
    final secretController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, insets + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '手動でアカウント登録',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: orgController,
                  decoration:
                      const InputDecoration(labelText: '組織コード / Issuer'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '組織コードを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: secretController,
                  decoration: const InputDecoration(
                    labelText: 'Base32 シークレット',
                    hintText: 'JBSWY3DPEHPK3PXP',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'シークレットを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final org = orgController.text.trim();
                      final email = emailController.text.trim();
                      final secret = secretController.text
                          .trim()
                          .toUpperCase()
                          .replaceAll(' ', '');

                      try {
                        final _ = OneTimeCodeService.generateCode(
                          secret: secret,
                          now: DateTime.now(),
                        );

                        final account = VerificationAccount(
                          id: _newId(),
                          organization: org.toUpperCase(),
                          email: email,
                          issuer: org,
                          secret: secret,
                        );

                        setState(() {
                          _accounts = [account, ..._accounts];
                        });
                        await _persistAccounts();
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                        _showSnack('アカウントを登録しました');
                      } catch (error) {
                        _showSnack('シークレット形式が正しくありません: $error');
                      }
                    },
                    child: const Text('登録する'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCloudBackupSheet() async {
    final backupIdController =
        TextEditingController(text: _cloudBackupId ?? '');
    final passphraseController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, insets + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'クラウドバックアップ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '新しい端末では「バックアップID + 合言葉」で復元できます。',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: backupIdController,
                decoration: const InputDecoration(
                  labelText: 'バックアップID（初回保存時は空欄でOK）',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passphraseController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '合言葉（6文字以上）',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _isCloudProcessing
                          ? null
                          : () async {
                              await _saveToCloud(
                                backupIdInput: backupIdController.text,
                                passphrase: passphraseController.text,
                              );
                              if (!mounted) return;
                              Navigator.of(this.context).pop();
                            },
                      child: const Text('保存する'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isCloudProcessing
                          ? null
                          : () async {
                              await _restoreFromCloud(
                                backupId: backupIdController.text,
                                passphrase: passphraseController.text,
                              );
                              if (!mounted) return;
                              Navigator.of(this.context).pop();
                            },
                      child: const Text('復元する'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToCloud({
    required String backupIdInput,
    required String passphrase,
  }) async {
    final normalizedPass = passphrase.trim();
    if (normalizedPass.length < 6) {
      _showSnack('合言葉は6文字以上で入力してください');
      return;
    }

    final payload = KeyNestBackupPayload(
      accounts: _accounts,
      backupCodes: _backupCodes,
      deviceLockEnabled: _deviceLockEnabled,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isCloudProcessing = true;
    });

    try {
      final result = await _cloudBackupService.saveBackup(
        passphrase: normalizedPass,
        backupId: backupIdInput.trim().isEmpty ? null : backupIdInput.trim(),
        payload: payload,
      );

      setState(() {
        _cloudBackupId = result.backupId;
      });
      await _storage.saveCloudBackupId(result.backupId);

      if (!mounted) return;
      _showSnack(
        result.usedLocalFallback
            ? '接続できなかったため、この端末の安全領域に保存しました: ID ${result.backupId}'
            : 'クラウド保存完了: ID ${result.backupId}',
      );
    } catch (error) {
      _showSnack('クラウド保存に失敗しました: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isCloudProcessing = false;
        });
      }
    }
  }

  Future<void> _restoreFromCloud({
    required String backupId,
    required String passphrase,
  }) async {
    if (backupId.trim().isEmpty) {
      _showSnack('バックアップIDを入力してください');
      return;
    }
    if (passphrase.trim().length < 6) {
      _showSnack('合言葉は6文字以上で入力してください');
      return;
    }

    setState(() {
      _isCloudProcessing = true;
    });

    try {
      final loadResult = await _cloudBackupService.loadBackup(
        backupId: backupId.trim(),
        passphrase: passphrase.trim(),
      );
      final payload = loadResult.payload;

      setState(() {
        _accounts = payload.accounts;
        _backupCodes = payload.backupCodes;
        _deviceLockEnabled = payload.deviceLockEnabled;
        _cloudBackupId = backupId.trim();
      });

      await Future.wait([
        _storage.saveAccounts(_accounts),
        _storage.saveBackupCodes(_backupCodes),
        _storage.saveDeviceLockEnabled(_deviceLockEnabled),
        _storage.saveCloudBackupId(backupId.trim()),
      ]);

      if (!mounted) return;
      _showSnack(
        loadResult.usedLocalFallback ? 'オフライン保存データから復元しました' : 'クラウドから復元しました',
      );
    } catch (error) {
      _showSnack('クラウド復元に失敗しました: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isCloudProcessing = false;
        });
      }
    }
  }

  void _removeAccount(VerificationAccount account) {
    setState(() {
      _accounts = _accounts.where((item) => item.id != account.id).toList();
    });
    unawaited(_persistAccounts());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _shortToken(String token) {
    if (token.length <= 16) {
      return token;
    }
    final head = token.substring(0, 8);
    final tail = token.substring(token.length - 8);
    return '$head...$tail';
  }

  Widget _flowBadge(String label, bool done) {
    final color = done ? const Color(0xFF166534) : const Color(0xFF9CA3AF);
    final bg = done ? const Color(0xFFE8F7EE) : const Color(0xFFF3F4F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCheckCard() {
    final hasAccount = _accounts.isNotEmpty;
    final hasCode = hasAccount &&
        OneTimeCodeService.generateCode(
          secret: _accounts.first.secret,
          now: _now,
          period: _accounts.first.period,
          digits: _accounts.first.digits,
          algorithm: _accounts.first.algorithm,
        ).isNotEmpty;
    final hasPendingApproval =
        _requests.any((item) => item.status == RequestStatus.pending);
    final hasBackupId = (_cloudBackupId ?? '').trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '導線チェック',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _flowBadge('追加', hasAccount),
                _flowBadge('コード表示', hasCode),
                _flowBadge('Push承認', hasPendingApproval),
                _flowBadge('クラウド復元', hasBackupId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_introCompleted) {
      return _buildWelcomeGate();
    }
    if (_deviceLockEnabled && !_isUnlocked) {
      return _buildLockGate();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KeyNest', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text(
              'Authenticator + Push approvals',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openCloudBackupSheet,
            icon: const Icon(Icons.cloud_sync_rounded),
            tooltip: 'クラウドバックアップ',
          ),
          if (_selectedTab == 1)
            IconButton(
              onPressed: _addMockRequest,
              icon: const Icon(Icons.add_alert_outlined),
              tooltip: 'テストリクエスト生成',
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _selectedTab == 0 ? _buildCodesTab() : _buildRequestsTab(),
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddAccountMenu,
              icon: const Icon(Icons.add),
              label: const Text('アカウント追加'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'コード',
          ),
          NavigationDestination(
            icon: Icon(Icons.phonelink_lock_outlined),
            selectedIcon: Icon(Icons.phonelink_lock),
            label: '承認',
          ),
        ],
      ),
    );
  }

  Widget _buildCodesTab() {
    return ListView(
      key: const ValueKey('codes-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AegisPalette.brand, AegisPalette.brandSecondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'このアプリでできること',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1) QRを読むだけで登録\n2) 6桁コードで本人確認\n3) Push承認を操作\n4) 機種変更時はクラウド復元',
                style: TextStyle(color: AegisPalette.brandOnDark, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildFlowCheckCard(),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            value: _deviceLockEnabled,
            onChanged: (value) {
              unawaited(_setDeviceLockEnabled(value));
            },
            title: const Text(
              'デバイス保護',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('ロック解除が必要な状態を維持します'),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '安心チェック',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '安全スコア: $_safetyScore点（$_safetyLabel）',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _showBackupCodesSheet,
                    icon: const Icon(Icons.password_rounded),
                    label: Text(
                      _backupCodes.isEmpty ? '緊急用コードを作る' : '緊急用コードを見る',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _openCloudBackupSheet,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _cloudBackupId == null
                          ? 'クラウド保存を設定する'
                          : 'クラウドID: $_cloudBackupId',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Push通知 (FCM/APNs)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _pushInitialized
                      ? (_pushGranted ? '通知権限: 許可済み' : '通知権限: 未許可（OS設定を確認）')
                      : '通知初期化: 未完了',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _pushFcmToken == null
                      ? 'FCMトークン: 未取得'
                      : 'FCMトークン: ${_shortToken(_pushFcmToken!)}',
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                if (_pushApnsToken != null && _pushApnsToken!.isNotEmpty)
                  Text(
                    'APNsトークン: ${_shortToken(_pushApnsToken!)}',
                    style:
                        const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                if (_pushError != null && _pushError!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '初期化エラー: $_pushError',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: _initializePushNotifications,
                        child: const Text('通知を再設定'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isPushProcessing ? null : _sendPushTest,
                        child: const Text('テスト通知'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_accounts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('登録済みアカウントがありません。右下ボタンで追加してください。'),
            ),
          ),
        ..._accounts.map((account) => _buildAccountCard(account)),
        const SizedBox(height: 8),
        const Text(
          'TOTPはRFC6238準拠（SHA1/SHA256/SHA512・6〜8桁）',
          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildAccountCard(VerificationAccount account) {
    String code;
    try {
      code = OneTimeCodeService.generateCode(
        secret: account.secret,
        now: _now,
        period: account.period,
        digits: account.digits,
        algorithm: account.algorithm,
      );
    } catch (_) {
      code = ''.padLeft(account.digits, '-');
    }

    final remaining = OneTimeCodeService.remainingSeconds(
      _now,
      period: account.period,
    );
    final progress = (account.period - remaining) / account.period;
    final formattedCode = code.length == 6
        ? '${code.substring(0, 3)} ${code.substring(3)}'
        : code;
    final badge = account.organization.isNotEmpty
        ? account.organization.substring(0, 1).toUpperCase()
        : 'K';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AegisPalette.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.organization,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.email,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${account.algorithm} / ${account.digits}桁 / ${account.period}s',
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedCode,
                        style: const TextStyle(
                          fontSize: 30,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _removeAccount(account);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('削除'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '次の更新まで ${remaining}s',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$formattedCode をコピーしました')),
                    );
                  },
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: AegisPalette.brandSoft,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AegisPalette.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return ListView(
      key: const ValueKey('requests-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'サインイン承認 (Push)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'この画面でApprove / Denyできます。コード認証と合わせて使います。',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _addMockRequest,
                  icon: const Icon(Icons.bolt),
                  label: const Text('テストリクエストを追加'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_requests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('保留中のリクエストはありません。'),
            ),
          ),
        ..._requests.map(_buildRequestCard),
      ],
    );
  }

  Widget _buildRequestCard(SignInRequest request) {
    final statusColor = switch (request.status) {
      RequestStatus.pending => const Color(0xFFB45309),
      RequestStatus.approved => const Color(0xFF166534),
      RequestStatus.denied => const Color(0xFFB91C1C),
    };

    final statusLabel = switch (request.status) {
      RequestStatus.pending => 'Pending',
      RequestStatus.approved => 'Approved',
      RequestStatus.denied => 'Denied',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  request.organization,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.location,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDateTime(request.createdAt),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              'Request ID: ${request.id}',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (request.status == RequestStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          _updateRequestStatus(request, RequestStatus.approved),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateRequestStatus(request, RequestStatus.denied),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                        side: const BorderSide(color: Color(0xFFB91C1C)),
                      ),
                      child: const Text('Deny'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}/$month/$day $hh:$mm';
  }
}
