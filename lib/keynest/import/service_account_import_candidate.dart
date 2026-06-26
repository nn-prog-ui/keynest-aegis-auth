import '../service_ai_profile.dart';
import '../service_recommendation_engine.dart';
import 'import_item.dart';

class ServiceAccountImportCandidate {
  const ServiceAccountImportCandidate({
    required this.sourceItem,
    this.serviceId,
    this.profile,
    this.recommendation,
    this.confirmationLabels = const <String>[],
  });

  final ImportItem sourceItem;
  final String? serviceId;
  final ServiceAiProfile? profile;
  final ServiceRecommendation? recommendation;
  final List<String> confirmationLabels;

  bool get hasDetectedService {
    final detectedServiceId = serviceId;
    return detectedServiceId != null && detectedServiceId.isNotEmpty;
  }

  bool get hasRecommendation => recommendation != null;

  bool get requiresUserConfirmation => confirmationLabels.isNotEmpty;
}
