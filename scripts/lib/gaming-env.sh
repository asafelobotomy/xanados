#!/bin/bash
# xanadOS Gaming Environment Detection Library
# Centralized gaming tool detection and environment management
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_GAMING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_GAMING_LOADED="true"

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# Note: validation.sh sources this file, so we don't source it here to avoid circular dependency
# command_exists is available from common.sh

# Gaming environment cache
declare -A GAMING_ENV_CACHE

# Gaming platforms and their configurations
declare -A GAMING_PLATFORMS
GAMING_PLATFORMS=(
    ["steam"]="Steam Gaming Platform"
    ["lutris"]="Lutris Gaming Manager"
    ["heroic"]="Epic Games Store Client"
    ["bottles"]="Windows Software Manager"
    ["itch"]="Itch.io Gaming Platform"
    ["gog"]="GOG Galaxy (unofficial)"
)

# Gaming tools and utilities
declare -A GAMING_UTILITIES
GAMING_UTILITIES=(
    ["wine"]="Windows Compatibility Layer"
    ["winetricks"]="Wine Configuration Tool"
    ["gamemoderun"]="GameMode Performance Optimization"
    ["mangohud"]="Performance Monitoring Overlay"
    ["goverlay"]="MangoHud Configuration GUI"
    ["protonup-qt"]="Proton Version Manager"
    ["protontricks"]="Proton Debugging Tool"
    ["steamtinkerlaunch"]="Steam Game Launcher"
)

# Graphics and drivers
declare -A GRAPHICS_TOOLS
GRAPHICS_TOOLS=(
    ["nvidia-smi"]="NVIDIA System Management Interface"
    ["nvidia-settings"]="NVIDIA Control Panel"
    ["radeontop"]="AMD GPU Monitoring"
    ["vulkaninfo"]="Vulkan API Information"
    ["glxinfo"]="OpenGL Information"
    ["vainfo"]="Video Acceleration Information"
    ["vdpauinfo"]="VDPAU Information"
)

# Audio tools
declare -A AUDIO_TOOLS
AUDIO_TOOLS=(
    ["pipewire"]="Modern Audio Server"
    ["pulseaudio"]="Audio Server"
    ["alsa-utils"]="ALSA Utilities"
    ["pavucontrol"]="PulseAudio Volume Control"
    ["qpwgraph"]="PipeWire Graph Manager"
)

# Performance monitoring tools
declare -A PERFORMANCE_TOOLS
PERFORMANCE_TOOLS=(
    ["htop"]="System Process Monitor"
    ["iotop"]="I/O Monitor"
    ["nethogs"]="Network Usage Monitor"
    ["glances"]="System Monitoring"
    ["stress"]="System Stress Testing"
    ["stress-ng"]="Advanced Stress Testing"
)

# Detect gaming environment with caching
detect_gaming_environment() {
    local force_refresh="${1:-false}"

    if [[ "$force_refresh" == "false" ]] && [[ -n "${GAMING_ENV_CACHE[detected]:-}" ]]; then
        return 0
    fi

    log_debug "Detecting gaming environment..."

    # Clear cache if forcing refresh
    if [[ "$force_refresh" == "true" ]]; then
        GAMING_ENV_CACHE=()
    fi

    # Detect platforms
    for platform in "${!GAMING_PLATFORMS[@]}"; do
        if command_exists "$platform"; then
            GAMING_ENV_CACHE["platform_$platform"]="available"
        else
            GAMING_ENV_CACHE["platform_$platform"]="missing"
        fi
    done

    # Detect utilities
    for utility in "${!GAMING_UTILITIES[@]}"; do
        if command_exists "$utility"; then
            GAMING_ENV_CACHE["utility_$utility"]="available"
        else
            GAMING_ENV_CACHE["utility_$utility"]="missing"
        fi
    done

    # Detect graphics tools
    for tool in "${!GRAPHICS_TOOLS[@]}"; do
        if command_exists "$tool"; then
            GAMING_ENV_CACHE["graphics_$tool"]="available"
        else
            GAMING_ENV_CACHE["graphics_$tool"]="missing"
        fi
    done

    # Detect audio tools
    for tool in "${!AUDIO_TOOLS[@]}"; do
        if command_exists "$tool"; then
            GAMING_ENV_CACHE["audio_$tool"]="available"
        else
            GAMING_ENV_CACHE["audio_$tool"]="missing"
        fi
    done

    # Detect performance tools
    for tool in "${!PERFORMANCE_TOOLS[@]}"; do
        if command_exists "$tool"; then
            GAMING_ENV_CACHE["perf_$tool"]="available"
        else
            GAMING_ENV_CACHE["perf_$tool"]="missing"
        fi
    done

    # Detect GPU type
    detect_gpu_type

    # Detect audio system
    detect_gaming_audio_system

    # Mark detection as complete
    GAMING_ENV_CACHE["detected"]="true"
    GAMING_ENV_CACHE["detection_time"]="$(date +%s)"

    log_debug "Gaming environment detection completed"
}

