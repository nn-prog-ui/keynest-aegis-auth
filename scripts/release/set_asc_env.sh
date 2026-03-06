#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="$ROOT_DIR/scripts/release/autopilot.env"

KEY_ID=""
ISSUER_ID=""
P8_PATH=""
APNS_TEAM_ID_VALUE=""
APNS_KEY_ID_VALUE=""

usage() {
  cat <<USAGE
Usage:
  scripts/release/set_asc_env.sh \
    --key-id <APP_STORE_CONNECT_API_KEY_ID> \
    --issuer-id <APP_STORE_CONNECT_ISSUER_ID> \
    --p8 <path/to/AuthKey_XXXXXXXXXX.p8> \
    [--apns-team-id <APNS_TEAM_ID>] \
    [--apns-key-id <APNS_KEY_ID>]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key-id)
      KEY_ID="${2:-}"
      shift 2
      ;;
    --issuer-id)
      ISSUER_ID="${2:-}"
      shift 2
      ;;
    --p8)
      P8_PATH="${2:-}"
      shift 2
      ;;
    --apns-team-id)
      APNS_TEAM_ID_VALUE="${2:-}"
      shift 2
      ;;
    --apns-key-id)
      APNS_KEY_ID_VALUE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$KEY_ID" || -z "$ISSUER_ID" || -z "$P8_PATH" ]]; then
  echo "Missing required arguments."
  usage
  exit 1
fi

if [[ ! -f "$P8_PATH" ]]; then
  echo "p8 file not found: $P8_PATH"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "autopilot.env not found: $ENV_FILE"
  exit 1
fi

P8_BASE64="$(base64 -i "$P8_PATH" | tr -d '\n')"

perl -0pi -e "s/^APP_STORE_CONNECT_API_KEY_ID=.*/APP_STORE_CONNECT_API_KEY_ID=$KEY_ID/m" "$ENV_FILE"
perl -0pi -e "s/^APP_STORE_CONNECT_ISSUER_ID=.*/APP_STORE_CONNECT_ISSUER_ID=$ISSUER_ID/m" "$ENV_FILE"
perl -0pi -e "s/^APP_STORE_CONNECT_API_KEY_BASE64=.*/APP_STORE_CONNECT_API_KEY_BASE64=$P8_BASE64/m" "$ENV_FILE"

if [[ -n "$APNS_TEAM_ID_VALUE" ]]; then
  perl -0pi -e "s/^APNS_TEAM_ID=.*/APNS_TEAM_ID=$APNS_TEAM_ID_VALUE/m" "$ENV_FILE"
fi

if [[ -n "$APNS_KEY_ID_VALUE" ]]; then
  perl -0pi -e "s/^APNS_KEY_ID=.*/APNS_KEY_ID=$APNS_KEY_ID_VALUE/m" "$ENV_FILE"
fi

echo "Updated: $ENV_FILE"
echo "Remaining empty keys:"
awk 'BEGIN{FS="="} /^[A-Z0-9_]+=/{if ($2=="") print "  - "$1}' "$ENV_FILE" || true
