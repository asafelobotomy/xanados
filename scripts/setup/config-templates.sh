#!/bin/bash
# ============================================================================
# xanadOS Configuration Template System
# 
# Description: Centralized template system for generating configuration files
# Version: 1.0.0
# Author: xanadOS Team
# 
# Features:
# - Template-based configuration generation
# - Variable substitution system
# - Hardware-specific adaptations
# - Gaming profile templates
# - Desktop environment configurations
# ============================================================================

set -euo pipefail

# Source shared setup library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/setup-common.sh" || {
    echo "Error: Could not source setup-common library"
    exit 1
}

# Template system configuration
readonly TEMPLATE_DIR="$SCRIPT_DIR/../templates"
readonly GENERATED_DIR="$HOME/.config/xanados/generated"
readonly CACHE_DIR="$HOME/.cache/xanados"

# Create necessary directories
mkdir -p "$TEMPLATE_DIR" "$GENERATED_DIR" "$CACHE_DIR"

# Initialize logging
setup_standard_logging "config-templates"

# ============================================================================
# Template Engine Functions
# ============================================================================

# Template variable substitution engine
substitute_template_variables() {
    local template_file="$1"
    local output_file="$2"
    local -A variables=()
    
    # Load variables from arguments (format: key=value)
    shift 2
    for arg in "$@"; do
        if [[ "$arg" == *"="* ]]; then
            local key="${arg%%=*}"
            local value="${arg#*=}"
            variables["$key"]="$value"
        fi
    done
    
    log_info "Processing template: $(basename "$template_file")"
    
    # Read template content
    local content
    content=$(cat "$template_file")
    
    # Substitute variables
    for key in "${!variables[@]}"; do
        local placeholder="{{${key}}}"
        content="${content//$placeholder/${variables[$key]}}"
    done
    
    # Write output
    echo "$content" > "$output_file"
    log_success "Template processed: $output_file"
}

# Generate audio configuration template
generate_audio_template() {
    local output_file="$1"
    local sample_rate="${2:-48000}"
    local buffer_size="${3:-256}"
    local periods="${4:-2}"
    
    cat > "$output_file" << EOF
# xanadOS Gaming Audio Configuration
# Generated: $(date)
# Hardware: $(get_audio_hardware_info)

[audio.pipewire]
default.clock.rate = $sample_rate
default.clock.quantum = $buffer_size
default.clock.min-quantum = 32
default.clock.max-quantum = 8192

[audio.alsa]
alsa.pcm.card = 0
alsa.pcm.device = 0
alsa.period-size = $buffer_size
alsa.periods = $periods

[gaming.optimizations]
enable-low-latency = true
disable-power-saving = true
prioritize-audio-threads = true
EOF
    
    log_success "Audio template generated: $output_file"
}

# Generate graphics configuration template
generate_graphics_template() {
    local output_file="$1"
    local gpu_vendor="$2"
    local enable_vsync="${3:-false}"
    local force_composition="${4:-false}"
    
    cat > "$output_file" << EOF
# xanadOS Gaming Graphics Configuration
# Generated: $(date)
# GPU Vendor: $gpu_vendor
# Hardware: $(get_gpu_hardware_info)

[graphics.general]
gpu_vendor = "$gpu_vendor"
enable_vsync = $enable_vsync
force_composition_pipeline = $force_composition

[graphics.nvidia]
# NVIDIA-specific settings (only used if gpu_vendor = "nvidia")
coolbits = 28
force_full_composition_pipeline = $force_composition
power_mizer_mode = 1

[graphics.amd]
# AMD-specific settings (only used if gpu_vendor = "amd")
radv_perftest = aco,llvm
amd_vulkan_icd = RADV
mesa_vulkan_device_select = $(get_gpu_pci_id)

[graphics.intel]
# Intel-specific settings (only used if gpu_vendor = "intel")
intel_vulkan_icd = ANV
mesa_loader_driver_override = iris

[gaming.environment]
# Gaming-specific graphics environment variables
DXVK_HUD = fps,memory,gpuload
MANGOHUD = 1
PROTON_USE_WINED3D = 0
EOF
    
    log_success "Graphics template generated: $output_file"
}

# Generate gaming profile template
generate_gaming_profile_template() {
    local output_file="$1"
    local profile_name="$2"
    local cpu_governor="${3:-performance}"
    local io_scheduler="${4:-mq-deadline}"
    
    cat > "$output_file" << EOF
# xanadOS Gaming Profile: $profile_name
# Generated: $(date)
# Hardware Profile: $(get_hardware_profile_name)

[profile.info]
name = "$profile_name"
created = "$(date -Iseconds)"
hardware_hash = "$(get_hardware_hash)"

[system.performance]
cpu_governor = "$cpu_governor"
io_scheduler = "$io_scheduler"
swappiness = 10
dirty_ratio = 15
transparent_hugepages = "madvise"

[gaming.environment]
# Game launcher optimizations
STEAM_COMPAT_CLIENT_INSTALL_PATH = "/home/$USER/.steam"
LUTRIS_SKIP_INIT = 0
GAMEMODE_ENABLE = 1

# Performance monitoring
MANGOHUD_CONFIG = "fps,frametime,cpu_temp,gpu_temp"
DXVK_HUD = "fps,memory"

[networking.gaming]
# Gaming network optimizations
tcp_congestion_control = "bbr"
net_core_rmem_max = 16777216
net_core_wmem_max = 16777216
EOF
    
    log_success "Gaming profile template generated: $output_file"
}

