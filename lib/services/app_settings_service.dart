import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_settings_storage_stub.dart'
    if (dart.library.html) 'app_settings_storage_web.dart'
    as app_settings_storage;

class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;

  AppSettingsService._internal() {
    _load();
  }

  final Map<String, dynamic> _values = <String, dynamic>{
    'メールビューア': 'コンパクト',
    '受信トレイ': '全受信',
    '外観': 'ライト',
    'スワイプ': '標準',
    '返信時に「完了」としてマーク': false,
    '宛先追加の提案': true,
    'インボックスゼロを共有': true,
    'サービス通知': 'オン',
    '通知音': 'デフォルト',
    'メール送信のキャンセル時間': '10秒',
    'VenemoAI': '無効',
    'plus_subscription_active': false,
    'plus_plan': 'free',
    'plus_billing_cycle': 'monthly',
    'plus_price_monthly_yen': 800,
    'plus_price_yearly_yen': 8000,
    'plus_source': 'none',
    'plus_product_id': '',
    'plus_expires_at': '',
    'plus_contract_type': 'individual',
    'plus_seat_count': 1,
    'plus_discount_percent': 0,
    'onboarding_completed': false,
    'onboarding_purpose': '',
    'onboarding_job': '',
    'onboarding_role': '',
    'onboarding_team_size': '',
    'onboarding_pain': '',
    'onboarding_goals': <String>[],
    'onboarding_yes_items': <String>[],
    'onboarding_ai_hint': '',
  };

  void _load() {
    final raw = app_settings_storage.readAppSettingsJson();
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _values.addAll(decoded);
        if (decoded.containsKey('Spark +AI') &&
            !decoded.containsKey('VenemoAI')) {
          _values['VenemoAI'] = decoded['Spark +AI'];
        }
        _values.remove('Spark +AI');
        if (decoded['plus_subscription_active'] != true) {
          _values['VenemoAI'] = '無効';
          _values['plus_plan'] = 'free';
          _values['plus_source'] = 'none';
          _values['plus_product_id'] = '';
          _values['plus_expires_at'] = '';
          _values['plus_contract_type'] = 'individual';
          _values['plus_seat_count'] = 1;
          _values['plus_discount_percent'] = 0;
        }
      }
    } catch (_) {
      // Ignore malformed stored settings and keep defaults.
    }
  }

  void _persist() {
    app_settings_storage.writeAppSettingsJson(jsonEncode(_values));
  }

  String getChoice(String key, {required String fallback}) {
    final value = _values[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  bool getSwitch(String key, {required bool fallback}) {
    final value = _values[key];
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  List<String> getStringList(String key) {
    final value = _values[key];
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  void setChoice(String key, String value) {
    _values[key] = value;
    _persist();
    notifyListeners();
  }

  void setSwitch(String key, bool value) {
    _values[key] = value;
    _persist();
    notifyListeners();
  }

  void setStringList(String key, List<String> values) {
    _values[key] = values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _persist();
    notifyListeners();
  }

  bool isPlusSubscribed() {
    return getSwitch('plus_subscription_active', fallback: false);
  }

  int plusMonthlyPriceYen() {
    final value = _values['plus_price_monthly_yen'];
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return 800;
  }

  int plusYearlyPriceYen() {
    final value = _values['plus_price_yearly_yen'];
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return plusMonthlyPriceYen() * 10;
  }

  void setPlusPricing({
    required int monthlyYen,
    required int yearlyYen,
  }) {
    final safeMonthly = monthlyYen > 0 ? monthlyYen : 800;
    final safeYearly = yearlyYen > 0 ? yearlyYen : safeMonthly * 10;
    _values['plus_price_monthly_yen'] = safeMonthly;
    _values['plus_price_yearly_yen'] = safeYearly;
    _persist();
    notifyListeners();
  }

  bool isAiAvailable() {
    return isPlusSubscribed();
  }

  String plusPlan() {
    return getChoice('plus_plan', fallback: 'free');
  }

  String plusBillingCycle() {
    return getChoice('plus_billing_cycle', fallback: 'monthly');
  }

  String plusSource() {
    return getChoice('plus_source', fallback: 'none');
  }

  String plusExpiresAt() {
    return getChoice('plus_expires_at', fallback: '');
  }

  String plusContractType() {
    return getChoice('plus_contract_type', fallback: 'individual');
  }

  int plusSeatCount() {
    final value = _values['plus_seat_count'];
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return 1;
  }

  int plusDiscountPercent() {
    final value = _values['plus_discount_percent'];
    if (value is int && value >= 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed >= 0) {
        return parsed;
      }
    }
    return 0;
  }

  void applyServerSubscriptionMap(Map<String, dynamic> subscription) {
    final plusActive = subscription['plusActive'] == true;
    final plan = (subscription['plan'] as String?)?.trim() ?? 'free';
    final billingCycle =
        (subscription['billingCycle'] as String?)?.trim() ?? 'monthly';
    final source = (subscription['source'] as String?)?.trim() ?? 'none';
    final productId = (subscription['productId'] as String?)?.trim() ?? '';
    final expiresAt = (subscription['expiresAt'] as String?)?.trim() ?? '';
    final contractType =
        (subscription['contractType'] as String?)?.trim() ?? 'individual';
    final seatCount = (subscription['seatCount'] as num?)?.toInt() ?? 1;
    final discountPercent =
        (subscription['discountPercent'] as num?)?.toInt() ?? 0;
    applyServerSubscription(
      plusActive: plusActive,
      plan: plan,
      billingCycle: billingCycle,
      source: source,
      productId: productId,
      expiresAt: expiresAt,
      contractType: contractType,
      seatCount: seatCount,
      discountPercent: discountPercent,
    );
  }

  void applyServerSubscription({
    required bool plusActive,
    required String plan,
    required String billingCycle,
    String source = 'none',
    String productId = '',
    String expiresAt = '',
    String contractType = 'individual',
    int seatCount = 1,
    int discountPercent = 0,
  }) {
    final normalizedContractType =
        contractType == 'business' ? 'business' : 'individual';
    final normalizedBillingCycle = normalizedContractType == 'business'
        ? 'yearly'
        : (billingCycle == 'yearly' ? 'yearly' : 'monthly');
    final normalizedSeatCount =
        normalizedContractType == 'business' ? (seatCount >= 40 ? 40 : 20) : 1;
    final normalizedDiscount = normalizedContractType == 'business'
        ? (discountPercent < 0 ? 0 : discountPercent)
        : 0;

    _values['plus_subscription_active'] = plusActive;
    _values['plus_plan'] = plusActive ? 'plus' : 'free';
    _values['plus_billing_cycle'] = normalizedBillingCycle;
    _values['plus_source'] = source.isEmpty ? 'none' : source;
    _values['plus_product_id'] = productId;
    _values['plus_expires_at'] = expiresAt;
    _values['plus_contract_type'] = normalizedContractType;
    _values['plus_seat_count'] = normalizedSeatCount;
    _values['plus_discount_percent'] = normalizedDiscount;

    if (!plusActive) {
      _values['VenemoAI'] = '無効';
    } else {
      _values['VenemoAI'] = '有効';
    }

    _persist();
    notifyListeners();
  }

  bool isAiEnabled() {
    if (!isAiAvailable()) return false;
    return getChoice('VenemoAI', fallback: '無効') == '有効';
  }

  void setAiEnabled(bool enabled) {
    if (enabled && !isAiAvailable()) {
      return;
    }
    setChoice('VenemoAI', enabled ? '有効' : '無効');
  }

  void activatePlusSubscription({String billingCycle = 'monthly'}) {
    _values['plus_subscription_active'] = true;
    _values['plus_plan'] = 'plus';
    _values['plus_billing_cycle'] = billingCycle;
    _values['plus_source'] = 'dev-local';
    _values['plus_product_id'] = '';
    _values['plus_expires_at'] = '';
    _values['plus_contract_type'] = 'individual';
    _values['plus_seat_count'] = 1;
    _values['plus_discount_percent'] = 0;
    _values['VenemoAI'] = '有効';
    _persist();
    notifyListeners();
  }

  void cancelPlusSubscription() {
    _values['plus_subscription_active'] = false;
    _values['plus_plan'] = 'free';
    _values['plus_billing_cycle'] = 'monthly';
    _values['plus_source'] = 'none';
    _values['plus_product_id'] = '';
    _values['plus_expires_at'] = '';
    _values['plus_contract_type'] = 'individual';
    _values['plus_seat_count'] = 1;
    _values['plus_discount_percent'] = 0;
    _values['VenemoAI'] = '無効';
    _persist();
    notifyListeners();
  }
}
