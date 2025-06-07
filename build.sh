#!/usr/bin/env bash
set -euo pipefail

WORK_DIR=${WORK_DIR:-work}
OUT_DIR=${OUT_DIR:-out}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROFILE_DIR="$SCRIPT_DIR/xanados-iso"

mkdir -p "$WORK_DIR" "$OUT_DIR"

echo "[XanadOS] Building ISO..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

echo "[XanadOS] Build complete. ISO is in $OUT_DIR"

