#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TZ_REGION="${TZ_REGION:-Asia/Tokyo}"
TODAY="${TODAY_OVERRIDE:-$(TZ="$TZ_REGION" date '+%Y-%m-%d')}"

PHASE=""
if [[ "$TODAY" > "2026-03-04" && "$TODAY" < "2026-03-13" ]]; then
  PHASE="phase1"
elif [[ "$TODAY" > "2026-03-12" && "$TODAY" < "2026-03-20" ]]; then
  PHASE="phase2"
elif [[ "$TODAY" > "2026-03-19" && "$TODAY" < "2026-03-25" ]]; then
  PHASE="phase3"
elif [[ "$TODAY" > "2026-03-24" && "$TODAY" < "2026-03-29" ]]; then
  PHASE="phase4"
fi

if [[ -z "$PHASE" ]]; then
  echo "No autopilot phase scheduled for $TODAY ($TZ_REGION)."
  exit 0
fi

echo "Running $PHASE for date $TODAY ($TZ_REGION)"
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "DRY_RUN=1: skip execution."
  exit 0
fi
"$ROOT_DIR/scripts/release/autopilot.sh" "$PHASE"
