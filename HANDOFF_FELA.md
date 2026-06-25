# Fela Handoff

最終更新: 2026-06-26

## 本日の作業

- Felaの方向性を「すべてのデジタルアカウントをサービス起点で管理するアプリ」として整理した。
- サービス詳細画面をFelaの中心画面にする方針を決定した。
- サービス詳細画面の仕様書を作成した。
  - `docs/FELA_SERVICE_DETAIL_SPEC.md`
- 左メニュー構成の仕様書を作成済み。
  - `docs/FELA_NAVIGATION_SPEC.md`
- 左メニューのUI土台を実装済み。
  - 左メニュー最上位は「サービス」
  - 初期表示も「サービス」
  - ホームは通知・最近使ったサービス程度の軽い画面
  - 認証コード / サブスク / Digital Vault / AI Security / 設定はプレースホルダー
- サービス詳細画面を整理済み。
  - ログイン情報
  - 認証コード
  - サブスク
  - AutoFill
- Service Masterを作成済み。
  - Amazon / Google / Apple / Netflix / ChatGPT / 楽天 / Adobe / Microsoftなどを固定候補化
  - カテゴリは日本語で管理
- サービス追加体験を改善済み。
  - 検索だけでなく、人気サービス、カテゴリー、最近追加が多いサービスを表示
  - 候補選択後、サービス名・ドメイン・ログインURLなどを初期入力
- 共有Keychain保存層を実装済み。
  - `SharedCredential`
  - `SharedCredentialStore`
  - `AutoFillCredentialBridge`
  - `SharedCredentialBridge`
- iOS Credential Provider Extensionの土台を追加済み。
- iOS審査エラー90683対応として、必要なPrivacy Usage DescriptionとBuild Number 3対応を実施済み。

## 現在の完成度

概算: 60%

できていること:

- Felaとしてのユーザー向け表示名統一は第1段階完了。
- サービス中心アプリとしての基本構成が固まりつつある。
- 左メニューにより、Fela全体を移動できる土台ができた。
- サービス追加、サービス一覧、サービス詳細の基本導線がある。
- サービスごとにID / パスワード / TOTP secret / サブスク情報をKeychain側へ保存する土台がある。
- iOS AutoFillに向けたCredential Provider Extensionと共有Keychainの土台がある。
- 仕様書として、全体ナビゲーションとサービス詳細の方針が残っている。

まだ完成ではないこと:

- AutoFill候補登録は未実装。
- Amazonログイン画面でFela候補を出す検証は未実装。
- 認証コード一覧画面はプレースホルダー。
- サブスク一覧画面はプレースホルダー。
- Digital Vaultはプレースホルダー。
- AI Securityはプレースホルダー。
- サービス詳細の完成形UIは仕様書化のみで、次の実装対象。
- 編集 / 削除 / 認証コード追加 / サブスク追加の実導線は未完成。

## 未完了タスク

- 未Pushコミットの扱い確認。
  - `76eab60 Add Fela service detail specification`
- `HANDOFF_FELA.md` の今回更新分をコミットするか確認。
- サービス詳細画面の完成形UI実装。
  - サービスヘッダー
  - ログインカード
  - 認証コードカード
  - サブスクカード
  - AutoFillカード
  - 操作カード
- 認証コード一覧画面の実装。
  - TOTP登録済みサービスだけを一覧化
  - 将来的に6桁コード表示
- サブスク画面の実装。
  - 月額合計
  - 更新日順
  - 支払い方法別
- AutoFill第3段階以降。
  - `ASCredentialIdentityStore` への候補登録
  - AmazonドメインでのMVP検証
  - ExtensionからrecordIdentifierでcredential取得
  - 選択時にusername/password返却
- サービス追加フローの短縮。
  - サービス選択後は確認画面なしでログイン情報入力へ
  - 認証コードとサブスクは「あとから追加できます」のオプション画面へまとめる
