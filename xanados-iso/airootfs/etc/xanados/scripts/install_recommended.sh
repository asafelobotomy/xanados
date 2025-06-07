#!/bin/bash
set -e
LOGFILE="/tmp/welcome_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1
echo "[INFO] Log file: $LOGFILE"

check_paru() {
    if ! command -v paru >/dev/null 2>&1; then
        echo "[ERROR] paru is not installed. Please install paru first." >&2
        exit 1
    fi
}

run_cmd() {
    if $DRY_RUN; then
        echo "DRY RUN: $*"
    else
        "$@"
    fi
}

DRY_RUN=false
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

echo "[XanadOS] Starting Full Recommended Stack installation at $(date)"

if ! run_cmd paru -Syu --needed --noconfirm flatpak firefox vlc gwenview btop timeshift snapper; then
        echo "[ERROR] Full Recommended Stack installation failed."
        exit 1
fi

echo "[XanadOS] Note: Spotify is available from the AUR as 'spotify-launcher'."
echo "Install it manually after setting up an AUR helper."

echo "[XanadOS] Full package set installed successfully at $(date)"
