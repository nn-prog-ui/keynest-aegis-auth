import 'package:flutter/material.dart';

class HtmlPreviewView extends StatelessWidget {
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

  String _toPlainText(String source) {
    return source
        .replaceAll(
            RegExp(r'<style[^>]*>.*?</style>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<script[^>]*>.*?</script>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final resolved =
        htmlContent.trim().isNotEmpty ? htmlContent : plainFallback;
    return SingleChildScrollView(
      padding: padding,
      child: SelectableText(
        _toPlainText(resolved),
        style: const TextStyle(
          height: 1.55,
          fontSize: 14,
          color: Color(0xFF1D1D1F),
        ),
      ),
    );
  }
}
