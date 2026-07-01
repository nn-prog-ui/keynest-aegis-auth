import 'package:flutter/material.dart';

import '../aegis_palette.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        const _SummaryGrid(),
        const SizedBox(height: 14),
        const _UpcomingRenewalsCard(),
        const SizedBox(height: 14),
        const _SuggestionCard(),
      ],
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AegisPalette.brandSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.dashboard_customize_outlined,
                color: AegisPalette.brand,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'おかえり',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '今日のデジタルライフ',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Felaが、サービス・固定費・保護状態をまとめて見えるようにします。',
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        return GridView.count(
          crossAxisCount: twoColumns ? 2 : 1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: twoColumns ? 2.25 : 2.7,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: const [
            _MetricCard(
              icon: Icons.payments_outlined,
              label: '今月のデジタル固定費',
              value: '12,480円',
              caption: 'ダミー値',
              color: Color(0xFF0B8F6D),
            ),
            _MetricCard(
              icon: Icons.verified_user_outlined,
              label: '保護率',
              value: '68%',
              caption: 'ダミー値',
              color: Color(0xFF2563EB),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w700,
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

class _UpcomingRenewalsCard extends StatelessWidget {
  const _UpcomingRenewalsCard();

  @override
  Widget build(BuildContext context) {
    return const _DashboardSectionCard(
      icon: Icons.event_available_outlined,
      title: '次回更新予定',
      subtitle: '近いうちに確認したい支払い',
      children: [
        _RenewalRow(
          serviceName: 'Netflix',
          detail: '7月20日 / 1,490円',
        ),
        _RenewalRow(
          serviceName: 'ChatGPT',
          detail: '7月28日 / 20 USD',
        ),
        _RenewalRow(
          serviceName: 'YouTube Premium',
          detail: '更新日を確認',
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

  @override
  Widget build(BuildContext context) {
    return const _DashboardSectionCard(
      icon: Icons.auto_awesome_outlined,
      title: 'Felaからの提案',
      subtitle: '次に補完すると便利なこと',
      children: [
        _SuggestionRow(
          icon: Icons.lock_outline_rounded,
          text: '3サービスでAutoFill設定を確認できます',
        ),
        _SuggestionRow(
          icon: Icons.password_outlined,
          text: '2FA未登録の重要サービスがあります',
        ),
        _SuggestionRow(
          icon: Icons.payments_outlined,
          text: '料金未設定のサブスク候補があります',
        ),
      ],
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AegisPalette.brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RenewalRow extends StatelessWidget {
  const _RenewalRow({
    required this.serviceName,
    required this.detail,
  });

  final String serviceName;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AegisPalette.brand,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              serviceName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AegisPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AegisPalette.brand, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
