import 'package:flutter/material.dart';

import '../aegis_palette.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: const [
        _HealthHeaderCard(),
        SizedBox(height: 16),
        _MonthlyCostCard(),
        SizedBox(height: 12),
        _ProtectionStateCard(),
        SizedBox(height: 12),
        _UpcomingRenewalsCard(),
      ],
    );
  }
}

class _HealthHeaderCard extends StatelessWidget {
  const _HealthHeaderCard();

  static const bool hasImportantNotice = false;

  @override
  Widget build(BuildContext context) {
    final title = hasImportantNotice ? '確認したいことがあります。' : 'おかえり';
    final message =
        hasImportantNotice ? 'いくつか確認すると安心な項目があります。' : '今日は大きな問題はありません。';
    final icon = hasImportantNotice
        ? Icons.notifications_active_outlined
        : Icons.health_and_safety_outlined;
    final color =
        hasImportantNotice ? const Color(0xFFB45309) : AegisPalette.brand;
    final backgroundColor =
        hasImportantNotice ? const Color(0xFFFFF7ED) : AegisPalette.brandSoft;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Felaが、固定費・保護状態・更新予定を静かに見守ります。',
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

class _MonthlyCostCard extends StatelessWidget {
  const _MonthlyCostCard();

  @override
  Widget build(BuildContext context) {
    return const _InsightCard(
      icon: Icons.payments_outlined,
      title: '今月の固定費',
      primaryText: '12,480円の予定です',
      secondaryText: '登録済みサービスの月額をまとめた目安です。',
      accentColor: AegisPalette.brand,
    );
  }
}

class _ProtectionStateCard extends StatelessWidget {
  const _ProtectionStateCard();

  @override
  Widget build(BuildContext context) {
    return const _InsightCard(
      icon: Icons.verified_user_outlined,
      title: '保護されているサービス',
      primaryText: '多くのサービスが見守られています',
      secondaryText: 'AutoFillや2FAの状態は、今後ここに自然に反映します。',
      accentColor: Color(0xFF2563EB),
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
      subtitle: '近い予定だけを表示します',
      children: [
        _RenewalRow(
          serviceName: 'Netflix',
          detail: '7月20日',
        ),
        _RenewalRow(
          serviceName: 'ChatGPT',
          detail: '7月28日',
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.primaryText,
    required this.secondaryText,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String primaryText;
  final String secondaryText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    primaryText,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    secondaryText,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.45,
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
        padding: const EdgeInsets.all(18),
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
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AegisPalette.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: AegisPalette.brand,
            ),
          ),
          const SizedBox(width: 12),
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
