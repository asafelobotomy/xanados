#!/bin/bash
# xanadOS Steam & Proton-GE Installation Script
# Automated setup for Steam with gaming optimizations

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/gaming-env.sh"

set -euo pipefail

# Log setup with fallback
setup_logging() {
    local log_dir="/var/log/xanados"
    
    # Try to create log directory with fallback to user directory
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/steam-install.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/steam-install.log"
    fi
    
    # Initialize log file
    echo "=== xanadOS Steam & Proton-GE Installation Started: $(date) ===" >> "$LOG_FILE"
}

# Configuration
STEAM_USER_DIR="$HOME/.local/share/Steam"
PROTON_GE_DIR="$STEAM_USER_DIR/compatibilitytools.d"
PROTON_GE_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"
LOG_FILE=""  # Will be set by setup_logging

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█           🎮 xanadOS Steam & Proton-GE Setup 🎮             █"
    echo "█                                                              █"
    echo "█        Gaming Platform & Windows Game Compatibility         █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# Main function for Steam installation
install_steam_components() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            print_status "Installing Steam with Proton-GE..."
            enable_multilib
            install_steam
            install_proton_ge
            configure_steam
            print_success "Steam installation completed!"
            ;;
        update)
            print_status "Updating Proton-GE..."
            update_proton_ge
            print_success "Proton-GE updated!"
            ;;
        status)
            check_steam_status
            ;;
        remove)
            print_status "Removing Steam..."
            remove_steam
            print_success "Steam removed!"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown option: $action"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Enable multilib repository (for 32-bit support)
enable_multilib() {
    print_section "Enabling Multilib Support"
    
    if command -v apt >/dev/null 2>&1; then
        # Enable i386 architecture for Steam
        if ! dpkg --print-foreign-architectures | grep -q i386; then
            print_status "Enabling i386 architecture..."
            sudo dpkg --add-architecture i386
            if sudo apt update; then
                print_success "i386 architecture enabled"
            else
                print_warning "Package update failed after enabling i386"
            fi
        else
            print_info "i386 architecture already enabled"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        # Enable multilib repository in Arch
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            print_status "Enabling multilib repository..."
            sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
            if sudo pacman -Sy; then
                print_success "Multilib repository enabled"
            else
                print_warning "Failed to refresh package database after enabling multilib"
            fi
        else
            print_info "Multilib repository already enabled"
        fi
    fi
}

# Install Steam
install_steam() {
    print_section "Installing Steam"
    
    if get_cached_command "steam"; then
        print_info "Steam is already installed"
        return 0
    fi
    
    # Install Steam package
    if command -v apt >/dev/null 2>&1; then
        # Try installing from repository first
        print_status "Checking for Steam in repositories..."
        if sudo apt update && apt list steam 2>/dev/null | grep -q steam; then
            print_status "Installing Steam from repository..."
            sudo apt install -y steam
        else
            # Download and install Steam .deb package
            print_status "Downloading Steam installer..."
            local steam_deb="/tmp/steam.deb"
            if wget -O "$steam_deb" "https://steamcdn-a.akamaihd.net/client/installer/steam.deb"; then
                print_status "Installing Steam from .deb package..."
                sudo dpkg -i "$steam_deb" || sudo apt-get install -f -y
                rm -f "$steam_deb"
            else
                print_error "Failed to download Steam installer"
                return 1
            fi
        fi
    elif command -v dnf >/dev/null 2>&1; then
        print_status "Enabling RPM Fusion repository..."
        # Enable RPM Fusion repositories first
        sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" || true
        print_status "Installing Steam via DNF..."
        sudo dnf install -y steam
    elif command -v pacman >/dev/null 2>&1; then
        print_status "Installing Steam via Pacman..."
        sudo pacman -S --noconfirm steam
    else
        print_error "Unsupported package manager. Please install Steam manually."
        return 1
    fi
    
    print_success "Steam installed successfully"
}

# Install Proton-GE
install_proton_ge() {
    print_section "Installing Proton-GE"
    
    # Create compatibility tools directory
    mkdir -p "$PROTON_GE_DIR"
    
    # Get latest Proton-GE release info
    print_status "Fetching latest Proton-GE release information..."
    local latest_release
    latest_release=$(curl -s "$PROTON_GE_URL" | grep -Po '"tag_name": "\K[^"]*' 2>/dev/null || echo "")
    
    if [[ -z "$latest_release" ]]; then
        print_error "Failed to get Proton-GE release information"
        print_info "Please check your internet connection and try again"
        return 1
    fi
    
    print_info "Latest Proton-GE version: $latest_release"
    local proton_ge_name="GE-Proton${latest_release}"
    local proton_ge_dir="$PROTON_GE_DIR/$proton_ge_name"
    
    # Check if already installed
    if [[ -d "$proton_ge_dir" ]]; then
        print_info "Proton-GE $latest_release is already installed"
        return 0
    fi
    
    # Download and extract Proton-GE
    local download_url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$latest_release/$proton_ge_name.tar.gz"
    local temp_file="/tmp/$proton_ge_name.tar.gz"
    
    print_status "Downloading Proton-GE $latest_release..."
    print_info "This may take several minutes depending on your connection..."
    
    if ! wget --progress=bar:force -O "$temp_file" "$download_url"; then
        print_error "Failed to download Proton-GE"
        rm -f "$temp_file"
        return 1
    fi
    
    print_status "Extracting Proton-GE..."
    if ! tar -xzf "$temp_file" -C "$PROTON_GE_DIR"; then
        print_error "Failed to extract Proton-GE"
        rm -f "$temp_file"
        return 1
    fi
    
    rm -f "$temp_file"
    print_success "Proton-GE $latest_release installed successfully"
}

