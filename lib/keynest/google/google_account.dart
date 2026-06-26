class GoogleAccount {
  const GoogleAccount({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.accessToken,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? accessToken;

  GoogleAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
  }) {
    return GoogleAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
