# Fela Project Context

最終更新: 2026-06-25

## プロジェクト概要

Fela は、Flutter ベースの認証アプリです。主な用途は TOTP 認証コード表示、Push 承認、端末ロック、暗号化バックアップ、復元です。

個人利用では軽量な認証アプリとして使い、チーム・法人利用ではブランド付きサインイン承認アプリとして展開する想定です。

## 旧名称 KeyNest / Nemokey

- 旧名称: KeyNest
- 直近のリポジトリ上の名称: Nemokey
- GitHubリポジトリ名: `keynest-aegis-auth`
- コード、API、文書には KeyNest / Nemokey / Aegis 由来の名称が混在しています。

## 現在の正式名称 Fela

このプロジェクトの現在の正式名称は Fela です。

表示名・文書・ストア提出素材は第1段階としてFelaへ統一済みです。ただし、内部識別子、Bundle ID、API path、storage key、クラス名、ディレクトリ名には旧名称由来の要素が残っています。

## GitHub URL

https://github.com/nn-prog-ui/keynest-aegis-auth

## ローカルパス

正式clone:

`/Users/nemotonoritake/Documents/GitHub/keynest-aegis-auth`

一時分析clone:

`/Users/nemotonoritake/Documents/Codex/2026-06-24/fela-keynest-github-https-github-com/work/keynest-aegis-auth-readonly`

今後の開発作業は正式cloneで行います。一時分析cloneは参照用であり、開発継続の本体として扱わないでください。

## 現在の完成度

- Flutterアプリとして主要な認証アプリ機能は実装済みです。
- iOS、Android、macOS、Windows、Web向けのプロジェクト構成があります。
- Node backend があり、バックアップとPush関連APIがあります。
- リリース、配布、運用、OAuth本番設定、監視、テストは未完了項目が残っています。
- 状態としては、プロトタイプから配布準備段階へ進む途中です。

## 現在の名称混在状況

Felaへの改名は第1段階まで完了しています。現在、以下の名称が混在しています。

- Fela: 現在の正式名称。表示名、README、Webタイトル、Android/iOS/macOS表示名、リリース文書に反映済みです。
- Nemokey: 旧表示名。第1段階で主要な表示名と提出素材からは除去済みです。
- KeyNest: ディレクトリ名、クラス名、API path、保存キー、Bundle ID、リリース文書名に残っています。
- Aegis: Dartクラス名、Application ID、Bundle ID、Windows表示名、画像アセット名、リリース文書名に残っています。

主な混在箇所:

- `README.md`
- `lib/keynest/`
- `lib/keynest/keynest_app.dart`
- `lib/keynest/keynest_storage.dart`
- `lib/keynest/cloud_backup_service.dart`
- `lib/keynest/push_gateway_service.dart`
- `server/index.js`
- `web/index.html`
- `web/landing.html`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `macos/Runner/Configs/AppInfo.xcconfig`
- `windows/runner/main.cpp`
- `windows/runner/Runner.rc`
- `docs/release/`

## 実装済み機能

- QR onboarding for `otpauth://` accounts
- RFC6238 TOTP generation
- SHA1 / SHA256 / SHA512 support
- 6-8 digit code support
- Push sign-in approvals
- Approve / Deny flow
- Device lock
- Biometric / device authentication
- Encrypted backup / restore
- PBKDF2 + AES-256-GCM
- Offline fallback for backup restore testing
- Backend endpoints for backup save/load
- Backend endpoints for push device registration and test push
- Web landing page draft
- Release docs and distribution checklists
- GitHub Actions workflows for CI and release-related builds

## 未完了タスク

