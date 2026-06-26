import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shared_credential_bridge.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.credential});

  final SharedCredentialListItem credential;

  static const Color _brand = Color(0xFF0B8F6D);
  static const Color _brandSoft = Color(0xFFEFF7F3);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFCDE5DC);
  static const Color _warning = Color(0xFFB45309);
  static const Color _warningSoft = Color(0xFFFFF7ED);
  static const Color _neutralSoft = Color(0xFFF3F4F6);

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}/$month/$day';
  }

  String _joinDomains(List<String> domains) {
    if (domains.isEmpty) {
      return '-';
    }
    return domains.join(', ');
  }

  String _text(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }
    return value.trim();
  }

  String _priceText() {
    final price = _text(credential.monthlyPrice);
    if (price == '-') {
      return '-';
    }
    return '$price ${_text(credential.currency ?? 'JPY')}';
  }

  bool get _hasSubscription {
    return _text(credential.monthlyPrice) != '-' ||
        _text(credential.billingCycle) != '-' ||
        credential.renewalDate != null ||
        _text(credential.paymentMethod) != '-' ||
        _text(credential.cancelUrl) != '-';
  }

  Uri? _loginUri() {
    final loginUrl = _text(credential.loginUrl);
    if (loginUrl == '-') {
      return null;
    }
    final normalized =
        loginUrl.contains('://') ? loginUrl : 'https://$loginUrl';
    return Uri.tryParse(normalized);
  }

  Future<void> _openLoginUrl(BuildContext context) async {
    final uri = _loginUri();
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _showError(context, 'ログインURLが登録されていません');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) {
      return;
    }
    if (!opened) {
      _showError(context, 'ログインページを開けませんでした');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginUri = _loginUri();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          credential.serviceName.isEmpty ? 'サービス詳細' : credential.serviceName,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _headerCard(),
            const SizedBox(height: 14),
            _infoCard(
              title: 'ログイン',
              icon: Icons.login_rounded,
              children: [
                _detailRow('メールアドレス / ID', credential.username),
                _detailRow('パスワード', '非表示'),
                _detailRow('ログインURL', _text(credential.loginUrl)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        loginUri == null ? null : () => _openLoginUrl(context),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('ログインする'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoCard(
              title: '認証コード',
              icon: Icons.verified_user_rounded,
              children: [
                _statusRow(
                  label: '登録状態',
                  value: credential.hasTotpSecret ? '登録あり' : '未登録',
                  active: credential.hasTotpSecret,
                ),
                if (!credential.hasTotpSecret)
                  _emptyHint('ログイン時に使う6桁コードはあとから追加できます。'),
              ],
            ),
            const SizedBox(height: 12),
            _infoCard(
              title: 'サブスク',
              icon: Icons.payments_outlined,
              children: [
                if (_hasSubscription) ...[
                  _detailRow('月額料金', _priceText()),
                  _detailRow('請求周期', _text(credential.billingCycle)),
                  _detailRow('更新日', _formatDate(credential.renewalDate)),
                  _detailRow('支払い方法', _text(credential.paymentMethod)),
                  _detailRow('解約URL', _text(credential.cancelUrl)),
                ] else ...[
                  _statusRow(label: '登録状態', value: '未登録', active: false),
                  _emptyHint('料金、更新日、支払い方法はあとから追加できます。'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _infoCard(
              title: 'AutoFill',
              icon: Icons.password_rounded,
              children: [
                _statusRow(
                  label: '対応状態',
                  value: '準備中',
                  active: false,
                  pending: true,
                ),
                _detailRow('対応ドメイン', _joinDomains(credential.domains)),
                _emptyHint('自動入力候補の本登録は次のステップで対応します。'),
              ],
            ),
            const SizedBox(height: 12),
            _actionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    final serviceName =
        credential.serviceName.isEmpty ? '未設定サービス' : credential.serviceName;
    final badge = serviceName.characters.first.toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _brand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _joinDomains(credential.domains),
                    style: const TextStyle(color: _textMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusBadge(
                        credential.hasTotpSecret ? '2FAあり' : '2FA未登録',
                        active: credential.hasTotpSecret,
                      ),
                      _statusBadge(
                        _hasSubscription ? 'サブスクあり' : 'サブスク未登録',
                        active: _hasSubscription,
                      ),
                      _statusBadge('AutoFill準備中', pending: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: _brand),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: _textMuted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required String label,
    required String value,
    required bool active,
    bool pending = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: _textMuted),
            ),
          ),
          const SizedBox(width: 10),
          _statusBadge(value, active: active, pending: pending),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String label, {
    bool active = false,
    bool pending = false,
  }) {
    final color = active ? _brand : (pending ? _warning : _textMuted);
    final background =
        active ? _brandSoft : (pending ? _warningSoft : _neutralSoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? _border : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _neutralSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _textMuted,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _actionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _brand,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '操作',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('編集'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('削除'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '編集と削除の実処理は次のステップで対応します。',
              style: TextStyle(color: _textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
