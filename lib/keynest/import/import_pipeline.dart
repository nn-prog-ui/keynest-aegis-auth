import '../gmail/gmail_import_service.dart';
import '../google/google_auth_service.dart';
import '../service_ai_profile.dart';
import '../service_recommendation_engine.dart';
import 'import_item.dart';
import 'import_repository.dart';
import 'import_source.dart';
import 'service_account_import_candidate.dart';
import 'service_detector.dart';

class ImportPipelineException implements Exception {
  const ImportPipelineException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'ImportPipelineException: $message';
}

class ImportPipeline {
  ImportPipeline({
    GoogleAuthService? googleAuthService,
    ImportRepository importRepository = const ImportRepository(),
    ServiceDetector serviceDetector = const ServiceDetector(),
    ServiceAiProfileRepository serviceAiProfileRepository =
        const ServiceAiProfileRepository(),
    ServiceRecommendationEngine recommendationEngine =
        const ServiceRecommendationEngine(),
  })  : _googleAuthService = googleAuthService ?? GoogleAuthService(),
        _importRepository = importRepository,
        _serviceDetector = serviceDetector,
        _serviceAiProfileRepository = serviceAiProfileRepository,
        _recommendationEngine = recommendationEngine;

  final GoogleAuthService _googleAuthService;
  final ImportRepository _importRepository;
  final ServiceDetector _serviceDetector;
  final ServiceAiProfileRepository _serviceAiProfileRepository;
  final ServiceRecommendationEngine _recommendationEngine;

  Future<List<ServiceAccountImportCandidate>> previewGmail({
    bool requireGoogleAccount = false,
  }) {
    return preview(
      source: ImportSource.gmail,
      requireGoogleAccount: requireGoogleAccount,
    );
  }

  Future<List<ServiceAccountImportCandidate>> preview({
    required ImportSource source,
    bool requireGoogleAccount = false,
  }) async {
    try {
      String? accessToken;
      if (source == ImportSource.gmail) {
        if (requireGoogleAccount) {
          final account = await _googleAuthService.currentAccount();
          if (account == null) {
            throw const ImportPipelineException('Googleアカウントが接続されていません。');
          }
        }
        accessToken = await _googleAuthService.getAccessToken();
        if (accessToken == null || accessToken.trim().isEmpty) {
          throw const ImportPipelineException(
            'Gmailの権限がまだ許可されていない可能性があります',
          );
        }
      }

      final items = await _parseImportItems(source, accessToken: accessToken);
      return items.map(_buildCandidate).toList(growable: false);
    } on ImportPipelineException {
      rethrow;
    } on GoogleAuthException catch (error) {
      throw ImportPipelineException(error.message, error);
    } on GmailImportException catch (error) {
      throw ImportPipelineException(error.message, error);
    } catch (error) {
      throw ImportPipelineException('インポート候補を作成できませんでした。', error);
    }
  }

  Future<List<ImportItem>> _parseImportItems(
    ImportSource source, {
    String? accessToken,
  }) {
    return _importRepository.preview(source, accessToken: accessToken);
  }

  ServiceAccountImportCandidate _buildCandidate(ImportItem item) {
    final serviceId = _serviceDetector.detectServiceId(item);
    final profile = serviceId == null
        ? null
        : _serviceAiProfileRepository.findByServiceId(serviceId);
    final recommendation =
        profile == null ? null : _recommendationEngine.recommend(profile);

    return ServiceAccountImportCandidate(
      sourceItem: item,
      serviceId: serviceId,
      profile: profile,
      recommendation: recommendation,
      confirmationLabels: _confirmationLabels(item, profile),
    );
  }

  List<String> _confirmationLabels(
    ImportItem item,
    ServiceAiProfile? profile,
  ) {
    final labels = <String>{
      if (item.serviceNameCandidate.isEmpty) 'サービス名',
      if (!item.hasAmountCandidate) '料金',
      if (item.billingCycleCandidate.isEmpty) '請求周期',
      if (!item.hasRenewalDateCandidate) '次回更新日',
      ...?profile?.userConfirmationItems.map((item) => item.label),
    };
    return labels.toList(growable: false);
  }
}
