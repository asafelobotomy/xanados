#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh disable=SC1091
source "$(dirname "$0")/common.sh"
init_logging install_minimal

DRY_RUN=false
export DRY_RUN
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

check_paru

echo "[XanadOS] Starting Minimal environment installation at $(date)"
if ! run_cmd paru -Syu --needed --noconfirm plasma-desktop dolphin konsole networkmanager; then
    echo "[ERROR] Minimal environment installation failed."
    exit 1
fi

echo "[XanadOS] Minimal environment ready at $(date)"

