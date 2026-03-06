# Aegis Auth 配布チェックリスト（macOS / Windows / iOS / Android）

最終更新: 2026-03-05

## 0. 事前共通
- アプリ名: `Aegis Auth`
- Android Application ID: `com.aegisauth.app`
- iOS Bundle ID: `com.aegisauth.app`
- macOS Bundle ID: `com.aegisauth.app.macos`
- 権限文言: `docs/release/PERMISSIONS_COPY_AEGIS.md`
- プライバシーポリシー: `docs/PRIVACY_POLICY_AEGIS_AUTH.md`
- スクショ: `docs/release/screenshots/`

## 1. iOS（App Store Connect）
1. App Store Connect で `com.aegisauth.app` の App レコード作成
2. 証明書/プロファイル設定
3. `flutter build ipa --release --export-method app-store`
4. `cd ios && bundle exec fastlane testflight`
5. テスト結果確認後、`submit_review`

## 2. macOS（Mac App Store）
1. App Store Connect で macOS app レコード紐付け
2. `flutter build macos --release`
3. `cd macos && bundle exec fastlane testflight`
4. 審査提出（必要に応じて notarization）

## 3. Android（Google Play）
1. Play Console に `com.aegisauth.app` を作成
2. `android/key.properties` を設定
3. `flutter build appbundle --release`
4. `cd android && bundle exec fastlane internal`
5. 動作確認後、`production`

## 4. Windows（Microsoft Store）
1. Partner Center にアプリ登録（Aegis Auth）
2. `flutter build windows --release`
3. MSIX化（必要なら `msix` パッケージ導入）
4. Partner Center へ提出

## 5. CI配布（GitHub Actions）
- 手動起動: `.github/workflows/release-build-all.yml`
- 出力artifact:
  - `aegis-android-aab`
  - `aegis-ios-ipa`
  - `aegis-macos-app`
  - `aegis-windows-release`

## 6. 最終QA
- `docs/release/AEGIS_DEVICE_FLOW_QA.md` を実機で全通し
- クリティカル不具合 0 件で提出
