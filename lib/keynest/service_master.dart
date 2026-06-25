class ServiceMaster {
  const ServiceMaster({
    required this.id,
    required this.name,
    required this.category,
    required this.domains,
    required this.loginUrl,
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
  final String defaultCurrency;
  final String defaultBillingCycle;
  final bool supportsAutofill;
  final bool supportsTotp;
  final bool supportsSubscription;
  final bool supportsPasskey;
  final bool isPopular;
  final bool isRecentlyAdded;

  String get primaryDomain => domains.isEmpty ? '' : domains.first;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return id.toLowerCase().contains(normalized) ||
        name.toLowerCase().contains(normalized) ||
        category.toLowerCase().contains(normalized) ||
        domains.any((domain) => domain.toLowerCase().contains(normalized)) ||
        loginUrl.toLowerCase().contains(normalized);
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
    isPopular: true,
  ),
  ServiceMaster(
    id: 'google',
    name: 'Google',
    category: 'メール',
    domains: ['google.com', 'accounts.google.com', 'gmail.com'],
    loginUrl: 'https://accounts.google.com/',
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
    isPopular: true,
  ),
  ServiceMaster(
    id: 'chatgpt',
    name: 'ChatGPT',
    category: 'AI',
    domains: ['chatgpt.com', 'openai.com', 'auth.openai.com'],
    loginUrl: 'https://chatgpt.com/auth/login',
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
    supportsTotp: true,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'microsoft',
    name: 'Microsoft',
    category: '仕事',
    domains: ['microsoft.com', 'login.microsoftonline.com', 'live.com'],
    loginUrl: 'https://login.microsoftonline.com/',
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
    supportsTotp: true,
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'youtube',
    name: 'YouTube',
    category: '動画・音楽',
    domains: ['youtube.com', 'www.youtube.com'],
    loginUrl: 'https://accounts.google.com/',
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
    isRecentlyAdded: true,
  ),
  ServiceMaster(
    id: 'yahoo-japan',
    name: 'Yahoo! JAPAN',
    category: 'メール',
    domains: ['yahoo.co.jp', 'login.yahoo.co.jp'],
    loginUrl: 'https://login.yahoo.co.jp/',
    supportsTotp: true,
  ),
  ServiceMaster(
    id: 'sbi-securities',
    name: 'SBI証券',
    category: '金融',
    domains: ['sbisec.co.jp', 'site1.sbisec.co.jp'],
    loginUrl: 'https://site1.sbisec.co.jp/ETGate/',
    supportsTotp: true,
    supportsSubscription: false,
  ),
  ServiceMaster(
    id: 'paypay',
    name: 'PayPay',
    category: '金融',
    domains: ['paypay.ne.jp', 'www.paypay.ne.jp'],
    loginUrl: 'https://www.paypay.ne.jp/',
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
    supportsTotp: true,
    supportsSubscription: false,
    isPopular: true,
  ),
];
