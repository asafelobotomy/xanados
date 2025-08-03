#!/bin/bash
# xanadOS Unified Gaming Platforms Installer
# Consolidates Steam, Lutris, GameMode, and other gaming platform installations

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh" || {
    echo "Error: Could not source common library"
    exit 1
}

# Gaming platforms installation functions
install_steam() {
    print_status "Installing Steam..."
    if command_exists steam; then
        print_warning "Steam already installed"
        return 0
    fi
    
    # Enable multilib repository
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    
    # Install Steam with 32-bit libraries
    sudo pacman -S --noconfirm steam lib32-nvidia-utils lib32-mesa-libgl lib32-alsa-plugins
    print_success "Steam installed successfully"
}

install_lutris() {
    print_status "Installing Lutris..."
    if command_exists lutris; then
        print_warning "Lutris already installed"
        return 0
    fi
    
    sudo pacman -S --noconfirm lutris wine-staging winetricks
    print_success "Lutris installed successfully"
}

install_gamemode() {
    print_status "Installing GameMode..."
    if command_exists gamemoded; then
        print_warning "GameMode already installed"
        return 0
    fi
    
    sudo pacman -S --noconfirm gamemode lib32-gamemode
    sudo usermod -a -G gamemode "$USER"
    print_success "GameMode installed successfully"
}

install_heroic() {
    print_status "Installing Heroic Games Launcher..."
    if command_exists heroic; then
        print_warning "Heroic already installed"
        return 0
    fi
    
    # Install via AUR helper if available, otherwise manual install
    if command_exists yay; then
        yay -S --noconfirm heroic-games-launcher-bin
    elif command_exists paru; then
        paru -S --noconfirm heroic-games-launcher-bin
    else
        print_warning "No AUR helper found, skipping Heroic Games Launcher"
        return 1
    fi
    
    print_success "Heroic Games Launcher installed successfully"
}

# Main installation function
main() {
    local action="${1:-all}"
    
    case "$action" in
        steam)
            install_steam
            ;;
        lutris)
            install_lutris
            ;;
        gamemode)
            install_gamemode
            ;;
        heroic)
            install_heroic
            ;;
        all)
            install_steam
            install_lutris
            install_gamemode
            install_heroic
            ;;
        *)
            echo "Usage: $0 [steam|lutris|gamemode|heroic|all]"
            exit 1
            ;;
    esac
    
    print_success "Gaming platforms installation completed"
}

main "$@"
