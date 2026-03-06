// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
  late String _viewId;
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
      _viewId = 'email-body-${widget.emailId}';
      _registerHtmlView();
    }
  }

  void _registerHtmlView() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..srcdoc = _wrapHtmlContent(widget.emailBody);
        return iframe;
      },
    );
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

    return HtmlElementView(viewType: _viewId);
  }
}
