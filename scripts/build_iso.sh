#!/bin/bash
set -euo pipefail

LOG_DIR="$(cd "$(dirname "$0")/.." && pwd)/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/iso-build.log"

# Ensure required tools are installed; attempt to install if missing
for cmd in mkarchiso grub-install; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if command -v pacman >/dev/null 2>&1; then
      case "$cmd" in
        mkarchiso) pkg=archiso ;;
        grub-install) pkg=grub ;;
      esac
      sudo pacman -Sy --needed --noconfirm "$pkg" >/dev/null
    fi
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: required command '$cmd' not found." >&2
      exit 1
    fi
  fi
done

# Update local package repository
REPO_DIR="$(cd "$(dirname "$0")/../packages/repo" && pwd)"
if [ ! -d "$REPO_DIR" ]; then
  echo "Error: Repository directory '$REPO_DIR' does not exist. Please create it or check the path." >&2
  exit 1
fi

if ! compgen -G "$REPO_DIR"/*.pkg.tar.zst >/dev/null; then
  echo "No packages found in '$REPO_DIR'. Building from PKGBUILDs..." >&2
  bash "$(dirname "$0")/build_packages.sh"
fi

if ! compgen -G "$REPO_DIR"/*.pkg.tar.zst >/dev/null; then
  echo "Error: No package files (*.pkg.tar.zst) found in '$REPO_DIR' after building." >&2
  exit 1
fi

repo-add "$REPO_DIR/xanados.db.tar.gz" "$REPO_DIR"/*.pkg.tar.zst

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