# Detect GPU type and driver
detect_gpu_type() {
    local gpu_type="unknown"
    local driver="unknown"

    if command_exists "nvidia-smi"; then
        gpu_type="nvidia"
        driver="nvidia"
    elif command_exists "radeontop" || [[ -d "/sys/class/drm/card0" ]]; then
        gpu_type="amd"
        if lsmod 2>/dev/null | grep -q "amdgpu" || false; then
            driver="amdgpu"
        elif lsmod 2>/dev/null | grep -q "radeon" || false; then
            driver="radeon"
        fi
    elif lspci 2>/dev/null | grep -qi intel || false; then
        gpu_type="intel"
        driver="intel"
    fi

    GAMING_ENV_CACHE["gpu_type"]="$gpu_type"
    GAMING_ENV_CACHE["gpu_driver"]="$driver"
}

# Detect audio system and cache result
detect_gaming_audio_system() {
    local audio_system="unknown"

    if systemctl --user is-active pipewire >/dev/null 2>&1; then
        audio_system="pipewire"
    elif systemctl --user is-active pulseaudio >/dev/null 2>&1; then
        audio_system="pulseaudio"
    elif command_exists "pulseaudio"; then
        audio_system="pulseaudio"
    fi

    GAMING_ENV_CACHE["audio_system"]="$audio_system"
}

# Check if specific gaming platform is available
is_platform_available() {
    local platform="$1"

    detect_gaming_environment
    [[ "${GAMING_ENV_CACHE[platform_$platform]:-}" == "available" ]]
}

# Check if specific gaming utility is available
is_utility_available() {
    local utility="$1"

    detect_gaming_environment
    [[ "${GAMING_ENV_CACHE[utility_$utility]:-}" == "available" ]]
}

# Get gaming environment report
get_gaming_environment_report() {
    local format="${1:-summary}"  # summary, detailed, json

    detect_gaming_environment

    case "$format" in
        "json")
            generate_json_report
            ;;
        "detailed")
            generate_detailed_report
            ;;
        "summary"|*)
            generate_summary_report
            ;;
    esac
}

