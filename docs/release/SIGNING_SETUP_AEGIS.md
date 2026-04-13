# Nemokey 署名設定

## Android
1. `android/key.properties.example` を `android/key.properties` にコピー
2. keystore情報を入力
3. `android/app/build.gradle.kts` は `key.properties` がある場合に release 署名を使用

ビルド:
```bash
flutter build appbundle --release
```

## iOS
1. Apple Developer で `com.nnprogui.keynestauth` を登録
2. Signing & Capabilities を Team/Provisioning に合わせる
3. `ios/fastlane/Appfile` の `app_identifier` を確認

ビルド:
```bash
flutter build ipa --release --export-method app-store
```

## CI向け環境変数
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_PATH`
- `APP_IDENTIFIER_IOS=com.nnprogui.keynestauth`
