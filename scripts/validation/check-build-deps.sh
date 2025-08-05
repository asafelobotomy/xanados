#!/bin/bash
# xanadOS Build Dependency Checker
# This script validates build dependencies and environment

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

echo "xanadOS Build Dependency Checker"
echo "================================="

errors=0

# Check for required tools
required_tools=(
    "mkarchiso"
    "pacman"
    "makepkg"
    "git"
    "pigz"
    "xz"
)

# Check for optional tools
optional_tools=(
    "docker"
)

print_info "Checking required build tools..."
for tool in "${required_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        print_status "$tool found"
    else
        print_error "$tool not found"
        ((errors++))
    fi
done

print_info "Checking optional tools..."
for tool in "${optional_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        print_status "$tool found"
    else
        print_warning "$tool not found (optional)"
    fi
done

# Check for archiso
print_info "Checking archiso installation..."
if [[ -d /usr/share/archiso/configs/releng ]]; then
    print_status "archiso configuration found"
else
    print_error "archiso not properly installed"
    ((errors++))
fi

# Check build root structure
build_root="/home/vm/Documents/xanadOS/build"
print_info "Checking build directory structure..."

required_dirs=(
    "$build_root/automation"
    "$build_root/targets"
    "$build_root/cache"
    "$build_root/logs"
    "$build_root/work"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        print_status "$(basename "$dir") directory exists"
    else
        print_error "$(basename "$dir") directory missing: $dir"
        ((errors++))
    fi
done

# Check required files
print_info "Checking required configuration files..."
required_files=(
    "$build_root/packages.x86_64"
    "$build_root/targets/x86-64-v3.conf"
    "$build_root/targets/compatibility.conf"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        print_status "$(basename "$file") exists"
    else
        print_error "$(basename "$file") missing: $file"
        ((errors++))
    fi
done

# Check disk space (need at least 10GB)
print_info "Checking disk space..."
available_space=$(df "$build_root" | awk 'NR==2 {print $4}')
required_space=$((10 * 1024 * 1024))  # 10GB in KB

if [[ $available_space -gt $required_space ]]; then
    print_status "Sufficient disk space available ($(( available_space / 1024 / 1024 ))GB)"
else
    print_error "Insufficient disk space. Need 10GB, have $(( available_space / 1024 / 1024 ))GB"
    ((errors++))
fi

# Check package dependencies in packages.x86_64
print_info "Validating package dependencies..."
package_file="$build_root/packages.x86_64"

if [[ -f "$package_file" ]]; then
    # Check for essential packages
    essential_packages=(
        "base"
        "base-devel"
        "linux-zen"
        "archiso"
        "grub"
        "networkmanager"
    )

    missing_packages=()
    for pkg in "${essential_packages[@]}"; do
        if grep -q "^$pkg$" "$package_file"; then
            print_status "Essential package $pkg found"
        else
            print_error "Essential package $pkg missing from packages.x86_64"
            missing_packages+=("$pkg")
            ((errors++))
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        print_error "Missing essential packages: ${missing_packages[*]}"
    fi
else
    print_error "Package file not found: $package_file"
    ((errors++))
fi

# Summary
echo ""
echo "================================="
if [[ $errors -eq 0 ]]; then
    print_status "All dependency checks passed!"
    echo "Build environment is ready."
    exit 0
else
    print_error "Found $errors errors in build environment"
    echo "Please fix the above issues before building."
    exit 1
fi
