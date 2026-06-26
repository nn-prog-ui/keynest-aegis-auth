import 'package:flutter/material.dart';

import '../aegis_palette.dart';
import '../service_account_add_screen.dart';
import '../service_master.dart';
import 'import_source.dart';
import 'service_account_import_candidate.dart';

class ImportCandidatePreviewScreen extends StatefulWidget {
  const ImportCandidatePreviewScreen({
    super.key,
    required this.candidates,
  });

  final List<ServiceAccountImportCandidate> candidates;

  @override
  State<ImportCandidatePreviewScreen> createState() =>
      _ImportCandidatePreviewScreenState();
}

class _ImportCandidatePreviewScreenState
    extends State<ImportCandidatePreviewScreen> {
  final _serviceMasterRepository = const ServiceMasterRepository();
  final Set<int> _skippedIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    final visibleCandidates = widget.candidates
        .asMap()
        .entries
        .where((entry) => !_skippedIndexes.contains(entry.key))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('インポート候補'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text(
              'Felaが見つけた候補',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              '料金や更新日は参考候補です。保存前に必ず確認してください。',
              style: TextStyle(color: Color(0xFF6B7280), height: 1.45),
            ),
            const SizedBox(height: 14),
            if (visibleCandidates.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('表示できる候補はありません。'),
                ),
              )
            else
              ...visibleCandidates.map(
                (entry) => _buildCandidateCard(entry.key, entry.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(
    int index,
    ServiceAccountImportCandidate candidate,
  ) {
    final service = _serviceFor(candidate);
    final serviceName = service?.name ??
        candidate.sourceItem.serviceNameCandidate.trim().ifEmpty('未判定サービス');
    final recommendation = candidate.recommendation;
    final recommendedPlan = recommendation?.planRecommendation;
    final recommendedBillingCycle =
        recommendation?.billingCycleRecommendation.billingCycle ?? '';
    final billingCycle = recommendedBillingCycle
        .ifEmpty(candidate.sourceItem.billingCycleCandidate)
        .ifEmpty(service?.defaultBillingCycle ?? '');
    final priceHint = recommendedPlan?.priceHint ?? '';
    final amountCandidate = candidate.sourceItem.amountCandidate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ServiceGlyph(service: service, fallbackName: serviceName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        candidate.sourceItem.source.label,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(
              'おすすめプラン',
              recommendedPlan?.planName ?? '候補なし',
            ),
            _infoRow(
              '請求周期',
              _billingCycleLabel(billingCycle),
            ),
            if (amountCandidate != null)
              _infoRow(
                '料金候補（参考）',
                '${amountCandidate.toStringAsFixed(0)} ${candidate.sourceItem.currency.ifEmpty('JPY')}',
              )
            else if (priceHint.isNotEmpty)
              _infoRow('料金候補（参考）', priceHint),
            if (recommendation != null) ...[
              const SizedBox(height: 10),
              Text(
                recommendation.reason,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                recommendation.caution,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openAddScreen(candidate),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('保存'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _skippedIndexes.add(index);
                    });
                  },
                  child: const Text('スキップ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '未設定' : value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddScreen(ServiceAccountImportCandidate candidate) async {
    final service = _serviceFor(candidate);
    final recommendation = candidate.recommendation;
    final recommendedBillingCycle =
        recommendation?.billingCycleRecommendation.billingCycle ?? '';
    final billingCycle = recommendedBillingCycle
        .ifEmpty(candidate.sourceItem.billingCycleCandidate)
        .ifEmpty(service?.defaultBillingCycle ?? 'monthly');
    final currency = candidate.sourceItem.currency.ifEmpty(
      service?.defaultCurrency ?? 'JPY',
    );
    final serviceName = service?.name ??
        candidate.sourceItem.serviceNameCandidate.trim().ifEmpty('');

    final result = await Navigator.of(context).push<ServiceAccountSaveResult>(
      MaterialPageRoute(
        builder: (_) => ServiceAccountAddScreen(
          initialServiceId: service?.id ?? candidate.serviceId ?? '',
          initialServiceName: serviceName,
          initialDomains: service?.domains.join(', ') ?? '',
          initialLoginUrl: service?.loginUrl ?? '',
          initialCancelUrl: service?.cancelUrl ?? '',
          initialCurrency: currency,
          initialBillingCycle: billingCycle,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.snackMessage)),
    );
  }

  ServiceMaster? _serviceFor(ServiceAccountImportCandidate candidate) {
    final serviceId = candidate.serviceId;
    if (serviceId == null || serviceId.isEmpty) {
      return null;
    }

    for (final service in _serviceMasterRepository.all()) {
      if (service.id == serviceId) {
        return service;
      }
    }
    return null;
  }

  String _billingCycleLabel(String value) {
    switch (value) {
      case 'monthly':
        return '月額';
      case 'yearly':
        return '年額';
      case 'monthly_or_yearly':
        return '月額または年額';
      case 'none':
        return 'なし';
      default:
        return value;
    }
  }
}

class _ServiceGlyph extends StatelessWidget {
  const _ServiceGlyph({
    required this.service,
    required this.fallbackName,
  });

  final ServiceMaster? service;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final color =
        service == null ? AegisPalette.brand : Color(service!.iconColor);
    final label = service?.resolvedIconLabel ??
        (fallbackName.isEmpty ? 'F' : fallbackName.substring(0, 1));

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

extension _PreviewStringExt on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}
