#!/bin/bash
# xanadOS ISO Building Script
# This script creates a bootable xanadOS ISO based on Arch Linux

set -e  # Exit on any error

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../lib/common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/common.sh"
else
    # Basic print functions if common.sh is not available
    print_info() { echo "[INFO] $*"; }
    print_success() { echo "[SUCCESS] $*"; }
    print_error() { echo "[ERROR] $*" >&2; }
    print_warning() { echo "[WARNING] $*"; }
    print_status() { echo "[STATUS] $*"; }
fi

# Configuration
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
WORK_DIR="$BUILD_DIR/work"
ISO_DIR="$BUILD_DIR/iso"
CACHE_DIR="$BUILD_DIR/cache"
ARCHISO_DIR="$WORK_DIR/archiso"

# xanadOS Configuration
XANADOS_VERSION="1.0.0"
ISO_NAME="xanadOS"
ISO_LABEL="XANADOS"
ISO_FILENAME="${ISO_NAME}-gaming-${XANADOS_VERSION}-x86_64.iso"

# Function to print colored output
print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

print_section() {
    echo -e "${BLUE}🔧 $1${NC}"
}

# Usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  build        Build the xanadOS ISO"
    echo "  clean        Clean build directories"
    echo "  setup        Setup build environment"
    echo "  help         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 build     # Build the complete ISO"
}

# Check system requirements
check_requirements() {
    print_section "Checking Build Requirements"
    
    # Check if running on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script must be run on Arch Linux"
        exit 1
    fi
    
    # Check for required packages
    local required_packages=(
        "archiso"
        "git"
        "base-devel"
    )
    
    for pkg in "${required_packages[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            print_info "✓ Found: $pkg"
        else
            print_error "Missing required package: $pkg"
            print_info "Install with: sudo pacman -S $pkg"
            exit 1
        fi
    done
    
    # Check for sudo access
    if ! sudo -n true 2>/dev/null; then
        print_error "This script requires sudo access"
        exit 1
    fi
    
    print_success "All requirements satisfied"
}

