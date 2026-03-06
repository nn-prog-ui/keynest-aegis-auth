import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../services/external_launcher.dart';
import '../services/subscription_service.dart';

class VenemoPlusScreen extends StatefulWidget {
  const VenemoPlusScreen({super.key});

  @override
  State<VenemoPlusScreen> createState() => _VenemoPlusScreenState();
}

class _VenemoPlusScreenState extends State<VenemoPlusScreen> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);

  final AppSettingsService _settings = AppSettingsService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _yearly = false;
  bool _processing = false;
  bool _restoring = false;
  bool _stripeEnabled = false;
  bool _isPlus = false;
  bool _handledWebBillingResult = false;
  String _contractType = 'individual';
  int _businessSeatCount = 20;
  List<Map<String, int>> _corporateDiscounts = const [
    {'seatCount': 20, 'discountPercent': 15},
    {'seatCount': 40, 'discountPercent': 20},
  ];
  String _statusText = '契約状態を確認中...';

  @override
  void initState() {
    super.initState();
    _syncSubscription();
    _handleWebBillingResultIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _settings.plusMonthlyPriceYen();
    final yearly = _settings.plusYearlyPriceYen();
    final effectiveYearly = _contractType == 'business' ? true : _yearly;
    final yearlyRegular = monthly * 12;
    final yearlySavingPercent = yearlyRegular > 0
        ? (((yearlyRegular - yearly) / yearlyRegular) * 100).floor()
        : 0;
    final discountPercent = _selectedDiscountPercent();
    final seatCount = _selectedSeatCount();
    final basePrice = effectiveYearly ? yearly : monthly;
    final discountedTotal = _contractType == 'business'
        ? ((basePrice * seatCount * (100 - discountPercent)) / 100).round()
        : basePrice;
    final perSeat = _contractType == 'business'
        ? (discountedTotal / seatCount).round()
        : basePrice;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: _text),
        ),
        title: const Text(
          'Venemo Plus',
          style: TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'プランを選択してください',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _billingChip(
                          title: '毎月',
                          subtitle: '¥$monthly/月',
                          selected: !effectiveYearly,
                          enabled: _contractType != 'business',
                          onTap: () => setState(() => _yearly = false),
                        ),
                      ),
                      Expanded(
                        child: _billingChip(
                          title: '毎年',
                          subtitle: '¥$yearly/年',
                          highlightLabel: yearlySavingPercent > 0
                              ? '$yearlySavingPercent%お得'
                              : null,
                          selected: effectiveYearly,
                          onTap: () => setState(() => _yearly = true),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_contractType == 'business')
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      '法人契約は年額プランのみです',
                      style: TextStyle(
                        color: _sub,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _contractChip(
                          title: '個人',
                          subtitle: '1名',
                          selected: _contractType == 'individual',
                          onTap: () => setState(() {
                            _contractType = 'individual';
                          }),
                        ),
                      ),
                      Expanded(
                        child: _contractChip(
                          title: '法人',
                          subtitle: '20名 / 40名',
                          selected: _contractType == 'business',
                          onTap: () => setState(() {
                            _contractType = 'business';
                            _yearly = true;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_contractType == 'business') ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _corporateDiscounts.map((option) {
                      final seats = option['seatCount'] ?? 20;
                      final discount = option['discountPercent'] ?? 0;
                      final totalAnnual =
                          ((yearly * seats * (100 - discount)) / 100).round();
                      final perSeatAnnual = (totalAnnual / seats).round();
                      return _seatChip(
                        seats: seats,
                        discountPercent: discount,
                        totalAnnual: totalAnnual,
                        perSeatAnnual: perSeatAnnual,
                        selected: _businessSeatCount == seats,
                        onTap: () => setState(() => _businessSeatCount = seats),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line),
                  ),
                  child: Text(
                    _contractType == 'business'
                        ? '法人プラン（個人年額 ¥$yearly/名 基準）: $seatCount名 / $discountPercent%OFF / 合計 ¥$discountedTotal/年（1名あたり ¥$perSeat/年）'
                        : '個人プラン: 合計 ¥$discountedTotal${effectiveYearly ? '/年' : '/月'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _sub,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line),
                  ),
                  child: Text(
                    _statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _sub,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _featureRow('AI返信の自動生成'),
                _featureRow('ユーザー要約からの返信文作成'),
                _featureRow('AI本文生成（新規作成）'),
                _featureRow('受信トレイ運用ヒント生成'),
                _featureRow('今後の高度AI機能の先行利用'),
                if (_contractType == 'business') ...[
                  const SizedBox(height: 4),
                  _featureRow('法人向け一括契約（$seatCount名）'),
                ],
                const SizedBox(height: 8),
                Text(
                  kIsWeb && _stripeEnabled
                      ? '※ WebはStripe決済で有効化します。決済完了後に「復元」で最新状態を同期してください。'
                      : '※ 開発版ではテスト購入を有効化します。StoreKit / Google Play Billing 連携後に実課金へ切替します。',
                  style: const TextStyle(
                    color: _sub,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _processing ? null : _activatePlan,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isPlus
                          ? 'Venemo Plus契約中'
                          : (_contractType == 'business'
                              ? 'Venemo Plus 法人（$seatCount名 ¥$discountedTotal/年）を有効化'
                              : (effectiveYearly
                                  ? 'Venemo Plus（年額¥$yearly / $yearlySavingPercent%お得）を有効化'
                                  : 'Venemo Plus（月額¥$monthly）を有効化')),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          TextButton(
            onPressed: _processing || _restoring ? null : _restore,
            child: const Text(
              '復元',
              style: TextStyle(
                fontSize: 13,
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingChip({
    required String title,
    required String subtitle,
    String? highlightLabel,
    required bool selected,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        decoration: BoxDecoration(
          color: selected ? _panel : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _accent : Colors.transparent),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: !enabled ? _sub : (selected ? _accent : _text),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (highlightLabel != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x14007AFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '年払いで$highlightLabel',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            Text(
              subtitle,
              style: TextStyle(
                color: !enabled ? const Color(0xFFB0B0B5) : _sub,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 18, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contractChip({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        decoration: BoxDecoration(
          color: selected ? _panel : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _accent : Colors.transparent),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? _accent : _text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: _sub,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatChip({
    required int seats,
    required int discountPercent,
    required int totalAnnual,
    required int perSeatAnnual,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x14007AFF) : _panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _accent : _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$seats名  $discountPercent%OFF  合計 ¥$totalAnnual/年',
              style: TextStyle(
                color: selected ? _accent : _text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '1名あたり ¥$perSeatAnnual/年',
              style: const TextStyle(
                color: _sub,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activatePlan() async {
    if (_isPlus) {
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    setState(() => _processing = true);
    final cycle = _contractType == 'business'
        ? 'yearly'
        : (_yearly ? 'yearly' : 'monthly');
    final contractType = _contractType;
    final seatCount = _selectedSeatCount();
    final discountPercent = _selectedDiscountPercent();
    try {
      if (kIsWeb && _stripeEnabled) {
        final checkoutUrl = await _subscriptionService.createWebCheckoutUrl(
          billingCycle: cycle,
          contractType: contractType,
          seatCount: seatCount,
          discountPercent: discountPercent,
        );
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _subscriptionService.lastError ?? '決済ページの起動に失敗しました',
              ),
            ),
          );
          return;
        }
        final opened = await openExternalUrl(checkoutUrl);
        if (!mounted) return;
        if (!opened) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('決済ページを開けませんでした')),
          );
        }
        return;
      }

      final ok = await _subscriptionService.activateDevPlus(
        billingCycle: cycle,
        contractType: contractType,
        seatCount: seatCount,
        discountPercent: discountPercent,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_subscriptionService.lastError ?? 'Plus有効化に失敗しました'),
          ),
        );
        return;
      }

      await _syncSubscription();
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final ok = await _subscriptionService.refreshStatus();
    if (!mounted) return;
    await _syncSubscription();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_subscriptionService.lastError ?? '契約状態の同期に失敗しました'),
        ),
      );
      return;
    }

    if (_isPlus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venemo Plus契約を復元しました')),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('有効なVenemo Plus契約は見つかりませんでした')),
    );
  }

  Future<void> _syncSubscription() async {
    final config = await _subscriptionService.fetchConfig();
    await _subscriptionService.refreshStatus();
    if (!mounted) return;

    final plus = _settings.isPlusSubscribed();
    final source = _settings.plusSource();
    final cycle = _settings.plusBillingCycle();
    final expires = _settings.plusExpiresAt();
    final contractType = _settings.plusContractType();
    final seatCount = _settings.plusSeatCount();
    final stripeEnabled = config != null && config['stripeEnabled'] == true;
    final serverCorporateDiscounts = _parseCorporateDiscounts(config);
    final seededSeatCount = serverCorporateDiscounts
            .map((e) => e['seatCount'] ?? 0)
            .contains(seatCount)
        ? seatCount
        : (serverCorporateDiscounts.first['seatCount'] ?? 20);

    setState(() {
      _isPlus = plus;
      _stripeEnabled = stripeEnabled;
      _contractType = contractType == 'business' ? 'business' : 'individual';
      _yearly = _contractType == 'business' ? true : cycle == 'yearly';
      _corporateDiscounts = serverCorporateDiscounts;
      _businessSeatCount = seededSeatCount;
      _statusText = _buildStatusText(
        plus: plus,
        source: source,
        cycle: cycle,
        expiresAt: expires,
        contractType: contractType,
        seatCount: seatCount,
        discountPercent: _settings.plusDiscountPercent(),
      );
    });
  }

  String _buildStatusText({
    required bool plus,
    required String source,
    required String cycle,
    required String expiresAt,
    required String contractType,
    required int seatCount,
    required int discountPercent,
  }) {
    if (!plus) {
      return '現在は Free プランです';
    }
    final suffix = cycle == 'yearly' ? '年額' : '月額';
    final contract = contractType == 'business'
        ? '法人 ${seatCount}名（${discountPercent}%OFF）'
        : '個人';
    if (expiresAt.isNotEmpty) {
      return 'Venemo Plus（$suffix / $contract） 有効期限: $expiresAt / 決済元: $source';
    }
    return 'Venemo Plus（$suffix / $contract）契約中 / 決済元: $source';
  }

  List<Map<String, int>> _parseCorporateDiscounts(
      Map<String, dynamic>? config) {
    final raw = config?['corporateDiscounts'];
    if (raw is List) {
      final parsed = raw
          .map((item) {
            if (item is! Map<String, dynamic>) return null;
            final seatCount = (item['seatCount'] as num?)?.toInt();
            final discountPercent = (item['discountPercent'] as num?)?.toInt();
            if (seatCount == null || discountPercent == null) return null;
            return <String, int>{
              'seatCount': seatCount,
              'discountPercent': discountPercent,
            };
          })
          .whereType<Map<String, int>>()
          .toList();
      if (parsed.isNotEmpty) {
        parsed.sort(
            (a, b) => (a['seatCount'] ?? 0).compareTo(b['seatCount'] ?? 0));
        return parsed;
      }
    }
    return const [
      {'seatCount': 20, 'discountPercent': 15},
      {'seatCount': 40, 'discountPercent': 20},
    ];
  }

  int _selectedSeatCount() {
    if (_contractType != 'business') return 1;
    final available =
        _corporateDiscounts.map((item) => item['seatCount'] ?? 20).toSet();
    if (available.contains(_businessSeatCount)) {
      return _businessSeatCount;
    }
    return _corporateDiscounts.first['seatCount'] ?? 20;
  }

  int _selectedDiscountPercent() {
    if (_contractType != 'business') return 0;
    final selectedSeat = _selectedSeatCount();
    for (final option in _corporateDiscounts) {
      if ((option['seatCount'] ?? 0) == selectedSeat) {
        return option['discountPercent'] ?? 0;
      }
    }
    return 0;
  }

  void _handleWebBillingResultIfNeeded() {
    if (!kIsWeb || _handledWebBillingResult) return;
    final billing = _extractBillingResult(Uri.base);
    if (billing.isEmpty) return;
    _handledWebBillingResult = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (billing == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('決済完了を確認中です...')),
        );
        await _restore();
        return;
      }
      if (billing == 'cancel') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('決済がキャンセルされました')),
        );
      }
    });
  }

  String _extractBillingResult(Uri uri) {
    final direct = (uri.queryParameters['billing'] ?? '').trim().toLowerCase();
    if (direct == 'success' || direct == 'cancel') {
      return direct;
    }

    final fragment = uri.fragment;
    final queryIndex = fragment.indexOf('?');
    if (queryIndex < 0 || queryIndex == fragment.length - 1) {
      return '';
    }

    final query = fragment.substring(queryIndex + 1);
    final fragmentUri = Uri.parse('https://venemo.local/?$query');
    final fromFragment =
        (fragmentUri.queryParameters['billing'] ?? '').trim().toLowerCase();
    if (fromFragment == 'success' || fromFragment == 'cancel') {
      return fromFragment;
    }
    return '';
  }
}
