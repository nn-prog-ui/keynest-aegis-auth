import 'package:flutter/material.dart';
import '../models/email_message.dart';
import '../services/gmail_service.dart';
import 'email_detail_screen.dart';

class ServiceNotificationsScreen extends StatefulWidget {
  final List<EmailMessage> emails;

  const ServiceNotificationsScreen({
    super.key,
    required this.emails,
  });

  @override
  State<ServiceNotificationsScreen> createState() =>
      _ServiceNotificationsScreenState();
}

class _ServiceNotificationsScreenState
    extends State<ServiceNotificationsScreen> {
  final GmailService _gmailService = GmailService();
  bool _enabled = true;
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

  String _extractAddress(String raw) {
    final match = RegExp(r'<([^>]+)>').firstMatch(raw);
    if (match != null) {
      return (match.group(1) ?? '').trim();
    }
    return raw.trim();
  }

  String _displayName(EmailMessage email) {
    final name = email.from.split('<').first.trim();
    if (name.isNotEmpty) return name;
    return _extractAddress(email.from);
  }

  Color _avatarColor(EmailMessage email) {
    final key = _extractAddress(email.from).toLowerCase();
    if (key.isEmpty) return _avatarColors.first;
    var sum = 0;
    for (final rune in key.runes) {
      sum += rune;
    }
    return _avatarColors[sum % _avatarColors.length];
  }

  String _avatarInitial(EmailMessage email) {
    final source = _displayName(email).replaceAll(RegExp("[\"'`]"), '').trim();
    for (final char in source.characters) {
      final rune = char.runes.first;
      final isAsciiAlphaNum = (rune >= 48 && rune <= 57) ||
          (rune >= 65 && rune <= 90) ||
          (rune >= 97 && rune <= 122);
      final isJapaneseLike = (rune >= 0x3040 && rune <= 0x30FF) ||
          (rune >= 0x4E00 && rune <= 0x9FFF);
      if (isAsciiAlphaNum || isJapaneseLike) return char.toUpperCase();
    }
    return '@';
  }

  Widget _avatar(EmailMessage email) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _avatarColor(email),
      ),
      child: Text(
        _avatarInitial(email),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  _circleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'サービス通知',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _enabled,
                          onChanged: (v) => setState(() => _enabled = v),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded, size: 34),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
                children: [
                  const Text(
                    '今日',
                    style: TextStyle(
                      color: Color(0xFF808790),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...widget.emails.map(_buildServiceEmailItem),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.auto_awesome, color: Color(0xFF0A84FF)),
                    SizedBox(width: 8),
                    Text(
                      '質問を入力してください',
                      style: TextStyle(
                        color: Color(0xFFB5B9C2),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A84FF),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceEmailItem(EmailMessage email) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailDetailScreen(email: email),
          ),
        );

        if (!mounted) return;
        _gmailService.markAsRead(email.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2F3138),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 86),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: const Text(
              'メールを既読にしました',
              style: TextStyle(fontSize: 18),
            ),
            action: SnackBarAction(
              label: '取り消す',
              textColor: Colors.white,
              onPressed: () {
                _gmailService.markAsUnread(email.id);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Icon(Icons.circle, color: Color(0xFF3B78F1), size: 13),
            ),
            const SizedBox(width: 10),
            _avatar(email),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(email),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.snippet.isEmpty ? '本文プレビューなし' : email.snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF88909B),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(email.date),
                        style: const TextStyle(
                          color: Color(0xFF88909B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    if (sameDay) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.year}/${date.month}/${date.day}';
  }
}
