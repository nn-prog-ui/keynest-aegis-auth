import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<Map<String, String>?> launchServerOAuthPopup(
  String startUrl, {
  Duration timeout = const Duration(minutes: 2),
}) async {
  late final html.WindowBase popup;
  try {
    popup = html.window.open(
      startUrl,
      'venemo_oauth_popup',
      'width=520,height=760,resizable=yes,scrollbars=yes',
    );
  } catch (_) {
    return <String, String>{
      'ok': 'false',
      'error': 'ポップアップがブロックされました。ブラウザ設定を確認してください。',
    };
  }

  final completer = Completer<Map<String, String>?>();
  StreamSubscription<html.MessageEvent>? subscription;
  Timer? closedWatcher;
  Timer? timeoutTimer;

  void finish(Map<String, String>? result) {
    if (completer.isCompleted) return;
    subscription?.cancel();
    closedWatcher?.cancel();
    timeoutTimer?.cancel();
    try {
      popup.close();
    } catch (_) {}
    completer.complete(result);
  }

  subscription = html.window.onMessage.listen((event) {
    final raw = event.data;
    if (raw is! String || raw.trim().isEmpty) {
      return;
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      payload = decoded;
    } catch (_) {
      return;
    }

    if (payload['type'] != 'venemo-oauth-result') {
      return;
    }

    final map = <String, String>{};
    payload.forEach((key, value) {
      if (value == null) return;
      map[key.toString()] = value.toString();
    });
    finish(map);
  });

  closedWatcher = Timer.periodic(const Duration(milliseconds: 250), (_) {
    if (popup.closed == true) {
      finish(<String, String>{
        'ok': 'false',
        'error': 'OAuthウィンドウが閉じられました',
      });
    }
  });

  timeoutTimer = Timer(timeout, () {
    finish(<String, String>{
      'ok': 'false',
      'error': 'OAuthログインがタイムアウトしました',
    });
  });

  return completer.future;
}
