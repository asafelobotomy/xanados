#!/bin/bash
# xanadOS GameMode & MangoHud Integration Script
# Setup and configure gaming performance tools

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
        LOG_FILE="$log_dir/gamemode-install.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/gamemode-install.log"
    fi
    
    # Initialize log file
    echo "=== xanadOS GameMode & MangoHud Installation Started: $(date) ===" >> "$LOG_FILE"
}

# Configuration
LOG_FILE=""  # Will be set by setup_logging

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█         🎮 xanadOS GameMode & MangoHud Setup 🎮             █"
    echo "█                                                              █"
    echo "█      Gaming Performance Tools & Monitoring System           █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# Main function for installing GameMode and MangoHud
install_gamemode_components() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            print_status "Installing GameMode and MangoHud..."
            install_gamemode
            install_mangohud
            configure_gamemode
            configure_mangohud
            print_success "GameMode and MangoHud installation completed!"
            ;;
        configure)
            print_status "Configuring GameMode and MangoHud..."
            configure_gamemode
            configure_mangohud
            print_success "Configuration completed!"
            ;;
        status)
            check_installation_status
            ;;
        remove)
            print_status "Removing GameMode and MangoHud..."
            remove_gamemode_components
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

# Install GameMode
install_gamemode() {
    print_section "Installing GameMode"
    
    if get_cached_command "gamemoderun"; then
        print_info "GameMode is already installed"
        return 0
    fi
    
    # Install GameMode package
    if command -v apt >/dev/null 2>&1; then
        print_status "Updating package list..."
        if ! sudo apt update; then
            print_warning "Package update failed, continuing with installation..."
        fi
        print_status "Installing GameMode package..."
        sudo apt install -y gamemode
    elif command -v dnf >/dev/null 2>&1; then
        print_status "Installing GameMode package..."
        sudo dnf install -y gamemode
    elif command -v pacman >/dev/null 2>&1; then
        print_status "Installing GameMode package..."
        sudo pacman -S --noconfirm gamemode
    else
        print_error "Unsupported package manager. Please install GameMode manually."
        return 1
    fi
    
    # Enable and start GameMode daemon
    print_status "Enabling GameMode daemon..."
    sudo systemctl enable --now gamemoded
    
    # Verify daemon started successfully
    sleep 2
    if systemctl is-active --quiet gamemoded; then
        print_success "GameMode daemon started successfully"
    else
        print_warning "GameMode daemon may not have started properly"
    fi
    
    # Add user to gamemode group
    print_status "Adding user to gamemode group..."
    sudo usermod -a -G gamemode "$USER"
    
    print_success "GameMode installed successfully"
    print_info "Note: You may need to log out and back in for group changes to take effect"
}

# Install MangoHud
install_mangohud() {
    print_section "Installing MangoHud"
    
    if get_cached_command "mangohud"; then
        print_info "MangoHud is already installed"
        return 0
    fi
    
    # Install MangoHud package
    if command -v apt >/dev/null 2>&1; then
        print_status "Installing MangoHud package..."
        sudo apt install -y mangohud
    elif command -v dnf >/dev/null 2>&1; then
        print_status "Installing MangoHud package..."
        sudo dnf install -y mangohud
    elif command -v pacman >/dev/null 2>&1; then
        print_status "Installing MangoHud package..."
        sudo pacman -S --noconfirm mangohud
    else
        print_error "Unsupported package manager. Please install MangoHud manually."
        return 1
    fi
    
    print_success "MangoHud installed successfully"
}

# Configure GameMode
configure_gamemode() {
    print_section "Configuring GameMode"
    
    local config_dir="$HOME/.config/gamemode"
    mkdir -p "$config_dir"
    
    # Create GameMode configuration
    cat > "$config_dir/gamemode.ini" << 'EOF'
[general]
renice=10
ioprio=1

[filter]
whitelist=steam,lutris,wine,heroic

[gpu]
apply_gpu_optimisations=accept-responsibility
nv_powermizer_mode=1
amd_performance_level=high

[cpu]
park_cores=no
pin_cores=no
EOF
    
    print_success "GameMode configuration created"
}

# Configure MangoHud
configure_mangohud() {
    print_section "Configuring MangoHud"
    
    local config_dir="$HOME/.config/MangoHud"
    mkdir -p "$config_dir"
    
    # Create MangoHud log directory
    mkdir -p "/tmp/mangohud-logs"
    
    # Create MangoHud configuration
    cat > "$config_dir/MangoHud.conf" << 'EOF'
# MangoHud Configuration for xanadOS Gaming

legacy_layout=false
horizontal

# Performance metrics
gpu_stats
cpu_stats
fps
frametime=0
frame_timing=1

# System info
engine_version
vulkan_driver

# Display settings
fps_limit=0
toggle_fps_limit=F1
hud_no_margin
table_columns=14

# Logging
output_folder=/tmp/mangohud-logs
autostart_log=0
log_duration=30
toggle_logging=F2
EOF
    
    print_success "MangoHud configuration created"
}

# Check installation status
check_installation_status() {
    print_section "Installation Status"
    
    # Check GameMode
    if get_cached_command "gamemoderun"; then
        print_success "GameMode: Installed"
        
        # Check daemon status
        if systemctl is-active --quiet gamemoded; then
            print_success "GameMode daemon: Running"
        else
            print_warning "GameMode daemon: Not running"
        fi
        
        # Check user groups
        if groups "$USER" | grep -q gamemode; then
            print_success "User groups: Configured"
        else
            print_warning "User not in gamemode group"
        fi
    else
        print_error "GameMode: Not installed"
    fi
    
    # Check MangoHud
    if get_cached_command "mangohud"; then
        print_success "MangoHud: Installed"
        
        # Check configuration
        if [[ -f "$HOME/.config/MangoHud/MangoHud.conf" ]]; then
            print_success "MangoHud configuration: Present"
        else
            print_warning "MangoHud configuration: Missing"
        fi
    else
        print_error "MangoHud: Not installed"
    fi
}

# Remove components
remove_gamemode_components() {
    # Stop and disable GameMode daemon
    sudo systemctl stop gamemoded || true
    sudo systemctl disable gamemoded || true
    
    # Remove packages
    if command -v apt >/dev/null 2>&1; then
        sudo apt remove -y gamemode mangohud
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf remove -y gamemode mangohud
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -R --noconfirm gamemode mangohud
    fi
    
    # Remove user from gamemode group
    sudo gpasswd -d "$USER" gamemode || true
    
    # Remove configurations (optional)
    read -p "Remove configuration files? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.config/gamemode"
        rm -rf "$HOME/.config/MangoHud"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [install|configure|status|remove|help]"
    echo
    echo "Commands:"
    echo "  install    - Install GameMode and MangoHud (default)"
    echo "  configure  - Configure existing installation"
    echo "  status     - Check installation status"
    echo "  remove     - Remove GameMode and MangoHud"
    echo "  help       - Show this help message"
    echo
    echo "GameMode provides automatic CPU and GPU optimizations for gaming."
    echo "MangoHud provides a customizable overlay for performance monitoring."
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
    
    # Process arguments
    local action="${1:-install}"
    install_gamemode_components "$action"
}

# Run main function
main "$@"