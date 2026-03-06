import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/email_attachment.dart';
import '../models/email_message.dart';
import '../services/ai_service.dart';
import '../services/app_settings_service.dart';
import '../services/gmail_service.dart';
import 'venemo_plus_screen.dart';

class _ReplyTextColorOption {
  final String label;
  final Color color;

  const _ReplyTextColorOption(this.label, this.color);
}

class EmailReplyScreen extends StatefulWidget {
  final EmailMessage email;

  const EmailReplyScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailReplyScreen> createState() => _EmailReplyScreenState();
}

enum _ReplyCloseAction { cancel, discard, saveDraft }

class _EmailReplyScreenState extends State<EmailReplyScreen> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _line = Color(0x14000000);
  static const Color _text = Color(0xFF1D1D1F);
  static const Color _sub = Color(0xFF6E6E73);
  static const Color _accent = Color(0xFF007AFF);
  static const Color _summaryBg = Color(0xFFF2FBF7);
  static const Color _summaryBorder = Color(0xFFD8EEE3);
  static const Color _defaultBodyTextColor = Color(0xFF1D1D1F);
  static const List<_ReplyTextColorOption> _textColorOptions = [
    _ReplyTextColorOption('標準（黒）', _defaultBodyTextColor),
    _ReplyTextColorOption('ブルー', Color(0xFF007AFF)),
    _ReplyTextColorOption('グリーン', Color(0xFF2E7D32)),
    _ReplyTextColorOption('レッド', Color(0xFFC62828)),
    _ReplyTextColorOption('オレンジ', Color(0xFFEF6C00)),
    _ReplyTextColorOption('パープル', Color(0xFF6A1B9A)),
    _ReplyTextColorOption('グレー', Color(0xFF616161)),
  ];

  final AIService _aiService = AIService();
  final GmailService _gmailService = GmailService();
  final AppSettingsService _settingsService = AppSettingsService();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final List<EmailAttachment> _attachments = <EmailAttachment>[];

  bool _isSending = false;
  bool _isGeneratingAI = false;
  bool _isGeneratingSummary = false;
  bool _isLoadingOriginalBody = false;
  bool _showCc = false;
  double _bodyFontSize = 16;
  Color _bodyTextColor = _defaultBodyTextColor;
  String _originalBody = '';
  String _selectedFromAddress = '';
  String _selectedSignatureId = 'none';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _summaryController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  bool get _isNewEmail => widget.email.id.isEmpty;

  String get _draftStorageKey =>
      'reply_draft_${_isNewEmail ? 'new' : widget.email.id}';

  void _initializeForm() {
    final currentUser = (_gmailService.getUserEmail() ?? '').trim();
    final savedFrom = _settingsService
        .getChoice('default_from_address', fallback: currentUser)
        .trim()
        .toLowerCase();
    _selectedFromAddress = savedFrom.isNotEmpty ? savedFrom : currentUser;
    _selectedSignatureId = _gmailService.selectedSignatureId;
    _signatureController.text =
        _gmailService.getSignatureTemplates()['custom'] ?? '';

    if (_isNewEmail) {
      _loadDraftIfExists();
      return;
    }

    final decodedFrom = _gmailService.normalizeDisplayText(widget.email.from);
    final decodedSubject =
        _gmailService.normalizeDisplayText(widget.email.subject);
    final decodedCc = _gmailService.normalizeDisplayText(widget.email.cc);
    _toController.text = _extractEmail(decodedFrom);
    _subjectController.text = decodedSubject.startsWith('Re:')
        ? decodedSubject
        : 'Re: $decodedSubject';
    _ccController.text = decodedCc;
    _showCc = widget.email.cc.trim().isNotEmpty;
    _loadOriginalBody();
    _loadDraftIfExists();
  }

  void _loadDraftIfExists() {
    final raw =
        _settingsService.getChoice(_draftStorageKey, fallback: '').trim();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      _toController.text = (decoded['to'] as String? ?? '').trim();
      _ccController.text = (decoded['cc'] as String? ?? '').trim();
      _bccController.text = (decoded['bcc'] as String? ?? '').trim();
      _subjectController.text = (decoded['subject'] as String? ?? '').trim();
      _bodyController.text = (decoded['body'] as String? ?? '').trim();
      _summaryController.text = (decoded['summary'] as String? ?? '').trim();
      _showCc = decoded['showCc'] == true ||
          _ccController.text.isNotEmpty ||
          _bccController.text.isNotEmpty;
      final draftFrom = (decoded['from'] as String? ?? '').trim();
      if (draftFrom.isNotEmpty) {
        _selectedFromAddress = draftFrom.toLowerCase();
      }
      final draftSignatureId = (decoded['signatureId'] as String? ?? '').trim();
      if (_gmailService.getSignatureTemplates().containsKey(draftSignatureId)) {
        _selectedSignatureId = draftSignatureId;
      }
      _signatureController.text =
          (decoded['signatureCustom'] as String? ?? _signatureController.text)
              .trim();
    } catch (_) {
      // 下書きデータが壊れている場合は無視
    }
  }

  bool _hasMeaningfulInput() {
    return _toController.text.trim().isNotEmpty ||
        _ccController.text.trim().isNotEmpty ||
        _bccController.text.trim().isNotEmpty ||
        _subjectController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty ||
        _summaryController.text.trim().isNotEmpty;
  }

  Future<void> _saveLocalDraft() async {
    final payload = <String, dynamic>{
      'to': _toController.text.trim(),
      'cc': _ccController.text.trim(),
      'bcc': _bccController.text.trim(),
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trimRight(),
      'summary': _summaryController.text.trim(),
      'from': _selectedFromAddress.trim(),
      'signatureId': _selectedSignatureId,
      'signatureCustom': _signatureController.text.trim(),
      'showCc': _showCc,
      'savedAt': DateTime.now().toIso8601String(),
    };
    _settingsService.setChoice(_draftStorageKey, jsonEncode(payload));
  }

  Future<bool> _saveServerDraft() async {
    return _gmailService.saveDraft(
      from: _selectedFromAddress.trim().isEmpty
          ? null
          : _selectedFromAddress.trim(),
      to: _toController.text.trim(),
      cc: _ccController.text.trim(),
      bcc: _bccController.text.trim(),
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trimRight(),
    );
  }

  void _clearLocalDraft() {
    _settingsService.setChoice(_draftStorageKey, '');
  }

  Future<bool> _confirmCloseWithDraftOption() async {
    if (!_hasMeaningfulInput()) {
      return true;
    }

    final action = await showDialog<_ReplyCloseAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('下書きをどうしますか？'),
          content: const Text('編集中の返信内容があります。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, _ReplyCloseAction.cancel);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _ReplyCloseAction.discard);
              },
              child: const Text('破棄'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, _ReplyCloseAction.saveDraft);
              },
              child: const Text('下書き保存'),
            ),
          ],
        );
      },
    );

    if (action == _ReplyCloseAction.saveDraft) {
      final serverSaved = await _saveServerDraft();
      if (!serverSaved) {
        await _saveLocalDraft();
      } else {
        _clearLocalDraft();
      }
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serverSaved ? '下書きをサーバーに保存しました' : 'サーバー保存失敗のためローカルに保存しました',
          ),
        ),
      );
      return true;
    }

    if (action == _ReplyCloseAction.discard) {
      _clearLocalDraft();
      return true;
    }

    return false;
  }

  Future<void> _closeScreen() async {
    final shouldClose = await _confirmCloseWithDraftOption();
    if (!mounted || !shouldClose) return;
    Navigator.pop(context);
  }

  String _extractEmail(String from) {
    final match = RegExp(r'<(.+?)>').firstMatch(from);
    if (match != null) {
      return match.group(1) ?? from;
    }
    return from;
  }

  String _stripHtml(String source) {
    if (source.trim().isEmpty) return '';
    return source
        .replaceAll(
          RegExp(
            r'<style[^>]*>.*?</style>',
            caseSensitive: false,
            dotAll: true,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'&#x([0-9a-fA-F]+);'), '')
        .replaceAll(RegExp(r'&#([0-9]+);'), '')
        .replaceAll(
            RegExp(r'&zwnj;|&#8204;|&#x200C;', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'&amp;zwnj;|&amp;#8204;|&amp;#x200C;',
                caseSensitive: false),
            '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200b', '')
        .replaceAll(RegExp(r'(?:\s*&zwnj;\s*){2,}', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t\r\f\v]+'), ' ')
        .trim();
  }

  String _normalizedOriginalPreview(String input) {
    var text = input
        .replaceAll(
            RegExp(r'&zwnj;|&#8204;|&#x200C;', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'&amp;zwnj;|&amp;#8204;|&amp;#x200C;',
                caseSensitive: false),
            '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200b', '')
        .replaceAll(RegExp(r'(?:\s*&zwnj;\s*){2,}', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'([^\s]{80})(?=[^\s])'), r'$1 ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.length > 5000) {
      text = '${text.substring(0, 5000)}\n\n...（長文のため一部省略）';
    }
    return text;
  }

  Future<void> _loadOriginalBody() async {
    setState(() {
      _isLoadingOriginalBody = true;
    });

    try {
      var original = widget.email.body.trim();
      if (original.isEmpty && widget.email.id.isNotEmpty) {
        original = await _gmailService.fetchEmailBody(widget.email.id);
      }

      if (!mounted) return;
      setState(() {
        _originalBody = _stripHtml(original);
        _isLoadingOriginalBody = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _originalBody = '（元メール本文を取得できませんでした）';
        _isLoadingOriginalBody = false;
      });
    }
  }

  String _composeForSend() {
    final reply = _bodyController.text.trimRight();
    final signature = _resolvedSignatureText();
    final withSignature = signature.isEmpty ? reply : '$reply\n\n$signature';
    if (_isNewEmail) return withSignature;
    return '$withSignature\n\n${_quotedOriginalBlock()}';
  }

  String _resolvedSignatureText() {
    if (_selectedSignatureId == 'custom') {
      return _signatureController.text.trim();
    }
    return (_gmailService.getSignatureTemplates()[_selectedSignatureId] ?? '')
        .trim();
  }

  List<String> _fromOptions() {
    final items = <String>{
      ..._gmailService.getRegisteredEmails().map((e) => e.trim().toLowerCase())
    };
    final current = (_gmailService.getUserEmail() ?? '').trim().toLowerCase();
    final saved = _settingsService
        .getChoice('default_from_address', fallback: '')
        .trim()
        .toLowerCase();
    if (current.isNotEmpty) {
      items.add(current);
    }
    if (saved.isNotEmpty) {
      items.add(saved);
    }
    final selected = _selectedFromAddress.trim().toLowerCase();
    if (selected.isNotEmpty) {
      items.add(selected);
    }
    final list = items.where((item) => item.isNotEmpty).toList()..sort();
    return list;
  }

  void _onSignatureTemplateChanged(String? templateId) {
    if (templateId == null) return;
    setState(() {
      _selectedSignatureId = templateId;
    });
  }

  Future<void> _editFromAddress() async {
    final controller = TextEditingController(text: _selectedFromAddress);
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('差出人アドレスを変更'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'name@example.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      _selectedFromAddress = value.toLowerCase();
    });
    _settingsService.setChoice('default_from_address', _selectedFromAddress);
  }

  String _quotedOriginalBlock() {
    final senderLabel =
        _gmailService.normalizeDisplayText(widget.email.from.trim());
    final subjectLabel =
        _gmailService.normalizeDisplayText(widget.email.subject.trim());
    final dateLabel =
        DateFormat('yyyy/MM/dd HH:mm').format(widget.email.date.toLocal());
    final original = _originalBody.isEmpty
        ? '（本文なし）'
        : _normalizedOriginalPreview(_originalBody);
    return '''$dateLabel、$senderLabel のメール:

差出人: $senderLabel
件名: $subjectLabel
────────────────────
$original''';
  }

  Future<void> _generateAIReply() async {
    if (!_settingsService.isPlusSubscribed()) {
      await _openPlusUpgradeDialog();
      return;
    }
    if (!_settingsService.isAiEnabled()) {
      _settingsService.setAiEnabled(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VenemoAIを有効化しました')),
      );
    }

    if (_isNewEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新規作成では AI 返信は使えません')),
      );
      return;
    }

    setState(() {
      _isGeneratingAI = true;
    });

    try {
      if (_originalBody.isEmpty) {
        await _loadOriginalBody();
      }
      if (_originalBody.trim().isEmpty ||
          _originalBody.trim() == '（元メール本文を取得できませんでした）') {
        throw Exception('元メール本文が取得できないため返信文を生成できません');
      }

      final userSummary = _summaryController.text.trim();
      final personaSummary =
          userSummary.isNotEmpty ? userSummary : _buildPersonaSummaryForAI();
      final reply = await AIService.generateReply(
        _originalBody,
        userSummary: personaSummary.isEmpty ? null : personaSummary,
      );

      if (reply == null || reply.trim().isEmpty) {
        throw Exception(AIService.lastError ?? '返信を生成できませんでした');
      }

      if (!mounted) return;
      setState(() {
        _bodyController.text = reply.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            personaSummary.isEmpty ? 'AIで返信文を作成しました' : 'プロフィールを反映して返信文を作成しました',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI生成に失敗しました: ${_aiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
        });
      }
    }
  }

  String _aiErrorMessage(Object error) {
    final last = AIService.lastError;
    if (last != null && last.trim().isNotEmpty) {
      return last.trim();
    }
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  Future<void> _generateAiSummary() async {
    if (!_settingsService.isPlusSubscribed()) {
      await _openPlusUpgradeDialog();
      return;
    }
    if (!_settingsService.isAiEnabled()) {
      _settingsService.setAiEnabled(true);
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      if (_originalBody.trim().isEmpty) {
        await _loadOriginalBody();
      }
      final source = _originalBody.trim();
      if (source.isEmpty || source == '（元メール本文を取得できませんでした）') {
        throw Exception('元メール本文が取得できないため要約できません');
      }

      final prompt = '''
以下のメール本文を、返信方針として使える短い要約にしてください。

要件:
- 日本語
- 40〜70文字程度
- 余計な前置きなし

本文:
$source
''';

      final summary = await _aiService.generateText(prompt);
      if (!mounted) return;
      setState(() {
        _summaryController.text = summary.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI要約を作成しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI要約に失敗しました: ${_aiErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
      }
    }
  }

  String _buildPersonaSummaryForAI() {
    final purpose =
        _settingsService.getChoice('onboarding_purpose', fallback: '');
    final job = _settingsService.getChoice('onboarding_job', fallback: '');
    final role = _settingsService.getChoice('onboarding_role', fallback: '');
    final teamSize =
        _settingsService.getChoice('onboarding_team_size', fallback: '');
    final pain = _settingsService.getChoice('onboarding_pain', fallback: '');
    final goals = _settingsService.getStringList('onboarding_goals');
    final hint = _settingsService.getChoice('onboarding_ai_hint', fallback: '');

    final lines = <String>[];
    if (purpose.isNotEmpty) lines.add('利用目的: $purpose');
    if (job.isNotEmpty) lines.add('職種: $job');
    if (role.isNotEmpty) lines.add('立場: $role');
    if (teamSize.isNotEmpty) lines.add('チーム規模: $teamSize');
    if (pain.isNotEmpty) lines.add('困りごと: $pain');
    if (goals.isNotEmpty) lines.add('重視すること: ${goals.join(' / ')}');
    if (hint.isNotEmpty) lines.add('運用ヒント: $hint');
    return lines.join('\n');
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'application/octet-stream';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _pickAttachments({bool imageOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly
          ? null
          : const [
              'pdf',
              'ppt',
              'pptx',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'jpg',
              'jpeg',
              'png',
              'gif',
              'heic',
              'txt',
              'zip',
            ],
    );
    if (result == null || !mounted) return;

    final picked = <EmailAttachment>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      picked.add(
        EmailAttachment(
          fileName: file.name,
          mimeType: _guessMimeType(file.name),
          bytes: bytes,
        ),
      );
    }
    if (picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('添付できるファイルが見つかりませんでした')),
      );
      return;
    }

    setState(() {
      for (final file in picked) {
        final exists = _attachments.any(
          (item) =>
              item.fileName == file.fileName &&
              item.sizeBytes == file.sizeBytes,
        );
        if (!exists) _attachments.add(file);
      }
    });
  }

  void _removeAttachmentAt(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _changeBodyFontSize(double delta) {
    setState(() {
      _bodyFontSize = (_bodyFontSize + delta).clamp(12, 22);
    });
  }

  String _toHexColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _escapeHtml(String source) {
    return source
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _composeHtmlBody(String plainText) {
    final escaped = _escapeHtml(plainText).replaceAll('\n', '<br>');
    final colorHex = _toHexColor(_bodyTextColor);
    final fontSize = _bodyFontSize.toStringAsFixed(0);
    return '<div style="font-family:-apple-system, BlinkMacSystemFont, \'Helvetica Neue\', sans-serif; '
        'font-size:${fontSize}px; line-height:1.6; color:$colorHex;">$escaped</div>';
  }

  Future<void> _sendEmail() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _composeForSend().trim();
    final bodyHtml = _composeHtmlBody(body);
    final fromAddress = _selectedFromAddress.trim().toLowerCase();

    if (to.isEmpty || subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('宛先・件名・本文を入力してください')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      if (fromAddress.isNotEmpty) {
        _settingsService.setChoice('default_from_address', fromAddress);
      }
      if (_selectedSignatureId == 'custom') {
        _gmailService.setEmailSignature(_signatureController.text);
      } else {
        _gmailService.setSelectedSignatureTemplate(_selectedSignatureId);
      }
      final success = await _gmailService.sendEmail(
        from: fromAddress.isEmpty ? null : fromAddress,
        to: to,
        cc: _ccController.text.trim().isEmpty
            ? null
            : _ccController.text.trim(),
        bcc: _bccController.text.trim().isEmpty
            ? null
            : _bccController.text.trim(),
        subject: subject,
        body: body,
        bodyHtml: bodyHtml,
        inReplyTo: !_isNewEmail ? widget.email.id : null,
        attachments: _attachments,
      );

      if (!mounted) return;
      if (success) {
        _clearLocalDraft();
        if (!_isNewEmail &&
            _settingsService.getSwitch('返信時に「完了」としてマーク', fallback: false)) {
          await _gmailService.markAsRead(widget.email.id);
          if (!mounted) return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メールを送信しました')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('送信に失敗しました')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信エラー: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _headerInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    Widget? trailing,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: _sub,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
              ),
              style: const TextStyle(
                color: _text,
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (trailing != null) const SizedBox(width: 10),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _aiActionButton({
    required bool isPlus,
    required bool aiEnabled,
    required bool aiPrimaryEnabled,
  }) {
    return SizedBox(
      height: 42,
      child: FilledButton.tonalIcon(
        onPressed: _isGeneratingAI ? null : _generateAIReply,
        style: FilledButton.styleFrom(
          backgroundColor: aiPrimaryEnabled
              ? const Color(0x12007AFF)
              : const Color(0xFFF2F4F7),
          foregroundColor: aiPrimaryEnabled ? _accent : _sub,
          minimumSize: const Size(126, 42),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _line),
          ),
        ),
        icon: _isGeneratingAI
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isPlus
                    ? Icons.auto_awesome_rounded
                    : Icons.lock_outline_rounded,
                size: 17,
              ),
        label: Text(
          isPlus ? (aiEnabled ? 'AI返信作成' : 'AI無効') : 'Plus限定',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sender = _selectedFromAddress.trim().isNotEmpty
        ? _selectedFromAddress.trim()
        : (_gmailService.getUserEmail() ?? 'me@example.com');
    final isPlus = _settingsService.isPlusSubscribed();
    final aiEnabled = _settingsService.isAiEnabled();
    final aiPrimaryEnabled = isPlus && aiEnabled;
    final fromOptions = _fromOptions();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _closeScreen();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: _panel,
                  border: Border(bottom: BorderSide(color: _line)),
                ),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.close_rounded,
                      onTap: _closeScreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _aiActionButton(
                      isPlus: isPlus,
                      aiEnabled: aiEnabled,
                      aiPrimaryEnabled: aiPrimaryEnabled,
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _isSending ? null : _sendEmail,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(46, 46),
                        maximumSize: const Size(46, 46),
                        shape: const CircleBorder(),
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Container(
                color: _panel,
                child: Column(
                  children: [
                    _headerInput(
                      label: '宛先',
                      controller: _toController,
                      hint: 'example@domain.com',
                      trailing: OutlinedButton(
                        onPressed: () => setState(() => _showCc = !_showCc),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(86, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(color: Color(0x33007AFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _showCc ? 'Cc/Bccを閉じる' : 'Cc/Bcc',
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_showCc)
                      _headerInput(
                        label: 'Cc',
                        controller: _ccController,
                        hint: 'Ccを追加',
                      ),
                    if (_showCc)
                      _headerInput(
                        label: 'Bcc',
                        controller: _bccController,
                        hint: 'Bccを追加',
                      ),
                    _headerInput(
                      label: '件名',
                      controller: _subjectController,
                      hint: '件名',
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _line)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 72,
                            child: Text(
                              '差出人',
                              style: TextStyle(
                                color: _sub,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey<String>(
                                  'reply-from-$_selectedFromAddress'),
                              initialValue: _selectedFromAddress.isEmpty
                                  ? null
                                  : _selectedFromAddress,
                              items: fromOptions
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry,
                                      child: Text(entry),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isSending || _isGeneratingAI
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedFromAddress = value;
                                      });
                                    },
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '差出人を編集',
                            onPressed: _isSending || _isGeneratingAI
                                ? null
                                : _editFromAddress,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '署名:',
                            style: TextStyle(
                              color: _sub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey<String>(
                                  'reply-signature-$_selectedSignatureId'),
                              initialValue: _selectedSignatureId,
                              items: _gmailService
                                  .getSignatureTemplateOptions()
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isSending || _isGeneratingAI
                                  ? null
                                  : _onSignatureTemplateChanged,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedSignatureId == 'custom')
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _line)),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: TextField(
                          controller: _signatureController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'カスタム署名',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _line)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 82,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'AI要約:',
                                    style: TextStyle(
                                      color: _sub,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 32,
                                  child: FilledButton.tonal(
                                    onPressed: _isGeneratingSummary
                                        ? null
                                        : (isPlus
                                            ? _generateAiSummary
                                            : _openPlusUpgradeDialog),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isPlus
                                          ? const Color(0xFFEAF7F1)
                                          : const Color(0xFFF2F2F7),
                                      foregroundColor: isPlus ? _accent : _sub,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 0,
                                      ),
                                      minimumSize: const Size(74, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: _line),
                                      ),
                                    ),
                                    child: _isGeneratingSummary
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPlus
                                                    ? Icons.auto_awesome_rounded
                                                    : Icons
                                                        .lock_outline_rounded,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isPlus ? '実行' : 'Plus',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPlus
                                    ? _summaryBg
                                    : const Color(0xFFF4F4F6),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: _summaryBorder),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: TextField(
                                controller: _summaryController,
                                maxLines: 2,
                                enabled: isPlus,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '例: 丁寧に断る。次回提案のみ依頼。',
                                  hintStyle:
                                      TextStyle(color: Color(0xFF6F7F92)),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _text,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: _panel,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _line)),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _toolbarButton(
                              icon: Icons.attach_file_rounded,
                              label: '添付',
                              onTap: (_isSending || _isGeneratingAI)
                                  ? null
                                  : () => _pickAttachments(),
                            ),
                            _toolbarButton(
                              icon: Icons.image_outlined,
                              label: '画像',
                              onTap: (_isSending || _isGeneratingAI)
                                  ? null
                                  : () => _pickAttachments(imageOnly: true),
                            ),
                            _toolbarButton(
                              icon: Icons.text_decrease_rounded,
                              label: 'A-',
                              onTap: (_isSending || _isGeneratingAI)
                                  ? null
                                  : () => _changeBodyFontSize(-1),
                            ),
                            _toolbarButton(
                              icon: Icons.text_increase_rounded,
                              label: 'A+',
                              onTap: (_isSending || _isGeneratingAI)
                                  ? null
                                  : () => _changeBodyFontSize(1),
                            ),
                            _textColorPickerButton(
                              disabled: _isSending || _isGeneratingAI,
                            ),
                            Chip(
                              label: Text(
                                '${_bodyFontSize.toStringAsFixed(0)}px',
                                style: const TextStyle(fontSize: 12),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      if (_attachments.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: _line)),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                List.generate(_attachments.length, (index) {
                              final file = _attachments[index];
                              return InputChip(
                                avatar: const Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  '${file.fileName} (${_formatFileSize(file.sizeBytes)})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onDeleted: _isSending
                                    ? null
                                    : () => _removeAttachmentAt(index),
                              );
                            }),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                          child: TextField(
                            controller: _bodyController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: '本文を入力してください',
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontSize: _bodyFontSize,
                              color: _bodyTextColor,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                      if (!_isNewEmail)
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _line),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            title: const Text(
                              '元メールを表示',
                              style: TextStyle(
                                fontSize: 13,
                                color: _sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              _isLoadingOriginalBody
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxHeight: 140),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          child: SelectableText(
                                            _quotedOriginalBlock(),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: _text,
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(84, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        side: const BorderSide(color: Color(0x22000000)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _textColorPickerButton({required bool disabled}) {
    return PopupMenuButton<Color>(
      enabled: !disabled,
      tooltip: '文字色',
      onSelected: (color) {
        setState(() {
          _bodyTextColor = color;
        });
      },
      itemBuilder: (context) {
        return _textColorOptions
            .map(
              (option) => PopupMenuItem<Color>(
                value: option.color,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: option.color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x22000000)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x22000000)),
            color: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _bodyTextColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0x22000000)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '文字色',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _line),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 19, color: _sub),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _openPlusUpgradeDialog() async {
    final price = _settingsService.plusMonthlyPriceYen();
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Venemo Plusが必要です'),
          content: Text('AI返信はVenemo Plus（月額¥$price）で利用できます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('あとで'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('アップグレード'),
            ),
          ],
        );
      },
    );

    if (upgrade != true || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VenemoPlusScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }
}
