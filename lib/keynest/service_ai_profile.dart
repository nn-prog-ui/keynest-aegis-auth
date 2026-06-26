class ServiceAiProfile {
  const ServiceAiProfile({
    required this.serviceId,
    required this.planCandidates,
    required this.billingCycleCandidates,
    required this.paymentMethodHints,
    required this.cancelGuide,
    required this.userConfirmationItems,
    required this.aiAssistText,
  });

  final String serviceId;
  final List<ServicePlanCandidate> planCandidates;
  final List<String> billingCycleCandidates;
  final List<String> paymentMethodHints;
  final String cancelGuide;
  final List<ServiceUserConfirmationItem> userConfirmationItems;
  final String aiAssistText;
}

class ServicePlanCandidate {
  const ServicePlanCandidate({
    required this.name,
    this.priceHint = '',
    this.currency = 'JPY',
    this.billingCycle = '',
    this.description = '',
    this.requiresUserConfirmation = true,
  });

  final String name;
  final String priceHint;
  final String currency;
  final String billingCycle;
  final String description;
  final bool requiresUserConfirmation;
}

class ServiceUserConfirmationItem {
  const ServiceUserConfirmationItem({
    required this.fieldKey,
    required this.label,
    required this.reason,
    this.requiredForAccuracy = true,
  });

  final String fieldKey;
  final String label;
  final String reason;
  final bool requiredForAccuracy;
}

class ServiceAiProfileRepository {
  const ServiceAiProfileRepository();

  List<ServiceAiProfile> all() => _serviceAiProfiles;

  ServiceAiProfile? findByServiceId(String serviceId) {
    final normalized = serviceId.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    for (final profile in _serviceAiProfiles) {
      if (profile.serviceId == normalized) {
        return profile;
      }
    }
    return null;
  }
}

