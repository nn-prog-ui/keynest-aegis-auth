# Fela v1.0 Release Plan

## 1. v1.0のコンセプト

Fela v1.0は、ユーザーが登録しているサービスを起点に、ログイン情報、サブスク情報、AutoFill、Import候補を一元管理できる最初の完成版とする。

v1.0の中心方針は以下の3つ。

- ユーザーに考えさせない
- 入力を最小化する
- サービス管理 / AutoFill / Import候補表示までを完成させる

Felaは単なる認証アプリではなく、すべてのデジタルアカウントを管理するアプリである。
ただしv1.0では、AI SecurityやDigital Vaultまで広げず、サービス管理体験を安定させることを最優先にする。

## 2. v1.0に入れる機能

### Service管理

- サービスを中心に管理する構成
- Amazon、Google、Netflix、ChatGPT、YouTubeなどのサービス情報をServiceMasterで管理
- サービス名、ドメイン、ログインURL、解約URL、簡易アイコン情報を保持

### Service追加 / 一覧 / 詳細

- サービスカタログから選択して追加
- 手動追加にも対応
- サービス一覧で登録済みサービスを確認
- サービス詳細でログイン情報、認証コード状態、サブスク情報、AutoFill状態を確認

### AutoFill

- iOS Credential Provider Extensionの土台
- 共有Keychain保存層
- 保存済みサービスのAutoFill identity登録
- Credential ProviderからrecordIdentifierでcredentialを取得し、ID/パスワードを返す構成

### Google OAuth

- Google Sign-InのiOS設定
- openid / email / profile の最小スコープ
- Gmail読み取りスコープはv1.0では追加しない

### Import Pipeline

- ImportSource / ImportItem / ImportRepository
- ServiceDetector
- Service AI Profile
- Recommendation Engine
- ServiceAccountImportCandidate生成
- 現時点ではダミーデータを利用

### Import Candidate Review

- Google連携後にImport Candidateを表示
- 候補は自動保存しない
- ユーザーが確認してからServiceAccountAddScreenで保存
- 保存後はサービス一覧へ反映

### Recommendation

- Amazon / Netflix / ChatGPT / YouTube向けの静的プロフィール
- おすすめプラン、請求周期、理由、注意文を表示
- 料金は確定値ではなく参考候補として扱う

### 重複登録防止

- Import Candidate保存時に既存サービスを検索
- 検索順は serviceId、domains、serviceName
- 一致した場合は新規追加ではなく既存credentialを更新

### Import Test Plan

- `docs/FELA_IMPORT_TEST_PLAN.md` に基づき、Import Flowを手動確認
- Googleログイン、候補表示、候補保存、重複更新、AutoFill、Keychain更新を確認

## 3. v1.0でやらない機能

v1.0では以下を実装しない。

- AI Security
- Digital Vault
- Microsoft連携
- Apple連携
- Claude / Gemini個別最適化
- Gmail本文全文解析
- 自動保存
- ユーザー確認なしの契約情報確定
- Gmail読み取りスコープ追加
- 添付ファイル取得
- パスワードやTOTP secretのImport解析
- サブスク料金の自動確定

v1.0では「候補を提示し、ユーザーが確認して保存する」体験に限定する。

## 4. v1.0までに必ず確認するテスト

### Googleログイン

- Google Sign-Inが実機で動作すること
- Bundle ID、GIDClientID、URL Schemeが正しいこと
- Gmail読み取り権限が要求されないこと

### Import候補表示

- Google連携後にImport Previewが表示されること
- ダミー候補が分かりやすく表示されること
- 候補が自動保存されないこと

### 候補保存

- PreviewからServiceAccountAddScreenへ遷移すること
- ユーザー確認後のみ保存されること
- 料金と更新日が確定値として自動保存されないこと

### 重複更新

- 既存サービスがある場合、新規追加ではなく更新されること
- serviceId、domains、serviceNameの順で既存サービスが検索されること
- 同じサービスが重複登録されないこと

### AutoFill

- 保存後にAutoFill登録処理が従来通り試行されること
- Credential Provider Extensionが壊れていないこと
- AutoFill登録失敗時もKeychain保存が成功扱いになること

### Keychain更新

- passwordやTOTP secretがSharedPreferencesに保存されないこと
- 既存credential更新時に同じrecordIdentifierが使われること
- Keychain上のcredentialが安全に更新されること

### 実機ビルド

- `flutter build ios --release --no-codesign` が成功すること
- Xcode Archiveが成功すること
- TestFlightアップロード前にFlutter生成ファイル差分が混ざっていないこと

## 5. v1.1以降

### v1.1: Gmail API実データ取得

- `gmail.readonly` スコープ追加はv1.1で検討
- OAuth Consent ScreenとGoogle OAuth審査を整理
- Gmail APIで件名、差出人、受信日、snippetなどのメタ情報を取得
- 本文全文保存は禁止
- 候補はユーザー確認後のみ保存

### v1.2: AI Security

- 弱いパスワード、2FA未設定、重複アカウントなどの診断
- ただしローカル安全性とプライバシーを優先
- ユーザーの秘密情報を不要に外部送信しない設計にする

### v2.0: Digital Vault

- 復旧コード、重要書類、秘密メモなどを安全に保存
- Keychain / Secure Storage / 暗号化設計を再整理
- AutoFill、Service管理、AI Securityと統合

## 6. リリース前の禁止事項

v1.0リリース前は、安定化を最優先とする。

- 新機能追加禁止
- 保存処理の大幅変更禁止
- Keychain / AutoFillの不用意な変更禁止
- Gmail読み取りスコープ追加は別フェーズ
- Gmail本文全文解析は禁止
- ユーザー確認なしの契約情報確定は禁止
- Import Candidateの自動保存は禁止
- Bundle IDやApplication IDの変更禁止
- 互換性に関わる内部識別子の変更禁止

v1.0は「広げる」段階ではなく、「今ある体験を安心して使える状態に仕上げる」段階とする。
