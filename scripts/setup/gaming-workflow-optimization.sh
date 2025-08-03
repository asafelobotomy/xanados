#!/bin/bash

# xanadOS Gaming Workflow Optimization
# Part of Phase 4.2.2: Gaming Workflow Optimization
#
# This script implements gaming mode desktop environment, shortcuts,
# notification management, and window management optimization

set -euo pipefail

# Script information
readonly SCRIPT_NAME="Gaming Workflow Optimization"
readonly SCRIPT_VERSION="1.0.0"
readonly PHASE="4.2.2"

# Configuration paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(realpath "$SCRIPT_DIR/../lib")"
CONFIG_DIR="$(realpath "$SCRIPT_DIR/../../configs")"

# KDE configuration paths
KDE_CONFIG="$HOME/.config"
KDE_DATA="$HOME/.local/share"
KDE_CACHE="$HOME/.cache"

# Gaming workflow configuration
GAMING_MODE_CONFIG="$CONFIG_DIR/system/gaming-mode.conf"
GAMING_SHORTCUTS_CONFIG="$CONFIG_DIR/desktop/gaming-shortcuts.conf"
GAMING_NOTIFICATIONS_CONFIG="$CONFIG_DIR/desktop/gaming-notifications.conf"
GAMING_WINDOW_RULES="$CONFIG_DIR/desktop/gaming-window-rules.conf"

# Source required libraries (use fallback functions if libraries not available)
if [[ -f "$LIB_DIR/common.sh" ]]; then
    # shellcheck source=../lib/common.sh
    source "$LIB_DIR/common.sh"
else
    # Fallback functions
    print_header() { echo -e "\n\e[1;96m================================================\e[0m"; echo -e "\e[1;96m$1\e[0m"; echo -e "\e[1;96m================================================\e[0m"; }
    print_success() { echo -e "\e[1;92m✅ $1\e[0m"; }
    print_info() { echo -e "\e[1;94mℹ️ $1\e[0m"; }
    print_warning() { echo -e "\e[1;93m⚠️ $1\e[0m"; }
    print_error() { echo -e "\e[1;91m❌ $1\e[0m"; }
    print_section() { echo -e "\n\e[1;95m$1\e[0m"; }
    ensure_directory() { mkdir -p "$1"; }
fi

# ==============================================================================
# Utility Functions
# ==============================================================================

# Ensure directory exists
ensure_directory() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
    fi
}

# ==============================================================================
# Gaming Mode Functions
# ==============================================================================

# Initialize gaming mode system
init_gaming_mode() {
    print_header "🎮 Initializing Gaming Mode System"

    # Create gaming mode configuration directory
    local gaming_mode_dir="$HOME/.config/xanados/gaming-mode"
    ensure_directory "$gaming_mode_dir"

    # Create gaming mode state file
    local gaming_mode_state="$gaming_mode_dir/state"
    echo "inactive" > "$gaming_mode_state"

    # Create gaming mode script
    create_gaming_mode_script

    # Create gaming mode service
    create_gaming_mode_service

    print_success "Gaming mode system initialized"
}

# Create gaming mode toggle script
create_gaming_mode_script() {
    local gaming_mode_script="$HOME/.local/bin/xanados-gaming-mode"
    ensure_directory "$(dirname "$gaming_mode_script")"

    cat > "$gaming_mode_script" << 'EOF'
#!/bin/bash

# xanadOS Gaming Mode Toggle Script
# Toggles between gaming and normal desktop modes

set -euo pipefail

GAMING_MODE_STATE="$HOME/.config/xanados/gaming-mode/state"
GAMING_MODE_CONFIG="$HOME/.config/xanados/gaming-mode/config"

# Get current gaming mode state
get_gaming_mode_state() {
    if [[ -f "$GAMING_MODE_STATE" ]]; then
        cat "$GAMING_MODE_STATE"
    else
        echo "inactive"
    fi
}

# Set gaming mode state
set_gaming_mode_state() {
    local state="$1"
    echo "$state" > "$GAMING_MODE_STATE"
    notify-send "xanadOS Gaming Mode" "Gaming mode: $state" --icon=applications-games
}

# Activate gaming mode
activate_gaming_mode() {
    echo "🎮 Activating Gaming Mode..."

    # Disable desktop effects and compositor
    qdbus org.kde.KWin /Compositor suspend 2>/dev/null || true

    # Set performance CPU governor
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true

    # Disable notifications (except critical)
    kwriteconfig5 --file "$HOME/.config/plasmanotifyrc" --group "Notifications" --key "PopupPosition" "Hidden"

    # Set gaming window management rules
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "FocusStealingPreventionLevel" "0"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "AutoRaise" "true"

    # Minimize non-gaming applications
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.toggleDashboard 2>/dev/null || true

    # Update state
    set_gaming_mode_state "active"

    echo "✅ Gaming mode activated"
}

# Deactivate gaming mode
deactivate_gaming_mode() {
    echo "🖥️ Deactivating Gaming Mode..."

    # Re-enable desktop effects and compositor
    qdbus org.kde.KWin /Compositor resume 2>/dev/null || true

    # Restore CPU governor to default
    echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true

    # Re-enable notifications
    kwriteconfig5 --file "$HOME/.config/plasmanotifyrc" --group "Notifications" --key "PopupPosition" "TopRight"

    # Restore window management rules
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "FocusStealingPreventionLevel" "1"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "AutoRaise" "false"

    # Update state
    set_gaming_mode_state "inactive"

    echo "✅ Gaming mode deactivated"
}

# Toggle gaming mode
toggle_gaming_mode() {
    local current_state
    current_state=$(get_gaming_mode_state)

    if [[ "$current_state" == "active" ]]; then
        deactivate_gaming_mode
    else
        activate_gaming_mode
    fi
}

# Show gaming mode status
show_status() {
    local current_state
    current_state=$(get_gaming_mode_state)

    echo "🎮 xanadOS Gaming Mode Status: $current_state"

    if [[ "$current_state" == "active" ]]; then
        echo "  • Desktop effects: Disabled"
        echo "  • CPU performance: Maximum"
        echo "  • Notifications: Minimal"
        echo "  • Window focus: Gaming optimized"
    else
        echo "  • Desktop effects: Enabled"
        echo "  • CPU performance: Balanced"
        echo "  • Notifications: Normal"
        echo "  • Window focus: Default"
    fi
}

# Main function
main() {
    local action="${1:-toggle}"

    case "$action" in
        "on"|"activate"|"enable")
            activate_gaming_mode
            ;;
        "off"|"deactivate"|"disable")
            deactivate_gaming_mode
            ;;
        "toggle")
            toggle_gaming_mode
            ;;
        "status"|"state")
            show_status
            ;;
        *)
            echo "Usage: $0 {on|off|toggle|status}"
            echo "  on/activate/enable  - Activate gaming mode"
            echo "  off/deactivate/disable - Deactivate gaming mode"
            echo "  toggle             - Toggle gaming mode"
            echo "  status/state       - Show current status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$gaming_mode_script"
    print_info "✓ Gaming mode script created: $gaming_mode_script"
}