- 編集 / 削除の安全な実装。
- TestFlight再提出前のArchive確認。
- 実機確認。
  - 初回起動
  - サービス追加
  - Keychain保存
  - サービス一覧
  - サービス詳細
  - Credential Provider Extension

## Fela改名状況

- 正式名称はFela。
- 旧名称:
  - KeyNest
  - Nemokey
- ユーザー向け表示名はFelaへ寄せる方針。
- 現在のリポジトリ名はまだ `keynest-aegis-auth`。
- 内部識別子や互換性に関わる名前はまだ残している。

残している重要な内部識別子:

- Bundle ID:
  - `com.nnprogui.keynestauth`
- iOS/macOS関連:
  - `com.aegisauth.app`
  - `com.aegisauth.app.macos`
- API path:
  - `/api/keynest`
- storage key / backup payload / server store file
- `lib/keynest/`
- `KeyNestStorage` などの内部クラス名
- `AegisAuthApp` などの内部識別子

注意:

- Bundle ID、Application ID、API path、local storage key、backup payloadは互換性に影響するため、まだ変更しない。
- Fela改名は「表示名・文書」から進め、内部識別子変更は別フェーズに分ける。

## 次回やること

推奨順:

1. 現在のgit状態を確認する。
   - `git status`
   - `git log --oneline -3`
2. 未Pushコミット `76eab60` をPushするか確認する。
3. 今回更新した `HANDOFF_FELA.md` をコミットするか確認する。
4. サービス詳細画面の完成形UIを実装する。
   - 仕様書: `docs/FELA_SERVICE_DETAIL_SPEC.md`
5. ビルド確認を行う。
   - `flutter build ios --release --no-codesign`
6. Flutter build副作用が出た場合は、対象外ファイルだけ戻す。
   - `ios/Flutter/AppFrameworkInfo.plist`
   - `pubspec.lock`
7. 次に認証コード一覧画面を作る。

## 注意事項

- 勝手にコミットしない。
- 勝手にPushしない。
- 変更対象ファイルを必ず確認してから作業する。
- 現在の正式clone:
  - `/Users/nemotonoritake/Documents/GitHub/keynest-aegis-auth`
- このCodexワークスペースとは別場所のため、作業時は正式cloneを明示する。
- Flutter build後に以下が副作用で変わることがある。
  - `ios/Flutter/AppFrameworkInfo.plist`
  - `pubspec.lock`
  - `ios/Podfile.lock`
  - `ios/Runner/AppDelegate.swift`
  - `ios/Runner/Info.plist`
- 副作用ファイルは、今回の目的に含まれない場合だけ個別にrevertする。
- パスワードやTOTP secretはSharedPreferencesに保存しない。
- password / totpSecret の生値を一覧画面やログに出さない。
- AutoFill、Digital Vault、AI Securityは重要だが、段階的に実装する。
- サービス詳細がFelaの中心画面。各一覧画面は補助画面として扱う。
- サブスク合計はホームではなくサブスク画面で見せる方針。
- 左メニュー最上位と初期表示は「サービス」。
- Venemo禁止。
- Elon禁止。

## 推奨開始プロンプト

このチャットはFela専用です。

GitHub:
https://github.com/nn-prog-ui/keynest-aegis-auth

ローカル正式clone:
`/Users/nemotonoritake/Documents/GitHub/keynest-aegis-auth`

まず以下を読んでください。

- `PROJECT_CONTEXT.md`
- `HANDOFF_FELA.md`
- `docs/FELA_NAVIGATION_SPEC.md`
- `docs/FELA_SERVICE_DETAIL_SPEC.md`

禁止:

- 勝手にコミットしない
- 勝手にPushしない
- Bundle ID / API path / storage key / backup payloadを勝手に変更しない
- パスワードやTOTP secretをSharedPreferencesに保存しない
- password / totpSecretの生値を一覧画面やログに出さない

次に、`git status` と `git log --oneline -3` を確認してください。

その後、サービス詳細画面をFelaの中心画面として完成形に近付けてください。
実装前に変更予定ファイルと実装順序を出してください。
