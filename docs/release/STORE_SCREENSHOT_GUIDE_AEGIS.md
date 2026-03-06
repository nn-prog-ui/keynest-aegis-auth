# Aegis Auth ストアスクリーンショット

## 必須ショット（iOS/Android共通）
1. Welcome画面（`Welcome to Aegis Auth`）
2. コード一覧（2件以上のアカウント表示）
3. 承認タブ（Pending request + Approve/Deny）
4. クラウドバックアップシート
5. 端末認証ロック画面

## 推奨サイズ
- iOS 6.7": 1290x2796
- iOS 6.5": 1242x2688
- Android Phone: 1080x1920 以上

## 撮影コマンド例
### Android
```bash
adb exec-out screencap -p > docs/release/screenshots/android_home.png
```

### iOS Simulator
```bash
xcrun simctl io booted screenshot docs/release/screenshots/ios_home.png
```

## 命名規約
- `ios_01_welcome.png`
- `ios_02_codes.png`
- `ios_03_approval.png`
- `ios_04_backup.png`
- `ios_05_lock.png`
- Android も同様に `android_01_*.png`
