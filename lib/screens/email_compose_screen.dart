import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/email_attachment.dart';
import '../services/gmail_service.dart';
import '../services/ai_service.dart'; // 🔧 追加
import '../services/app_settings_service.dart';
import '../theme/venemo_design.dart';
import 'venemo_plus_screen.dart';

class _ComposeTextColorOption {
  final String label;
  final Color color;

  const _ComposeTextColorOption(this.label, this.color);
}

class EmailComposeScreen extends StatefulWidget {
  final String initialTo;
  final String initialCc;
  final String initialBcc;
  final String initialSubject;
  final String initialBody;

  const EmailComposeScreen({
    super.key,
    this.initialTo = '',
    this.initialCc = '',
    this.initialBcc = '',
    this.initialSubject = '',
    this.initialBody = '',
  });

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  static const Color _defaultBodyTextColor = Color(0xFF1D1D1F);
  static const List<_ComposeTextColorOption> _textColorOptions = [
    _ComposeTextColorOption('標準（黒）', _defaultBodyTextColor),
    _ComposeTextColorOption('ブルー', Color(0xFF007AFF)),
    _ComposeTextColorOption('グリーン', Color(0xFF2E7D32)),
    _ComposeTextColorOption('レッド', Color(0xFFC62828)),
    _ComposeTextColorOption('オレンジ', Color(0xFFEF6C00)),
    _ComposeTextColorOption('パープル', Color(0xFF6A1B9A)),
    _ComposeTextColorOption('グレー', Color(0xFF616161)),
  ];

  final GmailService _gmailService = GmailService();
  final AIService _aiService = AIService(); // 🔧 追加
  final AppSettingsService _settingsService = AppSettingsService();
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _signatureController = TextEditingController();
  final FocusNode _toFocusNode = FocusNode();
  final FocusNode _ccFocusNode = FocusNode();
  final FocusNode _bccFocusNode = FocusNode();
  final List<EmailAttachment> _attachments = [];
  List<String> _toSuggestions = const <String>[];
  List<String> _ccSuggestions = const <String>[];
  List<String> _bccSuggestions = const <String>[];
  bool _isSending = false;
  bool _showBcc = false;
  bool _isAIGenerating = false;
  double _bodyFontSize = 15;
  Color _bodyTextColor = _defaultBodyTextColor;
  String _selectedFromAddress = '';
  String _selectedSignatureId = 'custom';

  String _aiErrorMessage(Object error) {
    final last = AIService.lastError;
    if (last != null && last.trim().isNotEmpty) {
      return last.trim();
    }
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    return raw.isEmpty ? 'AI生成に失敗しました' : raw;
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultSignature();
    _toController.addListener(() => _refreshRecipientSuggestions('to'));
    _ccController.addListener(() => _refreshRecipientSuggestions('cc'));
    _bccController.addListener(() => _refreshRecipientSuggestions('bcc'));
    _toFocusNode.addListener(() => _refreshRecipientSuggestions('to'));
    _ccFocusNode.addListener(() => _refreshRecipientSuggestions('cc'));
    _bccFocusNode.addListener(() => _refreshRecipientSuggestions('bcc'));
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _signatureController.dispose();
    _toFocusNode.dispose();
    _ccFocusNode.dispose();
    _bccFocusNode.dispose();
    super.dispose();
  }

  void _loadDefaultSignature() {
    final currentUser = _gmailService.getUserEmail()?.trim() ?? '';
    final savedFrom = _settingsService
        .getChoice('default_from_address', fallback: currentUser)
        .trim()
        .toLowerCase();
    _selectedFromAddress = savedFrom.isNotEmpty ? savedFrom : currentUser;
    _selectedSignatureId = _gmailService.selectedSignatureId;
    _signatureController.text =
        _gmailService.getEmailSignature(withFallback: false);

    _toController.text = widget.initialTo;
    _ccController.text = widget.initialCc;
    _bccController.text = widget.initialBcc;
    _subjectController.text = widget.initialSubject;
    _bodyController.text = widget.initialBody;
    _showBcc = widget.initialBcc.trim().isNotEmpty;
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
    final list = items.where((value) => value.trim().isNotEmpty).toList()
      ..sort();
    return list;
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

  String _currentAddressToken(String raw) {
    final parts = raw.split(',');
    return parts.isEmpty ? raw.trim() : parts.last.trim();
  }

  Set<String> _selectedAddresses(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.contains('@'))
        .toSet();
  }

