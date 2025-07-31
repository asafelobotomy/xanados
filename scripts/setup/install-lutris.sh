#!/bin/bash
# xanadOS Lutris & Wine Installation Script
# Automated setup for Lutris with Wine optimizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LUTRIS_CONFIG_DIR="$HOME/.config/lutris"
WINE_PREFIX_DIR="$HOME/Games/wine-prefixes"
DXVK_CACHE_DIR="$HOME/.cache/dxvk"

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

# Function to install Lutris and Wine
install_lutris_wine() {
    print_status "Installing Lutris and Wine components..."
    
    local packages=(
        # Lutris
        "lutris"
        
        # Wine and related packages
        "wine"
        "wine-staging"
        "winetricks"
        
        # DXVK and VKD3D
        "dxvk-bin"
        "vkd3d"
        "lib32-vkd3d"
        
        # Additional Wine dependencies
        "wine-gecko"
        "wine-mono"
        "lib32-gnutls"
        "lib32-ldap"
        "lib32-libgpg-error"
        "lib32-sqlite"
        "lib32-libpulse"
        
        # Graphics libraries
        "lib32-mesa"
        "lib32-vulkan-radeon"
        "lib32-vulkan-intel"
        "lib32-nvidia-utils"
        
        # Audio libraries
        "lib32-openal"
        "lib32-mpg123"
        "lib32-libao"
        
        # Codec support
        "lib32-gstreamer"
        "lib32-gst-plugins-base"
        "lib32-gst-plugins-good"
        
        # Additional tools
        "cabextract"
        "unzip"
        "curl"
    )
    
    # Install packages
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    print_success "Lutris and Wine installed"
}

# Function to install AUR packages (if AUR helper is available)
install_aur_packages() {
    print_status "Installing additional Wine packages from AUR..."
    
    # Check for AUR helpers
    local aur_helper=""
    for helper in "yay" "paru" "aurman" "pamac"; do
        if command -v "$helper" >/dev/null 2>&1; then
            aur_helper="$helper"
            break
        fi
    done
    
    if [ -z "$aur_helper" ]; then
        print_warning "No AUR helper found. Skipping AUR packages."
        return 0
    fi
    
    local aur_packages=(
        "wine-ge-custom"
        "proton-ge-custom-bin"
        "bottles"
        "heroic-games-launcher-bin"
    )
    
    print_status "Using $aur_helper to install AUR packages..."
    for package in "${aur_packages[@]}"; do
        "$aur_helper" -S --needed --noconfirm "$package" 2>/dev/null || true
    done
    
    print_success "AUR packages installation completed"
}

# Function to configure Lutris
configure_lutris() {
    print_status "Configuring Lutris for optimal gaming..."
    
    # Create Lutris config directory
    mkdir -p "$LUTRIS_CONFIG_DIR"
    
    # Create Lutris configuration
    cat > "$LUTRIS_CONFIG_DIR/lutris.conf" << 'EOF'
[lutris]
migration_version = 13
width = 1024
height = 768
window_x = -1
window_y = -1
maximized = False
library_sync_on_startup = True
show_advanced_options = True
filter_installed = False
sidebar_visible = True
view_type = grid
icon_type_gridview = banner
show_hidden_games = False
show_installed_games = True
show_installed_first = True

[services]
lutris = True
gog = True
steam = True
origin = True
ubisoft = True

[system]
terminal = konsole
env = DXVK_HUD=fps,memory,gpuload,version
game_path = /home/$USER/Games
prefix_path = /home/$USER/Games/wine-prefixes

[runners.wine]
esync = True
fsync = True
fsr = True
battleye = False
eac = False
vkd3d = True
dxvk = True
EOF
    
    # Replace $USER with actual username
    sed -i "s/\$USER/$USER/g" "$LUTRIS_CONFIG_DIR/lutris.conf"
    
    print_success "Lutris configured"
}