# Generate summary report
generate_summary_report() {
    echo "Gaming Environment Summary:"
    echo ""

    # Count available platforms
    local platform_count=0
    local available_platforms=()
    for platform in "${!GAMING_PLATFORMS[@]}"; do
        if [[ "${GAMING_ENV_CACHE[platform_$platform]:-}" == "available" ]]; then
            ((platform_count++))
            available_platforms+=("$platform")
        fi
    done

    # Count available utilities
    local utility_count=0
    local available_utilities=()
    for utility in "${!GAMING_UTILITIES[@]}"; do
        if [[ "${GAMING_ENV_CACHE[utility_$utility]:-}" == "available" ]]; then
            ((utility_count++))
            available_utilities+=("$utility")
        fi
    done

    echo "Platforms: $platform_count/${#GAMING_PLATFORMS[@]} available"
    if [[ ${#available_platforms[@]} -gt 0 ]]; then
        echo "  Available: ${available_platforms[*]}"
    fi
    echo ""

    echo "Utilities: $utility_count/${#GAMING_UTILITIES[@]} available"
    if [[ ${#available_utilities[@]} -gt 0 ]]; then
        echo "  Available: ${available_utilities[*]}"
    fi
    echo ""

    echo "Graphics: ${GAMING_ENV_CACHE[gpu_type]:-unknown} (${GAMING_ENV_CACHE[gpu_driver]:-unknown})"
    echo "Audio: ${GAMING_ENV_CACHE[audio_system]:-unknown}"
}

# Generate detailed report
generate_detailed_report() {
    echo "Gaming Environment Detailed Report:"
    echo ""

    # Gaming Platforms
    echo "Gaming Platforms:"
    for platform in "${!GAMING_PLATFORMS[@]}"; do
        local status="${GAMING_ENV_CACHE[platform_$platform]:-unknown}"
        local symbol="✗"
        [[ "$status" == "available" ]] && symbol="✓"
        echo "  $symbol $platform - ${GAMING_PLATFORMS[$platform]}"
    done
    echo ""

    # Gaming Utilities
    echo "Gaming Utilities:"
    for utility in "${!GAMING_UTILITIES[@]}"; do
        local status="${GAMING_ENV_CACHE[utility_$utility]:-unknown}"
        local symbol="✗"
        [[ "$status" == "available" ]] && symbol="✓"
        echo "  $symbol $utility - ${GAMING_UTILITIES[$utility]}"
    done
    echo ""

    # Graphics Tools
    echo "Graphics Tools:"
    for tool in "${!GRAPHICS_TOOLS[@]}"; do
        local status="${GAMING_ENV_CACHE[graphics_$tool]:-unknown}"
        local symbol="✗"
        [[ "$status" == "available" ]] && symbol="✓"
        echo "  $symbol $tool - ${GRAPHICS_TOOLS[$tool]}"
    done
    echo ""

    # Audio Tools
    echo "Audio Tools:"
    for tool in "${!AUDIO_TOOLS[@]}"; do
        local status="${GAMING_ENV_CACHE[audio_$tool]:-unknown}"
        local symbol="✗"
        [[ "$status" == "available" ]] && symbol="✓"
        echo "  $symbol $tool - ${AUDIO_TOOLS[$tool]}"
    done
    echo ""

    # Performance Tools
    echo "Performance Tools:"
    for tool in "${!PERFORMANCE_TOOLS[@]}"; do
        local status="${GAMING_ENV_CACHE[perf_$tool]:-unknown}"
        local symbol="✗"
        [[ "$status" == "available" ]] && symbol="✓"
        echo "  $symbol $tool - ${PERFORMANCE_TOOLS[$tool]}"
    done
    echo ""

    # System Information
    echo "System Information:"
    echo "  GPU Type: ${GAMING_ENV_CACHE[gpu_type]:-unknown}"
    echo "  GPU Driver: ${GAMING_ENV_CACHE[gpu_driver]:-unknown}"
    echo "  Audio System: ${GAMING_ENV_CACHE[audio_system]:-unknown}"
    echo "  Desktop Session: ${XDG_SESSION_TYPE:-unknown}"
    echo "  Display Server: ${WAYLAND_DISPLAY:+wayland}${DISPLAY:+${WAYLAND_DISPLAY:+/}x11}"
}

# Generate JSON report
generate_json_report() {
    echo "{"
    echo '  "gaming_environment": {'
    echo '    "detection_time": "'${GAMING_ENV_CACHE[detection_time]:-}'",'
    echo '    "platforms": {'

    local first=true
    for platform in "${!GAMING_PLATFORMS[@]}"; do
        [[ "$first" == "false" ]] && echo ","
        local status="${GAMING_ENV_CACHE[platform_$platform]:-unknown}"
        echo -n "      \"$platform\": \"$status\""
        first=false
    done
    echo ""
    echo '    },'

    echo '    "utilities": {'
    first=true
    for utility in "${!GAMING_UTILITIES[@]}"; do
        [[ "$first" == "false" ]] && echo ","
        local status="${GAMING_ENV_CACHE[utility_$utility]:-unknown}"
        echo -n "      \"$utility\": \"$status\""
        first=false
    done
    echo ""
    echo '    },'

    echo '    "system": {'
    echo "      \"gpu_type\": \"${GAMING_ENV_CACHE[gpu_type]:-unknown}\","
    echo "      \"gpu_driver\": \"${GAMING_ENV_CACHE[gpu_driver]:-unknown}\","
    echo "      \"audio_system\": \"${GAMING_ENV_CACHE[audio_system]:-unknown}\""
    echo '    }'
    echo '  }'
    echo "}"
}

# Get gaming readiness score (0-100)
get_gaming_readiness_score() {
    detect_gaming_environment

    local total_score=0
    local max_score=0

    # Score platforms (40% weight)
    local platform_score=0
    for platform in "${!GAMING_PLATFORMS[@]}"; do
        ((max_score += 10))
        if [[ "${GAMING_ENV_CACHE[platform_$platform]:-}" == "available" ]]; then
            ((platform_score += 10))
        fi
    done
    total_score=$((total_score + platform_score))

    # Score utilities (30% weight)
    local utility_score=0
    for utility in "${!GAMING_UTILITIES[@]}"; do
        ((max_score += 8))
        if [[ "${GAMING_ENV_CACHE[utility_$utility]:-}" == "available" ]]; then
            ((utility_score += 8))
        fi
    done
    total_score=$((total_score + utility_score))

    # Score graphics tools (20% weight)
    local graphics_score=0
    for tool in "${!GRAPHICS_TOOLS[@]}"; do
        ((max_score += 5))
        if [[ "${GAMING_ENV_CACHE[graphics_$tool]:-}" == "available" ]]; then
            ((graphics_score += 5))
        fi
    done
    total_score=$((total_score + graphics_score))

    # Score audio tools (10% weight)
    local audio_score=0
    for tool in "${!AUDIO_TOOLS[@]}"; do
        ((max_score += 2))
        if [[ "${GAMING_ENV_CACHE[audio_$tool]:-}" == "available" ]]; then
            ((audio_score += 2))
        fi
    done
    total_score=$((total_score + audio_score))

    # Calculate percentage
    local percentage=$((total_score * 100 / max_score))
    echo "$percentage"
}

# Clear gaming environment cache
clear_gaming_cache() {
    GAMING_ENV_CACHE=()
    log_debug "Gaming environment cache cleared"
}

# Get missing gaming tools
get_missing_gaming_tools() {
    local category="${1:-all}"  # all, platforms, utilities, graphics, audio

    detect_gaming_environment

    local missing=()

    case "$category" in
        "platforms")
            for platform in "${!GAMING_PLATFORMS[@]}"; do
                if [[ "${GAMING_ENV_CACHE[platform_$platform]:-}" == "missing" ]]; then
                    missing+=("$platform")
                fi
            done
            ;;
        "utilities")
            for utility in "${!GAMING_UTILITIES[@]}"; do
                if [[ "${GAMING_ENV_CACHE[utility_$utility]:-}" == "missing" ]]; then
                    missing+=("$utility")
                fi
            done
            ;;
        "graphics")
            for tool in "${!GRAPHICS_TOOLS[@]}"; do
                if [[ "${GAMING_ENV_CACHE[graphics_$tool]:-}" == "missing" ]]; then
                    missing+=("$tool")
                fi
            done
            ;;
        "audio")
            for tool in "${!AUDIO_TOOLS[@]}"; do
                if [[ "${GAMING_ENV_CACHE[audio_$tool]:-}" == "missing" ]]; then
                    missing+=("$tool")
                fi
            done
            ;;
        "all"|*)
            get_missing_gaming_tools "platforms"
            missing+=("$(get_missing_gaming_tools "utilities")")
            missing+=("$(get_missing_gaming_tools "graphics")")
            missing+=("$(get_missing_gaming_tools "audio")")
            ;;
    esac

    printf '%s\n' "${missing[@]}"
}

# ==============================================================================
# Gaming Tool Availability Matrix Functions (Task 3.1.2)
# ==============================================================================

# Generate comprehensive gaming tool availability matrix
generate_gaming_matrix() {
    local output_format="${1:-table}"  # table, json, detailed
    local show_versions="${2:-false}"

    # Ensure gaming environment is detected
    detect_gaming_environment

    case "$output_format" in
        "json")
            generate_gaming_matrix_json "$show_versions"
            ;;
        "detailed")
            generate_gaming_matrix_detailed "$show_versions"
            ;;
        "table"|*)
            generate_gaming_matrix_table "$show_versions"
            ;;
    esac
}