  void _refreshRecipientSuggestions(String field) {
    if (!mounted) return;
    TextEditingController controller;
    FocusNode focusNode;
    List<String> Function() current;
    void Function(List<String>) assign;

    switch (field) {
      case 'cc':
        controller = _ccController;
        focusNode = _ccFocusNode;
        current = () => _ccSuggestions;
        assign = (items) => _ccSuggestions = items;
        break;
      case 'bcc':
        controller = _bccController;
        focusNode = _bccFocusNode;
        current = () => _bccSuggestions;
        assign = (items) => _bccSuggestions = items;
        break;
      case 'to':
      default:
        controller = _toController;
        focusNode = _toFocusNode;
        current = () => _toSuggestions;
        assign = (items) => _toSuggestions = items;
        break;
    }

    if (!focusNode.hasFocus) {
      if (current().isNotEmpty) {
        setState(() => assign(const <String>[]));
      }
      return;
    }

    final token = _currentAddressToken(controller.text);
    final selected = _selectedAddresses(controller.text);
    final suggestions = _gmailService
        .getRecipientSuggestions(query: token, limit: 8)
        .where((item) => !selected.contains(item.toLowerCase()))
        .toList();
    final hasChanged = suggestions.join('|') != current().join('|');
    if (hasChanged) {
      setState(() => assign(suggestions));
    }
  }

  void _applySuggestion({
    required String field,
    required String suggestion,
  }) {
    TextEditingController controller;
    FocusNode focusNode;
    void Function(List<String>) assign;

    switch (field) {
      case 'cc':
        controller = _ccController;
        focusNode = _ccFocusNode;
        assign = (items) => _ccSuggestions = items;
        break;
      case 'bcc':
        controller = _bccController;
        focusNode = _bccFocusNode;
        assign = (items) => _bccSuggestions = items;
        break;
      case 'to':
      default:
        controller = _toController;
        focusNode = _toFocusNode;
        assign = (items) => _toSuggestions = items;
        break;
    }

    final parts = controller.text.split(',');
    if (parts.isEmpty) {
      controller.text = '$suggestion, ';
    } else {
      parts[parts.length - 1] = ' $suggestion';
      final merged = parts
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .join(', ');
      controller.text = '$merged, ';
    }
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    _gmailService.rememberRecipientCandidates(suggestion);
    setState(() => assign(const <String>[]));
    FocusScope.of(context).requestFocus(focusNode);
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

  void _onSignatureTemplateChanged(String? templateId) {
    if (templateId == null) return;
    final templates = _gmailService.getSignatureTemplates();
    setState(() {
      _selectedSignatureId = templateId;
      _signatureController.text = (templates[templateId] ?? '').trim();
    });
    _gmailService.setSelectedSignatureTemplate(templateId);
    if (templateId == 'custom') {
      _gmailService.setEmailSignature(_signatureController.text);
    }
  }

  // 🔧 追加: AI補完機能
  Future<void> _generateWithAI() async {
    if (!_settingsService.isPlusSubscribed()) {
      await _showPlusUpgradeDialog();
      return;
    }
    if (!_settingsService.isAiEnabled()) {
      _settingsService.setAiEnabled(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VenemoAIを有効化しました')),
      );
    }

    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (subject.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('件名または本文の一部を入力してください')),
      );
      return;
    }

    setState(() {
      _isAIGenerating = true;
    });

