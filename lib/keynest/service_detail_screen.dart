import 'package:flutter/material.dart';

import 'shared_credential_bridge.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.credential});

  final SharedCredentialListItem credential;

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

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 12),
            _sectionCard(
              title: 'ログイン情報',
              icon: Icons.login_rounded,
              children: [
                _detailRow('メールアドレス / ID', credential.username),
                _detailRow('パスワード', '非表示'),
                _detailRow('ログインURL', _text(credential.loginUrl)),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: '認証コード',
              icon: Icons.verified_user_rounded,
              children: [
                _statusRow(
                  label: 'TOTP',
                  value: credential.hasTotpSecret ? '登録あり' : '未登録',
                  active: credential.hasTotpSecret,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'サブスク',
              icon: Icons.payments_outlined,
              children: [
                _detailRow('月額料金', _priceText()),
                _detailRow('請求周期', _text(credential.billingCycle)),
                _detailRow('更新日', _formatDate(credential.renewalDate)),
                _detailRow('支払い方法', _text(credential.paymentMethod)),
                _detailRow('解約URL', _text(credential.cancelUrl)),
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'AutoFill',
              icon: Icons.password_rounded,
              children: [
                _statusRow(label: '対応状態', value: '準備中', active: false),
              ],
            ),
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
                color: const Color(0xFF0B8F6D),
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
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
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
                Icon(icon, size: 20, color: const Color(0xFF0B8F6D)),
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
              style: const TextStyle(color: Color(0xFF6B7280)),
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
  }) {
    final color = active ? const Color(0xFF0B8F6D) : const Color(0xFF6B7280);
    final background =
        active ? const Color(0xFFEFF7F3) : const Color(0xFFF3F4F6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
