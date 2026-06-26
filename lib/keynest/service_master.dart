class ServiceMaster {
  const ServiceMaster({
    required this.id,
    required this.name,
    required this.category,
    required this.domains,
    required this.loginUrl,
    this.iconLabel = '',
    this.iconColor = 0xFF0B8F6D,
    this.iconStyle = 'solid',
    this.logoAsset = '',
    this.cancelUrl = '',
    this.supportUrl = '',
    this.helpUrl = '',
    this.defaultCurrency = 'JPY',
    this.defaultBillingCycle = 'monthly',
    this.supportsAutofill = true,
    this.supportsTotp = false,
    this.supportsSubscription = true,
    this.supportsPasskey = false,
    this.isPopular = false,
    this.isRecentlyAdded = false,
  });

  final String id;
  final String name;
  final String category;
  final List<String> domains;
  final String loginUrl;
  final String iconLabel;
  final int iconColor;
  final String iconStyle;
  final String logoAsset;
  final String cancelUrl;
  final String supportUrl;
  final String helpUrl;
  final String defaultCurrency;
  final String defaultBillingCycle;
  final bool supportsAutofill;
  final bool supportsTotp;
  final bool supportsSubscription;
  final bool supportsPasskey;
  final bool isPopular;
  final bool isRecentlyAdded;

  String get primaryDomain => domains.isEmpty ? '' : domains.first;

  String get resolvedIconLabel {
    if (iconLabel.trim().isNotEmpty) {
      return iconLabel.trim();
    }
    return name.isEmpty ? 'F' : name.substring(0, 1).toUpperCase();
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return id.toLowerCase().contains(normalized) ||
        name.toLowerCase().contains(normalized) ||
        category.toLowerCase().contains(normalized) ||
        domains.any((domain) => domain.toLowerCase().contains(normalized)) ||
        loginUrl.toLowerCase().contains(normalized) ||
        cancelUrl.toLowerCase().contains(normalized) ||
        supportUrl.toLowerCase().contains(normalized) ||
        helpUrl.toLowerCase().contains(normalized);
  }
}

class ServiceMasterRepository {
  const ServiceMasterRepository();

  List<ServiceMaster> all() => _serviceMasters;

  List<String> categories() {
    return [
      'すべて',
      ..._serviceMasters.map((service) => service.category).toSet().toList()
        ..sort(),
    ];
  }

  List<ServiceMaster> popular() {
    return _serviceMasters.where((service) => service.isPopular).toList();
  }

  List<ServiceMaster> recentlyAdded() {
    return _serviceMasters.where((service) => service.isRecentlyAdded).toList();
  }

  ServiceMaster? findForCredential({
    required String serviceName,
    required List<String> domains,
  }) {
    final normalizedName = serviceName.trim().toLowerCase();
    final normalizedDomains =
        domains.map((domain) => domain.trim().toLowerCase()).toSet();

    for (final service in _serviceMasters) {
      if (normalizedName.isNotEmpty &&
          (service.name.toLowerCase() == normalizedName ||
              service.id.toLowerCase() == normalizedName)) {
        return service;
      }

      final serviceDomains =
          service.domains.map((domain) => domain.toLowerCase()).toSet();
      if (normalizedDomains.any(serviceDomains.contains)) {
        return service;
      }
    }
    return null;
  }

  List<ServiceMaster> search(
      {required String query, required String category}) {
    return _serviceMasters.where((service) {
      final categoryMatches = category == 'すべて' || service.category == category;
      return categoryMatches && service.matches(query);
    }).toList();
  }
}