    try {
      String prompt;
      if (subject.isNotEmpty && body.isEmpty) {
        // 件名からメール本文を生成
        prompt = '''
以下の件名に適したビジネスメールの本文を日本語で作成してください。
件名: $subject

要件:
- 丁寧で簡潔なビジネスメール
- 適切な挨拶と結びの言葉を含める
- 300文字程度
''';
      } else if (body.isNotEmpty) {
        // 本文を改善・補完
        prompt = '''
以下のメール本文を改善してください。

現在の本文:
$body

要件:
- より丁寧で読みやすい表現に改善
- ビジネスメールとして適切な形式
- 文法や表現の誤りを修正
''';
      } else {
        setState(() {
          _isAIGenerating = false;
        });
        return;
      }

      final result = await _aiService.generateText(prompt);

      if (mounted) {
        setState(() {
          _bodyController.text = result;
          _isAIGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AIがメール本文を生成しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAIGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI生成エラー: ${_aiErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (result == null) return;

    final picked = <EmailAttachment>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }
      picked.add(
        EmailAttachment(
          fileName: file.name,
          mimeType: _guessMimeType(file.name),
          bytes: bytes,
        ),
      );
    }

    if (!mounted) return;
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
        if (!exists) {
          _attachments.add(file);
        }
      }
    });
  }

  void _removeAttachmentAt(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _sendEmail() async {
    final to = _toController.text.trim();
    final cc = _ccController.text.trim();
    final bcc = _bccController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    final signature = _signatureController.text.trim();
    final fromAddress = _selectedFromAddress.trim().toLowerCase();

    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('宛先を入力してください')),
      );
      return;
    }

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('件名を入力してください')),
      );
      return;
    }

    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本文を入力してください')),
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
        _gmailService.setEmailSignature(signature);
      } else {
        _gmailService.setSelectedSignatureTemplate(_selectedSignatureId);
      }
      final fullBody = signature.isNotEmpty ? '$body\n\n$signature' : body;
      final fullBodyHtml = _composeHtmlBody(fullBody);

      final success = await _gmailService.sendEmail(
        from: fromAddress.isEmpty ? null : fromAddress,
        to: to,
        subject: subject,
        body: fullBody, // 🔧 修正
        bodyHtml: fullBodyHtml,
        cc: cc.isNotEmpty ? cc : null,
        bcc: bcc.isNotEmpty ? bcc : null,
        attachments: _attachments,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メールを送信しました')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('メールの送信に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = _settingsService.isPlusSubscribed();
    final aiEnabled = _settingsService.isAiEnabled();
    final fromOptions = _fromOptions();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('新規メール'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: FilledButton.tonalIcon(
              onPressed:
                  (_isSending || _isAIGenerating) ? null : _generateWithAI,
              icon: _isAIGenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isPlus ? Icons.auto_awesome_rounded : Icons.lock_rounded,
                    ),
              label: Text(
                _isAIGenerating
                    ? '生成中'
                    : isPlus
                        ? (aiEnabled ? 'AI作成' : 'AI無効')
                        : 'Plus限定',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEFF3F8),
                foregroundColor: VenemoPalette.textMain,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          if (_isSending)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.attach_file_rounded),
              onPressed:
                  (_isSending || _isAIGenerating) ? null : _pickAttachments,
              tooltip: '添付',
            ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSending ? null : _sendEmail,
            tooltip: '送信',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x14000000)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _addressInputField(
                        label: '宛先',
                        hintText: 'example@gmail.com',
                        controller: _toController,
                        focusNode: _toFocusNode,
                        field: 'to',
                        suggestions: _toSuggestions,
                      ),
                      const SizedBox(height: 12),
                      _addressInputField(
                        label: 'CC',
                        hintText: 'cc1@example.com, cc2@example.com',
                        controller: _ccController,
                        focusNode: _ccFocusNode,
                        field: 'cc',
                        suggestions: _ccSuggestions,
                        trailing: TextButton(
                          onPressed: () {
                            setState(() {
                              _showBcc = !_showBcc;
                            });
                          },
                          child: Text(
                            _showBcc ? 'BCC非表示' : 'BCC表示',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_showBcc) ...[
                        _addressInputField(
                          label: 'BCC',
                          hintText: 'bcc1@example.com, bcc2@example.com',
                          controller: _bccController,
                          focusNode: _bccFocusNode,
                          field: 'bcc',
                          suggestions: _bccSuggestions,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: '件名',
                        ),
                        enabled: !_isSending,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(
                            width: 74,
                            child: Text(
                              '差出人',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E6E73),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey<String>(
                                  'compose-from-$_selectedFromAddress'),
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
                              onChanged: _isSending || _isAIGenerating
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
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: '差出人を編集',
                            onPressed: _isSending || _isAIGenerating
                                ? null
                                : _editFromAddress,
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 42,
                            child: Text(
                              '署名',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E6E73),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey<String>(
                                  'compose-signature-$_selectedSignatureId'),
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
                              onChanged: _isSending || _isAIGenerating
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x14000000)),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _toolbarButton(
                              icon: Icons.attach_file_rounded,
                              label: '添付',
                              onTap: (_isSending || _isAIGenerating)
                                  ? null
                                  : () => _pickAttachments(),
                            ),
                            _toolbarButton(
                              icon: Icons.image_outlined,
                              label: '画像',
                              onTap: (_isSending || _isAIGenerating)
                                  ? null
                                  : () => _pickAttachments(imageOnly: true),
                            ),
                            _toolbarButton(
                              icon: Icons.text_decrease_rounded,
                              label: 'A-',
                              onTap: (_isSending || _isAIGenerating)
                                  ? null
                                  : () => _changeBodyFontSize(-1),
                            ),
                            _toolbarButton(
                              icon: Icons.text_increase_rounded,
                              label: 'A+',
                              onTap: (_isSending || _isAIGenerating)
                                  ? null
                                  : () => _changeBodyFontSize(1),
                            ),
                            _textColorPickerButton(
                              disabled: _isSending || _isAIGenerating,
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
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_attachments.length, (index) {
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
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _bodyController,
                          decoration: const InputDecoration(
                            labelText: '本文',
                            alignLabelWithHint: true,
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          enabled: !_isSending,
                          style: TextStyle(
                            fontSize: _bodyFontSize,
                            color: _bodyTextColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _signatureController,
                        decoration: const InputDecoration(
                          labelText: '署名本文',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        enabled:
                            !_isSending && _selectedSignatureId == 'custom',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String field,
    required List<String> suggestions,
    Widget? trailing,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixIcon: trailing == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [trailing],
                  ),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !_isSending,
        ),
        if (suggestions.isNotEmpty && focusNode.hasFocus)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x22000000)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x11000000)),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return InkWell(
                    onTap: () =>
                        _applySuggestion(field: field, suggestion: item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
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

  Future<void> _showPlusUpgradeDialog() async {
    final price = _settingsService.plusMonthlyPriceYen();
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Venemo Plusが必要です'),
          content: Text('AI作成はVenemo Plus（月額¥$price）で利用できます。'),
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
