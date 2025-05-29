#!/bin/bash
set -e

SYSROOT="$1"
USERNAME="$CALAMARES_USERNAME"

echo "[XanadOS] Setting up autostart files for user $USERNAME..."

AUTOSTART_SRC="$SYSROOT/etc/skel/.config/autostart/welcome.desktop"
AUTOSTART_DEST="$SYSROOT/home/$USERNAME/.config/autostart"

if [ -f "$AUTOSTART_SRC" ]; then
  mkdir -p "$AUTOSTART_DEST"
  cp "$AUTOSTART_SRC" "$AUTOSTART_DEST/"
  chown -R "$USERNAME:$USERNAME" "$SYSROOT/home/$USERNAME/.config"
  echo "[XanadOS] Autostart file copied successfully."
else
  echo "[WARNING] Autostart source file not found: $AUTOSTART_SRC"
fi
