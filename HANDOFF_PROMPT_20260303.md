# Venemo 引き継ぎプロンプト（2026-03-03 現在）

あなたは `/Users/nemotonoritake/Documents/venemo_ai_mail` の Flutter Web メールアプリ **Venemo** の後任エンジニアです。
この時点の実装・要望・未解決項目を引き継ぎます。**既存の動作を壊さず、最小変更で進めてください。**

## 0. 起動・確認
- プロジェクト: `/Users/nemotonoritake/Documents/venemo_ai_mail`
- 起動コマンド: `flutter run -d chrome --web-port=8080`
- ログイン用テストアカウント: `lguantailang@gmail.com`

## 1. 現在のUI方針（ユーザー要望）
- Apple/macOS Mail.app 風のミニマルUI
- 白基調、薄いボーダー、余白重視、過度な装飾禁止
- アプリ名は **Venemo**

## 2. 直近で入っている主な実装
### 2-1. 右ペインの表示系
- 右ペインに本文プレビュー表示
- `本文` / `HTML` 切替を追加
- `HTMLソース` 表示切替を追加
- 返信アクション用本文はHTMLタグ除去して生成するロジックを追加

関連ファイル:
- `lib/screens/mail_list_screen.dart`
- `lib/services/gmail_service.dart`

### 2-2. 右ペインの操作ボタン
- 返信
- 全員に返信
- 転送
- ゴミ箱へ移動

関連ファイル:
- `lib/screens/mail_list_screen.dart`

### 2-3. 署名設定
- 設定画面で署名を編集/保存/削除できるUIを追加
- 送信・返信時に署名を付与

関連ファイル:
- `lib/screens/settings_screen.dart`
- `lib/screens/email_compose_screen.dart`
- `lib/screens/email_reply_screen.dart`
- `lib/services/gmail_service.dart`

## 3. ユーザーからの最新指摘（最優先）
1. **「返信ボタンがありません」**
   - ユーザー環境で見えていない。表示条件・レイアウト崩れ・画面幅依存を確認して修正すること。
2. 右ペインを使うなら、本文/HTMLを正しく見せること（見た目崩れ、文字羅列対策）。
3. 署名設定は「使える状態」を最優先（再起動後の保持も含めて確認）。

## 4. 技術的に確認すべきポイント
- `mail_list_screen.dart` の右ペインヘッダーで、返信/全員返信/転送/ゴミ箱ボタンが常に見えるか
- 画面幅が狭い場合でも、ボタンが潰れない・折り返し崩れしないか
- HTMLメールで `style/script/head` 等のノイズが本文として出ないか
- 署名が現在は `GmailService` のメモリ保持中心のため、必要なら永続化（例: local storage / shared preferences 相当）を追加

## 5. コード変更時のルール
- 既存で動作中の機能を壊さない
- 変更は最小限
- 1コマンドずつ実行し、エラーを日本語で説明
- ユーザーはターミナル不慣れなので丁寧に案内

## 6. 最後にやること
- `dart format` 対象ファイルを整形
- `flutter analyze --no-fatal-infos --no-fatal-warnings` を実行
- `flutter run -d chrome --web-port=8080` で起動確認
- 変更内容を日本語で要点報告
