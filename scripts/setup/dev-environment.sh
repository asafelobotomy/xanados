#!/bin/bash
# xanadOS Development Environment Setup Script
# This script sets up the development environment for building xanadOS

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/validation.sh"

set -e  # Exit on any error

# Configuration
LOG_FILE="/tmp/xanados-dev-environment.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Main function for development environment setup
setup_dev_environment() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            print_status "Setting up xanadOS development environment..."
            install_build_tools
            install_development_packages
            setup_build_directories
            configure_development_environment
            print_success "Development environment setup completed!"
            ;;
        configure)
            print_status "Configuring development environment..."
            configure_development_environment
            print_success "Configuration completed!"
            ;;
        status)
            check_dev_environment_status
            ;;
        clean)
            print_status "Cleaning development environment..."
            clean_build_directories
            print_success "Cleanup completed!"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Install build tools
install_build_tools() {
    print_section "Installing Build Tools"
    
    # Essential build tools
    local build_packages=()
    
    if command -v apt >/dev/null 2>&1; then
        build_packages=(
            "build-essential"
            "make"
            "cmake"
            "autoconf"
            "automake"
            "libtool"
            "pkg-config"
            "git"
            "curl"
            "wget"
            "rsync"
            "squashfs-tools"
            "genisoimage"
            "syslinux-utils"
            "isolinux"
        )
        
        print_info "Updating package cache..."
        if sudo apt update; then
            print_info "Installing build packages..."
            sudo apt install -y "${build_packages[@]}"
        else
            print_error "Failed to update package cache"
            return 1
        fi
        
    elif command -v dnf >/dev/null 2>&1; then
        build_packages=(
            "gcc"
            "gcc-c++"
            "make"
            "cmake"
            "autoconf"
            "automake"
            "libtool"
            "pkgconfig"
            "git"
            "curl"
            "wget"
            "rsync"
            "squashfs-tools"
            "genisoimage"
            "syslinux"
        )
        
        print_info "Installing development tools group..."
        sudo dnf groupinstall -y "Development Tools"
        print_info "Installing build packages..."
        sudo dnf install -y "${build_packages[@]}"
        
    elif command -v pacman >/dev/null 2>&1; then
        build_packages=(
            "base-devel"
            "cmake"
            "git"
            "curl"
            "wget"
            "rsync"
            "squashfs-tools"
            "cdrtools"
            "syslinux"
        )
        
        print_info "Installing build packages..."
        sudo pacman -S --noconfirm "${build_packages[@]}"
    else
        print_error "Unsupported package manager. Please install build tools manually."
        print_info "Required tools: ${build_packages[*]}"
        return 1
    fi
    
    print_success "Build tools installed"
}

# Install development packages
install_development_packages() {
    print_section "Installing Development Packages"
    
    # Development libraries and tools
    local dev_packages=()
    
    if command -v apt >/dev/null 2>&1; then
        dev_packages=(
            "libssl-dev"
            "libffi-dev"
            "libxml2-dev"
            "libxslt1-dev"
            "libyaml-dev"
            "libreadline-dev"
            "zlib1g-dev"
            "libbz2-dev"
            "libsqlite3-dev"
            "libncurses5-dev"
            "libgdbm-dev"
            "libnss3-dev"
            "debootstrap"
            "schroot"
            "qemu-utils"
        )
        
        print_info "Installing development packages..."
        if ! sudo apt install -y "${dev_packages[@]}"; then
            print_warning "Some development packages may have failed to install"
        fi
        
    elif command -v dnf >/dev/null 2>&1; then
        dev_packages=(
            "openssl-devel"
            "libffi-devel"
            "libxml2-devel"
            "libxslt-devel"
            "libyaml-devel"
            "readline-devel"
            "zlib-devel"
            "bzip2-devel"
            "sqlite-devel"
            "ncurses-devel"
            "gdbm-devel"
            "nss-devel"
            "qemu-img"
        )
        
        print_info "Installing development packages..."
        if ! sudo dnf install -y "${dev_packages[@]}"; then
            print_warning "Some development packages may have failed to install"
        fi
        
    elif command -v pacman >/dev/null 2>&1; then
        dev_packages=(
            "openssl"
            "libffi"
            "libxml2"
            "libxslt"
            "libyaml"
            "readline"
            "zlib"
            "bzip2"
            "sqlite"
            "ncurses"
            "gdbm"
            "nss"
            "qemu"
            "arch-install-scripts"
        )
        
        print_info "Installing development packages..."
        if ! sudo pacman -S --noconfirm "${dev_packages[@]}"; then
            print_warning "Some development packages may have failed to install"
        fi
    else
        print_warning "Unsupported package manager for development packages"
        print_info "Please install development libraries manually if needed"
    fi
    
    print_success "Development packages installation completed"
}

