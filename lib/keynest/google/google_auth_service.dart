import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import 'google_account.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(
    this.message, [
    this.cause,
    this.isPermissionDenied = false,
  ]);

  final String message;
  final Object? cause;
  final bool isPermissionDenied;

  @override
  String toString() => 'GoogleAuthException: $message';
}

class GoogleAuthService {
  GoogleAuthService({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [
                'openid',
                'email',
                'profile',
                'https://www.googleapis.com/auth/gmail.readonly',
              ],
            );

  final GoogleSignIn _googleSignIn;

  Future<GoogleAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      final accessToken = await _accessTokenFor(account);
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const GoogleAuthException(
          'Google連携に失敗しました',
          null,
          true,
        );
      }
      return _toGoogleAccount(account, accessToken: accessToken);
    } on GoogleAuthException {
      rethrow;
    } catch (error) {
      throw _googleAuthExceptionFor(error);
    }
  }

  Future<GoogleAccount?> currentAccount() async {
    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) {
        return null;
      }
      return _toGoogleAccount(account);
    } catch (error) {
      throw _googleAuthExceptionFor(
        error,
        fallbackMessage: 'Googleアカウント情報を取得できませんでした',
      );
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) {
        return null;
      }
      return _accessTokenFor(account);
    } catch (error) {
      throw _googleAuthExceptionFor(
        error,
        fallbackMessage: 'Googleアクセストークンを取得できませんでした',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      throw GoogleAuthException('Googleサインアウトに失敗しました', error);
    }
  }

  GoogleAuthException _googleAuthExceptionFor(
    Object error, {
    String fallbackMessage = 'Googleログインに失敗しました',
  }) {
    if (_isAccessDenied(error)) {
      return GoogleAuthException(
        'Google連携に失敗しました',
        error,
        true,
      );
    }
    return GoogleAuthException(fallbackMessage, error);
  }

  bool _isAccessDenied(Object error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      final details = error.details?.toString().toLowerCase() ?? '';
      return code.contains('access_denied') ||
          code.contains('sign_in_failed') &&
              details.contains('access_denied') ||
          message.contains('access_denied') ||
          details.contains('access_denied') ||
          message.contains('403') ||
          details.contains('403');
    }
    final text = error.toString().toLowerCase();
    return text.contains('access_denied') || text.contains('403');
  }

  Future<String?> _accessTokenFor(GoogleSignInAccount account) async {
    final authentication = await account.authentication;
    return authentication.accessToken;
  }

  GoogleAccount _toGoogleAccount(
    GoogleSignInAccount account, {
    String? accessToken,
  }) {
    return GoogleAccount(
      id: account.id,
      email: account.email,
      displayName: account.displayName ?? '',
      photoUrl: account.photoUrl ?? '',
      accessToken: accessToken,
    );
  }
}
