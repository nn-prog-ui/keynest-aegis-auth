# Fela Data Merge Engine Specification

## Data Merge Engine の役割

Data Merge Engine は、Google / Apple / Microsoft / CSV / 手動入力 / 将来の銀行明細など、複数の情報源から届くサービス情報を 1 つのサービス管理画面へ統合する判断レイヤーである。

Fela は同じ情報を二度入力させない。Data Merge Engine は、同じサービスに関する候補を重複登録せず、既存の Single Service Record に集約する。

重要なのは、Data Merge Engine はユーザーの契約情報を勝手に確定する AI ではないこと。複数ソースから得た情報を整理し、ユーザーが迷わず確認できる状態にする。

## 入力

Data Merge Engine は、以下の情報源から候補データを受け取る。

- Google
  - Gmail 領収書候補
  - Google アカウント由来のサービス候補
  - Google Play / Google サービス連携候補
- Apple
  - App Store 購読候補
  - Apple ID 関連の購入・サブスク候補
- Microsoft
  - Microsoft アカウント由来のサービス候補
  - Microsoft 365 などの契約候補
- CSV
  - 既存パスワード管理ツールからのエクスポート
  - サービス名、URL、ID、パスワード候補
- 手動
  - ユーザーがFela上で入力したサービス情報
  - ユーザーが確認・修正したImport Candidate
- 銀行明細 / カード明細（将来）
  - 支払い先名
  - 金額
  - 通貨
  - 請求周期候補
  - 決済日候補

## 出力: Single Service Record

Data Merge Engine の出力は Single Service Record である。

Single Service Record は、1つのサービスにつき1つだけ存在する統合レコードであり、サービス詳細画面の情報源になる。

想定フィールド:

- serviceId
- serviceName
- aliases
- domains
- loginUrl
- cancelUrl
- supportUrl
- username
- hasPassword
- hasTotp
- autoFillStatus
- planName
- price
- currency
- billingCycle
- renewalDate
- paymentMethod
- subscriptionStatus
- sources
- confidence
- conflicts
- confirmedValues
- candidateValues
- secureCredentialRef
- lastConfirmedAt
- lastUpdatedAt
- history

password や totpSecret の生値は Single Service Record に直接保持しない。安全な保存先への参照だけを持つ。

## マージ優先順位

値の採用優先順位は以下を基本とする。

1. ユーザーが明示的に確認・保存した手動入力
2. 既存のKeychain保存済みログイン情報
3. ユーザー確認済みImport Candidate
4. ServiceMaster の静的情報
5. Service AI Profile / Recommendation Engine の候補情報
6. Google / Apple / Microsoft 由来の未確認Import Candidate
7. CSV由来の未確認候補
8. 銀行明細 / カード明細由来の推定候補

ユーザーが確認した情報は最も強い。外部ソースから新しい候補が来ても、確認済み情報を自動で上書きしない。

## 競合解決

競合が発生した場合は、即時上書きではなく候補として保持する。

例:

- Gmailでは Netflix が 1,490円、App Storeでは Netflix が 1,590円
- CSVでは ChatGPT のURLが `chat.openai.com`、ServiceMasterでは `chatgpt.com`
- 手動入力では更新日が 7月10日、領収書候補では 7月12日

解決方針:

- 確認済み値は維持する
- 新しい値は `candidateValues` に入れる
- 差分は `conflicts` として表示できる形にする
- 複数ソースが同じ値を示す場合は confidence を上げる
- 料金、更新日、支払い方法、解約状態はユーザー確認なしに確定しない
- パスワード、TOTP secret は候補マージ対象にしない

## ユーザー確認が必要な条件

以下はユーザー確認が必要。

- サービス判定の confidence が低い
- 既存サービスと候補サービスが似ているが完全一致しない
- 料金が既存値と異なる
- 更新日が既存値と異なる
- 支払い方法が既存値と異なる
- 解約済み / 契約中の状態が変わる
- 1つのサービスに複数契約がある可能性がある
- CSV由来のIDと既存KeychainのIDが異なる
- 銀行明細から推定したサービス名
- password / TOTP / Passkey など秘密情報に関わる変更

ユーザー確認画面では「既存情報」と「新しい候補」を比較し、採用 / 後で確認 / 無視を選べるようにする。

## 自動更新してよい条件

以下は自動更新してよい。

- ServiceMaster由来の静的情報
  - domains
  - loginUrl
  - cancelUrl
  - supportUrl
  - icon情報
- AutoFill登録状態
- 2FA登録有無
- ログイン情報有無
- Import source のメタ情報
- 最終検出日時
- confidence の更新
- 未確認候補の追加

条件付きで自動更新してよいもの:

- serviceName の表記ゆれ正規化
- domain の追加
- cancelUrl の補完
- loginUrl の補完

自動更新してはいけないもの:

- 確認済み料金
- 確認済み更新日
- 確認済み請求周期
- 確認済み支払い方法
- 解約状態
- password
- totpSecret
- Passkey

## 履歴管理

Data Merge Engine は、値の変化を追跡できるように履歴を持つ。

履歴に残す情報:

- source
- detectedAt
- detectedValue
- previousValue
- action
- userDecision
- confidence

action の例:

- candidateCreated
- candidateIgnored
- valueConfirmed
- valueUpdated
- conflictDetected
- sourceLinked
- sourceUnlinked

履歴はユーザーに細かく見せるためではなく、Felaが安全に統合判断を行うための内部根拠として扱う。

## Single Source of Truth の維持方法

Felaでは、1サービスにつき1つの Single Service Record を正とする。

維持方針:

- 新しい候補を受け取ったら、まず既存サービスを検索する
- 検索順は serviceId、domains、serviceName、aliases、source identifiers
- 一致すれば新規追加せず既存レコードを更新候補として扱う
- 一致しなければ新規候補として作成する
- confirmedValues と candidateValues を分ける
- 秘密情報は secureCredentialRef で参照する
- サービス詳細画面を最終的な管理画面にする

この設計により、Googleから来たChatGPT、CSVから来たChatGPT、手動で追加したChatGPTを1件に統合できる。

## Felaの設計原則との整合性

Data Merge Engine は、Felaの羅針盤に従う。

- ユーザーのタップを減らす
  - 既存サービスを自動で見つけ、重複追加を防ぐ
  - 分かる情報はFela側で補完する
- ユーザーに考えさせない
  - 競合は比較しやすい候補として提示する
  - 確定が必要な場面だけ確認を求める
- ユーザーのデジタルライフを整理する
  - ログイン、サブスク、AutoFill、2FAを1サービスに集約する
- 同じ情報を二度入力させない
  - 複数ソースから届いた情報を1サービス1管理画面へ統合する

## MVPでの最小形

v1 MVPでは、以下に絞る。

- Import Candidate 保存時に既存サービスを検索する
- 検索順は serviceId、domains、serviceName
- 一致すれば既存credential idを使って更新する
- 一致しなければ新規追加する
- 料金、更新日、請求周期は候補として扱う
- ユーザー確認後のみ保存する
- password / TOTP secret はKeychain保存を維持する
- AutoFill登録処理は既存のまま維持する

MVPでは高度な競合UIや履歴UIは作らない。ただし、将来拡張できるように、Data Merge Engine の考え方は最初から「追加」ではなく「同期・更新」を前提にする。