# Generate KDE customization template
generate_kde_template() {
    local output_file="$1"
    local theme_name="${2:-xanadOS-Gaming}"
    local panel_position="${3:-bottom}"
    local enable_effects="${4:-true}"
    
    cat > "$output_file" << EOF
# xanadOS KDE Plasma Gaming Customization
# Generated: $(date)
# Desktop Session: $(get_desktop_session_info)

[desktop.theme]
theme_name = "$theme_name"
color_scheme = "xanadOS-Dark"
icon_theme = "Papirus-Dark"
cursor_theme = "Breeze"

[desktop.layout]
panel_position = "$panel_position"
panel_height = 44
enable_desktop_effects = $enable_effects
animation_speed = 3

[gaming.taskbar]
# Gaming-specific taskbar widgets
show_system_monitor = true
show_performance_monitor = true
show_network_monitor = false

[gaming.shortcuts]
# Gaming keyboard shortcuts
launch_steam = "Meta+G"
launch_lutris = "Meta+L"
toggle_gamemode = "Meta+Shift+G"
show_mangohud = "Meta+H"

[performance.settings]
# Performance-oriented KDE settings
disable_baloo_indexing = true
disable_desktop_search = false
reduce_animations = false
disable_thumbnails = false
EOF
    
    log_success "KDE template generated: $output_file"
}

# ============================================================================
# Hardware Detection for Templates
# ============================================================================

get_audio_hardware_info() {
    if command -v pactl >/dev/null 2>&1; then
        pactl info 2>/dev/null | grep "Default Sink" | cut -d: -f2 | xargs || echo "Unknown"
    else
        echo "Unknown"
    fi
}

get_gpu_hardware_info() {
    if command -v lspci >/dev/null 2>&1; then
        lspci | grep -i vga | head -1 | cut -d: -f3 | xargs || echo "Unknown"
    else
        echo "Unknown"
    fi
}

get_gpu_pci_id() {
    if command -v lspci >/dev/null 2>&1; then
        lspci -nn | grep -i vga | head -1 | grep -o '\[.*\]' | tr -d '[]' || echo "0000:0000"
    else
        echo "0000:0000"
    fi
}

get_hardware_profile_name() {
    local cpu_info
    local gpu_info
    cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs | cut -d' ' -f1-3)
    gpu_info=$(get_gpu_hardware_info | cut -d' ' -f1-2)
    echo "${cpu_info:-Unknown}-${gpu_info:-Unknown}"
}

get_hardware_hash() {
    local hardware_string
    hardware_string="$(uname -m)-$(get_hardware_profile_name)-$(free -m | awk '/^Mem:/ {print $2}')"
    echo "$hardware_string" | sha256sum | cut -d' ' -f1 | head -c 16
}

get_desktop_session_info() {
    echo "${XDG_CURRENT_DESKTOP:-Unknown} / ${DESKTOP_SESSION:-Unknown}"
}

# ============================================================================
# Template Management Functions
# ============================================================================

create_template_set() {
    local profile_name="$1"
    local base_dir="$GENERATED_DIR/$profile_name"
    
    log_info "Creating template set: $profile_name"
    mkdir -p "$base_dir"
    
    # Detect hardware for intelligent defaults
    cache_hardware_info
    local gpu_vendor
    gpu_vendor=$(detect_gpu_vendor)
    
    # Generate all templates
    generate_audio_template "$base_dir/audio.conf"
    generate_graphics_template "$base_dir/graphics.conf" "$gpu_vendor"
    generate_gaming_profile_template "$base_dir/gaming-profile.conf" "$profile_name"
    generate_kde_template "$base_dir/kde-customization.conf"
    
    # Create index file
    cat > "$base_dir/index.conf" << EOF
# xanadOS Configuration Template Set
# Profile: $profile_name
# Generated: $(date)

[template.set]
name = "$profile_name"
version = "1.0.0"
created = "$(date -Iseconds)"

[files]
audio = "audio.conf"
graphics = "graphics.conf"
gaming_profile = "gaming-profile.conf"
kde_customization = "kde-customization.conf"

[hardware.detected]
cpu = "$(get_cpu_info)"
gpu = "$(get_gpu_info)"
memory = "$(get_memory_info)"
profile_hash = "$(get_hardware_hash)"
EOF
    
    log_success "Template set created: $base_dir"
}

