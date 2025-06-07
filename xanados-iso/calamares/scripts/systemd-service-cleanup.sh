#!/bin/bash
set -e

LOGFILE="/var/log/systemd-service-cleanup.log"
rotate_logs() {
    local f="$1" max=5
    for ((i=max; i>=1; i--)); do
        [ -f "${f}.${i}" ] && mv "${f}.${i}" "${f}.$((i+1))"
    done
    [ -f "$f" ] && mv "$f" "$f.1"
}
rotate_logs "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[XanadOS] Starting systemd service cleanup at $(date)"

# Disable live-session services
echo "[XanadOS] Disabling live-session services..."
systemctl disable livecd-alsa-unmuter.service || true
systemctl disable livecd-talk.service || true

# Disable virtual machine guest services
echo "[XanadOS] Disabling VM guest services..."
systemctl disable vboxservice.service || true
systemctl disable vmtoolsd.service || true
systemctl disable hv_fcopy_daemon.service || true
systemctl disable hv_kvp_daemon.service || true
systemctl disable hv_vss_daemon.service || true
systemctl disable vmware-vmblock-fuse.service || true

# Enable necessary networking services
echo "[XanadOS] Enabling NetworkManager..."
systemctl enable NetworkManager.service

# Disable conflicting network services
echo "[XanadOS] Disabling systemd-networkd and systemd-resolved..."
systemctl disable systemd-networkd.service || true
systemctl disable systemd-resolved.service || true

echo "[XanadOS] Cleanup complete."
