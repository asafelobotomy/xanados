#!/usr/bin/env bash
# shellcheck source=xanados-iso/airootfs/etc/xanados/scripts/common.sh
source "$(dirname "$0")/common.sh"
init_logging install_recommended

# Prebuilt packages from xanados-iso/packages/repo include btrfs-assistant, brave, and paru.
DRY_RUN=false
BROWSER="brave"
while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run)
        DRY_RUN=true
        shift
        ;;
    --browser)
        if [[ -n ${2:-} ]]; then
            BROWSER="$2"
            shift 2
        else
            echo "[ERROR] --browser requires an argument" >&2
            exit 1
        fi
        ;;
    *)
        break
        ;;
    esac
done

check_paru

echo "[XanadOS] Starting Full Recommended Stack installation at $(date)"
if ! run_cmd paru -Syu --needed --noconfirm flatpak "$BROWSER" vlc gwenview btop timeshift snapper; then
    echo "[ERROR] Full Recommended Stack installation failed."
    exit 1
fi

echo "[XanadOS] Note: Spotify is available from the AUR as 'spotify-launcher'."
echo "Install it manually after setting up an AUR helper."

echo "[XanadOS] Full package set installed successfully at $(date)"
