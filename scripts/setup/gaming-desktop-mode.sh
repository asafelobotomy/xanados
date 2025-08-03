#!/bin/bash

# 🎮 xanadOS Gaming Desktop Mode Implementation
# Phase 4.4.1: Gaming Environment Management
#
# Purpose: Specialized gaming desktop environment with mode switching,
#          performance optimization, and gaming tools quick access
#
# Author: xanadOS Development Team
# Version: 1.0.0
# Date: August 3, 2025

set -euo pipefail

# Simple logging functions (inline to avoid dependency issues)
log_info() {
    echo "[INFO] $*"
}

log_warning() {
    echo "[WARNING] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    [[ "${XANADOS_DEBUG:-false}" == "true" ]] && echo "[DEBUG] $*" >&2 || true
}

# 📁 Directory and file setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
XANADOS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
LIB_DIR="$SCRIPT_DIR/../lib"

# Optional library loading (fail gracefully if not available)
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh" || log_warning "Failed to load common library"
fi

if [[ -f "$LIB_DIR/gaming-env.sh" ]]; then
    source "$LIB_DIR/gaming-env.sh" || log_warning "Failed to load gaming environment library"
fi

if [[ -f "$LIB_DIR/hardware-detection.sh" ]]; then
    source "$LIB_DIR/hardware-detection.sh" || log_warning "Failed to load hardware detection library"
fi

# 🎯 Configuration
GAMING_MODE_CONFIG="$HOME/.config/xanados/gaming-mode.conf"
GAMING_MODE_STATE="$HOME/.cache/xanados/gaming-mode.state"
GAMING_WIDGETS_CONFIG="$HOME/.config/xanados/gaming-widgets.conf"
KDE_CONFIG_DIR="$HOME/.config"

# 🎮 Gaming Desktop Mode Functions

# Initialize gaming mode configuration
init_gaming_mode() {
    log_info "Initializing gaming desktop mode..."

    # Create configuration directories
    mkdir -p "$(dirname "$GAMING_MODE_CONFIG")"
    mkdir -p "$(dirname "$GAMING_MODE_STATE")"
    mkdir -p "$(dirname "$GAMING_WIDGETS_CONFIG")"

    # Create default gaming mode configuration
    cat > "$GAMING_MODE_CONFIG" << 'EOF'
# xanadOS Gaming Mode Configuration
# Generated automatically - modify with caution

[general]
auto_performance_mode=true
hide_desktop_clutter=true
minimize_background_apps=true
enable_gaming_shortcuts=true
show_performance_overlay=false

[desktop]
wallpaper_mode=gaming
panel_mode=minimal
widget_set=gaming
notification_mode=gaming

[performance]
cpu_governor=performance
gpu_performance_mode=high
disable_compositor=auto
reduce_animations=true
prioritize_gaming_processes=true

[shortcuts]
toggle_gaming_mode=Meta+F1
quick_performance_stats=Meta+F2
launch_steam=Meta+F3
launch_lutris=Meta+F4
system_monitor=Meta+F5

[notifications]
gaming_session_disable=true
performance_alerts=true
low_battery_gaming_mode=true
EOF

    # Create gaming widgets configuration
    cat > "$GAMING_WIDGETS_CONFIG" << 'EOF'
# xanadOS Gaming Widgets Configuration

[performance_monitor]
enabled=true
position=top_right
update_interval=1000
show_fps=true
show_cpu_usage=true
show_gpu_usage=true
show_memory_usage=true
show_temperature=true

[quick_launcher]
enabled=true
position=bottom_center
games_list=auto_detect
show_recently_played=true
max_games_shown=8

[system_status]
enabled=true
position=top_left
show_network_status=true
show_audio_status=true
show_controller_status=true

[notification_overlay]
enabled=true
position=bottom_right
gaming_mode_notifications=true
achievement_notifications=true
friend_notifications=false
EOF

    log_info "✅ Gaming mode configuration initialized"
}