# Setup build directories
setup_build_directories() {
    print_section "Setting up Build Directories"
    
    local xanados_root
    if ! xanados_root=$(get_xanados_root); then
        print_error "Failed to determine xanadOS root directory"
        return 1
    fi
    
    if [[ ! -d "$xanados_root" ]]; then
        print_error "xanadOS root directory does not exist: $xanados_root"
        return 1
    fi
    
    # Create build directories
    local build_dirs=(
        "$xanados_root/build"
        "$xanados_root/build/bootloader"
        "$xanados_root/build/kernel"
        "$xanados_root/build/filesystem"
        "$xanados_root/build/packages"
        "$xanados_root/build/iso"
        "$xanados_root/build/cache"
        "$xanados_root/build/work"
        "$xanados_root/build/makefiles"
    )
    
    for dir in "${build_dirs[@]}"; do
        if mkdir -p "$dir"; then
            print_info "Created: $dir"
            # Add .gitkeep if directory is empty
            if [[ ! "$(ls -A "$dir" 2>/dev/null)" ]]; then
                touch "$dir/.gitkeep"
            fi
        else
            print_error "Failed to create directory: $dir"
            return 1
        fi
    done
    
    # Set appropriate permissions
    if ! chmod 755 "$xanados_root/build"; then
        print_warning "Could not set permissions on build directory"
    fi
    
    if ! chmod -R 755 "$xanados_root/build"/* 2>/dev/null; then
        print_warning "Could not set recursive permissions on build subdirectories"
    fi
    
    print_success "Build directories created"
}

# Configure development environment
configure_development_environment() {
    print_section "Configuring Development Environment"
    
    # Create development configuration
    local config_dir="$HOME/.config/xanados-dev"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/build.conf" << EOF
# xanadOS Development Configuration
# Generated: $(date)

[Build]
XanadOSRoot=$(get_xanados_root)
BuildDir=$(get_xanados_root)/build
CacheDir=$(get_xanados_root)/build/cache
WorkDir=$(get_xanados_root)/build/work

[Parallel]
MakeJobs=$(nproc)
BuildThreads=$(nproc)

[Environment]
CC=gcc
CXX=g++
CFLAGS=-O2 -pipe
CXXFLAGS=-O2 -pipe
MAKEFLAGS=-j$(nproc)

[Paths]
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
LD_LIBRARY_PATH=/usr/local/lib:/usr/lib
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig
EOF
    
    # Create development aliases
    mkdir -p "$HOME/.bashrc.d"
    cat > "$HOME/.bashrc.d/xanados-dev.sh" << EOF
# xanadOS Development Aliases

# Helper function to get xanadOS root
get_xanados_root() {
    local script_dir="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
    echo "\$(cd "\$script_dir/../.." && pwd)"
}

# Build shortcuts
alias xbuild='cd \$(get_xanados_root) && ./scripts/build/create-iso.sh'
alias xclean='cd \$(get_xanados_root) && ./scripts/utilities/cleanup-build.sh'
alias xtest='cd \$(get_xanados_root) && ./scripts/testing/testing-suite.sh'

# Development shortcuts  
alias xroot='cd \$(get_xanados_root)'
alias xbuilddir='cd \$(get_xanados_root)/build'
alias xscripts='cd \$(get_xanados_root)/scripts'

# Git shortcuts
alias xstatus='cd \$(get_xanados_root) && git status'
alias xlog='cd \$(get_xanados_root) && git log --oneline -10'
alias xpull='cd \$(get_xanados_root) && git pull'

# Environment info
alias xenv='echo "XanadOS Root: \$(get_xanados_root)" && echo "Build Dir: \$(get_xanados_root)/build"'
EOF
    
    # Source the aliases file in .bashrc if not already present
    if ! grep -q "xanados-dev.sh" "$HOME/.bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# xanadOS Development Environment"
            echo "if [[ -f \"\$HOME/.bashrc.d/xanados-dev.sh\" ]]; then"
            echo "    source \"\$HOME/.bashrc.d/xanados-dev.sh\""
            echo "fi"
        } >> "$HOME/.bashrc"
    fi
    
    print_success "Development environment configured"
}

# Check development environment status
check_dev_environment_status() {
    print_section "Development Environment Status"
    
    # Check build tools
    local required_tools=("gcc" "make" "cmake" "git" "wget" "curl")
    
    print_info "Build Tools:"
    for tool in "${required_tools[@]}"; do
        if get_cached_command "$tool"; then
            local version
            case "$tool" in
                gcc) version=$(gcc --version | head -1) ;;
                make) version=$(make --version | head -1) ;;
                cmake) version=$(cmake --version | head -1) ;;
                git) version=$(git --version) ;;
                *) version="installed" ;;
            esac
            print_success "  $tool: $version"
        else
            print_error "  $tool: Not installed"
        fi
    done
    
    # Check build directories
    local xanados_root
    xanados_root=$(get_xanados_root)
    
    print_info "Build Directories:"
    local build_dirs=("build" "build/bootloader" "build/kernel" "build/filesystem" "build/iso")
    
    for dir in "${build_dirs[@]}"; do
        if [[ -d "$xanados_root/$dir" ]]; then
            print_success "  $dir: Present"
        else
            print_error "  $dir: Missing"
        fi
    done
    
    # Check configuration
    if [[ -f "$HOME/.config/xanados-dev/build.conf" ]]; then
        print_success "Development configuration: Present"
    else
        print_warning "Development configuration: Missing"
    fi
    
    # Check aliases
    if [[ -f "$HOME/.bashrc.d/xanados-dev.sh" ]]; then
        print_success "Development aliases: Configured"
    else
        print_warning "Development aliases: Not configured"
    fi
}

# Clean build directories
clean_build_directories() {
    local xanados_root
    if ! xanados_root=$(get_xanados_root); then
        print_error "Failed to determine xanadOS root directory"
        return 1
    fi
    
    print_info "Cleaning build directories..."
    
    # Clean specific directories
    local clean_dirs=("$xanados_root/build/work" "$xanados_root/build/cache" "$xanados_root/build/iso")
    
    for dir in "${clean_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_info "  Cleaning: $dir"
            if rm -rf "${dir:?}"/* 2>/dev/null; then
                touch "$dir/.gitkeep"
                print_info "  ✓ Cleaned: $dir"
            else
                print_warning "  Could not clean: $dir (may be empty or permission issue)"
            fi
        else
            print_info "  Directory not found: $dir"
        fi
    done
    
    print_success "Build directories cleaned"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [install|configure|status|clean]"
    echo
    echo "Commands:"
    echo "  install    - Install development environment (default)"
    echo "  configure  - Configure existing installation"
    echo "  status     - Check installation status"
    echo "  clean      - Clean build directories"
}

# Main execution
main() {
    print_header "xanadOS Development Environment Setup"
    
    # Setup logging
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        print_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Process arguments
    local action="${1:-install}"
    setup_dev_environment "$action"
}

# Run main function
main "$@"
