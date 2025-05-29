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

# File system and compression
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=()
airootfs_image_tool_options+=("-comp" "zstd" "-Xcompression-level" "19")
file_permissions=()

# Permissions example
file_permissions+=(["/etc/shadow"]="0:0:400")

# Paths - adjust this to your build directory if different
iso_prep="$(pwd)/work/x86_64"

# Ensure EFI bootloader is installed properly
install_efi_bootloader() {
    mkdir -p "${iso_prep}/efiboot/EFI/BOOT"
    bootctl --path="${iso_prep}/efiboot" install
    cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi "${iso_prep}/efiboot/EFI/BOOT/BOOTX64.EFI"
}

# Call the EFI bootloader installer at the end of ISO prep
install_efi_bootloader
