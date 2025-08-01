#!/bin/bash
# ============================================================================
# xanadOS Unified Gaming Setup Suite
# Consolidates all gaming setup components into one efficient script
# ============================================================================

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/gaming-env.sh"
source "$SCRIPT_DIR/../lib/setup-common.sh"

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="unified-gaming-setup"
readonly SCRIPT_TITLE="xanadOS Unified Gaming Setup"
readonly SCRIPT_SUBTITLE="Complete Gaming Environment Configuration"
readonly SCRIPT_ICON="🎮"

# Gaming components configuration
readonly COMPONENTS=(
    "steam:Steam & Proton-GE:install_steam:Essential gaming platform with compatibility layer"
    "lutris:Lutris & Wine:install_lutris:Universal game launcher with Windows compatibility"
    "gamemode:GameMode & MangoHud:install_gamemode:Performance optimization and monitoring tools"
    "audio:Audio Optimization:install_audio:Low-latency audio configuration for gaming"
    "graphics:Graphics Drivers:install_graphics:Graphics driver optimization for gaming"
    "hardware:Hardware Devices:install_hardware:Gaming controller and device optimization"
    "kde:KDE Customization:install_kde:Gaming-focused desktop environment customization"
)

readonly ESSENTIAL_COMPONENTS=("steam" "gamemode" "audio")

# ============================================================================
# Steam Installation Functions
# ============================================================================
install_steam() {
    print_info "Installing Steam and Proton-GE..."
    
    # Install Steam package
    install_packages_with_fallback steam
    
    # Setup Proton-GE
    setup_proton_ge
    
    # Create optimized launchers
    create_steam_launchers
    
    print_success "Steam installation completed"
}

setup_proton_ge() {
    local steam_dir="$HOME/.local/share/Steam"
    local proton_dir="$steam_dir/compatibilitytools.d"
    
    # Create directory if it doesn't exist
    mkdir -p "$proton_dir"
    
    # Check if Proton-GE is already installed
    if ls "$proton_dir"/GE-Proton* &>/dev/null; then
        print_info "Proton-GE already installed"
        return 0
    fi
    
    print_info "Installing latest Proton-GE..."
    
    # Get latest release info
    local latest_url
    if command -v curl &>/dev/null; then
        latest_url=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "browser_download_url.*tar.gz" | cut -d'"' -f4 | head -1)
    else
        print_warn "curl not available, skipping Proton-GE installation"
        return 0
    fi
    
    if [[ -n "$latest_url" ]]; then
        local temp_dir
        temp_dir=$(mktemp -d)
        
        if curl -L "$latest_url" | tar -xz -C "$temp_dir"; then
            mv "$temp_dir"/GE-Proton* "$proton_dir/"
            print_success "Proton-GE installed successfully"
        else
            print_warn "Failed to download/extract Proton-GE"
        fi
        
        rm -rf "$temp_dir"
    fi
}

create_steam_launchers() {
    # Create optimized Steam launcher with GameMode
    create_launcher "steam-gamemode" "gamemoderun steam" "" "Steam with GameMode"
    
    # Create Steam Big Picture launcher
    create_launcher "steam-bigpicture" "steam -bigpicture" "gamemoderun" "Steam Big Picture Mode"
}

# ============================================================================
# Lutris Installation Functions
# ============================================================================
install_lutris() {
    print_info "Installing Lutris and Wine..."
    
    # Install packages
    install_packages_with_fallback lutris wine winetricks
    
    # Setup Wine configurations
    setup_wine_optimizations
    
    # Configure Lutris
    configure_lutris
    
    print_success "Lutris installation completed"
}

setup_wine_optimizations() {
    local wine_prefix_dir="$HOME/Games/wine-prefixes"
    mkdir -p "$wine_prefix_dir"
    
    # Create default Wine prefix with optimizations
    print_info "Creating optimized Wine prefix..."
    
    export WINEPREFIX="$wine_prefix_dir/default"
    export WINEARCH=win64
    
    if command -v winecfg &>/dev/null; then
        # Set Wine to Windows 10 mode
        winetricks -q win10 &>/dev/null || true
        
        # Install essential libraries
        winetricks -q vcrun2019 d3dx9 dxvk &>/dev/null || true
    fi
}

configure_lutris() {
    local lutris_config_dir="$HOME/.config/lutris"
    mkdir -p "$lutris_config_dir"
    
    # Create optimized Lutris configuration
    cat > "$lutris_config_dir/system.yml" << 'EOF'
# xanadOS Lutris Optimization Configuration
system:
  disable_compositor: true
  disable_desktop_effects: true
  restore_gamma: true
  single_cpu: false
  env_vars:
    DXVK_HUD: fps
    MESA_GL_VERSION_OVERRIDE: "4.6"
    __GL_SHADER_DISK_CACHE: 1
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP: 1
EOF
}

