# Venemo 実装進捗（1〜7）

更新日: 2026-03-05

## 1. OAuth優先ログイン導線
- `lib/screens/login_screen.dart`
- OAuthを常時メイン導線に変更。
- アプリパスワードログインは「開発用」のみ表示可能。

## 2. サーバーセッション復元（自動ログイン）
- `lib/screens/splash_screen.dart`
- `lib/services/gmail_service.dart`
- 保存済みサーバーセッションを復元し、ログイン済みならそのまま受信画面へ遷移。

## 3. Plus契約状態の同期とAI利用制御（クライアント）
- `lib/services/subscription_service.dart`
- `lib/services/app_settings_service.dart`
- `lib/screens/venemo_plus_screen.dart`
- 契約状態をサーバーから同期し、Plus時のみAI機能を有効化。

## 4. Plus契約チェックのサーバー強制
- `server/index.js`
- `/api/ai/generate-text`
- `/api/ai/generate-reply`
- `/api/ai/improve-reply`
- いずれもサーバー側でPlus契約チェックを実施し、不正利用を防止。

## 5. 課金API基盤（Web / iOS / Android）
- `server/index.js`
- `lib/services/subscription_service.dart`
- Web: Stripe Checkout API作成済み。
- iOS / Android: 検証APIの受け口（verifyエンドポイント）実装済み。

## 6. HTML表示・返信可読性改善
- `lib/screens/mail_list_screen.dart`
- `lib/widgets/html_preview_view_web.dart`
- `lib/screens/email_reply_screen.dart`
- HTMLタブ表示時のフォールバック強化、本文ノイズ除去、引用可読性改善を実施。

## 7. 返信離脱時の下書き保護 + Venemo起動ルート整備
- `lib/screens/email_reply_screen.dart`
- `lib/main.dart`
- 返信離脱時に「キャンセル / 破棄 / 下書き保存」を選択可能。
- アプリ起動エントリをVenemoルーティングに統一。

## 注意（本番公開前）
- iOS/Androidの課金はストア連携の実検証が別途必要。
- Web決済はStripe本番キー設定が必要。
- `ALLOW_PASSWORD_LOGIN=false` 運用時はOAuthのみ表示する構成を推奨。
