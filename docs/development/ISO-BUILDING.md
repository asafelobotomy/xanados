# 🎮 xanadOS ISO Building Guide

This guide explains how to build a complete bootable ISO for the xanadOS Gaming Distribution.

## 📋 Prerequisites

### System Requirements
- **Arch Linux** (required - must build on Arch)
- **8GB RAM minimum** (16GB recommended for faster builds)
- **50GB free disk space** (for build artifacts and packages)
- **Fast internet connection** (for downloading packages)

### Required Packages
```bash
# Install build dependencies
sudo pacman -S archiso git base-devel

# Optional: accelerate builds
sudo pacman -S ccache
```

## 🚀 Building the ISO

### 1. Quick Build
```bash
# Clone the repository
git clone https://github.com/asafelobotomy/xanadOS.git
cd xanadOS

# Build the ISO (automated)
./scripts/build/create-iso.sh build
```

### 2. Step-by-Step Build
```bash
# Setup build environment
./scripts/build/create-iso.sh setup

# Customize if needed (edit packages, configs)
# Edit: build/work/archiso/packages.x86_64

# Build the ISO
./scripts/build/create-iso.sh build

# Clean up afterwards
./scripts/build/create-iso.sh clean
```

## 📦 What Gets Built

### Package Categories
The ISO includes packages from:
- **Base System**: Essential Arch Linux packages
- **Gaming Stack**: Steam, Lutris, GameMode, Wine, DXVK
- **Graphics**: NVIDIA, AMD, Intel drivers with Vulkan
- **Audio**: PipeWire with low-latency gaming profile
- **Desktop**: KDE Plasma with gaming optimizations

### xanadOS Components
- **Scripts**: All xanadOS automation scripts
- **Configs**: Gaming-optimized system configurations
- **Installer**: Calamares-based graphical installer
- **Desktop**: Gaming desktop mode and tools

## 🎯 Build Output

### Files Generated
```
build/iso/
├── xanadOS-gaming-1.0.0-x86_64.iso    # Main ISO file
├── xanadOS-gaming-1.0.0-x86_64.iso.sha256  # Checksum
└── xanadOS-gaming-1.0.0-x86_64.iso.md5     # Checksum
```

### ISO Features
- **Live Environment**: Full KDE desktop with gaming tools
- **Installer**: Graphical Calamares installer
- **Hardware Support**: Automatic driver detection
- **Gaming Ready**: Pre-configured gaming environment

## ⚙️ Customization

### Adding Packages
Edit package lists in `packages/`:
```bash
# Add to base system
echo "package-name" >> packages/core/base-system.list

# Add gaming packages  
echo "game-package" >> packages/core/gaming.list

# Rebuild package list
./scripts/build/create-iso.sh build
```

### Custom Configurations
Modify files in `configs/` directory:
- `configs/desktop/` - Desktop customizations
- `configs/system/` - System-level settings
- `configs/network/` - Network optimizations

### Boot Parameters
Edit `build/bootloader/grub.cfg` for custom kernel parameters.

## 🔧 Troubleshooting

### Common Issues

#### Build Fails with Package Errors
```bash
# Update Arch packages
sudo pacman -Syu

# Clean package cache
sudo pacman -Sc

# Retry build
./scripts/build/create-iso.sh clean
./scripts/build/create-iso.sh build
```

#### Insufficient Disk Space
```bash
# Check available space
df -h

# Clean old builds
./scripts/build/create-iso.sh clean

# Clean pacman cache
sudo pacman -Sc
```

#### Permission Errors
```bash
# Ensure sudo access
sudo echo "Testing sudo access..."

# Fix ownership if needed
sudo chown -R $USER:$USER build/
```

### Build Logs
Check build logs in:
- `build/work/` - Archiso build logs
- `/tmp/xanados-build.log` - Custom build logs

## 📊 Build Performance

### Typical Build Times
- **Fast System (NVMe, 16GB RAM)**: 20-30 minutes
- **Standard System (SSD, 8GB RAM)**: 45-60 minutes  
- **Slow System (HDD, 4GB RAM)**: 90+ minutes

### Optimization Tips
```bash
# Use ccache for faster compilation
export USE_CCACHE=1

# Parallel downloads
echo "ParallelDownloads = 5" | sudo tee -a /etc/pacman.conf

# Use tmpfs for work directory (if you have enough RAM)
sudo mount -t tmpfs -o size=8G tmpfs build/work/
```

## 🎮 Testing the ISO

### Virtual Machine Testing
```bash
# Using QEMU
qemu-system-x86_64 -enable-kvm -m 4096 -cdrom build/iso/xanadOS-gaming-*.iso

# Using VirtualBox
VBoxManage createvm --name "xanadOS-Test" --register
VBoxManage modifyvm "xanadOS-Test" --memory 4096 --cpus 2
VBoxManage storagectl "xanadOS-Test" --name "IDE" --add ide
VBoxManage storageattach "xanadOS-Test" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium build/iso/xanadOS-gaming-*.iso
```

### Physical Hardware Testing
1. Flash ISO to USB drive with `dd` or Rufus
2. Boot from USB drive
3. Test live environment
4. Test installation process

## 📝 Distribution Notes

### ISO Characteristics
- **Architecture**: x86_64 only
- **Boot Mode**: UEFI + Legacy BIOS
- **Filesystem**: Btrfs with subvolumes
- **Swap**: Zswap + swapfile
- **Init**: systemd

### Post-Installation
After installation, users can:
```bash
# Complete gaming setup
xanados-gaming-setup.sh

# Enable gaming mode
gaming-desktop-mode.sh enable

# Run hardware optimization
priority3-hardware-optimization.sh
```

---

**Build Time**: ~30-60 minutes  
**ISO Size**: ~2-3GB  
**Target Platform**: Gaming PCs and laptops

🎮 **Ready to build your ultimate gaming distribution!**
