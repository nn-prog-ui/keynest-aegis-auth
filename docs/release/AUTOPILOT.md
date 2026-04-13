# Nemokey Release Autopilot (2026-03-05 to 2026-03-28)

このドキュメントは、以下4フェーズをGitHub Actionsで日次自動実行するための設定です。

- 2026-03-05〜2026-03-12: `phase1` (FCM HTTP v1移行確認 + 本番設定チェック)
- 2026-03-13〜2026-03-19: `phase2` (実機QA向けビルド + TestFlightアップロード)
- 2026-03-20〜2026-03-24: `phase3` (修正反映 + Release Candidate資料生成)
- 2026-03-25〜2026-03-28: `phase4` (App Review提出)

## 実行エントリ

- スクリプト: `scripts/release/autopilot.sh`
- 日付振り分け: `scripts/release/autopilot_by_date.sh`
- Workflow: `.github/workflows/release-autopilot.yml`
- GitHubなし運用: `docs/release/LAUNCHD_SETUP.md`

## 必須Secrets (GitHub)

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64` (`AuthKey_xxx.p8` を base64 化した文字列)
- `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON_BASE64` (`google-services.json` を base64 化)
- `FIREBASE_IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64` (`GoogleService-Info.plist` を base64 化)

## 必須ファイル

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## レポート

各実行のログは `docs/release/reports/*.md` に保存され、Actions artifact (`keynest-release-reports`) として取得できます。

## 自動生成物

- `phase2` 実行時: `docs/release/QA_CHECKLIST_YYYYMMDD_HHMMSS.md`
- `phase4` 実行時: `docs/release/APP_REVIEW_SUBMISSION_YYYYMMDD_HHMMSS.md`
- テンプレート:
  - `docs/release/templates/PHASE2_QA_CHECKLIST_TEMPLATE.md`
  - `docs/release/templates/APP_REVIEW_TEMPLATE.md`

## 手動実行

- `workflow_dispatch` で `phase` を指定すると任意フェーズを即時実行できます。
- `phase` を空にすると日付で自動選択されます。
- `timezone` はデフォルト `Asia/Tokyo` です。
- ローカル動作確認は `TODAY_OVERRIDE=2026-03-13 DRY_RUN=1 scripts/release/autopilot_by_date.sh` のように実行できます。

## 補足

- 実機での手動確認操作そのものは自動化できないため、`phase2` は TestFlight 配信までを自動化し、最終の人手QAは別途実施します。
- App Review承認完了日はApple審査時間に依存します。提出自体は `phase4` で自動実行されます。
