import 'dart:html' as html;

const String _settingsStorageKey = 'venemo_app_settings';

String? readAppSettingsJson() {
  final raw = html.window.localStorage[_settingsStorageKey];
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return raw;
}

void writeAppSettingsJson(String jsonText) {
  final raw = jsonText.trim();
  if (raw.isEmpty) {
    html.window.localStorage.remove(_settingsStorageKey);
    return;
  }
  html.window.localStorage[_settingsStorageKey] = raw;
}
