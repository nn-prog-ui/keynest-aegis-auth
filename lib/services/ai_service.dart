import 'dart:convert';

import 'package:http/http.dart' as http;

import 'gmail_service.dart';

class AIService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'MAIL_BRIDGE_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static Future<void> initialize() async {
    // Client does not load API keys anymore.
    // AI requests are proxied to backend.
  }

  static Uri _uri(String path) => Uri.parse('$_apiBaseUrl$path');
  static String? _lastError;
  static String? get lastError => _lastError;

  Future<String> generateText(String prompt) async {
    final text = await _postAndReadText(
      '/api/ai/generate-text',
      {'prompt': prompt},
    );
    if (text == null) {
      throw Exception(_lastError ?? 'AIテキスト生成に失敗しました');
    }
    return text;
  }

  static Future<String?> generateReply(
    String emailContent, {
    String? userSummary,
  }) async {
    return _postAndReadText('/api/ai/generate-reply', {
      'emailContent': emailContent,
      'userSummary': userSummary,
    });
  }

  static Future<String?> improveReply(String reply) async {
    return _postAndReadText('/api/ai/improve-reply', {
      'reply': reply,
    });
  }

  static Future<String?> _postAndReadText(
    String path,
    Map<String, dynamic> payload,
  ) async {
    _lastError = null;
    try {
      final sessionToken = GmailService().mailSessionToken;
      if (sessionToken == null || sessionToken.trim().isEmpty) {
        _lastError = 'AI機能の利用にはログインが必要です';
        return null;
      }

      final response = await http.post(
        _uri(path),
        headers: {
          'Content-Type': 'application/json',
          'X-Mail-Session': sessionToken.trim(),
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        try {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data is Map<String, dynamic>) {
            final message = (data['error'] as String?)?.trim();
            if (message != null && message.isNotEmpty) {
              if (response.statusCode == 402) {
                _lastError = 'Venemo Plus契約が必要です: $message';
              } else {
                _lastError = message;
              }
              return null;
            }
          }
        } catch (_) {}
        if (response.statusCode == 401) {
          _lastError = 'セッションが無効です。再ログインしてください';
        } else if (response.statusCode == 402) {
          _lastError = 'Venemo Plus契約が必要です';
        } else {
          _lastError = 'AIサーバーエラー (${response.statusCode})';
        }
        return null;
      }

      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        _lastError = 'AIレスポンス形式が不正です';
        return null;
      }
      final text = body['text'];
      if (text is! String || text.trim().isEmpty) {
        _lastError = 'AIレスポンスが空でした';
        return null;
      }
      return text.trim();
    } catch (_) {
      _lastError = 'AIサーバーに接続できません。サーバー起動と接続設定を確認してください。';
      return null;
    }
  }
}
