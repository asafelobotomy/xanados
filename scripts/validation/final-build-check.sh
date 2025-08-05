#!/bin/bash
# xanadOS Comprehensive Build Readiness Check
# Final verification before building

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
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

print_section() {
    echo -e "${CYAN}▓▓▓ $1 ▓▓▓${NC}"
}

echo "xanadOS Comprehensive Build Readiness Check"
echo "==========================================="

errors=0

print_section "1. Build Tools Verification"

required_tools=(
    "mkarchiso"
    "pacman"
    "makepkg"
    "git"
    "pigz"
    "xz"
    "lrzip"
    "lzop"
    "lzip"
    "pbzip2"
    "lz4"
)

for tool in "${required_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        print_status "$tool found"
    else
        print_error "$tool not found"
        ((errors++))
    fi
done

print_section "2. Directory Structure"

build_root="/home/vm/Documents/xanadOS/build"
required_dirs=(
    "$build_root/automation"
    "$build_root/targets"
    "$build_root/cache"
    "$build_root/logs"
    "$build_root/work"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" && -w "$dir" ]]; then
        print_status "$(basename "$dir") directory ready"
    else
        print_error "$(basename "$dir") directory not ready: $dir"
        ((errors++))
    fi
done

print_section "3. Configuration Files"

# Check main files
required_files=(
    "$build_root/packages.x86_64"
    "$build_root/targets/x86-64-v3.conf"
    "$build_root/targets/x86-64-v4.conf"
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

print_section "4. Build Targets Validation"

# Test loading each target config
targets=("x86-64-v3" "x86-64-v4" "compatibility")

for target in "${targets[@]}"; do
    config_file="$build_root/targets/${target}.conf"
    if [[ -f "$config_file" ]]; then
        if source "$config_file" 2>/dev/null; then
            print_status "$target configuration loads successfully"
        else
            print_error "$target configuration has syntax errors"
            ((errors++))
        fi
    fi
done

print_section "5. Essential Package Check"

package_file="$build_root/packages.x86_64"
essential_packages=(
    "base"
    "base-devel"
    "linux-zen"
    "archiso"
    "grub"
    "networkmanager"
    "plasma-meta"
    "steam"
)

for pkg in "${essential_packages[@]}"; do
    if grep -q "^$pkg$" "$package_file" 2>/dev/null; then
        print_status "Essential package $pkg included"
    else
        print_error "Essential package $pkg missing from packages.x86_64"
        ((errors++))
    fi
done

print_section "6. System Resources"

# Check disk space (need at least 10GB)
available_space=$(df "$build_root" | awk 'NR==2 {print $4}')
required_space=$((10 * 1024 * 1024))  # 10GB in KB

if [[ $available_space -gt $required_space ]]; then
    print_status "Sufficient disk space available ($(( available_space / 1024 / 1024 ))GB)"
else
    print_error "Insufficient disk space. Need 10GB, have $(( available_space / 1024 / 1024 ))GB"
    ((errors++))
fi

# Check memory
available_memory=$(free -m | awk 'NR==2{print $7}')
if [[ $available_memory -gt 4096 ]]; then
    print_status "Sufficient memory available (${available_memory}MB)"
else
    print_warning "Low memory available (${available_memory}MB). Build may be slow."
fi

print_section "7. Permissions Check"

# Check if we can write to critical directories
critical_dirs=("$build_root/work" "$build_root/cache" "$build_root/logs")

for dir in "${critical_dirs[@]}"; do
    if [[ -w "$dir" ]]; then
        print_status "$(basename "$dir") directory writable"
    else
        print_error "$(basename "$dir") directory not writable"
        ((errors++))
    fi
done

print_section "Summary"

if [[ $errors -eq 0 ]]; then
    echo ""
    print_status "🎉 BUILD ENVIRONMENT IS READY!"
    echo ""
    print_info "You can now run the build pipeline:"
    echo "  ./build/automation/build-pipeline.sh --target x86-64-v3"
    echo "  ./build/automation/build-pipeline.sh --target compatibility"
    echo "  ./build/automation/build-pipeline.sh --all"
    echo ""
    exit 0
else
    echo ""
    print_error "❌ BUILD ENVIRONMENT HAS ISSUES!"
    print_error "Found $errors errors that must be fixed before building."
    echo ""
    exit 1
fi
