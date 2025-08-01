#!/bin/bash
# xanadOS Master Gaming Setup Script
# Complete automated gaming software stack installation

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/gaming-env.sh"

set -euo pipefail

# Colors are defined in common.sh - no need to redefine here
# Color variables: RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, WHITE, BOLD, NC

# Configuration
# SCRIPT_DIR already defined above
LOG_FILE="/tmp/xanados-gaming-setup.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█                    🎮 xanadOS Gaming Setup 🎮                █"
    echo "█                                                              █"
    echo "█              Complete Gaming Software Stack                  █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# Log setup with fallback
setup_logging() {
    local log_dir="/var/log/xanados"
    
    # Try to create log directory with fallback to user directory
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/gaming-setup.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/gaming-setup.log"
    fi
    
    # Initialize log file
    echo "=== xanadOS Gaming Setup Started: $(date) ===" >> "$LOG_FILE"
}

# Install Steam with Proton-GE
install_steam() {
    print_status "Installing Steam with Proton-GE..."
    
    if [[ -f "$SCRIPT_DIR/install-steam.sh" ]]; then
        "$SCRIPT_DIR/install-steam.sh" install 2>&1 | tee -a "$LOG_FILE"
    else
        print_warning "Steam installer script not found, skipping..."
    fi
}

# Install Lutris
install_lutris() {
    print_status "Installing Lutris..."
    
    if [[ -f "$SCRIPT_DIR/install-lutris.sh" ]]; then
        "$SCRIPT_DIR/install-lutris.sh" install 2>&1 | tee -a "$LOG_FILE"
    else
        print_warning "Lutris installer script not found, skipping..."
    fi
}

# Install GameMode and MangoHud
install_gamemode() {
    print_status "Installing GameMode and MangoHud..."
    
    if [[ -f "$SCRIPT_DIR/install-gamemode.sh" ]]; then
        "$SCRIPT_DIR/install-gamemode.sh" install 2>&1 | tee -a "$LOG_FILE"
    else
        print_warning "GameMode installer script not found, skipping..."
    fi
}

# Complete gaming setup
complete_gaming_setup() {
    print_banner
    print_status "Starting complete gaming software installation..."
    
    # Install core gaming components
    install_steam
    install_lutris  
    install_gamemode
    
    print_success "Complete gaming setup finished successfully!"
    print_info "Gaming software installation completed. Check $LOG_FILE for details."
}

# Essential gaming setup (core components only)
essential_gaming_setup() {
    print_banner
    print_status "Installing essential gaming components..."
    
    # Install core gaming components only
    install_steam
    install_gamemode
    
    print_success "Essential gaming setup finished successfully!"
    print_info "Essential gaming software installation completed. Check $LOG_FILE for details."
}

# Show usage information
show_usage() {
    echo "Usage: $0 [complete|essential|steam|lutris|gamemode|help]"
    echo
    echo "Options:"
    echo "  complete   - Install all gaming components (Steam, Lutris, GameMode)"
    echo "  essential  - Install core gaming components (Steam, GameMode)"
    echo "  steam      - Install Steam with Proton-GE only"
    echo "  lutris     - Install Lutris only"
    echo "  gamemode   - Install GameMode and MangoHud only"
    echo "  help       - Show this help message"
    echo
}

# Main function
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        print_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Setup logging
    setup_logging
    
    # Handle command line arguments
    local action="${1:-help}"
    
    case "$action" in
        complete)
            complete_gaming_setup
            ;;
        essential)
            essential_gaming_setup
            ;;
        steam)
            print_banner
            install_steam
            ;;
        lutris)
            print_banner
            install_lutris
            ;;
        gamemode)
            print_banner
            install_gamemode
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

# Run main function with all arguments
main "$@"

