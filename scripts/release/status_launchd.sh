#!/usr/bin/env bash
set -euo pipefail

LABEL="${AUTOPILOT_LAUNCHD_LABEL:-com.keynest.release-autopilot}"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

echo "Label: $LABEL"
echo "Plist: $PLIST_PATH"
if [[ -f "$PLIST_PATH" ]]; then
  echo "Plist exists: yes"
else
  echo "Plist exists: no"
fi

if launchctl print "gui/$(id -u)/${LABEL}" >/tmp/keynest_launchd_status.$$ 2>&1; then
  cat /tmp/keynest_launchd_status.$$
  rm -f /tmp/keynest_launchd_status.$$
  exit 0
fi

cat /tmp/keynest_launchd_status.$$
rm -f /tmp/keynest_launchd_status.$$
exit 1
