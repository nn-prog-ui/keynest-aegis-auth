# Fela Service Completion Specification

## 1. Service Completion の役割

Service Completion は、各サービスについて「どこまで情報が揃っているか」を可視化し、Felaが次に補完すべき情報を判断するための内部指標である。

Completion Scoreはユーザーを評価するものではない。
ユーザーに不足を突きつけるための点数でもない。

Felaが以下を判断するための仕組みとする。

- 次に何を補完すべきか
- どの情報をユーザーに確認すべきか
- Import候補をどのサービスへ優先的に反映すべきか
- AutoFillや2FAなど、セキュリティ面で未整備の項目は何か
- サブスク管理として不足している項目は何か

Felaの目的は「入力させること」ではなく、「ユーザーが迷わず整理できる状態を作ること」である。
Service Completionはそのための羅針盤として機能する。

## 2. Completion項目

Completionは、1サービスに紐づく情報をカテゴリ別に評価する。

### ログイン情報

- メールアドレス / ID が登録されている
- ログインURLがある
- サービスドメインがある

### パスワード

- パスワードがKeychain / Secure Storageに保存されている
- passwordがSharedPreferencesやログに出ていない
- パスワード表示はユーザー操作後のみ

### AutoFill

- AutoFill identity登録済み
- AutoFill登録を試行済み
- Credential ProviderからrecordIdentifierで取得できる

### 2FA

- TOTP secretが登録されている
- 2FAあり / なし / 未確認を区別する
- TOTP secretは一覧では生値を返さない

### 料金

- 月額または年額などの料金が登録されている
- 通貨が登録されている
- 料金が候補か、ユーザー確認済みかを区別する

### 更新日

- 次回更新日が登録されている
- 更新日が候補か、ユーザー確認済みかを区別する

### 支払い方法

- 支払い方法が登録されている
- カード、App Store、Google Play、PayPalなどカテゴリを管理できる
- 詳細なカード番号などは扱わない

### 解約URL

- 解約URLがServiceMasterまたはユーザー入力から補完されている
- 解約URL未登録の場合は不足項目として扱う

### Import済み

- Google、CSV、手動など、どのソースから候補が入ったかを持つ
- Import候補がユーザー確認済みかどうかを区別する

### AI確認済み

- Service AI ProfileまたはRecommendation Engineの候補が表示済み
- ユーザーが候補を確認した
- 候補が保存済み情報へ反映された

## 3. Completion Score

Completion Scoreは0〜100%で表す。

### 基本カテゴリ配点

初期案:

- 基本サービス情報: 15%
- ログイン情報: 20%
- パスワード: 15%
- AutoFill: 10%
- 2FA: 10%
- サブスク情報: 20%
- Import / AI確認: 10%

### 詳細配点例

基本サービス情報 15%:

- serviceName: 5%
- domains: 5%
- loginUrl: 5%

ログイン情報 20%:

- username: 15%
- loginUrl確認済み: 5%

パスワード 15%:

- password保存済み: 15%

AutoFill 10%:

- AutoFill登録済み: 10%
- 登録試行済みだが未確認: 5%

2FA 10%:

- TOTP登録済み: 10%
- 2FA未確認: 0%

サブスク情報 20%:

- price: 5%
- currency: 3%
- billingCycle: 4%
- renewalDate: 4%
- paymentMethod: 2%
- cancelUrl: 2%

Import / AI確認 10%:

- Import候補確認済み: 5%
- Recommendation確認済み: 5%

### Scoreの扱い

- 0〜39%: 最低限の情報のみ
- 40〜69%: 日常利用は可能だが補完余地あり
- 70〜89%: 管理に十分な情報が揃っている
- 90〜100%: ログイン、サブスク、AutoFill、2FAまで高い完成度

このScoreはユーザーへ厳しく見せるものではなく、Fela内部で次の補完提案を決めるために使う。

## 4. 不足情報の検出

FelaはCompletion Scoreだけでなく、不足項目の種類も検出する。

### 不足情報の例

- ID / メールアドレスが未登録
- パスワードが未登録
- AutoFill未登録
- 2FA未確認
- 料金未登録
- 請求周期未登録
- 更新日未登録
- 支払い方法未登録
- 解約URL未登録
- Import候補が未確認

### 不足情報の優先順位

優先順位は以下。

1. ログインできない原因になる情報
2. AutoFillに必要な情報
3. セキュリティ改善に必要な情報
4. サブスク管理に必要な情報
5. 便利機能として補完できる情報

例:

```text
Amazon
- password未登録
- AutoFill未登録
- 更新日未登録
↓
次の提案: パスワードを保存してAutoFillを有効にする
```

```text
Netflix
- price登録済み
- renewalDate未登録
- cancelUrl登録済み
↓
次の提案: 次回更新日を追加する
```

## 5. Fela Brainへの利用方法

Service Completionは、将来のFela Brainが判断に使う基礎データになる。

### Fela Brainが使う判断

- どのサービスを優先して補完するか
- どのImport候補をユーザーへ提示するか
- どのサービスにAutoFill設定を促すか
- どのサービスに2FA設定を促すか
- サブスク画面でどの未入力項目を目立たせるか
- AI Securityでどのリスクを優先表示するか

### 表示例

サービス一覧:

- `あと2項目で整理完了`
- `AutoFill未設定`
- `更新日を追加できます`

サービス詳細:

- `このサービスで次にできること`
- `パスワードを保存`
- `更新日を追加`
- `2FAを登録`

サブスク画面:

- `更新日未登録のサービス`
- `料金未確認のサービス`
- `解約URL未登録のサービス`

### 注意点

Fela Brainは自動確定しない。
候補を整理し、次に確認すべき項目を分かりやすく提示する。

## 6. Felaの羅針盤との整合性

### ユーザーのタップを減らす

Completion Scoreにより、Felaは不足項目をまとめて提示できる。
ユーザーが各画面を探し回らなくても、次に入力すべき情報へ直接進める。

### ユーザーに考えさせない

Felaは「何が足りないか」ではなく「次にこれを確認すればよい」と提示する。
Scoreの詳細よりも、次の行動を明確にする。

### ユーザーが使用しているサブスク料金・情報を整理する

料金、請求周期、更新日、支払い方法、解約URLをCompletion項目に含めることで、サブスク管理をサービス詳細へ統合する。

### 情報を重複追加せず、1サービス1管理画面に統合する

CompletionはService Subscription単位で計算する。
Google、CSV、手動など複数ソースからの情報は、1つのサービスに集約してScoreへ反映する。

## 7. MVPでの最小形

v1.0ではCompletion Scoreを大きなAI処理にしない。

最小形は以下。

- serviceName / domains / loginUrl の有無
- username / password の有無
- AutoFill登録状態
- hasTotpSecret
- monthlyPrice / billingCycle / renewalDate / paymentMethod / cancelUrl の有無
- Import候補確認済みかどうか

v1.0では、Scoreを内部計算し、UIでは以下のような控えめな表示にする。

- `整理中`
- `あとから追加できます`
- `AutoFill準備中`
- `更新日を追加できます`

ユーザーを採点する表現は避ける。
Completion Scoreは、Felaが次に補完すべき情報を判断するための内部指標として扱う。
