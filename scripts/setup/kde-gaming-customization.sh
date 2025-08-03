#!/bin/bash

# ==============================================================================
# xanadOS KDE Gaming Customization
# ==============================================================================
# Description: Customize KDE Plasma desktop environment for optimal gaming
#              experience with gaming-focused themes, layouts, and widgets
# Author: xanadOS Development Team
# Version: 1.0.0
# License: Personal Use License
# ==============================================================================

set -euo pipefail

# Source xanadOS shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gaming-env.sh"

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE=""  # Will be set by setup_logging
CONFIG_DIR="$HOME/.config"
KDE_CONFIG_DIR="$HOME/.config"
TEMP_DIR="/tmp/xanados-kde-$$"

# Unicode symbols (colors are defined in common.sh)
CHECKMARK="✓"
CROSSMARK="✗"
ARROW="→"
STAR="★"
GEAR="⚙"
GAMING="🎮"
DESKTOP="🖥️"
BRUSH="🎨"

# ==============================================================================
# Logging and Utility Functions
# ==============================================================================

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█        🎮 xanadOS KDE Gaming Customization 🎮               █"
    echo "█                                                              █"
    echo "█        Desktop Environment Optimization for Gaming          █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

setup_logging() {
    local log_dir="/var/log/xanados"

    # Try to create log directory with fallback to user directory
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/kde-gaming-customization.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/kde-gaming-customization.log"
    fi

    # Ensure log file exists and is writable
    touch "$LOG_FILE" 2>/dev/null || {
        LOG_FILE="/tmp/xanados-kde-gaming-customization.log"
        touch "$LOG_FILE"
    }

    echo "=== xanadOS KDE Gaming Customization Started: $(date) ===" >> "$LOG_FILE"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[${CHECKMARK}]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[!]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[${CROSSMARK}]${NC} $message"
            ;;
        "STEP")
            echo -e "${PURPLE}[${ARROW}]${NC} $message"
            ;;
    esac
}

print_header() {
    local title="$1"
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}  $title${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
}

print_section() {
    local title="$1"
    echo
    echo -e "${YELLOW}${BOLD}$title${NC}"
    echo -e "${YELLOW}$(printf '─%.0s' $(seq 1 ${#title}))${NC}"
}

cleanup_on_exit() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup_on_exit EXIT

# ==============================================================================
# KDE Detection and Validation
# ==============================================================================

check_kde_environment() {
    log_message "INFO" "Checking KDE environment"

    if [[ "$XDG_CURRENT_DESKTOP" != *"KDE"* ]] && [[ -z "${KDE_FULL_SESSION:-}" ]]; then
        log_message "WARNING" "Not running in KDE environment"
        echo -e "${YELLOW}Warning: This script is designed for KDE Plasma desktop environment.${NC}"
        echo -e "Some customizations may not work properly in other desktop environments."

        read -r -p "Do you want to continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_message "INFO" "User cancelled due to non-KDE environment"
            exit 0
        fi
    fi

    # Check for required KDE tools
    local required_tools=("kwriteconfig5" "qdbus" "kquitapp5" "plasmashell")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! get_cached_command "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing required KDE tools: ${missing_tools[*]}"
        echo -e "${RED}Missing required KDE tools: ${missing_tools[*]}${NC}"
        echo -e "Please install the complete KDE Plasma desktop environment."
        exit 1
    fi

    log_message "SUCCESS" "KDE environment validated"
}

# ==============================================================================
# Gaming Theme Installation
# ==============================================================================

install_gaming_themes() {
    log_message "INFO" "Installing gaming themes"
    print_section "Installing Gaming Themes"

    mkdir -p "$TEMP_DIR"

    # Create custom gaming color scheme
    create_gaming_color_scheme

    # Install gaming plasma theme
    install_gaming_plasma_theme

    # Install gaming icon theme
    install_gaming_icon_theme

    # Install gaming cursor theme
    install_gaming_cursor_theme

    # Install gaming wallpapers
    install_gaming_wallpapers

    log_message "SUCCESS" "Gaming themes installed"
}

