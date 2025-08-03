#!/bin/bash
# xanadOS Hardware Optimization Installation Script
# Sets up automatic hardware detection and optimization
# Personal Use License - see LICENSE file

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

install_hardware_optimization() {
    log_info "Installing xanadOS hardware optimization system..."

    # Create required directories
    mkdir -p /etc/xanados
    mkdir -p /usr/local/bin
    mkdir -p /etc/gamemode.d

    # Copy hardware optimization script
    if [[ -f "scripts/setup/hardware-optimization.sh" ]]; then
        cp scripts/setup/hardware-optimization.sh /usr/local/bin/xanados-hardware-optimization.sh
        chmod +x /usr/local/bin/xanados-hardware-optimization.sh
        log_info "Hardware optimization script installed"
    else
        log_error "Hardware optimization script not found"
        return 1
    fi

    # Copy hardware info utility
    if [[ -f "scripts/utilities/xanados-hwinfo.sh" ]]; then
        cp scripts/utilities/xanados-hwinfo.sh /usr/local/bin/xanados-hwinfo
        chmod +x /usr/local/bin/xanados-hwinfo
        log_info "Hardware info utility installed"
    else
        log_warn "Hardware info utility not found"
    fi

    # Install systemd service
    if [[ -f "configs/services/xanados-hardware-optimization.service" ]]; then
        cp configs/services/xanados-hardware-optimization.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable xanados-hardware-optimization.service
        log_info "Hardware optimization service enabled"
    else
        log_warn "Hardware optimization service file not found"
    fi

    # Copy hardware profiles
    if [[ -d "configs/hardware-profiles" ]]; then
        cp -r configs/hardware-profiles /etc/xanados/
        log_info "Hardware profiles installed"
    else
        log_warn "Hardware profiles directory not found"
    fi

    log_info "Hardware optimization system installation completed!"
    log_info "Run 'sudo /usr/local/bin/xanados-hardware-optimization.sh' to apply optimizations now"
    log_info "Or reboot to apply optimizations automatically"
    log_info "Use 'xanados-hwinfo' to check system status"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Check if we're in the xanadOS directory
if [[ ! -f "README.md" ]] || ! grep -q "xanadOS" README.md 2>/dev/null; then
    log_error "Please run this script from the xanadOS root directory"
    exit 1
fi

install_hardware_optimization