# Create gaming mode systemd service
create_gaming_mode_service() {
    local service_file="$HOME/.config/systemd/user/xanados-gaming-mode.service"
    ensure_directory "$(dirname "$service_file")"

    cat > "$service_file" << 'EOF'
[Unit]
Description=xanadOS Gaming Mode Monitor
After=graphical-session.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do sleep 30; done'
Environment="DISPLAY=:0"
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

    print_info "✓ Gaming mode service created: $service_file"
}

# ==============================================================================
# Gaming Shortcuts Functions
# ==============================================================================

# Setup gaming shortcuts
setup_gaming_shortcuts() {
    print_header "⌨️ Setting Up Gaming Shortcuts"

    # Create shortcuts configuration
    create_shortcuts_config

    # Install gaming shortcuts
    install_gaming_shortcuts

    # Setup controller shortcuts
    setup_controller_shortcuts

    print_success "Gaming shortcuts configured"
}

# Create shortcuts configuration file
create_shortcuts_config() {
    ensure_directory "$(dirname "$GAMING_SHORTCUTS_CONFIG")"

    cat > "$GAMING_SHORTCUTS_CONFIG" << 'EOF'
# xanadOS Gaming Shortcuts Configuration
# Defines keyboard and controller shortcuts for gaming workflows

[Gaming Mode Controls]
ToggleGamingMode=Meta+F1
ActivateGamingMode=Meta+Shift+F1
DeactivateGamingMode=Meta+Ctrl+F1
GamingModeStatus=Meta+Alt+F1

[Gaming Applications]
LaunchSteam=Meta+S
LaunchLutris=Meta+L
OpenGameMode=Meta+G
ShowMangoHud=Meta+H
GamingProfileManager=Meta+P

[Performance Controls]
ShowPerformanceMonitor=Meta+F2
ToggleCompositor=Alt+Shift+F12
ActivatePerformanceGovernor=Meta+Shift+P
ShowSystemMonitor=Ctrl+Shift+Esc

[Audio Controls]
VolumeUp=Meta+Plus
VolumeDown=Meta+Minus
VolumeMute=Meta+M
MicrophoneMute=Meta+Shift+M

[Window Management]
MaximizeWindow=Meta+Up
MinimizeWindow=Meta+Down
CloseWindow=Alt+F4
SwitchToNextWindow=Alt+Tab
SwitchToPreviousWindow=Alt+Shift+Tab
ShowDesktop=Meta+D

[Gaming Utilities]
TakeScreenshot=Print
TakeWindowScreenshot=Alt+Print
RecordScreen=Meta+R
ShowTaskManager=Ctrl+Alt+Del
EmergencyKill=Ctrl+Alt+K

[Controller Shortcuts]
ControllerToggleGaming=Guide+Start
ControllerVolumeUp=Guide+Y
ControllerVolumeDown=Guide+X
ControllerScreenshot=Guide+Back
EOF

    print_info "✓ Gaming shortcuts configuration created"
}

