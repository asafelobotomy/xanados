#!/bin/bash
# xanadOS Master Gaming Setup Script
# Complete automated gaming software stack installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if running as regular user
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        print_warning "Please run as a regular user"
        exit 1
    fi
    
    # Check if on Arch Linux
    if [ ! -f /etc/arch-release ]; then
        print_warning "This script is designed for Arch Linux"
        read -r -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check internet connection
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        print_error "No internet connection detected"
        exit 1
    fi
    
    # Check if setup scripts exist
    local required_scripts=(
        "install-steam.sh"
        "install-lutris.sh"
        "install-gamemode.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            print_error "Required script not found: $script"
            exit 1
        fi
    done
    
    print_success "All prerequisites met"
}

# Function to show installation menu
show_menu() {
    print_section "Gaming Software Installation Menu"
    
    echo "Choose installation options:"
    echo
    echo "1) Complete Gaming Setup (Recommended)"
    echo "   - Steam with Proton-GE"
    echo "   - Lutris with Wine optimizations"
    echo "   - GameMode & MangoHud"
    echo "   - All gaming tools and optimizations"
    echo
    echo "2) Steam Only"
    echo "   - Steam with Proton-GE"
    echo "   - Gaming optimizations"
    echo
    echo "3) Lutris & Wine Only"
    echo "   - Lutris gaming platform"
    echo "   - Wine with DXVK/VKD3D"
    echo "   - Windows game compatibility"
    echo
    echo "4) GameMode & Performance Tools Only"
    echo "   - GameMode daemon"
    echo "   - MangoHud overlay"
    echo "   - Performance monitoring tools"
    echo
    echo "5) Custom Installation"
    echo "   - Choose specific components"
    echo
    echo "6) Exit"
    echo
}

# Function for complete gaming setup
complete_setup() {
    print_section "Complete Gaming Setup"
    
    print_status "Installing complete gaming software stack..."
    echo "This will install:"
    echo "  • Steam with Proton-GE"
    echo "  • Lutris with Wine optimizations"
    echo "  • GameMode and MangoHud"
    echo "  • All gaming tools and utilities"
    echo
    
    read -r -p "Continue with complete installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return
    fi
    
    # Run all installation scripts
    print_status "Phase 1: Installing Steam and Proton-GE..."
    "$SCRIPT_DIR/install-steam.sh" install
    
    print_status "Phase 2: Installing Lutris and Wine..."
    "$SCRIPT_DIR/install-lutris.sh" install
    
    print_status "Phase 3: Installing GameMode and MangoHud..."
    "$SCRIPT_DIR/install-gamemode.sh" install
    
    print_success "Complete gaming setup finished!"
}

# Function for Steam-only installation
steam_only() {
    print_section "Steam Installation"
    
    print_status "Installing Steam with Proton-GE..."
    "$SCRIPT_DIR/install-steam.sh" install
    
    print_success "Steam installation completed!"
}

# Function for Lutris-only installation
lutris_only() {
    print_section "Lutris & Wine Installation"
    
    print_status "Installing Lutris and Wine..."
    "$SCRIPT_DIR/install-lutris.sh" install
    
    print_success "Lutris and Wine installation completed!"
}

# Function for GameMode-only installation
gamemode_only() {
    print_section "GameMode & Performance Tools Installation"
    
    print_status "Installing GameMode and MangoHud..."
    "$SCRIPT_DIR/install-gamemode.sh" install
    
    print_success "GameMode and performance tools installation completed!"
}

# Function for custom installation
custom_installation() {
    print_section "Custom Installation"
    
    echo "Select components to install:"
    echo
    
    # Steam selection
    read -r -p "Install Steam with Proton-GE? (Y/n): " -n 1 -r
    echo
    local install_steam=true
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        install_steam=false
    fi
    
    # Lutris selection
    read -r -p "Install Lutris and Wine? (Y/n): " -n 1 -r
    echo
    local install_lutris=true
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        install_lutris=false
    fi
    
    # GameMode selection
    read -r -p "Install GameMode and MangoHud? (Y/n): " -n 1 -r
    echo
    local install_gamemode=true
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        install_gamemode=false
    fi
    
    echo
    print_status "Custom installation starting..."
    
    # Install selected components
    if [ "$install_steam" = true ]; then
        print_status "Installing Steam and Proton-GE..."
        "$SCRIPT_DIR/install-steam.sh" install
    fi
    
    if [ "$install_lutris" = true ]; then
        print_status "Installing Lutris and Wine..."
        "$SCRIPT_DIR/install-lutris.sh" install
    fi
    
    if [ "$install_gamemode" = true ]; then
        print_status "Installing GameMode and MangoHud..."
        "$SCRIPT_DIR/install-gamemode.sh" install
    fi
    
    print_success "Custom installation completed!"
}

# Function to create unified gaming launcher
create_unified_launcher() {
    print_status "Creating unified gaming launcher..."
    
    local bin_dir="$HOME/.local/bin"
    local applications_dir="$HOME/.local/share/applications"
    
    mkdir -p "$bin_dir" "$applications_dir"
    
    # Create unified gaming launcher script
    cat > "$bin_dir/xanados-gaming" << 'EOF'
#!/bin/bash
# xanadOS Unified Gaming Launcher
# Central hub for all gaming platforms

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${BLUE}🎮 xanadOS Gaming Hub 🎮${NC}"
    echo
    echo "Choose your gaming platform:"
    echo
    echo "1) Steam (with GameMode)"
    echo "2) Lutris (with GameMode)" 
    echo "3) Heroic Games Launcher"
    echo "4) Bottles"
    echo "5) Native Games"
    echo "6) Performance Monitor"
    echo "7) Exit"
    echo
}

