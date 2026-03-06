import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gmail_service.dart';
import '../services/app_settings_service.dart';
import '../models/email_message.dart';
import 'email_reply_screen.dart';
import 'email_compose_screen.dart';

// 条件付きインポート
import 'email_detail_web.dart' if (dart.library.io) 'email_detail_mobile.dart';

class EmailDetailScreen extends StatefulWidget {
  final EmailMessage email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  final GmailService _gmailService = GmailService();
  final AppSettingsService _settings = AppSettingsService();
  String _emailBody = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool _linkMode = false;

  EmailMessage _buildReplyEmail() {
    return EmailMessage(
      id: widget.email.id,
      from: widget.email.from,
      to: widget.email.to,
      cc: widget.email.cc,
      subject: widget.email.subject,
      body: _emailBody.isNotEmpty ? _emailBody : widget.email.body,
      date: widget.email.date,
      isUnread: widget.email.isUnread,
      snippet: widget.email.snippet,
    );
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

  String _quotedOriginal() {
    final body = _emailBody.isNotEmpty ? _emailBody : widget.email.body;
    final sender = widget.email.from.split('<').first.trim();
    return '''

---------- Forwarded message ----------
From: $sender
Date: ${DateFormat('yyyy/MM/dd HH:mm').format(widget.email.date)}
Subject: ${widget.email.subject}
To: ${_gmailService.getUserEmail() ?? "me"}

$body
''';
  }

  void _openReply() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailReplyScreen(email: _buildReplyEmail()),
      ),
    );
  }

  void _openReplyAll() {
    final myEmail = (_gmailService.getUserEmail() ?? '').toLowerCase();
    final recipients = <String>{};

    for (final address in [
      _extractAddress(widget.email.from),
      ..._extractAddresses(widget.email.to),
      ..._extractAddresses(widget.email.cc),
    ]) {
      final normalized = address.toLowerCase();
      if (normalized.isEmpty || normalized == myEmail) continue;
      recipients.add(address);
    }

    final subject = widget.email.subject.startsWith('Re:')
        ? widget.email.subject
        : 'Re: ${widget.email.subject}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailComposeScreen(
          initialTo: recipients.join(', '),
          initialSubject: subject,
          initialBody: '\n\n--- 元のメッセージ ---\n'
              '${_emailBody.isNotEmpty ? _emailBody : widget.email.body}',
        ),
      ),
    );
  }

  void _openForward() {
    final subject = widget.email.subject.startsWith('Fwd:')
        ? widget.email.subject
        : 'Fwd: ${widget.email.subject}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailComposeScreen(
          initialSubject: subject,
          initialBody: _quotedOriginal(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEmailBody();
    if (widget.email.isUnread) {
      _gmailService.markAsRead(widget.email.id);
    }
  }

  Future<void> _loadEmailBody() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = await _gmailService.fetchEmailBody(widget.email.id);
      if (!mounted) return;

      if (body.isEmpty ||
          body.contains('ログインしていません') ||
          body.contains('アクセストークンが取得できませんでした') ||
          body.contains('本文の取得に失敗しました') ||
          body.contains('本文がありません')) {
        setState(() {
          _errorMessage = body.isEmpty ? '本文がありません' : body;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _emailBody = body;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '本文の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    final timeFormat = DateFormat('HH:mm');

    if (messageDate == today) {
      return timeFormat.format(date);
    } else if (messageDate == yesterday) {
      return '昨日 ${timeFormat.format(date)}';
    } else {
      return DateFormat('yyyy/M/d').format(date);
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メールを削除'),
        content: const Text('このメールをゴミ箱に移動しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await _gmailService.moveToTrash(widget.email.id);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('削除に失敗しました')),
        );
      }
    }
  }

  void _openAssistantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetRow(Icons.language_rounded, '次の言語に翻訳する：'),
              const Divider(height: 22),
              _sheetRow(Icons.auto_fix_high, '要約', aiRequired: true),
              const Divider(height: 22),
              _sheetRow(Icons.auto_awesome, 'VenemoAIに質問する', aiRequired: true),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetRow(IconData icon, String title, {bool aiRequired = false}) {
    return InkWell(
      onTap: () {
        if (aiRequired && !_settings.isAiAvailable()) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'この機能はVenemo Plus（月額¥${_settings.plusMonthlyPriceYen()}）で利用できます',
              ),
            ),
          );
          return;
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title を実行します')),
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF111418)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 40 / 2, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  _circleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: const Color(0xFFD1D5DB), width: 1),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              setState(() => _linkMode = !_linkMode),
                          icon: Icon(
                            Icons.link_rounded,
                            color: _linkMode ? const Color(0xFF2A7BF1) : null,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.push_pin_outlined),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.flash_on_outlined),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.person_add_alt_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Text(
                widget.email.subject,
                style: const TextStyle(
                    fontSize: 54 / 2, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.email.from.split('<').first.trim(),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '宛先: ${_gmailService.getUserEmail() ?? "me"}',
                          style: const TextStyle(
                            color: Color(0xFF2A7BF1),
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(widget.email.date),
                    style: const TextStyle(
                      color: Color(0xFF7E8792),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _openAssistantSheet,
                    icon: const Icon(Icons.more_horiz_rounded, size: 30),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '日本語に翻訳',
                        style: TextStyle(
                          color: Color(0xFF3A6FE2),
                          fontSize: 43 / 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openAssistantSheet,
                      icon: const Icon(Icons.tune_rounded,
                          color: Color(0xFF6F99F3)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : EmailBodyWidget(
                          emailBody: _emailBody,
                          emailId: widget.email.id,
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.circle_outlined)),
                    IconButton(
                      onPressed: _openReply,
                      icon: const Icon(Icons.reply_rounded),
                    ),
                    IconButton(
                      onPressed: _openReplyAll,
                      icon: const Icon(Icons.reply_all_rounded),
                    ),
                    IconButton(
                      onPressed: _openForward,
                      icon: const Icon(Icons.forward_to_inbox_rounded),
                    ),
                    IconButton(
                      onPressed: () {
                        _gmailService.markAsRead(widget.email.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('メールを完了にしました')),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.schedule_rounded)),
                    IconButton(
                      onPressed: _openAssistantSheet,
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _openAssistantSheet,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A84FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+ai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmAndDelete,
        tooltip: '削除',
        child: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
      ),
    );
  }
}
