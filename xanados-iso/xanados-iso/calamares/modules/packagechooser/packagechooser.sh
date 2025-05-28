#!/bin/bash

echo "[INFO] Running XanadOS package chooser..."

# Example logic (to be replaced by actual GUI selections)
if grep -q "STEAM=yes" /etc/xanados/package-options.conf; then
    pacman -Sy --noconfirm steam
fi
