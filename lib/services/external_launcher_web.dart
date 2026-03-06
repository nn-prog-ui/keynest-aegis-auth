import 'dart:html' as html;

Future<bool> openExternalUrl(String url) async {
  final value = url.trim();
  if (value.isEmpty) {
    return false;
  }
  html.window.open(value, '_self');
  return true;
}
