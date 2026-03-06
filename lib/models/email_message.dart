class EmailMessage {
  final String id;
  final String from;
  final String to;
  final String cc;
  final String subject;
  final String body;
  final DateTime date;
  final bool isUnread;
  final String snippet; // ← snippet を追加

  EmailMessage({
    required this.id,
    required this.from,
    this.to = '',
    this.cc = '',
    required this.subject,
    required this.body,
    required this.date,
    this.isUnread = false,
    this.snippet = '', // デフォルトは空文字
  });
}