# Install gaming shortcuts to KDE
install_gaming_shortcuts() {
    if ! command -v kwriteconfig5 >/dev/null 2>&1; then
        print_warning "KDE tools not available. Shortcuts configuration saved for manual installation."
        return 0
    fi

    local shortcuts_file="$KDE_CONFIG/kglobalshortcutsrc"

    # Gaming Mode Controls
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "toggle-gaming-mode" "Meta+F1,none,Toggle Gaming Mode"
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "activate-gaming-mode" "Meta+Shift+F1,none,Activate Gaming Mode"
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "deactivate-gaming-mode" "Meta+Ctrl+F1,none,Deactivate Gaming Mode"

    # Gaming Applications
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "launch-steam" "Meta+S,none,Launch Steam"
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "launch-lutris" "Meta+L,none,Launch Lutris"
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "gaming-profile-manager" "Meta+P,none,Gaming Profile Manager"

    # Performance Controls
    kwriteconfig5 --file "$shortcuts_file" --group "xanados-gaming" --key "show-performance" "Meta+F2,none,Show Performance Monitor"
    kwriteconfig5 --file "$shortcuts_file" --group "kwin" --key "Suspend Compositing" "Alt+Shift+F12,Alt+Shift+F12,Toggle Compositor"

    # Audio Controls
    kwriteconfig5 --file "$shortcuts_file" --group "kmix" --key "increase_volume" "Meta+Plus,Volume Up,Increase Volume"
    kwriteconfig5 --file "$shortcuts_file" --group "kmix" --key "decrease_volume" "Meta+Minus,Volume Down,Decrease Volume"
    kwriteconfig5 --file "$shortcuts_file" --group "kmix" --key "mute" "Meta+M,Volume Mute,Mute"

    print_info "✓ Gaming shortcuts installed to KDE"
}

# Setup controller shortcuts
setup_controller_shortcuts() {
    local controller_config="$HOME/.config/xanados/gaming-mode/controller-shortcuts.conf"
    ensure_directory "$(dirname "$controller_config")"

    cat > "$controller_config" << 'EOF'
# Controller Shortcuts Configuration
# Maps controller buttons to gaming functions

[Xbox Controller]
Guide+Start=toggle-gaming-mode
Guide+Back=take-screenshot
Guide+Y=volume-up
Guide+X=volume-down
Guide+A=confirm-action
Guide+B=cancel-action

[PlayStation Controller]
PS+Options=toggle-gaming-mode
PS+Share=take-screenshot
PS+Triangle=volume-up
PS+Square=volume-down
PS+Cross=confirm-action
PS+Circle=cancel-action

[Generic Controller]
Home+Menu=toggle-gaming-mode
Home+Select=take-screenshot
Home+ButtonY=volume-up
Home+ButtonX=volume-down
Home+ButtonA=confirm-action
Home+ButtonB=cancel-action
EOF

    print_info "✓ Controller shortcuts configured"
}

# ==============================================================================
# Notification Management Functions
# ==============================================================================

# Setup gaming notification management
setup_gaming_notifications() {
    print_header "🔔 Setting Up Gaming Notification Management"

    # Create notification configuration
    create_notification_config

    # Setup notification rules
    setup_notification_rules

    # Create notification management script
    create_notification_script

    print_success "Gaming notification management configured"
}

# Create notification configuration
create_notification_config() {
    ensure_directory "$(dirname "$GAMING_NOTIFICATIONS_CONFIG")"

    cat > "$GAMING_NOTIFICATIONS_CONFIG" << 'EOF'
# xanadOS Gaming Notifications Configuration
# Controls notification behavior during gaming sessions

[Gaming Mode Notifications]
# Disable most notifications during gaming
DisableNonCritical=true
DisableChat=false
DisableSocial=true
DisableUpdates=true
DisableNews=true

[Critical Notifications]
# Always allow critical notifications
AllowSystemErrors=true
AllowBatteryWarnings=true
AllowSecurityAlerts=true
AllowNetworkDisconnection=true

[Gaming-Specific Notifications]
# Gaming-related notifications
AllowGameLaunch=true
AllowGameAchievements=true
AllowFriendRequests=true
AllowVoiceChat=true
AllowScreenshots=true

[Notification Position]
# Position for gaming notifications
GamingPosition=BottomRight
NormalPosition=TopRight
MinimalOverlay=true

[Notification Duration]
# How long notifications stay visible
GamingDuration=3000
NormalDuration=5000
CriticalDuration=10000

[Do Not Disturb]
# Automatic do not disturb during gaming
AutoDNDFullscreen=true
AutoDNDGaming=true
DNDWhitelist=steam,lutris,discord,teamspeak
EOF

    print_info "✓ Gaming notifications configuration created"
}

# Setup notification rules
setup_notification_rules() {
    if ! command -v kwriteconfig5 >/dev/null 2>&1; then
        print_warning "KDE tools not available. Notification rules saved for manual installation."
        return 0
    fi

    local notify_config="$KDE_CONFIG/plasmanotifyrc"

    # Gaming notification settings
    kwriteconfig5 --file "$notify_config" --group "Gaming" --key "PopupPosition" "BottomRight"
    kwriteconfig5 --file "$notify_config" --group "Gaming" --key "PopupTimeout" "3000"
    kwriteconfig5 --file "$notify_config" --group "Gaming" --key "CriticalInGaming" "true"

    # Do not disturb settings
    kwriteconfig5 --file "$notify_config" --group "DoNotDisturb" --key "FullscreenMode" "true"
    kwriteconfig5 --file "$notify_config" --group "DoNotDisturb" --key "GamingMode" "true"
    kwriteconfig5 --file "$notify_config" --group "DoNotDisturb" --key "Whitelist" "steam,lutris,discord,teamspeak"

    print_info "✓ Notification rules configured"
}