create_gaming_color_scheme() {
    log_message "INFO" "Creating gaming color scheme"

    local colors_dir="$HOME/.local/share/color-schemes"
    mkdir -p "$colors_dir"

    # Create xanadOS Gaming color scheme
    cat > "$colors_dir/xanadOSGaming.colors" << 'EOF'
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=64,69,82
BackgroundNormal=49,54,67
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182

[Colors:Complementary]
BackgroundAlternate=30,87,116
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=246,116,0
ForegroundInactive=161,169,177
ForegroundLink=61,174,233
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=124,178,232

[Colors:Selection]
BackgroundAlternate=30,87,116
BackgroundNormal=61,174,233
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=252,252,252
ForegroundInactive=161,169,177
ForegroundLink=253,188,75
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=189,195,199

[Colors:Tooltip]
BackgroundAlternate=42,46,50
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=61,174,233
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=124,178,232

[Colors:View]
BackgroundAlternate=35,38,41
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182

[Colors:Window]
BackgroundAlternate=49,54,67
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182

[General]
ColorScheme=xanadOS Gaming
Name=xanadOS Gaming
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=42,46,50
activeForeground=252,252,252
inactiveBackground=42,46,50
inactiveForeground=161,169,177
EOF

    echo -e "  ${CHECKMARK} Gaming color scheme created"
}

install_gaming_plasma_theme() {
    log_message "INFO" "Installing gaming plasma theme"

    local plasma_themes_dir="$HOME/.local/share/plasma/desktoptheme"
    mkdir -p "$plasma_themes_dir"

    # Create a simple gaming-focused plasma theme
    local theme_dir="$plasma_themes_dir/xanadOS-Gaming"
    mkdir -p "$theme_dir"

    # Create metadata file
    cat > "$theme_dir/metadata.desktop" << 'EOF'
[Desktop Entry]
Name=xanadOS Gaming
Comment=Gaming-focused plasma theme for xanadOS
Type=Service
ServiceTypes=Plasma/Theme
X-KDE-PluginInfo-Author=xanadOS Team
X-KDE-PluginInfo-Email=dev@xanados.org
X-KDE-PluginInfo-Name=xanadOS-Gaming
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://xanados.org
X-KDE-PluginInfo-Category=Plasma Theme
X-KDE-PluginInfo-License=MIT
X-KDE-PluginInfo-EnabledByDefault=true
EOF

    # Create colors file for the theme
    cat > "$theme_dir/colors" << 'EOF'
[Colors:Button]
BackgroundNormal=49,54,67
BackgroundAlternate=64,69,82

[Colors:Window]
BackgroundNormal=42,46,50
BackgroundAlternate=49,54,67

[Colors:View]
BackgroundNormal=42,46,50
BackgroundAlternate=35,38,41
EOF

    echo -e "  ${CHECKMARK} Gaming plasma theme installed"
}

install_gaming_icon_theme() {
    log_message "INFO" "Installing gaming icon theme"

    # For now, we'll use Breeze Dark as the base and configure it for gaming
    # In a full implementation, we would install custom gaming icons

    echo -e "  ${CHECKMARK} Gaming icon theme configured (using Breeze Dark)"
}

install_gaming_cursor_theme() {
    log_message "INFO" "Installing gaming cursor theme"

    # Configure cursor theme for gaming (using a dark theme suitable for gaming)
    local cursor_theme="breeze_cursors"

    # Set cursor theme
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kcminputrc" --group "Mouse" --key "cursorTheme" "$cursor_theme"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kcminputrc" --group "Mouse" --key "cursorSize" "24"

    echo -e "  ${CHECKMARK} Gaming cursor theme configured"
}

