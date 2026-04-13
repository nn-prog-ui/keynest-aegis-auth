# Nemokey ストアスクリーンショット

## 必須ショット（iOS / Android 共通）
1. Welcome 画面（`Nemokey` と価値が一目で伝わる画面）
2. コード一覧（2件以上のアカウント表示）
3. Push 承認画面（承認/拒否が分かる画面）
4. クラウド復元画面
5. 端末認証ロック画面

## 推奨追加ショット
6. QR登録画面
7. バックアップコード管理画面
8. アカウント詳細画面

## 推奨キャプション
- 認証コードと Push 承認を1つに集約
- QR で素早く登録
- 重要な承認を安全に処理
- 機種変更後もクラウド復元で再開
- Face ID / 生体認証で保護

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
- `ios_03_push.png`
- `ios_04_restore.png`
- `ios_05_lock.png`
- Android も `android_01_*.png` 形式に統一
