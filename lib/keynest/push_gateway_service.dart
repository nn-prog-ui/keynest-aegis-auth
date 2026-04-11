import 'dart:convert';

import 'package:http/http.dart' as http;

class PushGatewayService {
  PushGatewayService({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'KEYNEST_API_URL',
      defaultValue: 'http://localhost:3000',
    ),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    required String fcmToken,
    String? apnsToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/keynest/push/register'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        'platform': platform,
        'token': fcmToken,
        'apnsToken': apnsToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('デバイス登録に失敗しました (${response.statusCode})');
    }
  }

  Future<void> sendTestPush({
    required String deviceId,
    String title = 'KeyNest Test',
    String body = 'Push通知のテストです',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/keynest/push/send-test'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        'title': title,
        'body': body,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('テスト通知の送信に失敗しました (${response.statusCode})');
    }
  }
}
