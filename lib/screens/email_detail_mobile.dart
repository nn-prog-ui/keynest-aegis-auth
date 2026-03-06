import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmailBodyWidget extends StatefulWidget {
  final String emailBody;
  final String emailId;

  const EmailBodyWidget({
    super.key,
    required this.emailBody,
    required this.emailId,
  });

  @override
  State<EmailBodyWidget> createState() => _EmailBodyWidgetState();
}

class _EmailBodyWidgetState extends State<EmailBodyWidget> {
  late final WebViewController? _controller;
  bool _isHtmlContent = false;

  @override
  void initState() {
    super.initState();
    
    // HTMLコンテンツかどうかを判定
    _isHtmlContent = widget.emailBody.contains('<html') || 
                      widget.emailBody.contains('<body') ||
                      widget.emailBody.contains('<div') ||
                      widget.emailBody.contains('<p>') ||
                      widget.emailBody.contains('<img');

    if (_isHtmlContent) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..loadHtmlString(_wrapHtmlContent(widget.emailBody));
    } else {
      _controller = null;
    }
  }

  String _wrapHtmlContent(String htmlContent) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
          font-size: 16px;
          line-height: 1.6;
          color: #333;
          padding: 16px;
          margin: 0;
        }
        img {
          max-width: 100%;
          height: auto;
        }
        table {
          max-width: 100%;
          border-collapse: collapse;
        }
        a {
          color: #FF6F00;
          text-decoration: none;
        }
        a:hover {
          text-decoration: underline;
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
    if (!_isHtmlContent) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          widget.emailBody,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      );
    }

    if (_controller != null) {
      return WebViewWidget(controller: _controller!);
    } else {
      return const Center(
        child: Text('メール本文を読み込めませんでした'),
      );
    }
  }
}