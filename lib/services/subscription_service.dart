import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_settings_service.dart';
import 'gmail_service.dart';

class SubscriptionService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'MAIL_BRIDGE_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final GmailService _gmail = GmailService();
  final AppSettingsService _settings = AppSettingsService();

  String? _lastError;
  String? get lastError => _lastError;

  Uri _uri(String path) => Uri.parse('$_apiBaseUrl$path');

  Map<String, String>? _sessionHeaders() {
    final token = _gmail.mailSessionToken?.trim() ?? '';
    if (token.isEmpty) {
      _lastError = 'サブスクリプション同期にはログインが必要です';
      return null;
    }
    return <String, String>{
      'Content-Type': 'application/json',
      'X-Mail-Session': token,
    };
  }

  void _applySubscriptionFromMap(Map<String, dynamic>? map) {
    if (map == null) return;
    _settings.applyServerSubscriptionMap(map);
  }

  Future<Map<String, dynamic>?> fetchConfig() async {
    _lastError = null;
    try {
      final response = await http.get(_uri('/api/subscription/config'));
      if (response.statusCode != 200) {
        _lastError = _extractError(response) ?? '課金設定の取得に失敗しました';
        return null;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        _lastError = '課金設定レスポンス形式が不正です';
        return null;
      }

      final plus = data['plus'];
      if (plus is Map<String, dynamic>) {
        final monthly = (plus['monthlyPriceYen'] as num?)?.toInt() ??
            _settings.plusMonthlyPriceYen();
        final yearly = (plus['yearlyPriceYen'] as num?)?.toInt() ??
            _settings.plusYearlyPriceYen();
        _settings.setPlusPricing(monthlyYen: monthly, yearlyYen: yearly);
        return plus;
      }
      return null;
    } catch (e) {
      _lastError = '課金設定の取得に失敗しました: $e';
      return null;
    }
  }

  Future<bool> refreshStatus() async {
    _lastError = null;
    await fetchConfig();
    final headers = _sessionHeaders();
    if (headers == null) return false;

    try {
      final response = await http.post(
        _uri('/api/subscription/status'),
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode != 200) {
        _lastError = _extractError(response) ?? '契約状態の取得に失敗しました';
        return false;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        _lastError = '契約状態レスポンス形式が不正です';
        return false;
      }
      final subscription = data['subscription'];
      if (subscription is Map<String, dynamic>) {
        _applySubscriptionFromMap(subscription);
      }
      return true;
    } catch (e) {
      _lastError = '契約状態の同期に失敗しました: $e';
      return false;
    }
  }

  Future<bool> activateDevPlus({
    String billingCycle = 'monthly',
    String contractType = 'individual',
    int seatCount = 1,
    int discountPercent = 0,
  }) async {
    _lastError = null;
    final headers = _sessionHeaders();
    if (headers == null) return false;

    try {
      final response = await http.post(
        _uri('/api/subscription/dev/activate'),
        headers: headers,
        body: jsonEncode({
          'billingCycle': billingCycle == 'yearly' ? 'yearly' : 'monthly',
          'contractType':
              contractType == 'business' ? 'business' : 'individual',
          'seatCount': seatCount,
          'discountPercent': discountPercent,
        }),
      );
      if (response.statusCode != 200) {
        _lastError = _extractError(response) ?? 'Plus有効化に失敗しました';
        return false;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        _lastError = 'Plus有効化レスポンス形式が不正です';
        return false;
      }
      final subscription = data['subscription'];
      if (subscription is Map<String, dynamic>) {
        _applySubscriptionFromMap(subscription);
      }
      return true;
    } catch (e) {
      _lastError = 'Plus有効化に失敗しました: $e';
      return false;
    }
  }

  Future<bool> cancelDevPlus() async {
    _lastError = null;
    final headers = _sessionHeaders();
    if (headers == null) return false;

    try {
      final response = await http.post(
        _uri('/api/subscription/dev/cancel'),
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode != 200) {
        _lastError = _extractError(response) ?? 'Plus解除に失敗しました';
        return false;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        _lastError = 'Plus解除レスポンス形式が不正です';
        return false;
      }
      final subscription = data['subscription'];
      if (subscription is Map<String, dynamic>) {
        _applySubscriptionFromMap(subscription);
      }
      return true;
    } catch (e) {
      _lastError = 'Plus解除に失敗しました: $e';
      return false;
    }
  }

  Future<String?> createWebCheckoutUrl({
    String billingCycle = 'monthly',
    String contractType = 'individual',
    int seatCount = 1,
    int discountPercent = 0,
  }) async {
    _lastError = null;
    final headers = _sessionHeaders();
    if (headers == null) return null;

    try {
      final response = await http.post(
        _uri('/api/subscription/web/checkout'),
        headers: headers,
        body: jsonEncode({
          'billingCycle': billingCycle == 'yearly' ? 'yearly' : 'monthly',
          'contractType':
              contractType == 'business' ? 'business' : 'individual',
          'seatCount': seatCount,
          'discountPercent': discountPercent,
          if (kIsWeb) ...{
            'successUrl': '${Uri.base.origin}/#/settings?billing=success',
            'cancelUrl': '${Uri.base.origin}/#/settings?billing=cancel',
          },
        }),
      );

      if (response.statusCode != 200) {
        _lastError = _extractError(response) ?? 'Stripe決済URLの作成に失敗しました';
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        _lastError = 'Stripe決済レスポンス形式が不正です';
        return null;
      }

      final checkoutUrl = (data['checkoutUrl'] as String?)?.trim() ?? '';
      if (checkoutUrl.isEmpty) {
        _lastError = 'Stripe決済URLが取得できませんでした';
        return null;
      }
      return checkoutUrl;
    } catch (e) {
      _lastError = 'Stripe決済URLの作成に失敗しました: $e';
      return null;
    }
  }

  Future<bool> verifyApplePurchase({
    required String transactionId,
    required String productId,
    String billingCycle = 'monthly',
    String receiptData = '',
    String originalTransactionId = '',
  }) async {
    return _verifyMobilePurchase(
      endpoint: '/api/subscription/apple/verify',
      payload: <String, dynamic>{
        'transactionId': transactionId,
        'productId': productId,
        'billingCycle': billingCycle,
        'receiptData': receiptData,
        'originalTransactionId': originalTransactionId,
      },
      errorPrefix: 'Apple課金検証に失敗しました',
    );
  }

  Future<bool> verifyGooglePurchase({
    required String purchaseToken,
    required String productId,
    String billingCycle = 'monthly',
    String orderId = '',
  }) async {
    return _verifyMobilePurchase(
      endpoint: '/api/subscription/google/verify',
      payload: <String, dynamic>{
        'purchaseToken': purchaseToken,
        'productId': productId,
        'billingCycle': billingCycle,
        'orderId': orderId,
      },
      errorPrefix: 'Google課金検証に失敗しました',
    );
  }

  Future<bool> _verifyMobilePurchase({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String errorPrefix,
  }) async {
    _lastError = null;
    final headers = _sessionHeaders();
    if (headers == null) return false;

    try {
      final response = await http.post(
        _uri(endpoint),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        _lastError = _extractError(response) ?? errorPrefix;
        return false;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        _lastError = '$errorPrefix: レスポンス形式が不正です';
        return false;
      }
      final subscription = data['subscription'];
      if (subscription is Map<String, dynamic>) {
        _applySubscriptionFromMap(subscription);
      }
      return true;
    } catch (e) {
      _lastError = '$errorPrefix: $e';
      return false;
    }
  }

  String? _extractError(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        final error = (data['error'] as String?)?.trim();
        if (error != null && error.isNotEmpty) {
          return error;
        }
      }
    } catch (_) {}
    return null;
  }
}
