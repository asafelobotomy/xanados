#!/bin/bash
set -e

LOGFILE="/var/log/postinstall.log"
ERRORLOG="/var/log/postinstall-error.log"
rotate_logs() {
    local f="$1" max=5
    for ((i=max; i>=1; i--)); do
        [ -f "${f}.${i}" ] && mv "${f}.${i}" "${f}.$((i+1))"
    done
    [ -f "$f" ] && mv "$f" "$f.1"
}
rotate_logs "$LOGFILE"
rotate_logs "$ERRORLOG"
exec > >(tee -a "$LOGFILE") 2> >(tee -a "$LOGFILE" "$ERRORLOG" >&2)

echo "[XanadOS] Starting post-install tasks..."

# Detect dev mode
if [ -f /etc/xanados/dev_mode ]; then
	echo "[XanadOS] Development mode detected."
	# Add any dev mode specific logic here
fi

# Secure Boot setup placeholder
if [ -f /etc/xanados/secureboot_enabled ]; then
        echo "[XanadOS] Secure Boot enabled, configuring keys..."
        if command -v sbctl >/dev/null 2>&1; then
                if sbctl create-keys && sbctl enroll-keys --yes-this-is-dangerous; then
                        echo "[XanadOS] Secure Boot keys enrolled." 
                else
                        echo "[ERROR] sbctl failed to enroll keys, continuing installation."
                fi
        else
                echo "[WARNING] sbctl not installed, skipping Secure Boot configuration."
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
