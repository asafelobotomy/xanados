#!/bin/bash
# xanadOS Lutris & Wine Installation Script
# Automated setup for Lutris with Wine optimizations

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
        LOG_FILE="$log_dir/lutris-install.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/lutris-install.log"
    fi
    
    # Initialize log file
    echo "=== xanadOS Lutris & Wine Installation Started: $(date) ===" >> "$LOG_FILE"
}

# Configuration
LUTRIS_CONFIG_DIR="$HOME/.config/lutris"
WINE_PREFIX_DIR="$HOME/Games/wine-prefixes"
DXVK_CACHE_DIR="$HOME/.cache/dxvk"
LOG_FILE=""  # Will be set by setup_logging

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█           🎮 xanadOS Lutris & Wine Setup 🎮                 █"
    echo "█                                                              █"
    echo "█       Gaming Platform & Windows Compatibility Layer         █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# Main function for Lutris installation
install_lutris_components() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            print_status "Installing Lutris with Wine optimizations..."
            install_wine
            install_lutris
            install_wine_dependencies
            configure_lutris
            setup_dxvk_vkd3d
            print_success "Lutris installation completed!"
            ;;
        configure)
            print_status "Configuring Lutris and Wine..."
            configure_lutris
            setup_dxvk_vkd3d
            print_success "Configuration completed!"
            ;;
        status)
            check_lutris_status
            ;;
        remove)
            print_status "Removing Lutris and Wine..."
            remove_lutris
            print_success "Removal completed!"
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

# Install Wine
install_wine() {
    print_section "Installing Wine"
    
    if get_cached_command "wine"; then
        print_info "Wine is already installed"
        return 0
    fi
    
    # Install Wine package
    if command -v apt >/dev/null 2>&1; then
        print_status "Adding Wine repository..."
        
        # Create directory for apt keys
        sudo mkdir -p /etc/apt/keyrings
        
        # Add Wine repository key (using new method)
        if ! wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive-keyring.gpg; then
            print_warning "Failed to add Wine repository, trying package manager version..."
            sudo apt update
            sudo apt install -y wine
            print_success "Wine installed from system packages"
            return 0
        fi
        
        # Add repository
        local release
        release=$(lsb_release -cs)
        echo "deb [signed-by=/etc/apt/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ $release main" | sudo tee /etc/apt/sources.list.d/winehq.list
        
        print_status "Installing Wine from WineHQ repository..."
        sudo apt update
        if ! sudo apt install -y --install-recommends winehq-staging; then
            print_warning "WineHQ staging failed, trying stable version..."
            sudo apt install -y --install-recommends winehq-stable || sudo apt install -y wine
        fi
        
    elif command -v dnf >/dev/null 2>&1; then
        print_status "Installing Wine via DNF..."
        sudo dnf install -y wine
    elif command -v pacman >/dev/null 2>&1; then
        print_status "Installing Wine via Pacman..."
        sudo pacman -S --noconfirm wine wine-gecko wine-mono
    else
        print_error "Unsupported package manager. Please install Wine manually."
        return 1
    fi
    
    print_success "Wine installed successfully"
}

# Install Lutris
install_lutris() {
    print_section "Installing Lutris"
    
    if get_cached_command "lutris"; then
        print_info "Lutris is already installed"
        return 0
    fi
    
    # Install Lutris package
    if command -v apt >/dev/null 2>&1; then
        print_status "Adding Lutris PPA..."
        # Add Lutris PPA for latest version
        if ! sudo add-apt-repository ppa:lutris-team/lutris -y; then
            print_warning "Failed to add Lutris PPA, trying system packages..."
        fi
        
        print_status "Installing Lutris..."
        sudo apt update
        sudo apt install -y lutris
    elif command -v dnf >/dev/null 2>&1; then
        print_status "Installing Lutris via DNF..."
        sudo dnf install -y lutris
    elif command -v pacman >/dev/null 2>&1; then
        print_status "Installing Lutris via Pacman..."
        sudo pacman -S --noconfirm lutris
    else
        print_error "Unsupported package manager. Please install Lutris manually."
        return 1
    fi
    
    print_success "Lutris installed successfully"
}

