enum ImportSource {
  gmail,
  google,
  microsoft,
  appStore,
  csv,
  shareSheet,
}

extension ImportSourceLabel on ImportSource {
  String get label {
    switch (this) {
      case ImportSource.gmail:
        return 'Gmail';
      case ImportSource.google:
        return 'Googleアカウント';
      case ImportSource.microsoft:
        return 'Microsoftアカウント';
      case ImportSource.appStore:
        return 'App Store';
      case ImportSource.csv:
        return 'CSV';
      case ImportSource.shareSheet:
        return '共有シート';
    }
  }
}