# Create notification management script
create_notification_script() {
    local notify_script="$HOME/.local/bin/xanados-gaming-notifications"
    ensure_directory "$(dirname "$notify_script")"

    cat > "$notify_script" << 'EOF'
#!/bin/bash

# xanadOS Gaming Notifications Manager
# Manages notification behavior during gaming sessions

set -euo pipefail

GAMING_MODE_STATE="$HOME/.config/xanados/gaming-mode/state"
NOTIFICATION_CONFIG="$HOME/.config/plasmanotifyrc"

# Get current gaming mode state
is_gaming_mode_active() {
    if [[ -f "$GAMING_MODE_STATE" ]]; then
        local state
        state=$(cat "$GAMING_MODE_STATE")
        [[ "$state" == "active" ]]
    else
        return 1
    fi
}

# Enable gaming notifications
enable_gaming_notifications() {
    echo "🔔 Enabling gaming notification mode..."

    # Move notifications to bottom-right
    kwriteconfig5 --file "$NOTIFICATION_CONFIG" --group "Notifications" --key "PopupPosition" "BottomRight"

    # Reduce notification timeout
    kwriteconfig5 --file "$NOTIFICATION_CONFIG" --group "Notifications" --key "PopupTimeout" "3000"

    # Enable do not disturb for non-gaming apps
    kwriteconfig5 --file "$NOTIFICATION_CONFIG" --group "DoNotDisturb" --key "Enabled" "true"

    # Restart plasma notification service
    systemctl --user restart plasma-plasmashell 2>/dev/null || true

    echo "✅ Gaming notifications enabled"
}

# Disable gaming notifications (restore normal)
disable_gaming_notifications() {
    echo "🔔 Restoring normal notification mode..."

    # Restore notifications to top-right
    kwriteconfig5 --file "$NOTIFICATION_CONFIG" --group "Notifications" --key "PopupPosition" "TopRight"

    # Restore normal notification timeout
    kwriteconfig5 --file "$NOTIFICATION_CONFIG" --group "Notifications" --key "PopupTimeout" "5000"

    # Disable do not disturb
    kwriteconfig5 --file "$NOTIFICATION_CONFIG" --group "DoNotDisturb" --key "Enabled" "false"

    # Restart plasma notification service
    systemctl --user restart plasma-plasmashell 2>/dev/null || true

    echo "✅ Normal notifications restored"
}

# Auto-manage notifications based on gaming mode
auto_manage() {
    if is_gaming_mode_active; then
        enable_gaming_notifications
    else
        disable_gaming_notifications
    fi
}

# Show notification status
show_status() {
    echo "🔔 Gaming Notifications Status"

    if is_gaming_mode_active; then
        echo "  Mode: Gaming"
        echo "  Position: Bottom-right"
        echo "  Timeout: 3 seconds"
        echo "  Do Not Disturb: Enabled"
    else
        echo "  Mode: Normal"
        echo "  Position: Top-right"
        echo "  Timeout: 5 seconds"
        echo "  Do Not Disturb: Disabled"
    fi
}

# Main function
main() {
    local action="${1:-auto}"

    case "$action" in
        "gaming"|"enable")
            enable_gaming_notifications
            ;;
        "normal"|"disable")
            disable_gaming_notifications
            ;;
        "auto")
            auto_manage
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 {gaming|normal|auto|status}"
            echo "  gaming/enable  - Enable gaming notification mode"
            echo "  normal/disable - Restore normal notifications"
            echo "  auto          - Auto-manage based on gaming mode"
            echo "  status        - Show current status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$notify_script"
    print_info "✓ Gaming notifications script created: $notify_script"
}

# ==============================================================================
# Window Management Functions
# ==============================================================================

# Setup gaming window management
setup_gaming_window_management() {
    print_header "🪟 Setting Up Gaming Window Management"

    # Create window rules configuration
    create_window_rules_config

    # Setup gaming window rules
    setup_gaming_window_rules

    # Create window management script
    create_window_management_script

    print_success "Gaming window management configured"
}

# Create window rules configuration
create_window_rules_config() {
    ensure_directory "$(dirname "$GAMING_WINDOW_RULES")"

    cat > "$GAMING_WINDOW_RULES" << 'EOF'
# xanadOS Gaming Window Rules Configuration
# Defines window management behavior for gaming applications

[Gaming Applications]
# Steam applications
Steam=fullscreen,no-border,high-priority
SteamWebHelper=normal,background
SteamVR=fullscreen,no-border,maximum-priority

# Lutris applications
Lutris=normal,high-priority
lutris-wine=fullscreen,no-border,high-priority

# Gaming engines and platforms
UnityPlayer=fullscreen,no-border,high-priority
UnrealEngine=fullscreen,no-border,high-priority
GameMaker=fullscreen,no-border,high-priority

# Communication applications (gaming-related)
Discord=floating,always-on-top,small
TeamSpeak=floating,always-on-top,small
Mumble=floating,always-on-top,small

[Window Rules]
# Fullscreen gaming behavior
FullscreenGames=no-border,disable-compositor,high-priority,no-shadow
WindowedGames=thin-border,high-priority,focus-follows-mouse

# Performance optimizations
DisableAnimations=true
DisableTransparency=true
DisableShadows=true
DisableBlur=true

[Focus Management]
# Gaming focus behavior
GameWindowFocus=immediate
PreventFocusSteal=false
AutoRaiseGames=true
ClickToFocusGames=false

[Gaming Mode Window Behavior]
# Window behavior during gaming mode
MinimizeNonGaming=true
HideDecorations=true
DisableEffects=true
MaximizePerformance=true
EOF

    print_info "✓ Gaming window rules configuration created"
}

