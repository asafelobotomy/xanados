#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="${1:-$REPO_ROOT/logs}"
ERROR_FILE="$REPO_ROOT/failed_checks_and_errors/errors1.md"

SHA="${GITHUB_SHA:-$(git -C "$REPO_ROOT" rev-parse HEAD)}"
RUN_URL=""
if [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ] && [ -n "${GITHUB_RUN_ID:-}" ]; then
  RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi

TIMESTAMP="$(date -u '+%Y-%m-%d %H:%M UTC')"

# Gather error lines from log files
ERROR_LINES=""
if ls "$LOG_DIR"/*.log >/dev/null 2>&1; then
  ERROR_LINES=$(grep -i "error" "$LOG_DIR"/*.log | tail -n 20 || true)
fi

if [ -z "$ERROR_LINES" ]; then
  echo "No error lines found" >&2
  exit 0
fi

{
  echo "\n---"
  echo "\n### CI Failure - $TIMESTAMP"
  echo ""
  echo "**Commit:** \`$SHA\`"
  if [ -n "$RUN_URL" ]; then
    echo "**Run:** [$GITHUB_RUN_ID]($RUN_URL)"
  fi
  echo ""
  echo '\```text'
  echo "$ERROR_LINES"
  echo '\```'
} >> "$ERROR_FILE"
