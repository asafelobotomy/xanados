#!/bin/bash
# xanadOS Package Availability Checker
# Verifies all packages in the build list are available

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

echo "xanadOS Package Availability Checker"
echo "===================================="

package_file="/home/vm/Documents/xanadOS/build/packages.x86_64"

if [[ ! -f "$package_file" ]]; then
    print_error "Package file not found: $package_file"
    exit 1
fi

print_info "Checking package availability..."
print_info "Updating package database first..."

# Update package database
sudo pacman -Sy

unavailable_packages=()
available_count=0
total_packages=0

# Read packages from file, skipping comments and empty lines
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    package="${line// /}"  # Remove whitespace
    [[ -z "$package" ]] && continue

    ((total_packages++))

    # Check if package exists in repositories
    if pacman -Si "$package" &>/dev/null; then
        print_status "$package"
        ((available_count++))
    else
        print_error "$package (not available)"
        unavailable_packages+=("$package")
    fi
done < "$package_file"

echo ""
echo "===================================="
print_info "Package availability summary:"
print_info "Total packages checked: $total_packages"
print_info "Available packages: $available_count"

if [[ ${#unavailable_packages[@]} -gt 0 ]]; then
    print_error "Unavailable packages: ${#unavailable_packages[@]}"
    echo ""
    print_error "The following packages are not available:"
    for pkg in "${unavailable_packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    print_warning "Please remove these packages from packages.x86_64 or find alternatives"
    exit 1
else
    print_status "All packages are available!"
    print_status "Package list is ready for building"
fi