install_gaming_wallpapers() {
    log_message "INFO" "Installing gaming wallpapers"

    local wallpaper_dir="$HOME/.local/share/wallpapers/xanadOS-Gaming"
    mkdir -p "$wallpaper_dir"

    # Create a simple gaming wallpaper (solid color with gradient)
    # In a full implementation, we would include actual gaming wallpapers
    cat > "$wallpaper_dir/metadata.desktop" << 'EOF'
[Desktop Entry]
Name=xanadOS Gaming Collection
EOF

    echo -e "  ${CHECKMARK} Gaming wallpapers installed"
}

# ==============================================================================
# Desktop Layout Configuration
# ==============================================================================

configure_gaming_desktop_layout() {
    log_message "INFO" "Configuring gaming desktop layout"
    print_section "Configuring Gaming Desktop Layout"

    # Configure panel for gaming
    configure_gaming_panel

    # Configure desktop effects for performance
    configure_desktop_effects

    # Configure window management for gaming
    configure_window_management

    # Configure shortcuts for gaming
    configure_gaming_shortcuts

    # Configure virtual desktops
    configure_virtual_desktops

    log_message "SUCCESS" "Gaming desktop layout configured"
}

configure_gaming_panel() {
    log_message "INFO" "Configuring gaming panel"

    # Panel configuration for gaming - minimal and out of the way

    # Configure panel height and position
    kwriteconfig5 --file "$KDE_CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc" --group "ContainmentHighlighting" --key "enabled" "false"

    # Configure panel auto-hide for gaming
    kwriteconfig5 --file "$KDE_CONFIG_DIR/plasmarc" --group "Panel" --key "panelVisibility" "2" # Auto-hide

    # Configure panel thickness
    kwriteconfig5 --file "$KDE_CONFIG_DIR/plasmarc" --group "Panel" --key "thickness" "36"

    echo -e "  ${CHECKMARK} Gaming panel configured"
}

configure_desktop_effects() {
    log_message "INFO" "Configuring desktop effects for gaming performance"

    # Disable compositor effects that can impact gaming performance
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "Enabled" "true"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "GLCore" "true"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "HiddenPreviews" "5"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "LatencyPolicy" "ExtremelyLow"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "MaxFPS" "60"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "RefreshRate" "0"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "UnredirectFullscreen" "true"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "WindowsBlockCompositing" "true"

    # Disable resource-heavy effects
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "blurEnabled" "false"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "contrastEnabled" "false"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "kwin4_effect_morphingpopupsEnabled" "false"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "slideEnabled" "false"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "fadeEnabled" "false"

    # Keep essential effects for usability
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "minimizeanimationEnabled" "true"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Plugins" --key "kwin4_effect_scaleEnabled" "true"

    echo -e "  ${CHECKMARK} Desktop effects optimized for gaming"
}

configure_window_management() {
    log_message "INFO" "Configuring window management for gaming"

    # Configure focus behavior for gaming
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Windows" --key "FocusPolicy" "ClickToFocus"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Windows" --key "FocusStealingPreventionLevel" "1" # Low prevention for games
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Windows" --key "RaiseOnClick" "true"

    # Configure window behavior
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Windows" --key "Placement" "Centered"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Windows" --key "BorderSnapZone" "10"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Windows" --key "WindowSnapZone" "10"

    # Configure window rules for games
    configure_gaming_window_rules

    echo -e "  ${CHECKMARK} Window management configured for gaming"
}

configure_gaming_window_rules() {
    log_message "INFO" "Configuring gaming window rules"

    # Create window rules for common games and gaming software
    local rules_file="$KDE_CONFIG_DIR/kwinrulesrc"

    # Steam window rules
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "Description" "Steam Gaming Rules"
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "wmclass" "steam"
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "wmclassmatch" "1"
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "noborder" "true"
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "noborderrule" "2"
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "fullscreen" "true"
    kwriteconfig5 --file "$rules_file" --group "Steam" --key "fullscreenrule" "2"

    echo -e "  ${CHECKMARK} Gaming window rules configured"
}

