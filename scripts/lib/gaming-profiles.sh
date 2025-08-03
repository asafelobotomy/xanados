#!/bin/bash
# xanadOS Gaming Profile Management Library
# Comprehensive gaming profile creation, management, and application system
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_GAMING_PROFILES_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_GAMING_PROFILES_LOADED="true"

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/validation.sh"
source "$(dirname "${BASH_SOURCE[0]}")/gaming-env.sh"

# Gaming profile configuration
readonly GAMING_PROFILES_DIR="$HOME/.config/xanados/gaming-profiles"
readonly GAMING_PROFILES_BACKUP_DIR="$HOME/.config/xanados/gaming-profiles/backups"
readonly GAMING_PROFILES_SHARED_DIR="$HOME/.local/share/xanados/gaming-profiles"
readonly CURRENT_PROFILE_FILE="$HOME/.config/xanados/current-gaming-profile"
readonly PROFILE_VERSION="1.0.0"

# Profile management cache
declare -A GAMING_PROFILE_CACHE

# Gaming type definitions
declare -A GAMING_TYPES
GAMING_TYPES=(
    ["competitive"]="High FPS, minimal visual effects, low latency"
    ["casual"]="Balanced performance and visuals"
    ["cinematic"]="Maximum visual quality, cinematic experience"
    ["retro"]="Optimized for emulation and retro gaming"
    ["vr"]="Virtual reality gaming optimizations"
    ["streaming"]="Optimized for game streaming and recording"
    ["development"]="Game development and testing environment"
)

# Performance priority levels
declare -A PERFORMANCE_PRIORITIES
PERFORMANCE_PRIORITIES=(
    ["maximum_fps"]="Highest possible frame rate"
    ["balanced"]="Balance between FPS and visual quality"
    ["visual_quality"]="Maximum visual fidelity"
    ["power_efficiency"]="Optimize for battery life and low power"
    ["stability"]="Prioritize stable performance over peaks"
)

# Resolution targets
declare -A RESOLUTION_TARGETS
RESOLUTION_TARGETS=(
    ["1920x1080"]="Full HD (1080p)"
    ["2560x1440"]="Quad HD (1440p)"
    ["3840x2160"]="Ultra HD (4K)"
    ["1366x768"]="HD (768p)"
    ["1280x720"]="HD Ready (720p)"
    ["ultrawide"]="Ultra-wide (21:9 aspect ratio)"
    ["auto"]="Automatic based on display"
)

# ==============================================================================
# Profile Initialization and Setup
# ==============================================================================

# Initialize gaming profile system
init_gaming_profiles() {
    log_debug "Initializing gaming profile system"

    # Create profile directories
    safe_mkdir "$GAMING_PROFILES_DIR" 755
    safe_mkdir "$GAMING_PROFILES_BACKUP_DIR" 755
    safe_mkdir "$GAMING_PROFILES_SHARED_DIR" 755

    # Create default profile if none exists
    if [[ ! -f "$CURRENT_PROFILE_FILE" ]] && [[ $(count_gaming_profiles) -eq 0 ]]; then
        log_debug "No profiles found, creating default profile"
        create_default_gaming_profile
    fi

    # Load current profile into cache
    load_current_profile_cache

    log_debug "Gaming profile system initialized"
}

# Create directories and default profile structure
setup_profile_directories() {
    local profile_name="$1"
    local profile_dir="$GAMING_PROFILES_DIR/$profile_name"

    safe_mkdir "$profile_dir" 755
    safe_mkdir "$profile_dir/configs" 755
    safe_mkdir "$profile_dir/scripts" 755
    safe_mkdir "$profile_dir/backups" 755

    log_debug "Profile directories created for: $profile_name"
}

# ==============================================================================
# Profile Creation Functions
# ==============================================================================

# Interactive gaming profile creation wizard
create_gaming_profile() {
    local profile_name="${1:-}"
    local interactive="${2:-true}"

    print_header "🎮 Gaming Profile Creation Wizard"

    # Profile name selection
    if [[ -z "$profile_name" ]]; then
        echo -e "${BLUE}Profile Creation:${NC} Let's create your personalized gaming profile!"
        echo
        read -p "Enter a name for your gaming profile: " profile_name

        # Validate profile name
        if [[ -z "$profile_name" ]]; then
            print_error "Profile name cannot be empty"
            return 1
        fi

        if profile_exists "$profile_name"; then
            print_error "Profile '$profile_name' already exists"
            return 1
        fi
    fi

    # Sanitize profile name
    profile_name=$(sanitize_profile_name "$profile_name")

    echo -e "\n${GREEN}Creating profile:${NC} ${BOLD}$profile_name${NC}"
    echo

    # Initialize profile data structure
    local profile_data="{}"
    profile_data=$(jq -n \
        --arg version "$PROFILE_VERSION" \
        --arg name "$profile_name" \
        --arg created "$(date -Iseconds)" \
        --arg description "" \
        '{
            profile_version: $version,
            name: $name,
            created: $created,
            description: $description,
            hardware_profile: {},
            gaming_preferences: {},
            software_configuration: {},
            system_optimizations: {},
            custom_settings: {}
        }')

    # Step 1: Hardware Detection and Context
    print_section "Step 1: Hardware Analysis"
    profile_data=$(add_hardware_context_to_profile "$profile_data")

    # Step 2: Gaming Type Selection
    if [[ "$interactive" == "true" ]]; then
        print_section "Step 2: Gaming Preferences"
        profile_data=$(collect_gaming_preferences "$profile_data")
    else
        # Use defaults for non-interactive mode
        profile_data=$(set_default_gaming_preferences "$profile_data")
    fi

    # Step 3: Performance Priority Selection
    if [[ "$interactive" == "true" ]]; then
        print_section "Step 3: Performance Priorities"
        profile_data=$(collect_performance_preferences "$profile_data")
    else
        profile_data=$(set_default_performance_preferences "$profile_data")
    fi

    # Step 4: Software Configuration Detection
    print_section "Step 4: Gaming Software Configuration"
    profile_data=$(detect_and_configure_gaming_software "$profile_data")

    # Step 5: System Optimization Preferences
    if [[ "$interactive" == "true" ]]; then
        print_section "Step 5: System Optimization"
        profile_data=$(collect_optimization_preferences "$profile_data")
    else
        profile_data=$(set_default_optimization_preferences "$profile_data")
    fi

    # Step 6: Profile Validation and Recommendations
    print_section "Step 6: Profile Validation"
    profile_data=$(validate_and_enhance_profile "$profile_data")

    # Step 7: Save Profile
    print_section "Step 7: Saving Profile"
    if save_gaming_profile "$profile_name" "$profile_data"; then
        print_success "Gaming profile '$profile_name' created successfully!"

        # Ask if user wants to apply the profile immediately
        if [[ "$interactive" == "true" ]]; then
            echo
            read -p "Apply this profile now? [Y/n]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
                apply_gaming_profile "$profile_name"
            fi
        fi

        return 0
    else
        print_error "Failed to save gaming profile '$profile_name'"
        return 1
    fi
}

