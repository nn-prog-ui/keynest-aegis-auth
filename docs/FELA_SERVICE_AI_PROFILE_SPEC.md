# Fela Service AI Profile Specification

## Service AI Profile の役割

Service AI Profile は、Fela がサービス登録を補助するためのサービス別プロフィールです。

Fela は「ユーザーがすべて入力するアプリ」ではなく、「Fela 側が分かる情報を準備し、ユーザーが確認して保存するアプリ」を目指します。Service AI Profile はそのために、サブスクプラン候補、請求周期候補、解約導線、確認すべき項目などをサービスごとに管理します。

重要な前提として、Service AI Profile はユーザーごとの契約情報を勝手に確定するものではありません。あくまでサービスごとの候補情報を提示し、ユーザー確認を補助するものです。

## ServiceMaster との違い

ServiceMaster は、サービスそのものの静的な基本情報を管理します。

- サービス名
- ドメイン
- ログイン URL
- 解約 URL
- サポート URL
- ヘルプ URL
- 簡易アイコン情報
- AutoFill / TOTP / サブスク / Passkey 対応の基本フラグ

Service AI Profile は、サービス登録時の入力補助に使う情報を管理します。

- サブスクプラン候補
- 料金候補
- 請求周期候補
- 解約導線の説明
- 支払い方法推定の補助
- 複数プランの整理
- ユーザーに確認すべき項目
- 将来の外部連携や AI 補助で照合するためのヒント

ServiceMaster は「このサービスは何か」を表し、Service AI Profile は「このサービスを登録するとき、Fela が何を手伝えるか」を表します。

## データ構造案

将来的な拡張を含めた構造案です。

```dart
class ServiceAiProfile {
  final String serviceId;
  final List<SubscriptionPlanCandidate> subscriptionPlans;
  final List<String> billingCycleCandidates;
  final List<String> paymentMethodHints;
  final CancellationGuide cancellationGuide;
  final List<UserConfirmationField> confirmationFields;
  final List<String> autofillHints;
  final String confidenceNote;
  final DateTime? lastReviewedAt;
}

class SubscriptionPlanCandidate {
  final String planName;
  final String? price;
  final String currency;
  final String billingCycle;
  final String? description;
  final bool requiresUserConfirmation;
}

class CancellationGuide {
  final String? cancelUrl;
  final String summary;
  final List<String> steps;
  final bool requiresLogin;
}

class UserConfirmationField {
  final String fieldKey;
  final String label;
  final String reason;
  final bool requiredForAccuracy;
}
```

この構造は、Gmail 領収書解析、Google 連携、App Store 購読連携、AI 補助をあとから追加しても破綻しにくい形です。

## MVP 用の簡易データ構造

最初の実装では、複雑な推定や AI 処理は入れず、静的な補助プロフィールとして始めます。

```dart
class ServiceAiProfile {
  final String serviceId;
  final List<SubscriptionPlanCandidate> planCandidates;
  final List<String> billingCycleCandidates;
  final List<String> paymentMethodHints;
  final String? cancelGuideText;
  final List<String> userConfirmationPrompts;
}

class SubscriptionPlanCandidate {
  final String planName;
  final String? price;
  final String currency;
  final String billingCycle;
  final String description;
  final bool requiresUserConfirmation;
}
```

MVP では `price` を空にできるようにします。料金は地域、時期、決済経路、プラン改定で変わるため、Fela が確定値として扱わない方針です。

## 具体例

### Amazon

プラン候補:

- Amazon Prime
- Prime Video
- Kindle Unlimited
- Amazon Music Unlimited
- Audible

請求周期候補:

- 月額
- 年額

ユーザー確認が必要な項目:

- どの Amazon サービスを契約しているか
- 月額か年額か
- 実際の料金
- 次回更新日
- 支払い方法

注意:

Amazon は複数のサブスクサービスを持つため、「Amazon」1件だけで確定せず、プラン選択を補助する必要があります。

### Netflix

プラン候補:

- 広告つき
- スタンダード
- プレミアム

請求周期候補:

- 月額

自動入力してよい情報:

- サービス名
- ログイン URL
- 解約 URL
- 請求周期候補として月額

ユーザー確認が必要な項目:

- 現在のプラン
- 実際の料金
- 次回更新日
- 支払い方法

### ChatGPT

プラン候補:

- Free
- Plus
- Pro
- Team

請求周期候補:

- 月額
- 年額

ユーザー確認が必要な項目:

- 個人契約か Team 契約か
- 現在のプラン
- 実際の料金
- 次回更新日
- 支払い方法

注意:

ChatGPT は個人向けとチーム向けで管理方法や請求が異なるため、プラン名だけで契約状態を確定しないことが重要です。

### YouTube

プラン候補:

- YouTube Premium
- YouTube Music Premium
- YouTube Premium Family
- YouTube Channel Membership

請求周期候補:

- 月額

ユーザー確認が必要な項目:

- どの YouTube プランか
- 個人 / ファミリー / メンバーシップのどれか
- Web 決済、Google Play、App Store 決済のどれか
- 実際の料金
- 次回更新日

注意:

YouTube は Google アカウントと紐づき、同じサービス内に複数の支払い形態が存在する可能性があります。

## 自動入力してよい情報

Fela が候補として自動入力してよい情報は、サービスごとに公開・一般化されている情報に限ります。

- サービス名
- カテゴリ
- ドメイン
- ログイン URL
- 解約 URL
- サポート URL
- ヘルプ URL
- 通貨の初期値
- 請求周期候補
- プラン名候補
- 「複数プランがあります」などの案内
- AutoFill 対応候補
- TOTP 対応候補

これらは確定情報ではなく、ユーザー入力を減らすための初期値または候補として扱います。

## ユーザー確認が必要な情報

以下はユーザーごとに異なるため、Fela が勝手に確定して保存してはいけません。

- 契約中かどうか
- 契約中のプラン
- 実際の料金
- 月額 / 年額などの実契約周期
- 次回更新日
- 支払い方法
- カード情報
- 請求元
- 解約済みかどうか
- ID / メールアドレス
- パスワード
- TOTP secret

Service AI Profile はこれらを直接決めるのではなく、「確認してください」「候補から選んでください」という導線を作るために使います。

## Gmail 連携 / Google 連携 / App Store 購読連携との関係

### Gmail 連携

将来的に Gmail 連携を行う場合、領収書メールからサービス名、金額、更新日候補を抽出できる可能性があります。

Service AI Profile は、領収書のサービス照合や確認項目の提示に使えます。ただし、メール本文を解析する場合はユーザーの明示的な許可が必要です。

### Google 連携

Google アカウント連携では、取得できる情報の範囲が API とユーザー許可に依存します。

Service AI Profile は、Google 連携で得られた候補情報を Fela のサービス単位に整理するための照合データとして使えます。

### App Store 購読連携

App Store の購読情報は Apple 側で管理されており、Fela が勝手にすべての購読情報を読み取れる前提にはしません。

現実的な補助案:

- ユーザーによる手動入力
- 共有シート経由
- スクリーンショットや明細をもとにした補助入力
- App Store の購読確認画面への案内

Service AI Profile は、取り込まれた候補をサービス名、プラン候補、請求周期候補に整理するために使います。

## Apple 審査・プライバシー注意点

Fela はセキュリティ・アカウント管理アプリとして、プライバシー上の説明が特に重要です。

守るべき方針:

- ユーザーのメール、購読、決済情報を勝手に取得しない
- Apple Passwords / iCloud Keychain の中身を勝手に読む設計にしない
- AI 解析を行う場合は、何を解析するか明示する
- パスワードや TOTP secret を外部 AI に送らない
- 推定情報を確定情報として表示しない
- 「自動で契約を検出」「自動で解約」など誤解を招く表現を避ける
- Gmail 連携や領収書解析は、ユーザーの明示操作と許可を前提にする

審査向けの説明方針:

Fela は、ユーザーが保存した情報と公開されているサービス情報をもとに、アカウント管理とサブスク管理を補助するアプリです。ユーザーごとの契約情報は、ユーザー確認後に保存します。

## MVP で最初に実装すべき範囲

最初の実装では、AI 処理や外部連携を入れず、静的な Service AI Profile として開始します。

MVP 範囲:

- `ServiceAiProfile` モデル
- `ServiceAiProfileRepository`
- Amazon / Netflix / ChatGPT / YouTube の4件
- プラン候補
- 請求周期候補
- 解約導線の説明
- ユーザー確認プロンプト
- サービス追加画面での候補表示

初期 UI で出す情報:

- プランを選択（任意）
- 料金は確認して入力してください
- 更新日はあとで設定できます
- 解約ページはこちら

MVP の最重要方針:

Service AI Profile は、ユーザーごとの契約情報を勝手に確定するものではありません。Fela がサービスごとの候補情報を準備し、ユーザーが確認して保存する体験を作るための補助レイヤーです。