# Generate gaming matrix in table format
generate_gaming_matrix_table() {
    local show_versions="${1:-false}"
    local readiness_score

    readiness_score=$(get_gaming_readiness_score)

    echo ""
    print_header "🎮 Gaming Environment Matrix"
    echo ""
    echo "Overall Gaming Readiness: ${readiness_score}%"
    echo ""

    # Table header
    if [[ "$show_versions" == "true" ]]; then
        printf "%-25s %-10s %-15s %-15s\n" "Tool" "Status" "Version" "Readiness"
        printf "%-25s %-10s %-15s %-15s\n" "-------------------------" "----------" "---------------" "---------------"
    else
        printf "%-25s %-10s %-15s\n" "Tool" "Status" "Readiness"
        printf "%-25s %-10s %-15s\n" "-------------------------" "----------" "---------------"
    fi

    # Gaming Platforms
    echo ""
    echo "Gaming Platforms:"
    for platform in "${!GAMING_PLATFORMS[@]}"; do
        local status="❌"
        local readiness="0%"
        local version="N/A"

        if get_cached_command "$platform"; then
            status="✅"
            readiness="95%"
            if [[ "$show_versions" == "true" ]]; then
                version=$(get_tool_version "$platform")
            fi
        fi

        if [[ "$show_versions" == "true" ]]; then
            printf "  %-23s %-10s %-15s %-15s\n" "$platform" "$status" "$version" "$readiness"
        else
            printf "  %-23s %-10s %-15s\n" "$platform" "$status" "$readiness"
        fi
    done

    # Gaming Utilities
    echo ""
    echo "Gaming Utilities:"
    for utility in "${!GAMING_UTILITIES[@]}"; do
        local status="❌"
        local readiness="0%"
        local version="N/A"

        if get_cached_command "$utility"; then
            status="✅"
            readiness="90%"
            if [[ "$show_versions" == "true" ]]; then
                version=$(get_tool_version "$utility")
            fi
        fi

        if [[ "$show_versions" == "true" ]]; then
            printf "  %-23s %-10s %-15s %-15s\n" "$utility" "$status" "$version" "$readiness"
        else
            printf "  %-23s %-10s %-15s\n" "$utility" "$status" "$readiness"
        fi
    done

    # Graphics Tools
    echo ""
    echo "Graphics Tools:"
    for tool in "${!GRAPHICS_TOOLS[@]}"; do
        local status="❌"
        local readiness="0%"
        local version="N/A"

        if get_cached_command "$tool"; then
            status="✅"
            readiness="85%"
            if [[ "$show_versions" == "true" ]]; then
                version=$(get_tool_version "$tool")
            fi
        fi

        if [[ "$show_versions" == "true" ]]; then
            printf "  %-23s %-10s %-15s %-15s\n" "$tool" "$status" "$version" "$readiness"
        else
            printf "  %-23s %-10s %-15s\n" "$tool" "$status" "$readiness"
        fi
    done

    echo ""
}