# Setup build environment
setup_build_environment() {
    print_section "Setting Up Build Environment"
    
    # Create build directories
    local dirs=(
        "$BUILD_DIR"
        "$WORK_DIR"
        "$ISO_DIR"
        "$CACHE_DIR"
        "$ARCHISO_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir"; then
            print_info "Created: $dir"
        else
            print_error "Failed to create: $dir"
            exit 1
        fi
    done
    
    # Copy archiso template
    if [[ ! -d "$ARCHISO_DIR" ]] || [[ -z "$(ls -A "$ARCHISO_DIR" 2>/dev/null)" ]]; then
        print_info "Copying archiso template..."
        cp -r /usr/share/archiso/configs/releng/* "$ARCHISO_DIR/"
        print_success "Archiso template copied"
    else
        print_info "Archiso template already exists"
    fi
}

# Generate package list
generate_package_list() {
    print_section "Generating Package List"
    
    local package_file="$ARCHISO_DIR/packages.x86_64"
    local optimized_packages="$PROJECT_ROOT/build/packages.x86_64"
    
    # Use our optimized packages.x86_64 if it exists
    if [[ -f "$optimized_packages" ]]; then
        print_info "Using optimized xanadOS package list"
        cp "$optimized_packages" "$package_file"
        
        local package_count
        package_count=$(grep -v '^#' "$package_file" | grep -v '^$' | wc -l)
        print_success "Using optimized package list with $package_count packages"
        return
    fi
    
    # Fallback: Generate from individual lists (legacy method)
    print_warning "Optimized package list not found, generating from individual lists"
    local temp_packages="/tmp/xanados-packages.tmp"
    
    # Combine all package lists
    {
        echo "# xanadOS Gaming Distribution Package List"
        echo "# Generated on $(date)"
        echo ""
        
        # Add packages from our lists
        if [[ -f "$PROJECT_ROOT/packages/core/base-system.list" ]]; then
            echo "# Base system packages"
            grep -v '^#' "$PROJECT_ROOT/packages/core/base-system.list" | grep -v '^$'
            echo ""
        fi
        
        if [[ -f "$PROJECT_ROOT/packages/core/graphics.list" ]]; then
            echo "# Graphics packages"  
            grep -v '^#' "$PROJECT_ROOT/packages/core/graphics.list" | grep -v '^$'
            echo ""
        fi
        
        if [[ -f "$PROJECT_ROOT/packages/core/audio.list" ]]; then
            echo "# Audio packages"
            grep -v '^#' "$PROJECT_ROOT/packages/core/audio.list" | grep -v '^$'
            echo ""
        fi
        
        if [[ -f "$PROJECT_ROOT/packages/core/gaming.list" ]]; then
            echo "# Gaming packages"
            grep -v '^#' "$PROJECT_ROOT/packages/core/gaming.list" | grep -v '^$'
            echo ""
        fi
        
        if [[ -f "$PROJECT_ROOT/packages/desktop/kde-plasma.list" ]]; then
            echo "# Desktop environment packages"
            grep -v '^#' "$PROJECT_ROOT/packages/desktop/kde-plasma.list" | grep -v '^$'
            echo ""
        fi
        
        # Add essential ISO packages
        echo "# ISO building essentials"
        echo "calamares"
        echo "gparted" 
        echo "firefox"
        echo "file-roller"
        
    } > "$temp_packages"
    
    # Remove duplicates and sort
    sort "$temp_packages" | uniq | grep -v '^#' | grep -v '^$' > "$package_file"
    
    local package_count
    package_count=$(wc -l < "$package_file")
    print_success "Generated package list with $package_count packages"
    
    rm -f "$temp_packages"
}

# Customize ISO
customize_iso() {
    print_section "Customizing ISO"
    
    # Update ISO info
    local iso_info="$ARCHISO_DIR/profiledef.sh"
    if [[ -f "$iso_info" ]]; then
        sed -i "s/iso_name=.*/iso_name=\"$ISO_NAME\"/" "$iso_info"
        sed -i "s/iso_label=.*/iso_label=\"$ISO_LABEL\"/" "$iso_info"
        sed -i "s/iso_version=.*/iso_version=\"$XANADOS_VERSION\"/" "$iso_info"
        print_info "Updated ISO information"
    fi
    
    # Copy xanadOS files to ISO
    local airootfs="$ARCHISO_DIR/airootfs"
    mkdir -p "$airootfs/opt/xanados"
    
    # Copy essential xanadOS components
    if [[ -d "$PROJECT_ROOT/scripts" ]]; then
        cp -r "$PROJECT_ROOT/scripts" "$airootfs/opt/xanados/"
        print_info "Copied xanadOS scripts"
    fi
    
    if [[ -d "$PROJECT_ROOT/configs" ]]; then
        cp -r "$PROJECT_ROOT/configs" "$airootfs/opt/xanados/"
        print_info "Copied xanadOS configurations"
    fi
    
    # Create xanadOS installer desktop entry
    mkdir -p "$airootfs/etc/skel/Desktop"
    cat > "$airootfs/etc/skel/Desktop/xanadOS-Installer.desktop" << 'EOF'
[Desktop Entry]
Name=Install xanadOS Gaming
Comment=Install xanadOS Gaming Distribution
Exec=calamares
Icon=system-software-install
Type=Application
Categories=System;
Keywords=install;installer;xanados;gaming;
EOF
    
    # Set up auto-login for live user
    mkdir -p "$airootfs/etc/systemd/system/getty@tty1.service.d"
    cat > "$airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin live %I $TERM
EOF
    
    print_success "ISO customization completed"
}

# Build the ISO
build_iso() {
    print_section "Building xanadOS Gaming ISO"
    
    cd "$ARCHISO_DIR"
    
    # Run archiso build
    print_info "Starting ISO build process..."
    print_warning "This may take 30-60 minutes depending on your system..."
    
    if sudo mkarchiso -v -w "$WORK_DIR" -o "$ISO_DIR" "$ARCHISO_DIR"; then
        print_success "ISO build completed successfully!"
        
        # Show results
        local iso_path
        iso_path=$(find "$ISO_DIR" -name "*.iso" -type f | head -1)
        if [[ -n "$iso_path" ]]; then
            print_info "ISO Location: $iso_path"
            print_info "ISO Size: $(du -h "$iso_path" | cut -f1)"
            
            # Calculate checksums
            print_info "Generating checksums..."
            cd "$ISO_DIR"
            sha256sum "$(basename "$iso_path")" > "$(basename "$iso_path").sha256"
            md5sum "$(basename "$iso_path")" > "$(basename "$iso_path").md5"
            
            print_success "Checksums generated"
        fi
    else
        print_error "ISO build failed!"
        exit 1
    fi
}

# Clean build directories
clean_build() {
    print_section "Cleaning Build Environment"
    
    local clean_dirs=(
        "$WORK_DIR"
        "$CACHE_DIR"
    )
    
    for dir in "${clean_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_info "Cleaning: $dir"
            sudo rm -rf "$dir"
        fi
    done
    
    print_success "Build directories cleaned"
}

# Main build process
main_build() {
    print_header "🎮 xanadOS Gaming Distribution ISO Builder"
    
    check_requirements
    setup_build_environment
    generate_package_list
    customize_iso
    build_iso
    
    print_header "✅ xanadOS Gaming ISO Build Complete"
    echo -e "${GREEN}Your gaming distribution is ready!${NC}"
    echo -e "${WHITE}Check the ISO at: $ISO_DIR${NC}"
}

# Main script logic
case "${1:-build}" in
    "build")
        main_build
        ;;
    "setup")
        check_requirements
        setup_build_environment
        print_success "Build environment setup complete"
        ;;
    "clean")
        clean_build
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
