import 'package:flutter/material.dart';

import '../google/google_auth_service.dart';
import '../import/import_candidate_preview_screen.dart';
import '../import/import_pipeline.dart';
import '../service_account_add_screen.dart';

class GoogleConnectScreen extends StatefulWidget {
  const GoogleConnectScreen({super.key});

  @override
  State<GoogleConnectScreen> createState() => _GoogleConnectScreenState();
}

class _GoogleConnectScreenState extends State<GoogleConnectScreen> {
  final _googleAuthService = GoogleAuthService();

  bool _isConnecting = false;

  Future<void> _connectGoogle() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final account = await _googleAuthService.signIn();
      if (!mounted) {
        return;
      }
      if (account == null) {
        _showSnack('Google連携をキャンセルしました');
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
    _showFailureSnack(primaryMessage: error?.message ?? 'Google連携に失敗しました');
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
    String primaryMessage = 'Google連携に失敗しました',
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
        title: const Text('Google連携'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 32),
                    SizedBox(height: 14),
                    Text(
                      'Gmailの領収書から候補を作る',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '今回はダミーデータでプレビューします。Gmail APIやメール本文の読み取りはまだ行いません。',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Felaが行うこと',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _checkLine('Googleアカウント連携を確認'),
                    _checkLine('ダミーの領収書候補を読み込み'),
                    _checkLine('サービス候補とおすすめを表示'),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isConnecting ? null : _connectGoogle,
                        icon: _isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.account_circle_outlined),
                        label: Text(
                          _isConnecting ? '連携中' : 'Googleと連携して候補を見る',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Color(0xFF0B8F6D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