list_template_sets() {
    log_info "Available template sets:"
    echo
    
    if [[ ! -d "$GENERATED_DIR" ]] || [[ -z "$(ls -A "$GENERATED_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}No template sets found${NC}"
        return 0
    fi
    
    for template_dir in "$GENERATED_DIR"/*; do
        if [[ -d "$template_dir" ]]; then
            local profile_name
            profile_name=$(basename "$template_dir")
            local index_file="$template_dir/index.conf"
            
            echo -e "${GREEN}• $profile_name${NC}"
            
            if [[ -f "$index_file" ]]; then
                local created
                created=$(grep "created = " "$index_file" 2>/dev/null | cut -d'"' -f2 || echo "Unknown")
                echo -e "  ${GRAY}Created: $created${NC}"
                
                local files_count
                files_count=$(find "$template_dir" -name "*.conf" | wc -l)
                echo -e "  ${GRAY}Files: $files_count templates${NC}"
            fi
            echo
        fi
    done
}

apply_template_set() {
    local profile_name="$1"
    local template_dir="$GENERATED_DIR/$profile_name"
    
    if [[ ! -d "$template_dir" ]]; then
        log_error "Template set not found: $profile_name"
        return 1
    fi
    
    log_info "Applying template set: $profile_name"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY RUN] Would apply template set: $profile_name"
        return 0
    fi
    
    # Apply each template file
    for template_file in "$template_dir"/*.conf; do
        if [[ -f "$template_file" && "$(basename "$template_file")" != "index.conf" ]]; then
            local filename
            filename=$(basename "$template_file")
            local target_file="$HOME/.config/xanados/applied/$filename"
            
            mkdir -p "$(dirname "$target_file")"
            cp "$template_file" "$target_file"
            log_success "Applied template: $filename"
        fi
    done
    
    log_success "Template set applied successfully"
}

# ============================================================================
# Main Template Functions
# ============================================================================

show_help() {
    cat << 'EOF'
xanadOS Configuration Template System

USAGE:
    config-templates.sh [OPTIONS] [COMMAND]

COMMANDS:
    create PROFILE     Create a new template set with hardware detection
    list               List available template sets
    apply PROFILE      Apply a template set to the system
    generate TYPE      Generate individual template (audio|graphics|gaming|kde)
    clean              Clean old templates and cache

OPTIONS:
    -h, --help         Show this help message
    -v, --verbose      Enable verbose output
    -q, --quiet        Suppress non-error output
    --dry-run          Show what would be done without executing

EXAMPLES:
    config-templates.sh create my-gaming-rig
    config-templates.sh list
    config-templates.sh apply my-gaming-rig
    config-templates.sh generate audio

EOF
}

main() {
    # Parse command line arguments
    parse_common_args "$@"
    
    # Handle help
    if [[ "${SHOW_HELP:-false}" == "true" ]]; then
        show_help
        exit 0
    fi
    
    # Get command
    local command="${1:-list}"
    shift 2>/dev/null || true
    
    case "$command" in
        create)
            local profile_name="${1:-default-gaming-$(date +%Y%m%d)}"
            print_standard_banner "Template Creation" "1.0.0"
            create_template_set "$profile_name"
            ;;
        list)
            print_standard_banner "Template Management" "1.0.0"
            list_template_sets
            ;;
        apply)
            local profile_name="${1:-}"
            if [[ -z "$profile_name" ]]; then
                log_error "Profile name required for apply command"
                exit 1
            fi
            print_standard_banner "Template Application" "1.0.0"
            apply_template_set "$profile_name"
            ;;
        generate)
            local template_type="${1:-gaming}"
            print_standard_banner "Template Generation" "1.0.0"
            case "$template_type" in
                audio)
                    generate_audio_template "$GENERATED_DIR/audio-$(date +%Y%m%d).conf"
                    ;;
                graphics)
                    local gpu_vendor
                    gpu_vendor=$(detect_gpu_vendor)
                    generate_graphics_template "$GENERATED_DIR/graphics-$(date +%Y%m%d).conf" "$gpu_vendor"
                    ;;
                gaming)
                    generate_gaming_profile_template "$GENERATED_DIR/gaming-$(date +%Y%m%d).conf" "custom-gaming"
                    ;;
                kde)
                    generate_kde_template "$GENERATED_DIR/kde-$(date +%Y%m%d).conf"
                    ;;
                *)
                    log_error "Unknown template type: $template_type"
                    exit 1
                    ;;
            esac
            ;;
        clean)
            print_standard_banner "Template Cleanup" "1.0.0"
            log_info "Cleaning old templates and cache"
            find "$GENERATED_DIR" -name "*.conf" -mtime +30 -delete 2>/dev/null || true
            find "$CACHE_DIR" -name "*" -mtime +7 -delete 2>/dev/null || true
            log_success "Template cleanup completed"
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
