import 'package:flutter/material.dart';

import 'aegis_palette.dart';
import 'service_account_add_screen.dart';
import 'service_master.dart';

class ServiceSearchScreen extends StatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  final _searchController = TextEditingController();
  final _serviceMasterRepository = const ServiceMasterRepository();
  String _selectedCategory = 'すべて';

  List<String> get _categories => _serviceMasterRepository.categories();

  List<ServiceMaster> get _filteredSuggestions {
    return _serviceMasterRepository.search(
      query: _searchController.text,
      category: _selectedCategory,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSuggestion(ServiceMaster suggestion) async {
    final saveResult =
        await Navigator.of(context).push<ServiceAccountSaveResult>(
      MaterialPageRoute(
        builder: (_) => ServiceAccountAddScreen(
          initialServiceName: suggestion.name,
          initialDomains: suggestion.domains.join(', '),
          initialLoginUrl: suggestion.loginUrl,
          initialCancelUrl: suggestion.cancelUrl,
          initialCurrency: suggestion.defaultCurrency,
          initialBillingCycle: suggestion.defaultBillingCycle,
        ),
      ),
    );
    if (!mounted || saveResult == null) {
      return;
    }
    Navigator.of(context).pop(saveResult);
  }

  Future<void> _openManualAdd() async {
    final saveResult =
        await Navigator.of(context).push<ServiceAccountSaveResult>(
      MaterialPageRoute(builder: (_) => const ServiceAccountAddScreen()),
    );
    if (!mounted || saveResult == null) {
      return;
    }
    Navigator.of(context).pop(saveResult);
  }

  @override
  Widget build(BuildContext context) {
    final popular = _serviceMasterRepository.popular();
    final recentlyAdded = _serviceMasterRepository.recentlyAdded();
    final filtered = _filteredSuggestions;

    return Scaffold(
      appBar: AppBar(title: const Text('サービス追加')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: 'サービス名・ドメインで検索',
                hintText: 'Amazon、Netflix、chatgpt.com など',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _buildCategorySelector(),
            const SizedBox(height: 14),
            if (_searchController.text.trim().isEmpty &&
                _selectedCategory == 'すべて') ...[
              _buildSuggestionSection('人気サービス', popular),
              const SizedBox(height: 14),
              _buildSuggestionSection('最近追加が多いサービス', recentlyAdded),
              const SizedBox(height: 14),
            ],
            _buildSuggestionSection(
              _searchController.text.trim().isEmpty ? 'すべての候補' : '検索結果',
              filtered,
              showEmptyState: true,
            ),
            const SizedBox(height: 18),
            _buildManualAddCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリー',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              final selected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionSection(
    String title,
    List<ServiceMaster> suggestions, {
    bool showEmptyState = false,
  }) {
    if (suggestions.isEmpty && !showEmptyState) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (suggestions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('候補が見つかりません。下の手動追加を使ってください。'),
            ),
          )
        else
          ...suggestions.map(_buildSuggestionCard),
      ],
    );
  }

  Widget _buildSuggestionCard(ServiceMaster suggestion) {
    final badge = suggestion.name.characters.first.toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openSuggestion(suggestion),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AegisPalette.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      suggestion.primaryDomain,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _smallBadge(suggestion.category),
                        if (suggestion.domains.length > 1)
                          _smallBadge('${suggestion.domains.length}ドメイン'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AegisPalette.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildManualAddCard() {
    return Card(
      child: ListTile(
        onTap: _openManualAdd,
        leading: const Icon(Icons.edit_note_rounded),
        title: const Text(
          '手動でサービスを追加',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('候補にないサービスを自分で入力'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
