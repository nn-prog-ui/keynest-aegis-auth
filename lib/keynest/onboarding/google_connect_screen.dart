import 'package:flutter/material.dart';

import '../aegis_palette.dart';
import '../google/google_auth_service.dart';
import '../import/import_candidate_preview_screen.dart';
import '../import/import_pipeline.dart';
import '../service_account_add_screen.dart';
import '../service_search_screen.dart';

class GoogleConnectScreen extends StatefulWidget {
  const GoogleConnectScreen({super.key});

  @override
  State<GoogleConnectScreen> createState() => _GoogleConnectScreenState();
}

class _GoogleConnectScreenState extends State<GoogleConnectScreen> {
  final _googleAuthService = GoogleAuthService();

  bool _isConnecting = false;

  Future<void> _findWithGoogle() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final account = await _googleAuthService.signIn();
      if (!mounted) {
        return;
      }
      if (account == null) {
        _showSnack('操作をキャンセルしました');
        return;
      }

      final candidates = await ImportPipeline(
        googleAuthService: _googleAuthService,
      ).previewGmail();

      if (!mounted) {
        return;
      }
      final result = await Navigator.of(context).push<ServiceAccountSaveResult>(
        MaterialPageRoute(
          builder: (_) => ImportCandidatePreviewScreen(
            candidates: candidates,
          ),
        ),
      );
      if (!mounted || result == null) {
        return;
      }
      Navigator.of(context).pop(result);
    } on GoogleAuthException catch (error) {
      _showGoogleFailure(error);
    } on ImportPipelineException catch (error) {
      _showImportFailure(error);
    } catch (_) {
      _showGoogleFailure();
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _openManualAdd() async {
    final result = await Navigator.of(context).push<ServiceAccountSaveResult>(
      MaterialPageRoute(builder: (_) => const ServiceSearchScreen()),
    );
    if (!mounted || result == null) {
      return;
    }
    Navigator.of(context).pop(result);
  }

  void _showComingSoon(String label) {
    _showSnack('$label は近日対応です');
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showGoogleFailure([GoogleAuthException? error]) {
    if (error?.isPermissionDenied ?? false) {
      _showFailureSnack();
      return;
    }
    _showFailureSnack(primaryMessage: error?.message ?? 'サービスを見つけられませんでした');
  }

  void _showImportFailure(ImportPipelineException error) {
    final message = error.message;
    if (message.contains('Gmailの権限') || message.contains('Googleアクセストークン')) {
      _showFailureSnack();
      return;
    }
    _showFailureSnack(primaryMessage: message);
  }

  void _showFailureSnack({
    String primaryMessage = 'サービスを見つけられませんでした',
  }) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(primaryMessage),
            const SizedBox(height: 4),
            const Text('Gmailの権限がまだ許可されていない可能性があります'),
            const SizedBox(height: 4),
            const Text('あとで再試行できます'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('データを追加'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const _WelcomeCard(),
            const SizedBox(height: 14),
            const Text(
              'あなたが利用しているサービスを見つけます。',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'どこから始めますか？',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SourceCard(
              icon: Icons.account_circle_outlined,
              title: 'Google',
              description: '領収書や利用中のサービスを見つけます。',
              enabled: !_isConnecting,
              trailing: _isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: _isConnecting ? null : _findWithGoogle,
            ),
            _SourceCard(
              icon: Icons.apple,
              title: 'Apple',
              description: '近日対応',
              enabled: false,
              onTap: () => _showComingSoon('Apple'),
            ),
            _SourceCard(
              icon: Icons.alternate_email_rounded,
              title: 'メールアドレス',
              description: '近日対応',
              enabled: false,
              onTap: () => _showComingSoon('メールアドレス'),
            ),
            _SourceCard(
              icon: Icons.description_outlined,
              title: 'CSV',
              description: '近日対応',
              enabled: false,
              onTap: () => _showComingSoon('CSV'),
            ),
            _SourceCard(
              icon: Icons.edit_outlined,
              title: '手動で追加',
              description: 'サービスを選んで、IDとパスワードを登録します。',
              onTap: _openManualAdd,
            ),
            const SizedBox(height: 14),
            const _SafetyNoteCard(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 34,
              color: AegisPalette.brand,
            ),
            SizedBox(height: 16),
            Text(
              'Felaへようこそ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'デジタルライフを、もっとシンプルに。',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'サブスクや毎月のお支払い、ログイン情報をまとめて整理します。',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.enabled = true,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AegisPalette.brand : const Color(0xFF9CA3AF);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? Colors.black : const Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Icon(
                    enabled ? Icons.chevron_right_rounded : Icons.schedule,
                    color: enabled ? null : const Color(0xFF9CA3AF),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyNoteCard extends StatelessWidget {
  const _SafetyNoteCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(
              Icons.lock_outline_rounded,
              color: AegisPalette.brand,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '勝手に保存することはありません。内容を確認してから登録できます。',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
