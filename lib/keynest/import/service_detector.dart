import '../service_master.dart';
import 'import_item.dart';

class ServiceDetector {
  const ServiceDetector({
    ServiceMasterRepository serviceMasterRepository =
        const ServiceMasterRepository(),
  }) : _serviceMasterRepository = serviceMasterRepository;

  static const Set<String> _supportedServiceIds = {
    'amazon',
    'netflix',
    'chatgpt',
    'youtube',
  };

  final ServiceMasterRepository _serviceMasterRepository;

  String? detectServiceId(ImportItem item) {
    final service = detect(item);
    return service?.id;
  }

  ServiceMaster? detect(ImportItem item) {
    final searchableText = _normalizedSearchableText(item);
    if (searchableText.isEmpty) {
      return null;
    }

    for (final service in _serviceMasterRepository.all()) {
      if (!_supportedServiceIds.contains(service.id)) {
        continue;
      }
      if (_matchesService(searchableText, service)) {
        return service;
      }
    }
    return null;
  }

  bool _matchesService(String searchableText, ServiceMaster service) {
    final serviceTokens = <String>{
      service.id,
      service.name,
      service.loginUrl,
      ...service.domains,
      ..._aliasesFor(service.id),
    };

    return serviceTokens
        .map(_normalize)
        .where((token) => token.isNotEmpty)
        .any(searchableText.contains);
  }

  String _normalizedSearchableText(ImportItem item) {
    return _normalize(
      [
        item.serviceNameCandidate,
        item.rawTitle,
        item.rawSender,
      ].join(' '),
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  List<String> _aliasesFor(String serviceId) {
    switch (serviceId) {
      case 'amazon':
        return const [
          'amazon prime',
          'prime video',
          'kindle unlimited',
          'amazon music',
          'audible',
        ];
      case 'netflix':
        return const [
          'netflix',
          'mailer.netflix.com',
        ];
      case 'chatgpt':
        return const [
          'chatgpt',
          'openai',
          'chatgpt plus',
          'chatgpt pro',
          'chatgpt team',
        ];
      case 'youtube':
        return const [
          'youtube',
          'youtube premium',
          'youtube music',
          'paid memberships',
        ];
      default:
        return const <String>[];
    }
  }
}
