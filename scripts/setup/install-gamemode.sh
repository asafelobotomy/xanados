#!/bin/bash
# xanadOS GameMode & MangoHud Integration Script
# Setup and configure gaming performance tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to install GameMode and MangoHud
install_gamemode_mangohud() {
    print_status "Installing GameMode and MangoHud..."
    
    local packages=(
        # GameMode
        "gamemode"
        "lib32-gamemode"
        
        # MangoHud
        "mangohud"
        "lib32-mangohud"
        
        # Additional gaming tools
        "goverlay"
        "corectrl"
        "gamescope"
        
        # Dependencies
        "meson"
        "ninja"
        "python-mako"
        "vulkan-headers"
        "vulkan-tools"
        "glslang"
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    print_success "GameMode and MangoHud installed"
}

# Function to configure GameMode
configure_gamemode() {
    print_status "Configuring GameMode for optimal performance..."
    
    # Create GameMode config directory
    local gamemode_config_dir="$HOME/.config/gamemode"
    mkdir -p "$gamemode_config_dir"
    
    # Create GameMode configuration
    cat > "$gamemode_config_dir/gamemode.ini" << 'EOF'
[general]
; The reaper thread will check every 5 seconds for exited clients, for config file changes, and for the CPU/iGPU power balance
reaper_freq=5

; The desired governor is used when entering GameMode instead of "performance"
desiredgov=performance
; The default governor is used when leaving GameMode instead of restoring the original value
defaultgov=powersave

; The iGPU desired governor is used when the integrated GPU is under heavy load
igpu_desiredgov=performance
; The iGPU default governor is used when the integrated GPU is not under heavy load
igpu_defaultgov=powersave

; GameMode can change the scheduler policy to SCHED_ISO on kernels which support it (currently
; not supported by upstream kernels). Can be set to "auto", "on" or "off". "auto" will enable
; this feature only on kernels which are detected to support it.
softrealtime=auto

; GameMode can renice game processes. You can put any value between 0 and 20 here, the value
; will be negated and applied as a nice value (0 means no change). Defaults to 0.
renice=10

; GameMode can change the iopriority of the game process. You can put any value between 0 and 7
; here (with 0 being the highest priority), or one of the special values "off" (the default)
; or "reset" (0 priority, neutral scheduling).
ioprio=0

; GameMode can inhibit the screensaver when active. This is useful if you have a screen-dimming
; timeout that would kick in when you are AFK, but you do not want it to do so when a game is
; running. Can be set to "on", "off", or "always" (the default). "always" means it will inhibit
; screensaver on all windows under a gamemoded game.
inhibit_screensaver=on

[filter]
; If "whitelist" entry has a value(s)
; gamemode will reject anything not in the whitelist
;whitelist=RiseOfTheTombRaider

; Gamemode will always reject anything in the blacklist
;blacklist=HalfLife3
;    glxgears

[gpu]
; Here Be Dragons!
; Warning: Use these settings at your own risk
; Any damage to hardware incurred due to this feature is your responsibility and yours alone
; It is also highly recommended you try these settings out first manually to find the sweet spots

; Setting this to the keyphrase "accept-responsibility" will allow gamemode to apply GPU optimisations such as overclocks
;apply_gpu_optimisations=accept-responsibility

; The DRM device number on the system (usually 0), ie. the number in /sys/class/drm/card0/
;gpu_device=0

; Nvidia specific settings
; Requires the coolbits extension activated in nvidia-xconfig
; This corresponds to the desired GPUPowerMizerMode
; "Adaptive"=0 "Prefer Maximum Performance"=1 "Auto"=2 "Prefer Consistent Performance"=3
;nv_powermizer_mode=1

; These will modify the core and mem clocks of the highest perf state in the Nvidia PowerMizer
; They are measured as Mhz offsets from the baseline, 0 will reset values to default, -1 or unset will not modify values
;nv_core_clock_mhz_offset=0
;nv_mem_clock_mhz_offset=0

; AMD specific settings
; Requires a relatively up to date AMDGPU kernel module
; See: https://wiki.archlinux.org/title/AMDGPU#Overclocking for the risks, potential damage to hardware and other caveats
; AMDGPU "manual" performance level, allows for custom power states
; Defaults to "auto", this must be set to "manual" for other AMDGPU options to work
;amd_performance_level=manual

[supervisor]
; This section controls the new gamemode functions gamemode_request_start_for and gamemode_request_end_for
; The settings are only used if the supervisor daemon is enabled

; Sets whether the supervisor should take over normal gamemode behaviour
supervisor=1

; Supervisor socket path, to allow games to switch gamemode without suid
; Requires systemd and dbus to be available
daemon_socket=/run/gamemode/gamemode.sock

[custom]
; Custom scripts (executed using /bin/sh) when gamemode starts and ends
;start=notify-send "GameMode started"
;end=notify-send "GameMode ended"

; Timeout for scripts (seconds). Scripts will be killed if they do not complete within this time.
script_timeout=10
EOF
    
    print_success "GameMode configured"
}

# Function to configure MangoHud
configure_mangohud() {
    print_status "Configuring MangoHud for performance monitoring..."
    
    # Create MangoHud config directory
    local mangohud_config_dir="$HOME/.config/MangoHud"
    mkdir -p "$mangohud_config_dir"
    
    # Create MangoHud configuration
    cat > "$mangohud_config_dir/MangoHud.conf" << 'EOF'
# xanadOS MangoHud Configuration
# Optimized for gaming performance monitoring

################ PERFORMANCE #################

# Enable performance metrics
gpu_stats
gpu_temp
gpu_core_clock
gpu_mem_clock
gpu_power
gpu_load_change
gpu_load_value=50,90
gpu_load_color=FFFFFF,FFAA7F,CC0000

cpu_stats
cpu_temp
cpu_power
core_load_change
core_load

ram
vram

################ VISUAL #################

# Position and layout
position=top_left
table_columns=3
background_alpha=0.4
font_size=24

# Colors
text_color=FFFFFF
gpu_color=2E9762
cpu_color=2E97CB
vram_color=AD64C1
ram_color=C26693
engine_color=EB5B5B
io_color=A491D3
frametime_color=00FF00
background_color=020202
media_player_color=FFFFFF

################ DISPLAY #################

# FPS and frametime
fps
frametime=0
frame_timing=1
histogram

# Engine info
engine_version
vulkan_driver

# System info
arch
kernel
wine
gamemode

################ INTERACTION #################

# Toggle and control
toggle_hud=Shift_R+F12
toggle_logging=Shift_L+F2
reload_cfg=Shift_L+F4
upload_log=Shift_L+F3

# Logging
output_folder=/home/$USER/MangoHud_Logs
log_duration=30
autostart_log=0

################ LIMITS #################

# FPS limiting (0 = disabled)
fps_limit=0,60,144

# Vsync override
vsync=0

################ OTHER #################

# Network monitoring
network

# Battery info (for laptops)
battery

# Time display
time
time_format=%R

# Media player integration
media_player
media_player_format={title}

# Process info
procmem
procmem_shared
procmem_virt

# IO stats
io_read
io_write

# Gamemode integration
gamemode

# Wine prefix
winesync
EOF
    
    # Replace $USER with actual username
    sed -i "s/\$USER/$USER/g" "$mangohud_config_dir/MangoHud.conf"
    
    # Create logs directory
    mkdir -p "$HOME/MangoHud_Logs"
    
    print_success "MangoHud configured"
}

# Function to setup GameMode service
setup_gamemode_service() {
    print_status "Setting up GameMode service..."
    
    # Enable and start GameMode daemon
    sudo systemctl enable gamemoded.service
    sudo systemctl start gamemoded.service
    
    # Add user to gamemode group
    sudo usermod -a -G gamemode "$USER"
    
    print_success "GameMode service configured"
}

# Function to create gaming wrapper scripts
create_gaming_wrappers() {
    print_status "Creating gaming wrapper scripts..."
    
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    # Create GameMode launcher wrapper
    cat > "$bin_dir/gamemode-launch" << 'EOF'
#!/bin/bash
# xanadOS GameMode Game Launcher
# Automatically enables GameMode and MangoHud for games

if [ $# -eq 0 ]; then
    echo "Usage: $0 <game_executable> [arguments...]"
    echo "Example: $0 steam steam://rungameid/12345"
    exit 1
fi

# Enable MangoHud and GameMode
export MANGOHUD=1
export MANGOHUD_DLSYM=1

echo "Starting game with GameMode and MangoHud..."
echo "Game: $1"

# Launch game with GameMode
gamemoderun "$@"
EOF
    
    # Create Steam wrapper
    cat > "$bin_dir/steam-gamemode" << 'EOF'
#!/bin/bash
# xanadOS Steam with GameMode and MangoHud

export MANGOHUD=1
export MANGOHUD_DLSYM=1
export RADV_PERFTEST=aco,llvm
export MESA_LOADER_DRIVER_OVERRIDE=zink
export __GL_THREADED_OPTIMIZATIONS=1

echo "Starting Steam with gaming optimizations..."
gamemoderun steam "$@"
EOF
    
    # Create Lutris wrapper
    cat > "$bin_dir/lutris-gamemode" << 'EOF'
#!/bin/bash
# xanadOS Lutris with GameMode and MangoHud

export MANGOHUD=1
export MANGOHUD_DLSYM=1
export DXVK_HUD=fps,memory,gpuload
export RADV_PERFTEST=aco,llvm

echo "Starting Lutris with gaming optimizations..."
gamemoderun lutris "$@"
EOF
    
    # Make scripts executable
    chmod +x "$bin_dir/gamemode-launch"
    chmod +x "$bin_dir/steam-gamemode"
    chmod +x "$bin_dir/lutris-gamemode"
    
    print_success "Gaming wrapper scripts created"
}

# Function to configure Goverlay
configure_goverlay() {
    print_status "Configuring Goverlay..."
    
    # Create Goverlay config directory
    local goverlay_config_dir="$HOME/.config/goverlay"
    mkdir -p "$goverlay_config_dir"
    
    # Create Goverlay configuration
    cat > "$goverlay_config_dir/goverlay.conf" << 'EOF'
[goverlay]
mangohud_fps_limit=0,60,144
vkbasalt_effects_enabled=false
replay_buffer_enabled=false
replay_time=30
mangohud_enabled=true
vkbasalt_enabled=false
EOF
    
    print_success "Goverlay configured"
}

# Function to install CoreCtrl (GPU control)
setup_corectrl() {
    print_status "Setting up CoreCtrl for GPU management..."
    
    # Create polkit rule for CoreCtrl
    sudo tee /etc/polkit-1/rules.d/90-corectrl.rules > /dev/null << EOF
polkit.addRule(function(action, subject) {
    if ((action.id == "org.corectrl.helper.init" ||
         action.id == "org.corectrl.helperkiller.init") &&
        subject.local == true &&
        subject.active == true &&
        subject.isInGroup("wheel")) {
            return polkit.Result.YES;
    }
});
EOF
    
    print_success "CoreCtrl configured"
}

# Function to create desktop shortcuts
create_desktop_shortcuts() {
    print_status "Creating desktop shortcuts..."
    
    local applications_dir="$HOME/.local/share/applications"
    mkdir -p "$applications_dir"
    
    # MangoHud configurator shortcut
    cat > "$applications_dir/mangohud-config.desktop" << 'EOF'
[Desktop Entry]
Name=MangoHud Configurator
Comment=Configure MangoHud overlay settings
Exec=goverlay
Icon=goverlay
Terminal=false
Type=Application
Categories=Settings;Game;
StartupNotify=true
EOF
    
    # CoreCtrl shortcut
    cat > "$applications_dir/corectrl.desktop" << 'EOF'
[Desktop Entry]
Name=CoreCtrl
Comment=GPU and CPU control utility
Exec=corectrl
Icon=corectrl
Terminal=false
Type=Application
Categories=Settings;System;
StartupNotify=true
EOF
    
    chmod +x "$applications_dir/mangohud-config.desktop"
    chmod +x "$applications_dir/corectrl.desktop"
    
    print_success "Desktop shortcuts created"
}

# Function to test GameMode installation
test_gamemode() {
    print_status "Testing GameMode installation..."
    
    if command -v gamemoderun >/dev/null 2>&1; then
        # Test GameMode
        gamemoderun echo "GameMode test successful!"
        print_success "GameMode is working correctly"
    else
        print_error "GameMode installation failed"
        return 1
    fi
    
    if command -v mangohud >/dev/null 2>&1; then
        print_success "MangoHud is installed correctly"
    else
        print_error "MangoHud installation failed"
        return 1
    fi
}

# Function to show installation summary
show_summary() {
    print_success "=== GameMode & MangoHud Installation Complete! ==="
    echo
    print_status "Installation Summary:"
    echo "  ✓ GameMode performance daemon"
    echo "  ✓ MangoHud performance overlay"
    echo "  ✓ Goverlay configuration tool"
    echo "  ✓ CoreCtrl GPU management"
    echo "  ✓ Gaming wrapper scripts"
    echo "  ✓ Optimized configurations"
    echo
    print_status "Available Commands:"
    echo "  • gamemode-launch <game> - Launch any game with optimizations"
    echo "  • steam-gamemode - Launch Steam with GameMode"
    echo "  • lutris-gamemode - Launch Lutris with GameMode"
    echo "  • goverlay - Configure MangoHud settings"
    echo "  • corectrl - Manage GPU settings"
    echo
    print_status "MangoHud Controls (in-game):"
    echo "  • Shift+F12 - Toggle overlay"
    echo "  • Shift+F2 - Start/stop logging"
    echo "  • Shift+F4 - Reload configuration"
    echo
    print_warning "Note: Log out and back in for group changes to take effect"
    print_success "Ready for high-performance gaming! 🚀"
}

# Main installation function
main() {
    echo "=== xanadOS GameMode & MangoHud Installation ==="
    echo
    
    check_user
    install_gamemode_mangohud
    configure_gamemode
    configure_mangohud
    setup_gamemode_service
    create_gaming_wrappers
    configure_goverlay
    setup_corectrl
    create_desktop_shortcuts
    test_gamemode
    show_summary
}

# Handle script arguments
case "${1:-install}" in
    "install")
        main
        ;;
    "configure")
        configure_gamemode
        configure_mangohud
        configure_goverlay
        ;;
    "test")
        test_gamemode
        ;;
    *)
        echo "Usage: $0 {install|configure|test}"
        echo "  install   - Full GameMode and MangoHud installation"
        echo "  configure - Configure GameMode and MangoHud only"
        echo "  test      - Test GameMode installation"
        exit 1
        ;;
esac
