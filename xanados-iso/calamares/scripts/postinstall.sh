#!/bin/bash
set -e

LOGFILE="/var/log/postinstall.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[XanadOS] Starting post-install tasks..."

# Detect dev mode
if [ -f /etc/xanados/dev_mode ]; then
	echo "[XanadOS] Development mode detected."
	# Add any dev mode specific logic here
fi

# Copy themes if source exists
THEME_SRC="/usr/share/xanados/themes"
THEME_DEST="/usr/share/themes"
if [ -d "$THEME_SRC" ]; then
	echo "[XanadOS] Copying themes from $THEME_SRC to $THEME_DEST"
	cp -r "$THEME_SRC" "$THEME_DEST"
else
	echo "[WARNING] Theme source directory $THEME_SRC not found."
fi

# Secure Boot setup placeholder
if [ -f /etc/xanados/secureboot_enabled ]; then
	echo "[XanadOS] Secure Boot enabled, configuring keys..."
	if command -v sbctl >/dev/null 2>&1; then
		sbctl create-keys
		sbctl enroll-keys --yes-this-is-dangerous
	else
		echo "[ERROR] sbctl not installed, cannot enroll Secure Boot keys."
		exit 1
	fi
else
	echo "[XanadOS] Secure Boot not enabled."
fi

# Setup Welcome App autostart if file exists
WELCOME_DESKTOP="/etc/xanados/welcome.desktop"
AUTOSTART_DIR="/etc/skel/.config/autostart"
if [ -f "$WELCOME_DESKTOP" ]; then
	echo "[XanadOS] Setting up Welcome App autostart."
	mkdir -p "$AUTOSTART_DIR"
	cp "$WELCOME_DESKTOP" "$AUTOSTART_DIR/"
else
	echo "[WARNING] Welcome desktop file $WELCOME_DESKTOP not found."
fi

# Systemd services management
echo "[XanadOS] Configuring systemd services..."

systemctl disable livecd-alsa-unmuter.service || true
systemctl disable autologin@tty1.service || true

systemctl enable NetworkManager.service
systemctl enable sshd.service
systemctl enable chronyd.service

systemctl disable systemd-timesyncd.service || true
systemctl disable systemd-resolved.service || true

echo "[XanadOS] Post-install tasks completed successfully."
