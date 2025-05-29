#!/bin/bash
LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[XanadOS] Starting Gaming Stack installation at $(date)"

if ! pacman -Syu --needed --noconfirm steam lutris heroic-games-launcher gamemode mangohud vkbasalt protontricks; then
  echo "[ERROR] Gaming Stack installation failed."
  exit 1
fi

echo "[XanadOS] Gaming tools installed successfully at $(date)"