# Install Wine dependencies
install_wine_dependencies() {
    print_section "Installing Wine Dependencies"
    
    # Install Winetricks
    if ! get_cached_command "winetricks"; then
        print_status "Installing Winetricks..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt install -y winetricks
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y winetricks
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm winetricks
        fi
        
        print_success "Winetricks installed"
    else
        print_info "Winetricks already installed"
    fi
    
    # Install additional libraries
    print_status "Installing Wine support libraries..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y lib32z1 libc6-i386 lib32ncurses6 lib32stdc++6 \
                            libfreetype6:i386 libfontconfig1:i386 libxinerama1:i386 \
                            libxrandr2:i386 libxcomposite1:i386 libxcursor1:i386
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y glibc-devel.i686 libgcc.i686
    fi
    
    print_success "Wine dependencies installed"
}

# Configure Lutris
configure_lutris() {
    print_section "Configuring Lutris"
    
    # Create Lutris config directory
    mkdir -p "$LUTRIS_CONFIG_DIR"
    mkdir -p "$WINE_PREFIX_DIR"
    mkdir -p "$DXVK_CACHE_DIR"
    mkdir -p "$HOME/.local/bin"
    
    # Create Lutris configuration
    cat > "$LUTRIS_CONFIG_DIR/lutris.conf" << 'EOF'
[lutris]
dark_theme = True
show_advanced_options = True
migration_version = 1

[system]
disable_runtime = False
prefer_system_libs = True
reset_desktop = True
restore_gamma = True

[runners]
wine_path = /usr/bin/wine

[wine]
Desktop = False
WineDesktop = 1024x768
MouseWarpOverride = enable
Audio = pulse
EOF
    
    # Create gaming launchers with optimizations
    cat > "$HOME/.local/bin/lutris-gamemode" << 'EOF'
#!/bin/bash
# Lutris with GameMode integration

if command -v gamemoderun >/dev/null 2>&1; then
    exec gamemoderun lutris "$@"
else
    exec lutris "$@"
fi
EOF
    chmod +x "$HOME/.local/bin/lutris-gamemode"
    
    cat > "$HOME/.local/bin/lutris-mangohud" << 'EOF'
#!/bin/bash
# Lutris with MangoHud integration

if command -v mangohud >/dev/null 2>&1; then
    exec mangohud lutris "$@"
else
    exec lutris "$@"
fi
EOF
    chmod +x "$HOME/.local/bin/lutris-mangohud"
    
    cat > "$HOME/.local/bin/lutris-optimized" << 'EOF'
#!/bin/bash
# Lutris with full gaming optimizations

if command -v gamemoderun >/dev/null 2>&1 && command -v mangohud >/dev/null 2>&1; then
    exec gamemoderun mangohud lutris "$@"
elif command -v gamemoderun >/dev/null 2>&1; then
    exec gamemoderun lutris "$@"
elif command -v mangohud >/dev/null 2>&1; then
    exec mangohud lutris "$@"
else
    exec lutris "$@"
fi
EOF
    chmod +x "$HOME/.local/bin/lutris-optimized"
    
    print_success "Lutris configuration completed"
}

