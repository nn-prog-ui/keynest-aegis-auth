import 'dart:html' as html;

const String _signatureStorageKey = 'venemo_email_signature';

String? readSignature() {
  final value = html.window.localStorage[_signatureStorageKey];
  if (value == null) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void writeSignature(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    html.window.localStorage.remove(_signatureStorageKey);
    return;
  }
  html.window.localStorage[_signatureStorageKey] = trimmed;
}
