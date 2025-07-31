#!/bin/bash
# xanadOS Steam & Proton-GE Installation Script
# Automated setup for Steam with gaming optimizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
STEAM_USER_DIR="$HOME/.local/share/Steam"
PROTON_GE_DIR="$STEAM_USER_DIR/compatibilitytools.d"
PROTON_GE_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"

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

# Function to check if running as regular user
check_user() {
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        print_warning "Please run as a regular user"
        exit 1
    fi
}

# Function to install Steam
install_steam() {
    print_status "Installing Steam..."
    
    # Check if Steam is already installed
    if command -v steam >/dev/null 2>&1; then
        print_success "Steam is already installed"
        return 0
    fi
    
    # Install Steam and dependencies
    local packages=(
        "steam"
        "lib32-mesa"
        "lib32-nvidia-utils"
        "lib32-vulkan-radeon"
        "lib32-vulkan-intel"
        "lib32-vulkan-mesa-layers"
        "lib32-openal"
        "lib32-pipewire"
        "lib32-pipewire-jack"
    )
    
    print_status "Installing Steam and 32-bit graphics libraries..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    print_success "Steam and dependencies installed"
}

# Function to enable multilib repository
enable_multilib() {
    print_status "Enabling multilib repository..."
    
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        print_success "Multilib repository already enabled"
        return 0
    fi
    
    # Enable multilib repository
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    
    # Update package database
    sudo pacman -Sy
    
    print_success "Multilib repository enabled"
}

# Function to get latest Proton-GE version
get_latest_proton_ge() {
    print_status "Fetching latest Proton-GE release information..."
    
    local release_info
    release_info=$(curl -s "$PROTON_GE_URL")
    
    if [ $? -ne 0 ]; then
        print_error "Failed to fetch Proton-GE release information"
        return 1
    fi
    
    # Extract download URL and version
    local download_url
    download_url=$(echo "$release_info" | jq -r '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url')
    local version
    version=$(echo "$release_info" | jq -r '.tag_name')
    
    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        print_error "Could not find Proton-GE download URL"
        return 1
    fi
    
    echo "$download_url|$version"
}

# Function to install Proton-GE
install_proton_ge() {
    print_status "Installing Proton-GE..."
    
    # Create compatibility tools directory
    mkdir -p "$PROTON_GE_DIR"
    
    # Get latest Proton-GE information
    local proton_info
    proton_info=$(get_latest_proton_ge)
    
    if [ $? -ne 0 ]; then
        print_warning "Could not install Proton-GE automatically"
        return 1
    fi
    
    local download_url
    download_url=$(echo "$proton_info" | cut -d'|' -f1)
    local version
    version=$(echo "$proton_info" | cut -d'|' -f2)
    
    print_status "Downloading Proton-GE $version..."
    
    # Download Proton-GE
    local temp_file="/tmp/proton-ge-$version.tar.gz"
    curl -L -o "$temp_file" "$download_url"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download Proton-GE"
        return 1
    fi
    
    # Extract Proton-GE
    print_status "Extracting Proton-GE..."
    tar -xzf "$temp_file" -C "$PROTON_GE_DIR"
    
    # Clean up
    rm -f "$temp_file"
    
    print_success "Proton-GE $version installed successfully"
}

# Function to configure Steam for gaming
configure_steam() {
    print_status "Configuring Steam for optimal gaming..."
    
    # Create Steam config directory
    local steam_config_dir="$HOME/.steam/steam"
    mkdir -p "$steam_config_dir"
    
    # Create optimized Steam launch options
    cat > "$steam_config_dir/steam_dev.cfg" << 'EOF'
// xanadOS Steam Gaming Optimizations
@nClientDownloadEnableHTTP2PlatformLinux 0
@fDownloadRateImprovementToAddAnotherConnection 1.0
developer 1
EOF
    
    # Create Steam autoexec config
    cat > "$steam_config_dir/config/config.vdf" << 'EOF'
"InstallConfigStore"
{
    "Software"
    {
        "Valve"
        {
            "Steam"
            {
                "CompatToolMapping"
                {
                }
                "SteamNetworkingMessages_RelayedPingRequests" "1"
                "SteamNetworkingMessages_RelayedPingUploadRateLimit" "100"
            }
        }
    }
}
EOF
    
    print_success "Steam configuration optimized"
}

