#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$REPO_ROOT/logs"
LOG_FILE="$LOG_DIR/docker-iso-build.log"
mkdir -p "$LOG_DIR"

# Rotate log if larger than 10MB
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -gt 10485760 ]; then
  mv "$LOG_FILE" "${LOG_FILE}.$(date -u +%Y%m%d%H%M%S)"
fi

{
  echo "### $(date -u '+%Y-%m-%d %H:%M:%S UTC') Starting Docker ISO build"
  docker run --rm \
    --privileged \
    -v "$REPO_ROOT":/repo \
    --workdir /repo/xanados-iso \
    archlinux:latest \
    bash -c 'pacman -Syu --noconfirm archiso grub bats && mkarchiso -v -o /repo/out .'
  echo "### $(date -u '+%Y-%m-%d %H:%M:%S UTC') Build finished"
} | tee "$LOG_FILE"
