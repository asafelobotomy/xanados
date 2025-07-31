#!/bin/bash
# xanadOS ISO Building Script
# This script creates a bootable xanadOS ISO based on Arch Linux

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
WORK_DIR="$BUILD_DIR/work"
OUT_DIR="$BUILD_DIR/out"
CACHE_DIR="$BUILD_DIR/cache"

# xanadOS Configuration
XANADOS_VERSION="0.1.0-alpha"
ISO_NAME="xanadOS"
ISO_LABEL="XANADOS"
ISO_FILENAME="${ISO_NAME}-${XANADOS_VERSION}-x86_64.iso"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    local required_commands=("mkarchiso" "pacman" "mksquashfs" "xorriso")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please run: ./scripts/setup/dev-environment.sh"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

# Clean previous build
clean_build() {
    print_status "Cleaning previous build..."
    
    if [ -d "$WORK_DIR" ]; then
        sudo rm -rf "$WORK_DIR"
        print_success "Cleaned work directory"
    fi
    
    if [ -d "$OUT_DIR" ]; then
        rm -rf "$OUT_DIR"
        mkdir -p "$OUT_DIR"
        print_success "Cleaned output directory"
    fi
}

# Create build directories
create_build_dirs() {
    print_status "Creating build directories..."
    
    mkdir -p "$WORK_DIR"
    mkdir -p "$OUT_DIR"
    mkdir -p "$CACHE_DIR"
    
    print_success "Build directories created"
}

# Copy archiso profile
setup_archiso_profile() {
    print_status "Setting up archiso profile..."
    
    # Copy the releng profile as base
    local archiso_profile="/usr/share/archiso/configs/releng"
    local profile_dir="$BUILD_DIR/archiso-profile"
    
    if [ ! -d "$archiso_profile" ]; then
        print_error "Archiso releng profile not found at $archiso_profile"
        exit 1
    fi
    
    # Clean and copy profile
    rm -rf "$profile_dir"
    cp -r "$archiso_profile" "$profile_dir"
    
    print_success "Archiso profile copied to $profile_dir"
    
    # Customize the profile for xanadOS
    customize_profile "$profile_dir"
}

# Customize archiso profile for xanadOS
customize_profile() {
    local profile_dir="$1"
    print_status "Customizing archiso profile for xanadOS..."
    
    # Update packages.x86_64 with gaming packages
    cat > "$profile_dir/packages.x86_64" << 'EOF'
# Base system
alsa-utils
amd-ucode
arch-install-scripts
archinstall
b43-fwcutter
base
bind
brltty
broadcom-wl
btrfs-progs
clonezilla
cloud-init
cryptsetup
darkhttpd
ddrescue
dhclient
dhcpcd
diffutils
dmidecode
dmraid
dnsmasq
dosfstools
e2fsprogs
edk2-shell
efibootmgr
espeakup
ethtool
exfatprogs
f2fs-tools
fatresize
fsarchiver
gnu-netcat
gpart
gpm
gptfdisk
grml-zsh-config
grub
hdparm
hyperv
intel-ucode
irssi
iw
iwd
jfsutils
kitty-terminfo
less
lftp
libfido2
libusb-compat
linux
linux-atm
linux-firmware
livecd-sounds
lsscsi
lvm2
lynx
man-db
man-pages
mc
mdadm
memtest86+
mkinitcpio
mkinitcpio-archiso
mkinitcpio-nfs-utils
modemmanager
mtools
nano
nbd
ndisc6
nfs-utils
nilfs-utils
nmap
ntfs-3g
nvme-cli
open-iscsi
open-vm-tools
openconnect
openssh
openvpn
partclone
parted
partimage
pcsclite
ppp
pptpclient
pv
qemu-guest-agent
refind
reflector
reiserfsprogs
rp-pppoe
rsync
rxvt-unicode-terminfo
screen
sdparm
sg3_utils
smartmontools
sof-firmware
squashfs-tools
sudo
syslinux
systemd-resolvconf
tcpdump
terminus-font
testdisk
tmux
tpm2-tss
udftools
usb_modeswitch
usbmuxd
usbutils
vim
virtualbox-guest-utils-nox
vpnc
wireless-regdb
wireless_tools
wpa_supplicant
wvdial
xfsprogs
xl2tpd
zsh

# Gaming specific packages
steam
lutris
wine
winetricks
gamemode
lib32-gamemode
mangohud
lib32-mangohud
corectrl

# Graphics drivers
mesa
lib32-mesa
vulkan-radeon
lib32-vulkan-radeon
vulkan-intel
lib32-vulkan-intel
nvidia
lib32-nvidia-utils
nvidia-dkms

# Audio
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
lib32-pipewire
lib32-pipewire-jack

# Desktop environment
plasma-meta
kde-applications-meta
sddm

# Development tools
git
base-devel
vim
code
EOF
    
    # Update profiledef.sh
    cat > "$profile_dir/profiledef.sh" << EOF
#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="$ISO_NAME"
iso_label="$ISO_LABEL"
iso_publisher="xanadOS Project <https://github.com/xanados>"
iso_application="xanadOS Live/Rescue CD"
iso_version="$XANADOS_VERSION"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
EOF
    
    print_success "Archiso profile customized for xanadOS"
}

# Build the ISO
build_iso() {
    print_status "Building xanadOS ISO..."
    
    local profile_dir="$BUILD_DIR/archiso-profile"
    
    cd "$BUILD_DIR"
    
    # Build with mkarchiso
    sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$profile_dir"
    
    # Rename the ISO to our naming convention
    local generated_iso
    generated_iso=$(find "$OUT_DIR" -name "*.iso" -type f | head -n 1)
    if [ -n "$generated_iso" ]; then
        mv "$generated_iso" "$OUT_DIR/$ISO_FILENAME"
        print_success "ISO built successfully: $OUT_DIR/$ISO_FILENAME"
    else
        print_error "ISO build failed - no ISO file found"
        exit 1
    fi
}

# Calculate checksums
generate_checksums() {
    print_status "Generating checksums..."
    
    cd "$OUT_DIR"
    
    if [ -f "$ISO_FILENAME" ]; then
        sha256sum "$ISO_FILENAME" > "$ISO_FILENAME.sha256"
        md5sum "$ISO_FILENAME" > "$ISO_FILENAME.md5"
        print_success "Checksums generated"
    else
        print_error "ISO file not found for checksum generation"
        exit 1
    fi
}

# Show build summary
show_summary() {
    print_success "=== xanadOS Build Complete! ==="
    echo
    print_status "Build Summary:"
    echo "  - Version: $XANADOS_VERSION"
    echo "  - ISO File: $OUT_DIR/$ISO_FILENAME"
    echo "  - Size: $(du -h "$OUT_DIR/$ISO_FILENAME" | cut -f1)"
    echo "  - SHA256: $(cat "$OUT_DIR/$ISO_FILENAME.sha256" | cut -d' ' -f1)"
    echo
    print_status "Next steps:"
    echo "1. Test the ISO in a virtual machine"
    echo "2. Burn to USB with: dd if=$OUT_DIR/$ISO_FILENAME of=/dev/sdX bs=4M status=progress"
    echo "3. Boot and test gaming performance"
    echo
}

# Main function
main() {
    echo "=== xanadOS ISO Builder ==="
    echo "Building xanadOS v$XANADOS_VERSION"
    echo
    
    check_prerequisites
    clean_build
    create_build_dirs
    setup_archiso_profile
    build_iso
    generate_checksums
    show_summary
}

# Handle interruption
trap 'print_error "Build interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