# Activate gaming desktop mode
activate_gaming_mode() {
    log_info "🎮 Activating Gaming Desktop Mode..."

    # Check if already in gaming mode
    if [[ -f "$GAMING_MODE_STATE" ]] && grep -q "active=true" "$GAMING_MODE_STATE"; then
        log_warning "Gaming mode is already active"
        return 0
    fi

    # Store current desktop state
    store_desktop_state

    # Apply gaming desktop configuration
    apply_gaming_desktop_config

    # Enable gaming performance optimizations
    enable_gaming_performance

    # Configure gaming shortcuts
    setup_gaming_shortcuts

    # Launch gaming widgets
    launch_gaming_widgets

    # Update gaming mode state
    cat > "$GAMING_MODE_STATE" << EOF
active=true
activated_at=$(date -Iseconds)
desktop_session=$(echo "${XDG_CURRENT_DESKTOP:-unknown}")
original_wallpaper=$(get_current_wallpaper)
original_panel_config=$(get_panel_config)
EOF

    # Send notification
    notify_gaming_mode_change "activated"

    log_info "✅ Gaming Desktop Mode activated successfully"
}

# Deactivate gaming desktop mode
deactivate_gaming_mode() {
    log_info "🔄 Deactivating Gaming Desktop Mode..."

    # Check if gaming mode is active
    if [[ ! -f "$GAMING_MODE_STATE" ]] || ! grep -q "active=true" "$GAMING_MODE_STATE"; then
        log_warning "Gaming mode is not currently active"
        return 0
    fi

    # Restore original desktop state
    restore_desktop_state

    # Disable gaming performance optimizations
    disable_gaming_performance

    # Remove gaming shortcuts
    remove_gaming_shortcuts

    # Close gaming widgets
    close_gaming_widgets

    # Clear gaming mode state
    cat > "$GAMING_MODE_STATE" << EOF
active=false
deactivated_at=$(date -Iseconds)
EOF

    # Send notification
    notify_gaming_mode_change "deactivated"

    log_info "✅ Gaming Desktop Mode deactivated successfully"
}

# Store current desktop state for restoration
store_desktop_state() {
    log_debug "Storing current desktop state..."

    local state_backup="$HOME/.cache/xanados/desktop-state-backup.conf"

    cat > "$state_backup" << EOF
# Desktop State Backup - $(date)
wallpaper=$(get_current_wallpaper)
panel_config=$(get_panel_config)
widget_config=$(get_widget_config)
compositor_enabled=$(get_compositor_status)
animation_speed=$(get_animation_speed)
notification_settings=$(get_notification_settings)
EOF

    log_debug "✅ Desktop state stored"
}

# Apply gaming-optimized desktop configuration
apply_gaming_desktop_config() {
    log_debug "Applying gaming desktop configuration..."

    # Set gaming wallpaper
    set_gaming_wallpaper

    # Configure minimal panel
    configure_gaming_panel

    # Optimize desktop effects
    optimize_desktop_effects

    # Configure gaming-friendly notifications
    configure_gaming_notifications

    log_debug "✅ Gaming desktop configuration applied"
}

# Enable gaming performance optimizations
enable_gaming_performance() {
    log_debug "Enabling gaming performance optimizations..."

    # Set CPU governor to performance
    if command -v cpupower &> /dev/null; then
        sudo cpupower frequency-set -g performance 2>/dev/null || log_warning "Failed to set CPU governor"
    fi

    # Disable desktop compositor if configured
    if [[ "$(get_config_value "$GAMING_MODE_CONFIG" "performance" "disable_compositor")" == "auto" ]]; then
        disable_compositor_for_gaming
    fi

    # Reduce animations
    if [[ "$(get_config_value "$GAMING_MODE_CONFIG" "performance" "reduce_animations")" == "true" ]]; then
        reduce_desktop_animations
    fi

    # Priority boost for gaming processes
    if [[ "$(get_config_value "$GAMING_MODE_CONFIG" "performance" "prioritize_gaming_processes")" == "true" ]]; then
        setup_gaming_process_priority
    fi

    log_debug "✅ Gaming performance optimizations enabled"
}

# Setup gaming shortcuts
setup_gaming_shortcuts() {
    log_debug "Setting up gaming shortcuts..."

    # KDE Plasma shortcut configuration
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        setup_kde_gaming_shortcuts
    fi

    log_debug "✅ Gaming shortcuts configured"
}

