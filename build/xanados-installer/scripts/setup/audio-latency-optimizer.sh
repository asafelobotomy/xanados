#!/bin/bash
# ============================================================================
# xanadOS Audio Latency Optimization Script
# Optimizes PipeWire and audio stack for low-latency gaming
# ============================================================================

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/gaming-env.sh"
source "$SCRIPT_DIR/../lib/setup-common.sh"

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="audio-latency-optimizer"
readonly SCRIPT_TITLE="xanadOS Audio Latency Optimization"
readonly SCRIPT_SUBTITLE="Low-Latency Audio for Gaming Performance"
readonly SCRIPT_ICON="🎵"

# Audio optimization settings
readonly QUANTUM_SIZE="64"
readonly RATE="48000"
readonly MIN_QUANTUM="32"
readonly MAX_QUANTUM="8192"

# Configuration directories
readonly PIPEWIRE_CONFIG_DIR="$HOME/.config/pipewire"
readonly WIREPLUMBER_CONFIG_DIR="$HOME/.config/wireplumber"

# Configuration templates
readonly PIPEWIRE_CONFIG_TEMPLATE='# xanadOS PipeWire Low-Latency Configuration
context.properties = {
    default.clock.rate = {{rate}}
    default.clock.quantum = {{quantum}}
    default.clock.min-quantum = {{min_quantum}}
    default.clock.max-quantum = {{max_quantum}}
    core.daemon = true
    core.name = pipewire-0
    settings.check-quantum = true
    settings.check-rate = true
    mem.warn-mlock = false
    mem.allow-mlock = true
    log.level = 2
}

context.spa-libs = {
    audio.convert.* = audioconvert/libspa-audioconvert
    support.*       = support/libspa-support
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level = -11
            rt.prio = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-profiler }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-spa-device-factory }
    { name = libpipewire-module-spa-node-factory }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-client-device }
    { name = libpipewire-module-portal
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-session-manager }
]

stream.properties = {
    node.latency = {{quantum}}/{{rate}}
    resample.quality = 1
}

context.exec = [
    { path = "pactl" args = "load-module module-always-sink" }
]'

readonly WIREPLUMBER_CONFIG_TEMPLATE='-- xanadOS WirePlumber Low-Latency Configuration
default_access.properties = {}

alsa_monitor.properties = {
  ["alsa.jack-device"] = false,
}

alsa_monitor.rules = {
  {
    matches = {
      {
        { "device.name", "matches", "alsa_card.*" },
      },
    },
    apply_properties = {
      ["api.alsa.period-size"] = {{quantum}},
      ["api.alsa.headroom"] = 0,
      ["session.suspend-timeout-seconds"] = 0,
    },
  },
}'

# ============================================================================
# Audio System Functions
# ============================================================================
detect_audio_system() {
    if systemctl --user is-active pipewire &>/dev/null; then
        echo "pipewire"
    elif systemctl --user is-active pulseaudio &>/dev/null; then
        echo "pulseaudio"
    elif command -v jackd &>/dev/null && pgrep -x jackd &>/dev/null; then
        echo "jack"
    else
        echo "unknown"
    fi
}

install_audio_packages() {
    local audio_system
    audio_system=$(detect_audio_system)
    
    case "$audio_system" in
        "pipewire")
            print_info "PipeWire detected, installing additional packages..."
            install_packages_with_fallback pipewire-audio pipewire-alsa pipewire-pulse wireplumber
            ;;
        "pulseaudio")
            print_info "PulseAudio detected, installing PipeWire..."
            install_packages_with_fallback pipewire-audio pipewire-alsa pipewire-pulse wireplumber
            systemctl --user --now disable pulseaudio.service pulseaudio.socket
            systemctl --user --now enable pipewire pipewire-pulse wireplumber
            ;;
        *)
            print_warn "Unknown audio system, installing PipeWire..."
            install_packages_with_fallback pipewire-audio pipewire-alsa pipewire-pulse wireplumber
            ;;
    esac
}

optimize_pipewire_config() {
    print_info "Configuring PipeWire for low-latency audio..."
    
    # Create backup
    create_backup "$PIPEWIRE_CONFIG_DIR"
    
    # Generate optimized PipeWire configuration
    generate_config "$PIPEWIRE_CONFIG_TEMPLATE" "$PIPEWIRE_CONFIG_DIR/pipewire.conf" \
        "rate" "$RATE" \
        "quantum" "$QUANTUM_SIZE" \
        "min_quantum" "$MIN_QUANTUM" \
        "max_quantum" "$MAX_QUANTUM"
    
    # Generate WirePlumber configuration
    mkdir -p "$WIREPLUMBER_CONFIG_DIR/main.lua.d"
    generate_config "$WIREPLUMBER_CONFIG_TEMPLATE" "$WIREPLUMBER_CONFIG_DIR/main.lua.d/99-xanados-lowlatency.lua" \
        "quantum" "$QUANTUM_SIZE"
    
    print_success "Audio configuration optimized"
}

restart_audio_services() {
    print_info "Restarting audio services..."
    
    # Stop services
    systemctl --user stop pipewire pipewire-pulse wireplumber 2>/dev/null || true
    
    # Wait a moment
    sleep 2
    
    # Start services
    systemctl --user start pipewire pipewire-pulse wireplumber
    
    # Wait for services to stabilize
    sleep 3
    
    if systemctl --user is-active pipewire &>/dev/null; then
        print_success "Audio services restarted successfully"
    else
        print_error "Failed to restart audio services"
        return 1
    fi
}