# Setup gaming window rules in KDE
setup_gaming_window_rules() {
    if ! command -v kwriteconfig5 >/dev/null 2>&1; then
        print_warning "KDE tools not available. Window rules saved for manual installation."
        return 0
    fi

    local kwin_rules="$KDE_CONFIG/kwinrulesrc"

    # Gaming window rules
    kwriteconfig5 --file "$kwin_rules" --group "1" --key "Description" "Gaming Applications"
    kwriteconfig5 --file "$kwin_rules" --group "1" --key "wmclass" "steam lutris discord"
    kwriteconfig5 --file "$kwin_rules" --group "1" --key "wmclassmatch" "3"
    kwriteconfig5 --file "$kwin_rules" --group "1" --key "noborder" "true"
    kwriteconfig5 --file "$kwin_rules" --group "1" --key "noborderrule" "2"

    # Gaming performance rules
    kwriteconfig5 --file "$kwin_rules" --group "2" --key "Description" "Gaming Performance"
    kwriteconfig5 --file "$kwin_rules" --group "2" --key "wmclass" "steam lutris"
    kwriteconfig5 --file "$kwin_rules" --group "2" --key "wmclassmatch" "3"
    kwriteconfig5 --file "$kwin_rules" --group "2" --key "disablecompositing" "true"
    kwriteconfig5 --file "$kwin_rules" --group "2" --key "disablecompositingrule" "2"

    # KWin general settings for gaming
    local kwin_config="$KDE_CONFIG/kwinrc"
    kwriteconfig5 --file "$kwin_config" --group "Compositing" --key "UnredirectFullscreen" "true"
    kwriteconfig5 --file "$kwin_config" --group "Compositing" --key "WindowsBlockCompositing" "true"
    kwriteconfig5 --file "$kwin_config" --group "Windows" --key "BorderlessMaximizedWindows" "true"

    print_info "✓ Gaming window rules installed to KDE"
}

# Create window management script
create_window_management_script() {
    local window_script="$HOME/.local/bin/xanados-gaming-windows"
    ensure_directory "$(dirname "$window_script")"

    cat > "$window_script" << 'EOF'
#!/bin/bash

# xanadOS Gaming Window Management
# Manages window behavior for gaming sessions

set -euo pipefail

# Apply gaming window settings
apply_gaming_windows() {
    echo "🪟 Applying gaming window settings..."

    # Disable window animations
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Effect-Fade" --key "FadeWindows" "false"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Effect-Scale" --key "ScaleWindows" "false"

    # Optimize window management for gaming
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "FocusStealingPreventionLevel" "0"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "AutoRaise" "true"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "DelayFocusInterval" "0"

    # Disable compositing for fullscreen windows
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Compositing" --key "UnredirectFullscreen" "true"

    # Reconfigure KWin
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

    echo "✅ Gaming window settings applied"
}

# Restore normal window settings
restore_normal_windows() {
    echo "🪟 Restoring normal window settings..."

    # Re-enable window animations
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Effect-Fade" --key "FadeWindows" "true"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Effect-Scale" --key "ScaleWindows" "true"

    # Restore normal window management
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "FocusStealingPreventionLevel" "1"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "AutoRaise" "false"
    kwriteconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "DelayFocusInterval" "300"

    # Reconfigure KWin
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

    echo "✅ Normal window settings restored"
}

# Show window management status
show_window_status() {
    echo "🪟 Gaming Window Management Status"

    local auto_raise=$(kreadconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "AutoRaise" 2>/dev/null || echo "false")
    local focus_prevention=$(kreadconfig5 --file "$HOME/.config/kwinrc" --group "Windows" --key "FocusStealingPreventionLevel" 2>/dev/null || echo "1")
    local unredirect=$(kreadconfig5 --file "$HOME/.config/kwinrc" --group "Compositing" --key "UnredirectFullscreen" 2>/dev/null || echo "false")

    echo "  Auto Raise: $auto_raise"
    echo "  Focus Prevention Level: $focus_prevention"
    echo "  Unredirect Fullscreen: $unredirect"
}

# Main function
main() {
    local action="${1:-status}"

    case "$action" in
        "gaming"|"apply")
            apply_gaming_windows
            ;;
        "normal"|"restore")
            restore_normal_windows
            ;;
        "status")
            show_window_status
            ;;
        *)
            echo "Usage: $0 {gaming|normal|status}"
            echo "  gaming/apply   - Apply gaming window settings"
            echo "  normal/restore - Restore normal window settings"
            echo "  status         - Show current window settings"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$window_script"
    print_info "✓ Gaming window management script created: $window_script"
}

# ==============================================================================
# Integration and Automation Functions
# ==============================================================================

# Setup gaming workflow automation
setup_gaming_workflow_automation() {
    print_header "🤖 Setting Up Gaming Workflow Automation"

    # Create workflow automation script
    create_workflow_automation_script

    # Setup gaming session detection
    setup_gaming_session_detection

    # Create workflow integration with gaming profiles
    create_workflow_integration

    print_success "Gaming workflow automation configured"
}