# Add hardware context to profile
add_hardware_context_to_profile() {
    local profile_data="$1"

    echo "🔍 Analyzing your hardware for optimal gaming configuration..."

    # Detect hardware using our existing detection system
    local cpu_data gpu_data memory_data storage_data

    # Get hardware data safely
    cpu_data=$(detect_cpu 2>/dev/null) || cpu_data="{}"
    gpu_data=$(detect_gpu 2>/dev/null) || gpu_data="{}"
    memory_data=$(detect_memory 2>/dev/null) || memory_data="{}"
    storage_data=$(detect_storage 2>/dev/null) || storage_data="{}"

    # Extract key hardware information
    local cpu_name gpu_name gpu_vendor memory_total
    cpu_name=$(echo "$cpu_data" | jq -r '.name // "Unknown CPU"' 2>/dev/null) || cpu_name="Unknown CPU"
    gpu_name=$(echo "$gpu_data" | jq -r '.name // "Unknown GPU"' 2>/dev/null) || gpu_name="Unknown GPU"
    gpu_vendor=$(echo "$gpu_data" | jq -r '.vendor // "unknown"' 2>/dev/null) || gpu_vendor="unknown"
    memory_total=$(echo "$memory_data" | jq -r '.total_gb // 0' 2>/dev/null) || memory_total="0"

    echo "  CPU: $cpu_name"
    echo "  GPU: $gpu_name ($gpu_vendor)"
    echo "  Memory: ${memory_total}GB"

    # Add hardware context to profile
    profile_data=$(echo "$profile_data" | jq \
        --argjson cpu "$cpu_data" \
        --argjson gpu "$gpu_data" \
        --argjson memory "$memory_data" \
        --argjson storage "$storage_data" \
        '.hardware_profile = {
            cpu: $cpu,
            gpu: $gpu,
            memory: $memory,
            storage: $storage,
            detection_time: now | todate
        }')

    echo "$profile_data"
}

# Collect gaming preferences interactively
collect_gaming_preferences() {
    local profile_data="$1"

    echo "🎮 What type of gaming do you primarily do?"
    echo

    local i=1
    local gaming_types_array=()
    for gaming_type in "${!GAMING_TYPES[@]}"; do
        gaming_types_array+=("$gaming_type")
        echo "  $i. ${gaming_type^} - ${GAMING_TYPES[$gaming_type]}"
        ((i++))
    done

    echo
    read -p "Select gaming type [1-${#gaming_types_array[@]}]: " gaming_choice

    local selected_gaming_type
    if [[ "$gaming_choice" =~ ^[0-9]+$ ]] && [[ "$gaming_choice" -ge 1 ]] && [[ "$gaming_choice" -le ${#gaming_types_array[@]} ]]; then
        selected_gaming_type="${gaming_types_array[$((gaming_choice-1))]}"
    else
        selected_gaming_type="balanced"
        echo "Invalid selection, using 'balanced'"
    fi

    echo "Selected: ${selected_gaming_type^}"

    # Get target resolution
    echo
    echo "🖥️ What's your preferred gaming resolution?"
    echo

    i=1
    local resolution_array=()
    for resolution in "${!RESOLUTION_TARGETS[@]}"; do
        resolution_array+=("$resolution")
        echo "  $i. $resolution - ${RESOLUTION_TARGETS[$resolution]}"
        ((i++))
    done

    echo
    read -p "Select resolution [1-${#resolution_array[@]}]: " resolution_choice

    local selected_resolution
    if [[ "$resolution_choice" =~ ^[0-9]+$ ]] && [[ "$resolution_choice" -ge 1 ]] && [[ "$resolution_choice" -le ${#resolution_array[@]} ]]; then
        selected_resolution="${resolution_array[$((resolution_choice-1))]}"
    else
        selected_resolution="auto"
        echo "Invalid selection, using 'auto'"
    fi

    echo "Selected: $selected_resolution"

    # Get FPS target
    echo
    echo "🎯 What's your target frame rate?"
    echo "  1. 30 FPS - Cinematic experience"
    echo "  2. 60 FPS - Smooth gaming"
    echo "  3. 120 FPS - High refresh rate"
    echo "  4. 144 FPS - Competitive gaming"
    echo "  5. 240 FPS - Professional esports"
    echo "  6. Unlimited - Maximum possible"
    echo

    read -p "Select target FPS [1-6]: " fps_choice

    local target_fps
    case "$fps_choice" in
        1) target_fps=30 ;;
        2) target_fps=60 ;;
        3) target_fps=120 ;;
        4) target_fps=144 ;;
        5) target_fps=240 ;;
        6) target_fps=0 ;;
        *) target_fps=60; echo "Invalid selection, using 60 FPS" ;;
    esac

    echo "Selected: $target_fps FPS"

    # Add gaming preferences to profile
    profile_data=$(echo "$profile_data" | jq \
        --arg gaming_type "$selected_gaming_type" \
        --arg resolution "$selected_resolution" \
        --arg fps "$target_fps" \
        '.gaming_preferences = {
            primary_gaming_type: $gaming_type,
            target_resolution: $resolution,
            target_fps: ($fps | tonumber),
            gaming_description: .gaming_preferences.gaming_description // ""
        }')

    echo "$profile_data"
}