# Function to setup Wine prefixes directory
setup_wine_prefixes() {
    print_status "Setting up Wine prefixes directory..."
    
    mkdir -p "$WINE_PREFIX_DIR"
    mkdir -p "$DXVK_CACHE_DIR"
    
    # Create a template Wine prefix with optimizations
    local template_prefix="$WINE_PREFIX_DIR/template"
    
    if [ ! -d "$template_prefix" ]; then
        print_status "Creating optimized Wine template prefix..."
        
        # Create template prefix
        WINEPREFIX="$template_prefix" winecfg /S
        
        # Install common redistributables
        WINEPREFIX="$template_prefix" winetricks -q corefonts vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005 &
        
        print_success "Wine template prefix created"
    fi
    
    print_success "Wine prefixes directory configured"
}

# Function to configure DXVK
configure_dxvk() {
    print_status "Configuring DXVK for optimal performance..."
    
    # Create DXVK config
    cat > "$HOME/.dxvk.conf" << 'EOF'
# xanadOS DXVK Configuration
# Optimized for gaming performance

# Enable GPU-based command submission
dxgi.useGpuSubmission = True

# Enable frame rate limit bypass
dxgi.syncInterval = 0

# Optimize memory allocation
dxvk.enableAsync = True
dxvk.numCompilerThreads = 0
dxvk.numAsyncThreads = 0

# Enable state cache
dxvk.enableStateCache = True

# Optimize for gaming
dxvk.hud = fps,memory,gpuload
dxvk.tearFree = Auto
dxvk.enableGraphicsPipelineLibrary = True

# Memory optimizations
d3d9.memoryTrackTest = True
d3d9.maxAvailableMemory = 4096
d3d9.supportDFFormats = True
d3d9.supportX4R4G4B4 = False
d3d9.supportD32 = True
d3d9.disableA8RT = True
d3d9.invariantPosition = True
d3d9.memoryTrackTest = True

# Performance optimizations
d3d11.relaxedBarriers = True
d3d11.constantBufferRangeCheck = False
d3d11.enableContextLock = False
EOF
    
    print_success "DXVK configured"
}

# Function to create gaming launchers
create_gaming_launchers() {
    print_status "Creating gaming application launchers..."
    
    local applications_dir="$HOME/.local/share/applications"
    mkdir -p "$applications_dir"
    
    # Create optimized Lutris launcher
    cat > "$applications_dir/lutris-xanados.desktop" << 'EOF'
[Desktop Entry]
Name=Lutris (xanadOS Optimized)
Comment=Open Gaming Platform
Exec=env DXVK_HUD=fps,memory,gpuload MANGOHUD=1 RADV_PERFTEST=aco,llvm lutris
Icon=lutris
Terminal=false
Type=Application
Categories=AudioVideo;Game;
MimeType=x-scheme-handler/lutris;
StartupNotify=true
EOF
    
    # Create Wine launcher
    cat > "$applications_dir/wine-xanados.desktop" << 'EOF'
[Desktop Entry]
Name=Wine Configuration (xanadOS)
Comment=Configure Wine
Exec=env DXVK_HUD=fps,memory winecfg
Icon=wine
Terminal=false
Type=Application
Categories=Settings;
StartupNotify=true
EOF
    
    # Make launchers executable
    chmod +x "$applications_dir/lutris-xanados.desktop"
    chmod +x "$applications_dir/wine-xanados.desktop"
    
    print_success "Gaming launchers created"
}

# Function to install gaming tools
install_gaming_tools() {
    print_status "Installing additional gaming tools..."
    
    local gaming_tools=(
        "gamemode"
        "lib32-gamemode"
        "mangohud"
        "lib32-mangohud"
        "goverlay"
        "corectrl"
        "gamescope"
    )
    
    sudo pacman -S --needed --noconfirm "${gaming_tools[@]}"
    
    print_success "Gaming tools installed"
}

