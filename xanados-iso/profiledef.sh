#!/usr/bin/env bash
# shellcheck disable=SC2034

# ISO label and versioning
iso_name="xanados"
iso_label="XANADOS_$(date +%Y%m)"
iso_publisher="XanadOS Project"
iso_application="XanadOS Live/Install ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="xanados"
buildmodes=("iso")
bootmodes=("uefi-x64.grub.esp")

# Root filesystem image configuration
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=()
airootfs_image_tool_options+=("-comp" "zstd" "-Xcompression-level" "19")

# File permissions (example: secure shadow)
file_permissions=()
file_permissions+=(["/etc/shadow"]="0:0:400")
