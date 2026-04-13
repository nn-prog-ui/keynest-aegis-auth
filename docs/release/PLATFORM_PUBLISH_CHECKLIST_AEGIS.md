# KeyNest 配布チェックリスト（iOS / Android / macOS / Windows）

最終更新: 2026-04-13

## 0. 事前共通
- プロダクト名: `KeyNest`
- ポジショニング: `企業向け軽量認証アプリ。ただし個人無料配布で導入導線も作る`
- iOS Bundle ID: `com.nnprogui.keynestauth`
- Android Application ID: `com.aegisauth.app`
- macOS Bundle ID: `com.aegisauth.app.macos`
- 権限文言: `docs/release/PERMISSIONS_COPY_AEGIS.md`
- プライバシーポリシー: `docs/PRIVACY_POLICY_AEGIS_AUTH.md`
- GTM方針: `docs/release/GTM_POSITIONING_KEYNEST.md`
- ストア文言: `docs/release/STORE_COPY_KEYNEST.md`
- スクリーンショット: `docs/release/screenshots/`

## 1. iOS（App Store Connect / TestFlight）
1. App Store Connect で `com.nnprogui.keynestauth` の App レコードを維持
2. Xcode で `Archive` を作成し、`Distribute App -> App Store Connect`
3. TestFlight 内部テストに配布
4. 実機導線を確認
   - 追加
   - QR登録
   - コード表示
   - Push承認
   - クラウド復元
5. ストア情報、プライバシーポリシー、サポートURLを設定
6. 問題なければ App Review 提出

## 2. Android（Google Play）
1. Play Console 側の開発者アカウント確認を完了
2. GitHub Actions `aegis-release-build-all` の最新 green run から `aegis-android-aab` を取得
3. 内部テストへアップロード
4. Android 実機で導線確認
5. 問題なければ本番トラックへ昇格

## 3. macOS（Mac App Store か直接配布）
1. まずは GitHub Actions 生成物で配布検証
2. Mac App Store に出すなら Bundle ID と署名を App Store Connect 基準に最終調整
3. notarization / sandbox 対応の有無を確認

## 4. Windows
1. GitHub Actions 生成物で配布検証
2. Microsoft Store に出すなら MSIX / Store metadata を整備
3. 企業配布なら直接ダウンロード版も検討

## 5. 直近の優先順
1. iPhone 実機起動の安定化
2. TestFlight 内部配布
3. App Store / Play の掲載文言確定
4. LP公開
5. 初期ユーザー獲得

## 6. 初期拡散チャネル
- 既存人脈の情報システム担当
- セキュリティ感度の高い個人ユーザー
- X / Reddit / Product Hunt / Hacker News
- SaaS 運営者コミュニティ
- GitHub README / デモ動画
