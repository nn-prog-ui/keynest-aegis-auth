import 'import_source.dart';

class ImportItem {
  const ImportItem({
    required this.source,
    this.serviceNameCandidate = '',
    this.amountCandidate,
    this.currency = '',
    this.billingCycleCandidate = '',
    this.renewalDateCandidate,
    this.rawTitle = '',
    this.rawSender = '',
  });

  final ImportSource source;
  final String serviceNameCandidate;
  final double? amountCandidate;
  final String currency;
  final String billingCycleCandidate;
  final DateTime? renewalDateCandidate;
  final String rawTitle;
  final String rawSender;

  bool get hasAmountCandidate => amountCandidate != null;
  bool get hasRenewalDateCandidate => renewalDateCandidate != null;
}
