# Fela Import Flow Test Plan

## 方針

このテストは、Google連携からImport Candidate確認、サービス保存、既存サービス更新までの流れを確認するための手動テストです。

Import Candidateは自動保存せず、ユーザー確認後のみ保存されることを前提とします。
Gmail API、Gmail本文取得、添付ファイル取得、パスワード/TOTP取得は対象外です。

## TEST-001 Googleログイン

### 目的

FelaからGoogle Sign-Inを開始し、Googleアカウント連携が完了できることを確認する。

### 手順

1. Felaを起動する。
2. ホーム画面を開く。
3. 「Google連携を試す」をタップする。
4. Googleログイン画面が表示されることを確認する。
5. テスト対象のGoogleアカウントでログインする。

### 期待結果

- Googleログイン画面が正常に表示される。
- ログイン完了後、Felaへ戻る。
- accessTokenや個人情報が画面やログに表示されない。
- Gmail API権限は要求されない。

## TEST-002 Import Preview表示

### 目的

Googleログイン後、ImportPipelineのダミー候補がImport Preview画面に表示されることを確認する。

### 手順

1. TEST-001を完了する。
2. Googleログイン後にImport Preview画面へ遷移することを確認する。
3. 候補カードの表示内容を確認する。

### 期待結果

- Import Preview画面が表示される。
- ダミー候補が一覧表示される。
- サービス名、おすすめプラン、請求周期、料金候補、更新日候補が表示される。
- 「候補は自動保存されません」「あとから編集できます」が分かる文言になっている。

## TEST-003 Import Candidate保存

### 目的

Import Candidateを選択し、既存のServiceAccountAddScreenでユーザー確認後に保存できることを確認する。

### 手順

1. Import Preview画面で任意の候補を選ぶ。
2. 「内容を確認して保存へ」をタップする。
3. ServiceAccountAddScreenへ遷移することを確認する。
4. メールアドレス/IDとパスワードを入力する。
5. 必要に応じて詳細設定やサブスク情報を確認する。
6. 「保存する」をタップする。

### 期待結果

- Preview画面から直接保存されない。
- ServiceAccountAddScreenでユーザー確認後のみ保存される。
- serviceId、serviceName、billingCycleが候補から引き継がれる。
- loginUrl、cancelUrl、domainsはServiceMasterから補完される。
- 料金候補と更新日候補は確定値として自動保存されない。

## TEST-004 既存サービス更新

### 目的

既存サービスと一致するImport Candidateを保存した場合、新規追加ではなく既存サービスが更新されることを確認する。

### 手順

1. 事前に対象サービスを1件保存しておく。
2. Google連携からImport Previewを表示する。
3. 既存サービスと同じserviceId、domain、またはserviceNameを持つ候補を選ぶ。
4. 「内容を確認して保存へ」をタップする。
5. ServiceAccountAddScreenで情報を入力・確認する。
6. 保存する。

### 期待結果

- 既存サービスが検索される。
- 検索順はserviceId、domains、serviceNameの順である。
- 一致した場合、既存recordIdentifierでKeychain保存が更新される。
- サービス一覧に同じサービスが増えない。
- username、password、billingCycle、price、renewalDate、cancelUrl、loginUrlなどが更新対象として扱われる。

## TEST-005 重複登録防止

### 目的

同じサービスをImport Candidateから複数回保存しても、サービスが重複登録されないことを確認する。

### 手順

1. Import Candidateから対象サービスを保存する。
2. サービス一覧に戻り、対象サービスが1件だけあることを確認する。
3. もう一度同じ候補をImport Previewから保存する。
4. サービス一覧を再確認する。

### 期待結果

- 同じサービスが2件以上に増えない。
- 既存サービスが更新される。
- 保存完了後、サービス一覧で確認できる。

## TEST-006 保存後サービス一覧反映

### 目的

Import Candidate保存後、サービス一覧へ戻り、保存または更新された内容が反映されることを確認する。

### 手順

1. Import Candidateを選択する。
2. ServiceAccountAddScreenで保存する。
3. 保存後にサービス一覧へ戻る。
4. 対象サービスのカードを確認する。
5. 必要に応じて詳細画面を開く。

### 期待結果

- 保存後、サービス一覧へ戻る。
- 保存完了メッセージが表示される。
- 対象サービスが一覧に表示される。
- 既存更新の場合は同じカードに反映される。
- 詳細画面でログイン情報、サブスク情報、AutoFill状態を確認できる。

## TEST-007 AutoFillへの影響確認

### 目的

Import Candidate保存または既存サービス更新後も、AutoFill登録処理が従来通り動作することを確認する。

### 手順

1. Import Candidateからサービスを保存する。
2. 保存完了メッセージを確認する。
3. 既存サービス更新パターンでも同じ操作を行う。
4. AutoFill登録の成功/再試行メッセージを確認する。

### 期待結果

- AutoFill登録処理は保存後に従来通り試行される。
- AutoFill登録に失敗してもKeychain保存自体は成功扱いになる。
- 既存サービス更新時もrecordIdentifierに紐づいたAutoFill登録が再試行される。
- passwordやtotpSecretがログや画面に漏れない。

## TEST-008 Keychain更新確認

### 目的

Import Candidate保存時に、Keychain上の既存credentialが正しく更新されることを確認する。

### 手順

1. 対象サービスを事前に保存する。
2. サービス一覧または詳細画面で現在のusername、billingCycle、loginUrlなどを確認する。
3. Import Candidateから同じサービスを選択する。
4. ServiceAccountAddScreenで値を変更して保存する。
5. サービス一覧または詳細画面で更新後の内容を確認する。

### 期待結果

- 新しいrecordIdentifierは作られず、既存recordIdentifierのcredentialが更新される。
- username、password、billingCycle、price、renewalDate、cancelUrl、loginUrlなどが保存内容に応じて更新される。
- Keychain保存処理の安全性は維持される。
- SharedPreferencesにpasswordやTOTP secretが保存されない。
- Import Candidateは自動保存されず、ユーザー確認後のみKeychainに反映される。