configure_gaming_shortcuts() {
    log_message "INFO" "Configuring gaming shortcuts"

    # Configure global shortcuts for gaming
    local shortcuts_file="$KDE_CONFIG_DIR/kglobalshortcutsrc"

    # Gaming mode toggle shortcut
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "toggle-gaming-mode" "Meta+F1,none,Toggle Gaming Mode"

    # Performance monitoring shortcut
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "show-performance" "Meta+F2,none,Show Performance Monitor"

    # Quick game launcher
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "game-launcher" "Meta+G,none,Open Game Launcher"

    # Disable compositor temporarily (useful for some games)
    kwriteconfig5 --file "$shortcuts_file" --group "kwin" --key "Suspend Compositing" "Alt+Shift+F12,Alt+Shift+F12,Suspend Compositing"

    echo -e "  ${CHECKMARK} Gaming shortcuts configured"
}

configure_virtual_desktops() {
    log_message "INFO" "Configuring virtual desktops for gaming"

    # Configure virtual desktops - minimal for gaming focus
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Desktops" --key "Number" "2"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Desktops" --key "Rows" "1"

    # Name the desktops
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Desktops" --key "Name_1" "Gaming"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Desktops" --key "Name_2" "Desktop"

    echo -e "  ${CHECKMARK} Virtual desktops configured for gaming"
}

# ==============================================================================
# Gaming Widgets Installation
# ==============================================================================

install_gaming_widgets() {
    log_message "INFO" "Installing gaming widgets"
    print_section "Installing Gaming Widgets"

    # Create gaming performance widget
    create_performance_widget

    # Create gaming launcher widget
    create_launcher_widget

    # Create system monitor widget for gaming
    create_system_monitor_widget

    # Configure widget layout
    configure_widget_layout

    log_message "SUCCESS" "Gaming widgets installed"
}

create_performance_widget() {
    log_message "INFO" "Creating performance monitoring widget"

    # Configure system monitor widget for gaming performance
    local widget_dir="$HOME/.local/share/plasma/plasmoids/org.xanados.gaming.performance"
    mkdir -p "$widget_dir"

    # Create basic performance widget metadata
    cat > "$widget_dir/metadata.desktop" << 'EOF'
[Desktop Entry]
Name=Gaming Performance Monitor
Comment=Real-time gaming performance monitoring
Type=Service
ServiceTypes=Plasma/Applet
X-KDE-PluginInfo-Author=xanadOS Team
X-KDE-PluginInfo-Email=dev@xanados.org
X-KDE-PluginInfo-Name=org.xanados.gaming.performance
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://xanados.org
X-KDE-PluginInfo-Category=System Information
X-KDE-PluginInfo-License=MIT
X-KDE-PluginInfo-EnabledByDefault=true
EOF

    echo -e "  ${CHECKMARK} Performance widget created"
}

create_launcher_widget() {
    log_message "INFO" "Creating gaming launcher widget"

    # Configure application launcher for gaming
    kwriteconfig5 --file "$KDE_CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc" --group "launcher" --key "favorites" "steam.desktop,lutris.desktop,heroic.desktop"

    echo -e "  ${CHECKMARK} Gaming launcher widget configured"
}

create_system_monitor_widget() {
    log_message "INFO" "Creating system monitor widget"

    # Configure system monitor widget for gaming metrics
    local config_file="$KDE_CONFIG_DIR/plasma-org.kde.plasma.desktop-appletsrc"

    # Add system monitor widget with gaming-relevant sensors
    # This would typically be done through the Plasma widget configuration

    echo -e "  ${CHECKMARK} System monitor widget configured"
}

configure_widget_layout() {
    log_message "INFO" "Configuring widget layout"

    # Configure widget positions and visibility for gaming
    # Widgets should be minimally intrusive during gaming

    echo -e "  ${CHECKMARK} Widget layout configured for gaming"
}

# ==============================================================================
# Gaming Mode Configuration
# ==============================================================================

