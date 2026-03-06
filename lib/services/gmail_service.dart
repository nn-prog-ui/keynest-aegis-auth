// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/email_attachment.dart';
import '../models/email_message.dart';
import 'mail_session_storage_stub.dart'
    if (dart.library.html) 'mail_session_storage_web.dart'
    as mail_session_storage;
import 'local_signature_storage_stub.dart'
    if (dart.library.html) 'local_signature_storage_web.dart'
    as local_signature_storage;
import 'contact_suggestion_storage_stub.dart'
    if (dart.library.html) 'contact_suggestion_storage_web.dart'
    as contact_suggestion_storage;
import 'oauth_popup_bridge_stub.dart'
    if (dart.library.html) 'oauth_popup_bridge_web.dart' as oauth_popup_bridge;

enum MailProvider { gmail, yahoo, outlook }

class GmailService extends ChangeNotifier {
  static final GmailService _instance = GmailService._internal();
  static final Set<String> _registeredEmails = <String>{};

  factory GmailService() => _instance;
  GmailService._internal() {
    _loadSignatureFromStorage();
    _loadKnownContactsFromStorage();
    _loadMailSessionFromStorage();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/gmail.modify',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _userEmail;
  String? _accessToken;
  int _unreadCount = 0;
  String _emailSignature = '';
  String _selectedSignatureId = 'none';
  final Set<String> _knownContacts = <String>{};
  static const int _maxKnownContacts = 400;
  static const Map<String, String> _signatureTemplates = <String, String>{
    'none': '',
    'business_standard':
        'いつも大変お世話になっております。\n\n何卒よろしくお願いいたします。\n\n根本憲武\nNoritake Nemoto',
    'business_brief': 'お世話になっております。\n\n以上、よろしくお願いいたします。\n\n根本憲武',
    'thanks': 'ご確認いただきありがとうございます。\n\n引き続きよろしくお願いいたします。\n\n根本憲武',
    'sales_polite':
        '平素よりお世話になっております。\n\nご不明点がございましたら、お気軽にお知らせください。\n\n何卒よろしくお願いいたします。\n\n根本憲武\nNoritake Nemoto',
    'proposal_followup':
        'お世話になっております。\n\n先日のご提案について、進捗をご共有いただけますと幸いです。\n\nご検討のほどよろしくお願いいたします。\n\n根本憲武',
    'english_business':
        'Thank you for your continued support.\n\nPlease let me know if you need any additional information.\n\nBest regards,\nNoritake Nemoto',
    'custom': '',
  };
  MailProvider _provider = MailProvider.gmail;
  String _mailAuthMode = 'password';
  String? _mailAccountId;
  String? _mailSessionToken;
  static const String _mailBridgeBaseUrl = String.fromEnvironment(
    'MAIL_BRIDGE_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  final Map<String, List<EmailMessage>> _emailCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 10);

  String? _lastError;
  String? get lastError => _lastError;

  bool isSignedIn() {
    if (_useMailBridge) {
      return _mailSessionToken != null && (_userEmail?.isNotEmpty ?? false);
    }
    return _currentUser != null;
  }

  String? getUserEmail() => _userEmail;
  String? get mailSessionToken => _mailSessionToken;
  String get mailProviderId => _providerId(_provider);
  String get mailAuthMode => _mailAuthMode;
  String normalizeDisplayText(String value) => _decodeHeaderValue(value);

  Map<String, String> getSignatureTemplates() {
    final templates = Map<String, String>.from(_signatureTemplates);
    templates['custom'] = _emailSignature.trim();
    return templates;
  }

  List<MapEntry<String, String>> getSignatureTemplateOptions() {
    const order = <String>[
      'none',
      'business_standard',
      'business_brief',
      'thanks',
      'sales_polite',
      'proposal_followup',
      'english_business',
      'custom',
    ];
    const labels = <String, String>{
      'none': 'なし',
      'business_standard': 'ビジネス標準',
      'business_brief': 'ビジネス簡潔',
      'thanks': 'お礼・返信用',
      'sales_polite': '営業・丁寧文',
      'proposal_followup': '提案フォローアップ',
      'english_business': 'English Business',
      'custom': 'カスタム',
    };
    final templates = getSignatureTemplates();
    return order
        .map((id) => MapEntry<String, String>(id, labels[id] ?? id))
        .where((entry) => templates.containsKey(entry.key))
        .toList();
  }

  String getSignatureTemplateLabel(String templateId) {
    final option = getSignatureTemplateOptions().firstWhere(
      (entry) => entry.key == templateId,
      orElse: () => const MapEntry<String, String>('custom', 'カスタム'),
    );
    return option.value;
  }

  String get selectedSignatureId => _selectedSignatureId;

  String _resolveSignatureText() {
    if (_selectedSignatureId == 'custom') {
      return _emailSignature.trim();
    }
    return (_signatureTemplates[_selectedSignatureId] ?? '').trim();
  }

  String getEmailSignature({bool withFallback = true}) {
    final resolved = _resolveSignatureText();
    if (resolved.isNotEmpty) {
      return resolved;
    }
    if (_selectedSignatureId == 'none') {
      return '';
    }
    if (!withFallback) {
      return '';
    }
    final email = (_userEmail ?? '').trim();
    if (email.isEmpty) {
      return '';
    }
    return '--\n$email';
  }

  void setEmailSignature(String signature) {
    _emailSignature = signature.trim();
    _selectedSignatureId = 'custom';
    _persistSignatureSettings();
    notifyListeners();
  }

  void setSelectedSignatureTemplate(String templateId) {
    if (!_signatureTemplates.containsKey(templateId)) {
      return;
    }
    _selectedSignatureId = templateId;
    _persistSignatureSettings();
    notifyListeners();
  }

  void _persistSignatureSettings() {
    final payload = jsonEncode(<String, String>{
      'selected': _selectedSignatureId,
      'custom': _emailSignature.trim(),
    });
    local_signature_storage.writeSignature(payload);
  }

  void _loadSignatureFromStorage() {
    final saved = local_signature_storage.readSignature();
    if (saved == null || saved.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(saved);
      if (decoded is Map<String, dynamic>) {
        final custom = (decoded['custom'] as String?)?.trim() ?? '';
        final selected = (decoded['selected'] as String?)?.trim() ?? '';
        _emailSignature = custom;
        _selectedSignatureId =
            _signatureTemplates.containsKey(selected) ? selected : 'custom';
        return;
      }
    } catch (_) {
      // Backward compatibility: old plain signature text
    }
    _emailSignature = saved.trim();
    _selectedSignatureId = 'custom';
  }

  void _loadKnownContactsFromStorage() {
    final raw = contact_suggestion_storage.readKnownContactsJson();
    if (raw == null || raw.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is String) {
            _rememberContact(item, persist: false);
          }
        }
      }
    } catch (_) {}
  }

  void _persistKnownContacts() {
    contact_suggestion_storage
        .writeKnownContactsJson(jsonEncode(_knownContacts.toList()));
  }

  void _rememberContact(String raw, {bool persist = true}) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return;
    }
    _knownContacts.remove(normalized);
    _knownContacts.add(normalized);
    if (_knownContacts.length > _maxKnownContacts) {
      final overflow = _knownContacts.length - _maxKnownContacts;
      final toDrop = _knownContacts.take(overflow).toList();
      for (final item in toDrop) {
        _knownContacts.remove(item);
      }
    }
    if (persist) {
      _persistKnownContacts();
    }
  }

  Iterable<String> _extractAddresses(String raw) sync* {
    final matches = RegExp(
      r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).allMatches(raw);
    for (final match in matches) {
      final value = match.group(0);
      if (value != null && value.isNotEmpty) {
        yield value;
      }
    }
  }

  void _rememberContactsFromText(String raw) {
    for (final address in _extractAddresses(raw)) {
      _rememberContact(address, persist: false);
    }
  }

  void _rememberContactsFromEmail(EmailMessage email) {
    _rememberContactsFromText(email.from);
    _rememberContactsFromText(email.to);
    _rememberContactsFromText(email.cc);
    _persistKnownContacts();
  }

  List<String> getRecipientSuggestions({
    required String query,
    int limit = 10,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final candidates = <String>{..._knownContacts};
    for (final account in getRegisteredEmails()) {
      candidates.add(account.toLowerCase());
    }
    if (normalizedQuery.isEmpty) {
      return candidates.take(limit).toList();
    }
    final ranked = candidates.where((value) {
      return value.contains(normalizedQuery);
    }).toList();
    ranked.sort((a, b) {
      final aStarts = a.startsWith(normalizedQuery) ? 0 : 1;
      final bStarts = b.startsWith(normalizedQuery) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.compareTo(b);
    });
    return ranked.take(limit).toList();
  }

  void rememberRecipientCandidates(String raw) {
    _rememberContactsFromText(raw);
    _persistKnownContacts();
  }

  List<String> getRegisteredEmails() {
    final set = <String>{..._registeredEmails};
    final current = _normalizeEmail(_userEmail ?? '');
    if (current.isNotEmpty) {
      set.add(current);
    }
    final emails = set.toList()..sort();
    return emails;
  }

  int get unreadCount => _unreadCount;
  String get unreadCountDisplay =>
      _unreadCount >= 100 ? '99+' : _unreadCount.toString();
  MailProvider get provider => _provider;
  String get providerLabel {
    switch (_provider) {
      case MailProvider.gmail:
        return 'Gmail';
      case MailProvider.yahoo:
        return 'Yahoo';
      case MailProvider.outlook:
        return 'Outlook';
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
  bool get _useMailBridge => _mailSessionToken != null;

  MailProvider _providerFromId(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'yahoo':
        return MailProvider.yahoo;
      case 'outlook':
        return MailProvider.outlook;
      case 'gmail':
      default:
        return MailProvider.gmail;
    }
  }

  void _loadMailSessionFromStorage() {
    final raw = mail_session_storage.readMailSessionJson();
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return;
      final token = (data['token'] as String?)?.trim() ?? '';
      final email = (data['email'] as String?)?.trim() ?? '';
      final provider = (data['provider'] as String?)?.trim() ?? 'gmail';
      final authMode = (data['authMode'] as String?)?.trim() ?? 'password';
      final accountId = (data['accountId'] as String?)?.trim() ?? '';
      final hasRestorableOAuthIdentity =
          authMode == 'oauth' && (accountId.isNotEmpty || email.isNotEmpty);
      final hasValidSessionIdentity = token.isNotEmpty && email.isNotEmpty;

      if (!hasValidSessionIdentity && !hasRestorableOAuthIdentity) {
        return;
      }

      _mailSessionToken = token.isEmpty ? null : token;
      _userEmail = email.isEmpty ? null : email;
      _provider = _providerFromId(provider);
      _mailAuthMode = authMode == 'oauth' ? 'oauth' : 'password';
      _mailAccountId = accountId.isEmpty ? null : accountId;
      _rememberEmail(_userEmail);
    } catch (_) {
      _clearPersistedMailSession();
    }
  }

  void _persistMailSession() {
    final token = _mailSessionToken?.trim() ?? '';
    final email = _userEmail?.trim() ?? '';
    final accountId = _mailAccountId?.trim() ?? '';
    final keepOAuthIdentity =
        _mailAuthMode == 'oauth' && (accountId.isNotEmpty || email.isNotEmpty);

    if (token.isEmpty && !keepOAuthIdentity) {
      _clearPersistedMailSession();
      return;
    }
    if (email.isEmpty && !keepOAuthIdentity) {
      _clearPersistedMailSession();
      return;
    }

    mail_session_storage.writeMailSessionJson(
      jsonEncode({
        'token': token,
        'email': email,
        'provider': _providerId(_provider),
        'authMode': _mailAuthMode,
        'accountId': accountId,
      }),
    );
  }

  void _clearPersistedMailSession() {
    mail_session_storage.writeMailSessionJson('');
  }

  bool get _hasRestorableOAuthIdentity {
    final accountId = _mailAccountId?.trim() ?? '';
    final email = _userEmail?.trim() ?? '';
    return _mailAuthMode == 'oauth' &&
        (_providerId(_provider).isNotEmpty) &&
        (accountId.isNotEmpty || email.isNotEmpty);
  }

  void _invalidateSession({bool keepOAuthIdentity = true}) {
    _mailSessionToken = null;
    if (keepOAuthIdentity && _hasRestorableOAuthIdentity) {
      _persistMailSession();
      return;
    }
    _mailAuthMode = 'password';
    _mailAccountId = null;
    _clearPersistedMailSession();
  }

  void _rememberEmail(String? email) {
    final normalized = _normalizeEmail(email ?? '');
    if (normalized.isNotEmpty) {
      _registeredEmails.add(normalized);
    }
  }

  void clearCache() {
    _emailCache.clear();
    _cacheTimestamps.clear();
    print('🗑️ キャッシュをクリアしました');
  }

  Future<bool> signIn({
    MailProvider provider = MailProvider.gmail,
    String? email,
    String? password,
    bool useOAuthForGmail = false,
  }) async {
    if (provider != MailProvider.gmail || !useOAuthForGmail) {
      return _signInViaMailBridge(
        provider: provider,
        email: email,
        password: password,
      );
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _provider = MailProvider.gmail;
        _mailAuthMode = 'password';
        _mailAccountId = null;
        _mailSessionToken = null;
        _clearPersistedMailSession();
        _currentUser = account;
        _userEmail = account.email;
        _rememberEmail(_userEmail);
        await _updateUnreadCount();
        notifyListeners();
        print('✅ ログイン成功: $_userEmail');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ ログインエラー: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    if (_useMailBridge) {
      await _postMailBridge('/api/mail/logout', {});
    } else {
      await _googleSignIn.signOut();
    }
    _currentUser = null;
    _userEmail = null;
    _accessToken = null;
    _mailSessionToken = null;
    _mailAuthMode = 'password';
    _mailAccountId = null;
    _clearPersistedMailSession();
    _provider = MailProvider.gmail;
    _unreadCount = 0;
    clearCache();
    notifyListeners();
    print('✅ ログアウトしました');
  }

  Future<String?> _getAccessToken({bool forceRefresh = false}) async {
    if (_currentUser == null) return null;

    try {
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;

      if (_accessToken == null && forceRefresh) {
        print('🔄 アクセストークンを強制リフレッシュ');
        await _currentUser!.clearAuthCache();
        final newAuth = await _currentUser!.authentication;
        _accessToken = newAuth.accessToken;
      }

      return _accessToken;
    } catch (e) {
      print('❌ アクセストークン取得エラー: $e');
      return null;
    }
  }

  Future<http.Response?> _retryWithBackoff(
    Future<http.Response> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retries = 0;
    Duration delay = initialDelay;

    while (retries < maxRetries) {
      try {
        final response = await request();

        if (response.statusCode == 200) {
          _lastError = null;
          return response;
        }

        if (response.statusCode == 403) {
          print('⚠️ 403エラー（リトライ ${retries + 1}/$maxRetries）');

          if (retries < maxRetries - 1) {
            print('🔄 アクセストークンをリフレッシュして再試行');
            await _getAccessToken(forceRefresh: true);
            await Future.delayed(delay);
            delay *= 2;
            retries++;
            continue;
          } else {
            _lastError = 'APIのレート制限に達しました。しばらく待ってから再度お試しください。';
            print('❌ $_lastError');
            notifyListeners();
            return response;
          }
        }

        if (response.statusCode == 429) {
          print('⚠️ レート制限（リトライ ${retries + 1}/$maxRetries）');

          if (retries < maxRetries - 1) {
            await Future.delayed(delay);
            delay *= 2;
            retries++;
            continue;
          } else {
            _lastError = 'APIのレート制限に達しました。しばらく待ってから再度お試しください。';
            print('❌ $_lastError');
            notifyListeners();
            return response;
          }
        }

        _lastError = 'メールの取得に失敗しました（エラーコード: ${response.statusCode}）';
        print('❌ $_lastError');
        notifyListeners();
        return response;
      } catch (e) {
        print('❌ リクエストエラー（リトライ ${retries + 1}/$maxRetries）: $e');

        if (retries < maxRetries - 1) {
          await Future.delayed(delay);
          delay *= 2;
          retries++;
          continue;
        } else {
          _lastError = 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
          print('❌ $_lastError');
          notifyListeners();
          return null;
        }
      }
    }

    return null;
  }

  Future<void> _updateUnreadCount() async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      return;
    }

    if (_useMailBridge) {
      final response = await _postMailBridge('/api/mail/unread', {});
      if (response == null) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
        notifyListeners();
      }
      return;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      return;
    }

    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?labelIds=INBOX&labelIds=UNREAD&maxResults=50',
      );

      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));

      if (response?.statusCode == 200) {
        final data = json.decode(response!.body);
        final messages = data['messages'] as List?;
        _unreadCount = messages?.length ?? 0;
        print('📬 未読件数を更新: $_unreadCount 件');
        notifyListeners();
      } else {
        print('❌ 未読件数の取得に失敗: ${response?.statusCode}');
      }
    } catch (e) {
      print('❌ 未読件数の更新エラー: $e');
    }
  }

  Future<List<EmailMessage>> fetchEmails(
      {int maxResults = 50, bool forceRefresh = false}) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      _lastError = 'ログインしていません';
      notifyListeners();
      return [];
    }

    if (_useMailBridge) {
      return _fetchEmailsViaMailBridge(
        mailbox: 'inbox',
        maxResults: maxResults,
        forceRefresh: forceRefresh,
      );
    }

    final cacheKey = 'inbox_$maxResults';
    if (!forceRefresh && _emailCache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiration) {
        print('📦 キャッシュから受信メールを取得: ${_emailCache[cacheKey]!.length} 件');
        return _emailCache[cacheKey]!;
      }
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      _lastError = 'アクセストークンが取得できませんでした';
      notifyListeners();
      return [];
    }

    try {
      print('📬 受信メールを取得開始: $maxResults 件');

      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?labelIds=INBOX&maxResults=$maxResults',
      );

      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));

      if (response == null || response.statusCode != 200) {
        print('❌ メール取得失敗: ${response?.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final messages = data['messages'] as List?;

      if (messages == null || messages.isEmpty) {
        print('📬 受信メール: 0 件');
        return [];
      }

      print('📬 受信メール: ${messages.length} 件');

      final emails = <EmailMessage>[];
      const batchSize = 20;

      for (var i = 0; i < messages.length; i += batchSize) {
        final end =
            (i + batchSize < messages.length) ? i + batchSize : messages.length;
        final batch = messages.sublist(i, end);

        final futures = batch
            .map((msg) => _fetchEmailMetadataWithRetry(msg['id'], accessToken))
            .toList();
        final batchResults = await Future.wait(futures);
        emails.addAll(batchResults.whereType<EmailMessage>());

        print(
            '📬 バッチ ${i + 1}-$end 完了: ${batchResults.whereType<EmailMessage>().length} 件');
      }

      print('✅ 受信メール取得完了: ${emails.length} 件');

      _emailCache[cacheKey] = emails;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return emails;
    } catch (e) {
      print('❌ メール取得エラー: $e');
      _lastError = 'メールの取得中にエラーが発生しました';
      notifyListeners();
      return [];
    }
  }

  Future<EmailMessage?> _fetchEmailMetadataWithRetry(
      String messageId, String accessToken,
      {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      final result = await _fetchEmailMetadata(messageId, accessToken);
      if (result != null) return result;

      if (i < retries) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return null;
  }

  Future<EmailMessage?> _fetchEmailMetadata(
      String messageId, String accessToken) async {
    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId?format=metadata&metadataHeaders=From&metadataHeaders=To&metadataHeaders=Cc&metadataHeaders=Subject&metadataHeaders=Date',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final headers = data['payload']['headers'] as List;
      final snippet = data['snippet'] ?? '';
      final labelIds = List<String>.from(data['labelIds'] ?? []);

      String from = '';
      String to = '';
      String cc = '';
      String subject = '';
      DateTime date = DateTime.now();

      for (var header in headers) {
        final name = header['name'];
        final value = header['value'];

        if (name == 'From') {
          from = _decodeHeaderValue(value);
        } else if (name == 'To') {
          to = _decodeHeaderValue(value);
        } else if (name == 'Cc') {
          cc = _decodeHeaderValue(value);
        } else if (name == 'Subject') {
          subject = _decodeHeaderValue(value);
        } else if (name == 'Date') {
          date = _parseDate(value);
        }
      }

      final isUnread = labelIds.contains('UNREAD');

      final email = EmailMessage(
        id: messageId,
        from: from,
        to: to,
        cc: cc,
        subject: subject.isEmpty ? '(件名なし)' : subject,
        body: '',
        date: date,
        isUnread: isUnread,
        snippet: snippet,
      );
      _rememberContactsFromEmail(email);
      return email;
    } catch (e) {
      return null;
    }
  }

  Future<List<EmailMessage>> fetchSentEmails(
      {int maxResults = 50, bool forceRefresh = false}) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      _lastError = 'ログインしていません';
      notifyListeners();
      return [];
    }

    if (_useMailBridge) {
      return _fetchEmailsViaMailBridge(
        mailbox: 'sent',
        maxResults: maxResults,
        forceRefresh: forceRefresh,
      );
    }

    final cacheKey = 'sent_$maxResults';
    if (!forceRefresh && _emailCache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiration) {
        print('📦 キャッシュから送信済みメールを取得: ${_emailCache[cacheKey]!.length} 件');
        return _emailCache[cacheKey]!;
      }
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      _lastError = 'アクセストークンが取得できませんでした';
      notifyListeners();
      return [];
    }

    try {
      print('📤 送信済みメールを取得開始: $maxResults 件');

      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?labelIds=SENT&maxResults=$maxResults',
      );

      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));

      if (response == null || response.statusCode != 200) {
        print('❌ 送信済みメール取得失敗: ${response?.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final messages = data['messages'] as List?;

      if (messages == null || messages.isEmpty) {
        print('📤 送信済みメール: 0 件');
        return [];
      }

      print('📤 送信済みメール: ${messages.length} 件');

      final emails = <EmailMessage>[];
      const batchSize = 20;

      for (var i = 0; i < messages.length; i += batchSize) {
        final end =
            (i + batchSize < messages.length) ? i + batchSize : messages.length;
        final batch = messages.sublist(i, end);

        final futures = batch
            .map((msg) =>
                _fetchSentEmailMetadataWithRetry(msg['id'], accessToken))
            .toList();
        final batchResults = await Future.wait(futures);
        emails.addAll(batchResults.whereType<EmailMessage>());

        print(
            '📤 バッチ ${i + 1}-$end 完了: ${batchResults.whereType<EmailMessage>().length} 件');
      }

      final filteredEmails = emails.where((email) {
        return email.from.contains(_userEmail ?? '');
      }).toList();

      print('✅ 送信済みメール取得完了: ${filteredEmails.length} 件');

      _emailCache[cacheKey] = filteredEmails;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return filteredEmails;
    } catch (e) {
      print('❌ 送信済みメール取得エラー: $e');
      _lastError = '送信済みメールの取得中にエラーが発生しました';
      notifyListeners();
      return [];
    }
  }

  Future<List<EmailMessage>> fetchTrashEmails(
      {int maxResults = 50, bool forceRefresh = false}) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      _lastError = 'ログインしていません';
      notifyListeners();
      return [];
    }

    if (_useMailBridge) {
      return _fetchEmailsViaMailBridge(
        mailbox: 'trash',
        maxResults: maxResults,
        forceRefresh: forceRefresh,
      );
    }

    final cacheKey = 'trash_$maxResults';
    if (!forceRefresh && _emailCache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiration) {
        return _emailCache[cacheKey]!;
      }
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      _lastError = 'アクセストークンが取得できませんでした';
      notifyListeners();
      return [];
    }

    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?labelIds=TRASH&maxResults=$maxResults',
      );

      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));

      if (response == null || response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      final messages = data['messages'] as List?;
      if (messages == null || messages.isEmpty) {
        return [];
      }

      final emails = <EmailMessage>[];
      const batchSize = 20;
      for (var i = 0; i < messages.length; i += batchSize) {
        final end =
            (i + batchSize < messages.length) ? i + batchSize : messages.length;
        final batch = messages.sublist(i, end);
        final futures = batch
            .map((msg) => _fetchEmailMetadataWithRetry(msg['id'], accessToken))
            .toList();
        final batchResults = await Future.wait(futures);
        emails.addAll(batchResults.whereType<EmailMessage>());
      }

      _emailCache[cacheKey] = emails;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return emails;
    } catch (e) {
      _lastError = 'ゴミ箱メールの取得に失敗しました';
      notifyListeners();
      return [];
    }
  }

  Future<EmailMessage?> _fetchSentEmailMetadataWithRetry(
      String messageId, String accessToken,
      {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      final result = await _fetchSentEmailMetadata(messageId, accessToken);
      if (result != null) return result;

      if (i < retries) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return null;
  }

  Future<EmailMessage?> _fetchSentEmailMetadata(
      String messageId, String accessToken) async {
    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId?format=metadata&metadataHeaders=From&metadataHeaders=To&metadataHeaders=Cc&metadataHeaders=Subject&metadataHeaders=Date',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final headers = data['payload']['headers'] as List;
      final snippet = data['snippet'] ?? '';

      String from = '';
      String to = '';
      String cc = '';
      String subject = '';
      DateTime date = DateTime.now();

      for (var header in headers) {
        final name = header['name'];
        final value = header['value'];

        if (name == 'From') {
          from = _decodeHeaderValue(value);
        } else if (name == 'To') {
          to = _decodeHeaderValue(value);
        } else if (name == 'Cc') {
          cc = _decodeHeaderValue(value);
        } else if (name == 'Subject') {
          subject = _decodeHeaderValue(value);
        } else if (name == 'Date') {
          date = _parseDate(value);
        }
      }

      final email = EmailMessage(
        id: messageId,
        from: from,
        to: to,
        cc: cc,
        subject: subject.isEmpty ? '(件名なし)' : subject,
        body: '',
        date: date,
        isUnread: false,
        snippet: snippet,
      );
      _rememberContactsFromEmail(email);
      return email;
    } catch (e) {
      return null;
    }
  }

  Future<String> fetchEmailBody(String messageId) async {
    final bodyParts = await fetchEmailBodyParts(messageId);
    final preferred = bodyParts['preferred'] ?? '';
    return preferred.isEmpty ? '本文がありません' : preferred;
  }

  Future<Map<String, String>> fetchEmailBodyParts(String messageId) async {
    if (!isSignedIn()) {
      return {
        'plain': '',
        'html': '',
        'preferred': 'ログインしていません',
      };
    }

    if (_useMailBridge) {
      final response = await _postMailBridge('/api/mail/body', {
        'id': messageId,
      });
      if (response == null) {
        return {
          'plain': '',
          'html': '',
          'preferred': '本文の取得エラー: サーバーに接続できませんでした',
        };
      }
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final preferred = (data['preferred'] as String?)?.trim() ??
            (data['body'] as String?)?.trim() ??
            '';
        final plain = (data['plain'] as String?)?.trim() ??
            (_looksLikeHtml(preferred) ? '' : preferred);
        final html = (data['html'] as String?)?.trim() ??
            (_looksLikeHtml(preferred) ? preferred : '');
        return {
          'plain': plain,
          'html': html,
          'preferred': preferred,
        };
      }

      final sentResponse = await _postMailBridge('/api/mail/body', {
        'id': messageId,
        'mailbox': 'sent',
      });
      if (sentResponse?.statusCode == 200) {
        final data = json.decode(sentResponse!.body) as Map<String, dynamic>;
        final preferred = (data['preferred'] as String?)?.trim() ??
            (data['body'] as String?)?.trim() ??
            '';
        final plain = (data['plain'] as String?)?.trim() ??
            (_looksLikeHtml(preferred) ? '' : preferred);
        final html = (data['html'] as String?)?.trim() ??
            (_looksLikeHtml(preferred) ? preferred : '');
        return {
          'plain': plain,
          'html': html,
          'preferred': preferred,
        };
      }
      return {
        'plain': '',
        'html': '',
        'preferred': '本文の取得に失敗しました',
      };
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      return {
        'plain': '',
        'html': '',
        'preferred': 'アクセストークンが取得できませんでした',
      };
    }

    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId?format=full',
      );

      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));

      if (response?.statusCode == 200) {
        final data = json.decode(response!.body);
        final payload = data['payload'];
        final plainBody = await _extractBodyByMimeType(
          payload,
          'text/plain',
          messageId: messageId,
          accessToken: accessToken,
        );
        final htmlBody = await _extractBodyByMimeType(
          payload,
          'text/html',
          messageId: messageId,
          accessToken: accessToken,
        );
        final preferred = _choosePreferredBody(plainBody, htmlBody, payload);
        return {
          'plain': plainBody,
          'html': htmlBody,
          'preferred': preferred,
        };
      } else {
        return {
          'plain': '',
          'html': '',
          'preferred': '本文の取得に失敗しました',
        };
      }
    } catch (e) {
      return {
        'plain': '',
        'html': '',
        'preferred': '本文の取得エラー: $e',
      };
    }
  }

  String _choosePreferredBody(
    String plainBody,
    String htmlBody,
    Map<String, dynamic> payload,
  ) {
    final plainHasStyleNoise = _looksLikeStyleNoise(plainBody);

    if (plainBody.isNotEmpty && htmlBody.isNotEmpty) {
      final plainLooksCollapsed =
          !plainBody.contains('\n') && plainBody.length > 700;
      final htmlLooksStructured = htmlBody.contains('<p') ||
          htmlBody.contains('<div') ||
          htmlBody.contains('<table');
      if ((plainLooksCollapsed || plainHasStyleNoise) && htmlLooksStructured) {
        return htmlBody;
      }
      return plainBody;
    }

    if (plainBody.isNotEmpty) {
      return plainBody;
    }

    if (htmlBody.isNotEmpty) {
      return htmlBody;
    }

    if (payload['body'] != null && payload['body']['data'] != null) {
      return _decodeBase64(payload['body']['data']);
    }

    return '';
  }

  bool _looksLikeHtml(String text) {
    return RegExp(r'<[a-zA-Z][^>]*>').hasMatch(text);
  }

  bool _looksLikeStyleNoise(String text) {
    if (text.isEmpty) {
      return false;
    }

    final keywordCount = RegExp(
      r'(font-family|background-color|color-scheme|text-decoration|box-sizing|min-width|max-width|@media|table table)',
      caseSensitive: false,
    ).allMatches(text).length;
    final punctuationCount = RegExp(r'[;{}]').allMatches(text).length;
    return keywordCount >= 3 || punctuationCount >= 24;
  }

  Future<String> _extractBodyByMimeType(
    Map<String, dynamic> part,
    String mimeType, {
    required String messageId,
    required String accessToken,
  }) async {
    if (part['mimeType'] == mimeType) {
      final body = part['body'];
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is String && data.isNotEmpty) {
          return _decodeBase64(data);
        }

        final attachmentId = body['attachmentId'];
        if (attachmentId is String && attachmentId.isNotEmpty) {
          return _fetchAttachmentBody(
            messageId: messageId,
            attachmentId: attachmentId,
            accessToken: accessToken,
          );
        }
      }
    }

    final children = part['parts'];
    if (children is List) {
      for (final child in children) {
        if (child is! Map) {
          continue;
        }

        final nested = await _extractBodyByMimeType(
          Map<String, dynamic>.from(child),
          mimeType,
          messageId: messageId,
          accessToken: accessToken,
        );
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return '';
  }

  Future<String> _fetchAttachmentBody({
    required String messageId,
    required String attachmentId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId/attachments/$attachmentId',
      );
      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));
      if (response?.statusCode != 200) {
        return '';
      }
      final data = json.decode(response!.body);
      final encoded = data['data'];
      if (encoded is String && encoded.isNotEmpty) {
        return _decodeBase64(encoded);
      }
    } catch (_) {}
    return '';
  }

  String _decodeBase64(String encoded) {
    try {
      final normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
      final padding = normalized.length % 4;
      final padded =
          padding > 0 ? normalized + ('=' * (4 - padding)) : normalized;
      return _repairMojibake(utf8.decode(base64.decode(padded)));
    } catch (e) {
      print('❌ Base64デコードエラー: $e');
      return '';
    }
  }

  String _decodeHeaderValue(dynamic rawValue) {
    final value = (rawValue ?? '').toString();
    if (value.trim().isEmpty) return '';
    final decodedEncodedWords = _decodeMimeEncodedWords(value);
    return _repairMojibake(decodedEncodedWords).trim();
  }

  String _decodeMimeEncodedWords(String value) {
    final encodedWordPattern = RegExp(r'=\?([^?]+)\?([bBqQ])\?([^?]*)\?=');
    if (!encodedWordPattern.hasMatch(value)) {
      return value;
    }
    return value.replaceAllMapped(encodedWordPattern, (match) {
      final charset = (match.group(1) ?? 'utf-8').toLowerCase();
      final encoding = (match.group(2) ?? 'b').toLowerCase();
      final payload = match.group(3) ?? '';
      final bytes = encoding == 'b'
          ? _decodeHeaderBase64(payload)
          : _decodeHeaderQuotedPrintable(payload);
      if (bytes == null) {
        return match.group(0) ?? '';
      }
      return _decodeBytesByCharset(bytes, charset);
    });
  }

  List<int>? _decodeHeaderBase64(String payload) {
    try {
      final normalized = payload.replaceAll('_', '/').replaceAll('-', '+');
      final padding = normalized.length % 4;
      final padded =
          padding == 0 ? normalized : '$normalized${'=' * (4 - padding)}';
      return base64.decode(padded);
    } catch (_) {
      return null;
    }
  }

  List<int>? _decodeHeaderQuotedPrintable(String payload) {
    final bytes = <int>[];
    final normalized = payload.replaceAll('_', ' ');
    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      if (char == '=' && i + 2 < normalized.length) {
        final hex = normalized.substring(i + 1, i + 3);
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) {
          bytes.add(parsed);
          i += 2;
          continue;
        }
      }
      bytes.add(char.codeUnitAt(0));
    }
    return bytes;
  }

  String _decodeBytesByCharset(List<int> bytes, String charset) {
    try {
      if (charset.contains('utf-8') || charset.contains('utf8')) {
        return utf8.decode(bytes, allowMalformed: true);
      }
      if (charset.contains('iso-8859-1') ||
          charset.contains('latin1') ||
          charset.contains('windows-1252') ||
          charset.contains('us-ascii') ||
          charset.contains('ascii')) {
        return latin1.decode(bytes, allowInvalid: true);
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  String _repairMojibake(String input) {
    if (input.isEmpty) return input;
    final trimmed = input.trim();
    final suspicious = RegExp(r'[ÃÂâ€™â€œâ€â€¢�]');
    if (!suspicious.hasMatch(trimmed)) {
      return trimmed;
    }
    try {
      final repaired =
          utf8.decode(latin1.encode(trimmed), allowMalformed: true);
      return _isBetterDecodedCandidate(original: trimmed, candidate: repaired)
          ? repaired
          : trimmed;
    } catch (_) {
      return trimmed;
    }
  }

  bool _isBetterDecodedCandidate({
    required String original,
    required String candidate,
  }) {
    int score(String value) {
      var s = 0;
      s += RegExp(r'�').allMatches(value).length * 4;
      s += RegExp(r'[ÃÂâ€™â€œâ€â€¢]').allMatches(value).length * 2;
      return s;
    }

    return score(candidate) < score(original);
  }

  DateTime _parseDate(String dateString) {
    final timezoneMap = <String, String>{
      'UTC': '+0000',
      'GMT': '+0000',
      'JST': '+0900',
      'PST': '-0800',
      'PDT': '-0700',
      'MST': '-0700',
      'MDT': '-0600',
      'CST': '-0600',
      'CDT': '-0500',
      'EST': '-0500',
      'EDT': '-0400',
    };

    var normalized = dateString
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final tzMatch = RegExp(r' ([A-Z]{2,5})$').firstMatch(normalized);
    if (tzMatch != null) {
      final abbr = tzMatch.group(1)!;
      final offset = timezoneMap[abbr];
      if (offset != null) {
        normalized =
            normalized.replaceFirst(RegExp(r' [A-Z]{2,5}$'), ' $offset');
      }
    }

    const formats = <String>[
      'EEE, dd MMM yyyy HH:mm:ss Z',
      'EEE, d MMM yyyy HH:mm:ss Z',
      'EEE, dd MMM yyyy HH:mm Z',
      'EEE, d MMM yyyy HH:mm Z',
      'dd MMM yyyy HH:mm:ss Z',
      'd MMM yyyy HH:mm:ss Z',
      'dd MMM yyyy HH:mm Z',
      'd MMM yyyy HH:mm Z',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format, 'en_US').parse(normalized);
      } catch (_) {}
    }

    return DateTime.tryParse(normalized) ?? DateTime.now();
  }

  Future<void> markAsRead(String messageId) async {
    if (!isSignedIn()) return;

    if (_useMailBridge) {
      await _postMailBridge('/api/mail/read', {
        'id': messageId,
        'unread': false,
      });
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      clearCache();
      notifyListeners();
      return;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) return;

    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId/modify',
      );

      final response = await _retryWithBackoff(() => http.post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'removeLabelIds': ['UNREAD'],
            }),
          ));

      if (response?.statusCode == 200) {
        print('✅ メールを既読にしました: $messageId');
        if (_unreadCount > 0) {
          _unreadCount--;
          print('📬 未読件数を更新: $_unreadCount 件');
          clearCache();
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ 既読化エラー: $e');
    }
  }

  Future<void> markAsUnread(String messageId) async {
    if (!isSignedIn()) return;

    if (_useMailBridge) {
      await _postMailBridge('/api/mail/read', {
        'id': messageId,
        'unread': true,
      });
      _unreadCount++;
      clearCache();
      notifyListeners();
      return;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) return;

    try {
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId/modify',
      );

      final response = await _retryWithBackoff(() => http.post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'addLabelIds': ['UNREAD'],
            }),
          ));

      if (response?.statusCode == 200) {
        print('✅ メールを未読にしました: $messageId');
        _unreadCount++;
        print('📬 未読件数を更新: $_unreadCount 件');
        clearCache();
        notifyListeners();
      }
    } catch (e) {
      print('❌ 未読化エラー: $e');
    }
  }

  Future<bool> moveToTrash(String messageId) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      return false;
    }

    if (_useMailBridge) {
      final response = await _postMailBridge('/api/mail/trash', {
        'id': messageId,
      });
      if (response?.statusCode == 200) {
        clearCache();
        notifyListeners();
        return true;
      }
      return false;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      return false;
    }

    try {
      print('🗑️ メールをゴミ箱に移動開始: $messageId');

      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId/trash',
      );

      final response = await _retryWithBackoff(() => http.post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          ));

      if (response?.statusCode == 200) {
        print('✅ メールをゴミ箱に移動しました: $messageId');
        clearCache();
        notifyListeners();
        return true;
      } else {
        print('❌ ゴミ箱への移動に失敗: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ ゴミ箱への移動エラー: $e');
      return false;
    }
  }

  Future<List<EmailMessage>> searchEmails(String query) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      _lastError = 'ログインしていません';
      notifyListeners();
      return [];
    }

    if (query.trim().isEmpty) {
      print('🔍 検索クエリが空です');
      return [];
    }

    if (_useMailBridge) {
      return _searchEmailsViaMailBridge(query);
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      _lastError = 'アクセストークンが取得できませんでした';
      notifyListeners();
      return [];
    }

    try {
      print('🔍 メール検索開始: "$query"');

      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?q=$encodedQuery&maxResults=100',
      );

      final response = await _retryWithBackoff(() => http.get(
            url,
            headers: {'Authorization': 'Bearer $accessToken'},
          ));

      if (response == null || response.statusCode != 200) {
        print('❌ 検索失敗: ${response?.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final messages = data['messages'] as List?;

      if (messages == null || messages.isEmpty) {
        print('🔍 検索結果: 0 件');
        return [];
      }

      print('🔍 検索結果: ${messages.length} 件');

      final emails = <EmailMessage>[];
      const batchSize = 20;

      for (var i = 0; i < messages.length; i += batchSize) {
        final end =
            (i + batchSize < messages.length) ? i + batchSize : messages.length;
        final batch = messages.sublist(i, end);

        final futures = batch
            .map((msg) => _fetchEmailMetadataWithRetry(msg['id'], accessToken))
            .toList();
        final batchResults = await Future.wait(futures);
        emails.addAll(batchResults.whereType<EmailMessage>());

        print(
            '🔍 バッチ ${i + 1}-$end 完了: ${batchResults.whereType<EmailMessage>().length} 件');
      }

      print('✅ 検索完了: ${emails.length} 件');
      return emails;
    } catch (e) {
      print('❌ 検索エラー: $e');
      _lastError = '検索中にエラーが発生しました';
      notifyListeners();
      return [];
    }
  }

  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? bodyHtml,
    String? from,
    String? cc,
    String? bcc,
    String? inReplyTo,
    String? references,
    List<EmailAttachment>? attachments,
  }) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      return false;
    }

    final safeAttachments = attachments ?? const <EmailAttachment>[];
    rememberRecipientCandidates(to);
    if (cc != null) rememberRecipientCandidates(cc);
    if (bcc != null) rememberRecipientCandidates(bcc);

    if (_useMailBridge) {
      final response = await _postMailBridge('/api/mail/send', {
        'from': from,
        'to': to,
        'subject': subject,
        'body': body,
        'bodyHtml': bodyHtml,
        'cc': cc,
        'bcc': bcc,
        'inReplyTo': inReplyTo,
        'references': references,
        'attachments': safeAttachments.isEmpty
            ? null
            : safeAttachments
                .map((file) => {
                      'filename': file.fileName,
                      'mimeType': file.mimeType,
                      'data': base64.encode(file.bytes),
                    })
                .toList(),
      });
      final ok = response?.statusCode == 200;
      if (ok) {
        clearCache();
      }
      return ok;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      return false;
    }

    try {
      final email = _createMimeMessage(
        from: from,
        to: to,
        subject: subject,
        body: body,
        bodyHtml: bodyHtml,
        cc: cc,
        bcc: bcc,
        inReplyTo: inReplyTo,
        references: references,
        attachments: safeAttachments,
      );

      final encodedEmail =
          base64Url.encode(utf8.encode(email)).replaceAll('=', '');

      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
      );

      final response = await _retryWithBackoff(() => http.post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'raw': encodedEmail,
            }),
          ));

      if (response?.statusCode == 200) {
        print('✅ メール送信成功');
        clearCache();
        return true;
      } else {
        print('❌ メール送信失敗: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ メール送信エラー: $e');
      return false;
    }
  }

  Future<bool> saveDraft({
    String? from,
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
  }) async {
    if (!isSignedIn()) {
      print('❌ ログインしていません');
      return false;
    }

    final trimmedTo = to.trim();
    final trimmedCc = (cc ?? '').trim();
    final trimmedBcc = (bcc ?? '').trim();
    final trimmedSubject = subject.trim();
    final trimmedBody = body.trimRight();
    rememberRecipientCandidates(trimmedTo);
    rememberRecipientCandidates(trimmedCc);
    rememberRecipientCandidates(trimmedBcc);

    if (trimmedTo.isEmpty &&
        trimmedCc.isEmpty &&
        trimmedBcc.isEmpty &&
        trimmedSubject.isEmpty &&
        trimmedBody.isEmpty) {
      return false;
    }

    if (_useMailBridge) {
      final response = await _postMailBridge('/api/mail/draft', {
        'from': from,
        'to': trimmedTo,
        'cc': trimmedCc,
        'bcc': trimmedBcc,
        'subject': trimmedSubject,
        'body': trimmedBody,
      });
      return response?.statusCode == 200;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('❌ アクセストークンが取得できませんでした');
      return false;
    }

    try {
      final mime = _createDraftMimeMessage(
        from: from,
        to: trimmedTo,
        cc: trimmedCc,
        bcc: trimmedBcc,
        subject: trimmedSubject,
        body: trimmedBody,
      );
      final encoded = base64Url.encode(utf8.encode(mime)).replaceAll('=', '');
      final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/drafts',
      );
      final response = await _retryWithBackoff(() => http.post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'message': {'raw': encoded},
            }),
          ));
      return response?.statusCode == 200;
    } catch (e) {
      print('❌ 下書き保存エラー: $e');
      return false;
    }
  }

  Future<bool> _signInViaMailBridge({
    required MailProvider provider,
    String? email,
    String? password,
  }) async {
    final inputEmail = email?.trim() ?? '';
    final inputPassword = password?.trim() ?? '';

    if (inputEmail.isEmpty || inputPassword.isEmpty) {
      _lastError = 'メールアドレスとアプリパスワードが必要です';
      notifyListeners();
      return false;
    }

    final response = await http.post(
      Uri.parse('$_mailBridgeBaseUrl/api/mail/login'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({
        'provider': _providerId(provider),
        'email': inputEmail,
        'password': inputPassword,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'ログインに失敗しました';
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final error = data['error'] as String?;
        if (error != null && error.isNotEmpty) {
          message = error;
        }
      } catch (_) {}
      _lastError = message;
      notifyListeners();
      return false;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    _provider = provider;
    _mailSessionToken = data['token'] as String?;
    _mailAuthMode =
        (data['authMode'] as String?)?.trim() == 'oauth' ? 'oauth' : 'password';
    _mailAccountId = (data['accountId'] as String?)?.trim();
    if (_mailAccountId?.isEmpty ?? true) {
      _mailAccountId = null;
    }
    _currentUser = null;
    _accessToken = null;
    _userEmail = (data['email'] as String?) ?? inputEmail;
    _rememberEmail(_userEmail);
    _unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
    _lastError = null;
    _persistMailSession();
    clearCache();
    notifyListeners();
    return _mailSessionToken != null;
  }

  Future<bool> signInWithServerOAuth({
    required MailProvider provider,
  }) async {
    try {
      final origin = Uri.base.origin;
      final startUrl = Uri.parse(
        '$_mailBridgeBaseUrl/api/mail/oauth/start'
        '?provider=${_providerId(provider)}'
        '&origin=${Uri.encodeComponent(origin)}',
      ).toString();

      final result = await oauth_popup_bridge.launchServerOAuthPopup(startUrl);
      if (result == null) {
        _lastError = 'OAuthログインに失敗しました';
        notifyListeners();
        return false;
      }

      final ok = (result['ok'] ?? '').toLowerCase() == 'true';
      if (!ok) {
        _lastError = result['error'] ?? 'OAuthログインに失敗しました';
        notifyListeners();
        return false;
      }

      final token = (result['token'] ?? '').trim();
      final email = (result['email'] ?? '').trim();
      final providerId = (result['provider'] ?? _providerId(provider)).trim();
      final unread = int.tryParse((result['unreadCount'] ?? '0').trim()) ?? 0;
      if (token.isEmpty || email.isEmpty) {
        _lastError = 'OAuthレスポンスが不正です';
        notifyListeners();
        return false;
      }

      _provider = _providerFromId(providerId);
      _mailSessionToken = token;
      _mailAuthMode = 'oauth';
      _mailAccountId = (result['accountId'] ?? '').trim();
      if (_mailAccountId?.isEmpty ?? true) {
        _mailAccountId = null;
      }
      _currentUser = null;
      _accessToken = null;
      _userEmail = email;
      _unreadCount = unread;
      _lastError = null;
      _rememberEmail(_userEmail);
      _persistMailSession();
      clearCache();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'OAuthログインに失敗しました: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchServerProviderConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_mailBridgeBaseUrl/api/system/providers'),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<bool> restoreServerSessionIfNeeded() async {
    final hasToken = _mailSessionToken != null && _mailSessionToken!.isNotEmpty;

    if (!hasToken) {
      if (_hasRestorableOAuthIdentity) {
        return _restoreOAuthSession(notifyOnFailure: false);
      }
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_mailBridgeBaseUrl/api/mail/session'),
        headers: {
          'Content-Type': 'application/json',
          'X-Mail-Session': _mailSessionToken!,
        },
        body: jsonEncode({}),
      );
      if (response.statusCode != 200) {
        if (_hasRestorableOAuthIdentity) {
          return _restoreOAuthSession(notifyOnFailure: false);
        }
        _invalidateSession(keepOAuthIdentity: false);
        return false;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      _userEmail = (data['email'] as String?)?.trim() ?? _userEmail;
      final providerRaw = (data['provider'] as String?)?.trim();
      if (providerRaw != null && providerRaw.isNotEmpty) {
        _provider = _providerFromId(providerRaw);
      }
      final authMode = (data['authMode'] as String?)?.trim();
      if (authMode == 'oauth' || authMode == 'password') {
        _mailAuthMode = authMode!;
      }
      final accountId = (data['accountId'] as String?)?.trim();
      if (accountId != null && accountId.isNotEmpty) {
        _mailAccountId = accountId;
      } else if (_mailAuthMode != 'oauth') {
        _mailAccountId = null;
      }
      _unreadCount = (data['unreadCount'] as num?)?.toInt() ?? _unreadCount;
      _lastError = null;
      _rememberEmail(_userEmail);
      _persistMailSession();
      notifyListeners();
      return true;
    } catch (e) {
      if (_hasRestorableOAuthIdentity) {
        return _restoreOAuthSession(notifyOnFailure: false);
      }
      _lastError = 'サーバーセッションの復元に失敗しました: $e';
      _invalidateSession(keepOAuthIdentity: false);
      return false;
    }
  }

  Future<bool> _restoreOAuthSession({bool notifyOnFailure = true}) async {
    if (!_hasRestorableOAuthIdentity) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_mailBridgeBaseUrl/api/mail/oauth/restore'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': _providerId(_provider),
          'email': _userEmail?.trim() ?? '',
          'accountId': _mailAccountId?.trim() ?? '',
        }),
      );

      if (response.statusCode != 200) {
        if (notifyOnFailure) {
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final message = (data['error'] as String?)?.trim();
            _lastError = (message?.isNotEmpty ?? false)
                ? message
                : 'OAuthセッションの復元に失敗しました';
          } catch (_) {
            _lastError = 'OAuthセッションの復元に失敗しました';
          }
          notifyListeners();
        }
        _invalidateSession(keepOAuthIdentity: true);
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = (data['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) {
        _invalidateSession(keepOAuthIdentity: true);
        return false;
      }

      _mailSessionToken = token;
      _mailAuthMode = 'oauth';
      _mailAccountId = (data['accountId'] as String?)?.trim() ?? _mailAccountId;
      if (_mailAccountId?.isEmpty ?? true) {
        _mailAccountId = null;
      }
      _userEmail = (data['email'] as String?)?.trim() ?? _userEmail;
      final providerRaw = (data['provider'] as String?)?.trim();
      if (providerRaw != null && providerRaw.isNotEmpty) {
        _provider = _providerFromId(providerRaw);
      }
      _unreadCount = (data['unreadCount'] as num?)?.toInt() ?? _unreadCount;
      _lastError = null;
      _rememberEmail(_userEmail);
      _persistMailSession();
      notifyListeners();
      return true;
    } catch (e) {
      if (notifyOnFailure) {
        _lastError = 'OAuthセッションの復元に失敗しました: $e';
        notifyListeners();
      }
      _invalidateSession(keepOAuthIdentity: true);
      return false;
    }
  }

  Future<http.Response?> _postMailBridge(
    String path,
    Map<String, dynamic> payload,
  ) async {
    if (_mailSessionToken == null) {
      _lastError = 'セッションが無効です。再ログインしてください';
      notifyListeners();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_mailBridgeBaseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'X-Mail-Session': _mailSessionToken!,
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 401) {
        final canRestore = _hasRestorableOAuthIdentity;
        if (canRestore && await _restoreOAuthSession(notifyOnFailure: false)) {
          final retryResponse = await http.post(
            Uri.parse('$_mailBridgeBaseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'X-Mail-Session': _mailSessionToken!,
            },
            body: json.encode(payload),
          );
          if (retryResponse.statusCode != 401) {
            return retryResponse;
          }
        }

        _lastError = 'セッションが期限切れです。再ログインしてください';
        _invalidateSession(keepOAuthIdentity: canRestore);
        notifyListeners();
      }

      return response;
    } catch (e) {
      _lastError = 'メールサーバーに接続できませんでした: $e';
      notifyListeners();
      return null;
    }
  }

  Future<List<EmailMessage>> _fetchEmailsViaMailBridge({
    required String mailbox,
    required int maxResults,
    required bool forceRefresh,
  }) async {
    final cacheKey = '${_providerId(_provider)}_${mailbox}_$maxResults';
    if (!forceRefresh && _emailCache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiration) {
        return _emailCache[cacheKey]!;
      }
    }

    final response = await _postMailBridge('/api/mail/list', {
      'mailbox': mailbox,
      'maxResults': maxResults,
    });

    if (response == null || response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final emailsRaw = (data['emails'] as List?) ?? const [];
    final emails = emailsRaw
        .whereType<Map<String, dynamic>>()
        .map(_mailBridgeMessageToModel)
        .toList();

    _emailCache[cacheKey] = emails;
    _cacheTimestamps[cacheKey] = DateTime.now();
    _lastError = null;
    return emails;
  }

  Future<List<EmailMessage>> _searchEmailsViaMailBridge(String query) async {
    final response = await _postMailBridge('/api/mail/search', {
      'query': query,
      'maxResults': 100,
    });

    if (response == null || response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final emailsRaw = (data['emails'] as List?) ?? const [];
    _lastError = null;
    return emailsRaw
        .whereType<Map<String, dynamic>>()
        .map(_mailBridgeMessageToModel)
        .toList();
  }

  String _providerId(MailProvider provider) {
    switch (provider) {
      case MailProvider.gmail:
        return 'gmail';
      case MailProvider.yahoo:
        return 'yahoo';
      case MailProvider.outlook:
        return 'outlook';
    }
  }

  EmailMessage _mailBridgeMessageToModel(Map<String, dynamic> data) {
    final dateString = data['date'] as String?;
    final parsedDate = dateString != null
        ? (DateTime.tryParse(dateString)?.toLocal() ?? DateTime.now())
        : DateTime.now();

    final email = EmailMessage(
      id: (data['id'] ?? '').toString(),
      from: (data['from'] as String?) ?? '',
      to: (data['to'] as String?) ?? '',
      cc: (data['cc'] as String?) ?? '',
      subject: ((data['subject'] as String?)?.isNotEmpty ?? false)
          ? _decodeHeaderValue(data['subject'] as String)
          : '(件名なし)',
      body: (data['body'] as String?) ?? '',
      date: parsedDate,
      isUnread: data['isUnread'] == true,
      snippet: (data['snippet'] as String?) ?? '',
    );
    _rememberContactsFromEmail(email);
    return email;
  }

  String _createMimeMessage({
    String? from,
    required String to,
    required String subject,
    required String body,
    String? bodyHtml,
    String? cc,
    String? bcc,
    String? inReplyTo,
    String? references,
    List<EmailAttachment> attachments = const [],
  }) {
    final buffer = StringBuffer();
    final sender = (from ?? _userEmail ?? '').trim();
    if (sender.isNotEmpty) {
      buffer.writeln('From: $sender');
    }
    buffer.writeln('To: $to');

    if (cc != null && cc.isNotEmpty) {
      buffer.writeln('Cc: $cc');
    }

    if (bcc != null && bcc.isNotEmpty) {
      buffer.writeln('Bcc: $bcc');
    }

    final safeSubject =
        _sanitizeHeaderValue(_encodeMimeHeaderIfNeeded(subject));
    buffer.writeln('Subject: $safeSubject');
    buffer.writeln('MIME-Version: 1.0');
    final html = (bodyHtml ?? '').trim();
    final hasHtml = html.isNotEmpty;

    if (inReplyTo != null) {
      buffer.writeln('In-Reply-To: $inReplyTo');
    }

    if (references != null) {
      buffer.writeln('References: $references');
    }

    if (attachments.isEmpty && !hasHtml) {
      buffer.writeln('Content-Type: text/plain; charset=utf-8');
      buffer.writeln('Content-Transfer-Encoding: base64');
      buffer.writeln();
      buffer.writeln(_encodeBase64WithLineWrap(utf8.encode(body)));
      return buffer.toString();
    }

    if (attachments.isEmpty && hasHtml) {
      final alternativeBoundary =
          'venemo_alt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 30)}';
      buffer.writeln(
          'Content-Type: multipart/alternative; boundary="$alternativeBoundary"');
      buffer.writeln();
      _appendMimeBodyPart(
        buffer,
        boundary: alternativeBoundary,
        mimeType: 'text/plain; charset=utf-8',
        content: body,
      );
      _appendMimeBodyPart(
        buffer,
        boundary: alternativeBoundary,
        mimeType: 'text/html; charset=utf-8',
        content: html,
      );
      buffer.writeln('--$alternativeBoundary--');
      return buffer.toString();
    }

    final boundary =
        'venemo_boundary_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 30)}';
    buffer.writeln('Content-Type: multipart/mixed; boundary="$boundary"');
    buffer.writeln();
    if (hasHtml) {
      final alternativeBoundary =
          'venemo_alt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 30)}';
      buffer.writeln('--$boundary');
      buffer.writeln(
          'Content-Type: multipart/alternative; boundary="$alternativeBoundary"');
      buffer.writeln();
      _appendMimeBodyPart(
        buffer,
        boundary: alternativeBoundary,
        mimeType: 'text/plain; charset=utf-8',
        content: body,
      );
      _appendMimeBodyPart(
        buffer,
        boundary: alternativeBoundary,
        mimeType: 'text/html; charset=utf-8',
        content: html,
      );
      buffer.writeln('--$alternativeBoundary--');
    } else {
      _appendMimeBodyPart(
        buffer,
        boundary: boundary,
        mimeType: 'text/plain; charset=utf-8',
        content: body,
      );
    }

    for (final file in attachments) {
      final fileName = _escapeMimeHeaderValue(
        file.fileName.isEmpty ? 'attachment.bin' : file.fileName,
      );
      final mimeType =
          file.mimeType.isEmpty ? 'application/octet-stream' : file.mimeType;
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Type: $mimeType; name="$fileName"');
      buffer.writeln('Content-Disposition: attachment; filename="$fileName"');
      buffer.writeln('Content-Transfer-Encoding: base64');
      buffer.writeln();
      buffer.writeln(_encodeBase64WithLineWrap(file.bytes));
    }

    buffer.writeln('--$boundary--');

    return buffer.toString();
  }

  void _appendMimeBodyPart(
    StringBuffer buffer, {
    required String boundary,
    required String mimeType,
    required String content,
  }) {
    buffer.writeln('--$boundary');
    buffer.writeln('Content-Type: $mimeType');
    buffer.writeln('Content-Transfer-Encoding: base64');
    buffer.writeln();
    buffer.writeln(_encodeBase64WithLineWrap(utf8.encode(content)));
  }

  String _createDraftMimeMessage({
    String? from,
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
  }) {
    final buffer = StringBuffer();
    final sender = (from ?? _userEmail ?? '').trim();
    if (sender.isNotEmpty) {
      buffer.writeln('From: $sender');
    }
    if (to.trim().isNotEmpty) {
      buffer.writeln('To: $to');
    }
    if (cc != null && cc.trim().isNotEmpty) {
      buffer.writeln('Cc: $cc');
    }
    if (bcc != null && bcc.trim().isNotEmpty) {
      buffer.writeln('Bcc: $bcc');
    }

    final draftSubject = subject.trim().isEmpty ? '(下書き)' : subject.trim();
    final safeSubject =
        _sanitizeHeaderValue(_encodeMimeHeaderIfNeeded(draftSubject));
    buffer.writeln('Subject: $safeSubject');
    buffer.writeln('MIME-Version: 1.0');
    buffer.writeln('Content-Type: text/plain; charset=utf-8');
    buffer.writeln('Content-Transfer-Encoding: base64');
    buffer.writeln();
    buffer.writeln(_encodeBase64WithLineWrap(utf8.encode(body)));
    return buffer.toString();
  }

  String _escapeMimeHeaderValue(String value) {
    return value.replaceAll('"', "'");
  }

  String _sanitizeHeaderValue(String value) {
    return value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  }

  String _encodeMimeHeaderIfNeeded(String value) {
    final normalized = _repairMojibake(value);
    final shouldEncode =
        normalized.runes.any((rune) => rune > 0x7E || rune < 0x20);
    if (!shouldEncode) {
      return normalized;
    }
    final encoded = base64.encode(utf8.encode(normalized));
    return '=?UTF-8?B?$encoded?=';
  }

  String _encodeBase64WithLineWrap(List<int> bytes) {
    final encoded = base64.encode(bytes);
    final wrapped = StringBuffer();
    for (int i = 0; i < encoded.length; i += 76) {
      final end = (i + 76 < encoded.length) ? i + 76 : encoded.length;
      wrapped.writeln(encoded.substring(i, end));
    }
    return wrapped.toString().trimRight();
  }
}
