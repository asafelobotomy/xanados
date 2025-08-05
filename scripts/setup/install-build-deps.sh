#!/bin/bash
# xanadOS Build Dependencies Installer
# Installs missing build dependencies

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "xanadOS Build Dependencies Installer"
echo "===================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Don't run this script as root"
    exit 1
fi

# Missing compression tools needed for build targets
missing_packages=(
    "lrzip"      # For COMPRESSLRZ
    "lzop"       # For COMPRESSLZO
    "lzip"       # For COMPRESSLZ
)

# Check what's missing
to_install=()
for pkg in "${missing_packages[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        to_install+=("$pkg")
        print_warning "$pkg is missing"
    else
        print_status "$pkg is already installed"
    fi
done

if [[ ${#to_install[@]} -gt 0 ]]; then
    print_info "Installing missing packages: ${to_install[*]}"
    sudo pacman -S --needed "${to_install[@]}"
    print_status "Missing packages installed"
else
    print_status "All compression tools are already installed"
fi

print_status "Build dependencies check complete"
