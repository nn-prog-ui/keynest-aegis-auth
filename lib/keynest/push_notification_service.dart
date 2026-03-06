import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> keyNestFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationSnapshot {
  PushNotificationSnapshot({
    required this.initialized,
    required this.granted,
    required this.authorizationStatus,
    this.fcmToken,
    this.apnsToken,
    this.errorMessage,
  });

  final bool initialized;
  final bool granted;
  final String authorizationStatus;
  final String? fcmToken;
  final String? apnsToken;
  final String? errorMessage;
}

class PushNotificationService {
  PushNotificationService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  Future<PushNotificationSnapshot> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(String token)? onTokenRefresh,
  }) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(keyNestFirebaseBackgroundHandler);
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        (message) {
          onForegroundMessage?.call(message);
        },
      );

      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
        onTokenRefresh?.call(token);
      });

      final fcmToken = await messaging.getToken();
      final apnsToken = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => await messaging.getAPNSToken(),
        TargetPlatform.macOS => await messaging.getAPNSToken(),
        _ => null,
      };

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      return PushNotificationSnapshot(
        initialized: true,
        granted: granted,
        authorizationStatus: settings.authorizationStatus.name,
        fcmToken: fcmToken,
        apnsToken: apnsToken,
      );
    } catch (error) {
      return PushNotificationSnapshot(
        initialized: false,
        granted: false,
        authorizationStatus: 'not_initialized',
        errorMessage: '$error',
      );
    }
  }

  Future<String?> getLatestToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
  }
}
