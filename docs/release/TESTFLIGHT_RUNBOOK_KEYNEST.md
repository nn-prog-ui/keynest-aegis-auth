# Nemokey TestFlight Runbook

最終更新: 2026-04-13

## 目的
Nemokey の iOS ビルドを App Store Connect / TestFlight に上げるための実行手順を固定する。

## 現在の前提
- iOS Bundle ID: `com.nnprogui.keynestauth`
- Apple Developer / App Store Connect API Key は取得済み
- `ios/fastlane/Fastfile` に `testflight` lane あり
- 実機起動安定化は別途継続中

## 方法 A: Xcode から Archive する
1. `ios/Runner.xcworkspace` を Xcode で開く
2. Scheme が `Runner`、Destination が `Any iOS Device (arm64)` になっていることを確認
3. `Product -> Archive`
4. Organizer が開いたら、最新 Archive を選ぶ
5. `Distribute App`
6. `App Store Connect`
7. `Upload`
8. 署名とチェックを通す
9. アップロード完了後、App Store Connect の TestFlight で処理完了を待つ

## 方法 B: fastlane から上げる
事前に以下を環境変数で設定する。
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_PATH` または `APP_STORE_CONNECT_API_KEY_BASE64` をファイル化した `AuthKey.p8`
- `APPLE_ID`（必要なら）
- `APP_IDENTIFIER_IOS=com.nnprogui.keynestauth`

実行:
```bash
cd ios
bundle install
bundle exec fastlane testflight
```

## fastlane の中身
- `build_ipa`: `flutter build ipa --release --export-method app-store`
- `testflight`: `upload_to_testflight`
- `submit_review`: `upload_to_app_store(... submit_for_review: true)`

## TestFlight でやること
1. `My Apps -> Nemokey -> TestFlight`
2. ビルド処理完了を待つ
3. 内部テスターを追加
4. 必要なら外部テスターを追加
5. 実機導線を確認
   - 追加
   - QR登録
   - コード表示
   - Push承認
   - クラウド復元

## 詰まりやすい点
- Provisioning profile に実機が紐付いていない
- keychain の `Apple Development` へのアクセス許可が出る
- Xcode の iOS platform version が端末と一致していない
- 実機は入るが自動起動だけ失敗することがある

## 今の推奨
- まず Xcode Archive で TestFlight に上げる
- その後、fastlane で CI 化する