# Create main workflow automation script
create_workflow_automation_script() {
    local automation_script="$HOME/.local/bin/xanados-gaming-workflow"
    ensure_directory "$(dirname "$automation_script")"

    cat > "$automation_script" << 'EOF'
#!/bin/bash

# xanadOS Gaming Workflow Automation
# Coordinates all gaming workflow components

set -euo pipefail

GAMING_MODE_SCRIPT="$HOME/.local/bin/xanados-gaming-mode"
NOTIFICATION_SCRIPT="$HOME/.local/bin/xanados-gaming-notifications"
WINDOW_SCRIPT="$HOME/.local/bin/xanados-gaming-windows"

# Start gaming session
start_gaming_session() {
    echo "🚀 Starting gaming session..."

    # Activate gaming mode
    "$GAMING_MODE_SCRIPT" activate

    # Setup gaming notifications
    "$NOTIFICATION_SCRIPT" gaming

    # Apply gaming window settings
    "$WINDOW_SCRIPT" gaming

    # Show session started notification
    notify-send "xanadOS Gaming" "Gaming session started" --icon=applications-games

    echo "✅ Gaming session started successfully"
}

# End gaming session
end_gaming_session() {
    echo "🏁 Ending gaming session..."

    # Deactivate gaming mode
    "$GAMING_MODE_SCRIPT" deactivate

    # Restore normal notifications
    "$NOTIFICATION_SCRIPT" normal

    # Restore normal window settings
    "$WINDOW_SCRIPT" normal

    # Show session ended notification
    notify-send "xanadOS Gaming" "Gaming session ended" --icon=dialog-information

    echo "✅ Gaming session ended successfully"
}

# Show gaming workflow status
show_workflow_status() {
    echo "🎮 xanadOS Gaming Workflow Status"
    echo "================================="

    # Check gaming mode status
    "$GAMING_MODE_SCRIPT" status
    echo

    # Check notification status
    "$NOTIFICATION_SCRIPT" status
    echo

    # Check window management status
    "$WINDOW_SCRIPT" status
}

# Quick game launcher
quick_game_launcher() {
    local launcher_choice

    # Show game launcher menu
    launcher_choice=$(zenity --list \
        --title="xanadOS Game Launcher" \
        --text="Choose a gaming platform:" \
        --column="Platform" \
        --column="Description" \
        "Steam" "Steam gaming platform" \
        "Lutris" "Open gaming platform" \
        "GameMode" "Game optimization tool" \
        "Gaming Profile Manager" "Manage gaming profiles" \
        2>/dev/null || echo "")

    case "$launcher_choice" in
        "Steam")
            start_gaming_session
            steam &
            ;;
        "Lutris")
            start_gaming_session
            lutris &
            ;;
        "GameMode")
            gamemoderun &
            ;;
        "Gaming Profile Manager")
            konsole -e "cd /home/vm/Documents/xanadOS && source scripts/lib/gaming-profiles.sh && list_gaming_profiles" &
            ;;
    esac
}

# Main function
main() {
    local action="${1:-menu}"

    case "$action" in
        "start"|"begin")
            start_gaming_session
            ;;
        "end"|"stop")
            end_gaming_session
            ;;
        "status")
            show_workflow_status
            ;;
        "launcher"|"launch")
            quick_game_launcher
            ;;
        "menu")
            # Interactive menu
            local choice
            choice=$(zenity --list \
                --title="xanadOS Gaming Workflow" \
                --text="Choose an action:" \
                --column="Action" \
                --column="Description" \
                "Start Gaming Session" "Start optimized gaming session" \
                "End Gaming Session" "End gaming session and restore normal settings" \
                "Quick Game Launcher" "Launch gaming platforms" \
                "Show Status" "Show current gaming workflow status" \
                2>/dev/null || echo "")

            case "$choice" in
                "Start Gaming Session")
                    start_gaming_session
                    ;;
                "End Gaming Session")
                    end_gaming_session
                    ;;
                "Quick Game Launcher")
                    quick_game_launcher
                    ;;
                "Show Status")
                    show_workflow_status
                    ;;
            esac
            ;;
        *)
            echo "Usage: $0 {start|end|status|launcher|menu}"
            echo "  start/begin    - Start gaming session"
            echo "  end/stop       - End gaming session"
            echo "  status         - Show workflow status"
            echo "  launcher/launch - Quick game launcher"
            echo "  menu           - Interactive menu"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$automation_script"
    print_info "✓ Gaming workflow automation script created: $automation_script"
}

