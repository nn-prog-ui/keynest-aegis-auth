import 'import_item.dart';
import 'import_source.dart';

class ImportRepository {
  const ImportRepository();

  Future<List<ImportItem>> preview(ImportSource source) async {
    switch (source) {
      case ImportSource.gmail:
        return _gmailDummyItems();
      case ImportSource.google:
      case ImportSource.microsoft:
      case ImportSource.appStore:
      case ImportSource.csv:
      case ImportSource.shareSheet:
        return const <ImportItem>[];
    }
  }

  List<ImportSource> supportedSources() {
    return ImportSource.values;
  }

  List<ImportItem> _gmailDummyItems() {
    return [
      ImportItem(
        source: ImportSource.gmail,
        serviceNameCandidate: 'Netflix',
        amountCandidate: 1490,
        currency: 'JPY',
        billingCycleCandidate: 'monthly',
        renewalDateCandidate: DateTime(2026, 7, 26),
        rawTitle: 'Netflix ご請求内容のお知らせ',
        rawSender: 'info@mailer.netflix.com',
      ),
      ImportItem(
        source: ImportSource.gmail,
        serviceNameCandidate: 'YouTube',
        amountCandidate: 1280,
        currency: 'JPY',
        billingCycleCandidate: 'monthly',
        renewalDateCandidate: DateTime(2026, 7, 20),
        rawTitle: 'YouTube Premium の領収書',
        rawSender: 'payments-noreply@google.com',
      ),
    ];
  }
}
