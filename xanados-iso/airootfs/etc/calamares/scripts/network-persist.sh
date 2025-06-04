#!/bin/bash
set -e

echo "[XanadOS] Saving network configuration persistently..."

# Directory paths
SYSROOT="$1"

# Example for NetworkManager configs
if [ -d "$SYSROOT/etc/NetworkManager/system-connections" ]; then
	echo "[XanadOS] NetworkManager configs found, setting permissions..."
	chmod 600 "$SYSROOT/etc/NetworkManager/system-connections/"*
fi

# Ensure NetworkManager service enabled on installed system
chroot "$SYSROOT" systemctl enable NetworkManager.service

echo "[XanadOS] Network persistence setup complete."
