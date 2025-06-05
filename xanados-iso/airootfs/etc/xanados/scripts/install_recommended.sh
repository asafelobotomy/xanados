#!/bin/bash
set -e
LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[XanadOS] Starting Full Recommended Stack installation at $(date)"

if ! paru -Syu --needed --noconfirm flatpak firefox vlc gwenview btop timeshift snapper; then
	echo "[ERROR] Full Recommended Stack installation failed."
	exit 1
fi

echo "[XanadOS] Note: Spotify is available from the AUR as 'spotify-launcher'."
echo "Install it manually after setting up an AUR helper."

echo "[XanadOS] Full package set installed successfully at $(date)"
