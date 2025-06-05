#!/bin/bash
set -e
LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[XanadOS] Starting Minimal environment installation at $(date)"

if ! paru -Syu --needed --noconfirm plasma-desktop dolphin konsole networkmanager; then
	echo "[ERROR] Minimal environment installation failed."
	exit 1
fi

echo "[XanadOS] Minimal environment ready at $(date)"