# ============================================================================
# GameMode Installation Functions
# ============================================================================
install_gamemode() {
    print_info "Installing GameMode and MangoHud..."
    
    # Install packages
    install_packages_with_fallback gamemode mangohud
    
    # Configure GameMode
    configure_gamemode
    
    # Configure MangoHud
    configure_mangohud
    
    print_success "GameMode and MangoHud installation completed"
}

configure_gamemode() {
    local gamemode_config="$HOME/.config/gamemode.ini"
    
    # Create GameMode configuration
    cat > "$gamemode_config" << EOF
# xanadOS GameMode Configuration
[general]
renice=10
ioprio=1
inhibit_screensaver=1
softrealtime=on

[filter]
whitelist=steam
whitelist=lutris
whitelist=wine
whitelist=proton

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high
EOF
    
    # Enable GameMode service
    if ! systemctl --user is-enabled gamemoded &>/dev/null; then
        systemctl --user enable gamemoded
        print_info "GameMode service enabled"
    fi
}

configure_mangohud() {
    local mangohud_config="$HOME/.config/MangoHud/MangoHud.conf"
    mkdir -p "$(dirname "$mangohud_config")"
    
    # Create MangoHud configuration
    cat > "$mangohud_config" << 'EOF'
# xanadOS MangoHud Configuration
fps
cpu_temp
gpu_temp
cpu_load_change
gpu_load_change
ram
vram
fps_limit=0
position=top-right
background_alpha=0.4
font_size=18
EOF
}

# ============================================================================
# Audio Optimization Functions
# ============================================================================
install_audio() {
    print_info "Optimizing audio for low-latency gaming..."
    
    # Use the audio latency optimizer
    if [[ -x "$SCRIPT_DIR/audio-latency-optimizer.sh" ]]; then
        "$SCRIPT_DIR/audio-latency-optimizer.sh" optimize
    else
        print_warn "Audio optimizer not found, performing basic setup..."
        install_packages_with_fallback pipewire-audio pipewire-alsa pipewire-pulse wireplumber
    fi
    
    print_success "Audio optimization completed"
}

# ============================================================================
# Graphics Optimization Functions  
# ============================================================================
install_graphics() {
    print_info "Optimizing graphics drivers..."
    
    # Use the graphics driver optimizer
    if [[ -x "$SCRIPT_DIR/graphics-driver-optimizer.sh" ]]; then
        "$SCRIPT_DIR/graphics-driver-optimizer.sh" install
    else
        print_warn "Graphics optimizer not found, performing basic setup..."
        local gpu_vendor
        gpu_vendor=$(get_cached_hardware_info "gpu_vendor")
        
        case "$gpu_vendor" in
            "nvidia")
                install_packages_with_fallback nvidia-driver nvidia-settings
                ;;
            "amd")
                install_packages_with_fallback mesa-vulkan-drivers vulkan-tools
                ;;
            *)
                print_info "Using default graphics drivers"
                ;;
        esac
    fi
    
    print_success "Graphics optimization completed"
}

# ============================================================================
# Hardware Optimization Functions
# ============================================================================
install_hardware() {
    print_info "Optimizing gaming hardware..."
    
    # Use the hardware device optimizer
    if [[ -x "$SCRIPT_DIR/hardware-device-optimizer.sh" ]]; then
        "$SCRIPT_DIR/hardware-device-optimizer.sh" install
    else
        print_warn "Hardware optimizer not found, performing basic setup..."
        # Install basic controller support
        install_packages_with_fallback joystick jstest-gtk
    fi
    
    print_success "Hardware optimization completed"
}

# ============================================================================
# KDE Customization Functions
# ============================================================================
install_kde() {
    print_info "Applying KDE gaming customizations..."
    
    # Check if running KDE
    if [[ "$XDG_CURRENT_DESKTOP" != *"KDE"* ]]; then
        print_warn "Not running KDE, skipping desktop customization"
        return 0
    fi
    
    # Use the KDE gaming customization script
    if [[ -x "$SCRIPT_DIR/kde-gaming-customization.sh" ]]; then
        "$SCRIPT_DIR/kde-gaming-customization.sh" install
    else
        print_warn "KDE customizer not found, performing basic setup..."
        # Basic gaming shortcuts
        create_launcher "gaming-mode" "systemctl --user start gamemoded" "" "Gaming Mode"
    fi
    
    print_success "KDE customization completed"
}