# Function to install gaming fonts
install_gaming_fonts() {
    print_status "Installing gaming fonts..."
    
    local font_packages=(
        "ttf-liberation"
        "ttf-dejavu"
        "noto-fonts"
        "ttf-droid"
        "ttf-roboto"
        "wqy-zenhei"
    )
    
    sudo pacman -S --needed --noconfirm "${font_packages[@]}"
    
    print_success "Gaming fonts installed"
}

# Function to create Steam desktop shortcut
create_steam_shortcut() {
    print_status "Creating optimized Steam shortcut..."
    
    local desktop_dir="$HOME/Desktop"
    local applications_dir="$HOME/.local/share/applications"
    
    mkdir -p "$applications_dir"
    
    # Create custom Steam launcher with optimizations
    cat > "$applications_dir/steam-xanados.desktop" << 'EOF'
[Desktop Entry]
Name=Steam (xanadOS Optimized)
Comment=Application for managing and playing games on Steam
Exec=env STEAM_FRAME_FORCE_CLOSE=1 RADV_PERFTEST=aco,llvm MESA_LOADER_DRIVER_OVERRIDE=zink steam %U
Icon=steam
Terminal=false
Type=Application
MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
Categories=Network;FileTransfer;Game;
StartupNotify=true
EOF
    
    # Make it executable
    chmod +x "$applications_dir/steam-xanados.desktop"
    
    # Copy to desktop if it exists
    if [ -d "$desktop_dir" ]; then
        cp "$applications_dir/steam-xanados.desktop" "$desktop_dir/"
        chmod +x "$desktop_dir/steam-xanados.desktop"
    fi
    
    print_success "Optimized Steam shortcut created"
}

# Function to setup Steam input
setup_steam_input() {
    print_status "Setting up Steam Input..."
    
    # Add user to input group for controller access
    sudo usermod -a -G input "$USER"
    
    # Create udev rules for Steam controller
    sudo tee /etc/udev/rules.d/99-steam-controller-perms.rules > /dev/null << 'EOF'
# Steam Controller udev rules
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
EOF
    
    # Reload udev rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    print_success "Steam Input configured"
}

# Function to show installation summary
show_summary() {
    print_success "=== Steam & Proton-GE Installation Complete! ==="
    echo
    print_status "Installation Summary:"
    echo "  ✓ Steam with gaming optimizations"
    echo "  ✓ Proton-GE compatibility layer"
    echo "  ✓ 32-bit graphics libraries"
    echo "  ✓ Gaming fonts"
    echo "  ✓ Steam Input configuration"
    echo "  ✓ Optimized launcher"
    echo
    print_status "Next Steps:"
    echo "1. Restart your system to apply all changes"
    echo "2. Launch Steam and sign in to your account"
    echo "3. Go to Steam Settings > Compatibility and enable Proton-GE"
    echo "4. Start gaming! 🎮"
    echo
    print_warning "Note: You may need to log out and back in for group changes to take effect"
}

# Main installation function
main() {
    echo "=== xanadOS Steam & Proton-GE Installation ==="
    echo
    
    check_user
    enable_multilib
    install_steam
    install_proton_ge
    configure_steam
    install_gaming_fonts
    create_steam_shortcut
    setup_steam_input
    show_summary
}

# Handle script arguments
case "${1:-install}" in
    "install")
        main
        ;;
    "proton-ge")
        install_proton_ge
        ;;
    "configure")
        configure_steam
        ;;
    *)
        echo "Usage: $0 {install|proton-ge|configure}"
        echo "  install    - Full Steam installation with optimizations"
        echo "  proton-ge  - Install/update Proton-GE only"
        echo "  configure  - Configure Steam settings only"
        exit 1
        ;;
esac
