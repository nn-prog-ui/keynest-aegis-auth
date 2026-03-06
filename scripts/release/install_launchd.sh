#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LABEL="${AUTOPILOT_LAUNCHD_LABEL:-com.keynest.release-autopilot}"
AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$AGENT_DIR/${LABEL}.plist"
RUNNER_SCRIPT="$ROOT_DIR/scripts/release/autopilot_launchd_runner.sh"
LOG_DIR="$ROOT_DIR/docs/release/launchd_logs"
OUT_LOG="$LOG_DIR/launchd_stdout.log"
ERR_LOG="$LOG_DIR/launchd_stderr.log"
RUN_NOW="${1:-}"

mkdir -p "$AGENT_DIR" "$LOG_DIR"

if [[ "$ROOT_DIR" == "$HOME/Documents/"* ]]; then
  echo "⚠️  Warning: project is under Documents ($ROOT_DIR)."
  echo "   launchd background jobs may hit macOS privacy restrictions (exit code 126)."
  echo "   If that happens, move the project to a non-protected path (e.g. ~/dev)."
fi

if [[ ! -x "$RUNNER_SCRIPT" ]]; then
  chmod +x "$RUNNER_SCRIPT"
fi

cat >"$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${RUNNER_SCRIPT}</string>
  </array>

  <key>WorkingDirectory</key>
  <string>${ROOT_DIR}</string>

  <key>RunAtLoad</key>
  <false/>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>EnvironmentVariables</key>
  <dict>
    <key>TZ_REGION</key>
    <string>Asia/Tokyo</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>

  <key>StandardOutPath</key>
  <string>${OUT_LOG}</string>
  <key>StandardErrorPath</key>
  <string>${ERR_LOG}</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true
if ! launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"; then
  echo "⚠️ launchctl bootstrap failed. Trying legacy load fallback..."
  launchctl load -w "$PLIST_PATH"
fi
launchctl enable "gui/$(id -u)/${LABEL}" || true

if [[ "$RUN_NOW" == "--run-now" ]]; then
  launchctl kickstart -k "gui/$(id -u)/${LABEL}"
fi

echo "Installed launchd agent."
echo "Label: $LABEL"
echo "Plist: $PLIST_PATH"
echo "Runner: $RUNNER_SCRIPT"
echo "Logs: $LOG_DIR"
echo "Status: launchctl print gui/$(id -u)/${LABEL}"