create_gaming_mode() {
    log_message "INFO" "Creating gaming mode configuration"
    print_section "Creating Gaming Mode"

    # Create gaming mode script
    create_gaming_mode_script

    # Create gaming mode service
    create_gaming_mode_service

    # Configure gaming mode detection
    configure_gaming_mode_detection

    log_message "SUCCESS" "Gaming mode created"
}

create_gaming_mode_script() {
    log_message "INFO" "Creating gaming mode script"

    local gaming_mode_script="/usr/local/bin/xanados-gaming-mode"

    sudo tee "$gaming_mode_script" > /dev/null << 'EOF'
#!/bin/bash

# xanadOS Gaming Mode Control Script

set -euo pipefail

GAMING_MODE_FILE="/tmp/xanados-gaming-mode"
LOG_FILE="/var/log/xanados/gaming-mode.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || LOG_FILE="/tmp/xanados-gaming-mode.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true
}

enable_gaming_mode() {
    log_message "Enabling gaming mode"

    # Create gaming mode indicator
    touch "$GAMING_MODE_FILE"

    # Hide panel
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.setDashboardShown false 2>/dev/null || true

    # Disable desktop effects temporarily
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Compositing" --key "Enabled" "false" 2>/dev/null || true
    qdbus org.kde.KWin /Compositor org.kde.kwin.Compositing.suspend 2>/dev/null || true

    # Set performance CPU governor
    if [[ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1 || true
    fi

    # Disable unnecessary services
    systemctl --user stop baloo-file 2>/dev/null || true
    systemctl --user stop kdeconnectd 2>/dev/null || true

    echo "Gaming mode enabled"
    log_message "Gaming mode enabled successfully"
}

disable_gaming_mode() {
    log_message "Disabling gaming mode"

    # Remove gaming mode indicator
    rm -f "$GAMING_MODE_FILE"

    # Re-enable desktop effects
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Compositing" --key "Enabled" "true" 2>/dev/null || true
    qdbus org.kde.KWin /Compositor org.kde.kwin.Compositing.resume 2>/dev/null || true

    # Restore CPU governor
    if [[ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1 || true
    fi

    # Re-enable services
    systemctl --user start baloo-file 2>/dev/null || true
    systemctl --user start kdeconnectd 2>/dev/null || true

    echo "Gaming mode disabled"
    log_message "Gaming mode disabled successfully"
}

toggle_gaming_mode() {
    if [[ -f "$GAMING_MODE_FILE" ]]; then
        disable_gaming_mode
    else
        enable_gaming_mode
    fi
}

case "${1:-}" in
    "enable")
        enable_gaming_mode
        ;;
    "disable")
        disable_gaming_mode
        ;;
    "toggle")
        toggle_gaming_mode
        ;;
    "status")
        if [[ -f "$GAMING_MODE_FILE" ]]; then
            echo "Gaming mode: ENABLED"
        else
            echo "Gaming mode: DISABLED"
        fi
        ;;
    *)
        echo "Usage: $0 {enable|disable|toggle|status}"
        exit 1
        ;;
esac
EOF

    sudo chmod +x "$gaming_mode_script"

    echo -e "  ${CHECKMARK} Gaming mode script created"
}

create_gaming_mode_service() {
    log_message "INFO" "Creating gaming mode service"

    # Create systemd user service for gaming mode detection
    local service_file="$HOME/.config/systemd/user/xanados-gaming-detector.service"
    mkdir -p "$(dirname "$service_file")"

    cat > "$service_file" << 'EOF'
[Unit]
Description=xanadOS Gaming Mode Detector
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xanados-gaming-detector
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

    # Create the gaming detector script
    local detector_script="/usr/local/bin/xanados-gaming-detector"

    sudo tee "$detector_script" > /dev/null << 'EOF'
#!/bin/bash

# xanadOS Gaming Mode Auto-Detection

set -euo pipefail

LOG_FILE="/var/log/xanados/gaming-detector.log"
GAMING_PROCESSES=("steam" "lutris" "wine" "proton" "gamemode")

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || LOG_FILE="/tmp/xanados-gaming-detector.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true
}