# Generate gaming matrix in JSON format
generate_gaming_matrix_json() {
    local show_versions="${1:-false}"
    local readiness_score

    readiness_score=$(get_gaming_readiness_score)

    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"gaming_readiness_score\": $readiness_score,"
    echo "  \"show_versions\": $show_versions,"
    echo "  \"categories\": {"

    # Gaming Platforms
    echo "    \"gaming_platforms\": {"
    local platform_count=0
    local total_platforms=${#GAMING_PLATFORMS[@]}

    for platform in "${!GAMING_PLATFORMS[@]}"; do
        ((platform_count++))
        local is_available=false
        local version="null"

        if get_cached_command "$platform"; then
            is_available=true
            if [[ "$show_versions" == "true" ]]; then
                version="\"$(get_tool_version "$platform")\""
            fi
        fi

        echo "      \"$platform\": {"
        echo "        \"description\": \"${GAMING_PLATFORMS[$platform]}\","
        echo "        \"available\": $is_available,"
        if [[ "$show_versions" == "true" ]]; then
            echo "        \"version\": $version,"
        fi
        echo "        \"readiness_contribution\": $([ "$is_available" = true ] && echo "95" || echo "0")"
        if [[ $platform_count -lt $total_platforms ]]; then
            echo "      },"
        else
            echo "      }"
        fi
    done
    echo "    },"

    # Gaming Utilities
    echo "    \"gaming_utilities\": {"
    local utility_count=0
    local total_utilities=${#GAMING_UTILITIES[@]}

    for utility in "${!GAMING_UTILITIES[@]}"; do
        ((utility_count++))
        local is_available=false
        local version="null"

        if get_cached_command "$utility"; then
            is_available=true
            if [[ "$show_versions" == "true" ]]; then
                version="\"$(get_tool_version "$utility")\""
            fi
        fi

        echo "      \"$utility\": {"
        echo "        \"description\": \"${GAMING_UTILITIES[$utility]}\","
        echo "        \"available\": $is_available,"
        if [[ "$show_versions" == "true" ]]; then
            echo "        \"version\": $version,"
        fi
        echo "        \"readiness_contribution\": $([ "$is_available" = true ] && echo "90" || echo "0")"
        if [[ $utility_count -lt $total_utilities ]]; then
            echo "      },"
        else
            echo "      }"
        fi
    done
    echo "    },"

    # Graphics Tools
    echo "    \"graphics_tools\": {"
    local graphics_count=0
    local total_graphics=${#GRAPHICS_TOOLS[@]}

    for tool in "${!GRAPHICS_TOOLS[@]}"; do
        ((graphics_count++))
        local is_available=false
        local version="null"

        if get_cached_command "$tool"; then
            is_available=true
            if [[ "$show_versions" == "true" ]]; then
                version="\"$(get_tool_version "$tool")\""
            fi
        fi

        echo "      \"$tool\": {"
        echo "        \"description\": \"${GRAPHICS_TOOLS[$tool]}\","
        echo "        \"available\": $is_available,"
        if [[ "$show_versions" == "true" ]]; then
            echo "        \"version\": $version,"
        fi
        echo "        \"readiness_contribution\": $([ "$is_available" = true ] && echo "85" || echo "0")"
        if [[ $graphics_count -lt $total_graphics ]]; then
            echo "      },"
        else
            echo "      }"
        fi
    done
    echo "    }"

    echo "  }"
    echo "}"
}

# Generate detailed gaming matrix with recommendations
generate_gaming_matrix_detailed() {
    local show_versions="${1:-false}"
    local readiness_score

    readiness_score=$(get_gaming_readiness_score)

    print_header "🎮 Detailed Gaming Environment Analysis"
    echo ""
    echo "Overall Gaming Readiness Score: ${readiness_score}%"
    echo ""

    # Assessment
    if [[ $readiness_score -ge 90 ]]; then
        log_success "Excellent! Your system is ready for high-performance gaming."
    elif [[ $readiness_score -ge 70 ]]; then
        log_warning "Good gaming setup. Consider installing missing tools for optimal experience."
    elif [[ $readiness_score -ge 50 ]]; then
        log_warning "Basic gaming capability. Several important tools are missing."
    else
        log_error "Limited gaming capability. Significant setup required."
    fi

    echo ""

    # Detailed breakdown by category
    analyze_gaming_category "Gaming Platforms" GAMING_PLATFORMS 95
    analyze_gaming_category "Gaming Utilities" GAMING_UTILITIES 90
    analyze_gaming_category "Graphics Tools" GRAPHICS_TOOLS 85

    # Recommendations
    echo ""
    print_section "🚀 Recommendations"
    provide_gaming_recommendations
}

# Analyze a specific gaming category
analyze_gaming_category() {
    local category_name="$1"
    local -n tools_array=$2
    local weight="$3"

    local available_count=0
    local total_count=0
    local missing_tools=()

    echo "📊 $category_name Analysis:"

    for tool in "${!tools_array[@]}"; do
        ((total_count++))
        if get_cached_command "$tool"; then
            ((available_count++))
            echo "  ✅ $tool - ${tools_array[$tool]}"
        else
            missing_tools+=("$tool")
            echo "  ❌ $tool - ${tools_array[$tool]} (MISSING)"
        fi
    done

    local category_percentage=$((available_count * 100 / total_count))
    echo ""
    echo "  Category Score: $available_count/$total_count tools ($category_percentage%)"

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "  Missing: ${missing_tools[*]}"
    fi

    echo ""
}

# Provide gaming-specific recommendations
provide_gaming_recommendations() {
    local recommendations=()

    # Check for essential gaming platforms
    if ! get_cached_command "steam"; then
        recommendations+=("Install Steam for the largest gaming library")
    fi

    if ! get_cached_command "lutris"; then
        recommendations+=("Install Lutris for non-Steam games and emulators")
    fi

    # Check for gaming utilities
    if ! get_cached_command "gamemoderun"; then
        recommendations+=("Install GameMode for CPU/GPU performance optimization")
    fi

    if ! get_cached_command "mangohud"; then
        recommendations+=("Install MangoHud for in-game performance monitoring")
    fi

    if ! get_cached_command "wine"; then
        recommendations+=("Install Wine for Windows game compatibility")
    fi

    # Check for graphics tools
    if ! get_cached_command "vulkaninfo"; then
        recommendations+=("Install Vulkan tools for modern graphics API support")
    fi

    # GPU-specific recommendations
    if get_cached_command "nvidia-smi"; then
        if ! get_cached_command "nvidia-settings"; then
            recommendations+=("Install nvidia-settings for GPU configuration")
        fi
    elif lspci | grep -qi "amd.*vga\|amd.*display"; then
        if ! get_cached_command "radeontop"; then
            recommendations+=("Install radeontop for AMD GPU monitoring")
        fi
    fi

    # Display recommendations
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        echo "Priority Recommendations:"
        for i in "${!recommendations[@]}"; do
            echo "  $((i+1)). ${recommendations[i]}"
        done
    else
        echo "🎉 No recommendations needed! Your gaming environment is well-configured."
    fi

    echo ""
    echo "💡 Tip: Run 'generate_gaming_matrix json true' for machine-readable output with versions."
}

# Get tool version safely
get_tool_version() {
    local tool="$1"
    local version="Unknown"

    case "$tool" in
        "steam")
            version=$(steam --version 2>/dev/null | head -1 | awk '{print $2}' || echo "Unknown")
            ;;
        "wine")
            version=$(wine --version 2>/dev/null || echo "Unknown")
            ;;
        "nvidia-smi")
            version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "Unknown")
            ;;
        "vulkaninfo")
            version=$(vulkaninfo --summary 2>/dev/null | grep "Vulkan API Version" | awk '{print $4}' || echo "Unknown")
            ;;
        *)
            # Try generic --version
            version=$($tool --version 2>/dev/null | head -1 | awk '{print $NF}' || echo "Unknown")
            ;;
    esac

    echo "$version"
}

