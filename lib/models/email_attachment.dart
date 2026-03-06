class EmailAttachment {
  final String fileName;
  final String mimeType;
  final List<int> bytes;

  const EmailAttachment({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  int get sizeBytes => bytes.length;
}