# Setup gaming session detection
setup_gaming_session_detection() {
    local detection_script="$HOME/.local/bin/xanados-gaming-detector"
    ensure_directory "$(dirname "$detection_script")"

    cat > "$detection_script" << 'EOF'
#!/bin/bash

# xanadOS Gaming Session Detector
# Automatically detects when games are running and adjusts settings

set -euo pipefail

GAMING_PROCESSES=("steam" "lutris" "wine" "steamwebhelper" "steam.exe" "gamemode")
CHECK_INTERVAL=5
GAMING_WORKFLOW_SCRIPT="$HOME/.local/bin/xanados-gaming-workflow"

# Check if gaming processes are running
is_gaming_active() {
    for process in "${GAMING_PROCESSES[@]}"; do
        if pgrep -f "$process" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

# Monitor gaming sessions
monitor_gaming_sessions() {
    local was_gaming=false
    local is_gaming=false

    echo "🎮 Starting gaming session monitor..."

    while true; do
        if is_gaming_active; then
            is_gaming=true
        else
            is_gaming=false
        fi

        # Gaming session started
        if [[ "$is_gaming" == true && "$was_gaming" == false ]]; then
            echo "🚀 Gaming session detected - starting optimization..."
            "$GAMING_WORKFLOW_SCRIPT" start
        fi

        # Gaming session ended
        if [[ "$is_gaming" == false && "$was_gaming" == true ]]; then
            echo "🏁 Gaming session ended - restoring normal settings..."
            "$GAMING_WORKFLOW_SCRIPT" end
        fi

        was_gaming=$is_gaming
        sleep $CHECK_INTERVAL
    done
}

# Main function
main() {
    local action="${1:-monitor}"

    case "$action" in
        "monitor"|"start")
            monitor_gaming_sessions
            ;;
        "check")
            if is_gaming_active; then
                echo "Gaming session active"
                exit 0
            else
                echo "No gaming session detected"
                exit 1
            fi
            ;;
        "status")
            if is_gaming_active; then
                echo "🎮 Gaming processes detected:"
                for process in "${GAMING_PROCESSES[@]}"; do
                    if pgrep -f "$process" >/dev/null 2>&1; then
                        echo "  ✓ $process"
                    fi
                done
            else
                echo "❌ No gaming processes detected"
            fi
            ;;
        *)
            echo "Usage: $0 {monitor|check|status}"
            echo "  monitor/start - Start gaming session monitoring"
            echo "  check         - Check if gaming is currently active"
            echo "  status        - Show detected gaming processes"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$detection_script"
    print_info "✓ Gaming session detection script created: $detection_script"
}

# Create workflow integration with gaming profiles
create_workflow_integration() {
    local integration_script="$HOME/.local/bin/xanados-workflow-integration"
    ensure_directory "$(dirname "$integration_script")"

    cat > "$integration_script" << 'EOF'
#!/bin/bash

# xanadOS Gaming Workflow Integration
# Integrates gaming profiles with workflow automation

set -euo pipefail

GAMING_PROFILES_LIB="/home/vm/Documents/xanadOS/scripts/lib/gaming-profiles.sh"
GAMING_WORKFLOW_SCRIPT="$HOME/.local/bin/xanados-gaming-workflow"

# Source gaming profiles if available
if [[ -f "$GAMING_PROFILES_LIB" ]]; then
    source "$GAMING_PROFILES_LIB"
fi

# Apply gaming profile with workflow
apply_profile_with_workflow() {
    local profile_name="$1"

    echo "🎮 Applying gaming profile with workflow: $profile_name"

    # Start gaming session
    "$GAMING_WORKFLOW_SCRIPT" start

    # Apply gaming profile if available
    if command -v apply_gaming_profile >/dev/null 2>&1; then
        apply_gaming_profile "$profile_name"
    else
        echo "⚠️ Gaming profiles not available"
    fi

    echo "✅ Gaming profile and workflow applied: $profile_name"
}

# List available profiles and workflows
list_profiles_and_workflows() {
    echo "🎮 Available Gaming Profiles and Workflows"
    echo "==========================================="

    # List gaming profiles if available
    if command -v list_gaming_profiles >/dev/null 2>&1; then
        echo "📋 Gaming Profiles:"
        list_gaming_profiles
    else
        echo "❌ Gaming profiles not available"
    fi

    echo
    echo "🛠️ Available Workflows:"
    echo "  • Standard Gaming Session"
    echo "  • Competitive Gaming Session"
    echo "  • Streaming Gaming Session"
    echo "  • VR Gaming Session"
}

# Quick profile launcher
quick_profile_launcher() {
    if ! command -v list_gaming_profiles >/dev/null 2>&1; then
        echo "❌ Gaming profiles not available"
        return 1
    fi

    # Get available profiles
    local profiles
    profiles=$(list_gaming_profiles names)

    if [[ -z "$profiles" ]]; then
        echo "❌ No gaming profiles found"
        return 1
    fi

    # Show profile selection menu
    local selected_profile
    selected_profile=$(echo "$profiles" | zenity --list \
        --title="Select Gaming Profile" \
        --text="Choose a gaming profile to apply:" \
        --column="Profile Name" \
        2>/dev/null || echo "")

    if [[ -n "$selected_profile" ]]; then
        apply_profile_with_workflow "$selected_profile"
    fi
}

# Main function
main() {
    local action="${1:-menu}"

    case "$action" in
        "apply")
            if [[ $# -ge 2 ]]; then
                apply_profile_with_workflow "$2"
            else
                echo "❌ Error: Profile name required"
                echo "Usage: $0 apply <profile-name>"
                exit 1
            fi
            ;;
        "list")
            list_profiles_and_workflows
            ;;
        "launcher")
            quick_profile_launcher
            ;;
        "menu")
            # Interactive menu
            local choice
            choice=$(zenity --list \
                --title="xanadOS Gaming Integration" \
                --text="Choose an option:" \
                --column="Option" \
                --column="Description" \
                "Quick Profile Launcher" "Select and apply a gaming profile" \
                "List Profiles" "Show available profiles and workflows" \
                "Apply Profile" "Apply a specific gaming profile" \
                2>/dev/null || echo "")

            case "$choice" in
                "Quick Profile Launcher")
                    quick_profile_launcher
                    ;;
                "List Profiles")
                    list_profiles_and_workflows
                    ;;
                "Apply Profile")
                    # Get profile name from user
                    local profile_name
                    profile_name=$(zenity --entry \
                        --title="Apply Gaming Profile" \
                        --text="Enter the gaming profile name:" \
                        2>/dev/null || echo "")

                    if [[ -n "$profile_name" ]]; then
                        apply_profile_with_workflow "$profile_name"
                    fi
                    ;;
            esac
            ;;
        *)
            echo "Usage: $0 {apply|list|launcher|menu}"
            echo "  apply <profile>  - Apply gaming profile with workflow"
            echo "  list            - List available profiles and workflows"
            echo "  launcher        - Quick profile launcher"
            echo "  menu            - Interactive menu"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x "$integration_script"
    print_info "✓ Gaming workflow integration script created: $integration_script"
}