# ==============================================================================
# Gaming Environment Compatibility Checking
# ==============================================================================

# Gaming configuration profiles - known good configurations
declare -A GAMING_PROFILES

# Define gaming configuration profiles
init_gaming_profiles() {
    # Essential Gaming Profile - Minimum for basic gaming
    GAMING_PROFILES[essential]="steam gamemode mangohud"

    # Standard Gaming Profile - Good general gaming setup
    GAMING_PROFILES[standard]="steam lutris gamemode mangohud wine winetricks"

    # Advanced Gaming Profile - Comprehensive gaming environment
    GAMING_PROFILES[advanced]="steam lutris gamemode mangohud wine winetricks protontricks bottles heroic goverlay"

    # Professional Gaming Profile - Full gaming development/streaming setup
    GAMING_PROFILES[professional]="steam lutris gamemode mangohud wine winetricks protontricks bottles heroic goverlay obs-studio discord"

    # Emulation Profile - Retro gaming focused
    GAMING_PROFILES[emulation]="retroarch pcsx2 dolphin-emu ppsspp duckstation"

    # VR Gaming Profile - Virtual reality gaming
    GAMING_PROFILES[vr]="steam steamvr wine gamemode mangohud"
}

# Check gaming environment compatibility against a profile
check_gaming_compatibility() {
    local profile="${1:-standard}"  # essential, standard, advanced, professional, emulation, vr
    local verbose="${2:-false}"

    init_gaming_profiles

    if [[ -z "${GAMING_PROFILES[$profile]:-}" ]]; then
        echo "Error: Unknown gaming profile '$profile'"
        echo "Available profiles: ${!GAMING_PROFILES[*]}"
        return 1
    fi

    if [[ "$verbose" == "true" ]]; then
        echo "Checking compatibility with '$profile' gaming profile..."
        echo
    fi

    local profile_tools
    read -ra profile_tools <<< "${GAMING_PROFILES[$profile]}"

    local missing_tools=()
    local available_tools=()
    local compatibility_score=0
    local total_tools=${#profile_tools[@]}

    # Check each required tool
    for tool in "${profile_tools[@]}"; do
        if get_cached_command "$tool"; then
            available_tools+=("$tool")
            ((compatibility_score++))
        else
            missing_tools+=("$tool")
        fi
    done

    # Calculate compatibility percentage
    local compatibility_percentage=$((compatibility_score * 100 / total_tools))

    if [[ "$verbose" == "true" ]]; then
        echo "Profile: $profile"
        echo "Required tools: ${#profile_tools[@]}"
        echo "Available tools: ${#available_tools[@]}"
        echo "Missing tools: ${#missing_tools[@]}"
        echo "Compatibility: $compatibility_percentage%"
        echo

        if [[ ${#available_tools[@]} -gt 0 ]]; then
            echo "✅ Available tools:"
            for tool in "${available_tools[@]}"; do
                echo "   $tool"
            done
            echo
        fi

        if [[ ${#missing_tools[@]} -gt 0 ]]; then
            echo "❌ Missing tools:"
            for tool in "${missing_tools[@]}"; do
                echo "   $tool"
            done
            echo
        fi
    fi

    # Store results for other functions to use
    COMPATIBILITY_PROFILE="$profile"
    COMPATIBILITY_SCORE="$compatibility_percentage"
    MISSING_TOOLS=("${missing_tools[@]}")
    AVAILABLE_TOOLS=("${available_tools[@]}")

    return 0
}

# Get compatibility recommendations based on missing tools
get_compatibility_recommendations() {
    local profile="${1:-standard}"

    # Run compatibility check if not already done
    if [[ -z "${COMPATIBILITY_PROFILE:-}" ]] || [[ "$COMPATIBILITY_PROFILE" != "$profile" ]]; then
        check_gaming_compatibility "$profile" false
    fi

    if [[ ${#MISSING_TOOLS[@]} -eq 0 ]]; then
        echo "🎉 Your system is fully compatible with the '$profile' gaming profile!"
        return 0
    fi

    echo "📋 Recommendations for '$profile' gaming profile compatibility:"
    echo

    # Categorize missing tools and provide specific recommendations
    local platforms=()
    local utilities=()
    local graphics=()
    local emulators=()
    local other=()

    for tool in "${MISSING_TOOLS[@]}"; do
        case "$tool" in
            steam|lutris|heroic|bottles|itch|gog)
                platforms+=("$tool")
                ;;
            gamemode|mangohud|wine|winetricks|protontricks|goverlay|protonup-qt|steamtinkerlaunch)
                utilities+=("$tool")
                ;;
            nvidia-smi|nvidia-settings|radeontop|vulkaninfo|glxinfo|vainfo|vdpauinfo)
                graphics+=("$tool")
                ;;
            retroarch|pcsx2|dolphin-emu|ppsspp|duckstation)
                emulators+=("$tool")
                ;;
            *)
                other+=("$tool")
                ;;
        esac
    done

    # Provide category-specific recommendations
    if [[ ${#platforms[@]} -gt 0 ]]; then
        echo "🎮 Gaming Platforms:"
        for platform in "${platforms[@]}"; do
            case "$platform" in
                steam)
                    echo "   • Install Steam: sudo apt install steam-installer (or from website)"
                    ;;
                lutris)
                    echo "   • Install Lutris: sudo apt install lutris"
                    ;;
                heroic)
                    echo "   • Install Heroic Games Launcher: Download from heroicgameslauncher.com"
                    ;;
                bottles)
                    echo "   • Install Bottles: flatpak install flathub com.usebottles.bottles"
                    ;;
                *)
                    echo "   • Install $platform: Check official website or package manager"
                    ;;
            esac
        done
        echo
    fi

    if [[ ${#utilities[@]} -gt 0 ]]; then
        echo "🔧 Gaming Utilities:"
        for utility in "${utilities[@]}"; do
            case "$utility" in
                gamemode)
                    echo "   • Install GameMode: sudo apt install gamemode"
                    ;;
                mangohud)
                    echo "   • Install MangoHud: sudo apt install mangohud"
                    ;;
                wine)
                    echo "   • Install Wine: sudo apt install wine"
                    ;;
                winetricks)
                    echo "   • Install Winetricks: sudo apt install winetricks"
                    ;;
                protontricks)
                    echo "   • Install Protontricks: pip install protontricks"
                    ;;
                goverlay)
                    echo "   • Install GOverlay: Download from github.com/benjamimgois/goverlay"
                    ;;
                *)
                    echo "   • Install $utility: Check documentation for installation method"
                    ;;
            esac
        done
        echo
    fi

    if [[ ${#graphics[@]} -gt 0 ]]; then
        echo "🖥️ Graphics Tools:"
        for tool in "${graphics[@]}"; do
            case "$tool" in
                nvidia-smi|nvidia-settings)
                    echo "   • Install NVIDIA drivers and tools: sudo apt install nvidia-driver-XXX nvidia-settings"
                    ;;
                radeontop)
                    echo "   • Install radeontop: sudo apt install radeontop"
                    ;;
                vulkaninfo)
                    echo "   • Install Vulkan tools: sudo apt install vulkan-tools"
                    ;;
                glxinfo)
                    echo "   • Install Mesa utils: sudo apt install mesa-utils"
                    ;;
                vainfo|vdpauinfo)
                    echo "   • Install VA-API/VDPAU tools: sudo apt install vainfo vdpau-va-driver"
                    ;;
            esac
        done
        echo
    fi

    if [[ ${#emulators[@]} -gt 0 ]]; then
        echo "🕹️ Emulators:"
        for emulator in "${emulators[@]}"; do
            case "$emulator" in
                retroarch)
                    echo "   • Install RetroArch: sudo apt install retroarch"
                    ;;
                pcsx2)
                    echo "   • Install PCSX2: Download from pcsx2.net"
                    ;;
                dolphin-emu)
                    echo "   • Install Dolphin: sudo apt install dolphin-emu"
                    ;;
                ppsspp)
                    echo "   • Install PPSSPP: sudo apt install ppsspp"
                    ;;
                duckstation)
                    echo "   • Install DuckStation: Download from github.com/stenzek/duckstation"
                    ;;
            esac
        done
        echo
    fi

    if [[ ${#other[@]} -gt 0 ]]; then
        echo "📦 Other Tools:"
        for tool in "${other[@]}"; do
            echo "   • Install $tool: Check official documentation"
        done
        echo
    fi

    # Provide priority recommendations
    echo "🎯 Priority Installation Order:"
    case "$profile" in
        essential)
            echo "   1. Steam (primary gaming platform)"
            echo "   2. GameMode (performance optimization)"
            echo "   3. MangoHud (performance monitoring)"
            ;;
        standard)
            echo "   1. Steam + GameMode (core gaming)"
            echo "   2. Wine + Winetricks (Windows game compatibility)"
            echo "   3. Lutris (game management)"
            echo "   4. MangoHud (performance monitoring)"
            ;;
        advanced)
            echo "   1. Core tools: Steam, GameMode, Wine"
            echo "   2. Game launchers: Lutris, Heroic"
            echo "   3. Advanced tools: Protontricks, Bottles"
            echo "   4. Monitoring: MangoHud, GOverlay"
            ;;
        professional)
            echo "   1. Gaming foundation: Steam, Lutris, Wine"
            echo "   2. Content creation: OBS Studio, Discord"
            echo "   3. Advanced gaming: All utilities and platforms"
            ;;
        emulation)
            echo "   1. RetroArch (multi-system emulator)"
            echo "   2. PCSX2 (PlayStation 2)"
            echo "   3. Dolphin (GameCube/Wii)"
            echo "   4. Specialized emulators as needed"
            ;;
        vr)
            echo "   1. Steam + SteamVR"
            echo "   2. Wine (for VR game compatibility)"
            echo "   3. GameMode + MangoHud (performance critical)"
            ;;
    esac
}

