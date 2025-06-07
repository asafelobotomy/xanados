#!/usr/bin/env bash
set -euo pipefail

echo "[XanadOS] Saving network configuration persistently..."

SYSROOT="$1"

if [ -d "$SYSROOT/etc/NetworkManager/system-connections" ]; then
    echo "[XanadOS] NetworkManager configs found, setting permissions..."
    chmod 600 "$SYSROOT"/etc/NetworkManager/system-connections/*
fi

chroot "$SYSROOT" systemctl enable NetworkManager.service

echo "[XanadOS] Network persistence setup complete."