const List<ServiceMaster> _serviceMasters = [
  ServiceMaster(
    id: 'amazon',
    name: 'Amazon',
    category: '買い物',
    domains: [
      'amazon.co.jp',
      'www.amazon.co.jp',
      'amazon.com',
      'www.amazon.com',
    ],
    loginUrl: 'https://www.amazon.co.jp/ap/signin',
    iconLabel: 'am',
    iconColor: 0xFF232F3E,
    iconStyle: 'accent',
    isPopular: true,
  ),
  ServiceMaster(
    id: 'google',
    name: 'Google',
    category: 'メール',
    domains: ['google.com', 'accounts.google.com', 'gmail.com'],
    loginUrl: 'https://accounts.google.com/',
    iconLabel: 'G',
    iconColor: 0xFF4285F4,
    iconStyle: 'outline',
    supportsTotp: true,
    supportsPasskey: true,
    isPopular: true,
  ),
  ServiceMaster(
    id: 'apple',
    name: 'Apple',
    category: 'クラウド',
    domains: ['apple.com', 'icloud.com', 'appleid.apple.com'],
    loginUrl: 'https://appleid.apple.com/sign-in',
    iconLabel: 'A',
    iconColor: 0xFF111827,
    iconStyle: 'solid',
    supportsTotp: true,
    supportsPasskey: true,
    isPopular: true,
  ),
  ServiceMaster(
    id: 'netflix',
    name: 'Netflix',
    category: '動画・音楽',
    domains: ['netflix.com', 'www.netflix.com'],
    loginUrl: 'https://www.netflix.com/login',
    iconLabel: 'N',
    iconColor: 0xFFE50914,
    iconStyle: 'solid',
    cancelUrl: 'https://www.netflix.com/cancelplan',
    isPopular: true,
  ),
  ServiceMaster(
    id: 'chatgpt',
    name: 'ChatGPT',
    category: 'AI',
    domains: ['chatgpt.com', 'openai.com', 'auth.openai.com'],
    loginUrl: 'https://chatgpt.com/auth/login',
    iconLabel: 'AI',
    iconColor: 0xFF10A37F,
    iconStyle: 'soft',
    supportsTotp: true,
    supportsPasskey: true,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'rakuten',
    name: '楽天',
    category: '買い物',
    domains: ['rakuten.co.jp', 'www.rakuten.co.jp'],
    loginUrl: 'https://grp01.id.rakuten.co.jp/rms/nid/login',
    iconLabel: '楽',
    iconColor: 0xFFBF0000,
    iconStyle: 'solid',
    supportsTotp: true,
    isPopular: true,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'adobe',
    name: 'Adobe',
    category: '仕事',
    domains: ['adobe.com', 'auth.services.adobe.com'],
    loginUrl: 'https://auth.services.adobe.com/',
    iconLabel: 'Ad',
    iconColor: 0xFFFA0F00,
    iconStyle: 'solid',
    cancelUrl: 'https://account.adobe.com/plans',
    supportsTotp: true,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'microsoft',
    name: 'Microsoft',
    category: '仕事',
    domains: ['microsoft.com', 'login.microsoftonline.com', 'live.com'],
    loginUrl: 'https://login.microsoftonline.com/',
    iconLabel: 'M',
    iconColor: 0xFF2563EB,
    iconStyle: 'grid',
    supportsTotp: true,
    supportsPasskey: true,
    isPopular: true,
  ),
  ServiceMaster(
    id: 'canva',
    name: 'Canva',
    category: '仕事',
    domains: ['canva.com', 'www.canva.com'],
    loginUrl: 'https://www.canva.com/login/',
    iconLabel: 'C',
    iconColor: 0xFF7C3AED,
    iconStyle: 'soft',
    cancelUrl: 'https://www.canva.com/account/billing-and-plans/',
    supportsTotp: true,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'youtube',
    name: 'YouTube',
    category: '動画・音楽',
    domains: ['youtube.com', 'www.youtube.com'],
    loginUrl: 'https://accounts.google.com/',
    iconLabel: '▶',
    iconColor: 0xFFFF0000,
    iconStyle: 'solid',
    cancelUrl: 'https://www.youtube.com/paid_memberships',
    supportsTotp: true,
    supportsPasskey: true,
    isPopular: true,
  ),
  ServiceMaster(
    id: 'spotify',
    name: 'Spotify',
    category: '動画・音楽',
    domains: ['spotify.com', 'accounts.spotify.com'],
    loginUrl: 'https://accounts.spotify.com/login',
    iconLabel: 'S',
    iconColor: 0xFF1DB954,
    iconStyle: 'solid',
    cancelUrl: 'https://www.spotify.com/account/subscription/',
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'yahoo-japan',
    name: 'Yahoo! JAPAN',
    category: 'メール',
    domains: ['yahoo.co.jp', 'login.yahoo.co.jp'],
    loginUrl: 'https://login.yahoo.co.jp/',
    iconLabel: 'Y!',
    iconColor: 0xFFFF0033,
    iconStyle: 'solid',
    supportsTotp: true,
  ),
  ServiceMaster(
    id: 'sbi-securities',
    name: 'SBI証券',
    category: '金融',
    domains: ['sbisec.co.jp', 'site1.sbisec.co.jp'],
    loginUrl: 'https://site1.sbisec.co.jp/ETGate/',
    iconLabel: 'SBI',
    iconColor: 0xFF1D4ED8,
    iconStyle: 'accent',
    supportsTotp: true,
    supportsSubscription: false,
  ),
  ServiceMaster(
    id: 'paypay',
    name: 'PayPay',
    category: '金融',
    domains: ['paypay.ne.jp', 'www.paypay.ne.jp'],
    loginUrl: 'https://www.paypay.ne.jp/',
    iconLabel: 'P',
    iconColor: 0xFFE60012,
    iconStyle: 'soft',
    supportsTotp: true,
    supportsSubscription: false,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'line',
    name: 'LINE',
    category: 'SNS',
    domains: ['line.me', 'access.line.me'],
    loginUrl: 'https://access.line.me/',
    iconLabel: 'L',
    iconColor: 0xFF06C755,
    iconStyle: 'solid',
    supportsTotp: true,
    supportsSubscription: false,
    isPopular: true,
  ),
  ServiceMaster(
    id: 'instagram',
    name: 'Instagram',
    category: 'SNS',
    domains: ['instagram.com', 'www.instagram.com'],
    loginUrl: 'https://www.instagram.com/accounts/login/',
    iconLabel: 'IG',
    iconColor: 0xFFE1306C,
    iconStyle: 'accent',
    supportsTotp: true,
    supportsSubscription: false,
    isPopular: true,
  ),
  ServiceMaster(
    id: 'facebook',
    name: 'Facebook',
    category: 'SNS',
    domains: ['facebook.com', 'www.facebook.com'],
    loginUrl: 'https://www.facebook.com/login/',
    iconLabel: 'f',
    iconColor: 0xFF1877F2,
    iconStyle: 'solid',
    supportsTotp: true,
    supportsSubscription: false,
    isPopular: true,
  ),
];
