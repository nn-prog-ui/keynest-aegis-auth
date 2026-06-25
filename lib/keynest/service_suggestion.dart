class ServiceSuggestion {
  const ServiceSuggestion({
    required this.serviceName,
    required this.category,
    required this.domains,
    required this.loginUrl,
    this.defaultCurrency = 'JPY',
    this.defaultBillingCycle = 'monthly',
    this.isPopular = false,
    this.isRecentlyAdded = false,
  });

  final String serviceName;
  final String category;
  final List<String> domains;
  final String loginUrl;
  final String defaultCurrency;
  final String defaultBillingCycle;
  final bool isPopular;
  final bool isRecentlyAdded;

  String get primaryDomain => domains.isEmpty ? '' : domains.first;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return serviceName.toLowerCase().contains(normalized) ||
        category.toLowerCase().contains(normalized) ||
        domains.any((domain) => domain.toLowerCase().contains(normalized)) ||
        loginUrl.toLowerCase().contains(normalized);
  }
}

const List<ServiceSuggestion> serviceSuggestions = [
  ServiceSuggestion(
    serviceName: 'Amazon',
    category: '買い物',
    domains: [
      'amazon.co.jp',
      'www.amazon.co.jp',
      'amazon.com',
      'www.amazon.com'
    ],
    loginUrl: 'https://www.amazon.co.jp/ap/signin',
    isPopular: true,
  ),
  ServiceSuggestion(
    serviceName: 'Google',
    category: '仕事',
    domains: ['google.com', 'accounts.google.com'],
    loginUrl: 'https://accounts.google.com/',
    isPopular: true,
  ),
  ServiceSuggestion(
    serviceName: 'Apple',
    category: '仕事',
    domains: ['apple.com', 'icloud.com', 'appleid.apple.com'],
    loginUrl: 'https://appleid.apple.com/sign-in',
    isPopular: true,
  ),
  ServiceSuggestion(
    serviceName: 'Netflix',
    category: '動画',
    domains: ['netflix.com', 'www.netflix.com'],
    loginUrl: 'https://www.netflix.com/login',
    isPopular: true,
  ),
  ServiceSuggestion(
    serviceName: 'ChatGPT',
    category: 'AI',
    domains: ['chatgpt.com', 'openai.com', 'auth.openai.com'],
    loginUrl: 'https://chatgpt.com/auth/login',
    isRecentlyAdded: true,
  ),
  ServiceSuggestion(
    serviceName: '楽天',
    category: '買い物',
    domains: ['rakuten.co.jp', 'www.rakuten.co.jp'],
    loginUrl: 'https://grp01.id.rakuten.co.jp/rms/nid/login',
    isPopular: true,
    isRecentlyAdded: true,
  ),
  ServiceSuggestion(
    serviceName: 'Adobe',
    category: '仕事',
    domains: ['adobe.com', 'auth.services.adobe.com'],
    loginUrl: 'https://auth.services.adobe.com/',
    isRecentlyAdded: true,
  ),
  ServiceSuggestion(
    serviceName: 'Microsoft',
    category: '仕事',
    domains: ['microsoft.com', 'login.microsoftonline.com', 'live.com'],
    loginUrl: 'https://login.microsoftonline.com/',
    isPopular: true,
  ),
  ServiceSuggestion(
    serviceName: 'Canva',
    category: '仕事',
    domains: ['canva.com', 'www.canva.com'],
    loginUrl: 'https://www.canva.com/login/',
    isRecentlyAdded: true,
  ),
  ServiceSuggestion(
    serviceName: 'YouTube',
    category: '動画',
    domains: ['youtube.com', 'www.youtube.com'],
    loginUrl: 'https://accounts.google.com/',
    isPopular: true,
  ),
  ServiceSuggestion(
    serviceName: 'Spotify',
    category: '音楽',
    domains: ['spotify.com', 'accounts.spotify.com'],
    loginUrl: 'https://accounts.spotify.com/login',
    isRecentlyAdded: true,
  ),
  ServiceSuggestion(
    serviceName: 'Yahoo! JAPAN',
    category: 'ポータル',
    domains: ['yahoo.co.jp', 'login.yahoo.co.jp'],
    loginUrl: 'https://login.yahoo.co.jp/',
  ),
  ServiceSuggestion(
    serviceName: 'SBI証券',
    category: '金融',
    domains: ['sbisec.co.jp', 'site1.sbisec.co.jp'],
    loginUrl: 'https://site1.sbisec.co.jp/ETGate/',
  ),
];
