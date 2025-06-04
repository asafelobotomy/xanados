#!/bin/bash
set -e

echo "[INFO] Running XanadOS package chooser..."

CONFIG="/etc/xanados/package-options.conf"
if [ -f "$CONFIG" ]; then
	# shellcheck source=/etc/xanados/package-options.conf
	source "$CONFIG"
fi

case "$KERNEL" in
xanmod)
	pacman -Syu --needed --noconfirm linux-xanmod
	pacman -Rns --noconfirm linux-zen || true
	;;
*)
	pacman -Syu --needed --noconfirm linux-zen
	pacman -Rns --noconfirm linux-xanmod || true
	;;
esac
