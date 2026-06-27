import 'package:flutter/services.dart';

class SharedCredentialSaveRequest {
  const SharedCredentialSaveRequest({
    required this.serviceName,
    required this.domains,
    required this.username,
    required this.password,
    this.recordIdentifier,
    this.loginUrl,
    this.monthlyPrice,
    this.currency,
    this.billingCycle,
    this.renewalDate,
    this.paymentMethod,
    this.cancelUrl,
  });

  final String? recordIdentifier;
  final String serviceName;
  final List<String> domains;
  final String username;
  final String password;
  final String? loginUrl;
  final String? monthlyPrice;
  final String? currency;
  final String? billingCycle;
  final DateTime? renewalDate;
  final String? paymentMethod;
  final String? cancelUrl;

  Map<String, Object?> toMethodArguments() {
    return {
      if (recordIdentifier != null && recordIdentifier!.isNotEmpty)
        'recordIdentifier': recordIdentifier,
      'serviceName': serviceName,
      'domains': domains,
      'username': username,
      'password': password,
      if (loginUrl != null && loginUrl!.isNotEmpty) 'loginUrl': loginUrl,
      if (monthlyPrice != null && monthlyPrice!.isNotEmpty)
        'monthlyPrice': monthlyPrice,
      if (currency != null && currency!.isNotEmpty) 'currency': currency,
      if (billingCycle != null && billingCycle!.isNotEmpty)
        'billingCycle': billingCycle,
      if (renewalDate != null)
        'renewalDate': renewalDate!.toUtc().toIso8601String(),
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'paymentMethod': paymentMethod,
      if (cancelUrl != null && cancelUrl!.isNotEmpty) 'cancelUrl': cancelUrl,
    };
  }
}

class SharedCredentialListItem {
  const SharedCredentialListItem({
    required this.recordIdentifier,
    required this.serviceName,
    required this.domains,
    required this.username,
    required this.hasTotpSecret,
    this.loginUrl,
    this.monthlyPrice,
    this.currency,
    this.billingCycle,
    this.renewalDate,
    this.paymentMethod,
    this.cancelUrl,
    this.updatedAt,
  });

  final String recordIdentifier;
  final String serviceName;
  final List<String> domains;
  final String username;
  final bool hasTotpSecret;
  final String? loginUrl;
  final String? monthlyPrice;
  final String? currency;
  final String? billingCycle;
  final DateTime? renewalDate;
  final String? paymentMethod;
  final String? cancelUrl;
  final DateTime? updatedAt;

  factory SharedCredentialListItem.fromMap(Map<String, Object?> map) {
    return SharedCredentialListItem(
      recordIdentifier: map['recordIdentifier']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      domains: _stringList(map['domains']),
      username: map['username']?.toString() ?? '',
      hasTotpSecret: map['hasTotpSecret'] == true,
      loginUrl: _optionalString(map['loginUrl']),
      monthlyPrice: _optionalString(map['monthlyPrice']),
      currency: _optionalString(map['currency']),
      billingCycle: _optionalString(map['billingCycle']),
      renewalDate: DateTime.tryParse(map['renewalDate']?.toString() ?? ''),
      paymentMethod: _optionalString(map['paymentMethod']),
      cancelUrl: _optionalString(map['cancelUrl']),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }

  double get monthlyEquivalent {
    final value = double.tryParse(monthlyPrice ?? '') ?? 0;
    final cycle = (billingCycle ?? '').trim().toLowerCase();
    if (cycle == 'yearly' ||
        cycle == 'annual' ||
        cycle == 'year' ||
        cycle == '年額') {
      return value / 12;
    }
    if (cycle == 'weekly' || cycle == 'week' || cycle == '週額') {
      return value * 4.345;
    }
    if (cycle == 'daily' || cycle == 'day' || cycle == '日額') {
      return value * 30.437;
    }
    return value;
  }

  String get primaryDomain => domains.isEmpty ? '-' : domains.first;

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

class SharedCredentialBridge {
  const SharedCredentialBridge();

  static const MethodChannel _channel =
      MethodChannel('fela/shared_credentials');

  Future<String> saveCredential(SharedCredentialSaveRequest request) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'saveCredential',
      request.toMethodArguments(),
    );
    final recordIdentifier = result?['recordIdentifier']?.toString();
    if (recordIdentifier == null || recordIdentifier.isEmpty) {
      throw StateError('保存結果を確認できませんでした');
    }
    return recordIdentifier;
  }

  Future<int> registerAutoFillCredential(String recordIdentifier) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'registerAutoFillCredential',
      {'recordIdentifier': recordIdentifier},
    );
    final count = result?['registeredIdentityCount'];
    if (count is int) {
      return count;
    }
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  Future<List<SharedCredentialListItem>> listCredentials() async {
    final result =
        await _channel.invokeListMethod<Object?>('listCredentials') ??
            <Object?>[];
    return result.whereType<Map>().map((item) {
      return SharedCredentialListItem.fromMap(Map<String, Object?>.from(item));
    }).toList();
  }
}
