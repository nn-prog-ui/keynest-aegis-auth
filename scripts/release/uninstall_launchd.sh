#!/usr/bin/env bash
set -euo pipefail

LABEL="${AUTOPILOT_LAUNCHD_LABEL:-com.keynest.release-autopilot}"
AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$AGENT_DIR/${LABEL}.plist"
KEEP_PLIST="${1:-}"

launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl disable "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true

if [[ "$KEEP_PLIST" != "--keep-plist" && -f "$PLIST_PATH" ]]; then
  rm -f "$PLIST_PATH"
fi

echo "Uninstalled launchd agent: $LABEL"
if [[ "$KEEP_PLIST" == "--keep-plist" ]]; then
  echo "Kept plist: $PLIST_PATH"
fi
