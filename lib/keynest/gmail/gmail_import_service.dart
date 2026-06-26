import 'gmail_receipt_candidate.dart';

class GmailImportException implements Exception {
  const GmailImportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'GmailImportException: $message';
}

class GmailImportService {
  const GmailImportService();

  static const String receiptCandidateQuery =
      'newer_than:12m (receipt OR invoice OR subscription OR 領収書 OR 請求 OR サブスクリプション)';

  Future<List<GmailReceiptCandidate>> searchReceiptCandidates({
    required String accessToken,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw const GmailImportException('Googleアクセストークンがありません。');
    }

    return const <GmailReceiptCandidate>[];
  }
}
