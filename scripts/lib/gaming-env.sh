#!/bin/bash
# xanadOS Gaming Environment Detection Library
# Centralized gaming tool detection and environment management
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_GAMING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_GAMING_LOADED="true"

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/validation.sh"

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
    
    print_debug "Detecting gaming environment..."
    
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
    detect_audio_system
    
    # Mark detection as complete
    GAMING_ENV_CACHE["detected"]="true"
    GAMING_ENV_CACHE["detection_time"]="$(date +%s)"
    
    print_debug "Gaming environment detection completed"
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
        if lsmod | grep -q "amdgpu"; then
            driver="amdgpu"
        elif lsmod | grep -q "radeon"; then
            driver="radeon"
        fi
    elif lspci | grep -qi intel; then
        gpu_type="intel"
        driver="intel"
    fi
    
    GAMING_ENV_CACHE["gpu_type"]="$gpu_type"
    GAMING_ENV_CACHE["gpu_driver"]="$driver"
}

# Detect audio system
detect_audio_system() {
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
    print_debug "Gaming environment cache cleared"
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

# Export functions for other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Gaming Environment Library v1.0.0"
    echo "This library should be sourced, not executed directly."
    echo ""
    echo "Available functions:"
    echo "  - detect_gaming_environment, get_gaming_environment_report"
    echo "  - is_platform_available, is_utility_available"
    echo "  - get_gaming_readiness_score, get_missing_gaming_tools"
    exit 1
fi