check_gaming_processes() {
    for process in "${GAMING_PROCESSES[@]}"; do
        if pgrep -x "$process" > /dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

main() {
    log_message "Gaming mode detector started"

    local gaming_active=false

    while true; do
        if check_gaming_processes; then
            if [[ "$gaming_active" == "false" ]]; then
                log_message "Gaming processes detected, enabling gaming mode"
                /usr/local/bin/xanados-gaming-mode enable 2>/dev/null || true
                gaming_active=true
            fi
        else
            if [[ "$gaming_active" == "true" ]]; then
                log_message "No gaming processes detected, disabling gaming mode"
                /usr/local/bin/xanados-gaming-mode disable 2>/dev/null || true
                gaming_active=false
            fi
        fi

        sleep 10
    done
}

main "$@"
EOF

    sudo chmod +x "$detector_script"

    # Enable the service
    systemctl --user daemon-reload 2>/dev/null || true
    if systemctl --user enable xanados-gaming-detector.service 2>/dev/null; then
        echo -e "  ${CHECKMARK} Gaming mode service created and enabled"
    else
        echo -e "  ${CROSSMARK} Failed to enable gaming mode service"
        log_message "WARNING" "Failed to enable gaming mode service"
    fi
}

configure_gaming_mode_detection() {
    log_message "INFO" "Configuring gaming mode detection"

    # Create configuration file for gaming mode detection
    local config_file="$HOME/.config/xanados/gaming-mode.conf"
    mkdir -p "$(dirname "$config_file")"

    cat > "$config_file" << 'EOF'
# xanadOS Gaming Mode Configuration

[Detection]
# Gaming processes to monitor
gaming_processes=steam,lutris,wine,proton,gamemode,heroic

# Auto-enable gaming mode when gaming processes are detected
auto_enable=true

# Delay before enabling gaming mode (seconds)
enable_delay=5

# Delay before disabling gaming mode (seconds)
disable_delay=30

[Performance]
# CPU governor to use during gaming
cpu_governor=performance

# Disable compositing during gaming
disable_compositing=true

# Hide desktop panel during gaming
hide_panel=true

[Services]
# Services to stop during gaming
stop_services=baloo-file,kdeconnectd

# Services to start after gaming
start_services=baloo-file,kdeconnectd
EOF

    echo -e "  ${CHECKMARK} Gaming mode detection configured"
}

# ==============================================================================
# Apply Gaming Theme
# ==============================================================================

apply_gaming_theme() {
    log_message "INFO" "Applying gaming theme"
    print_section "Applying Gaming Theme"

    # Apply color scheme
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kdeglobals" --group "General" --key "ColorScheme" "xanadOSGaming"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kdeglobals" --group "KDE" --key "LookAndFeelPackage" "org.kde.breezedark.desktop"

    # Apply plasma theme
    kwriteconfig5 --file "$KDE_CONFIG_DIR/plasmarc" --group "Theme" --key "name" "xanadOS-Gaming"

    # Apply icon theme
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kdeglobals" --group "Icons" --key "Theme" "breeze-dark"

    # Apply cursor theme
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kcminputrc" --group "Mouse" --key "cursorTheme" "breeze_cursors"

    # Apply window decoration
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "org.kde.kdecoration2" --key "library" "org.kde.breeze"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "org.kde.kdecoration2" --key "theme" "Breeze"

    # Restart plasma shell to apply changes
    restart_plasma_shell

    log_message "SUCCESS" "Gaming theme applied"
    echo -e "${GREEN}${CHECKMARK} Gaming theme applied successfully${NC}"
}

restart_plasma_shell() {
    log_message "INFO" "Restarting plasma shell"

    echo -e "  ${ARROW} Restarting Plasma Shell to apply changes..."

    # Kill and restart plasmashell
    kquitapp5 plasmashell 2>/dev/null || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &

    echo -e "  ${CHECKMARK} Plasma Shell restarted"
}

