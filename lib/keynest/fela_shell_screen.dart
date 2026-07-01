import 'package:flutter/material.dart';

import 'aegis_palette.dart';
import 'home/home_dashboard_screen.dart';
import 'service_list_screen.dart';

enum FelaSection {
  services,
  home,
  authCodes,
  subscriptions,
  vault,
  aiSecurity,
  settings,
}

class FelaShellScreen extends StatefulWidget {
  const FelaShellScreen({super.key});

  @override
  State<FelaShellScreen> createState() => _FelaShellScreenState();
}

class _FelaShellScreenState extends State<FelaShellScreen> {
  FelaSection _selectedSection = FelaSection.services;

  String get _title {
    return switch (_selectedSection) {
      FelaSection.services => 'サービス',
      FelaSection.home => 'ホーム',
      FelaSection.authCodes => '認証コード',
      FelaSection.subscriptions => 'サブスク',
      FelaSection.vault => 'Digital Vault',
      FelaSection.aiSecurity => 'AI Security',
      FelaSection.settings => '設定',
    };
  }

  void _selectSection(FelaSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final body = _buildBody();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text(
              'Fela',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: _FelaMenu(
                  selectedSection: _selectedSection,
                  onSelected: (section) {
                    Navigator.of(context).pop();
                    _selectSection(section);
                  })),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              SizedBox(
                width: 248,
                child: _FelaMenu(
                  selectedSection: _selectedSection,
                  onSelected: _selectSection,
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_selectedSection) {
      FelaSection.services => const ServiceListScreen(showAppBar: false),
      FelaSection.home => const HomeDashboardScreen(),
      FelaSection.authCodes => const FelaPlaceholderScreen(
          icon: Icons.verified_user_outlined,
          title: '認証コード',
          description: 'TOTP登録済みサービスを素早く確認する画面です。',
          actionLabel: 'サービスから認証コードを確認',
        ),
      FelaSection.subscriptions => const FelaPlaceholderScreen(
          icon: Icons.payments_outlined,
          title: 'サブスク',
          description: '月額料金、更新日、支払い方法をサービス単位で確認します。',
          actionLabel: 'サービス詳細でサブスクを管理',
        ),
      FelaSection.vault => const FelaPlaceholderScreen(
          icon: Icons.inventory_2_outlined,
          title: 'Digital Vault',
          description: '復旧コードや重要情報を安全に保管する場所です。',
          actionLabel: 'Vault詳細は準備中',
        ),
      FelaSection.aiSecurity => const FelaPlaceholderScreen(
          icon: Icons.shield_outlined,
          title: 'AI Security',
          description: '弱いパスワードや2FA未設定などを確認する画面です。',
          actionLabel: 'セキュリティ診断は準備中',
        ),
      FelaSection.settings => const FelaPlaceholderScreen(
          icon: Icons.settings_outlined,
          title: '設定',
          description: 'Face ID、AutoFill、バックアップなどの全体設定を管理します。',
          actionLabel: '設定項目は準備中',
        ),
    };
  }
}

class _FelaMenu extends StatelessWidget {
  const _FelaMenu({
    required this.selectedSection,
    required this.onSelected,
  });

  final FelaSection selectedSection;
  final ValueChanged<FelaSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text(
              'Fela',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          _menuItem(
            icon: Icons.apps_rounded,
            label: 'サービス',
            section: FelaSection.services,
          ),
          _menuItem(
            icon: Icons.home_outlined,
            label: 'ホーム',
            section: FelaSection.home,
          ),
          _menuItem(
            icon: Icons.verified_user_outlined,
            label: '認証コード',
            section: FelaSection.authCodes,
          ),
          _menuItem(
            icon: Icons.payments_outlined,
            label: 'サブスク',
            section: FelaSection.subscriptions,
          ),
          _menuItem(
            icon: Icons.inventory_2_outlined,
            label: 'Digital Vault',
            section: FelaSection.vault,
          ),
          _menuItem(
            icon: Icons.shield_outlined,
            label: 'AI Security',
            section: FelaSection.aiSecurity,
          ),
          _menuItem(
            icon: Icons.settings_outlined,
            label: '設定',
            section: FelaSection.settings,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required FelaSection section,
  }) {
    final selected = selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedTileColor: AegisPalette.brandSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: selected ? AegisPalette.brand : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        onTap: () => onSelected(section),
      ),
    );
  }
}

class FelaPlaceholderScreen extends StatelessWidget {
  const FelaPlaceholderScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AegisPalette.brand, size: 32),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7F3),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AegisPalette.border),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
