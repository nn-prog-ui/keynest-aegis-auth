#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="${AUTOPILOT_ENV_FILE:-$ROOT_DIR/scripts/release/autopilot.env}"
LOG_DIR="$ROOT_DIR/docs/release/launchd_logs"
mkdir -p "$LOG_DIR"

DATE_TAG="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="$LOG_DIR/${DATE_TAG}_launchd_runner.log"
exec >>"$LOG_FILE" 2>&1

echo "=== KeyNest launchd runner start: $(date '+%Y-%m-%d %H:%M:%S %Z') ==="
echo "ROOT_DIR=$ROOT_DIR"

if [[ -f "$ENV_FILE" ]]; then
  echo "Loading env file: $ENV_FILE"
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
else
  echo "Env file not found (optional): $ENV_FILE"
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
export TZ_REGION="${TZ_REGION:-Asia/Tokyo}"

"$ROOT_DIR/scripts/release/autopilot_by_date.sh"

echo "=== KeyNest launchd runner end: $(date '+%Y-%m-%d %H:%M:%S %Z') ==="
