#!/usr/bin/env bash

# ISO Label
iso_name="xanados"
iso_label="XANADOS_$(date +%Y%m)"
iso_publisher="XanadOS Project"
iso_application="XanadOS Live/Install ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="xanados"
buildmodes=("iso")
bootmodes=("uefi-x64.systemd-boot.esp")

# File system
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=()
airootfs_image_tool_options+=("-comp" "zstd" "-Xcompression-level" "19")
file_permissions=()

# Optional: copy files with root:root
file_permissions+=(["/etc/shadow"]="0:0:400")

# Default ISO boot background
# You can later set GRUB and Plymouth themes in /airootfs

# Custom hooks (none yet)
# file_permissions+=([“/usr/bin/xanados-hook”]=“0:0:755”)
