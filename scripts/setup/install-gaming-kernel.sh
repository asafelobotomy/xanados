#!/bin/bash
# xanadOS Gaming Kernel Installer
# Installs optimized kernel options for gaming performance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}

install_linux_zen() {
    print_status "Installing Linux Zen kernel (gaming optimized)..."
    sudo pacman -S --noconfirm linux-zen linux-zen-headers
    print_success "Linux Zen kernel installed"
}

install_linux_cachyos() {
    print_status "Installing CachyOS kernel (BORE scheduler)..."

    # Add CachyOS repository
    if ! grep -q "cachyos" /etc/pacman.conf; then
        print_status "Adding CachyOS repository..."
        sudo tee -a /etc/pacman.conf << 'REPO'

[cachyos]
SigLevel = Required DatabaseOptional
Server = https://mirror.cachyos.org/repo/$arch/$repo
REPO

        # Import GPG key
        sudo pacman-key --recv-keys F3B607488DB35A47
        sudo pacman-key --lsign-key F3B607488DB35A47
        sudo pacman -Sy
    fi

    # Install CachyOS kernel
    sudo pacman -S --noconfirm linux-cachyos linux-cachyos-headers
    print_success "CachyOS kernel with BORE scheduler installed"
}

configure_gaming_parameters() {
    print_status "Configuring gaming kernel parameters..."

    # Create gaming-optimized sysctl configuration
    sudo tee /etc/sysctl.d/99-gaming-optimization.conf << 'SYSCTL'
# Gaming optimization parameters
vm.swappiness=1
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=5
vm.dirty_ratio=10

# Network optimization for gaming
net.core.rmem_default=65536
net.core.rmem_max=16777216
net.core.wmem_default=65536
net.core.wmem_max=16777216
net.core.netdev_max_backlog=5000

# CPU scheduling optimization
kernel.sched_autogroup_enabled=0
kernel.sched_child_runs_first=1
SYSCTL

    print_success "Gaming kernel parameters configured"
}

main() {
    local kernel_type="${1:-zen}"

    case "$kernel_type" in
        zen)
            install_linux_zen
            ;;
        cachyos)
            install_linux_cachyos
            ;;
        both)
            install_linux_zen
            install_linux_cachyos
            ;;
        *)
            echo "Usage: $0 [zen|cachyos|both]"
            exit 1
            ;;
    esac

    configure_gaming_parameters

    print_status "Gaming kernel installation completed"
    print_warning "Reboot required to use new kernel"
}

main "$@"
