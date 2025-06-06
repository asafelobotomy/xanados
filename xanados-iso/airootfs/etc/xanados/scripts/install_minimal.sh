#!/bin/bash
set -e
LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

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

echo "[XanadOS] Starting Minimal environment installation at $(date)"

if ! run_cmd paru -Syu --needed --noconfirm plasma-desktop dolphin konsole networkmanager; then
	echo "[ERROR] Minimal environment installation failed."
	exit 1
fi

echo "[XanadOS] Minimal environment ready at $(date)"