apply_realtime_settings() {
    print_info "Applying real-time audio settings..."
    
    # Add user to audio group
    if ! groups "$USER" | grep -q audio; then
        sudo usermod -a -G audio "$USER"
        print_info "Added user to audio group (requires logout/login)"
    fi
    
    # Configure audio limits
    local limits_file="/etc/security/limits.d/99-xanados-audio.conf"
    if [[ ! -f "$limits_file" ]]; then
        sudo tee "$limits_file" >/dev/null << EOF
# xanadOS Audio Real-time Configuration
@audio   -  rtprio     95
@audio   -  memlock    unlimited
@audio   -  nice       -19
EOF
        print_success "Real-time audio limits configured"
    fi
}

# ============================================================================
# Main Functions
# ============================================================================
optimize_audio() {
    print_info "Starting audio optimization for low-latency gaming..."
    
    # Install required packages
    install_audio_packages
    
    # Optimize configuration
    optimize_pipewire_config
    
    # Apply real-time settings
    apply_realtime_settings
    
    # Restart services
    restart_audio_services
    
    print_success "Audio optimization completed successfully!"
    print_info "Current settings: ${QUANTUM_SIZE} samples @ ${RATE}Hz"
    print_info "Estimated latency: $((QUANTUM_SIZE * 1000 / RATE))ms"
}

check_status() {
    print_info "Checking audio optimization status..."
    
    local audio_system
    audio_system=$(detect_audio_system)
    
    echo "Audio System: $audio_system"
    
    # Check if optimized configs exist
    if [[ -f "$PIPEWIRE_CONFIG_DIR/pipewire.conf" ]]; then
        print_success "PipeWire configuration: Optimized"
    else
        print_warning "PipeWire configuration: Default"
    fi
    
    if [[ -f "$WIREPLUMBER_CONFIG_DIR/main.lua.d/99-xanados-lowlatency.lua" ]]; then
        print_success "WirePlumber configuration: Optimized"
    else
        print_warning "WirePlumber configuration: Default"
    fi
    
    # Check services
    check_installation_status \
        "PipeWire" "systemctl --user is-active pipewire" \
        "PipeWire-Pulse" "systemctl --user is-active pipewire-pulse" \
        "WirePlumber" "systemctl --user is-active wireplumber"
    
    # Check current settings
    if command -v pw-top &>/dev/null; then
        print_info "Current PipeWire status:"
        timeout 3 pw-top -b || print_warning "Could not get PipeWire status"
    fi
}

restore_defaults() {
    print_info "Restoring default audio settings..."
    
    # Find latest backup
    local backup_file="$HOME/.config/xanados/audio-backup-latest"
    if [[ -f "$backup_file" ]]; then
        local backup_dir
        backup_dir=$(cat "$backup_file")
        
        if [[ -d "$backup_dir" ]]; then
            print_info "Restoring from backup: $backup_dir"
            
            # Restore configs
            [[ -d "$backup_dir/pipewire" ]] && cp -r "$backup_dir/pipewire/"* "$PIPEWIRE_CONFIG_DIR/" 2>/dev/null || true
            [[ -d "$backup_dir/wireplumber" ]] && cp -r "$backup_dir/wireplumber/"* "$WIREPLUMBER_CONFIG_DIR/" 2>/dev/null || true
            
            restart_audio_services
            print_success "Default settings restored"
        else
            print_error "Backup directory not found: $backup_dir"
        fi
    else
        print_warning "No backup found, removing optimization configs..."
        rm -f "$PIPEWIRE_CONFIG_DIR/pipewire.conf"
        rm -f "$WIREPLUMBER_CONFIG_DIR/main.lua.d/99-xanados-lowlatency.lua"
        restart_audio_services
        print_success "Optimization configs removed"
    fi
}

remove_optimizations() {
    print_info "Removing all audio optimizations..."
    
    # Remove config files
    rm -f "$PIPEWIRE_CONFIG_DIR/pipewire.conf"
    rm -f "$WIREPLUMBER_CONFIG_DIR/main.lua.d/99-xanados-lowlatency.lua"
    
    # Remove limits file
    sudo rm -f "/etc/security/limits.d/99-xanados-audio.conf"
    
    restart_audio_services
    print_success "All optimizations removed"
}

show_usage() {
    cat << 'EOF'
xanadOS Audio Latency Optimization

USAGE:
    audio-latency-optimizer.sh [COMMAND]

COMMANDS:
    optimize    Optimize audio for low-latency gaming (default)
    status      Check current audio optimization status  
    restore     Restore default audio settings
    remove      Remove all optimizations
    help        Show this help message

EXAMPLES:
    audio-latency-optimizer.sh optimize
    audio-latency-optimizer.sh status
    audio-latency-optimizer.sh restore

EOF
}

# ============================================================================
# Main Function
# ============================================================================
main() {
    local action="${1:-optimize}"
    
    # Initialize script
    standard_script_init "$SCRIPT_NAME" "$SCRIPT_TITLE" "$SCRIPT_SUBTITLE" "$SCRIPT_ICON"
    
    case "$action" in
        "optimize"|"install"|"")
            optimize_audio
            ;;
        "status"|"check")
            check_status
            ;;
        "restore"|"reset")
            restore_defaults
            ;;
        "remove"|"uninstall")
            remove_optimizations
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