# Function to configure Wine registry optimizations
configure_wine_registry() {
    print_status "Applying Wine registry optimizations..."
    
    # Create Wine registry optimization script
    cat > "/tmp/wine-optimizations.reg" << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="opengl"
"Multisampling"="enabled"
"OffscreenRenderingMode"="backbuffer"
"RenderTargetLockMode"="disabled"
"StrictDrawOrdering"="disabled"
"UseGLSL"="enabled"
"VertexShaderMode"="hardware"
"VideoMemorySize"="2048"

[HKEY_CURRENT_USER\Software\Wine\DirectSound]
"DefaultBitsPerSample"="16"
"DefaultSampleRate"="44100"
"DriverPlayMode"="2"
"HelBuflen"="32768"
"SndQueueMax"="28"

[HKEY_CURRENT_USER\Software\Wine\Drivers]
"Audio"="pulse"
"Graphics"="x11"

[HKEY_CURRENT_USER\Software\Wine\WineDbg]
"ShowCrashDialog"="0"
EOF
    
    print_success "Wine registry optimizations prepared"
}

# Function to create Wine environment setup script
create_wine_env_script() {
    print_status "Creating Wine environment setup script..."
    
    cat > "$HOME/.local/bin/setup-wine-env" << 'EOF'
#!/bin/bash
# xanadOS Wine Environment Setup

# Gaming-optimized environment variables
export WINE_CPU_TOPOLOGY=4:2
export WINEFSYNC=1
export WINEESYNC=1
export DXVK_HUD=fps,memory,gpuload
export MANGOHUD=1
export RADV_PERFTEST=aco,llvm
export MESA_LOADER_DRIVER_OVERRIDE=zink
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1

# Wine optimizations
export WINEDEBUG=-all
export WINE_LARGE_ADDRESS_AWARE=1

echo "Wine environment configured for gaming performance"
EOF
    
    chmod +x "$HOME/.local/bin/setup-wine-env"
    
    print_success "Wine environment script created"
}

# Function to show installation summary
show_summary() {
    print_success "=== Lutris & Wine Installation Complete! ==="
    echo
    print_status "Installation Summary:"
    echo "  ✓ Lutris gaming platform"
    echo "  ✓ Wine with staging patches"
    echo "  ✓ DXVK and VKD3D for DirectX"
    echo "  ✓ Gaming tools (GameMode, MangoHud, etc.)"
    echo "  ✓ Optimized configurations"
    echo "  ✓ Wine prefixes directory"
    echo "  ✓ Performance optimizations"
    echo
    print_status "Directories Created:"
    echo "  • Games: $HOME/Games"
    echo "  • Wine Prefixes: $WINE_PREFIX_DIR"
    echo "  • DXVK Cache: $DXVK_CACHE_DIR"
    echo
    print_status "Next Steps:"
    echo "1. Launch Lutris and sign in to your gaming accounts"
    echo "2. Use the optimized launchers for better performance"
    echo "3. Install games and enjoy enhanced gaming! 🎮"
    echo
    print_warning "Note: Some games may require additional setup in Lutris"
}

# Main installation function
main() {
    echo "=== xanadOS Lutris & Wine Installation ==="
    echo
    
    check_user
    install_lutris_wine
    install_aur_packages
    configure_lutris
    setup_wine_prefixes
    configure_dxvk
    install_gaming_tools
    create_gaming_launchers
    configure_wine_registry
    create_wine_env_script
    show_summary
}

# Handle script arguments
case "${1:-install}" in
    "install")
        main
        ;;
    "configure")
        configure_lutris
        configure_dxvk
        ;;
    "wine-setup")
        setup_wine_prefixes
        configure_wine_registry
        ;;
    *)
        echo "Usage: $0 {install|configure|wine-setup}"
        echo "  install    - Full Lutris and Wine installation"
        echo "  configure  - Configure Lutris and DXVK only"
        echo "  wine-setup - Setup Wine prefixes and registry"
        exit 1
        ;;
esac
