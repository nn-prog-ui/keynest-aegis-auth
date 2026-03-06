#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT_DIR="$ROOT_DIR/docs/release/reports"
RELEASE_DIR="$ROOT_DIR/docs/release"
TEMPLATE_DIR="$RELEASE_DIR/templates"
mkdir -p "$REPORT_DIR"

PHASE="${1:-}"
if [[ -z "$PHASE" ]]; then
  echo "Usage: scripts/release/autopilot.sh <phase1|phase2|phase3|phase4>"
  exit 1
fi

DATE_TAG="$(date '+%Y%m%d_%H%M%S')"
REPORT_FILE="$REPORT_DIR/${DATE_TAG}_${PHASE}.md"
touch "$REPORT_FILE"

TMP_FILES=()
cleanup() {
  for file in "${TMP_FILES[@]:-}"; do
    if [[ -n "$file" && -f "$file" ]]; then
      rm -f "$file"
    fi
  done
}
trap cleanup EXIT

log() {
  echo "$1"
  echo "$1" >> "$REPORT_FILE"
}

run_cmd() {
  log ""
  log "## $*"
  (cd "$ROOT_DIR" && eval "$*") 2>&1 | tee -a "$REPORT_FILE"
}

check_required_file() {
  local file="$1"
  if [[ ! -f "$ROOT_DIR/$file" ]]; then
    log "❌ Missing required file: $file"
    return 1
  fi
  log "✅ Found: $file"
}

ensure_asc_env() {
  if [[ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" || -z "${APP_STORE_CONNECT_ISSUER_ID:-}" || -z "${APP_STORE_CONNECT_API_KEY_BASE64:-}" ]]; then
    log "⚠️ App Store Connect API key env vars are not fully set."
    log "   Required: APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_API_KEY_BASE64"
    return 1
  fi
  return 0
}

prepare_asc_key_file() {
  local tmp_key
  tmp_key="$(mktemp -t keynest_asc_key_XXXXXX.p8)"
  echo "$APP_STORE_CONNECT_API_KEY_BASE64" | base64 --decode > "$tmp_key"
  TMP_FILES+=("$tmp_key")
  echo "$tmp_key"
}

run_fastlane_with_key() {
  local platform_dir="$1"
  local lane_name="$2"
  local key_path="$3"

  run_cmd "cd ${platform_dir} && APP_STORE_CONNECT_API_KEY_PATH='${key_path}' bundle install"
  run_cmd "cd ${platform_dir} && APP_STORE_CONNECT_API_KEY_PATH='${key_path}' bundle exec fastlane ${lane_name}"
}

materialize_template() {
  local template_path="$1"
  local output_path="$2"
  local release_date="$3"
  local release_datetime="$4"

  if [[ ! -f "$template_path" ]]; then
    log "⚠️ Missing template: $template_path"
    return 1
  fi

  sed \
    -e "s/{{RELEASE_DATE}}/${release_date}/g" \
    -e "s/{{RELEASE_DATETIME}}/${release_datetime}/g" \
    "$template_path" > "$output_path"
  log "✅ Generated: $output_path"
}

run_common_checks() {
  run_cmd "flutter pub get"
  run_cmd "flutter analyze --no-fatal-infos --no-fatal-warnings"
  run_cmd "flutter test test/widget_test.dart"
  run_cmd "cd server && npm ci"
  run_cmd "cd server && node --check index.js"

  log ""
  log "## Required production files"
  check_required_file "android/app/google-services.json"
  check_required_file "ios/Runner/GoogleService-Info.plist"
}

phase1() {
  log "# Phase 1: FCM HTTP v1 + production setup checks"
  run_common_checks
}

phase2() {
  log "# Phase 2: device QA + TestFlight"
  mkdir -p "$RELEASE_DIR"

  local qa_output
  local release_date
  local release_datetime
  release_date="$(date '+%Y-%m-%d')"
  release_datetime="$(date '+%Y-%m-%d %H:%M:%S %Z')"
  qa_output="$RELEASE_DIR/QA_CHECKLIST_${DATE_TAG}.md"
  materialize_template \
    "$TEMPLATE_DIR/PHASE2_QA_CHECKLIST_TEMPLATE.md" \
    "$qa_output" \
    "$release_date" \
    "$release_datetime"

  run_common_checks

  run_cmd "flutter build ios --release --no-codesign"
  run_cmd "flutter build macos --release"

  if ensure_asc_env; then
    local key_path
    key_path="$(prepare_asc_key_file)"
    run_fastlane_with_key "ios" "ios testflight" "$key_path"
    run_fastlane_with_key "macos" "mac testflight" "$key_path"
  else
    log "⚠️ Skipped TestFlight upload because ASC env vars are missing."
  fi
}

phase3() {
  log "# Phase 3: fixes + release candidate"
  run_common_checks
  run_cmd "flutter build ios --release --no-codesign"
  run_cmd "flutter build macos --release"
  run_cmd "mkdir -p docs/release"
  run_cmd "git log --oneline --no-merges -n 100 > docs/release/RC_CHANGELOG_${DATE_TAG}.txt"
  run_cmd "cp pubspec.yaml docs/release/RC_PUBSPEC_${DATE_TAG}.yaml"
}

phase4() {
  log "# Phase 4: submit to App Review"
  mkdir -p "$RELEASE_DIR"

  local review_output
  local release_date
  local release_datetime
  release_date="$(date '+%Y-%m-%d')"
  release_datetime="$(date '+%Y-%m-%d %H:%M:%S %Z')"
  review_output="$RELEASE_DIR/APP_REVIEW_SUBMISSION_${DATE_TAG}.md"
  materialize_template \
    "$TEMPLATE_DIR/APP_REVIEW_TEMPLATE.md" \
    "$review_output" \
    "$release_date" \
    "$release_datetime"

  run_common_checks

  if ! ensure_asc_env; then
    log "❌ App Review submission requires ASC env vars."
    exit 2
  fi

  local key_path
  key_path="$(prepare_asc_key_file)"
  run_fastlane_with_key "ios" "ios submit_review" "$key_path"
  run_fastlane_with_key "macos" "mac submit_review" "$key_path"
}

case "$PHASE" in
  phase1) phase1 ;;
  phase2) phase2 ;;
  phase3) phase3 ;;
  phase4) phase4 ;;
  *)
    echo "Unknown phase: $PHASE"
    exit 1
    ;;
esac

log ""
log "✅ Completed $PHASE"
log "Report: $REPORT_FILE"
