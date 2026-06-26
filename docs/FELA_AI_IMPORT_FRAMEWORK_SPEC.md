# Fela AI Import Framework Specification

## AI Import Framework の役割

AI Import Framework は、ユーザーが許可した情報だけを解析し、Fela に登録するサービス候補を作るための基盤です。

Fela は、ユーザーにすべてを手入力させるアプリではなく、領収書、購読履歴、CSV、共有シートなどから候補を作り、最後にユーザーが確認して保存できるアプリを目指します。

最重要方針として、Fela はユーザーのデータを勝手に集めるアプリではありません。Fela は、ユーザーが明示的に許可・提供した情報だけを解析して、サービス登録を補助するアプリです。

また、解析結果はあくまで候補です。ユーザー確認なしに契約情報として確定・保存しません。

## Import Source の種類

初期および将来の Import Source は以下を想定します。

### Gmail

- 領収書メール
- サブスク更新通知
- 支払い完了メール
- 解約/更新メール

### Google アカウント

- Google Play 購読
- Google 支払い関連情報
- YouTube / Google One などの契約確認補助

### Microsoft アカウント

- Microsoft 365
- Xbox Game Pass
- OneDrive
- Microsoft Store 関連購読

### App Store 購入履歴

- アプリ内購読
- 更新日
- 価格
- 購読名

### CSV インポート

- 既存パスワード管理アプリからの移行
- サービス名
- ID
- Password
- URL
- カテゴリ
- メモ

### 共有シート

- Safari / メール / PDF / スクリーンショットなどからの手動共有
- ユーザーが明示的に Fela へ送った情報だけ解析

### 将来追加可能な Import Source

- Outlook メール
- Yahoo メール
- 銀行/カード明細 CSV
- PDF 領収書
- スクリーンショット OCR
- ブラウザ拡張
- Android AutoFill / Credential Manager
- 企業 SaaS 請求 API

## データフロー

```text
Import Source
↓
Import Permission / User Consent
↓
Import Parser
↓
Normalized Import Item
↓
Service Detector
↓
Service AI Profile
↓
Recommendation Engine
↓
ServiceAccount 作成候補
↓
ユーザー確認
↓
保存
```

### Import Source

Gmail、CSV、共有シートなどの入力元です。

### Import Permission / User Consent

何を読み取るか、どこまで解析するかをユーザーに明示し、同意を得ます。

### Import Parser

メール本文、CSV、共有テキストなどを構造化します。

### Normalized Import Item

サービス候補、金額候補、更新日候補などに正規化した中間データです。

### Service Detector

Netflix、Amazon、ChatGPT、YouTube など、どのサービスかを推定します。

### Service AI Profile

サービスごとのプラン候補、請求周期候補、確認項目と照合します。

### Recommendation Engine

おすすめプラン、請求周期、確認理由を作ります。

### ServiceAccount 作成候補

保存前の候補です。ユーザー確認なしに保存しません。

## Source ごとの取得可能情報

### Gmail

取得可能な候補:

- サービス名候補
- 領収書タイトル
- 差出人ドメイン
- 金額候補
- 通貨
- 更新日候補
- 請求日候補
- プラン名候補
- 解約/更新メールの有無

取得しないもの:

- メール全体の無断継続監視
- パスワード
- TOTP secret
- 個人メール全体の保存

### Google アカウント

取得可能な候補:

- Google Play 購読候補
- YouTube / Google One などの契約候補
- 請求元候補
- 更新日候補

取得しないもの:

- Google Password Manager の中身
- ユーザーの Google アカウント全体情報
- 不要な連絡先や Drive 内容

### Microsoft アカウント

取得可能な候補:

- Microsoft 365 候補
- Xbox / OneDrive 候補
- Microsoft Store 購読候補
- 更新日候補

取得しないもの:

- Microsoft Authenticator の中身
- Password Manager の中身
- Outlook 全メールの無断解析

### App Store 購入履歴

取得可能な候補:

- 購読名
- 価格
- 更新日
- 請求周期候補
- Apple 経由の契約であること

注意:

- Fela が App Store 購読情報を直接自由に取得できる前提にはしません。
- ユーザー操作、共有、スクリーンショット、手動入力補助を現実的な導線にします。

