#!/bin/bash

echo "[XanadOS] Running Post-Install Script..."

# Mount point of installed system
TARGET="/mnt"

# Check for Dev Mode
if [ -f "$TARGET/etc/xanados/dev_mode" ]; then
    echo "Enabling Dev Mode packages..."
    arch-chroot $TARGET pacman -Sy --noconfirm base-devel cmake openssh
fi

# Set Secure Boot status
if [ -f "$TARGET/etc/xanados/secureboot_enabled" ]; then
    echo "Secure Boot flag applied"
    touch $TARGET/etc/xanados/secureboot_enabled
fi

# Copy wallpapers/themes if available
if [ -d "/etc/xanados/themes" ]; then
    mkdir -p $TARGET/usr/share/xanados-themes
    cp -r /etc/xanados/themes/* $TARGET/usr/share/xanados-themes/
fi

# Enable Welcome App on first boot
mkdir -p $TARGET/etc/skel/.config/autostart
cp /etc/xanados/welcome.desktop $TARGET/etc/skel/.config/autostart/

echo "[XanadOS] Post-install complete."
exit 0