# Generate compatibility report
generate_compatibility_report() {
    local profile="${1:-standard}"
    local format="${2:-table}"  # table, json, detailed

    check_gaming_compatibility "$profile" false

    case "$format" in
        json)
            cat << EOF
{
  "profile": "$profile",
  "compatibility_score": $COMPATIBILITY_SCORE,
  "total_tools": ${#GAMING_PROFILES[$profile]},
  "available_tools": [$(printf '"%s",' "${AVAILABLE_TOOLS[@]}" | sed 's/,$//')]
  "missing_tools": [$(printf '"%s",' "${MISSING_TOOLS[@]}" | sed 's/,$//')]
  "recommendations_available": $(if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then echo "true"; else echo "false"; fi)
}
EOF
            ;;
        detailed)
            echo "================================================"
            echo "Gaming Environment Compatibility Report"
            echo "================================================"
            echo
            echo "Profile: $profile"
            echo "Compatibility Score: $COMPATIBILITY_SCORE%"
            echo
            check_gaming_compatibility "$profile" true
            echo
            get_compatibility_recommendations "$profile"
            ;;
        table|*)
            echo "Gaming Profile Compatibility: $profile"
            echo "Score: $COMPATIBILITY_SCORE%"
            echo

            local profile_tools
            read -ra profile_tools <<< "${GAMING_PROFILES[$profile]}"

            printf "%-20s %-10s\n" "Tool" "Status"
            printf "%-20s %-10s\n" "----" "------"

            for tool in "${profile_tools[@]}"; do
                if get_cached_command "$tool"; then
                    printf "%-20s %-10s\n" "$tool" "✅"
                else
                    printf "%-20s %-10s\n" "$tool" "❌"
                fi
            done
            ;;
    esac
}

# List available gaming profiles
list_gaming_profiles() {
    init_gaming_profiles

    echo "Available Gaming Profiles:"
    echo

    for profile in "${!GAMING_PROFILES[@]}"; do
        local tools
        read -ra tools <<< "${GAMING_PROFILES[$profile]}"
        echo "  $profile: ${#tools[@]} tools (${GAMING_PROFILES[$profile]})"
    done
}

# Export functions for other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Gaming Environment Library v1.0.0"
    echo "This library should be sourced, not executed directly."
    echo ""
    echo "Available functions:"
    echo "  - detect_gaming_environment, get_gaming_environment_report"
    echo "  - is_platform_available, is_utility_available"
    echo "  - get_gaming_readiness_score, get_missing_gaming_tools"
    echo "  - check_gaming_compatibility, get_compatibility_recommendations"
    echo "  - generate_compatibility_report, list_gaming_profiles"
    exit 1
fi
