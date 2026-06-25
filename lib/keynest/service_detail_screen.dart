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

  @override
  Widget build(BuildContext context) {
    final currency = _text(credential.currency ?? 'JPY');
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.serviceName.isEmpty
                          ? '未設定サービス'
                          : credential.serviceName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _joinDomains(credential.domains),
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _detailCard('ログイン情報', [
              _detailRow('メールアドレス / ID', credential.username),
              _detailRow('ログインURL', _text(credential.loginUrl)),
              _detailRow('2FA', credential.hasTotpSecret ? 'あり' : 'なし'),
            ]),
            const SizedBox(height: 12),
            _detailCard('サブスク情報', [
              _detailRow('月額料金', '${_text(credential.monthlyPrice)} $currency'),
              _detailRow('請求周期', _text(credential.billingCycle)),
              _detailRow('更新日', _formatDate(credential.renewalDate)),
              _detailRow('支払い方法', _text(credential.paymentMethod)),
              _detailRow('解約URL', _text(credential.cancelUrl)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detailCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...rows,
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
}
