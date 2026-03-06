import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class HtmlPreviewView extends StatefulWidget {
  final String htmlContent;
  final String plainFallback;
  final String viewId;
  final EdgeInsetsGeometry padding;

  const HtmlPreviewView({
    super.key,
    required this.htmlContent,
    this.plainFallback = '',
    required this.viewId,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<HtmlPreviewView> createState() => _HtmlPreviewViewState();
}

class _HtmlPreviewViewState extends State<HtmlPreviewView> {
  static final Set<String> _registeredTypes = <String>{};
  static final Map<String, html.IFrameElement> _frames =
      <String, html.IFrameElement>{};

  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'venemo-html-preview-${widget.viewId.hashCode.abs()}-${DateTime.now().microsecondsSinceEpoch}';
    _registerIfNeeded(_viewType);
    _updateFrameHtml();
  }

  @override
  void didUpdateWidget(covariant HtmlPreviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent ||
        oldWidget.plainFallback != widget.plainFallback) {
      _updateFrameHtml();
    }
  }

  void _registerIfNeeded(String viewType) {
    if (_registeredTypes.contains(viewType)) {
      return;
    }

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      return _frames.putIfAbsent(viewType, () => _createFrame());
    });
    _registeredTypes.add(viewType);
  }

  html.IFrameElement _createFrame() {
    final frame = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#FFFFFF';
    frame.setAttribute(
      'sandbox',
      'allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-top-navigation-by-user-activation',
    );
    return frame;
  }

  void _updateFrameHtml() {
    final frame = _frames.putIfAbsent(_viewType, () => _createFrame());
    try {
      final safeSource = _sanitize(widget.htmlContent);
      final renderableHtml = _extractRenderableHtml(safeSource);
      frame.srcdoc = _buildDocument(renderableHtml);
    } catch (_) {
      frame.srcdoc = _buildDocument(_fallbackHtml());
    }
  }

  String _sanitize(String source) {
    var text = source;
    text = text.replaceAll(
      RegExp(
        r'<script[^>]*>.*?</script>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'<iframe[^>]*>.*?</iframe>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'<object[^>]*>.*?</object>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'<embed[^>]*>',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(r'on[a-z]+\s*=\s*"[^"]*"', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r"on[a-z]+\s*=\s*'[^']*'", caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'on[a-z]+\s*=\s*[^\s>]+', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\sstyle\s*=\s*"[^"]*"', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r"\sstyle\s*=\s*'[^']*'", caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\sclass\s*=\s*"[^"]*"', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r"\sclass\s*=\s*'[^']*'", caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\shidden(\s|>|/)', caseSensitive: false),
      ' ',
    );
    text = text.replaceAll(
      RegExp(r'\saria-hidden\s*=\s*"true"', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r"\saria-hidden\s*=\s*'true'", caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
      '',
    );
    text = text.replaceAllMapped(
      RegExp(
        r'''(href|src)\s*=\s*(["'])\s*javascript:[^"']*\2''',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}="#"',
    );
    return text;
  }

  String _extractRenderableHtml(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return _fallbackHtml();
    }

    String cleanup(String value) {
      return value
          .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ')
          .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
            ' ',
          )
          .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
            ' ',
          )
          .trim();
    }

    final bodyMatch = RegExp(
      r'<body[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (bodyMatch != null) {
      final bodyOnly = cleanup(bodyMatch.group(1) ?? '');
      if (bodyOnly.isNotEmpty && _hasVisibleContent(bodyOnly)) {
        return bodyOnly;
      }
    }

    final stripped = cleanup(trimmed
        .replaceAll(RegExp(r'<!doctype[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<html[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</html>', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'<head[^>]*>[\s\S]*?</head>', caseSensitive: false),
          '',
        ));
    if (stripped.isEmpty || !_hasVisibleContent(stripped)) {
      return _fallbackHtml();
    }
    return stripped;
  }

  String _fallbackHtml() {
    final plain = widget.plainFallback.trim();
    if (plain.isEmpty) {
      return '<p style="color:#6E6E73;">HTML本文がありません</p>';
    }
    final escaped = _escapeHtml(plain).replaceAll('\n', '<br/>');
    return '<div>$escaped</div>';
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  bool _hasVisibleContent(String html) {
    if (RegExp(r'''<img[^>]+src=['"]https?://''', caseSensitive: false)
        .hasMatch(html)) {
      return true;
    }
    if (RegExp(r'''<img[^>]+src=['"]cid:''', caseSensitive: false)
        .hasMatch(html)) {
      return true;
    }
    final plain = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(
            RegExp(r'&zwnj;|&#8204;|&#x200C;', caseSensitive: false), '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200b', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return plain.length > 2;
  }

  String _buildDocument(String htmlContent) {
    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html, body {
      margin: 0;
      padding: 0;
      background: #FFFFFF;
      color: #1D1D1F;
      font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
      font-size: 14px;
      line-height: 1.55;
      word-break: break-word;
    }
    body {
      padding: 16px;
    }
    *, *::before, *::after {
      box-sizing: border-box;
      max-width: 100%;
      color: inherit !important;
    }
    img {
      max-width: 100%;
      height: auto;
    }
    table {
      max-width: 100% !important;
      width: 100% !important;
      border-collapse: collapse;
    }
    a {
      color: #007AFF !important;
    }
    blockquote {
      margin: 0;
      padding-left: 12px;
      border-left: 2px solid rgba(0,0,0,0.12);
      color: #6E6E73;
    }
  </style>
</head>
<body>
  $htmlContent
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.white,
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