### CSV

取得可能な候補:

- サービス名
- URL
- ID / メールアドレス
- Password
- カテゴリ
- メモ
- TOTP URI が含まれる場合の候補

注意:

- CSV は機密情報を含むため、ローカル処理を基本にします。
- インポート後の元ファイル削除案内が必要です。
- パスワードをログに出しません。

### 共有シート

取得可能な候補:

- URL
- ページタイトル
- 選択テキスト
- 領収書本文
- スクリーンショット/PDF 候補

注意:

- ユーザーが明示的に共有したデータだけ解析します。
- 自動収集ではないことを UI で明示します。

## ユーザー同意フロー

```text
Import Source を選ぶ
↓
取得する情報を説明
↓
取得しない情報を説明
↓
ユーザーが同意
↓
解析実行
↓
候補一覧を表示
↓
ユーザーが確認・編集
↓
保存
```

同意画面で明記すること:

- 何を取得するか
  - 例: 領収書メール、送信元、件名、金額候補、日付候補
- 何を取得しないか
  - パスワード
  - 認証コード
  - 連絡先
  - 不要なメール本文
  - 全アカウント情報
- いつでも解除できること
  - Google / Microsoft 連携解除
  - Fela 内の接続解除
  - 解析結果の削除
- 保存前に必ず確認すること
  - 候補は自動保存しない
  - ユーザーが確認したものだけ保存する

## Apple 審査を考慮した設計

守るべきこと:

- ユーザー同意なしにメールや購読情報を取得しない
- パスワードや TOTP secret を外部 AI へ送らない
- App Store 購読情報を勝手に取得できると誤解させない
- 「自動で全部検出」ではなく「ユーザーが許可した情報から候補を作る」と説明する
- 解析結果は保存前にユーザー確認を必須にする
- 連携解除・データ削除導線を用意する
- 必要最小限の権限だけ要求する

取得できる情報:

- ユーザーが許可したメール/CSV/共有データ
- OAuth で許可された範囲の情報
- ユーザーが手動で共有した App Store 購読情報

取得できない、または前提にしない情報:

- Apple Passwords / iCloud Keychain の中身
- 他アプリの保存済みパスワード
- App Store 購読一覧の完全な自動取得
- Gmail 全体の無断常時監視
- 認証コード/TOTP secret の自動収集

ユーザー操作必須の部分:

- Import Source 選択
- OAuth 同意
- 共有シート送信
- CSV 選択
- 候補確認
- 保存確定
- 連携解除

## MVP: Gmail Import のみ

最初の MVP は Gmail Import の設計に絞ります。

MVP スコープ:

- Gmail 連携の同意画面
- 読み取り対象の説明
- 領収書/サブスク関連メールの検索
- メール件名・差出人・本文の一部から候補抽出
- 金額候補
- 通貨候補
- 請求日/更新日候補
- サービス名候補
- Service Detector によるサービス推定
- Service AI Profile との照合
- Recommendation Engine によるおすすめ候補生成
- ユーザー確認画面
- 保存はユーザー確定後のみ

Gmail MVP で取得するもの:

- 件名
- 差出人
- 受信日
- 領収書らしい本文の一部
- 金額候補
- 日付候補
- サービス名候補

Gmail MVP で取得しないもの:

- パスワード
- 認証コード
- 全メールの保存
- 連絡先
- 添付ファイル全体
- メール常時監視

Gmail MVP のデータフロー:

```text
Gmail Import を選択
↓
ユーザー同意
↓
領収書候補メールを検索
↓
Import Parser で金額・日付・サービス名候補を抽出
↓
Service Detector で Netflix / YouTube / ChatGPT などに照合
↓
Service AI Profile でプラン候補を補助
↓
Recommendation Engine でおすすめ候補を生成
↓
ユーザーが確認・修正
↓
ServiceAccount 候補として保存
```

## 最重要方針

Fela はユーザーのデータを勝手に集めません。

Fela は、ユーザーが許可した情報だけを解析し、サービス登録を補助します。

候補は候補のままであり、ユーザー確認なしに契約情報として確定・保存しません。

Fela は、ユーザーの入力負担を減らしながらも、プライバシーと確認責任を明確に守るアプリとして設計します。