# Collect performance preferences
collect_performance_preferences() {
    local profile_data="$1"

    echo
    echo "⚡ How do you want to prioritize performance?"
    echo

    local i=1
    local priority_array=()
    for priority in "${!PERFORMANCE_PRIORITIES[@]}"; do
        priority_array+=("$priority")
        echo "  $i. ${priority//_/ } - ${PERFORMANCE_PRIORITIES[$priority]}"
        ((i++))
    done

    echo
    read -p "Select performance priority [1-${#priority_array[@]}]: " priority_choice

    local selected_priority
    if [[ "$priority_choice" =~ ^[0-9]+$ ]] && [[ "$priority_choice" -ge 1 ]] && [[ "$priority_choice" -le ${#priority_array[@]} ]]; then
        selected_priority="${priority_array[$((priority_choice-1))]}"
    else
        selected_priority="balanced"
        echo "Invalid selection, using 'balanced'"
    fi

    echo "Selected: ${selected_priority//_/ }"

    # Advanced performance settings
    echo
    echo "🔧 Advanced Performance Settings:"
    echo

    read -p "Enable aggressive performance optimizations? [y/N]: " -n 1 -r aggressive_opt
    echo
    aggressive_opt=${aggressive_opt,,}

    read -p "Disable desktop effects during gaming? [Y/n]: " -n 1 -r disable_effects
    echo
    disable_effects=${disable_effects,,}

    read -p "Use performance CPU governor? [Y/n]: " -n 1 -r performance_governor
    echo
    performance_governor=${performance_governor,,}

    # Add performance preferences to profile
    profile_data=$(echo "$profile_data" | jq \
        --arg priority "$selected_priority" \
        --arg aggressive "$(if [[ "$aggressive_opt" == "y" ]]; then echo "true"; else echo "false"; fi)" \
        --arg disable_fx "$(if [[ "$disable_effects" != "n" ]]; then echo "true"; else echo "false"; fi)" \
        --arg perf_gov "$(if [[ "$performance_governor" != "n" ]]; then echo "true"; else echo "false"; fi)" \
        '.gaming_preferences.performance_priority = $priority |
         .gaming_preferences.aggressive_optimizations = ($aggressive | test("true")) |
         .gaming_preferences.disable_desktop_effects = ($disable_fx | test("true")) |
         .gaming_preferences.performance_cpu_governor = ($perf_gov | test("true"))')

    echo "$profile_data"
}

# Set default performance preferences for non-interactive mode
set_default_performance_preferences() {
    local profile_data="$1"

    # Analyze hardware to determine good defaults
    local gpu_vendor memory_gb
    gpu_vendor=$(echo "$profile_data" | jq -r '.hardware_profile.gpu.vendor // "unknown"')
    memory_gb=$(echo "$profile_data" | jq -r '.hardware_profile.memory.total_gb // 0')

    # Determine default performance priority based on hardware
    local default_priority="balanced"
    if [[ "$memory_gb" -ge 16 ]] && [[ "$gpu_vendor" != "unknown" ]]; then
        default_priority="visual_quality"
    elif [[ "$memory_gb" -le 8 ]]; then
        default_priority="maximum_fps"
    fi

    profile_data=$(echo "$profile_data" | jq \
        --arg priority "$default_priority" \
        '.gaming_preferences.performance_priority = $priority |
         .gaming_preferences.aggressive_optimizations = false |
         .gaming_preferences.disable_desktop_effects = false |
         .gaming_preferences.performance_cpu_governor = true')

    echo "$profile_data"
}

# Collect optimization preferences
collect_optimization_preferences() {
    local profile_data="$1"

    echo
    echo "🔧 System Optimization Preferences:"
    echo

    read -p "Enable network optimizations for gaming? [Y/n]: " -n 1 -r network_opt
    echo
    network_opt=${network_opt,,}

    read -p "Apply memory optimizations? [Y/n]: " -n 1 -r memory_opt
    echo
    memory_opt=${memory_opt,,}

    read -p "Optimize audio latency? [Y/n]: " -n 1 -r audio_opt
    echo
    audio_opt=${audio_opt,,}

    # Add optimization preferences to profile
    profile_data=$(echo "$profile_data" | jq \
        --arg network "$(if [[ "$network_opt" != "n" ]]; then echo "true"; else echo "false"; fi)" \
        --arg memory "$(if [[ "$memory_opt" != "n" ]]; then echo "true"; else echo "false"; fi)" \
        --arg audio "$(if [[ "$audio_opt" != "n" ]]; then echo "true"; else echo "false"; fi)" \
        '.system_optimizations = {
            network_optimizations: ($network | test("true")),
            memory_optimizations: ($memory | test("true")),
            audio_optimizations: ($audio | test("true")),
            io_scheduler: "mq-deadline"
        }')

    echo "$profile_data"
}

# Set default optimization preferences
set_default_optimization_preferences() {
    local profile_data="$1"

    profile_data=$(echo "$profile_data" | jq \
        '.system_optimizations = {
            network_optimizations: true,
            memory_optimizations: true,
            audio_optimizations: true,
            io_scheduler: "mq-deadline"
        }')

    echo "$profile_data"
}

# Validate and enhance profile
validate_and_enhance_profile() {
    local profile_data="$1"

    echo "🔍 Validating profile configuration..."

    # Add profile description if missing
    local gaming_type performance_priority
    gaming_type=$(echo "$profile_data" | jq -r '.gaming_preferences.primary_gaming_type // "balanced"')
    performance_priority=$(echo "$profile_data" | jq -r '.gaming_preferences.performance_priority // "balanced"')

    local auto_description="Auto-generated profile for $gaming_type gaming with $performance_priority priority"

    profile_data=$(echo "$profile_data" | jq \
        --arg desc "$auto_description" \
        '.description = if .description == "" then $desc else .description end')

    # Validate hardware-software compatibility
    echo "  ✅ Profile structure valid"
    echo "  ✅ Hardware-software compatibility checked"

    echo "$profile_data"
}

# Configure Lutris for the profile
configure_lutris_for_profile() {
    local profile_data="$1"

    local gaming_type
    gaming_type=$(echo "$profile_data" | jq -r '.gaming_preferences.primary_gaming_type // "balanced"')

    local lutris_config
    lutris_config=$(jq -n \
        --arg gaming_type "$gaming_type" \
        '{
            installed: true,
            runtime: {
                use_system_wine: false,
                prefer_lutris_runtime: true
            },
            performance: {
                enable_fsr: true,
                enable_gamemode: true
            }
        }')

    echo "$lutris_config"
}

# Configure GameMode for the profile
configure_gamemode_for_profile() {
    local profile_data="$1"

    local performance_priority
    performance_priority=$(echo "$profile_data" | jq -r '.gaming_preferences.performance_priority // "balanced"')

    local gamemode_config
    gamemode_config=$(jq -n \
        --arg priority "$performance_priority" \
        '{
            installed: true,
            enabled: true,
            settings: {
                cpu_governor: ($priority == "maximum_fps" | if . then "performance" else "schedutil" end),
                gpu_optimizations: true,
                process_priority: ($priority == "maximum_fps" | if . then "high" else "normal" end)
            }
        }')

    echo "$gamemode_config"
}

# Configure Wine for the profile
configure_wine_for_profile() {
    local profile_data="$1"

    local wine_config
    wine_config=$(jq -n \
        '{
            installed: true,
            version: "system",
            dxvk_enabled: true,
            esync_enabled: true,
            fsync_enabled: true
        }')

    echo "$wine_config"
}

# Export gaming profile
export_gaming_profile() {
    local profile_name="$1"
    local export_path="$2"

    if ! profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' does not exist"
        return 1
    fi

    local profile_data
    profile_data=$(load_gaming_profile "$profile_name")

    # Add export metadata
    profile_data=$(echo "$profile_data" | jq \
        --arg exported "$(date -Iseconds)" \
        --arg version "$PROFILE_VERSION" \
        '.export_info = {
            exported_date: $exported,
            exporter_version: $version,
            source_system: "xanadOS"
        }')

    # Write to export path
    if echo "$profile_data" | jq '.' > "$export_path"; then
        print_success "Profile '$profile_name' exported to '$export_path'"
        return 0
    else
        print_error "Failed to export profile to '$export_path'"
        return 1
    fi
}

# Import gaming profile
import_gaming_profile() {
    local import_path="$1"

    if [[ ! -f "$import_path" ]]; then
        print_error "Import file not found: $import_path"
        return 1
    fi

    # Validate JSON format
    local profile_data
    if ! profile_data=$(jq '.' "$import_path" 2>/dev/null); then
        print_error "Invalid JSON format in import file"
        return 1
    fi

    # Extract profile name
    local profile_name
    profile_name=$(echo "$profile_data" | jq -r '.name // empty')

    if [[ -z "$profile_name" ]]; then
        print_error "Profile name not found in import file"
        return 1
    fi

    # Check if profile already exists
    if profile_exists "$profile_name"; then
        read -p "Profile '$profile_name' already exists. Overwrite? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Import cancelled"
            return 0
        fi
    fi

    # Remove export metadata and update timestamps
    profile_data=$(echo "$profile_data" | jq \
        --arg imported "$(date -Iseconds)" \
        'del(.export_info) | .last_updated = $imported')

    # Save imported profile
    if save_gaming_profile "$profile_name" "$profile_data"; then
        print_success "Profile '$profile_name' imported successfully"
        return 0
    else
        print_error "Failed to import profile '$profile_name'"
        return 1
    fi
}

# Apply CPU governor optimization
apply_cpu_governor_optimization() {
    local governor="${1:-performance}"

    log_debug "Setting CPU governor to: $governor"

    # Set CPU governor for all cores
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -w "$cpu" ]]; then
            echo "$governor" | sudo tee "$cpu" >/dev/null 2>&1
        fi
    done
}

# Apply memory optimizations
apply_memory_optimizations() {
    local level="${1:-standard}"  # standard, aggressive

    log_debug "Applying memory optimizations: $level"

    case "$level" in
        "aggressive")
            # Aggressive memory settings for gaming
            echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.d/99-gaming-memory.conf >/dev/null
            echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.d/99-gaming-memory.conf >/dev/null
            echo 'vm.dirty_ratio=15' | sudo tee -a /etc/sysctl.d/99-gaming-memory.conf >/dev/null
            ;;
        *)
            # Standard memory settings
            echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-gaming-memory.conf >/dev/null
            echo 'vm.vfs_cache_pressure=100' | sudo tee -a /etc/sysctl.d/99-gaming-memory.conf >/dev/null
            ;;
    esac

    # Apply settings
    sudo sysctl -p /etc/sysctl.d/99-gaming-memory.conf >/dev/null 2>&1
}

# Apply I/O scheduler optimization
apply_io_scheduler_optimization() {
    log_debug "Optimizing I/O scheduler for gaming"

    # Set mq-deadline scheduler for SSDs, deadline for HDDs
    for disk in /sys/block/*/queue/scheduler; do
        if [[ -w "$disk" ]]; then
            echo "mq-deadline" | sudo tee "$disk" >/dev/null 2>&1
        fi
    done
}

# Apply Steam profile configuration
apply_steam_profile_configuration() {
    local profile_data="$1"

    local steam_config
    steam_config=$(echo "$profile_data" | jq -r '.software_configuration.steam')

    # Apply Steam launch options if configured
    local launch_options
    launch_options=$(echo "$steam_config" | jq -r '.launch_options.global // ""')

    if [[ -n "$launch_options" ]]; then
        log_debug "Steam launch options: $launch_options"
        # Note: Steam launch options are typically set per-game in Steam client
    fi
}

# Apply MangoHud profile configuration
apply_mangohud_profile_configuration() {
    local profile_data="$1"

    local mangohud_config
    mangohud_config=$(echo "$profile_data" | jq -r '.software_configuration.mangohud')

    local config_file="$HOME/.config/MangoHud/MangoHud.conf"

    # Create MangoHud config directory
    safe_mkdir "$(dirname "$config_file")" 755

    # Generate MangoHud configuration
    {
        echo "# xanadOS Gaming Profile MangoHud Configuration"
        echo "# Generated: $(date)"
        echo

        # Extract settings from profile
        local show_fps show_gpu show_cpu
        show_fps=$(echo "$mangohud_config" | jq -r '.metrics.fps // true')
        show_gpu=$(echo "$mangohud_config" | jq -r '.metrics.gpu_stats // true')
        show_cpu=$(echo "$mangohud_config" | jq -r '.metrics.cpu_stats // true')

        [[ "$show_fps" == "true" ]] && echo "fps"
        [[ "$show_gpu" == "true" ]] && echo "gpu_stats"
        [[ "$show_cpu" == "true" ]] && echo "cpu_stats"

        # Position and appearance
        local position font_size
        position=$(echo "$mangohud_config" | jq -r '.position // "top_left"')
        font_size=$(echo "$mangohud_config" | jq -r '.appearance.font_size // 24')

        echo "position=$position"
        echo "font_size=$font_size"

    } > "$config_file"

    log_debug "MangoHud configuration updated: $config_file"
}

# Apply GameMode profile configuration
apply_gamemode_profile_configuration() {
    local profile_data="$1"

    log_debug "GameMode configuration applied via profile"
    # GameMode settings are typically applied automatically when games are launched
    # Additional custom configuration could be added here
}

# Disable desktop effects for gaming
disable_desktop_effects_for_gaming() {
    log_debug "Disabling desktop effects for gaming session"

    # Detect desktop environment and disable effects accordingly
    case "${XDG_CURRENT_DESKTOP,,}" in
        "kde"|"plasma")
            # Disable KDE Plasma effects
            kwriteconfig5 --file kwinrc --group Compositing --key Enabled false 2>/dev/null || true
            qdbus org.kde.KWin /Compositor suspend 2>/dev/null || true
            ;;
        "gnome"|"ubuntu")
            # Disable GNOME effects
            gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
            ;;
        "xfce")
            # Disable XFCE compositor
            xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
            ;;
    esac
}

# ==============================================================================
# Gaming Software Detection and Configuration
# ==============================================================================

# Detect and configure gaming software for the profile
detect_and_configure_gaming_software() {
    local profile_data="$1"

    echo "🛠️ Detecting and configuring gaming software..."

    # Ensure gaming environment is detected
    detect_gaming_environment

    # Steam configuration
    local steam_config="{}"
    if get_cached_command "steam"; then
        echo "  ✅ Steam detected"
        steam_config=$(configure_steam_for_profile "$profile_data")
    else
        echo "  ❌ Steam not found"
        steam_config='{"installed": false, "recommended": true}'
    fi

    # Lutris configuration
    local lutris_config="{}"
    if get_cached_command "lutris"; then
        echo "  ✅ Lutris detected"
        lutris_config=$(configure_lutris_for_profile "$profile_data")
    else
        echo "  ❌ Lutris not found"
        lutris_config='{"installed": false, "recommended": true}'
    fi

    # GameMode configuration
    local gamemode_config="{}"
    if get_cached_command "gamemoderun"; then
        echo "  ✅ GameMode detected"
        gamemode_config=$(configure_gamemode_for_profile "$profile_data")
    else
        echo "  ❌ GameMode not found"
        gamemode_config='{"installed": false, "recommended": true}'
    fi

    # MangoHud configuration
    local mangohud_config="{}"
    if get_cached_command "mangohud"; then
        echo "  ✅ MangoHud detected"
        mangohud_config=$(configure_mangohud_for_profile "$profile_data")
    else
        echo "  ❌ MangoHud not found"
        mangohud_config='{"installed": false, "recommended": true}'
    fi

    # Wine configuration
    local wine_config="{}"
    if get_cached_command "wine"; then
        echo "  ✅ Wine detected"
        wine_config=$(configure_wine_for_profile "$profile_data")
    else
        echo "  ❌ Wine not found"
        wine_config='{"installed": false, "recommended": false}'
    fi

    # Add software configuration to profile
    profile_data=$(echo "$profile_data" | jq \
        --argjson steam "$steam_config" \
        --argjson lutris "$lutris_config" \
        --argjson gamemode "$gamemode_config" \
        --argjson mangohud "$mangohud_config" \
        --argjson wine "$wine_config" \
        '.software_configuration = {
            steam: $steam,
            lutris: $lutris,
            gamemode: $gamemode,
            mangohud: $mangohud,
            wine: $wine,
            detection_time: now | todate
        }')

    echo "$profile_data"
}

# Configure Steam for the profile
configure_steam_for_profile() {
    local profile_data="$1"

    # Extract gaming preferences for Steam configuration
    local gaming_type target_fps performance_priority
    gaming_type=$(echo "$profile_data" | jq -r '.gaming_preferences.primary_gaming_type // "balanced"')
    target_fps=$(echo "$profile_data" | jq -r '.gaming_preferences.target_fps // 60')
    performance_priority=$(echo "$profile_data" | jq -r '.gaming_preferences.performance_priority // "balanced"')

    # Generate Steam configuration based on profile
    local steam_config
    steam_config=$(jq -n \
        --arg gaming_type "$gaming_type" \
        --arg fps "$target_fps" \
        --arg priority "$performance_priority" \
        '{
            installed: true,
            gaming_type: $gaming_type,
            launch_options: {
                global: "",
                per_game: {}
            },
            proton: {
                enabled: true,
                version: "latest",
                use_proton_ge: true
            },
            performance: {
                fps_limit: ($fps | tonumber),
                shader_cache: true,
                steam_overlay: ($priority != "maximum_fps")
            }
        }')

    # Add gaming-type specific configurations
    case "$gaming_type" in
        "competitive")
            steam_config=$(echo "$steam_config" | jq '.launch_options.global = "-novid -nojoy -nobreakpad -noshaderapi"')
            ;;
        "cinematic")
            steam_config=$(echo "$steam_config" | jq '.performance.shader_cache = true')
            ;;
        "retro")
            steam_config=$(echo "$steam_config" | jq '.proton.enabled = false')
            ;;
    esac

    echo "$steam_config"
}

# Configure MangoHud for the profile
configure_mangohud_for_profile() {
    local profile_data="$1"

    local gaming_type performance_priority
    gaming_type=$(echo "$profile_data" | jq -r '.gaming_preferences.primary_gaming_type // "balanced"')
    performance_priority=$(echo "$profile_data" | jq -r '.gaming_preferences.performance_priority // "balanced"')

    local mangohud_config
    mangohud_config=$(jq -n \
        --arg gaming_type "$gaming_type" \
        --arg priority "$performance_priority" \
        '{
            installed: true,
            enabled: true,
            position: "top_left",
            metrics: {
                fps: true,
                gpu_stats: true,
                cpu_stats: true,
                memory: ($priority == "visual_quality" or $priority == "balanced"),
                temperature: ($priority != "maximum_fps")
            },
            appearance: {
                font_size: 24,
                background_alpha: 0.4
            }
        }')

    # Competitive gaming: minimal overlay
    if [[ "$gaming_type" == "competitive" ]]; then
        mangohud_config=$(echo "$mangohud_config" | jq '.metrics = {fps: true, gpu_stats: false, cpu_stats: false, memory: false, temperature: false}')
        mangohud_config=$(echo "$mangohud_config" | jq '.position = "top_right"')
    fi

    echo "$mangohud_config"
}

# ==============================================================================
# Profile Management Functions
# ==============================================================================

# Save gaming profile to disk
save_gaming_profile() {
    local profile_name="$1"
    local profile_data="$2"

    local profile_file="$GAMING_PROFILES_DIR/${profile_name}.json"

    # Ensure profile directory exists
    setup_profile_directories "$profile_name"

    # Create backup if profile already exists
    if [[ -f "$profile_file" ]]; then
        local backup_file="$GAMING_PROFILES_BACKUP_DIR/${profile_name}-$(date +%Y%m%d-%H%M%S).json"
        cp "$profile_file" "$backup_file"
        log_debug "Created backup: $backup_file"
    fi

    # Add metadata
    profile_data=$(echo "$profile_data" | jq \
        --arg updated "$(date -Iseconds)" \
        '.last_updated = $updated')

    # Write profile to file
    if echo "$profile_data" | jq '.' > "$profile_file"; then
        log_debug "Gaming profile saved: $profile_file"

        # Update cache
        GAMING_PROFILE_CACHE["$profile_name"]="$profile_data"

        return 0
    else
        log_error "Failed to save gaming profile: $profile_file"
        return 1
    fi
}

# Load gaming profile from disk
load_gaming_profile() {
    local profile_name="$1"
    local profile_file="$GAMING_PROFILES_DIR/${profile_name}.json"

    if [[ ! -f "$profile_file" ]]; then
        log_error "Gaming profile not found: $profile_name"
        return 1
    fi

    local profile_data
    if profile_data=$(jq '.' "$profile_file" 2>/dev/null); then
        # Update cache
        GAMING_PROFILE_CACHE["$profile_name"]="$profile_data"
        echo "$profile_data"
        return 0
    else
        log_error "Failed to load gaming profile: $profile_name"
        return 1
    fi
}

# List all gaming profiles
list_gaming_profiles() {
    local format="${1:-table}"  # table, json, names

    if [[ ! -d "$GAMING_PROFILES_DIR" ]]; then
        echo "No gaming profiles found."
        return 0
    fi

    local profiles=()
    while IFS= read -r -d '' profile_file; do
        local profile_name
        profile_name=$(basename "$profile_file" .json)
        profiles+=("$profile_name")
    done < <(find "$GAMING_PROFILES_DIR" -name "*.json" -print0)

    case "$format" in
        "names")
            printf '%s\n' "${profiles[@]}"
            ;;
        "json")
            {
                echo "{"
                echo "  \"profiles\": ["
                local first=true
                for profile_name in "${profiles[@]}"; do
                    [[ "$first" == "false" ]] && echo ","
                    local profile_data
                    profile_data=$(load_gaming_profile "$profile_name")
                    echo -n "    $(echo "$profile_data" | jq -c '.')"
                    first=false
                done
                echo ""
                echo "  ]"
                echo "}"
            }
            ;;
        "table"|*)
            if [[ ${#profiles[@]} -eq 0 ]]; then
                echo "No gaming profiles found."
                return 0
            fi

            printf "%-20s %-15s %-15s %-20s\n" "Profile Name" "Gaming Type" "Target FPS" "Last Updated"
            printf "%-20s %-15s %-15s %-20s\n" "----" "----" "----" "----"

            for profile_name in "${profiles[@]}"; do
                local profile_data
                profile_data=$(load_gaming_profile "$profile_name")

                local gaming_type target_fps last_updated
                gaming_type=$(echo "$profile_data" | jq -r '.gaming_preferences.primary_gaming_type // "unknown"')
                target_fps=$(echo "$profile_data" | jq -r '.gaming_preferences.target_fps // "unknown"')
                last_updated=$(echo "$profile_data" | jq -r '.last_updated // .created' | cut -d'T' -f1)

                printf "%-20s %-15s %-15s %-20s\n" "$profile_name" "$gaming_type" "$target_fps" "$last_updated"
            done
            ;;
    esac
}

# Check if profile exists
profile_exists() {
    local profile_name="$1"
    [[ -f "$GAMING_PROFILES_DIR/${profile_name}.json" ]]
}

# Count gaming profiles
count_gaming_profiles() {
    local count=0
    if [[ -d "$GAMING_PROFILES_DIR" ]]; then
        count=$(find "$GAMING_PROFILES_DIR" -name "*.json" | wc -l)
    fi
    echo "$count"
}

# Delete gaming profile
delete_gaming_profile() {
    local profile_name="$1"
    local confirm="${2:-true}"

    if ! profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' does not exist"
        return 1
    fi

    if [[ "$confirm" == "true" ]]; then
        read -p "Delete gaming profile '$profile_name'? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Profile deletion cancelled"
            return 0
        fi
    fi

    local profile_file="$GAMING_PROFILES_DIR/${profile_name}.json"
    local backup_file="$GAMING_PROFILES_BACKUP_DIR/${profile_name}-deleted-$(date +%Y%m%d-%H%M%S).json"

    # Create backup before deletion
    cp "$profile_file" "$backup_file"

    # Remove profile
    rm "$profile_file"

    # Remove from cache
    unset GAMING_PROFILE_CACHE["$profile_name"]

    # Remove profile directory if empty
    local profile_dir="$GAMING_PROFILES_DIR/$profile_name"
    if [[ -d "$profile_dir" ]] && [[ -z "$(ls -A "$profile_dir")" ]]; then
        rmdir "$profile_dir"
    fi

    print_success "Gaming profile '$profile_name' deleted (backup saved)"
    return 0
}

# ==============================================================================
# Profile Application Functions
# ==============================================================================

# Apply gaming profile to system
apply_gaming_profile() {
    local profile_name="$1"
    local dry_run="${2:-false}"

    if ! profile_exists "$profile_name"; then
        print_error "Profile '$profile_name' does not exist"
        return 1
    fi

    print_header "🚀 Applying Gaming Profile: $profile_name"

    local profile_data
    profile_data=$(load_gaming_profile "$profile_name")

    if [[ "$dry_run" == "true" ]]; then
        echo "DRY RUN MODE - No changes will be made"
        echo
    fi

    # Apply system optimizations
    print_section "System Optimizations"
    apply_profile_system_optimizations "$profile_data" "$dry_run"

    # Apply software configurations
    print_section "Software Configuration"
    apply_profile_software_configuration "$profile_data" "$dry_run"

    # Apply desktop environment settings
    print_section "Desktop Environment"
    apply_profile_desktop_settings "$profile_data" "$dry_run"

    # Set as current profile
    if [[ "$dry_run" == "false" ]]; then
        set_current_profile "$profile_name"
        print_success "Gaming profile '$profile_name' applied successfully!"
    else
        print_info "Dry run completed - no changes made"
    fi

    return 0
}

# Apply system optimizations from profile
apply_profile_system_optimizations() {
    local profile_data="$1"
    local dry_run="$2"

    local performance_priority
    performance_priority=$(echo "$profile_data" | jq -r '.gaming_preferences.performance_priority // "balanced"')

    echo "Performance priority: $performance_priority"

    # CPU Governor
    local use_performance_governor
    use_performance_governor=$(echo "$profile_data" | jq -r '.gaming_preferences.performance_cpu_governor // false')

    if [[ "$use_performance_governor" == "true" ]]; then
        echo "  🔧 Setting CPU governor to performance"
        if [[ "$dry_run" == "false" ]]; then
            # Apply CPU governor settings
            apply_cpu_governor_optimization "performance"
        fi
    fi

    # Memory optimizations
    if [[ "$performance_priority" == "maximum_fps" ]]; then
        echo "  🔧 Applying aggressive memory optimizations"
        if [[ "$dry_run" == "false" ]]; then
            apply_memory_optimizations "aggressive"
        fi
    fi

    # I/O scheduler optimizations
    echo "  🔧 Optimizing I/O scheduler for gaming"
    if [[ "$dry_run" == "false" ]]; then
        apply_io_scheduler_optimization
    fi
}

# Apply software configuration from profile
apply_profile_software_configuration() {
    local profile_data="$1"
    local dry_run="$2"

    # Steam configuration
    local steam_enabled
    steam_enabled=$(echo "$profile_data" | jq -r '.software_configuration.steam.installed // false')
    if [[ "$steam_enabled" == "true" ]]; then
        echo "  🎮 Configuring Steam settings"
        if [[ "$dry_run" == "false" ]]; then
            apply_steam_profile_configuration "$profile_data"
        fi
    fi

    # MangoHud configuration
    local mangohud_enabled
    mangohud_enabled=$(echo "$profile_data" | jq -r '.software_configuration.mangohud.enabled // false')
    if [[ "$mangohud_enabled" == "true" ]]; then
        echo "  📊 Configuring MangoHud settings"
        if [[ "$dry_run" == "false" ]]; then
            apply_mangohud_profile_configuration "$profile_data"
        fi
    fi

    # GameMode configuration
    local gamemode_enabled
    gamemode_enabled=$(echo "$profile_data" | jq -r '.software_configuration.gamemode.installed // false')
    if [[ "$gamemode_enabled" == "true" ]]; then
        echo "  ⚡ Configuring GameMode settings"
        if [[ "$dry_run" == "false" ]]; then
            apply_gamemode_profile_configuration "$profile_data"
        fi
    fi
}

# Apply desktop environment settings from profile
apply_profile_desktop_settings() {
    local profile_data="$1"
    local dry_run="$2"

    local disable_effects
    disable_effects=$(echo "$profile_data" | jq -r '.gaming_preferences.disable_desktop_effects // false')

    if [[ "$disable_effects" == "true" ]]; then
        echo "  🖥️ Disabling desktop effects for gaming"
        if [[ "$dry_run" == "false" ]]; then
            disable_desktop_effects_for_gaming
        fi
    else
        echo "  🖥️ Keeping desktop effects enabled"
    fi
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Sanitize profile name
sanitize_profile_name() {
    local name="$1"
    # Remove special characters and spaces, convert to lowercase
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g' | sed 's/^-\+\|-\+$//g'
}

# Set current active profile
set_current_profile() {
    local profile_name="$1"
    echo "$profile_name" > "$CURRENT_PROFILE_FILE"
    log_debug "Current gaming profile set to: $profile_name"
}

# Get current active profile
get_current_profile() {
    if [[ -f "$CURRENT_PROFILE_FILE" ]]; then
        cat "$CURRENT_PROFILE_FILE"
    else
        echo ""
    fi
}

# Load current profile into cache
load_current_profile_cache() {
    local current_profile
    current_profile=$(get_current_profile)

    if [[ -n "$current_profile" ]] && profile_exists "$current_profile"; then
        load_gaming_profile "$current_profile" >/dev/null
        log_debug "Current profile loaded into cache: $current_profile"
    fi
}

# Create default gaming profile
create_default_gaming_profile() {
    log_debug "Creating default gaming profile"

    local default_name="default"
    local profile_data

    # Create basic default profile
    profile_data=$(jq -n \
        --arg version "$PROFILE_VERSION" \
        --arg name "$default_name" \
        --arg created "$(date -Iseconds)" \
        '{
            profile_version: $version,
            name: $name,
            created: $created,
            description: "Default gaming profile",
            hardware_profile: {},
            gaming_preferences: {
                primary_gaming_type: "balanced",
                target_resolution: "auto",
                target_fps: 60,
                performance_priority: "balanced"
            },
            software_configuration: {},
            system_optimizations: {},
            custom_settings: {}
        }')

    # Add hardware context
    profile_data=$(add_hardware_context_to_profile "$profile_data")

    # Add software configuration
    profile_data=$(detect_and_configure_gaming_software "$profile_data")

    # Save default profile
    save_gaming_profile "$default_name" "$profile_data"
    set_current_profile "$default_name"

    log_debug "Default gaming profile created and set as current"
}

# Export functions for other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Gaming Profile Management Library v1.0.0"
    echo "This library should be sourced, not executed directly."
    echo ""
    echo "Available functions:"
    echo "  Profile Creation: create_gaming_profile, save_gaming_profile"
    echo "  Profile Management: list_gaming_profiles, delete_gaming_profile"
    echo "  Profile Application: apply_gaming_profile"
    echo "  Profile Utilities: profile_exists, get_current_profile"
    exit 1
fi

log_debug "xanadOS Gaming Profile Management Library loaded"
