import 'package:flutter/material.dart';
import '../services/gmail_service.dart';
import '../services/subscription_service.dart';
import '../theme/venemo_design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GmailService _gmailService = GmailService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  MailProvider _selectedProvider = MailProvider.gmail;
  bool _showPasswordLogin = false;
  bool _isLoading = false;
  bool _isLoadingServerConfig = true;
  bool _serverConfigAvailable = false;
  bool _passwordLoginEnabled = false;
  Map<MailProvider, bool> _oauthEnabled = const {
    MailProvider.gmail: true,
    MailProvider.yahoo: true,
    MailProvider.outlook: true,
  };
  static const String _serverStartCommand =
      'cd /Users/nemotonoritake/Documents/venemo_ai_mail/server && npm run start';

  @override
  void initState() {
    super.initState();
    _loadServerProviderConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadServerProviderConfig() async {
    final config = await _gmailService.fetchServerProviderConfig();
    if (!mounted) return;

    setState(() {
      _applyServerProviderConfig(config);
      _isLoadingServerConfig = false;
    });
  }

  void _applyServerProviderConfig(Map<String, dynamic>? config) {
    if (config == null) {
      _serverConfigAvailable = false;
      _passwordLoginEnabled = false;
      _showPasswordLogin = false;
      return;
    }

    final oauthRaw = config['oauthEnabled'];
    final nextOauth = <MailProvider, bool>{
      MailProvider.gmail: true,
      MailProvider.yahoo: true,
      MailProvider.outlook: true,
    };
    if (oauthRaw is Map) {
      bool toFlag(dynamic value) => value == true;
      nextOauth[MailProvider.gmail] = toFlag(oauthRaw['gmail']);
      nextOauth[MailProvider.yahoo] = toFlag(oauthRaw['yahoo']);
      nextOauth[MailProvider.outlook] = toFlag(oauthRaw['outlook']);
    }

    _serverConfigAvailable = true;
    _oauthEnabled = nextOauth;
    _passwordLoginEnabled = config['passwordLoginEnabled'] == true;
    if (!_passwordLoginEnabled) {
      _showPasswordLogin = false;
    }
  }

  Future<bool> _refreshServerProviderConfig(
      {bool showSnackOnFail = true}) async {
    final config = await _gmailService.fetchServerProviderConfig();
    if (!mounted) return false;

    setState(() {
      _applyServerProviderConfig(config);
    });

    if (config == null && showSnackOnFail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'サーバーに接続できません。先に次のコマンドを実行してください:\n$_serverStartCommand',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    return config != null;
  }

  bool _isDirectGoogleOAuthMode() {
    if (_selectedProvider != MailProvider.gmail) {
      return false;
    }
    final gmailServerOAuthEnabled = _oauthEnabled[MailProvider.gmail] == true;
    return !_serverConfigAvailable || !gmailServerOAuthEnabled;
  }

  bool _isOAuthAvailableForSelectedProvider() {
    if (_isDirectGoogleOAuthMode()) {
      return true;
    }
    return _serverConfigAvailable && _oauthEnabled[_selectedProvider] == true;
  }

  bool _isConnectionRefusedError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup');
  }

  Future<bool> _signInWithDirectGoogleOAuth() async {
    final success = await _gmailService.signIn(
      provider: MailProvider.gmail,
      useOAuthForGmail: true,
    );
    if (!mounted) return false;
    if (success) {
      await _subscriptionService.refreshStatus();
      if (!mounted) return false;
      Navigator.pushReplacementNamed(context, '/mail_list');
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_gmailService.lastError ?? 'Googleログインに失敗しました')),
    );
    return false;
  }

  Future<void> _handleLogin() async {
    final serverOk = await _refreshServerProviderConfig();
    if (!serverOk) {
      return;
    }
    if (!_passwordLoginEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サーバー設定でパスワードログインは無効です')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _gmailService.signIn(
        provider: _selectedProvider,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        useOAuthForGmail: false,
      );

      if (mounted) {
        if (success) {
          await _subscriptionService.refreshStatus();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/mail_list');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_gmailService.lastError ?? 'ログインに失敗しました'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインエラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleOAuthLogin() async {
    if (_isDirectGoogleOAuthMode()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _signInWithDirectGoogleOAuth();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Googleログインエラー: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      return;
    }

    final serverOk = await _refreshServerProviderConfig(showSnackOnFail: false);
    if (!serverOk) {
      if (_selectedProvider == MailProvider.gmail) {
        setState(() {
          _serverConfigAvailable = false;
        });
        await _signInWithDirectGoogleOAuth();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'サーバーに接続できません。先に次のコマンドを実行してください:\n$_serverStartCommand',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!_isOAuthAvailableForSelectedProvider()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _serverConfigAvailable
                ? 'このプロバイダは現在OAuth未設定です'
                : 'サーバーに接続できません。先に server を起動してください',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _gmailService.signInWithServerOAuth(
        provider: _selectedProvider,
      );
      if (!mounted) return;
      if (success) {
        await _subscriptionService.refreshStatus();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/mail_list');
      } else {
        final error = _gmailService.lastError ?? 'OAuthログインに失敗しました';
        if (_selectedProvider == MailProvider.gmail &&
            _isConnectionRefusedError(error)) {
          await _signInWithDirectGoogleOAuth();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
      }
    } catch (e) {
      if (_selectedProvider == MailProvider.gmail &&
          _isConnectionRefusedError(e.toString())) {
        await _signInWithDirectGoogleOAuth();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OAuthログインエラー: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _providerName(MailProvider provider) {
    switch (provider) {
      case MailProvider.gmail:
        return 'Gmail';
      case MailProvider.yahoo:
        return 'Yahoo';
      case MailProvider.outlook:
        return 'Outlook';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGmailProvider = _selectedProvider == MailProvider.gmail;
    final requiresCredentialLogin =
        _showPasswordLogin && _passwordLoginEnabled && _serverConfigAvailable;
    final providerName = _providerName(_selectedProvider);
    final oauthAvailable = _isOAuthAvailableForSelectedProvider();
    final isDirectGoogleOAuth = _isDirectGoogleOAuthMode();

    return Scaffold(
      body: SparkBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: FrostedPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: VenemoPalette.panelDark),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 52,
                        color: VenemoPalette.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Venemo',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: VenemoPalette.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'シンプルな受信管理と AI 返信',
                      style: TextStyle(
                        fontSize: 17,
                        color: VenemoPalette.textSub,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final provider in MailProvider.values)
                          ChoiceChip(
                            label: Text(_providerName(provider)),
                            selected: _selectedProvider == provider,
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() {
                                _selectedProvider = provider;
                                _showPasswordLogin = false;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isDirectGoogleOAuth
                          ? 'Gmail は直接OAuthでログインします（推奨）'
                          : '$providerName は OAuth でログインします（推奨）',
                      style: const TextStyle(
                        fontSize: 15,
                        color: VenemoPalette.textSub,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || !oauthAvailable)
                            ? null
                            : _handleOAuthLogin,
                        icon: const Icon(Icons.shield_outlined),
                        label: Text(
                          isDirectGoogleOAuth
                              ? 'Googleでログイン（推奨）'
                              : 'OAuthでログイン（推奨）',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    if (!oauthAvailable)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _serverConfigAvailable
                                ? 'このプロバイダのOAuthはサーバー側で未設定です。'
                                : 'サーバー接続待ちです（http://localhost:3000）。',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: VenemoPalette.textSub,
                            ),
                          ),
                        ),
                      ),
                    if (_isLoadingServerConfig)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ログイン設定を確認中...',
                            style: TextStyle(
                              fontSize: 12,
                              color: VenemoPalette.textSub,
                            ),
                          ),
                        ),
                      ),
                    if (!_serverConfigAvailable)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: VenemoPalette.panelDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ローカルサーバーが停止しています',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: VenemoPalette.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '別ターミナルで次を実行してください',
                              style: TextStyle(
                                fontSize: 12,
                                color: VenemoPalette.textSub,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              _serverStartCommand,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: VenemoPalette.textMain,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _refreshServerProviderConfig(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '接続を再確認',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (_passwordLoginEnabled)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _showPasswordLogin = !_showPasswordLogin;
                                  });
                                },
                          child: Text(
                            _showPasswordLogin
                                ? 'アプリパスワード入力を閉じる'
                                : 'アプリパスワードでログイン（開発用）',
                            style: const TextStyle(
                              fontSize: 13,
                              color: VenemoPalette.textSub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            _serverConfigAvailable
                                ? 'この環境ではアプリパスワードログインを無効化しています。'
                                : 'サーバー未接続のためアプリパスワードログインは使えません。',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: VenemoPalette.textSub,
                            ),
                          ),
                        ),
                      ),
                    if (requiresCredentialLogin) ...[
                      const SizedBox(height: 4),
                      Text(
                        isGmailProvider
                            ? 'Gmailは通常パスワード不可です。Google発行の16桁アプリパスワードを使ってください。'
                            : '$providerName でアプリパスワードを発行して入力してください。',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: VenemoPalette.textSub,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 8),
                      if (_showPasswordLogin) ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'メールアドレス',
                            hintText: isGmailProvider
                                ? 'example@gmail.com'
                                : 'example@yahoo.co.jp',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'アプリパスワード',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '通常のパスワードではなく、各サービスで発行したアプリパスワードを使用してください。',
                            style: TextStyle(
                              fontSize: 13,
                              color: VenemoPalette.textSub,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleLogin,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text(
                              'サーバー経由でログイン',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