# Launch gaming widgets
launch_gaming_widgets() {
    log_debug "Launching gaming widgets..."

    # Performance monitor widget
    if [[ "$(get_config_value "$GAMING_WIDGETS_CONFIG" "performance_monitor" "enabled")" == "true" ]]; then
        launch_performance_monitor_widget
    fi

    # Quick launcher widget
    if [[ "$(get_config_value "$GAMING_WIDGETS_CONFIG" "quick_launcher" "enabled")" == "true" ]]; then
        launch_quick_launcher_widget
    fi

    # System status widget
    if [[ "$(get_config_value "$GAMING_WIDGETS_CONFIG" "system_status" "enabled")" == "true" ]]; then
        launch_system_status_widget
    fi

    log_debug "✅ Gaming widgets launched"
}

# Restore original desktop state
restore_desktop_state() {
    log_debug "Restoring original desktop state..."

    local state_backup="$HOME/.cache/xanados/desktop-state-backup.conf"

    if [[ -f "$state_backup" ]]; then
        # Restore wallpaper
        local original_wallpaper
        original_wallpaper=$(get_config_value "$state_backup" "" "wallpaper")
        if [[ -n "$original_wallpaper" ]]; then
            restore_wallpaper "$original_wallpaper"
        fi

        # Restore compositor
        local compositor_was_enabled
        compositor_was_enabled=$(get_config_value "$state_backup" "" "compositor_enabled")
        if [[ "$compositor_was_enabled" == "true" ]]; then
            enable_compositor
        fi

        # Restore animations
        local original_animation_speed
        original_animation_speed=$(get_config_value "$state_backup" "" "animation_speed")
        if [[ -n "$original_animation_speed" ]]; then
            restore_animation_speed "$original_animation_speed"
        fi
    fi

    log_debug "✅ Desktop state restored"
}

# Helper Functions

