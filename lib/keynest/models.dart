enum RequestStatus {
  pending,
  approved,
  denied,
}

class VerificationAccount {
  VerificationAccount({
    required this.id,
    required this.organization,
    required this.email,
    required this.secret,
    this.issuer,
    this.period = 30,
    this.digits = 6,
    this.algorithm = 'SHA1',
  });

  final String id;
  final String organization;
  final String email;
  final String secret;
  final String? issuer;
  final int period;
  final int digits;
  final String algorithm;

  VerificationAccount copyWith({
    String? id,
    String? organization,
    String? email,
    String? secret,
    String? issuer,
    int? period,
    int? digits,
    String? algorithm,
  }) {
    return VerificationAccount(
      id: id ?? this.id,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      secret: secret ?? this.secret,
      issuer: issuer ?? this.issuer,
      period: period ?? this.period,
      digits: digits ?? this.digits,
      algorithm: algorithm ?? this.algorithm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization': organization,
      'email': email,
      'secret': secret,
      'issuer': issuer,
      'period': period,
      'digits': digits,
      'algorithm': algorithm,
    };
  }

  factory VerificationAccount.fromJson(Map<String, dynamic> json) {
    final period = (json['period'] as num?)?.toInt() ?? 30;
    final digits = (json['digits'] as num?)?.toInt() ?? 6;
    final safeDigits = digits.clamp(6, 8);
    return VerificationAccount(
      id: (json['id'] as String?) ?? '',
      organization: (json['organization'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      secret: (json['secret'] as String?) ?? '',
      issuer: json['issuer'] as String?,
      period: period <= 0 ? 30 : period,
      digits: safeDigits,
      algorithm: ((json['algorithm'] as String?) ?? 'SHA1').toUpperCase(),
    );
  }
}

class SignInRequest {
  SignInRequest({
    required this.id,
    required this.organization,
    required this.location,
    required this.createdAt,
    this.status = RequestStatus.pending,
  });

  final String id;
  final String organization;
  final String location;
  final DateTime createdAt;
  RequestStatus status;
}

class KeyNestBackupPayload {
  KeyNestBackupPayload({
    required this.accounts,
    required this.backupCodes,
    required this.deviceLockEnabled,
    required this.updatedAt,
  });

  final List<VerificationAccount> accounts;
  final List<String> backupCodes;
  final bool deviceLockEnabled;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'accounts': accounts.map((item) => item.toJson()).toList(),
      'backupCodes': backupCodes,
      'deviceLockEnabled': deviceLockEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory KeyNestBackupPayload.fromJson(Map<String, dynamic> json) {
    final accountList = (json['accounts'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map((map) => VerificationAccount.fromJson(map))
        .where((item) => item.id.isNotEmpty && item.secret.isNotEmpty)
        .toList();

    final backupCodes = (json['backupCodes'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return KeyNestBackupPayload(
      accounts: accountList,
      backupCodes: backupCodes,
      deviceLockEnabled: json['deviceLockEnabled'] as bool? ?? true,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
