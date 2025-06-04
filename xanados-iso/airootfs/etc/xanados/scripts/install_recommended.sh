#!/bin/bash
set -e
LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[XanadOS] Starting Full Recommended Stack installation at $(date)"

if ! pacman -Syu --needed --noconfirm flatpak firefox vlc gwenview btop timeshift snapper spotify-launcher; then
	echo "[ERROR] Full Recommended Stack installation failed."
	exit 1
fi

echo "[XanadOS] Full package set installed successfully at $(date)"