# ==============================================================================
# Main Functions
# ==============================================================================

# Show usage information
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  init-gaming-mode     Initialize gaming mode system"
    echo "  setup-shortcuts      Setup gaming shortcuts"
    echo "  setup-notifications  Setup gaming notification management"
    echo "  setup-windows        Setup gaming window management"
    echo "  setup-automation     Setup gaming workflow automation"
    echo "  install-all         Install all gaming workflow components"
    echo "  status              Show gaming workflow status"
    echo "  help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install-all"
    echo "  $0 setup-shortcuts"
    echo "  $0 status"
}

# Install all gaming workflow components
install_all_components() {
    print_header "🎮 Installing Gaming Workflow Optimization - Phase 4.2.2"
    print_info "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    print_info "Phase: $PHASE"
    echo

    # Initialize gaming mode system
    init_gaming_mode
    echo

    # Setup gaming shortcuts
    setup_gaming_shortcuts
    echo

    # Setup gaming notifications
    setup_gaming_notifications
    echo

    # Setup gaming window management
    setup_gaming_window_management
    echo

    # Setup gaming workflow automation
    setup_gaming_workflow_automation
    echo

    print_header "🎉 Phase 4.2.2 Gaming Workflow Optimization Complete!"
    print_success "All gaming workflow components installed successfully"
    echo

    print_section "📋 Summary of Changes"
    echo "✅ Gaming mode system initialized"
    echo "✅ Gaming shortcuts configured"
    echo "✅ Gaming notification management setup"
    echo "✅ Gaming window management optimized"
    echo "✅ Gaming workflow automation implemented"
    echo

    print_section "🚀 Quick Start"
    echo "• Toggle gaming mode: xanados-gaming-mode toggle"
    echo "• Start gaming session: xanados-gaming-workflow start"
    echo "• Quick game launcher: xanados-gaming-workflow launcher"
    echo "• Gaming profile integration: xanados-workflow-integration launcher"
    echo "• Check status: xanados-gaming-workflow status"
    echo

    print_section "📁 Created Scripts"
    echo "• Gaming mode: ~/.local/bin/xanados-gaming-mode"
    echo "• Notifications: ~/.local/bin/xanados-gaming-notifications"
    echo "• Window management: ~/.local/bin/xanados-gaming-windows"
    echo "• Workflow automation: ~/.local/bin/xanados-gaming-workflow"
    echo "• Session detection: ~/.local/bin/xanados-gaming-detector"
    echo "• Profile integration: ~/.local/bin/xanados-workflow-integration"
}

# Show gaming workflow status
show_gaming_workflow_status() {
    print_header "📊 Gaming Workflow Status"

    # Check if scripts exist
    local scripts=(
        "xanados-gaming-mode"
        "xanados-gaming-notifications"
        "xanados-gaming-windows"
        "xanados-gaming-workflow"
        "xanados-gaming-detector"
        "xanados-workflow-integration"
    )

    echo "🛠️ Gaming Workflow Scripts:"
    for script in "${scripts[@]}"; do
        if [[ -x "$HOME/.local/bin/$script" ]]; then
            echo "  ✅ $script"
        else
            echo "  ❌ $script (not found)"
        fi
    done
    echo

    # Check configuration files
    echo "📁 Configuration Files:"
    local configs=(
        "$GAMING_MODE_CONFIG"
        "$GAMING_SHORTCUTS_CONFIG"
        "$GAMING_NOTIFICATIONS_CONFIG"
        "$GAMING_WINDOW_RULES"
    )

    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            echo "  ✅ $(basename "$config")"
        else
            echo "  ❌ $(basename "$config") (not found)"
        fi
    done
    echo

    # Check gaming mode status if available
    if [[ -x "$HOME/.local/bin/xanados-gaming-mode" ]]; then
        echo "🎮 Current Gaming Mode Status:"
        "$HOME/.local/bin/xanados-gaming-mode" status
    fi
}

# Main function
main() {
    local cmd="${1:-help}"

    case "$cmd" in
        init-gaming-mode)
            init_gaming_mode
            ;;
        setup-shortcuts)
            setup_gaming_shortcuts
            ;;
        setup-notifications)
            setup_gaming_notifications
            ;;
        setup-windows)
            setup_gaming_window_management
            ;;
        setup-automation)
            setup_gaming_workflow_automation
            ;;
        install-all)
            install_all_components
            ;;
        status)
            show_gaming_workflow_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo "❌ Error: Unknown command '$cmd'"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