# ============================================================================
# Installation Management Functions
# ============================================================================
install_component() {
    local component="$1"
    
    for comp in "${COMPONENTS[@]}"; do
        local name="${comp%%:*}"
        if [[ "$name" == "$component" ]]; then
            local func="${comp#*:*:}"; func="${func%%:*}"
            print_info "Installing component: $component"
            if "$func"; then
                print_success "Component '$component' installed successfully"
                return 0
            else
                print_error "Component '$component' installation failed"
                return 1
            fi
        fi
    done
    
    print_error "Unknown component: $component"
    return 1
}

install_multiple_components() {
    local components=("$@")
    local failed=()
    
    for component in "${components[@]}"; do
        if ! install_component "$component"; then
            failed+=("$component")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_warn "Failed components: ${failed[*]}"
        return 1
    fi
    
    return 0
}

install_all_components() {
    print_info "Installing all gaming components..."
    
    local component_names=()
    for comp in "${COMPONENTS[@]}"; do
        component_names+=("${comp%%:*}")
    done
    
    install_multiple_components "${component_names[@]}"
}

install_essential_components() {
    print_info "Installing essential gaming components..."
    install_multiple_components "${ESSENTIAL_COMPONENTS[@]}"
}

# ============================================================================
# Interactive Menu Functions
# ============================================================================
show_interactive_menu() {
    while true; do
        print_standard_banner "$SCRIPT_TITLE" "$SCRIPT_SUBTITLE" "$SCRIPT_ICON"
        
        show_component_menu "Select Gaming Components to Install:" "${COMPONENTS[@]}"
        echo "  a. Install All Components"
        echo "  e. Install Essential Components Only"
        echo "  s. Show Installation Status"
        echo
        
        read -r -p "Enter your choice: " choice
        
        case "$choice" in
            [0])
                print_info "Exiting..."
                exit 0
                ;;
            [1-7])
                local component_array=()
                for comp in "${COMPONENTS[@]}"; do
                    component_array+=("${comp%%:*}")
                done
                local selected="${component_array[$((choice-1))]}"
                install_component "$selected"
                ;;
            [aA])
                install_all_components
                ;;
            [eE])
                install_essential_components
                ;;
            [sS])
                show_installation_status
                ;;
            *)
                print_error "Invalid choice: $choice"
                ;;
        esac
        
        echo
        read -r -p "Press Enter to continue..." -t 3 || true
    done
}

show_installation_status() {
    print_info "Checking gaming setup status..."
    
    check_installation_status \
        "Steam" "command -v steam" \
        "Lutris" "command -v lutris" \
        "GameMode" "systemctl --user is-active gamemoded" \
        "MangoHud" "command -v mangohud" \
        "PipeWire" "systemctl --user is-active pipewire"
}

# ============================================================================
# CLI Functions
# ============================================================================
show_usage() {
    cat << 'EOF'
xanadOS Unified Gaming Setup Suite

USAGE:
    unified-gaming-setup.sh [COMMAND] [COMPONENT...]

COMMANDS:
    install [component]     Install specific component(s)
    all                     Install all gaming components
    essential               Install essential components only
    status                  Show installation status
    menu                    Show interactive menu (default)
    list                    List available components
    help                    Show this help message

COMPONENTS:
    steam       Steam & Proton-GE
    lutris      Lutris & Wine  
    gamemode    GameMode & MangoHud
    audio       Audio optimization
    graphics    Graphics drivers
    hardware    Hardware devices
    kde         KDE customization

EXAMPLES:
    unified-gaming-setup.sh all
    unified-gaming-setup.sh essential
    unified-gaming-setup.sh install steam lutris
    unified-gaming-setup.sh status

EOF
}

list_components() {
    echo "Available Gaming Components:"
    echo "============================"
    
    for comp in "${COMPONENTS[@]}"; do
        local name="${comp%%:*}"
        local title="${comp#*:}"; title="${title%%:*}"
        local desc="${comp##*:}"
        printf "  %-12s %-25s %s\n" "$name" "$title" "$desc"
    done
    echo
    echo "Essential components: ${ESSENTIAL_COMPONENTS[*]}"
}

# ============================================================================
# Main Function
# ============================================================================
main() {
    local command="${1:-menu}"
    
    # Initialize script
    standard_script_init "$SCRIPT_NAME" "$SCRIPT_TITLE" "$SCRIPT_SUBTITLE" "$SCRIPT_ICON"
    
    case "$command" in
        "install")
            shift
            if [[ $# -eq 0 ]]; then
                print_error "No components specified for installation"
                show_usage
                exit 1
            fi
            install_multiple_components "$@"
            ;;
        "all")
            install_all_components
            ;;
        "essential")
            install_essential_components
            ;;
        "status")
            show_installation_status
            ;;
        "list")
            list_components
            ;;
        "menu"|"")
            show_interactive_menu
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            # Try to install as component
            install_component "$command"
            ;;
    esac
}

# Execute main function
main "$@"
