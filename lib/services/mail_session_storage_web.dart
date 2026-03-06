import 'dart:html' as html;

const String _mailSessionStorageKey = 'venemo_mail_session_v1';

String? readMailSessionJson() {
  final raw = html.window.localStorage[_mailSessionStorageKey];
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return raw;
}

void writeMailSessionJson(String jsonText) {
  final raw = jsonText.trim();
  if (raw.isEmpty) {
    html.window.localStorage.remove(_mailSessionStorageKey);
    return;
  }
  html.window.localStorage[_mailSessionStorageKey] = raw;
}
