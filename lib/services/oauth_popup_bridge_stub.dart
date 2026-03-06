import 'dart:async';

Future<Map<String, String>?> launchServerOAuthPopup(
  String startUrl, {
  Duration timeout = const Duration(minutes: 2),
}) async {
  return <String, String>{
    'ok': 'false',
    'error': 'このプラットフォームではOAuthポップアップログインに未対応です',
  };
}