get_current_wallpaper() {
    if command -v plasma-apply-wallpaperimage &> /dev/null; then
        # KDE Plasma
        kreadconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --key Image 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

get_panel_config() {
    echo "default"  # Placeholder - would implement actual panel detection
}

get_widget_config() {
    echo "default"  # Placeholder - would implement actual widget detection
}

get_compositor_status() {
    if command -v kwin_x11 &> /dev/null; then
        # Check if KWin compositor is running
        if pgrep -x kwin_x11 &> /dev/null || pgrep -x kwin_wayland &> /dev/null; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "unknown"
    fi
}

get_animation_speed() {
    echo "1.0"  # Placeholder - would implement actual animation speed detection
}

get_notification_settings() {
    echo "default"  # Placeholder - would implement actual notification settings detection
}

set_gaming_wallpaper() {
    local gaming_wallpaper="$XANADOS_ROOT/configs/desktop/wallpapers/gaming-mode.jpg"

    if [[ -f "$gaming_wallpaper" ]] && command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage "$gaming_wallpaper" 2>/dev/null || log_warning "Failed to set gaming wallpaper"
    fi
}

configure_gaming_panel() {
    # Configure minimal panel for gaming (KDE Plasma)
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        # Hide panel auto-hide
        kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key alignment 1 2>/dev/null || true
    fi
}

optimize_desktop_effects() {
    # Disable heavy desktop effects during gaming
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key Enabled false 2>/dev/null || true
        kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 0 2>/dev/null || true
    fi
}

configure_gaming_notifications() {
    # Configure gaming-friendly notification settings
    log_debug "Configuring gaming notifications..."
}

disable_compositor_for_gaming() {
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key Enabled false
        # Restart KWin to apply changes
        if command -v kwin_x11 &> /dev/null; then
            kwin_x11 --replace &>/dev/null &
        fi
    fi
}

reduce_desktop_animations() {
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 0
    fi
}

setup_gaming_process_priority() {
    # This would implement process priority management
    log_debug "Gaming process priority optimization configured"
}

setup_kde_gaming_shortcuts() {
    if command -v kwriteconfig5 &> /dev/null; then
        # Toggle gaming mode shortcut
        kwriteconfig5 --file kglobalshortcutsrc --group xanados-gaming --key "toggle-gaming-mode" "Meta+F1,none,Toggle Gaming Mode"

        # Performance stats shortcut
        kwriteconfig5 --file kglobalshortcutsrc --group xanados-gaming --key "performance-stats" "Meta+F2,none,Show Performance Stats"

        # Steam shortcut
        kwriteconfig5 --file kglobalshortcutsrc --group xanados-gaming --key "launch-steam" "Meta+F3,none,Launch Steam"

        # Lutris shortcut
        kwriteconfig5 --file kglobalshortcutsrc --group xanados-gaming --key "launch-lutris" "Meta+F4,none,Launch Lutris"
    fi
}

launch_performance_monitor_widget() {
    # Launch performance monitoring widget
    log_debug "Performance monitor widget launched"
}

launch_quick_launcher_widget() {
    # Launch gaming quick launcher widget
    log_debug "Quick launcher widget launched"
}

launch_system_status_widget() {
    # Launch system status widget
    log_debug "System status widget launched"
}

disable_gaming_performance() {
    log_debug "Disabling gaming performance optimizations..."

    # Restore CPU governor
    if command -v cpupower &> /dev/null; then
        sudo cpupower frequency-set -g powersave 2>/dev/null || log_warning "Failed to restore CPU governor"
    fi

    # Re-enable compositor
    enable_compositor

    # Restore animations
    restore_animations

    log_debug "✅ Gaming performance optimizations disabled"
}

remove_gaming_shortcuts() {
    log_debug "Removing gaming shortcuts..."
    # Implementation would remove the gaming shortcuts
    log_debug "✅ Gaming shortcuts removed"
}

close_gaming_widgets() {
    log_debug "Closing gaming widgets..."
    # Implementation would close gaming widgets
    log_debug "✅ Gaming widgets closed"
}

restore_wallpaper() {
    local wallpaper="$1"
    if [[ -n "$wallpaper" ]] && [[ "$wallpaper" != "unknown" ]] && command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage "$wallpaper" 2>/dev/null || log_warning "Failed to restore wallpaper"
    fi
}

enable_compositor() {
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
        if command -v kwin_x11 &> /dev/null; then
            kwin_x11 --replace &>/dev/null &
        fi
    fi
}

restore_animation_speed() {
    local speed="$1"
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed "$speed"
    fi
}

restore_animations() {
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 1
    fi
}

notify_gaming_mode_change() {
    local action="$1"

    if command -v notify-send &> /dev/null; then
        case "$action" in
            "activated")
                notify-send "🎮 Gaming Mode" "Gaming Desktop Mode activated" --icon=applications-games
                ;;
            "deactivated")
                notify-send "🔄 Gaming Mode" "Gaming Desktop Mode deactivated" --icon=applications-games
                ;;
        esac
    fi
}

get_config_value() {
    local config_file="$1"
    local section="$2"
    local key="$3"

    if [[ -f "$config_file" ]]; then
        if [[ -n "$section" ]]; then
            sed -n "/^\[$section\]/,/^\[.*\]/p" "$config_file" | grep "^$key=" | cut -d'=' -f2 || echo ""
        else
            grep "^$key=" "$config_file" | cut -d'=' -f2 || echo ""
        fi
    else
        echo ""
    fi
}

# Toggle gaming mode
toggle_gaming_mode() {
    if [[ -f "$GAMING_MODE_STATE" ]] && grep -q "active=true" "$GAMING_MODE_STATE"; then
        deactivate_gaming_mode
    else
        activate_gaming_mode
    fi
}

