import 'package:google_sign_in/google_sign_in.dart';

import 'google_account.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message, [this.cause]);

  final String message;
  final Object? cause;

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
      return _toGoogleAccount(account, accessToken: accessToken);
    } catch (error) {
      throw GoogleAuthException('Googleログインに失敗しました', error);
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
      throw GoogleAuthException('Googleアカウント情報を取得できませんでした', error);
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
      throw GoogleAuthException('Googleアクセストークンを取得できませんでした', error);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      throw GoogleAuthException('Googleサインアウトに失敗しました', error);
    }
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