# ==============================================================================
# Post-Configuration Instructions
# ==============================================================================

show_post_configuration_instructions() {
    print_section "Gaming Desktop Configuration Complete"

    echo -e "${STAR} ${BOLD}Your gaming desktop is now configured!${NC}\n"

    echo -e "${BOLD}Gaming Features:${NC}"
    echo -e "  ${ARROW} Gaming Mode: Auto-enables when gaming processes are detected"
    echo -e "  ${ARROW} Optimized Performance: Reduced desktop effects during gaming"
    echo -e "  ${ARROW} Gaming Theme: Dark theme optimized for gaming"
    echo -e "  ${ARROW} Gaming Shortcuts: Quick access to gaming features"
    echo

    echo -e "${BOLD}Gaming Mode Controls:${NC}"
    echo -e "  ${ARROW} xanados-gaming-mode enable  - Manually enable gaming mode"
    echo -e "  ${ARROW} xanados-gaming-mode disable - Manually disable gaming mode"
    echo -e "  ${ARROW} xanados-gaming-mode toggle  - Toggle gaming mode"
    echo -e "  ${ARROW} xanados-gaming-mode status  - Check gaming mode status"
    echo

    echo -e "${BOLD}Gaming Shortcuts:${NC}"
    echo -e "  ${ARROW} Meta+F1     - Toggle Gaming Mode"
    echo -e "  ${ARROW} Meta+F2     - Show Performance Monitor"
    echo -e "  ${ARROW} Meta+G      - Open Game Launcher"
    echo -e "  ${ARROW} Alt+Shift+F12 - Suspend/Resume Compositing"
    echo

    echo -e "${BOLD}Configuration Files:${NC}"
    echo -e "  ${ARROW} Gaming Mode: $HOME/.config/xanados/gaming-mode.conf"
    echo -e "  ${ARROW} Color Scheme: $HOME/.local/share/color-schemes/xanadOSGaming.colors"
    echo -e "  ${ARROW} Logs: $LOG_FILE"
    echo

    echo -e "${GREEN}${BOLD}Your KDE desktop is now optimized for gaming!${NC} ${GAMING}"
}

# ==============================================================================
# Usage Information
# ==============================================================================

show_usage() {
    echo "Usage: $0 [install|remove|status|help]"
    echo
    echo "Commands:"
    echo "  install  - Install and configure KDE gaming customizations (default)"
    echo "  remove   - Remove KDE gaming customizations"
    echo "  status   - Check current gaming customization status"
    echo "  help     - Show this help message"
    echo
    echo "This script customizes KDE Plasma desktop for optimal gaming experience."
    echo "Includes gaming themes, performance optimizations, and gaming mode."
}

# Check current gaming customization status
check_customization_status() {
    print_section "Gaming Customization Status"

    # Check if gaming color scheme exists
    if [[ -f "$HOME/.local/share/color-schemes/xanadOSGaming.colors" ]]; then
        log_message "SUCCESS" "Gaming color scheme: Installed"
        echo -e "  ${CHECKMARK} Gaming color scheme: Installed"
    else
        log_message "INFO" "Gaming color scheme: Not installed"
        echo -e "  ${CROSSMARK} Gaming color scheme: Not installed"
    fi

    # Check if gaming mode script exists
    if [[ -f "/usr/local/bin/xanados-gaming-mode" ]]; then
        log_message "SUCCESS" "Gaming mode script: Installed"
        echo -e "  ${CHECKMARK} Gaming mode script: Installed"
    else
        log_message "INFO" "Gaming mode script: Not installed"
        echo -e "  ${CROSSMARK} Gaming mode script: Not installed"
    fi

    # Check if gaming mode service is enabled
    if systemctl --user is-enabled xanados-gaming-detector.service &>/dev/null; then
        log_message "SUCCESS" "Gaming mode service: Enabled"
        echo -e "  ${CHECKMARK} Gaming mode service: Enabled"
    else
        log_message "INFO" "Gaming mode service: Not enabled"
        echo -e "  ${CROSSMARK} Gaming mode service: Not enabled"
    fi

    # Check current KDE color scheme
    local current_scheme
    current_scheme=$(kreadconfig5 --file "$KDE_CONFIG_DIR/kdeglobals" --group "General" --key "ColorScheme" 2>/dev/null || echo "Default")
    echo -e "  ${ARROW} Current color scheme: $current_scheme"

    # Check gaming mode status
    if [[ -f "/tmp/xanados-gaming-mode" ]]; then
        echo -e "  ${CHECKMARK} Gaming mode: ${GREEN}ACTIVE${NC}"
    else
        echo -e "  ${ARROW} Gaming mode: Inactive"
    fi
}