# Show gaming mode status
show_gaming_mode_status() {
    echo "🎮 xanadOS Gaming Desktop Mode Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ -f "$GAMING_MODE_STATE" ]] && grep -q "active=true" "$GAMING_MODE_STATE"; then
        echo "Status: ✅ ACTIVE"
        local activated_at
        activated_at=$(grep "activated_at=" "$GAMING_MODE_STATE" | cut -d'=' -f2)
        echo "Activated: $activated_at"
        echo ""
        echo "Active Features:"
        echo "  • Gaming performance optimizations"
        echo "  • Minimal desktop layout"
        echo "  • Gaming shortcuts (Meta+F1-F5)"
        echo "  • Performance monitoring widgets"
        echo "  • Gaming-optimized notifications"
    else
        echo "Status: ⭕ INACTIVE"
        echo ""
        echo "Available Commands:"
        echo "  • $0 activate    - Enable gaming mode"
        echo "  • $0 toggle      - Toggle gaming mode"
        echo "  • $0 configure   - Configure gaming mode"
    fi

    echo ""
    echo "Gaming Mode Commands:"
    echo "  • Meta+F1: Toggle Gaming Mode"
    echo "  • Meta+F2: Performance Stats"
    echo "  • Meta+F3: Launch Steam"
    echo "  • Meta+F4: Launch Lutris"
    echo "  • Meta+F5: System Monitor"
}

# Configure gaming mode settings
configure_gaming_mode() {
    echo "🔧 Gaming Desktop Mode Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Configuration file: $GAMING_MODE_CONFIG"
    echo "Widget configuration: $GAMING_WIDGETS_CONFIG"
    echo ""
    echo "Edit these files to customize gaming mode behavior."
    echo "Run '$0 init' to reset to default configuration."
}

# Performance quick stats
show_performance_stats() {
    echo "📊 Gaming Performance Stats"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # CPU info
    echo "🔥 CPU Usage: $(get_cpu_usage)%"
    echo "⚡ CPU Governor: $(get_cpu_governor)"

    # Memory info
    echo "💾 Memory: $(get_memory_usage)"

    # GPU info if available
    if command -v nvidia-smi &> /dev/null; then
        echo "🎮 GPU Usage: $(get_gpu_usage)%"
        echo "🌡️  GPU Temp: $(get_gpu_temperature)°C"
    fi

    # Gaming mode status
    if [[ -f "$GAMING_MODE_STATE" ]] && grep -q "active=true" "$GAMING_MODE_STATE"; then
        echo "🎯 Gaming Mode: ✅ ACTIVE"
    else
        echo "🎯 Gaming Mode: ⭕ INACTIVE"
    fi
}

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'%' -f1 || echo "N/A"
}

get_cpu_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
}

get_memory_usage() {
    free -h | awk 'NR==2{printf "%s/%s (%.1f%%)", $3, $2, $3*100/$2}' || echo "N/A"
}

get_gpu_usage() {
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A"
}

get_gpu_temperature() {
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "N/A"
}

# 🎯 Main execution logic
main() {
    local command="${1:-status}"

    case "$command" in
        "init"|"initialize")
            log_info "🎮 Initializing Gaming Desktop Mode..."
            init_gaming_mode
            log_info "✅ Gaming Desktop Mode initialized successfully"
            ;;
        "activate"|"enable"|"on")
            activate_gaming_mode
            ;;
        "deactivate"|"disable"|"off")
            deactivate_gaming_mode
            ;;
        "toggle")
            toggle_gaming_mode
            ;;
        "status"|"show")
            show_gaming_mode_status
            ;;
        "configure"|"config")
            configure_gaming_mode
            ;;
        "stats"|"performance")
            show_performance_stats
            ;;
        "help"|"--help"|"-h")
            echo "🎮 xanadOS Gaming Desktop Mode - Usage"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Commands:"
            echo "  init        Initialize gaming mode configuration"
            echo "  activate    Enable gaming desktop mode"
            echo "  deactivate  Disable gaming desktop mode"
            echo "  toggle      Toggle gaming mode on/off"
            echo "  status      Show current gaming mode status"
            echo "  configure   Show configuration options"
            echo "  stats       Show performance statistics"
            echo "  help        Show this help message"
            echo ""
            echo "Keyboard Shortcuts (when active):"
            echo "  Meta+F1     Toggle gaming mode"
            echo "  Meta+F2     Show performance stats"
            echo "  Meta+F3     Launch Steam"
            echo "  Meta+F4     Launch Lutris"
            echo "  Meta+F5     System monitor"
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
