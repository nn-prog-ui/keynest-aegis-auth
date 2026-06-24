# Fela Handoff

最終更新: 2026-06-24

## 本日の作業

- 指定リポジトリ `nn-prog-ui/keynest-aegis-auth` を読み取り専用で確認した。
- ローカル作業ディレクトリが実体リポジトリではなく、分析用に一時クローンが必要な状態であることを確認した。
- 現在のREADME、Flutterアプリ設定、Web、Android、iOS、macOS、サーバー、配布ドキュメントを横断し、名称と識別子の状態を確認した。
- 最新コミット、Handoff文書の有無、未完了タスク、Felaへ改名する場合の影響範囲を整理した。
- コード本体、設定、API、リリース文書の変更は行っていない。

## 現在の完成度

- アプリ本体はFlutterベースの認証アプリとして主要機能が実装済み。
- README上の主な機能は、TOTP、Push承認、端末ロック、暗号化バックアップ、復元、QR登録。
- サーバー側にはバックアップ保存・読込、Push端末登録、Pushテスト送信のエンドポイントがある。
- iOS、Android、macOS、Windows、Web向けのプロジェクト構成とリリース関連ファイルが存在する。
- 配布・運用面は未完了項目が残っており、本番公開前の最終整備段階と見るのが妥当。

## 未完了タスク

- 実機での主要導線確認。
  - 初回起動
  - QR登録
  - TOTP表示
  - Push承認
  - クラウドバックアップ
  - 復元
- iOS TestFlight配布準備。
- Android内部テスト配布準備。
- macOS / Windows配布方式の確定と署名。
- OAuth本番設定。
  - Web用OAuthクライアント
  - デスクトップ用redirect方式
  - iOS用OAuthクライアント
  - staging / production分離
- 監視と品質保証。
  - Flutterアプリのエラー監視
  - Node backendのエラー監視
  - integration test
  - backend smoke test
- ストア掲載文言、スクリーンショット、LP、プライバシーポリシーの最終確認。
- リリースCIと成果物取得手順の確認。

## Fela改名状況

- 現時点の公開表示名はFelaではない。
- README、Flutter `MaterialApp`、Webタイトル、Android/iOS/macOS表示名には別名が入っている。
- 旧名称KeyNest由来の要素が多く残っている。
  - `lib/keynest/`
  - `KeyNestStorage`
  - `KeyNestBackupPayload`
  - `/api/keynest/...`
  - `keynest_*` 保存ファイル
  - `keynest.*.v1` local storage keys
  - `com.nnprogui.keynestauth`
  - docs/release配下の `*_KEYNEST.md`
- Aegis由来の識別子も残っている。
  - Dartクラス名
  - Android Application ID
  - macOS Bundle ID
  - Windows表示名
  - 画像アセット名
  - リリース文書名
- Felaへの完全改名は、単純な表示名置換ではなく、アプリ識別子・API互換・既存データ移行・配布ストア設定まで含む作業になる。

## 次回やること

1. Felaとして変更する範囲を決める。
   - 表示名のみ
   - 文書とLPまで
   - 内部コード名まで
   - Bundle ID / Application ID / API pathまで
2. 改名対象リストを作る。
   - ユーザー表示名
   - ファイル名
   - クラス名
   - package / bundle identifiers
   - API endpoint
   - local storage key
   - server store file
   - release docs
   - CI artifact name
3. 互換性方針を決める。
   - 既存APIパスを残すか
   - 既存local storage keysをmigrationするか
   - 既存bundle identifierを維持するか
4. 小さなPR単位で改名する。
   - まず表示名と文書
   - 次にコード内部名
   - 最後に識別子とAPI
5. 各段階で `flutter analyze`、`flutter test`、server smoke testを実行する。

## 注意事項

- 勝手にコミットしない。
- 勝手にPushしない。
- 改名は影響範囲が広いため、最初に範囲確認を行う。
- Bundle ID / Application IDを変えるとストア、署名、既存インストール、OAuth設定に影響する。
- API pathを変えると既存クライアントやbackend設定に影響する。
- local storage keyを変える場合はmigrationを用意しないと既存データが見えなくなる可能性がある。
- 既存のHandoff文書には別プロジェクト由来の内容が含まれるため、Fela作業ではこの `HANDOFF_FELA.md` を優先する。
- `server/node_modules/` がリポジトリに含まれているため、検索・diff確認時は必要に応じて除外する。
- 現在の作業場所は分析用クローン:
  `/Users/nemotonoritake/Documents/Codex/2026-06-24/fela-keynest-github-https-github-com/work/keynest-aegis-auth-readonly`

## 推奨開始プロンプト

このチャットはFela専用です。

GitHub:
https://github.com/nn-prog-ui/keynest-aegis-auth

禁止:
- 勝手にコミットしない
- 勝手にPushしない
- 変更前に影響範囲を確認する

まず `HANDOFF_FELA.md` を読み、現在の状態を確認してください。
次に、Felaへの改名範囲を「表示名のみ」「文書まで」「内部コード名まで」「識別子/APIまで」のどこまで行うか整理してください。
まだコード変更はしないでください。
