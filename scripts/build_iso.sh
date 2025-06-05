#!/bin/bash
set -euo pipefail

LOG_DIR="$(cd "$(dirname "$0")/.." && pwd)/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/iso-build.log"

# Rotate log if larger than 10MB
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -gt 10485760 ]; then
  mv "$LOG_FILE" "${LOG_FILE}.$(date -u +%Y%m%d%H%M%S)"
fi

{
  echo "### $(date -u '+%Y-%m-%d %H:%M:%S UTC') Starting ISO build"
  cd "$(dirname "$0")/../xanados-iso"
  sudo mkarchiso -v -o out .
  echo "### $(date -u '+%Y-%m-%d %H:%M:%S UTC') Build finished"
} | tee "$LOG_FILE"
