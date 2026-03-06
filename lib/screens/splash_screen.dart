import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';
import '../services/gmail_service.dart';
import '../services/subscription_service.dart';
import '../theme/venemo_design.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GmailService _gmailService = GmailService();
  final AppSettingsService _settingsService = AppSettingsService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 体感を速くするため最小限のみ表示
      await Future.delayed(const Duration(milliseconds: 350));

      // 保存済みサーバーセッションを復元
      await _gmailService.restoreServerSessionIfNeeded();

      // ログイン状態を確認
      final isSignedIn = _gmailService.isSignedIn();
      if (isSignedIn) {
        await _subscriptionService.refreshStatus();
      }
      final onboardingCompleted = _settingsService.getSwitch(
        'onboarding_completed',
        fallback: false,
      );

      if (mounted) {
        if (!onboardingCompleted) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else if (isSignedIn) {
          // ログイン済み → メール一覧へ
          Navigator.pushReplacementNamed(context, '/mail_list');
        } else {
          // 未ログイン → ログイン画面へ
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('❌ 初期化エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初期化に失敗しました: $e')),
        );
        // エラーでもログイン画面へ
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SparkBackground(
        withClouds: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FrostedPanel(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: VenemoPalette.panelDark),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 56,
                      color: VenemoPalette.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Venemo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: VenemoPalette.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '受信トレイを AI で整理する',
                    style: TextStyle(
                      fontSize: 16,
                      color: VenemoPalette.textSub,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(VenemoPalette.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