# Update Proton-GE
update_proton_ge() {
    print_section "Updating Proton-GE"
    
    # Remove old versions (keep only the latest)
    if [[ -d "$PROTON_GE_DIR" ]]; then
        find "$PROTON_GE_DIR" -maxdepth 1 -name "GE-Proton*" -type d -exec rm -rf {} +
    fi
    
    # Install latest version
    install_proton_ge
}

# Configure Steam
configure_steam() {
    print_section "Configuring Steam"
    
    # Create Steam config directory
    local steam_config_dir="$HOME/.steam/steam/config"
    mkdir -p "$steam_config_dir"
    mkdir -p "$HOME/.local/bin"
    
    print_status "Creating optimized Steam launchers..."
    
    # Create launch options for GameMode integration
    cat > "$HOME/.local/bin/steam-gamemode" << 'EOF'
#!/bin/bash
# Steam with GameMode integration

# Check if GameMode is available
if command -v gamemoderun >/dev/null 2>&1; then
    exec gamemoderun steam "$@"
else
    exec steam "$@"
fi
EOF
    chmod +x "$HOME/.local/bin/steam-gamemode"
    
    # Create launch options for MangoHud integration
    cat > "$HOME/.local/bin/steam-mangohud" << 'EOF'
#!/bin/bash
# Steam with MangoHud integration

# Check if MangoHud is available
if command -v mangohud >/dev/null 2>&1; then
    exec mangohud steam "$@"
else
    exec steam "$@"
fi
EOF
    chmod +x "$HOME/.local/bin/steam-mangohud"
    
    # Create unified gaming launcher
    cat > "$HOME/.local/bin/steam-optimized" << 'EOF'
#!/bin/bash
# Steam with full gaming optimizations

# Combine GameMode and MangoHud if available
if command -v gamemoderun >/dev/null 2>&1 && command -v mangohud >/dev/null 2>&1; then
    exec gamemoderun mangohud steam "$@"
elif command -v gamemoderun >/dev/null 2>&1; then
    exec gamemoderun steam "$@"
elif command -v mangohud >/dev/null 2>&1; then
    exec mangohud steam "$@"
else
    exec steam "$@"
fi
EOF
    chmod +x "$HOME/.local/bin/steam-optimized"
    
    print_success "Steam configuration completed"
}

# Check Steam installation status
check_steam_status() {
    print_section "Steam Installation Status"
    
    # Check Steam
    if get_cached_command "steam"; then
        print_success "Steam: Installed"
        
        # Check Steam version
        local steam_version
        steam_version=$(steam --version 2>/dev/null | head -1 || echo "Unknown")
        print_info "Steam version: $steam_version"
    else
        print_error "Steam: Not installed"
    fi
    
    # Check Proton-GE
    if [[ -d "$PROTON_GE_DIR" ]] && [[ -n "$(ls -A "$PROTON_GE_DIR" 2>/dev/null)" ]]; then
        print_success "Proton-GE: Installed"
        
        # List installed versions
        local versions=""
        if compgen -G "$PROTON_GE_DIR/GE-Proton*" > /dev/null; then
            for dir in "$PROTON_GE_DIR"/GE-Proton*; do
                if [[ -d "$dir" ]]; then
                    versions="${versions}$(basename "$dir") "
                fi
            done
            versions=${versions% }  # Remove trailing space
        else
            versions="None"
        fi
        print_info "Installed versions: $versions"
    else
        print_error "Proton-GE: Not installed"
    fi
    
    # Check optimized launchers
    if [[ -x "$HOME/.local/bin/steam-gamemode" ]]; then
        print_success "Gaming integration: Configured"
    else
        print_warning "Gaming integration: Not configured"
    fi
}

# Remove Steam
remove_steam() {
    # Stop Steam if running
    print_status "Stopping Steam processes..."
    pkill steam || true
    sleep 2
    
    # Remove packages
    print_status "Removing Steam packages..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt remove -y steam-installer steam || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y steam
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -R --noconfirm steam
    fi
    
    # Remove Proton-GE
    print_status "Removing Proton-GE..."
    rm -rf "$PROTON_GE_DIR"
    
    # Remove launchers
    print_status "Removing custom launchers..."
    rm -f "$HOME/.local/bin/steam-gamemode"
    rm -f "$HOME/.local/bin/steam-mangohud"
    rm -f "$HOME/.local/bin/steam-optimized"
    
    # Ask about user data
    read -p "Remove Steam user data? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.steam"
        rm -rf "$HOME/.local/share/Steam"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [install|update|status|remove|help]"
    echo
    echo "Commands:"
    echo "  install  - Install Steam with Proton-GE (default)"
    echo "  update   - Update Proton-GE to latest version"
    echo "  status   - Check installation status"
    echo "  remove   - Remove Steam and Proton-GE"
    echo "  help     - Show this help message"
    echo
    echo "Steam is the primary gaming platform for Linux with Proton compatibility."
    echo "Proton-GE provides enhanced Windows game compatibility and performance."
}

# Main execution
main() {
    print_banner
    
    # Setup logging
    setup_logging
    
    # Initialize command cache for performance optimization
    cache_system_tools &>/dev/null || true
    
    # Setup logging redirection
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        print_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check for required tools
    if ! command -v wget >/dev/null 2>&1; then
        print_error "wget is required but not installed. Please install wget first."
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Process arguments
    local action="${1:-install}"
    install_steam_components "$action"
}

# Run main function
main "$@"