import '../gmail/gmail_import_service.dart';
import '../gmail/gmail_receipt_candidate.dart';
import 'import_item.dart';
import 'import_source.dart';

class ImportRepository {
  const ImportRepository({
    GmailImportService gmailImportService = const GmailImportService(),
  }) : _gmailImportService = gmailImportService;

  final GmailImportService _gmailImportService;

  Future<List<ImportItem>> preview(
    ImportSource source, {
    String? accessToken,
  }) async {
    switch (source) {
      case ImportSource.gmail:
        return _gmailCandidatesToImportItems(
          await _gmailImportService.searchReceiptCandidates(
            accessToken: accessToken ?? '',
          ),
        );
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

  List<ImportItem> _gmailCandidatesToImportItems(
    List<GmailReceiptCandidate> candidates,
  ) {
    return candidates
        .map(
          (candidate) => ImportItem(
            source: ImportSource.gmail,
            rawTitle: candidate.subject,
            rawSender: candidate.from,
          ),
        )
        .toList(growable: false);
  }
}