# Setup DXVK and VKD3D
setup_dxvk_vkd3d() {
    print_section "Setting up DXVK and VKD3D"
    
    # Check for Vulkan support
    if ! get_cached_command "vulkaninfo"; then
        print_status "Installing Vulkan support..."
        
        if command -v apt >/dev/null 2>&1; then
            sudo apt install -y vulkan-tools mesa-vulkan-drivers
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y vulkan-tools mesa-vulkan-drivers
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm vulkan-tools vulkan-mesa-layers
        fi
        
        print_success "Vulkan support installed"
    else
        print_info "Vulkan support already available"
    fi
    
    # Install DXVK and VKD3D through package manager if available
    print_status "Installing DXVK and VKD3D..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y dxvk vkd3d || print_info "DXVK/VKD3D packages not available in repository"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm dxvk-bin || print_info "DXVK packages not available in repository"
    fi
    
    # Create DXVK cache directory
    mkdir -p "$DXVK_CACHE_DIR"
    
    # Set environment variables for DXVK
    mkdir -p "$HOME/.profile.d"
    cat > "$HOME/.profile.d/dxvk.sh" << 'EOF'
# DXVK environment variables
export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk"
export DXVK_LOG_LEVEL=warn
export DXVK_HUD=compiler
EOF
    
    print_success "DXVK and VKD3D setup completed"
}

# Check Lutris installation status
check_lutris_status() {
    print_section "Lutris Installation Status"
    
    # Check Lutris
    if get_cached_command "lutris"; then
        print_success "Lutris: Installed"
        
        # Check Lutris version
        local lutris_version
        lutris_version=$(lutris --version 2>/dev/null || echo "Unknown")
        print_info "Lutris version: $lutris_version"
    else
        print_error "Lutris: Not installed"
    fi
    
    # Check Wine
    if get_cached_command "wine"; then
        print_success "Wine: Installed"
        
        # Check Wine version
        local wine_version
        wine_version=$(wine --version 2>/dev/null || echo "Unknown")
        print_info "Wine version: $wine_version"
    else
        print_error "Wine: Not installed"
    fi
    
    # Check Winetricks
    if get_cached_command "winetricks"; then
        print_success "Winetricks: Installed"
    else
        print_warning "Winetricks: Not installed"
    fi
    
    # Check Vulkan
    if get_cached_command "vulkaninfo"; then
        print_success "Vulkan: Available"
    else
        print_warning "Vulkan: Not available"
    fi
    
    # Check directories
    if [[ -d "$WINE_PREFIX_DIR" ]]; then
        print_success "Wine prefixes directory: Created"
    else
        print_warning "Wine prefixes directory: Not created"
    fi
    
    # Check optimized launchers
    if [[ -x "$HOME/.local/bin/lutris-gamemode" ]]; then
        print_success "Gaming integration: Configured"
    else
        print_warning "Gaming integration: Not configured"
    fi
}

# Remove Lutris
remove_lutris() {
    # Stop Lutris if running
    pkill lutris || true
    
    # Remove packages
    if command -v apt >/dev/null 2>&1; then
        sudo apt remove -y lutris winehq-staging winehq-stable wine winetricks || true
        sudo add-apt-repository --remove ppa:lutris-team/lutris -y || true
        # Remove Wine repository
        sudo rm -f /etc/apt/sources.list.d/winehq.list
        sudo rm -f /etc/apt/keyrings/winehq-archive-keyring.gpg
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y lutris wine winetricks
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -R --noconfirm lutris wine winetricks
    fi
    
    # Remove launchers
    rm -f "$HOME/.local/bin/lutris-gamemode"
    rm -f "$HOME/.local/bin/lutris-mangohud"
    rm -f "$HOME/.local/bin/lutris-optimized"
    
    # Ask about user data
    read -p "Remove Wine prefixes and game data? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$WINE_PREFIX_DIR"
        rm -rf "$LUTRIS_CONFIG_DIR"
        rm -rf "$DXVK_CACHE_DIR"
        rm -rf "$HOME/.wine"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [install|configure|status|remove|help]"
    echo
    echo "Commands:"
    echo "  install    - Install Lutris with Wine optimizations (default)"
    echo "  configure  - Configure existing installation"
    echo "  status     - Check installation status"
    echo "  remove     - Remove Lutris and Wine"
    echo "  help       - Show this help message"
    echo
    echo "Lutris is a gaming platform that supports Windows games via Wine."
    echo "This installer includes DXVK/VKD3D for optimal gaming performance."
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
    
    # Process arguments
    local action="${1:-install}"
    install_lutris_components "$action"
}

# Run main function
main "$@"
