import 'dart:async';

import 'package:flutter/material.dart';

import '../models/email_message.dart';
import '../services/app_settings_service.dart';
import '../services/gmail_service.dart';
import '../widgets/html_preview_view.dart';
import 'email_compose_screen.dart';
import 'email_detail_screen.dart';
import 'email_reply_screen.dart';
import 'settings_screen.dart';

class _AccountBucket {
  final String address;
  final String label;
  final int count;

  _AccountBucket({
    required this.address,
    required this.label,
    required this.count,
  });
}

enum _PreviewBodyMode { plain, html }

class MailListScreen extends StatefulWidget {
  const MailListScreen({super.key});

  @override
  State<MailListScreen> createState() => _MailListScreenState();
}

class _MailListScreenState extends State<MailListScreen> {
  static const Color _bgColor = Color(0xFFF5F5F7);
  static const Color _sidebarColor = Color(0xFFF2F2F7);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _primaryText = Color(0xFF1D1D1F);
  static const Color _secondaryText = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);
  static const Color _border = Color(0x14000000);
  static const Color _hover = Color(0x0A000000);
  static const List<Color> _avatarColors = <Color>[
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC04),
    Color(0xFFEA4335),
    Color(0xFF7E57C2),
    Color(0xFF00ACC1),
    Color(0xFF5C6BC0),
    Color(0xFFFF7043),
  ];

  final GmailService _gmailService = GmailService();
  final AppSettingsService _settingsService = AppSettingsService();
  final TextEditingController _searchController = TextEditingController();

  List<EmailMessage> _emails = [];
  EmailMessage? _selectedEmail;
  String _selectedBodyText = '';
  String _selectedBodyHtml = '';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isPreviewLoading = false;
  String _selectedMailbox = 'inbox';
  int _fetchLimit = 80;
  String? _selectedAccountAddress;
  _PreviewBodyMode _previewBodyMode = _PreviewBodyMode.html;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadEmails();
    _searchController.addListener(_onSearchChanged);
    _gmailService.addListener(_onGmailServiceChanged);
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _gmailService.removeListener(_onGmailServiceChanged);
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
    _syncSelectedEmail();
  }

  void _onGmailServiceChanged() {
    if (_gmailService.lastError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_gmailService.lastError!),
          backgroundColor: Colors.red.shade600,
          action: SnackBarAction(
            label: '再試行',
            textColor: Colors.white,
            onPressed: () => _loadEmails(forceRefresh: true),
          ),
        ),
      );
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 350), _performSearch);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
      await _loadEmails();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    final results = await _gmailService.searchEmails(query);
    if (!mounted) return;

    setState(() {
      _emails = results;
      _isLoading = false;
    });

    _syncSelectedEmail();
  }

  Future<void> _loadEmails({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    List<EmailMessage> loaded;
    if (_selectedMailbox == 'inbox') {
      loaded = await _gmailService.fetchEmails(
        maxResults: _fetchLimit,
        forceRefresh: forceRefresh,
      );
    } else if (_selectedMailbox == 'sent') {
      loaded = await _gmailService.fetchSentEmails(
        maxResults: _fetchLimit,
        forceRefresh: forceRefresh,
      );
    } else if (_selectedMailbox == 'trash') {
      loaded = await _gmailService.fetchTrashEmails(
        maxResults: _fetchLimit,
        forceRefresh: forceRefresh,
      );
    } else {
      loaded = [];
    }

    if (!mounted) return;
    setState(() {
      _emails = loaded;
      _isLoading = false;

      if (_selectedMailbox != 'inbox') {
        _selectedAccountAddress = null;
      }
    });

    _syncSelectedEmail();
  }

  void _syncSelectedEmail() {
    final visible = _visibleEmails;
    if (visible.isEmpty) {
      setState(() {
        _selectedEmail = null;
        _selectedBodyText = '';
        _selectedBodyHtml = '';
      });
      return;
    }

    if (_selectedEmail == null ||
        !visible.any((mail) => mail.id == _selectedEmail!.id)) {
      _setSelectedEmail(visible.first, loadBody: true);
    }
  }

  Future<void> _setSelectedEmail(
    EmailMessage email, {
    bool loadBody = true,
  }) async {
    if (!mounted) return;

    setState(() {
      _selectedEmail = email;
      _isPreviewLoading = loadBody;
      _selectedBodyText = '';
      _selectedBodyHtml = '';
      _previewBodyMode = _PreviewBodyMode.plain;
    });

    if (email.isUnread) {
      _gmailService.markAsRead(email.id);
      setState(() {
        _emails = _emails
            .map(
              (item) => item.id == email.id
                  ? EmailMessage(
                      id: item.id,
                      from: item.from,
                      to: item.to,
                      cc: item.cc,
                      subject: item.subject,
                      body: item.body,
                      date: item.date,
                      isUnread: false,
                      snippet: item.snippet,
                    )
                  : item,
            )
            .toList();
      });
    }

    if (!loadBody) return;

    final bodyParts = await _gmailService.fetchEmailBodyParts(email.id);
    if (!mounted || _selectedEmail?.id != email.id) return;

    final plain = bodyParts['plain'] ?? '';
    final html = bodyParts['html'] ?? '';
    final hasHtml = _hasRenderableHtml(_sanitizeHtmlForRender(html));

    setState(() {
      _selectedBodyText = plain;
      _selectedBodyHtml = html;
      _previewBodyMode =
          hasHtml ? _PreviewBodyMode.html : _PreviewBodyMode.plain;
      _isPreviewLoading = false;
    });
  }

  String _extractAddress(String raw) {
    final match = RegExp(r'<([^>]+)>').firstMatch(raw);
    if (match != null) {
      return match.group(1)?.trim() ?? raw.trim();
    }
    return raw.trim();
  }

  List<String> _extractAddresses(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map(_extractAddress)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _recipientAddressesFromEmail(EmailMessage email) {
    final recipients = <String>{
      ..._extractAddresses(email.to).map((e) => e.toLowerCase()),
      ..._extractAddresses(email.cc).map((e) => e.toLowerCase()),
    };

    if (recipients.isEmpty) {
      final current = (_gmailService.getUserEmail() ?? '').toLowerCase();
      if (current.isNotEmpty) {
        recipients.add(current);
      }
    }

    return recipients.toList();
  }

  String _bestTextBodyForActions(EmailMessage email) {
    if (_selectedBodyText.trim().isNotEmpty) {
      return _selectedBodyText.trim();
    }

    final htmlOrRaw =
        _selectedBodyHtml.trim().isNotEmpty ? _selectedBodyHtml : email.body;
    final converted = _plainText(htmlOrRaw).trim();
    if (converted.isNotEmpty) {
      return converted;
    }

    return email.snippet.trim();
  }

  EmailMessage _selectedEmailForAction() {
    final email = _selectedEmail!;
    return EmailMessage(
      id: email.id,
      from: email.from,
      to: email.to,
      cc: email.cc,
      subject: email.subject,
      body: _bestTextBodyForActions(email),
      date: email.date,
      isUnread: email.isUnread,
      snippet: email.snippet,
    );
  }

  void _openReplyFromPreview() {
    if (_selectedEmail == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EmailReplyScreen(email: _selectedEmailForAction()),
      ),
    );
  }

  void _openReplyAllFromPreview() {
    if (_selectedEmail == null) return;

    final email = _selectedEmail!;
    final myEmail = (_gmailService.getUserEmail() ?? '').toLowerCase();
    final recipients = <String>{};
    for (final address in [
      _extractAddress(email.from),
      ..._extractAddresses(email.to),
      ..._extractAddresses(email.cc),
    ]) {
      final normalized = address.toLowerCase();
      if (normalized.isEmpty || normalized == myEmail) continue;
      recipients.add(address);
    }

    final subject = email.subject.startsWith('Re:')
        ? email.subject
        : 'Re: ${email.subject}';
    final original = _bestTextBodyForActions(email);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailComposeScreen(
          initialTo: recipients.join(', '),
          initialSubject: subject,
          initialBody: '\n\n--- 元のメッセージ ---\n$original',
        ),
      ),
    );
  }

  void _openForwardFromPreview() {
    if (_selectedEmail == null) return;
    final email = _selectedEmail!;
    final subject = email.subject.startsWith('Fwd:')
        ? email.subject
        : 'Fwd: ${email.subject}';
    final original = _bestTextBodyForActions(email);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailComposeScreen(
          initialSubject: subject,
          initialBody: '\n\n--- 転送メッセージ ---\n$original',
        ),
      ),
    );
  }

  Future<void> _moveSelectedToTrash() async {
    if (_selectedEmail == null) return;
    final email = _selectedEmail!;
    final success = await _gmailService.moveToTrash(email.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールをゴミ箱へ移動しました')),
      );
      await _loadEmails(forceRefresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ゴミ箱への移動に失敗しました')),
      );
    }
  }

  bool _belongsToAccount(EmailMessage email, String accountAddress) {
    return _recipientAddressesFromEmail(email)
        .contains(accountAddress.toLowerCase());
  }

  bool _isLikelyImportant(EmailMessage email) {
    final content =
        '${email.subject} ${email.snippet} ${email.from}'.toLowerCase();
    final hasKeyword = RegExp(
      r'(重要|urgent|至急|認証|verification|security|セキュリティ|請求|invoice|支払い|payment|alert|通知)',
      caseSensitive: false,
    ).hasMatch(content);
    return email.isUnread || hasKeyword;
  }

  List<EmailMessage> get _visibleEmails {
    var list = _emails;
    if (_selectedMailbox == 'inbox' && _selectedAccountAddress != null) {
      list = list
          .where(
            (mail) => _belongsToAccount(mail, _selectedAccountAddress!),
          )
          .toList();
    }

    if (_selectedMailbox == 'inbox') {
      final inboxFilter = _currentInboxFilter;
      if (inboxFilter == '未読のみ') {
        list = list.where((mail) => mail.isUnread).toList();
      } else if (inboxFilter == '重要のみ') {
        list = list.where(_isLikelyImportant).toList();
      }
    }

    return list;
  }

  String get _currentInboxFilter =>
      _settingsService.getChoice('受信トレイ', fallback: '全受信');

  bool get _hasInboxFilter =>
      _selectedMailbox == 'inbox' && _currentInboxFilter != '全受信';

  void _setInboxFilter(String value) {
    _settingsService.setChoice('受信トレイ', value);
    setState(() {});
    _syncSelectedEmail();
  }

  List<_AccountBucket> get _accountBuckets {
    final registered = _gmailService.getRegisteredEmails();
    final current = (_gmailService.getUserEmail() ?? '').trim().toLowerCase();

    final addresses = <String>{
      ...registered
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty),
    };
    if (current.isNotEmpty) {
      addresses.add(current);
    }

    if (addresses.isEmpty) {
      for (final email in _emails) {
        for (final recipient in _recipientAddressesFromEmail(email)) {
          if (recipient.contains('@')) {
            addresses.add(recipient);
          }
        }
      }
    }

    final values = addresses
        .map(
          (address) => _AccountBucket(
            address: address,
            label: address,
            count: _emails
                .where((mail) => _belongsToAccount(mail, address))
                .length,
          ),
        )
        .toList()
      ..sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;
        return a.label.compareTo(b.label);
      });

    return values;
  }

  Future<void> _openEmail(EmailMessage email, bool desktopLayout) async {
    if (desktopLayout) {
      await _setSelectedEmail(email, loadBody: true);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EmailDetailScreen(email: email)),
    );

    if (!mounted) return;

    if (result == true) {
      _loadEmails(forceRefresh: true);
      return;
    }

    if (_isSearching && _searchController.text.trim().isNotEmpty) {
      _performSearch();
    } else {
      _loadEmails();
    }
  }

  void _selectMailbox(String mailbox) {
    setState(() {
      _selectedMailbox = mailbox;
      _selectedAccountAddress = null;
      _isSearching = false;
      _searchController.clear();
      _emails = [];
      _fetchLimit = 80;
    });
    _loadEmails(forceRefresh: true);
  }

  void _loadMoreEmails() {
    setState(() {
      _fetchLimit += 80;
    });
    _loadEmails(forceRefresh: true);
  }

  String _mailboxTitle() {
    switch (_selectedMailbox) {
      case 'sent':
        return '送信済み';
      case 'trash':
        return 'ゴミ箱';
      default:
        return '全受信';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mailDay = DateTime(date.year, date.month, date.day);
    if (mailDay == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (date.year == now.year) {
      return '${date.month}/${date.day}';
    }
    return '${date.year}/${date.month}/${date.day}';
  }

  String _dateSectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mailDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(mailDay).inDays;

    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    if (diff >= 2 && diff <= 7) return '今週';
    if (date.year == now.year) return '${date.month}月${date.day}日';
    return '${date.year}/${date.month}/${date.day}';
  }

  String _senderDisplayName(EmailMessage email) {
    final name = email.from.split('<').first.trim();
    if (name.isNotEmpty) return name;
    return _extractAddress(email.from);
  }

  String _senderInitial(EmailMessage email) {
    final source =
        _senderDisplayName(email).replaceAll(RegExp("[\"'`]"), '').trim();
    for (final char in source.characters) {
      final rune = char.runes.first;
      final isAsciiAlphaNum = (rune >= 48 && rune <= 57) ||
          (rune >= 65 && rune <= 90) ||
          (rune >= 97 && rune <= 122);
      final isJapaneseLike = (rune >= 0x3040 && rune <= 0x30FF) ||
          (rune >= 0x4E00 && rune <= 0x9FFF);
      if (isAsciiAlphaNum || isJapaneseLike) {
        return char.toUpperCase();
      }
    }
    return '@';
  }

  Color _avatarColorFor(EmailMessage email) {
    final key = _extractAddress(email.from).toLowerCase();
    if (key.isEmpty) {
      return _avatarColors.first;
    }
    var sum = 0;
    for (final rune in key.runes) {
      sum += rune;
    }
    return _avatarColors[sum % _avatarColors.length];
  }

  Widget _senderAvatar(EmailMessage email, {required bool selected}) {
    return _senderAvatarFallback(email, selected: selected);
  }

  Widget _senderAvatarFallback(EmailMessage email, {required bool selected}) {
    final first = _senderInitial(email);
    final avatarColor = _avatarColorFor(email);

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white24 : avatarColor,
        border: Border.all(
          color: selected ? Colors.white30 : const Color(0x22000000),
        ),
      ),
      child: Text(
        first,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _secondaryText,
        ),
      ),
    );
  }

  Widget _buildMailboxRow({
    required String id,
    required IconData icon,
    required String title,
    int? count,
  }) {
    final selected = _selectedMailbox == id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: _hover,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).maybePop();
          }
          _selectMailbox(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : _primaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : _primaryText,
                  ),
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : _secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountRow(_AccountBucket account) {
    final selected = _selectedAccountAddress == account.address;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: _hover,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          setState(() {
            _selectedAccountAddress = account.address;
          });
          _syncSelectedEmail();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.alternate_email_rounded,
                size: 16,
                color: selected ? Colors.white : _secondaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : _primaryText,
                  ),
                ),
              ),
              Text(
                '${account.count}',
                style: TextStyle(
                  color: selected ? Colors.white : _secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent() {
    final unread = _gmailService.unreadCount;
    final userEmail = _gmailService.getUserEmail() ?? 'no-account';

    return Container(
      color: _sidebarColor,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.mail_outline_rounded, size: 18, color: _primaryText),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Venemo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
                  child: Text(
                    'メールボックス',
                    style: TextStyle(
                      color: _secondaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.11,
                    ),
                  ),
                ),
                _buildMailboxRow(
                  id: 'inbox',
                  icon: Icons.all_inbox_rounded,
                  title: '全受信',
                  count: unread,
                ),
                _buildMailboxRow(
                  id: 'sent',
                  icon: Icons.send_rounded,
                  title: '送信済み',
                ),
                _buildMailboxRow(
                  id: 'trash',
                  icon: Icons.delete_outline_rounded,
                  title: 'ゴミ箱',
                ),
                if (_selectedMailbox == 'inbox') ...[
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
                    child: Text(
                      '受信（登録アカウント別）',
                      style: TextStyle(
                        color: _secondaryText,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        letterSpacing: 0.11,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: _hover,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        setState(() {
                          _selectedAccountAddress = null;
                        });
                        _syncSelectedEmail();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedAccountAddress == null
                              ? _accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 16,
                              color: _selectedAccountAddress == null
                                  ? Colors.white
                                  : _secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '全受信',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _selectedAccountAddress == null
                                    ? Colors.white
                                    : _primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._accountBuckets.map(_buildAccountRow),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _border),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0x26007AFF),
                  child: Icon(Icons.person, color: _accent, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '設定',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined,
                      size: 18, color: _secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool desktopLayout) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobileSearchWidth = (screenWidth * 0.4).clamp(148.0, 220.0);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          if (!desktopLayout)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, size: 18),
                color: _primaryText,
              ),
            ),
          if (!desktopLayout) const SizedBox(width: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSubtitle = constraints.maxWidth >= 160;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mailboxTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                    if (showSubtitle)
                      Text(
                        _selectedAccountAddress == null
                            ? 'すべてのメール'
                            : 'アカウント: $_selectedAccountAddress',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.11,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: desktopLayout ? 300 : mobileSearchWidth,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 13,
                color: _primaryText,
              ),
              decoration: InputDecoration(
                hintText: 'メール検索',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: _secondaryText,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: _secondaryText),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                fillColor: _sidebarColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '更新',
            onPressed: () => _loadEmails(forceRefresh: true),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: _border),
              ),
              backgroundColor: _surfaceColor,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.refresh_rounded,
                size: 16, color: _primaryText),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: '新規作成',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmailComposeScreen(),
                ),
              );
            },
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: _border),
              ),
              backgroundColor: _surfaceColor,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            icon:
                const Icon(Icons.edit_outlined, size: 16, color: _primaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildMailRow(EmailMessage email, bool desktopLayout) {
    final selected = desktopLayout && _selectedEmail?.id == email.id;
    final viewerMode = _settingsService.getChoice('メールビューア', fallback: 'コンパクト');
    final compact = viewerMode == 'コンパクト';
    final comfortable = viewerMode == '広め';
    final verticalPadding = compact ? 10.0 : (comfortable ? 12.0 : 11.0);
    final subjectSize = compact ? 14.0 : (comfortable ? 15.0 : 14.4);
    final snippetLines = compact ? 1 : 2;
    final senderLabel = _senderDisplayName(email);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _openEmail(email, desktopLayout),
        hoverColor: _hover,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding:
              EdgeInsets.fromLTRB(16, verticalPadding, 16, verticalPadding),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 17),
                decoration: BoxDecoration(
                  color: email.isUnread
                      ? (selected ? Colors.white : _accent)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              _senderAvatar(email, selected: selected),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            senderLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : _primaryText,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(email.date),
                          style: TextStyle(
                            color: selected ? Colors.white70 : _secondaryText,
                            fontSize: 12,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: subjectSize,
                        color: selected ? Colors.white : _primaryText,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.snippet.isEmpty ? '本文なし' : email.snippet,
                      maxLines: snippetLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white70 : _secondaryText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(bool desktopLayout) {
    final visible = _visibleEmails;
    final inboxFilter = _currentInboxFilter;
    final sectioned = <Object>[];
    String? lastSection;
    for (final mail in visible) {
      final section = _dateSectionLabel(mail.date);
      if (section != lastSection) {
        sectioned.add(section);
        lastSection = section;
      }
      sectioned.add(mail);
    }

    if (_isLoading && _emails.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _hasInboxFilter ? 'フィルタに一致するメールがありません' : 'メールがありません',
              style: const TextStyle(
                color: _secondaryText,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (_hasInboxFilter) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _setInboxFilter('全受信'),
                child: const Text('全受信を表示'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 32,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: _surfaceColor,
            border: Border(
              bottom: BorderSide(color: _border),
            ),
          ),
          child: Text(
            _isSearching
                ? '検索結果 ${visible.length} 件'
                : '${_mailboxTitle()} ${visible.length} 件 / 最新$_fetchLimit件'
                    '${_hasInboxFilter ? '（$inboxFilter）' : ''}',
            style: const TextStyle(
              color: _secondaryText,
              fontWeight: FontWeight.w500,
              fontSize: 11,
              letterSpacing: 0.11,
            ),
          ),
        ),
        if (_selectedMailbox == 'inbox')
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            decoration: const BoxDecoration(
              color: _surfaceColor,
              border: Border(
                bottom: BorderSide(color: _border),
              ),
            ),
            child: Row(
              children: [
                _filterChip('全受信'),
                const SizedBox(width: 6),
                _filterChip('重要のみ'),
                const SizedBox(width: 6),
                _filterChip('未読のみ'),
                const Spacer(),
                if (_hasInboxFilter)
                  TextButton(
                    onPressed: () => _setInboxFilter('全受信'),
                    child: const Text('解除'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            color: _surfaceColor,
            child: ListView.builder(
              itemCount: sectioned.length,
              itemBuilder: (context, index) {
                final item = sectioned[index];
                if (item is String) {
                  return _sectionHeader(item);
                }
                return _buildMailRow(item as EmailMessage, desktopLayout);
              },
            ),
          ),
        ),
        if (!_isSearching)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            decoration: const BoxDecoration(
              color: _surfaceColor,
              border: Border(top: BorderSide(color: _border)),
            ),
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _loadMoreEmails,
              icon: const Icon(Icons.expand_more_rounded, size: 16),
              label: const Text('さらに80件読み込む'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border),
                foregroundColor: _secondaryText,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
      ],
    );
  }

  String _plainText(String source) {
    if (source.trim().isEmpty) {
      return '';
    }

    String text = source
        .replaceAll(
          RegExp(r'<style[^>]*>.*?</style>',
              caseSensitive: false, dotAll: true),
          ' ',
        )
        .replaceAll(
          RegExp(r'<script[^>]*>.*?</script>',
              caseSensitive: false, dotAll: true),
          ' ',
        )
        .replaceAll(
          RegExp(r'<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true),
          ' ',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(p|div|li|tr|h[1-6]|section)>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ');

    text = _decodeHtmlEntities(text);
    text = text
        .replaceAll(
          RegExp(
            "[.#]?[A-Za-z][A-Za-z0-9_\\- .,#:>+*()\\[\\]\"'/=]{0,120}\\{[^{}]{0,800}\\}",
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'[A-Za-z-]{2,30}\s*:\s*[^;\n]{1,180};',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll('}', '\n');

    final lines = text.split('\n');
    final filtered = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (filtered.isNotEmpty && filtered.last.isNotEmpty) {
          filtered.add('');
        }
        continue;
      }

      final cssNoise = RegExp(
        r'(\{|\}|font-family|background-color|color-scheme|text-decoration|box-sizing|min-width|max-width)',
        caseSensitive: false,
      ).hasMatch(trimmed);
      if (cssNoise) {
        continue;
      }

      if (RegExp(r'^[A-Za-z-]+\s*:\s*[^:]+$').hasMatch(trimmed)) {
        continue;
      }

      if (trimmed.length > 200 &&
          RegExp(r'(unsubscribe|配信停止|購読解除|privacy policy|利用規約)',
                  caseSensitive: false)
              .hasMatch(trimmed)) {
        continue;
      }

      filtered.add(trimmed);
    }

    text = filtered.join('\n');
    text = text
        .replaceAll(RegExp(r'[ \t\r\f\v]+'), ' ')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (text.length > 5000) {
      text = '${text.substring(0, 5000)}\n\n...';
    }

    return text;
  }

  bool _looksLikeTemplateNoise(String text) {
    if (text.isEmpty) {
      return false;
    }

    final noisyKeywords = RegExp(
      r'(font-family|background-color|color-scheme|text-decoration|box-sizing|min-width|max-width|table table|unsubscribe|配信停止|購読解除|privacy policy)',
      caseSensitive: false,
    ).allMatches(text).length;
    final punctuationCount = RegExp(r'[;{}]').allMatches(text).length;

    return noisyKeywords >= 4 || punctuationCount >= 24;
  }

  bool _looksLikeHtml(String text) {
    return RegExp(r'<[a-zA-Z][^>]*>').hasMatch(text);
  }

  String _decodeHtmlEntities(String text) {
    final named = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ensp;', ' ')
        .replaceAll('&emsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return named.replaceAllMapped(RegExp(r'&#(x?[0-9A-Fa-f]+);'), (match) {
      final value = match.group(1);
      if (value == null) {
        return match.group(0) ?? '';
      }

      try {
        final codePoint = value.startsWith('x') || value.startsWith('X')
            ? int.parse(value.substring(1), radix: 16)
            : int.parse(value);
        return String.fromCharCode(codePoint);
      } catch (_) {
        return match.group(0) ?? '';
      }
    });
  }

  String _sanitizeHtmlForRender(String html) {
    if (html.trim().isEmpty) {
      return '';
    }

    var cleaned = html
        .replaceAll(
          RegExp(r'<script[^>]*>.*?</script>',
              caseSensitive: false, dotAll: true),
          '',
        )
        .replaceAll(
          RegExp(r'<style[^>]*>.*?</style>',
              caseSensitive: false, dotAll: true),
          '',
        )
        .replaceAll(
          RegExp(r'<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true),
          '',
        );

    if (!RegExp(r'<(html|body)\b', caseSensitive: false).hasMatch(cleaned)) {
      cleaned = '<div>$cleaned</div>';
    }
    return cleaned;
  }

  bool _hasRenderableHtml(String html) {
    final source = html.trim();
    if (source.isEmpty) return false;

    final bodyOnly = source
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ')
        .replaceAll(
          RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false),
          ' ',
        );

    final plain = _plainText(bodyOnly).trim();
    if (plain.isNotEmpty) {
      return true;
    }

    final hasRemoteImage = RegExp(
      r"""<img[^>]+src=['"]https?://""",
      caseSensitive: false,
    ).hasMatch(source);
    if (hasRemoteImage) {
      return true;
    }

    final hasCidImage = RegExp(
      r"""<img[^>]+src=['"]cid:""",
      caseSensitive: false,
    ).hasMatch(bodyOnly);
    if (hasCidImage) {
      return true;
    }

    return RegExp(
      r'<(p|div|span|li|section|article|h[1-6]|blockquote|table|img|svg)\b',
      caseSensitive: false,
    ).hasMatch(bodyOnly);
  }

  Widget _previewActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(74, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _border),
          ),
          backgroundColor: const Color(0xFFF3F6FA),
          foregroundColor: _primaryText,
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPane() {
    if (_selectedEmail == null) {
      return const Center(
        child: Text(
          'メールを選択してください',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final email = _selectedEmail!;
    final fallbackSource = email.body.isNotEmpty ? email.body : email.snippet;
    final plainBody = _selectedBodyText.isNotEmpty
        ? _selectedBodyText
        : _plainText(
            _selectedBodyHtml.isNotEmpty ? _selectedBodyHtml : fallbackSource);
    final htmlBody = _selectedBodyHtml.isNotEmpty
        ? _selectedBodyHtml
        : (_looksLikeHtml(_selectedBodyText)
            ? _selectedBodyText
            : (_looksLikeHtml(fallbackSource) ? fallbackSource : ''));

    var displayBody = plainBody;

    if (displayBody.isEmpty || _looksLikeTemplateNoise(displayBody)) {
      final snippetFallback = _plainText(email.snippet);
      if (snippetFallback.isNotEmpty) {
        displayBody = snippetFallback;
      }
    }

    final sanitizedHtml = _sanitizeHtmlForRender(htmlBody);
    final hasRenderableHtml = _hasRenderableHtml(sanitizedHtml);
    final shouldRenderHtml = hasRenderableHtml || displayBody.trim().isNotEmpty;
    final effectivePreviewMode = _previewBodyMode == _PreviewBodyMode.html
        ? _PreviewBodyMode.html
        : _PreviewBodyMode.plain;

    Widget previewContent;
    if (_isPreviewLoading) {
      previewContent =
          const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else {
      previewContent = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: SelectableText(
          displayBody.isEmpty ? '本文がありません' : displayBody,
          style: const TextStyle(
            height: 1.55,
            fontSize: 14,
            color: _primaryText,
          ),
        ),
      );
    }

    return Container(
      color: _surfaceColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.subject,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${email.from} ・ ${_formatDate(email.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _previewActionButton(
                        icon: Icons.reply_rounded,
                        label: '返信',
                        tooltip: '返信',
                        onPressed: _openReplyFromPreview,
                      ),
                      const SizedBox(width: 6),
                      _previewActionButton(
                        icon: Icons.reply_all_rounded,
                        label: '全員に返信',
                        tooltip: '全員に返信',
                        onPressed: _openReplyAllFromPreview,
                      ),
                      const SizedBox(width: 6),
                      _previewActionButton(
                        icon: Icons.forward_rounded,
                        label: '転送',
                        tooltip: '転送',
                        onPressed: _openForwardFromPreview,
                      ),
                      const SizedBox(width: 6),
                      _previewActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'ゴミ箱',
                        tooltip: 'ゴミ箱へ移動',
                        onPressed: _moveSelectedToTrash,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _bodyModeChip(
                        label: '本文',
                        selected:
                            effectivePreviewMode == _PreviewBodyMode.plain,
                        onPressed: () {
                          setState(() {
                            _previewBodyMode = _PreviewBodyMode.plain;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _bodyModeChip(
                        label: 'HTML',
                        selected: effectivePreviewMode == _PreviewBodyMode.html,
                        enabled: true,
                        onPressed: () {
                          setState(() {
                            _previewBodyMode = _PreviewBodyMode.html;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: effectivePreviewMode == _PreviewBodyMode.html &&
                    shouldRenderHtml
                ? HtmlPreviewView(
                    key: ValueKey(
                      '${email.id}-${email.date.millisecondsSinceEpoch}-${sanitizedHtml.length}',
                    ),
                    htmlContent: sanitizedHtml,
                    plainFallback:
                        displayBody.isEmpty ? '本文がありません' : displayBody,
                    viewId:
                        '${email.id}-${email.date.millisecondsSinceEpoch}-${sanitizedHtml.length}',
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  )
                : previewContent,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _currentInboxFilter == label;
    return GestureDetector(
      onTap: () => _setInboxFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0x12007AFF) : _sidebarColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _accent : _border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? _accent : _secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _bodyModeChip({
    required String label,
    required bool selected,
    bool enabled = true,
    VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(54, 28),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? _accent : _border,
          ),
        ),
        backgroundColor: selected ? const Color(0x12007AFF) : _surfaceColor,
        foregroundColor: enabled
            ? (selected ? _accent : _primaryText)
            : _secondaryText.withValues(alpha: 0.6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildComposeFab({required bool desktopLayout}) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailComposeScreen(),
          ),
        );
      },
      tooltip: '新規作成',
      extendedPadding: EdgeInsets.symmetric(
        horizontal: desktopLayout ? 24 : 22,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.edit_rounded, size: 22),
      label: Text(
        '新規作成',
        style: TextStyle(
          fontSize: desktopLayout ? 17 : 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopLayout = constraints.maxWidth >= 1080;

        return Scaffold(
          backgroundColor: _bgColor,
          drawer: desktopLayout
              ? null
              : Drawer(
                  width: 290,
                  child: SafeArea(child: _buildSidebarContent()),
                ),
          body: SafeArea(
            child: desktopLayout
                ? Row(
                    children: [
                      SizedBox(width: 280, child: _buildSidebarContent()),
                      const VerticalDivider(width: 1, color: _border),
                      SizedBox(
                        width: 460,
                        child: Column(
                          children: [
                            _buildToolbar(true),
                            Expanded(child: _buildMessageList(true)),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1, color: _border),
                      Expanded(
                        child: _buildPreviewPane(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildToolbar(false),
                      Expanded(child: _buildMessageList(false)),
                    ],
                  ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _buildComposeFab(desktopLayout: desktopLayout),
        );
      },
    );
  }
}
