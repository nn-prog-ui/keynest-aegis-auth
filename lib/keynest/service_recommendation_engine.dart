import 'service_ai_profile.dart';

class ServiceRecommendation {
  const ServiceRecommendation({
    required this.serviceId,
    required this.planRecommendation,
    required this.billingCycleRecommendation,
    required this.reason,
    required this.caution,
  });

  final String serviceId;
  final ServicePlanRecommendation planRecommendation;
  final BillingCycleRecommendation billingCycleRecommendation;
  final String reason;
  final String caution;
}

class ServicePlanRecommendation {
  const ServicePlanRecommendation({
    required this.planName,
    required this.reason,
    required this.priceHint,
    required this.requiresUserConfirmation,
  });

  final String planName;
  final String reason;
  final String priceHint;
  final bool requiresUserConfirmation;
}

class BillingCycleRecommendation {
  const BillingCycleRecommendation({
    required this.billingCycle,
    required this.reason,
    required this.requiresUserConfirmation,
  });

  final String billingCycle;
  final String reason;
  final bool requiresUserConfirmation;
}

class ServiceRecommendationEngine {
  const ServiceRecommendationEngine();

  ServiceRecommendation? recommend(ServiceAiProfile profile) {
    switch (profile.serviceId) {
      case 'amazon':
        return _amazon(profile);
      case 'netflix':
        return _netflix(profile);
      case 'chatgpt':
        return _chatGpt(profile);
      case 'youtube':
        return _youtube(profile);
      default:
        return null;
    }
  }

  ServiceRecommendation? recommendByServiceId(String serviceId) {
    final profile =
        const ServiceAiProfileRepository().findByServiceId(serviceId);
    if (profile == null) {
      return null;
    }
    return recommend(profile);
  }

  ServiceRecommendation _amazon(ServiceAiProfile profile) {
    final plan = _planByName(profile, 'Amazon Prime');
    return ServiceRecommendation(
      serviceId: profile.serviceId,
      planRecommendation: ServicePlanRecommendation(
        planName: plan.name,
        reason: 'Amazonで最も代表的なサブスク候補です。',
        priceHint: plan.priceHint,
        requiresUserConfirmation: true,
      ),
      billingCycleRecommendation: const BillingCycleRecommendation(
        billingCycle: 'monthly_or_yearly',
        reason: 'Amazon Primeは月額または年額の可能性があります。',
        requiresUserConfirmation: true,
      ),
      reason: 'Amazonは複数のサブスクを持つため、まず代表候補を提示します。',
      caution: '契約中のサービス名、料金、更新日はAmazon側で確認してください。',
    );
  }

  ServiceRecommendation _netflix(ServiceAiProfile profile) {
    final plan = _planByName(profile, 'スタンダード');
    return ServiceRecommendation(
      serviceId: profile.serviceId,
      planRecommendation: ServicePlanRecommendation(
        planName: plan.name,
        reason: '個人利用で比較しやすい標準的な候補です。',
        priceHint: plan.priceHint,
        requiresUserConfirmation: true,
      ),
      billingCycleRecommendation: const BillingCycleRecommendation(
        billingCycle: 'monthly',
        reason: 'Netflixは月額契約が中心です。',
        requiresUserConfirmation: true,
      ),
      reason: 'Netflixはプランごとの差が大きいため、標準候補から確認するのが分かりやすいです。',
      caution: '実際のプラン、料金、次回更新日はNetflixのアカウント画面で確認してください。',
    );
  }

  ServiceRecommendation _chatGpt(ServiceAiProfile profile) {
    final plan = _planByName(profile, 'Plus');
    return ServiceRecommendation(
      serviceId: profile.serviceId,
      planRecommendation: ServicePlanRecommendation(
        planName: plan.name,
        reason: '個人向け有料利用で代表的な候補です。',
        priceHint: plan.priceHint,
        requiresUserConfirmation: true,
      ),
      billingCycleRecommendation: const BillingCycleRecommendation(
        billingCycle: 'monthly',
        reason: '個人向け有料プランは月額管理されることが多い候補です。',
        requiresUserConfirmation: true,
      ),
      reason: 'ChatGPTはFree、Plus、Pro、Teamで管理方法が変わるため、代表候補を起点に確認します。',
      caution: 'Web契約、App Store、Google Play、Team契約のどれかを確認してください。',
    );
  }

  ServiceRecommendation _youtube(ServiceAiProfile profile) {
    final plan = _planByName(profile, 'YouTube Premium');
    return ServiceRecommendation(
      serviceId: profile.serviceId,
      planRecommendation: ServicePlanRecommendation(
        planName: plan.name,
        reason: 'YouTubeの有料利用で最も分かりやすい代表候補です。',
        priceHint: plan.priceHint,
        requiresUserConfirmation: true,
      ),
      billingCycleRecommendation: const BillingCycleRecommendation(
        billingCycle: 'monthly',
        reason: 'YouTubeの有料メンバーシップは月額候補として扱います。',
        requiresUserConfirmation: true,
      ),
      reason: 'YouTubeはPremium、Music、Family、メンバーシップがあるため、代表候補から確認します。',
      caution: 'Google、App Store、Google Playなど請求元によって料金と解約導線が変わります。',
    );
  }

  ServicePlanCandidate _planByName(
    ServiceAiProfile profile,
    String planName,
  ) {
    for (final plan in profile.planCandidates) {
      if (plan.name == planName) {
        return plan;
      }
    }
    return profile.planCandidates.first;
  }
}