- Felaへの改名第2段階の範囲を確定する。
- 表示名、文書、LPのFela統一状態を確認する。
- 必要に応じて内部コード名をFelaへ更新する。
- Bundle ID / Application ID を変更するか維持するか判断する。
- API pathを変更するか、互換性のため残すか判断する。
- local storage keys のmigration方針を決める。
- server store file の互換性方針を決める。
- iOS実機導線を確認する。
- TestFlight内部配布を準備する。
- Android内部テスト配布を準備する。
- macOS / Windowsの署名・配布方式を決める。
- OAuth本番設定を整備する。
- Sentry等のエラー監視を追加する。
- integration testを追加する。
- backend smoke testを追加する。
- ストア文言、スクリーンショット、LP、プライバシーポリシーを最終確認する。
- CI成果物の取得と配布手順を確認する。

## Fela改名方針

改名は段階的に進めます。

推奨順:

1. 表示名と文書をFelaへ変更する。
2. Web / LP / README / store copyをFelaへ変更する。
3. Flutter内のユーザー表示テキストをFelaへ変更する。
4. 内部クラス名、ディレクトリ名、ファイル名の改名可否を判断する。
5. Bundle ID / Application ID / API path / storage key の変更可否を判断する。
6. 互換性が必要な箇所にはmigrationまたはlegacy aliasを用意する。

注意:

完全改名は単純な文字列置換ではありません。既存ユーザーデータ、配布ストア、OAuth、Push通知、API互換性に影響します。

## 変更してよい範囲

ユーザー確認後に変更してよい範囲:

- `README.md`
- `PROJECT_CONTEXT.md`
- `HANDOFF_FELA.md`
- `docs/`
- `web/landing.html`
- `web/index.html`
- Flutter内のユーザー表示テキスト
- ストア文言
- リリース文書
- テスト追加
- 明確にFela改名に関係する軽微な表記修正

ただし、実作業前に変更範囲を一覧化して確認してください。

## まだ変更してはいけない範囲

明示許可なしに変更してはいけない範囲:

- Bundle ID
- Android Application ID
- iOS Bundle ID
- macOS Bundle ID
- API endpoint path
- local storage key
- backup data format
- server store file name
- Push notification channel ID
- OAuth client settings
- signing / provisioning settings
- CI release artifact名
- package name
- ディレクトリ名やクラス名など大規模rename

これらは既存データ、配布、署名、OAuth、Push、サーバー互換性に影響するため、必ず事前に方針を確認してください。

## Git運用ルール

- 勝手にコミットしない。
- 勝手にPushしない。
- 作業前に `git status --short --branch` を確認する。
- 変更対象ファイルを明示してから作業する。
- 変更後に `git status` と変更ファイル一覧を表示する。
- コミットする場合は、ユーザー確認後に行う。
- Pushする場合は、ユーザー確認後に行う。
- 既存の未追跡・未コミット変更がある場合は、勝手に削除・上書きしない。
- 一時分析cloneではなく、正式cloneで作業する。

## 絶対禁止事項

- 勝手にコミットすること。
- 勝手にPushすること。
- ユーザー確認なしにFela改名作業を開始すること。
- ユーザー確認なしにBundle ID / Application ID / API path / storage keyを変更すること。
- 既存データを読めなくする変更をmigrationなしで入れること。
- 既存の未コミット変更を勝手に戻すこと。
- 一時分析cloneを正式な開発本体として扱うこと。
- 禁止された旧候補名を新規文書やUIへ追加すること。

## 次回開始プロンプト

このチャットはFela専用です。

GitHub:
https://github.com/nn-prog-ui/keynest-aegis-auth

正式ローカルパス:
`/Users/nemotonoritake/Documents/GitHub/keynest-aegis-auth`

まず `PROJECT_CONTEXT.md` と `HANDOFF_FELA.md` を読んでください。

禁止:
- 勝手にコミットしない
- 勝手にPushしない
- Fela改名前に影響範囲を確認する
- Bundle ID / Application ID / API path / storage key は許可なく変更しない

最初に `git status --short --branch` を確認してください。
次に、Felaへの改名範囲を「表示名のみ」「文書まで」「内部コード名まで」「識別子/APIまで」のどこまで行うか整理してください。
まだコード変更はしないでください。
