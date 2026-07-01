# Fela Subscription Intelligence Specification

## 1. Subscription Intelligence の役割

Subscription Intelligence は、Felaが扱うサービス情報、ログイン情報、サブスク候補、Import結果、ユーザー入力を統合し、ユーザーが契約しているサービスを1件の管理単位として整理する判断レイヤーである。

これは勝手に確定するAIではない。
複数の情報源から候補をまとめ、ユーザーが迷わず確認できる状態にするための中核である。

Subscription Intelligence の主な役割は以下。

- 複数ソースから得た情報をサービス単位にまとめる
- 同じサービスの重複登録を防ぐ
- サブスク候補をService Subscriptionとして整理する
- 料金、更新日、請求周期、支払い方法の候補を比較する
- ユーザー確認が必要な項目を明確にする
- AutoFill / 2FA / ログイン情報の状態を同じサービス上に集約する

Fela全体では以下の位置づけとする。

```text
Import Source
↓
Import Parser
↓
Service Detector
↓
Subscription Intelligence
↓
Service Subscription Candidate
↓
User Confirmation
↓
Keychain / Service管理へ保存
```

## 2. 入力

### Google

- Gmail領収書候補
- Googleアカウント情報
- YouTube / Google One / Workspace などの候補
- ユーザーが許可した情報のみ

### Apple

- App Store購読候補
- Apple ID関連サービス候補
- iCloud、Apple Music、Apple TV+ など

### Microsoft

- Microsoft 365
- OneDrive
- Xbox Game Pass
- Azure / Copilot 系候補

### CSV

- サービス名
- URL
- ID
- パスワード
- メモに含まれる支払い情報候補
- 他パスワード管理アプリからの移行データ

### 手動

- ユーザーが入力したサービス名
- ログインURL
- ID / パスワード
- 料金
- 請求周期
- 更新日
- 支払い方法
- 解約URL

### 将来の銀行 / カード明細

- 加盟店名
- 金額
- 通貨
- 決済日
- 継続課金らしさ
- 支払い方法

銀行 / カード明細から得た情報は、契約確定には必ずユーザー確認を必要とする。

## 3. 出力

出力は `Service Subscription` として扱う。

Service Subscription の主な項目は以下。

- serviceId
- serviceName
- serviceAliases
- domains
- loginUrl
- hasLoginCredential
- username
- hasPassword
- hasTotp
- autoFillStatus
- subscriptionStatus
- planName
- price
- currency
- billingCycle
- renewalDate
- paymentMethod
- cancelUrl
- sourceRefs
- confidence
- requiresUserConfirmation
- lastDetectedAt
- lastConfirmedAt

`price` や `renewalDate` は、最初から確定値として扱わない。
まず候補として扱い、ユーザー確認後に確定値へ昇格する。

## 4. 同じサービスを統合するロジック

統合の優先順位は以下。

1. serviceId
2. domains
3. 正規化したサービス名
4. ログインURL
5. 支払い元の加盟店名
6. ServiceMasterのalias
7. ユーザー確認済みの過去マッピング

例:

```text
Googleから ChatGPT 候補
CSVから ChatGPT ログイン情報
手動で ChatGPT サブスク情報
↓
serviceId = chatgpt と判定
↓
1件のService Subscriptionに統合
```

統合時の基本方針:

- ログイン情報はKeychain側の既存credentialを優先する
- サブスク情報はユーザー確認済みデータを優先する
- Import情報は候補として追加する
- 新しいImport候補が既存確定値と違う場合は変更候補として表示する
- 自動で上書きしない

統合結果の例:

```text
ChatGPT
- ログイン情報: CSV由来
- サブスク候補: Google/Gmail由来
- プラン候補: Service AI Profile由来
- AutoFill: 登録済み
- 2FA: 未登録
```

## 5. 更新ロジック

### 料金変更

- 既存料金と新しい候補料金が違う場合、即上書きしない
- `料金変更の可能性があります` と表示する
- ユーザーが確認したら更新する

### 更新日変更

- 次回更新日が新しい候補で検出された場合、候補として表示する
- 前回の請求周期と整合する場合は信頼度を上げる
- 確定はユーザー確認後とする

### 解約

- 解約メール、キャンセル完了通知、支払い停止候補を検出する
- 即 `解約済み` にはしない
- `解約済みの可能性` として表示する
- ユーザー確認後に inactive へ変更する

### 新規契約

- 既存サービスに一致しない継続課金候補を検出する
- `新しいサブスク候補` として表示する
- ユーザーが確認して保存した場合のみService Subscription化する

## 6. ユーザー確認が必要なもの

以下は必ずユーザー確認を必要とする。

- 契約中かどうか
- プラン名
- 実際の料金
- 次回更新日
- 支払い方法
- 解約済みかどうか
- 同じサービスとして統合してよいか
- password / TOTP / recovery code など秘密情報
- 銀行 / カード明細から推定したサービス名

これらはユーザーごとに異なり、誤判定すると金銭面・セキュリティ面のリスクが高い。

## 7. 自動更新してよいもの

### 自動更新してよいもの

- ServiceMaster由来の静的情報
  - serviceName
  - domains
  - loginUrl
  - cancelUrl
  - icon情報
- Service AI Profile由来の候補情報
  - プラン候補
  - 請求周期候補
  - 注意文
- AutoFill状態
  - 登録済み / 未登録 / 準備中
- 2FA有無
  - Fela内にTOTP secretが登録されているか
- ログイン情報有無
  - Keychain credentialがあるか

### 条件付きで自動更新してよいもの

- 請求周期候補
  - 同じサービスで過去にユーザー確認済みパターンと一致する場合
- 支払い方法カテゴリ
  - `カードらしい` `App Storeらしい` 程度の候補表示まで

### 自動更新してはいけないもの

- 料金の確定値
- 更新日の確定値
- 解約状態
- 契約プラン確定
- ユーザー秘密情報
- サービス統合の確定判断

## 8. Felaの設計原則との整合性

Felaの羅針盤:

- ユーザーのタップを減らす
- ユーザーに考えさせない
- ユーザーが使用しているサブスク料金・情報を整理する
- 情報を重複追加せず、1サービス1管理画面に統合する

### ユーザーのタップを減らす

- ServiceMasterで分かる情報は自動入力する
- Import候補を1サービス単位にまとめる
- 重複候補を出さず、更新候補として表示する
- 候補カードから確認画面へ直行する
- 保存後はサービス一覧へ戻す

### ユーザーに考えさせない

- `候補です` と `確認が必要です` を明確に分ける
- 料金や更新日の意味をUIで説明する
- サービス名を知らなくてもカテゴリや候補から選べる
- 不確かな情報をFelaが断定しない
- 次に何をすればよいか常に1つの主要CTAで示す

### ユーザーのデジタルライフを整理する

- ログイン情報、サブスク、2FA、AutoFillを同じサービス詳細へ集約する
- Google、CSV、手動、将来のApple / Microsoft / 銀行明細を1つのService Subscriptionに統合する
- サービス一覧を中心に、各情報へ迷わず到達できる構造にする
- 重複登録を防ぎ、1サービス1管理画面を徹底する

## 9. MVPでの最小形

v1.0では、Subscription Intelligenceを大きなAI処理にしない。
最小形は以下。

- serviceId / domains / serviceName による統合
- Import Candidateを既存サービスへ更新
- 料金・更新日は参考候補
- ユーザー確認後のみ保存
- AutoFill / Keychainは既存処理を維持

この最小形により、Felaは「追加アプリ」ではなく「整理して更新するアプリ」として成立する。