launch_steam() {
    echo -e "${GREEN}Launching Steam with optimizations...${NC}"
    export MANGOHUD=1
    export RADV_PERFTEST=aco,llvm
    gamemoderun steam
}

launch_lutris() {
    echo -e "${GREEN}Launching Lutris with optimizations...${NC}"
    export MANGOHUD=1
    export DXVK_HUD=fps,memory,gpuload
    gamemoderun lutris
}

launch_heroic() {
    echo -e "${GREEN}Launching Heroic Games Launcher...${NC}"
    export MANGOHUD=1
    gamemoderun heroic
}

launch_bottles() {
    echo -e "${GREEN}Launching Bottles...${NC}"
    export MANGOHUD=1
    gamemoderun bottles
}

launch_native() {
    echo -e "${YELLOW}Enter the command for your native game:${NC}"
    read -r -p "Game command: " game_cmd
    if [ -n "$game_cmd" ]; then
        echo -e "${GREEN}Launching $game_cmd with optimizations...${NC}"
        export MANGOHUD=1
        gamemoderun $game_cmd
    fi
}

show_performance() {
    echo -e "${GREEN}Opening performance monitoring tools...${NC}"
    goverlay &
    corectrl &
}

while true; do
    show_menu
    read -r -p "Select option [1-7]: " choice
    
    case $choice in
        1) launch_steam ;;
        2) launch_lutris ;;
        3) launch_heroic ;;
        4) launch_bottles ;;
        5) launch_native ;;
        6) show_performance ;;
        7) echo "Happy gaming! 🎮"; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    
    echo
    read -r -p "Press Enter to continue..."
done
EOF
    
    chmod +x "$bin_dir/xanados-gaming"
    
    # Create desktop shortcut for gaming hub
    cat > "$applications_dir/xanados-gaming-hub.desktop" << 'EOF'
[Desktop Entry]
Name=xanadOS Gaming Hub
Comment=Central gaming platform launcher
Exec=xanados-gaming
Icon=applications-games
Terminal=true
Type=Application
Categories=Game;
StartupNotify=true
EOF
    
    chmod +x "$applications_dir/xanados-gaming-hub.desktop"
    
    print_success "Unified gaming launcher created"
}

# Function to run post-installation setup
post_installation_setup() {
    print_section "Post-Installation Setup"
    
    # Create gaming directories
    print_status "Creating gaming directories..."
    mkdir -p "$HOME/Games"
    mkdir -p "$HOME/Games/wine-prefixes"
    mkdir -p "$HOME/Games/native"
    mkdir -p "$HOME/.local/share/applications"
    
    # Create unified launcher
    create_unified_launcher
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    print_success "Post-installation setup completed"
}

# Function to show final summary
show_final_summary() {
    print_section "Installation Complete!"
    
    echo -e "${GREEN}🎉 xanadOS Gaming Setup Completed Successfully! 🎉${NC}"
    echo
    print_status "Installed Components:"
    
    # Check installed components
    if command -v steam >/dev/null 2>&1; then
        echo "  ✓ Steam with Proton-GE"
    fi
    
    if command -v lutris >/dev/null 2>&1; then
        echo "  ✓ Lutris with Wine optimizations"
    fi
    
    if command -v gamemoderun >/dev/null 2>&1; then
        echo "  ✓ GameMode performance daemon"
    fi
    
    if command -v mangohud >/dev/null 2>&1; then
        echo "  ✓ MangoHud performance overlay"
    fi
    
    if [ -f "$HOME/.local/bin/xanados-gaming" ]; then
        echo "  ✓ xanadOS Gaming Hub"
    fi
    
    echo
    print_status "Available Launchers:"
    echo "  • xanados-gaming - Unified gaming hub"
    echo "  • steam-gamemode - Optimized Steam launcher"
    echo "  • lutris-gamemode - Optimized Lutris launcher"
    echo "  • gamemode-launch - Universal game launcher"
    echo
    print_status "Quick Start:"
    echo "1. Run 'xanados-gaming' for the unified gaming hub"
    echo "2. Launch Steam and enable Proton-GE in compatibility settings"
    echo "3. Configure Lutris runners and install Windows games"
    echo "4. Use MangoHud (Shift+F12) to monitor performance"
    echo
    print_warning "Important: Log out and back in for all changes to take effect"
    echo
    print_success "Ready for epic gaming sessions! 🚀🎮"
    
    # Save installation log
    print_status "Installation log saved to: $LOG_FILE"
}

# Main function
main() {
    # Initialize log file
    echo "xanadOS Gaming Setup Log - $(date)" > "$LOG_FILE"
    
    print_banner
    check_prerequisites
    
    while true; do
        show_menu
        read -r -p "Select option [1-6]: " choice
        
        case $choice in
            1)
                complete_setup
                break
                ;;
            2)
                steam_only
                break
                ;;
            3)
                lutris_only
                break
                ;;
            4)
                gamemode_only
                break
                ;;
            5)
                custom_installation
                break
                ;;
            6)
                print_status "Installation cancelled by user"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                continue
                ;;
        esac
    done
    
    post_installation_setup
    show_final_summary
}

# Handle interruption
trap 'print_error "Installation interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
