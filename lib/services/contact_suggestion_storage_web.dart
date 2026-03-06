import 'dart:html' as html;

const String _knownContactsStorageKey = 'venemo_known_contacts';

String? readKnownContactsJson() {
  final value = html.window.localStorage[_knownContactsStorageKey];
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void writeKnownContactsJson(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    html.window.localStorage.remove(_knownContactsStorageKey);
    return;
  }
  html.window.localStorage[_knownContactsStorageKey] = trimmed;
}
