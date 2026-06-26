class GmailReceiptCandidate {
  const GmailReceiptCandidate({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.from,
    required this.receivedAt,
    required this.snippet,
    required this.sourceQuery,
  });

  final String id;
  final String threadId;
  final String subject;
  final String from;
  final DateTime? receivedAt;
  final String snippet;
  final String sourceQuery;

  bool get hasReceivedAt => receivedAt != null;
}
