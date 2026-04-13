# KeyNest App Review Notes

最終更新: 2026-04-13

## App Information
- App Name: KeyNest
- Platform: iOS
- Bundle ID: `com.nnprogui.keynestauth`
- Category: Business / Utilities（最終選択に合わせて修正）

## Review Notes (貼り付け用)
```text
KeyNest is an authenticator app that provides:
- QR code registration for OTP accounts
- RFC6238 compatible one-time code generation
- Push-based sign-in approval requests
- Encrypted backup and restore for device migration
- Biometric / device-auth protection for stored account data

The camera is used only for QR code onboarding.
Notifications are used only for sign-in approval and security-related prompts.
Biometric authentication is used only to protect access to the app and sensitive account data.

No paid content is required for review.
The app shell can be opened without a third-party paid account.

If review needs a guided scenario, please use the in-app account registration flow and local test data.
If a deeper push-approval test flow is required, we can provide additional review instructions on request.
```

## Review Guidance
- カメラ: QR 登録時のみ
- 通知: Push 承認 / セキュリティ通知のみ
- Face ID: アプリ保護のみ
- バックアップ: 暗号化済みデータの保存 / 復元

## 提出前チェック
- [ ] App Store の説明文を最新化
- [ ] スクリーンショットを最新化
- [ ] Privacy Policy URL を設定
- [ ] Support URL を設定
- [ ] Export Compliance を回答
- [ ] 年齢レーティングを確認
- [ ] 必要なら審査向け補足を更新
