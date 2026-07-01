import 'dart:convert';

import 'package:http/http.dart' as http;

import 'gmail_receipt_candidate.dart';

class GmailImportException implements Exception {
  const GmailImportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'GmailImportException: $message';
}

class GmailImportService {
  const GmailImportService({
    http.Client? httpClient,
  }) : _httpClient = httpClient;

  static const String receiptCandidateQuery =
      'newer_than:12m (receipt OR invoice OR subscription OR 領収書 OR 請求 OR サブスクリプション)';
  static const int defaultMaxResults = 10;

  final http.Client? _httpClient;

  Future<List<GmailReceiptCandidate>> searchReceiptCandidates({
    required String accessToken,
    int maxResults = defaultMaxResults,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw const GmailImportException('Googleアクセストークンがありません。');
    }

    final client = _httpClient ?? http.Client();
    final shouldCloseClient = _httpClient == null;
    try {
      final messageIds = await _listCandidateMessageIds(
        client: client,
        accessToken: accessToken,
        maxResults: maxResults,
      );
      final candidates = <GmailReceiptCandidate>[];
      for (final messageId in messageIds) {
        final candidate = await _getCandidateMessage(
          client: client,
          accessToken: accessToken,
          messageId: messageId,
        );
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
      return candidates;
    } on GmailImportException {
      rethrow;
    } catch (error) {
      throw GmailImportException('Gmailの候補取得に失敗しました。', error);
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<List<String>> _listCandidateMessageIds({
    required http.Client client,
    required String accessToken,
    required int maxResults,
  }) async {
    final response = await client.get(
      Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages',
        {
          'q': receiptCandidateQuery,
          'maxResults': maxResults.clamp(1, 25).toString(),
        },
      ),
      headers: _authorizationHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const GmailImportException(
          'Gmailの権限がまだ許可されていない可能性があります',
        );
      }
      throw GmailImportException(
        'Gmailの候補一覧を取得できませんでした。(${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GmailImportException('Gmailの候補一覧形式が不正です。');
    }

    final messages = decoded['messages'];
    if (messages is! List) {
      return const <String>[];
    }

    return messages
        .whereType<Map<String, dynamic>>()
        .map((message) => message['id'])
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<GmailReceiptCandidate?> _getCandidateMessage({
    required http.Client client,
    required String accessToken,
    required String messageId,
  }) async {
    final response = await client.get(
      Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages/$messageId',
        {
          'format': 'metadata',
        },
      ),
      headers: _authorizationHeaders(accessToken),
    );

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const GmailImportException(
          'Gmailの権限がまだ許可されていない可能性があります',
        );
      }
      throw GmailImportException(
        'Gmailの候補詳細を取得できませんでした。(${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GmailImportException('Gmailの候補詳細形式が不正です。');
    }

    final headers = _headersFrom(decoded);
    final subject = headers['subject'] ?? '';
    final from = headers['from'] ?? '';
    final snippet =
        decoded['snippet'] is String ? decoded['snippet'] as String : '';

    return GmailReceiptCandidate(
      id: decoded['id'] is String ? decoded['id'] as String : messageId,
      threadId:
          decoded['threadId'] is String ? decoded['threadId'] as String : '',
      subject: subject,
      from: from,
      receivedAt: _receivedAtFrom(decoded),
      snippet: snippet,
      sourceQuery: receiptCandidateQuery,
    );
  }

  Map<String, String> _authorizationHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _headersFrom(Map<String, dynamic> message) {
    final payload = message['payload'];
    if (payload is! Map<String, dynamic>) {
      return const <String, String>{};
    }
    final rawHeaders = payload['headers'];
    if (rawHeaders is! List) {
      return const <String, String>{};
    }

    final headers = <String, String>{};
    for (final rawHeader in rawHeaders.whereType<Map<String, dynamic>>()) {
      final name = rawHeader['name'];
      final value = rawHeader['value'];
      if (name is String && value is String) {
        headers[name.toLowerCase()] = value;
      }
    }
    return headers;
  }

  DateTime? _receivedAtFrom(Map<String, dynamic> message) {
    final internalDate = message['internalDate'];
    if (internalDate is! String) {
      return null;
    }
    final millisecondsSinceEpoch = int.tryParse(internalDate);
    if (millisecondsSinceEpoch == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }
}
