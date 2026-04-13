# KeyNest GTM / Positioning

## 1. 結論
KeyNest は「汎用の無料認証アプリ」として戦うより、
「小規模〜中規模組織が、自社ブランドで早く導入できる軽量認証アプリ」として売る方が勝ちやすい。

個人ユーザーも獲得対象にはするが、製品メッセージの中心は以下に置く。

- TOTP コード表示
- Push 承認
- クラウド復元
- 企業ブランド化
- 軽量導入

## 2. 競合と差別化

### Google Authenticator
強い点:
- 無料
- 軽量
- 知名度が高い

弱い点:
- Push 承認が主役ではない
- 組織導入向けの体験が弱い
- ブランド化できない

KeyNest の差別化:
- コード表示だけでなく Push 承認まで一体化
- 機種変更/復元まで一つの導線にまとめる
- 組織ごとのブランドに寄せやすい

### Microsoft Authenticator
強い点:
- パスワードレス/通知承認/企業導入の完成度が高い
- Microsoft Entra の既存顧客基盤が強い
- 公式価格は Entra ID P1 が USD 6/ユーザー/月、P2 が USD 9/ユーザー/月（年契約）

弱い点:
- Microsoft 圏に強く依存
- 小規模 SaaS や独自認証体験には過剰

KeyNest の差別化:
- Microsoft 導入前提なしで軽量に入れられる
- 特定ベンダー色を薄くできる
- 自社サービス用の専用認証体験を作りやすい

### Okta Verify
強い点:
- 組織導入・MFA・Push 承認で強い
- TOTP も Push もサポート
- Okta Workforce Identity Starter は USD 6/ユーザー/月級の価格帯から始まる

弱い点:
- Okta 導入前提
- 小さいプロダクトや独立 SaaS には重い

KeyNest の差別化:
- Okta 全体を入れずに、承認アプリだけの体験を持てる
- 小規模プロダクトでも導入しやすい
- ホワイトラベルに寄せやすい

### Duo Mobile
強い点:
- Push 承認 UX が強い
- 企業の MFA / device trust に強い

弱い点:
- Cisco / Duo の文脈が前提
- 個別プロダクトの専用ブランドには向きにくい

KeyNest の差別化:
- 組織固有ブランドに寄せられる
- TOTP + Push + Restore を一つにまとめられる

## 3. 需要のある顧客

### 最重要ターゲット
- 20〜500人規模の SaaS 企業
- 社内ツール/顧客向け管理画面を持つ会社
- Okta や Entra は重いが、Push 承認と復元は欲しい会社

### 次点ターゲット
- セキュリティ感度の高い個人
- IT 管理者
- 小規模チームの管理者

### 避けるべき主戦場
- 「無料の認証コードアプリ」としてだけ訴求する市場
- ここは Google / Microsoft / Authy / 1Password 系が強い

## 4. 製品メッセージ

### 主メッセージ
- 企業向けの軽量認証アプリ
- TOTP、Push 承認、クラウド復元を一つに集約
- 自社ブランドで展開できる認証体験

### サブメッセージ
- 社員や顧客が迷わないサインイン承認
- 端末変更時も復元しやすい
- 既存の大規模 IAM より軽く始められる

## 5. 収益化

### 収益化の本線
1. B2B 席課金
- 価格帯の初期仮説: 300〜800円 / ユーザー / 月
- 最初は最低契約金額を付ける
- 例: 月額 3万円〜

2. ホワイトラベル初期費用
- ブランド差し替え
- App 名 / ロゴ / 配色 / 文言 / bundle ID を調整
- 初期費用 20万〜100万円

3. エンタープライズ保守/監査ログ/API
- 承認ログ
- 端末管理
- 監査エクスポート
- Push 承認 API

### 個人向けはどうするか
個人課金は補助線としてはありだが、主戦場にはしない。

やるなら:
- Pro バックアップ
- 複数端末復元
- 高度なエクスポート
- 追加セキュリティ設定

ただし、個人向け単独で大きく伸ばすのは難しい。

## 6. 早く広める方法

### 最短で広がるやり方
1. 個人向け無料配布でユーザー母数を作る
2. その上で B2B 導入相談を受ける
3. 法人向けには Push 承認とブランド化を前面に出す

### 実行順
1. App Store / Play にまず出す
2. LP を作る
3. GitHub / Product Hunt / X / Reddit / Hacker News で配布
4. 個人ユーザーから反応を取る
5. 反応が取れた導線を法人向け営業資料に変換する

### 配布時の訴求軸
- 認証コードだけではない
- Push 承認対応
- 機種変更に強い
- 企業ブランドにも対応可能

### 伸ばし方
- 無料版: TOTP + 基本復元
- Pro / Team: Push 承認、チーム管理、監査ログ
- 法人営業: セキュリティ導入の軽量代替として提案

## 7. 今直すべきプロダクト項目

### 最優先
1. Face ID ループの解消
2. iOS 実機の安定起動
3. ブランド名混在の除去（Venemo / Aegis / KeyNest）

### 次点
4. Push 承認の本番運用仕様
- 承認対象の明確化
- ログ保存
- 拒否/失効

5. クラウド復元の安心感
- 暗号化の説明
- 復元時の本人確認
- 失効端末の扱い

6. ストア説明文の再設計
- 個人向け無料アプリの文脈ではなく、業務利用可能性を前面に出す

## 8. 直近 2 週間の実行計画

### Phase 1
- iOS 実機起動を安定化
- TestFlight へ上げる
- App Store / Play 用スクリーンショットを作成

### Phase 2
- LP 作成
- 3パターンの説明文を AB テスト
- 個人ユーザー向け無料公開

### Phase 3
- 法人向け資料作成
- 「Okta Verify 的な体験を軽量導入できる」訴求で営業
- 3社ヒアリング

## 9. 意思決定
今の KeyNest は、
- 企業向けを本線
- 個人向け無料配布を拡散導線
として扱うのが最も合理的。

個人向け一本で勝つのではなく、
「個人に広めて、法人導入へ繋げる」形にする。

## 10. 参考
- Okta Verify overview: https://help.okta.com/en-us/Content/Topics/Mobile/okta-verify-overview.htm
- Okta pricing: https://www.okta.com/en-ca/pricing/
- Microsoft Authenticator: https://support.microsoft.com/en-us/authenticator/about-microsoft-authenticator
- Microsoft Entra pricing: https://www.microsoft.com/en-us/security/business/microsoft-entra-pricing
- Duo Push: https://duo.com/product/multi-factor-authentication-mfa/authentication-methods/duo-push
- Duo Mobile overview: https://duo.com/product/multi-factor-authentication-mfa/duo-mobile-app
