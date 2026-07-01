# Fela Subscription Ledger Specification

## Subscription Ledger の役割

Subscription Ledger は、Felaが管理しているすべてのサービスから、ユーザーの毎月・毎年の支払いを集計し、デジタルライフ全体の固定費を可視化する台帳である。

Subscription Ledger は家計簿ではない。食費、交通費、日用品など生活全体の支出を管理するものではなく、Amazon、Netflix、ChatGPT、YouTube、Adobe、Canva、クラウド、AIサービスなど、デジタルサービスにかかる継続費用を整理する。

目的は、ユーザーが「何にいくら払っているか」を迷わず把握できること。料金が不明なサービスは無理に確定せず、Felaが次に補完すべき情報として扱う。

## 入力

Subscription Ledger は Single Service Record を入力とする。

主な入力項目:

- serviceId
- serviceName
- category
- price
- currency
- billingCycle
- subscriptionStatus
- renewalDate
- paymentMethod
- planName
- sources
- confidence
- confirmedValues
- candidateValues

料金や更新日はユーザー確認済みの値を優先する。Import Candidate、Service AI Profile、Gmail、App Store、CSV、銀行明細などから得た未確認候補は、確定値として集計しない。

## 出力

Subscription Ledger は、以下の集計結果を出力する。

### 今月の合計

今月発生する見込みのサブスク料金合計。

- 月額サービスはそのまま加算
- 年額サービスは月割り換算と実請求月の両方を扱える設計にする
- 不明料金は合計に含めず、「金額未設定」として別表示する

### 年間合計

1年間に発生する見込みのサブスク料金合計。

- 月額サービスは `price * 12`
- 年額サービスは `price`
- 週額やその他周期は正規化ルールに従って換算する

### サービス別一覧

サービスごとの支払い状況を表示する。

- サービス名
- カテゴリ
- プラン
- 料金
- 請求周期
- 次回更新日
- 支払い方法
- 契約状態
- 情報の確定状態

### カテゴリ別集計

ServiceMaster のカテゴリや将来の分類情報を使って集計する。

例:

- AI
- 動画・音楽
- 買い物
- 仕事
- クラウド
- 金融
- SNS
- メール

### AIサービス合計

ChatGPT、Claude、Gemini、Perplexity、GitHub Copilot など、AI関連サービスの固定費合計。

v1では ServiceMaster / Service AI Profile に存在するカテゴリから集計する。将来はユーザーの分類修正も反映する。

### 動画サービス合計

Netflix、YouTube Premium、Amazon Prime Video、Disney+ などの動画・音楽系サービス合計。

### クラウドサービス合計

iCloud、Google One、Microsoft 365、Dropbox、Adobe Cloud などのクラウド・仕事系サービス合計。

## 料金が不明な場合

料金が不明なサービスは、合計金額に含めない。

表示方針:

- 「料金未設定」と表示する
- 「あとで設定できます」と案内する
- Service AI Profile の料金候補がある場合は参考候補として表示する
- Gmail / App Store / 銀行明細から候補が見つかった場合も、ユーザー確認前は確定扱いしない

Subscription Ledger は、料金不明のサービスを「エラー」と扱わない。Felaが次に補完すべき情報として扱う。

## 無料プランの扱い

無料プランは `price = 0` として扱う。

表示方針:

- 合計金額には 0円として含める
- サービス一覧には表示する
- 「無料プラン」と明示する
- 将来有料化・トライアル終了の候補がある場合は注意候補として表示する

無料サービスもログイン情報、AutoFill、2FAの管理対象なので、Subscription Ledger から完全に除外しない。

## 解約済みサービスの扱い

解約済みサービスは、通常の合計から除外する。

ただし、以下のために履歴として保持する。

- 過去に利用していたサービスの確認
- 再契約時の候補
- ログイン情報やデータ削除確認
- 支払いがまだ続いていないかの確認

表示方針:

- active / canceled / trial / unknown のように契約状態を持つ
- canceled は合計対象外
- trial は終了日がある場合に注意表示
- unknown は確認が必要な候補として扱う

## 複数通貨の扱い

複数通貨は、v1では無理に自動換算しない。

v1方針:

- 通貨ごとに別集計する
- JPY、USD、EUR などを混ぜて単一合計にしない
- 為替換算が必要な場合は「参考換算」と明示する

将来方針:

- ユーザーの基準通貨を設定できる
- 為替レートの取得元と日時を保持する
- 換算結果は参考値として表示する
- 実請求額はカード明細や銀行明細の確定値を優先する

## Felaの羅針盤との整合性

Subscription Ledger は、Felaの羅針盤に従う。

- ユーザーのタップを減らす
  - 登録済みサービスから自動で集計する
  - ユーザーに電卓計算をさせない
- ユーザーに考えさせない
  - 今月、年間、カテゴリ別に分けて見せる
  - 不明な情報は「未設定」「あとで確認」として扱う
- ユーザーのデジタルライフを整理する
  - サブスク料金をサービス詳細と結びつける
  - ログイン情報、AutoFill、2FA、支払い情報を1サービスに集約する
- 同じ情報を二度入力させない
  - Single Service Record の確認済み値から台帳を作る
  - ImportやData Merge Engineで得た情報を再利用する

## MVPでの最小形

v1 MVPでは、以下に絞る。

- Single Service Record の確認済み `price` / `currency` / `billingCycle` / `subscriptionStatus` を使う
- 今月の合計を表示する
- 年間合計を表示する
- サービス別一覧を表示する
- カテゴリ別集計を表示する
- 料金未設定サービスを別表示する
- 無料プランを 0円として表示する
- 解約済みサービスを合計対象外にする
- 複数通貨は通貨別に集計する

MVPでは、為替自動換算、銀行明細連携、カード明細連携、AIによる自動確定は行わない。

最重要方針:

Subscription Ledger は、Felaが管理するデジタルサービスの固定費台帳である。家計簿ではなく、ユーザーのデジタルライフにかかる継続コストを見える化し、1サービス1管理画面へ整理するための基盤として扱う。