const List<ServiceAiProfile> _serviceAiProfiles = [
  ServiceAiProfile(
    serviceId: 'amazon',
    planCandidates: [
      ServicePlanCandidate(
        name: 'Amazon Prime',
        priceHint: '料金は地域・契約時期で変わるため確認してください',
        billingCycle: 'monthly_or_yearly',
        description: '配送特典、Prime Videoなどを含む代表的なAmazonサブスクです。',
      ),
      ServicePlanCandidate(
        name: 'Prime Video',
        priceHint: '契約経路により異なるため確認してください',
        billingCycle: 'monthly',
        description: '動画視聴を中心に使う場合の候補です。',
      ),
      ServicePlanCandidate(
        name: 'Kindle Unlimited',
        priceHint: 'キャンペーンや改定があるため確認してください',
        billingCycle: 'monthly',
        description: '電子書籍読み放題を管理したい場合の候補です。',
      ),
      ServicePlanCandidate(
        name: 'Amazon Music Unlimited',
        priceHint: '個人・ファミリー等で変わるため確認してください',
        billingCycle: 'monthly',
        description: '音楽サブスクをAmazonアカウントで管理している場合の候補です。',
      ),
      ServicePlanCandidate(
        name: 'Audible',
        priceHint: '現在の料金を確認してください',
        billingCycle: 'monthly',
        description: 'オーディオブック購読を管理する場合の候補です。',
      ),
    ],
    billingCycleCandidates: ['monthly', 'yearly'],
    paymentMethodHints: ['クレジットカード', 'デビットカード', 'Amazonギフトカード'],
    cancelGuide: 'Amazonアカウントにログインし、メンバーシップまたは各サービスの管理画面で解約導線を確認してください。',
    userConfirmationItems: [
      ServiceUserConfirmationItem(
        fieldKey: 'plan',
        label: '契約中のAmazonサービス',
        reason: 'AmazonにはPrime、Kindle、Music、Audibleなど複数のサブスクがあります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'price',
        label: '実際の料金',
        reason: '料金はプラン、地域、キャンペーン、契約時期で変わります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'renewalDate',
        label: '次回更新日',
        reason: '更新日はユーザーごとの契約日によって異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'paymentMethod',
        label: '支払い方法',
        reason: 'Amazon側の設定やギフト残高利用状況により異なります。',
      ),
    ],
    aiAssistText:
        'Amazonは複数サービスを同じアカウントで管理することがあります。Felaは候補を提示しますが、契約中のサービス名、料金、更新日はAmazon側で確認してください。',
  ),
  ServiceAiProfile(
    serviceId: 'netflix',
    planCandidates: [
      ServicePlanCandidate(
        name: '広告つき',
        priceHint: '現在のNetflix料金表で確認してください',
        billingCycle: 'monthly',
        description: '広告つきの低価格プラン候補です。',
      ),
      ServicePlanCandidate(
        name: 'スタンダード',
        priceHint: '現在のNetflix料金表で確認してください',
        billingCycle: 'monthly',
        description: '標準的なNetflixプラン候補です。',
      ),
      ServicePlanCandidate(
        name: 'プレミアム',
        priceHint: '現在のNetflix料金表で確認してください',
        billingCycle: 'monthly',
        description: '高画質・複数視聴向けのNetflixプラン候補です。',
      ),
    ],
    billingCycleCandidates: ['monthly'],
    paymentMethodHints: ['クレジットカード', 'デビットカード', 'PayPal', 'ギフトカード'],
    cancelGuide: 'Netflixにログインし、アカウント設定のメンバーシップ管理から解約状態を確認してください。',
    userConfirmationItems: [
      ServiceUserConfirmationItem(
        fieldKey: 'plan',
        label: '現在のNetflixプラン',
        reason: 'Netflixの料金と機能はプランによって異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'price',
        label: '実際の月額料金',
        reason: '料金改定や地域差があるため、Fela側では確定しません。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'renewalDate',
        label: '次回更新日',
        reason: '請求日はユーザーごとに異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'paymentMethod',
        label: '支払い方法',
        reason: 'Web決済、ギフトカード等で管理方法が変わる可能性があります。',
      ),
    ],
    aiAssistText:
        'Netflixは月額契約が中心ですが、プランと料金はユーザーごとに確認が必要です。Felaはプラン候補を表示し、正しい金額と更新日の入力を促します。',
  ),
  ServiceAiProfile(
    serviceId: 'chatgpt',
    planCandidates: [
      ServicePlanCandidate(
        name: 'Free',
        priceHint: '無料利用の場合は料金入力不要です',
        billingCycle: 'none',
        description: '無料プランとして管理する候補です。',
      ),
      ServicePlanCandidate(
        name: 'Plus',
        priceHint: '現在の請求画面で確認してください',
        billingCycle: 'monthly',
        description: '個人向け有料プラン候補です。',
      ),
      ServicePlanCandidate(
        name: 'Pro',
        priceHint: '現在の請求画面で確認してください',
        billingCycle: 'monthly',
        description: '上位の個人向け有料プラン候補です。',
      ),
      ServicePlanCandidate(
        name: 'Team',
        priceHint: '席数・契約周期で変わるため確認してください',
        billingCycle: 'monthly_or_yearly',
        description: 'チーム契約として管理する場合の候補です。',
      ),
    ],
    billingCycleCandidates: ['none', 'monthly', 'yearly'],
    paymentMethodHints: ['クレジットカード', 'デビットカード', 'App Store決済', 'Google Play決済'],
    cancelGuide: 'ChatGPTの設定または契約したストア側の購読管理画面で、現在のプランと解約導線を確認してください。',
    userConfirmationItems: [
      ServiceUserConfirmationItem(
        fieldKey: 'plan',
        label: '現在のChatGPTプラン',
        reason: 'Free、Plus、Pro、Teamで料金と管理画面が異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'billingSource',
        label: '請求元',
        reason: 'Web、App Store、Google Playなどで解約導線が変わります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'price',
        label: '実際の料金',
        reason: '為替、税、契約経路、席数により異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'renewalDate',
        label: '次回更新日',
        reason: '契約開始日や請求元によって異なります。',
      ),
    ],
    aiAssistText:
        'ChatGPTは請求元によって管理場所が変わることがあります。Felaはプラン候補を提示し、Web契約かストア決済かの確認を促します。',
  ),
  ServiceAiProfile(
    serviceId: 'youtube',
    planCandidates: [
      ServicePlanCandidate(
        name: 'YouTube Premium',
        priceHint: '現在のGoogle/YouTube請求画面で確認してください',
        billingCycle: 'monthly',
        description: '広告なし視聴などを含む代表的なYouTubeサブスクです。',
      ),
      ServicePlanCandidate(
        name: 'YouTube Music Premium',
        priceHint: '現在のGoogle/YouTube請求画面で確認してください',
        billingCycle: 'monthly',
        description: '音楽視聴を中心に管理する候補です。',
      ),
      ServicePlanCandidate(
        name: 'YouTube Premium Family',
        priceHint: 'ファミリー契約の料金を確認してください',
        billingCycle: 'monthly',
        description: '家族向け契約として管理する候補です。',
      ),
      ServicePlanCandidate(
        name: 'YouTube Channel Membership',
        priceHint: 'チャンネルごとに金額が異なるため確認してください',
        billingCycle: 'monthly',
        description: '個別チャンネルのメンバーシップ候補です。',
      ),
    ],
    billingCycleCandidates: ['monthly'],
    paymentMethodHints: ['Googleアカウントの支払い方法', 'App Store決済', 'Google Play決済'],
    cancelGuide: 'YouTubeの有料メンバーシップ管理画面、または契約したストア側の購読管理画面で解約導線を確認してください。',
    userConfirmationItems: [
      ServiceUserConfirmationItem(
        fieldKey: 'plan',
        label: 'YouTubeの契約プラン',
        reason: 'Premium、Music、Family、メンバーシップで管理内容が異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'billingSource',
        label: '請求元',
        reason: 'Google、App Store、Google Playで解約方法が変わります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'price',
        label: '実際の料金',
        reason: 'プラン、地域、契約経路で料金が異なります。',
      ),
      ServiceUserConfirmationItem(
        fieldKey: 'renewalDate',
        label: '次回更新日',
        reason: 'Googleアカウントやストアの契約日で異なります。',
      ),
    ],
    aiAssistText:
        'YouTubeはGoogleアカウントと紐づき、複数の有料プランが存在します。Felaは候補を整理し、どの契約かをユーザーに確認してから保存します。',
  ),
];
