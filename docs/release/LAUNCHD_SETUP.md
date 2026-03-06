# KeyNest launchd 自動実行セットアップ（GitHub不要）

この手順で、Macローカルだけで `autopilot` を毎日 09:00 (JST) に実行できます。

## 1. 環境ファイル作成

```bash
cd /Users/nemotonoritake/dev/venemo_ai_mail
cp scripts/release/autopilot.env.example scripts/release/autopilot.env
```

## 2. App Store Connect値を反映（必須）

```bash
cd /Users/nemotonoritake/dev/venemo_ai_mail
scripts/release/set_asc_env.sh \
  --key-id <APP_STORE_CONNECT_API_KEY_ID> \
  --issuer-id <APP_STORE_CONNECT_ISSUER_ID> \
  --p8 <AuthKey_XXXXXXXXXX.p8 のフルパス>
```

APNsを同時に入れる場合:

```bash
scripts/release/set_asc_env.sh \
  --key-id <APP_STORE_CONNECT_API_KEY_ID> \
  --issuer-id <APP_STORE_CONNECT_ISSUER_ID> \
  --p8 <AuthKey_XXXXXXXXXX.p8 のフルパス> \
  --apns-team-id <APNS_TEAM_ID> \
  --apns-key-id <APNS_KEY_ID>
```

## 3. launchd エージェントをインストール

```bash
cd /Users/nemotonoritake/dev/venemo_ai_mail
chmod +x scripts/release/*.sh
scripts/release/install_launchd.sh
```

初回動作をすぐ確認する場合:

```bash
scripts/release/install_launchd.sh --run-now
```

## 4. 状態確認

```bash
scripts/release/status_launchd.sh
```

## 5. ログ確認

- `docs/release/launchd_logs/launchd_stdout.log`
- `docs/release/launchd_logs/launchd_stderr.log`
- `docs/release/launchd_logs/*_launchd_runner.log`
- `docs/release/reports/*_phase*.md`

## 6. 停止・削除

```bash
scripts/release/uninstall_launchd.sh
```

plistを残して停止だけする場合:

```bash
scripts/release/uninstall_launchd.sh --keep-plist
```

## 補足

- 実行フェーズの判定は `scripts/release/autopilot_by_date.sh` が行います。
- 2026-03-05 〜 2026-03-28 の期間だけ `phase1` 〜 `phase4` を実行し、それ以外の日は何もしません。
- `autopilot.env` の未入力確認:
  - `awk 'BEGIN{FS="="} /^[A-Z0-9_]+=/{if ($2=="") print $1}' scripts/release/autopilot.env`
