import 'package:flutter/material.dart';

import 'aegis_palette.dart';
import 'service_account_add_screen.dart';
import 'service_detail_screen.dart';
import 'service_search_screen.dart';
import 'shared_credential_bridge.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _credentialBridge = const SharedCredentialBridge();

  late Future<List<SharedCredentialListItem>> _credentialsFuture;

  @override
  void initState() {
    super.initState();
    _credentialsFuture = _credentialBridge.listCredentials();
  }

  void _reload() {
    setState(() {
      _credentialsFuture = _credentialBridge.listCredentials();
    });
  }

  Future<void> _openServiceSearch() async {
    final saveResult =
        await Navigator.of(context).push<ServiceAccountSaveResult>(
      MaterialPageRoute(builder: (_) => const ServiceSearchScreen()),
    );
    if (!mounted || saveResult == null) {
      return;
    }
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saveResult.snackMessage)),
    );
  }

  Map<String, double> _monthlyTotalsByCurrency(
    List<SharedCredentialListItem> credentials,
  ) {
    final totals = <String, double>{};
    for (final credential in credentials) {
      final currency = (credential.currency ?? 'JPY').trim().toUpperCase();
      if (currency.isEmpty) {
        continue;
      }
      totals[currency] = (totals[currency] ?? 0) + credential.monthlyEquivalent;
    }
    return totals;
  }

  String _formatMoney(double value, String currency) {
    final rounded =
        currency == 'JPY' ? value.round().toString() : value.toStringAsFixed(2);
    return '$rounded $currency';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}/$month/$day';
  }

  String _formatPrice(SharedCredentialListItem credential) {
    final price = credential.monthlyPrice;
    if (price == null || price.isEmpty) {
      return '-';
    }
    final currency = (credential.currency ?? 'JPY').toUpperCase();
    return '$price $currency';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('サービス一覧'),
              actions: [
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: '更新',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: FutureBuilder<List<SharedCredentialListItem>>(
          future: _credentialsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('保存済みサービスを読み込めませんでした。'),
                    ),
                  ),
                ],
              );
            }

            final credentials =
                snapshot.data ?? const <SharedCredentialListItem>[];
            final totals = _monthlyTotalsByCurrency(credentials);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _buildTotalsCard(credentials, totals),
                const SizedBox(height: 12),
                if (credentials.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('保存済みサービスがありません。サービス追加から登録してください。'),
                    ),
                  ),
                ...credentials.map(_buildServiceCard),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openServiceSearch,
        icon: const Icon(Icons.add_rounded),
        label: const Text('サービス追加'),
      ),
    );
  }

  Widget _buildTotalsCard(
    List<SharedCredentialListItem> credentials,
    Map<String, double> totals,
  ) {
    final totalText = totals.isEmpty
        ? '-'
        : totals.entries
            .map((entry) => _formatMoney(entry.value, entry.key))
            .join(' / ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今月のサブスク合計',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              totalText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '登録サービス: ${credentials.length}件',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(SharedCredentialListItem credential) {
    final badge = credential.serviceName.isNotEmpty
        ? credential.serviceName.characters.first.toUpperCase()
        : 'F';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(credential: credential),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
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
                          credential.serviceName.isEmpty
                              ? '未設定サービス'
                              : credential.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          credential.primaryDomain,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _serviceChip(
                      Icons.person_outline_rounded, credential.username),
                  _serviceChip(
                      Icons.payments_outlined, _formatPrice(credential)),
                  _serviceChip(
                    Icons.event_repeat_rounded,
                    _formatDate(credential.renewalDate),
                  ),
                  _serviceChip(
                    credential.hasTotpSecret
                        ? Icons.verified_user_rounded
                        : Icons.lock_open_rounded,
                    credential.hasTotpSecret ? '2FAあり' : '2FAなし',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AegisPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AegisPalette.brand),
          const SizedBox(width: 5),
          Text(
            text.isEmpty ? '-' : text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