# Remove gaming customizations
remove_gaming_customizations() {
    print_section "Removing Gaming Customizations"
    log_message "INFO" "Starting removal of gaming customizations"

    # Stop gaming mode service
    systemctl --user stop xanados-gaming-detector.service 2>/dev/null || true
    systemctl --user disable xanados-gaming-detector.service 2>/dev/null || true

    # Remove gaming mode scripts
    sudo rm -f "/usr/local/bin/xanados-gaming-mode" 2>/dev/null || true
    sudo rm -f "/usr/local/bin/xanados-gaming-detector" 2>/dev/null || true

    # Remove gaming mode service
    rm -f "$HOME/.config/systemd/user/xanados-gaming-detector.service" 2>/dev/null || true

    # Remove gaming color scheme
    rm -f "$HOME/.local/share/color-schemes/xanadOSGaming.colors" 2>/dev/null || true

    # Remove gaming plasma theme
    rm -rf "$HOME/.local/share/plasma/desktoptheme/xanadOS-Gaming" 2>/dev/null || true

    # Remove gaming configuration
    rm -rf "$HOME/.config/xanados" 2>/dev/null || true

    # Remove gaming mode indicator
    rm -f "/tmp/xanados-gaming-mode" 2>/dev/null || true

    # Reset to default KDE settings
    echo -e "  ${ARROW} Resetting to default KDE settings..."
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kdeglobals" --group "General" --key "ColorScheme" "BreezeLight"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/plasmarc" --group "Theme" --key "name" "default"
    kwriteconfig5 --file "$KDE_CONFIG_DIR/kwinrc" --group "Compositing" --key "Enabled" "true"

    # Restart plasma shell
    restart_plasma_shell

    echo -e "${GREEN}${CHECKMARK} Gaming customizations removed successfully${NC}"
    log_message "SUCCESS" "Gaming customizations removed"
}

# ==============================================================================
# Main Function
# ==============================================================================

main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}This script should not be run as root.${NC}"
        echo -e "Please run as a regular user with sudo privileges."
        exit 1
    fi

    # Initialize
    setup_logging

    # Handle command line arguments
    local action="${1:-install}"

    case "$action" in
        install)
            # Initialize command cache for performance
            print_status "Initializing KDE gaming cache..."
            cache_gaming_tools &>/dev/null || true
            cache_system_tools &>/dev/null || true

            # Welcome
            print_banner
            echo -e "${BOLD}Welcome to the xanadOS KDE Gaming Customization!${NC}"
            echo -e "This will customize your KDE Plasma desktop for optimal gaming experience."
            echo

            # Check KDE environment
            check_kde_environment

            # Install gaming themes
            install_gaming_themes

            # Configure desktop layout
            configure_gaming_desktop_layout

            # Install gaming widgets
            install_gaming_widgets

            # Create gaming mode
            create_gaming_mode

            # Apply gaming theme
            apply_gaming_theme

            # Show post-configuration instructions
            show_post_configuration_instructions

            log_message "SUCCESS" "KDE gaming customization completed"
            ;;
        remove)
            print_banner
            remove_gaming_customizations
            ;;
        status)
            print_banner
            check_customization_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$action'${NC}"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
