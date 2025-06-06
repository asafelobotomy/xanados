#!/bin/bash
set -e

echo "[INFO] Running XanadOS package chooser..."

CONFIG="/etc/xanados/package-options.conf"
if [ -f "$CONFIG" ]; then
    # shellcheck source=/etc/xanados/package-options.conf
    # shellcheck disable=SC1091
    source "$CONFIG"
fi

KERNEL_CHOICE="${CALAMARES_KERNEL:-$KERNEL}"
KERNEL_CHOICE=${KERNEL_CHOICE:-linux}

# Map short names to package names
case "$KERNEL_CHOICE" in
    linux|base)   KERNEL_PKG="linux";;
    zen)          KERNEL_PKG="linux-zen";;
    lts)          KERNEL_PKG="linux-lts";;
    hardened)     KERNEL_PKG="linux-hardened";;
    xanmod)       KERNEL_PKG="linux-xanmod";;
    *)
        echo "[WARNING] Unknown kernel '$KERNEL_CHOICE', defaulting to linux"
        KERNEL_PKG="linux"
        ;;
esac

AVAILABLE_KERNELS=(linux linux-zen linux-lts linux-hardened linux-xanmod)

# Install selected kernel
pacman -Syu --needed --noconfirm "$KERNEL_PKG"

# Remove unneeded kernels
for k in "${AVAILABLE_KERNELS[@]}"; do
    if [ "$k" != "$KERNEL_PKG" ]; then
        pacman -Rns --noconfirm "$k" || true
    fi
done
