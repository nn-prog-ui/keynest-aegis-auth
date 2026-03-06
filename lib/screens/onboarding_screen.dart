import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/app_settings_service.dart';
import '../services/gmail_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _StepKind {
  intro,
  singleChoice,
  multiChoice,
  yesNo,
  socialProof,
  notification,
  finish,
}

enum _IntroVisual {
  smartInbox,
  gatekeeper,
  priority,
  grouped,
  ai,
}

class _OnboardingStep {
  final _StepKind kind;
  final String id;
  final String title;
  final String subtitle;
  final List<String> options;
  final _IntroVisual? introVisual;
  final String? quote;
  final int questionProgress;

  const _OnboardingStep({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.options = const <String>[],
    this.introVisual,
    this.quote,
    this.questionProgress = 0,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _bgSurface = Color(0xFFF5F5F7);
  static const Color _bgShapePrimary = Color(0x14007AFF);
  static const Color _bgShapeSecondary = Color(0x12000000);
  static const Color _panel = Color(0xFFF2F2F7);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _option = Color(0xFFF7F8FA);
  static const Color _optionActive = Color(0xFFEAF2FF);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF616A78);
  static const Color _accent = Color(0xFF1D82F2);
  static const Color _line = Color(0x33000000);

  final AppSettingsService _settings = AppSettingsService();
  final GmailService _gmail = GmailService();
  final ScrollController _jobScrollController = ScrollController();

  int _index = 0;
  bool _isFinishing = false;
  bool _isHintPrefetching = false;

  String _purpose = '';
  String _job = '';
  String _role = '';
  String _teamSize = '';
  String _pain = '';
  final Set<String> _goals = <String>{};
  final Map<String, bool> _yesMap = <String, bool>{
    'あのメール、受信トレイのどこかにあるはずなのに、すぐに見つからない。': false,
    '毎日同じメール作業を繰り返していて、終わりが見えない。': false,
    'そもそもメールはチーム向きじゃないのに、仕事のほとんどがそこで行われている。': false,
  };

  late final List<_OnboardingStep> _steps = <_OnboardingStep>[
    const _OnboardingStep(
      kind: _StepKind.intro,
      id: 'smart_inbox',
      title: 'Smart Inbox',
      subtitle: '受信トレイを整理整頓して、本当に大事なことに集中',
      introVisual: _IntroVisual.smartInbox,
    ),
    const _OnboardingStep(
      kind: _StepKind.intro,
      id: 'gatekeeper',
      title: 'ゲートキーパー',
      subtitle: '不明なアドレスからのメールをスクリーニングし、ブロックできます',
      introVisual: _IntroVisual.gatekeeper,
    ),
    const _OnboardingStep(
      kind: _StepKind.intro,
      id: 'priority',
      title: '優先アドレス',
      subtitle: '重要な送信者をハイライトして、見逃しを防ぎます',
      introVisual: _IntroVisual.priority,
    ),
    const _OnboardingStep(
      kind: _StepKind.intro,
      id: 'grouped',
      title: '送信者でグループ化',
      subtitle: 'よく届くアドレスごとに並べて、受信トレイをすっきり整理',
      introVisual: _IntroVisual.grouped,
    ),
    const _OnboardingStep(
      kind: _StepKind.intro,
      id: 'ai',
      title: 'AIアシスタント',
      subtitle: '受信メールを要約し、次のアクションにつながる返信をサポート',
      introVisual: _IntroVisual.ai,
    ),
    const _OnboardingStep(
      kind: _StepKind.singleChoice,
      id: 'purpose',
      title: 'Venemoを使う目的はどれですか？',
      subtitle: '最も当てはまるものをお選びください。',
      options: <String>['仕事', 'プライベート', '両方'],
      questionProgress: 1,
    ),
    const _OnboardingStep(
      kind: _StepKind.singleChoice,
      id: 'job',
      title: 'あなたの職種を教えてください。',
      subtitle: '最も当てはまるものをお選びください。',
      options: <String>[
        '法務',
        'マーケティング',
        'コンサルティング',
        '総務',
        '営業',
        '人事',
        'ソフトウェア開発/IT',
        '教育',
        'デザイン/クリエイティブ',
        '財務/会計',
        'カスタマーサポート',
      ],
      questionProgress: 2,
    ),
    const _OnboardingStep(
      kind: _StepKind.singleChoice,
      id: 'role',
      title: 'あなたの立場を教えてください。',
      subtitle: '最も近い役職をお選びください。',
      options: <String>['経営者', 'マネージャー', '実務', 'フリーランス'],
      questionProgress: 3,
    ),
    const _OnboardingStep(
      kind: _StepKind.singleChoice,
      id: 'team_size',
      title: 'チームの規模を教えてください。',
      subtitle: '所属チームの人数をお選びください。',
      options: <String>['2-10名', '11-30名', '30名以上', '普段は自分一人で作業'],
      questionProgress: 4,
    ),
    const _OnboardingStep(
      kind: _StepKind.singleChoice,
      id: 'pain',
      title: 'メールで最も困っていることは？',
      subtitle: '最も当てはまるものをお選びください。',
      options: <String>[
        '受信トレイがごちゃごちゃしている',
        'メールが多すぎて集中できない',
        'メールの対応に時間を取られすぎている',
        'メールでのチーム連携がうまくいかない',
        'ビジネス文や丁寧語を毎回考えるのが面倒',
      ],
      questionProgress: 5,
    ),
    const _OnboardingStep(
      kind: _StepKind.yesNo,
      id: 'yes_no_1',
      title: 'こんな悩み、あなたにもありますか？',
      quote: 'あのメール、受信トレイのどこかにあるはずなのに、すぐに見つからない。',
      questionProgress: 6,
    ),
    const _OnboardingStep(
      kind: _StepKind.yesNo,
      id: 'yes_no_2',
      title: 'こんな悩み、あなたにもありますか？',
      quote: '毎日同じメール作業を繰り返していて、終わりが見えない。',
      questionProgress: 7,
    ),
    const _OnboardingStep(
      kind: _StepKind.yesNo,
      id: 'yes_no_3',
      title: 'こんな悩み、あなたにもありますか？',
      quote: 'そもそもメールはチーム向きじゃないのに、仕事のほとんどがそこで行われている。',
      questionProgress: 8,
    ),
    const _OnboardingStep(
      kind: _StepKind.multiChoice,
      id: 'goals',
      title: 'Venemoで達成したいことは何ですか？',
      subtitle: '少なくとも3つお選びください。あなたの成功プラン作成に役立てます。',
      options: <String>[
        '受信トレイを自動で整理する',
        '重要なメールを上部に表示する',
        '送信者ごとにメールをまとめる',
        '通知が多いスレッドをミュートする',
        'スマートフィルターで受信トレイをすっきり整理',
        'メール処理をスピードアップ',
        '不要な送信者をブロックする',
        'AIでビジネス文や丁寧な返信文をすばやく作る',
      ],
      questionProgress: 9,
    ),
    const _OnboardingStep(
      kind: _StepKind.socialProof,
      id: 'social',
      title: '継続利用ユーザーの声',
    ),
    const _OnboardingStep(
      kind: _StepKind.notification,
      id: 'notifications',
      title: '新着メールの通知を受け取りますか？',
      subtitle: 'Venemo がリアルタイム通知するかどうかを選びましょう。',
    ),
    const _OnboardingStep(
      kind: _StepKind.finish,
      id: 'finish',
      title: 'Venemoの準備が整いました！',
      subtitle: '受信トレイを整理し、すっきり保つことに集中できます。',
    ),
  ];

  @override
  void dispose() {
    _jobScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];

    return Scaffold(
      body: Stack(
        children: [
          const _VenemoBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Padding(
                    key: ValueKey<String>(step.id),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildStep(step),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step) {
    switch (step.kind) {
      case _StepKind.intro:
        return _buildIntro(step);
      case _StepKind.singleChoice:
        return _buildSingleChoice(step);
      case _StepKind.multiChoice:
        return _buildMultiChoice(step);
      case _StepKind.yesNo:
        return _buildYesNo(step);
      case _StepKind.socialProof:
        return _buildSocialProof(step);
      case _StepKind.notification:
        return _buildNotification(step);
      case _StepKind.finish:
        return _buildFinish(step);
    }
  }

  Widget _buildIntro(_OnboardingStep step) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child:
                _buildIntroVisual(step.introVisual ?? _IntroVisual.smartInbox),
          ),
        ),
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _text,
            height: 1.06,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          step.subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _sub,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: '次へ',
          onPressed: _goNext,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSingleChoice(_OnboardingStep step) {
    final selected = switch (step.id) {
      'purpose' => _purpose,
      'job' => _job,
      'role' => _role,
      'team_size' => _teamSize,
      'pain' => _pain,
      _ => '',
    };

    final canContinue = selected.isNotEmpty;

    return _questionShell(
      progress: step.questionProgress,
      title: step.title,
      subtitle: step.subtitle,
      child: ListView.separated(
        controller: step.id == 'job' ? _jobScrollController : null,
        padding: EdgeInsets.zero,
        itemBuilder: (context, i) {
          final option = step.options[i];
          final active = selected == option;
          return _choiceTile(
            label: option,
            selected: active,
            onTap: () {
              setState(() {
                switch (step.id) {
                  case 'purpose':
                    _purpose = option;
                    break;
                  case 'job':
                    _job = option;
                    break;
                  case 'role':
                    _role = option;
                    break;
                  case 'team_size':
                    _teamSize = option;
                    break;
                  case 'pain':
                    _pain = option;
                    break;
                }
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: step.options.length,
      ),
      bottomAction: _primaryButton(
        label: '続ける',
        enabled: canContinue,
        onPressed: canContinue ? _goNext : null,
      ),
    );
  }

  Widget _buildYesNo(_OnboardingStep step) {
    final quote = step.quote ?? '';
    final selected = _yesMap[quote];

    return _questionShell(
      progress: step.questionProgress,
      title: step.title,
      subtitle: '',
      child: Column(
        children: [
          _speechCard(quote),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _optionButton(
                  label: 'いいえ',
                  icon: Icons.close_rounded,
                  selected: selected == false,
                  onTap: () {
                    setState(() {
                      _yesMap[quote] = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _optionButton(
                  label: 'はい',
                  icon: Icons.check_rounded,
                  selected: selected == true,
                  onTap: () {
                    setState(() {
                      _yesMap[quote] = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomAction: _primaryButton(
        label: '続ける',
        enabled: selected != null,
        onPressed: selected == null ? null : _goNext,
      ),
    );
  }

  Widget _buildMultiChoice(_OnboardingStep step) {
    final canContinue = _goals.length >= 3;

    return _questionShell(
      progress: step.questionProgress,
      title: step.title,
      subtitle: step.subtitle,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemBuilder: (context, i) {
          final option = step.options[i];
          final active = _goals.contains(option);
          return _choiceTile(
            label: option,
            selected: active,
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active ? _accent : const Color(0xFF91B6E9),
                  width: 1.5,
                ),
              ),
              child: active
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            onTap: () {
              setState(() {
                if (active) {
                  _goals.remove(option);
                } else {
                  _goals.add(option);
                }
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: step.options.length,
      ),
      bottomAction: _primaryButton(
        label: canContinue ? '続ける' : '3つ以上選択してください',
        enabled: canContinue,
        onPressed: canContinue ? _goNext : null,
      ),
    );
  }

  Widget _buildSocialProof(_OnboardingStep step) {
    return Column(
      children: [
        const SizedBox(height: 28),
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFFF0B100)),
                      Icon(Icons.star_rounded, color: Color(0xFFF0B100)),
                      Icon(Icons.star_rounded, color: Color(0xFFF0B100)),
                      Icon(Icons.star_rounded, color: Color(0xFFF0B100)),
                      Icon(Icons.star_rounded, color: Color(0xFFF0B100)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'メールが多い日でも、優先度で自動整理されるので対応漏れが減りました。',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: _text,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Venemo ユーザー / 事業責任者',
                    style: TextStyle(
                      fontSize: 13,
                      color: _sub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: _BadgeMetric(
                title: '4.6 out of 5',
                subtitle: '353K+ ratings',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _BadgeMetric(
                title: 'Editors\' Choice',
                subtitle: 'Minimal Design',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _primaryButton(label: '続ける', onPressed: _goNext),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNotification(_OnboardingStep step) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FA),
                borderRadius: BorderRadius.circular(42),
                border: Border.all(
                  color: const Color(0x1F000000),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 148,
                color: Color(0xFF8CA2BB),
              ),
            ),
          ),
        ),
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _text,
            height: 1.12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Text(
          step.subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _sub,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: '通知する',
          onPressed: () {
            _settings.setChoice('サービス通知', 'オン');
            _goNext();
          },
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _settings.setChoice('サービス通知', 'オフ');
            _goNext();
          },
          style: TextButton.styleFrom(
            foregroundColor: _secondaryBlueText,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('あとで'),
        ),
      ],
    );
  }

  Widget _buildFinish(_OnboardingStep step) {
    final hasHint = _settings
        .getChoice('onboarding_ai_hint', fallback: '')
        .trim()
        .isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 34),
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x1F000000), width: 2),
            color: const Color(0xFFEFF4FA),
          ),
          child: const Icon(
            Icons.send_rounded,
            size: 54,
            color: Color(0xFF7996B5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _text,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          step.subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: _sub,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        _taskRow('メールをインポートする', done: true, icon: Icons.inbox_outlined),
        const SizedBox(height: 10),
        _taskRow('AIアシスタントを設定する',
            done: _goals.isNotEmpty, icon: Icons.auto_awesome_outlined),
        const SizedBox(height: 10),
        _taskRow(
          hasHint ? '専用のヒントを作成しました' : '専用のヒントを作成中',
          done: hasHint,
          icon: Icons.note_alt_outlined,
        ),
        const Spacer(),
        _primaryButton(
          label: _isFinishing ? '設定中...' : '続ける',
          enabled: !_isFinishing,
          onPressed: _finishOnboarding,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _questionShell({
    required int progress,
    required String title,
    required String subtitle,
    required Widget child,
    required Widget bottomAction,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              _backButton(),
              const SizedBox(width: 12),
              Expanded(
                child: _progressBar(progress / 9),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _text,
                height: 1.2,
              ),
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: _sub,
                  height: 1.3,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(child: child),
          const SizedBox(height: 14),
          bottomAction,
        ],
      ),
    );
  }

  Widget _choiceTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: selected ? _optionActive : _option,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.8)
                  : const Color(0x22000000),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _text,
                    height: 1.3,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _speechCard(String quote) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line),
          ),
          child: Text(
            quote,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _text,
              height: 1.4,
            ),
          ),
        ),
        Positioned(
          left: 28,
          bottom: 0,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 18,
              height: 18,
              color: _card,
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? _optionActive : _card,
        foregroundColor: _accent,
        side: BorderSide(
          color: selected ? _accent : _line,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _taskRow(String label, {required bool done, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: done ? Colors.white : const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: done ? const Color(0x1A007AFF) : const Color(0xFFE9EEF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: done ? _accent : const Color(0xA61F5A92),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: done ? _text : const Color(0xA6333F50),
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: done ? _accent : Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : const SizedBox(
                    width: 18,
                    height: 18,
                    child: Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return SizedBox(
      width: 44,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _sub),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _progressBar(double value) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: 5,
        backgroundColor: const Color(0x16000000),
        color: _accent,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: const Color(0xFFA4C8F0),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildIntroVisual(_IntroVisual visual) {
    switch (visual) {
      case _IntroVisual.smartInbox:
        return const _LayeredInboxVisual();
      case _IntroVisual.gatekeeper:
        return const _GatekeeperVisual();
      case _IntroVisual.priority:
        return const _PriorityVisual();
      case _IntroVisual.grouped:
        return const _GroupedVisual();
      case _IntroVisual.ai:
        return const _AiVisual();
    }
  }

  static const Color _secondaryBlueText = Color(0xFF4E6D90);

  void _goBack() {
    if (_index == 0) return;
    setState(() {
      _index -= 1;
    });
  }

  void _goNext() {
    if (_index >= _steps.length - 1) return;
    setState(() {
      _index += 1;
    });
    final current = _steps[_index];
    if (current.kind == _StepKind.finish) {
      _seedHintImmediatelyIfNeeded();
      _prefetchHintIfNeeded(force: true);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;

    setState(() {
      _isFinishing = true;
    });

    _settings.setChoice('onboarding_purpose', _purpose);
    _settings.setChoice('onboarding_job', _job);
    _settings.setChoice('onboarding_role', _role);
    _settings.setChoice('onboarding_team_size', _teamSize);
    _settings.setChoice('onboarding_pain', _pain);
    _settings.setStringList('onboarding_goals', _goals.toList());

    final yesItems = _yesMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    _settings.setStringList('onboarding_yes_items', yesItems);

    _settings.setChoice('受信トレイ', '全受信');
    _settings.setChoice('VenemoAI', _settings.isPlusSubscribed() ? '有効' : '無効');

    final existingHint =
        _settings.getChoice('onboarding_ai_hint', fallback: '').trim();
    if (existingHint.isEmpty) {
      _settings.setChoice('onboarding_ai_hint', _generateLocalHint());
      _prefetchHintIfNeeded(force: true);
    }

    _settings.setSwitch('onboarding_completed', true);

    if (!mounted) {
      return;
    }

    final targetRoute = _gmail.isSignedIn() ? '/mail_list' : '/login';
    Navigator.of(context).pushNamedAndRemoveUntil(targetRoute, (_) => false);
  }

  void _prefetchHintIfNeeded({bool force = false}) {
    if (_isHintPrefetching) return;
    final existing =
        _settings.getChoice('onboarding_ai_hint', fallback: '').trim();
    if (!force && existing.isNotEmpty) return;

    _isHintPrefetching = true;
    unawaited(_refreshHintInBackground());
  }

  void _seedHintImmediatelyIfNeeded() {
    final existing =
        _settings.getChoice('onboarding_ai_hint', fallback: '').trim();
    if (existing.isNotEmpty) return;

    _settings.setChoice('onboarding_ai_hint', _generateLocalHint());
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshHintInBackground() async {
    try {
      final hint = await _generateHint();
      if (hint.isNotEmpty) {
        _settings.setChoice('onboarding_ai_hint', hint);
      }
    } finally {
      _isHintPrefetching = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<String> _generateHint() async {
    if (!_settings.isAiEnabled()) {
      return _generateLocalHint();
    }

    final prompt = '''
以下のユーザー情報に合わせて、メール運用を改善する短いヒントを3つ作成してください。
各ヒントは1行、合計150文字以内、日本語で出力してください。

目的: $_purpose
職種: $_job
立場: $_role
チーム規模: $_teamSize
困りごと: $_pain
優先したいこと: ${_goals.join(' / ')}
''';

    try {
      return await AIService().generateText(prompt);
    } catch (_) {
      return _generateLocalHint();
    }
  }

  String _generateLocalHint() {
    final tips = <String>[
      '毎朝10分だけ未読を確認する時間を先に確保する',
      '件名に期限を含むメールを先に処理する',
      '返信が必要なメールはラベルで分けて当日中に返す',
    ];

    if (_pain.contains('ごちゃごちゃ')) {
      tips[0] = '送信者ごとにまとめ表示を有効にして一覧性を上げる';
    } else if (_pain.contains('時間')) {
      tips[1] = 'テンプレ返信を2つ作って定型メール処理を短縮する';
    }

    if (_goals.contains('重要なメールを上部に表示する')) {
      tips[2] = '重要送信者を優先リストへ追加して通知対象を絞る';
    }

    return tips.join('\n');
  }
}

class _VenemoBackdrop extends StatelessWidget {
  const _VenemoBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: _OnboardingScreenState._bgSurface,
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _BackdropShapePainter(),
          ),
        ),
      ],
    );
  }
}

class _BackdropShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final softBlue = Paint()..color = _OnboardingScreenState._bgShapePrimary;
    final softGray = Paint()..color = _OnboardingScreenState._bgShapeSecondary;

    final topLeft = RRect.fromRectAndRadius(
      Rect.fromLTWH(-70, -20, size.width * 0.52, size.height * 0.26),
      const Radius.circular(48),
    );
    canvas.drawRRect(topLeft, softBlue);

    final topRight = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          size.width * 0.58, 30, size.width * 0.46, size.height * 0.2),
      const Radius.circular(56),
    );
    canvas.drawRRect(topRight, softGray);

    final bottomLeft = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          -30, size.height * 0.72, size.width * 0.45, size.height * 0.22),
      const Radius.circular(60),
    );
    canvas.drawRRect(bottomLeft, softGray);

    final bottomRight = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.66, size.width * 0.45,
          size.height * 0.26),
      const Radius.circular(72),
    );
    canvas.drawRRect(bottomRight, softBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LayeredInboxVisual extends StatelessWidget {
  const _LayeredInboxVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.08,
            child: _card(const Color(0xFFF2F5F9), const Offset(10, 8)),
          ),
          Transform.rotate(
            angle: -0.05,
            child: _card(const Color(0xFFF7FAFE), const Offset(-8, 0)),
          ),
          _card(const Color(0xFFFFFFFF), const Offset(0, 0)),
        ],
      ),
    );
  }

  Widget _card(Color color, Offset textOffset) {
    return Container(
      width: 270,
      height: 175,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.menu, color: Color(0xFF8392A6)),
                SizedBox(width: 8),
                Text('Inbox',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Spacer(),
                Icon(Icons.search, color: Color(0xFF8392A6)),
              ],
            ),
            const SizedBox(height: 14),
            for (final sender in ['Mike', 'Arleene', 'Notifications'])
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFF1D82F2)),
                    const SizedBox(width: 8),
                    Text(
                      sender,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'workflow update',
                        style:
                            TextStyle(color: Color(0xFF778090), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GatekeeperVisual extends StatelessWidget {
  const _GatekeeperVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.14,
            child: Container(
              width: 260,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 270,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Senders',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Divider(height: 1),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                            radius: 18, child: Icon(Icons.person_outline)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Starla Wind',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              Text('Unknown sender review',
                                  style: TextStyle(color: Color(0xFF6E6E73))),
                            ],
                          ),
                        ),
                        Icon(Icons.thumb_up_alt_outlined,
                            color: Color(0xFF00A65A)),
                        SizedBox(width: 10),
                        Icon(Icons.thumb_down_alt_outlined,
                            color: Color(0xFF8A94A3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityVisual extends StatelessWidget {
  const _PriorityVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.09,
            child: Container(
              width: 270,
              height: 178,
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Container(
            width: 280,
            height: 188,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EEDC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Row(
                      children: [
                        CircleAvatar(
                            radius: 14,
                            child: Text('J',
                                style: TextStyle(fontWeight: FontWeight.w700))),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'IMPORTANT UPDATES!',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final row in [
                    'Mike  Workflow Examples',
                    'Arleene  Onboarding Brief'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 8, color: Color(0xFF1D82F2)),
                          const SizedBox(width: 8),
                          Text(row,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedVisual extends StatelessWidget {
  const _GroupedVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 34,
            top: 14,
            child: _bubble('12'),
          ),
          Positioned(
            right: 28,
            top: 52,
            child: _bubble('7'),
          ),
          Positioned(
            left: 110,
            bottom: 8,
            child: _bubble('16'),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.84),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Icon(Icons.group_work_rounded,
              size: 58, color: Color(0xFF4D657E)),
        ),
        Positioned(
          right: -2,
          top: -4,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF1F9),
            ),
            alignment: Alignment.center,
            child: Text(
              count,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF657386)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiVisual extends StatelessWidget {
  const _AiVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 250,
              height: 172,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Container(
            width: 250,
            height: 178,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Assistant',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 9),
                  Text('When is my flight to Rome?',
                      style: TextStyle(color: Color(0xFF404B57), fontSize: 12)),
                  SizedBox(height: 9),
                  Divider(height: 1),
                  SizedBox(height: 8),
                  Text('Flight info • Booking questions',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Spacer(),
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Ask me anything',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeMetric extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BadgeMetric({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F4D85),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B6585),
            ),
          ),
        ],
      ),
    );
  }
}
