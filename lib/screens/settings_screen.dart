import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../services/gmail_service.dart';
import 'venemo_plus_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);

  final GmailService _gmailService = GmailService();
  final AppSettingsService _settings = AppSettingsService();

  String _userEmail = '読み込み中...';

  final Map<String, String> _choice = <String, String>{
    'メールビューア_削除後': '次を開く',
    'メールビューア_ブラウザ': 'デフォルト',
    '外観モード': 'システム',
    'プレビュー内の行数': '1行',
    'ラベル': '標準',
    '受信トレイ': 'フォーカスリスト',
    '受信トレイタイプ': 'フォーカスリスト',
    'グループの位置': '「今日」に表示',
    'ゲートキーパー': '受信トレイの最上部',
    '優先': 'すべてのメール',
    'メール送信のキャンセル時間': '10秒',
    '通知音': 'デフォルト',
    '署名': 'なし',
    'VenemoAI': '無効',
  };

  final Map<String, bool> _switches = <String, bool>{
    'トゥルーブラック': false,
    'メールのプロフィール写真を表示': true,
    'カレンダーの通知': true,
    '不参加の予定を表示しない': false,
    'サービス通知': true,
    'メールマガジン': true,
    'ピン付き': false,
    '自分に割り当てられたメール': true,
    '宛先追加の提案': true,
    'インボックスゼロを共有': true,
    '返信時に「完了」としてマーク': false,
  };

  @override
  void initState() {
    super.initState();
    _userEmail = _gmailService.getUserEmail() ?? 'unknown@example.com';
    _loadPersisted();
    _refreshSignatureChoice();
  }

  void _loadPersisted() {
    for (final entry in _choice.entries.toList()) {
      _choice[entry.key] =
          _settings.getChoice(entry.key, fallback: entry.value);
    }
    for (final entry in _switches.entries.toList()) {
      _switches[entry.key] =
          _settings.getSwitch(entry.key, fallback: entry.value);
    }

    // 既存キー互換
    final inboxLegacy = _settings.getChoice('受信トレイ', fallback: '全受信');
    if (inboxLegacy == '全受信') {
      _choice['受信トレイタイプ'] = 'フォーカスリスト';
    }
  }

  void _refreshSignatureChoice() {
    final signature = _gmailService.getEmailSignature(withFallback: false);
    if (signature.trim().isEmpty) {
      _choice['署名'] = 'なし';
      return;
    }
    _choice['署名'] = _gmailService
        .getSignatureTemplateLabel(_gmailService.selectedSignatureId);
  }

  @override
  Widget build(BuildContext context) {
    final name = _userEmail.split('@').first;
    final isPlus = _settings.isPlusSubscribed();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                _roundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      '設定',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 14),
            _sectionCard(
              children: [
                _navRow(
                  icon: Icons.account_circle_outlined,
                  title: name,
                  subtitle: _userEmail,
                  onTap: _openAccountDetail,
                  topRounded: true,
                  bottomRounded: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionLabel('サブスクリプション'),
            _subscriptionCard(isPlus: isPlus),
            const SizedBox(height: 14),
            _sectionLabel('アカウントとサービス'),
            _sectionCard(
              children: [
                _navRow(
                  icon: Icons.alternate_email_rounded,
                  title: 'メールアカウント',
                  onTap: _openMailAccountSettings,
                  topRounded: true,
                ),
                _navRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'カレンダー',
                  onTap: _openCalendarSettings,
                ),
                _navRow(
                  icon: Icons.cloud_outlined,
                  title: 'サービス',
                  onTap: () => _showSimpleMessage('サービス設定は準備中です'),
                ),
                _navRow(
                  icon: Icons.groups_2_outlined,
                  title: 'チーム',
                  onTap: () => _showSimpleMessage('チーム設定は準備中です'),
                  bottomRounded: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionLabel('カスタマイズ'),
            _sectionCard(
              children: [
                _navRow(
                  icon: Icons.view_agenda_outlined,
                  title: 'メールビューア',
                  subtitle: _choice['メールビューア_削除後'],
                  onTap: _openMailViewerSettings,
                  topRounded: true,
                ),
                _navRow(
                  icon: Icons.inbox_outlined,
                  title: '受信トレイ',
                  subtitle: _choice['受信トレイタイプ'],
                  onTap: _openInboxSettings,
                ),
                _navRow(
                  icon: Icons.format_paint_outlined,
                  title: '外観',
                  subtitle: _choice['外観モード'],
                  onTap: _openAppearanceSettings,
                ),
                _navRow(
                  icon: Icons.swap_horiz_rounded,
                  title: 'スワイプ',
                  subtitle: '標準',
                  onTap: () => _showSimpleMessage('スワイプ設定は準備中です'),
                  bottomRounded: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionLabel('一般'),
            _sectionCard(
              children: [
                _navRow(
                  icon: Icons.auto_awesome_rounded,
                  title: 'VenemoAI',
                  subtitle: isPlus
                      ? (_settings.isAiEnabled() ? '有効' : '無効')
                      : 'Venemo Plus限定',
                  onTap: _openVenemoAiSettings,
                  topRounded: true,
                ),
                _navRow(
                  icon: Icons.note_alt_outlined,
                  title: '会議メモ',
                  subtitle: '有効',
                  onTap: () => _showSimpleMessage('会議メモ設定は準備中です'),
                ),
                _navRow(
                  icon: Icons.speaker_phone_outlined,
                  title: '通知音',
                  subtitle: _choice['通知音'],
                  onTap: () => _openChoiceSheet(
                    title: '通知音',
                    keyName: '通知音',
                    options: const ['デフォルト', 'チャイム', 'なし'],
                  ),
                ),
                _navRow(
                  icon: Icons.schedule_send_outlined,
                  title: 'メール送信のキャンセル時間',
                  subtitle: _choice['メール送信のキャンセル時間'],
                  onTap: () => _openChoiceSheet(
                    title: 'メール送信のキャンセル時間',
                    keyName: 'メール送信のキャンセル時間',
                    options: const ['5秒', '10秒', '20秒'],
                  ),
                  bottomRounded: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionLabel('その他'),
            _sectionCard(
              children: [
                _switchRow('返信時に「完了」としてマーク', topRounded: true),
                _switchRow('宛先追加の提案'),
                _switchRow('インボックスゼロを共有'),
                _signatureRow(bottomRounded: true),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _gmailService.signOut();
                if (!mounted) return;
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: _panel,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'ログアウト',
                style: TextStyle(
                  color: Color(0xFFD33131),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(children: children),
    );
  }

  Widget _subscriptionCard({required bool isPlus}) {
    final price = _settings.plusMonthlyPriceYen();
    return InkWell(
      onTap: _openSubscription,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isPlus ? const Color(0x14007AFF) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _line),
              ),
              child: Text(
                isPlus ? 'PLUS' : 'FREE',
                style: TextStyle(
                  fontSize: 11,
                  color: isPlus ? _accent : _sub,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlus ? 'Venemo Plus' : 'Venemo Free',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPlus ? 'AI機能をご利用中です' : 'AI機能はPlusで利用できます（月額¥$price）',
                    style: const TextStyle(
                      color: _sub,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isPlus ? '管理' : 'アップグレード',
              style: const TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: _sub,
          fontSize: 11,
          letterSpacing: 0.11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _roundIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _panel,
        shape: BoxShape.circle,
        border: Border.all(color: _line),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: _text, size: 22),
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool topRounded = false,
    bool bottomRounded = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: subtitle == null ? 58 : 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topRounded ? 16 : 0),
            topRight: Radius.circular(topRounded ? 16 : 0),
            bottomLeft: Radius.circular(bottomRounded ? 16 : 0),
            bottomRight: Radius.circular(bottomRounded ? 16 : 0),
          ),
          border: bottomRounded
              ? null
              : const Border(
                  bottom: BorderSide(color: _line),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accent, size: 27),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: _sub,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _sub, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String key,
      {bool topRounded = false, bool bottomRounded = false}) {
    final value = _switches[key] ?? false;
    return InkWell(
      onTap: () {
        final next = !value;
        setState(() => _switches[key] = next);
        _settings.setSwitch(key, next);
      },
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topRounded ? 16 : 0),
            topRight: Radius.circular(topRounded ? 16 : 0),
            bottomLeft: Radius.circular(bottomRounded ? 16 : 0),
            bottomRight: Radius.circular(bottomRounded ? 16 : 0),
          ),
          border: bottomRounded
              ? null
              : const Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                key,
                style: const TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              activeTrackColor: const Color(0x4D007AFF),
              activeThumbColor: _accent,
              onChanged: (next) {
                setState(() => _switches[key] = next);
                _settings.setSwitch(key, next);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _signatureRow({bool bottomRounded = false}) {
    final options = _gmailService.getSignatureTemplateOptions();
    final selectedId = _gmailService.selectedSignatureId;
    final selectedLabel = options
        .firstWhere(
          (item) => item.key == selectedId,
          orElse: () => const MapEntry<String, String>('custom', 'カスタム'),
        )
        .value;
    final signature = _gmailService.getEmailSignature(withFallback: false);
    final firstLine = signature.split('\n').first.trim();
    final preview =
        firstLine.isEmpty ? selectedLabel : '$selectedLabel: $firstLine';

    return InkWell(
      onTap: _openSignatureDialog,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(bottomRounded ? 16 : 0),
            bottomRight: Radius.circular(bottomRounded ? 16 : 0),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '署名',
                style: TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              preview,
              style: const TextStyle(color: _sub, fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _sub, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openSubscription() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VenemoPlusScreen()),
    );

    if (!mounted || updated != true) return;
    setState(() {
      // plus有効化後はUI再描画のみ
    });
  }

  Future<void> _openAppearanceSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AppearanceSettingsPage()),
    );
    if (!mounted) return;
    setState(() {
      _choice['外観モード'] = _settings.getChoice('外観モード', fallback: 'システム');
    });
  }

  Future<void> _openMailViewerSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _MailViewerSettingsPage()),
    );
    if (!mounted) return;
    setState(() {
      _choice['メールビューア_削除後'] =
          _settings.getChoice('メールビューア_削除後', fallback: '次を開く');
    });
  }

  Future<void> _openInboxSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _InboxSettingsPage()),
    );
    if (!mounted) return;
    setState(() {
      _choice['受信トレイタイプ'] =
          _settings.getChoice('受信トレイタイプ', fallback: 'フォーカスリスト');
    });
  }

  Future<void> _openVenemoAiSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _VenemoAiSettingsPage()),
    );
    if (!mounted) return;
    setState(() {
      _choice['VenemoAI'] = _settings.getChoice('VenemoAI', fallback: '無効');
    });
  }

  Future<void> _openMailAccountSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _MailAccountSettingsPage(email: _userEmail)),
    );
  }

  Future<void> _openAccountDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _AccountDetailPage(email: _userEmail)),
    );
  }

  Future<void> _openCalendarSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CalendarSettingsPage()),
    );
  }

  Future<void> _openSignatureDialog() async {
    final customController = TextEditingController(
      text: _gmailService.getSignatureTemplates()['custom'] ?? '',
    );
    String selectedId = _gmailService.selectedSignatureId;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('署名を編集'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('署名テンプレート'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    items: _gmailService
                        .getSignatureTemplateOptions()
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('カスタム署名'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: '例:\n--\nNoritake Nemoto\nsupport@venemo.jp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '用途に合わせて複数テンプレートを使い分けできます。',
                    style: TextStyle(fontSize: 12, color: _sub),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  <String, String>{
                    'selected': 'custom',
                    'custom': '',
                  },
                ),
                child: const Text('削除'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  <String, String>{
                    'selected': selectedId,
                    'custom': customController.text,
                  },
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    _gmailService.setEmailSignature(result['custom'] ?? '');
    _gmailService
        .setSelectedSignatureTemplate((result['selected'] ?? 'custom').trim());
    setState(() {
      _refreshSignatureChoice();
    });
  }

  Future<void> _openChoiceSheet({
    required String title,
    required String keyName,
    required List<String> options,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map(
                  (option) => ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(fontSize: 14, color: _text),
                    ),
                    trailing: _choice[keyName] == option
                        ? const Icon(Icons.check_rounded,
                            color: _accent, size: 18)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _choice[keyName] = selected;
    });
    _settings.setChoice(keyName, selected);
  }

  void _showSimpleMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _panel,
                    shape: BoxShape.circle,
                    border: Border.all(color: _line),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _text, size: 20),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _AppearanceSettingsPage extends StatefulWidget {
  const _AppearanceSettingsPage();

  @override
  State<_AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<_AppearanceSettingsPage> {
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);

  final AppSettingsService _settings = AppSettingsService();

  late String _mode;
  late bool _trueBlack;
  late bool _showProfile;

  @override
  void initState() {
    super.initState();
    _mode = _settings.getChoice('外観モード', fallback: 'システム');
    _trueBlack = _settings.getSwitch('トゥルーブラック', fallback: false);
    _showProfile = _settings.getSwitch('メールのプロフィール写真を表示', fallback: true);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: '外観',
      child: Column(
        children: [
          _simpleCard(
            child: _row(
              title: 'アプリアイコン',
              subtitle: '#Venemo',
              trailing: const Icon(Icons.chevron_right_rounded, color: _sub),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 10),
          _simpleCard(
            child: Column(
              children: [
                _radioRow('ライト', _mode == 'ライト', () => _setMode('ライト')),
                _divider(),
                _radioRow('ダーク', _mode == 'ダーク', () => _setMode('ダーク')),
                _divider(),
                _radioRow('システム', _mode == 'システム', () => _setMode('システム')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _simpleCard(
            child: _switchLine(
              'トゥルーブラック',
              _trueBlack,
              (v) {
                setState(() => _trueBlack = v);
                _settings.setSwitch('トゥルーブラック', v);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ダークテーマで黒色を使用する',
                style: TextStyle(color: _sub, fontSize: 12),
              ),
            ),
          ),
          _simpleCard(
            child: _row(
              title: 'プレビュー内の行数',
              subtitle: _settings.getChoice('プレビュー内の行数', fallback: '1行'),
              trailing: const Icon(Icons.chevron_right_rounded, color: _sub),
              onTap: () => _openChoice(
                context,
                'プレビュー内の行数',
                const ['1行', '2行', '3行'],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _simpleCard(
            child: _row(
              title: 'ラベル',
              subtitle: _settings.getChoice('ラベル', fallback: '標準'),
              trailing: const Icon(Icons.chevron_right_rounded, color: _sub),
              onTap: () => _openChoice(
                context,
                'ラベル',
                const ['標準', '最小', '詳細'],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _simpleCard(
            child: _switchLine(
              'メールのプロフィール写真を表示',
              _showProfile,
              (v) {
                setState(() => _showProfile = v);
                _settings.setSwitch('メールのプロフィール写真を表示', v);
              },
            ),
          ),
          const SizedBox(height: 14),
          _simpleCard(
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロフィール写真キャッシュを削除しました')),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'プロフィール写真のキャッシュを削除',
                  style: TextStyle(color: Color(0xFFE54848), fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }

  Widget _row({
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: _sub, fontSize: 13),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _radioRow(String title, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: _text),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  color: Color(0xFF007AFF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchLine(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: _text),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: _line);
  }

  void _setMode(String mode) {
    setState(() => _mode = mode);
    _settings.setChoice('外観モード', mode);
    _settings.setChoice('外観', mode == 'システム' ? 'ライト' : mode);
  }

  Future<void> _openChoice(
      BuildContext context, String key, List<String> options) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((item) => ListTile(
                      title: Text(item),
                      trailing: _settings.getChoice(key, fallback: '') == item
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFF007AFF))
                          : null,
                      onTap: () => Navigator.pop(context, item),
                    ))
                .toList(),
          ),
        );
      },
    );

    if (selected == null) return;
    _settings.setChoice(key, selected);
    setState(() {});
  }
}

class _MailViewerSettingsPage extends StatefulWidget {
  const _MailViewerSettingsPage();

  @override
  State<_MailViewerSettingsPage> createState() =>
      _MailViewerSettingsPageState();
}

class _MailViewerSettingsPageState extends State<_MailViewerSettingsPage> {
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);

  final AppSettingsService _settings = AppSettingsService();

  late String _openAfterDelete;
  late String _browser;
  late bool _showProfile;

  @override
  void initState() {
    super.initState();
    _openAfterDelete = _settings.getChoice('メールビューア_削除後', fallback: '次を開く');
    _browser = _settings.getChoice('メールビューア_ブラウザ', fallback: 'デフォルト');
    _showProfile = _settings.getSwitch('メールのプロフィール写真を表示', fallback: true);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'メールビューア',
      child: Column(
        children: [
          _card(
            child: _lineRow(
              title: 'ツールバーのカスタマイズ',
              onTap: () {},
              arrow: true,
            ),
          ),
          const SizedBox(height: 10),
          _caption('メールを削除またはアーカイブした時'),
          _card(
            child: Column(
              children: [
                _checkRow('次を開く', _openAfterDelete == '次を開く', () {
                  setState(() => _openAfterDelete = '次を開く');
                  _settings.setChoice('メールビューア_削除後', '次を開く');
                }),
                _divider(),
                _checkRow('アカウント一覧に戻る', _openAfterDelete == 'アカウント一覧に戻る', () {
                  setState(() => _openAfterDelete = 'アカウント一覧に戻る');
                  _settings.setChoice('メールビューア_削除後', 'アカウント一覧に戻る');
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _caption('デフォルトのブラウザ'),
          _card(
            child: Column(
              children: [
                _checkRow(
                    'デフォルト', _browser == 'デフォルト', () => _setBrowser('デフォルト')),
                _divider(),
                _checkRow('Chrome', _browser == 'Chrome',
                    () => _setBrowser('Chrome')),
                _divider(),
                _checkRow(
                    'App内', _browser == 'App内', () => _setBrowser('App内')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _card(
            child: _switchLine('メールのプロフィール写真を表示', _showProfile, (v) {
              setState(() => _showProfile = v);
              _settings.setSwitch('メールのプロフィール写真を表示', v);
            }),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  Widget _caption(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: _sub,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _lineRow(
      {required String title,
      required VoidCallback onTap,
      bool arrow = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16, color: _text, fontWeight: FontWeight.w500)),
            ),
            if (arrow) const Icon(Icons.chevron_right_rounded, color: _sub),
          ],
        ),
      ),
    );
  }

  Widget _checkRow(String title, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, color: _text))),
            if (selected)
              const Icon(Icons.check_rounded, color: Color(0xFF007AFF)),
          ],
        ),
      ),
    );
  }

  Widget _switchLine(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16, color: _text))),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _line);

  void _setBrowser(String value) {
    setState(() => _browser = value);
    _settings.setChoice('メールビューア_ブラウザ', value);
  }
}

class _InboxSettingsPage extends StatefulWidget {
  const _InboxSettingsPage();

  @override
  State<_InboxSettingsPage> createState() => _InboxSettingsPageState();
}

class _InboxSettingsPageState extends State<_InboxSettingsPage> {
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);

  final AppSettingsService _settings = AppSettingsService();

  late String _type;
  late bool _serviceNotice;
  late bool _newsletter;
  late bool _pin;
  late bool _assigned;

  @override
  void initState() {
    super.initState();
    _type = _settings.getChoice('受信トレイタイプ', fallback: 'フォーカスリスト');
    _serviceNotice = _settings.getSwitch('サービス通知', fallback: true);
    _newsletter = _settings.getSwitch('メールマガジン', fallback: true);
    _pin = _settings.getSwitch('ピン付き', fallback: false);
    _assigned = _settings.getSwitch('自分に割り当てられたメール', fallback: true);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: '受信トレイ',
      child: Column(
        children: [
          _card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _typeOption(
                      title: 'フォーカスリスト',
                      selected: _type == 'フォーカスリスト',
                      onTap: () => _setType('フォーカスリスト'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeOption(
                      title: '未読カード',
                      selected: _type == '未読カード',
                      onTap: () => _setType('未読カード'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _lineRow('ゲートキーパー',
                    _settings.getChoice('ゲートキーパー', fallback: '受信トレイの最上部')),
                _divider(),
                _lineRow('優先', _settings.getChoice('優先', fallback: 'すべてのメール')),
                _divider(),
                _lineRow('グループの位置',
                    _settings.getChoice('グループの位置', fallback: '「今日」に表示')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _caption('メールのグループ'),
          _card(
            child: Column(
              children: [
                _switchLine('サービス通知', _serviceNotice, (v) {
                  setState(() => _serviceNotice = v);
                  _settings.setSwitch('サービス通知', v);
                }),
                _divider(),
                _switchLine('メールマガジン', _newsletter, (v) {
                  setState(() => _newsletter = v);
                  _settings.setSwitch('メールマガジン', v);
                }),
                _divider(),
                _switchLine('ピン付き', _pin, (v) {
                  setState(() => _pin = v);
                  _settings.setSwitch('ピン付き', v);
                }),
                _divider(),
                _switchLine('自分に割り当てられたメール', _assigned, (v) {
                  setState(() => _assigned = v);
                  _settings.setSwitch('自分に割り当てられたメール', v);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  Widget _caption(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: _sub,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _typeOption(
      {required String title,
      required bool selected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 144,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _accent : _line, width: selected ? 2 : 1),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Icon(
                title == 'フォーカスリスト'
                    ? Icons.view_list_rounded
                    : Icons.dashboard_outlined,
                size: 48,
                color: selected ? _accent : _sub,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: selected ? _accent : _text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(color: _sub, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _sub),
        ],
      ),
    );
  }

  Widget _switchLine(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16, color: _text))),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _line);

  void _setType(String value) {
    setState(() => _type = value);
    _settings.setChoice('受信トレイタイプ', value);
    _settings.setChoice('受信トレイ', '全受信');
  }
}

class _VenemoAiSettingsPage extends StatefulWidget {
  const _VenemoAiSettingsPage();

  @override
  State<_VenemoAiSettingsPage> createState() => _VenemoAiSettingsPageState();
}

class _VenemoAiSettingsPageState extends State<_VenemoAiSettingsPage> {
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);

  final AppSettingsService _settings = AppSettingsService();

  late bool _master;
  late bool _assistant;
  late bool _translate;
  late bool _quickReply;

  @override
  void initState() {
    super.initState();
    _master = _settings.isAiEnabled();
    _assistant = _settings.getSwitch('VenemoAI_assistant', fallback: false);
    _translate = _settings.getSwitch('VenemoAI_translate', fallback: false);
    _quickReply = _settings.getSwitch('VenemoAI_quick_reply', fallback: false);
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = _settings.isPlusSubscribed();

    return _SectionScaffold(
      title: 'VenemoAI',
      child: Column(
        children: [
          if (!isPlus) ...[
            Container(
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VenemoAIはVenemo Plusで利用できます（月額¥${_settings.plusMonthlyPriceYen()}）',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: _openPlus,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Venemo Plusにアップグレード'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          _card(
            child: Column(
              children: [
                _switchLine(
                  'VenemoAI を有効にする',
                  _master,
                  enabled: isPlus,
                  onChanged: (v) {
                    setState(() => _master = v);
                    _settings.setAiEnabled(v);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Text(
                    'メール作成・要約・編集を支援します。Freeプランでは利用できません。',
                    style: TextStyle(color: _sub, fontSize: 12, height: 1.5),
                  ),
                ),
                _divider(),
                _switchLine(
                  'AIアシスタント',
                  _assistant,
                  enabled: isPlus && _master,
                  onChanged: (v) {
                    setState(() => _assistant = v);
                    _settings.setSwitch('VenemoAI_assistant', v);
                  },
                ),
                _divider(),
                _lineRow('メール作成アシスタント', '返信・新規作成でAIを使う'),
                _divider(),
                _switchLine(
                  'メールの翻訳',
                  _translate,
                  enabled: isPlus && _master,
                  onChanged: (v) {
                    setState(() => _translate = v);
                    _settings.setSwitch('VenemoAI_translate', v);
                  },
                ),
                _divider(),
                _switchLine(
                  'クイック返信 +AI',
                  _quickReply,
                  enabled: isPlus && _master,
                  onChanged: (v) {
                    setState(() => _quickReply = v);
                    _settings.setSwitch('VenemoAI_quick_reply', v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  Widget _lineRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        color: _text,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: _sub)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _sub),
        ],
      ),
    );
  }

  Widget _switchLine(
    String title,
    bool value, {
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: enabled ? _text : _sub,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _line);

  Future<void> _openPlus() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VenemoPlusScreen()),
    );
    if (!mounted || updated != true) return;
    setState(() {
      _master = _settings.isAiEnabled();
    });
  }
}

class _MailAccountSettingsPage extends StatelessWidget {
  const _MailAccountSettingsPage({required this.email});

  final String email;

  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final name = email.split('@').first;

    return _SectionScaffold(
      title: 'メールアカウント',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0x14007AFF),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V'),
                  ),
                  title: Text(name, style: const TextStyle(color: _text)),
                  subtitle: Text(email, style: const TextStyle(color: _sub)),
                  trailing:
                      const Icon(Icons.chevron_right_rounded, color: _sub),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('アカウントを追加', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarSettingsPage extends StatefulWidget {
  const _CalendarSettingsPage();

  @override
  State<_CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<_CalendarSettingsPage> {
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);

  final AppSettingsService _settings = AppSettingsService();

  late bool _notice;
  late bool _hideDeclined;

  @override
  void initState() {
    super.initState();
    _notice = _settings.getSwitch('カレンダーの通知', fallback: true);
    _hideDeclined = _settings.getSwitch('不参加の予定を表示しない', fallback: false);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
      title: 'カレンダー',
      child: Column(
        children: [
          _card(
            child: Column(
              children: [
                _lineRow('カレンダーのアカウント', 'Google'),
                _divider(),
                _lineRow('デフォルト', _defaultEmailPreview),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _lineRow('イベントのデフォルト時間', '1時間'),
                _divider(),
                _switchLine('カレンダーの通知', _notice, (v) {
                  setState(() => _notice = v);
                  _settings.setSwitch('カレンダーの通知', v);
                }),
                _divider(),
                _switchLine('不参加の予定を表示しない', _hideDeclined, (v) {
                  setState(() => _hideDeclined = v);
                  _settings.setSwitch('不参加の予定を表示しない', v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('カレンダー設定をリセットしました')),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'カレンダーをリセット',
                  style: TextStyle(color: Color(0xFFE54848), fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _defaultEmailPreview {
    final email = GmailService().getUserEmail() ?? '未設定';
    return email;
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  Widget _lineRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: _text, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _sub, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: _sub),
        ],
      ),
    );
  }

  Widget _switchLine(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _text, fontSize: 16),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _line);
}

class _AccountDetailPage extends StatefulWidget {
  const _AccountDetailPage({required this.email});

  final String email;

  @override
  State<_AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<_AccountDetailPage> {
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);

  final AppSettingsService _settings = AppSettingsService();

  late bool _serviceInbox;

  @override
  void initState() {
    super.initState();
    _serviceInbox = _settings.getSwitch('サービス通知', fallback: true);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.email.split('@').first;

    return _SectionScaffold(
      title: widget.email,
      child: Column(
        children: [
          _card(
            child: Column(
              children: [
                _lineRow('説明', '自宅'),
                _divider(),
                _lineRow('名前', name),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {},
              child: const Text('チームとメールアカウントを共有する'),
            ),
          ),
          const SizedBox(height: 12),
          _caption('サービス通知'),
          _card(
            child: Column(
              children: [
                _radioEntry('すべて', true, 'すべてのメール受信時に通知'),
                _divider(),
                _radioEntry('スマート', false, '知らない人や自動送信メールは通知しない'),
                _divider(),
                _radioEntry('優先', false, '優先アドレスからのメールの通知'),
                _divider(),
                _radioEntry('通知なし', false, '通知を完全にオフに'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: _switchLine('共通受信トレイに表示', _serviceInbox, (v) {
              setState(() => _serviceInbox = v);
              _settings.setSwitch('サービス通知', v);
            }),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              children: [
                _lineRow('自動的に Cc/Bcc', '未設定'),
                _divider(),
                _lineRow('エイリアスを追加', ''),
                _divider(),
                _lineRow('フォルダ', ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  Widget _caption(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
                color: _sub, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );

  Widget _lineRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _text, fontSize: 16),
            ),
          ),
          if (value.isNotEmpty)
            Flexible(
              child: Text(
                value,
                style: const TextStyle(color: _sub, fontSize: 15),
              ),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: _sub),
        ],
      ),
    );
  }

  Widget _radioEntry(String title, bool active, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_off,
              color: active ? const Color(0xFF007AFF) : _line,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(color: _sub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchLine(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _text, fontSize: 16),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _line);
}
