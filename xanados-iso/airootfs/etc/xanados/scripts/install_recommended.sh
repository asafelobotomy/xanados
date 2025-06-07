#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
init_logging install_recommended

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

