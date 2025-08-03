#!/bin/bash
# xanadOS Hardware Detection Library
# Comprehensive hardware analysis and optimization recommendations

set -euo pipefail

# Source required libraries only if they exist and we're not already in a sourced environment
if [[ -z "${XANADOS_COMMON_LOADED:-}" ]]; then
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
    if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
        source "$SCRIPT_DIR/common.sh"
    fi
    if [[ -f "$SCRIPT_DIR/validation.sh" ]]; then
        source "$SCRIPT_DIR/validation.sh"
    fi
fi

# Hardware detection cache for performance
declare -A HARDWARE_CACHE

# Initialize hardware detection
init_hardware_detection() {
    echo "Initializing hardware detection system..." >&2

    # Clear previous cache
    unset HARDWARE_CACHE 2>/dev/null || true
    declare -gA HARDWARE_CACHE

    # Cache common hardware detection commands (if available)
    if command -v cache_system_tools >/dev/null 2>&1; then
        cache_system_tools
    fi

    echo "Hardware detection system initialized" >&2
}

# CPU Detection and Analysis
detect_cpu() {
    if [[ -n "${HARDWARE_CACHE[cpu]:-}" ]]; then
        echo "${HARDWARE_CACHE[cpu]}"
        return 0
    fi

    local cpu_info=""
    local cpu_cores=""
    local cpu_threads=""
    local cpu_freq=""
    local cpu_arch=""

    # Get CPU information
    if [[ -f /proc/cpuinfo ]]; then
        cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
        cpu_cores=$(grep "cpu cores" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
        cpu_threads=$(grep "processor" /proc/cpuinfo | wc -l)
        cpu_arch=$(uname -m)
    fi

    # Get CPU frequency
    if [[ -f /proc/cpuinfo ]]; then
        cpu_freq=$(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//' | cut -d. -f1)
    fi

    # Create CPU info JSON with safe defaults
    local cpu_cores_safe="${cpu_cores:-0}"
    local cpu_threads_safe="${cpu_threads:-0}"
    local cpu_freq_safe="${cpu_freq:-0}"
    local cpu_info_safe="${cpu_info:-Unknown CPU}"
    local cpu_arch_safe="${cpu_arch:-unknown}"

    local cpu_gaming_score=$(calculate_cpu_gaming_score "$cpu_cores_safe" "$cpu_threads_safe" "$cpu_freq_safe")
    local cpu_recommendations=$(generate_cpu_recommendations "$cpu_cores_safe" "$cpu_threads_safe" "$cpu_freq_safe")

    local cpu_json=$(cat << EOF
{
    "name": "$cpu_info_safe",
    "cores": $cpu_cores_safe,
    "threads": $cpu_threads_safe,
    "frequency": $cpu_freq_safe,
    "architecture": "$cpu_arch_safe",
    "gaming_score": $cpu_gaming_score,
    "recommendations": $cpu_recommendations
}
EOF
    )

    HARDWARE_CACHE[cpu]="$cpu_json"
    echo "$cpu_json"
}

# GPU Detection and Analysis
detect_gpu() {
    if [[ -n "${HARDWARE_CACHE[gpu]:-}" ]]; then
        echo "${HARDWARE_CACHE[gpu]}"
        return 0
    fi

    local gpu_info=""
    local gpu_vendor=""
    local gpu_driver=""
    local gpu_memory=""
    local vulkan_support="false"

    # Detect GPU using lspci
    if command -v lspci >/dev/null 2>&1; then
        gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -1 | cut -d: -f3 | sed 's/^[ \t]*//')

        # Determine vendor
        if echo "$gpu_info" | grep -qi "nvidia"; then
            gpu_vendor="nvidia"
        elif echo "$gpu_info" | grep -qi "amd\|radeon"; then
            gpu_vendor="amd"
        elif echo "$gpu_info" | grep -qi "intel"; then
            gpu_vendor="intel"
        else
            gpu_vendor="unknown"
        fi
    fi

    # Check for GPU drivers
    case "$gpu_vendor" in
        "nvidia")
            if command -v nvidia-smi >/dev/null 2>&1; then
                gpu_driver="nvidia-proprietary"
                gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
            elif lsmod | grep -q nouveau; then
                gpu_driver="nouveau"
            else
                gpu_driver="none"
            fi
            ;;
        "amd")
            if lsmod | grep -q amdgpu; then
                gpu_driver="amdgpu"
            elif lsmod | grep -q radeon; then
                gpu_driver="radeon"
            else
                gpu_driver="none"
            fi
            ;;
        "intel")
            if lsmod | grep -q i915; then
                gpu_driver="i915"
            else
                gpu_driver="none"
            fi
            ;;
    esac

    # Check Vulkan support
    if command -v vulkaninfo >/dev/null 2>&1; then
        if vulkaninfo >/dev/null 2>&1; then
            vulkan_support="true"
        fi
    fi

    # Create GPU info JSON with safe defaults
    local gpu_info_safe="${gpu_info:-Unknown GPU}"
    local gpu_vendor_safe="${gpu_vendor:-unknown}"
    local gpu_driver_safe="${gpu_driver:-none}"
    local gpu_memory_safe="${gpu_memory:-0}"

    local gpu_gaming_score=$(calculate_gpu_gaming_score "$gpu_vendor_safe" "$gpu_driver_safe" "$vulkan_support")
    local gpu_recommendations=$(generate_gpu_recommendations "$gpu_vendor_safe" "$gpu_driver_safe" "$vulkan_support")

    local gpu_json=$(cat << EOF
{
    "name": "$gpu_info_safe",
    "vendor": "$gpu_vendor_safe",
    "driver": "$gpu_driver_safe",
    "memory": "$gpu_memory_safe",
    "vulkan_support": $vulkan_support,
    "gaming_score": $gpu_gaming_score,
    "recommendations": $gpu_recommendations
}
EOF
    )

    HARDWARE_CACHE[gpu]="$gpu_json"
    echo "$gpu_json"
}

# Memory Detection and Analysis
detect_memory() {
    if [[ -n "${HARDWARE_CACHE[memory]:-}" ]]; then
        echo "${HARDWARE_CACHE[memory]}"
        return 0
    fi

    local total_memory=""
    local available_memory=""
    local swap_total=""
    local memory_type=""

    # Get memory information
    if [[ -f /proc/meminfo ]]; then
        total_memory=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        available_memory=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
        swap_total=$(grep "SwapTotal" /proc/meminfo | awk '{print $2}')
    fi

    # Convert to GB safely
    local total_gb=0
    local available_gb=0
    local swap_gb=0

    if [[ -n "$total_memory" && "$total_memory" -gt 0 ]]; then
        total_gb=$((total_memory / 1024 / 1024))
    fi
    if [[ -n "$available_memory" && "$available_memory" -gt 0 ]]; then
        available_gb=$((available_memory / 1024 / 1024))
    fi
    if [[ -n "$swap_total" && "$swap_total" -gt 0 ]]; then
        swap_gb=$((swap_total / 1024 / 1024))
    fi

    # Detect memory type (basic detection)
    local memory_type="unknown"
    if [[ -f /sys/devices/system/memory/memory0/valid_zones ]]; then
        memory_type="DDR"
    fi

    local memory_gaming_score=$(calculate_memory_gaming_score "$total_gb")
    local memory_recommendations=$(generate_memory_recommendations "$total_gb" "$swap_gb")

    # Create memory info JSON
    local memory_json=$(cat << EOF
{
    "total_gb": $total_gb,
    "available_gb": $available_gb,
    "swap_gb": $swap_gb,
    "type": "$memory_type",
    "gaming_score": $memory_gaming_score,
    "recommendations": $memory_recommendations
}
EOF
    )

    HARDWARE_CACHE[memory]="$memory_json"
    echo "$memory_json"
}

# Storage Detection and Analysis
detect_storage() {
    if [[ -n "${HARDWARE_CACHE[storage]:-}" ]]; then
        echo "${HARDWARE_CACHE[storage]}"
        return 0
    fi

    local storage_devices=()
    local root_device=""
    local root_type=""

    # Get storage device information
    if command -v lsblk >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                storage_devices+=("$line")
            fi
        done < <(lsblk -d -o NAME,SIZE,TYPE,MODEL --json | jq -r '.blockdevices[] | select(.type=="disk") | "\(.name),\(.size),\(.model // "Unknown")"')
    fi

    # Get root filesystem information
    local root_device=""
    local root_type="unknown"

    root_device=$(df / 2>/dev/null | tail -1 | awk '{print $1}' || echo "unknown")
    if command -v lsblk >/dev/null 2>&1 && [[ "$root_device" != "unknown" ]]; then
        root_type=$(lsblk -no FSTYPE "$root_device" 2>/dev/null | head -1 || echo "unknown")
    fi

    local storage_gaming_score=$(calculate_storage_gaming_score "${storage_devices[@]}")
    local storage_recommendations=$(generate_storage_recommendations "$root_type" "${storage_devices[@]}")

    # Create storage info JSON
    local storage_json=$(cat << EOF
{
    "devices": [],
    "root_device": "$root_device",
    "root_filesystem": "$root_type",
    "gaming_score": $storage_gaming_score,
    "recommendations": $storage_recommendations
}
EOF
    )

    HARDWARE_CACHE[storage]="$storage_json"
    echo "$storage_json"
}

# Gaming Score Calculations
calculate_cpu_gaming_score() {
    local cores="${1:-0}"
    local threads="${2:-0}"
    local freq="${3:-0}"

    local score=0

    # Core count scoring (max 30 points)
    if [[ "$cores" -ge 8 ]]; then
        score=$((score + 30))
    elif [[ "$cores" -ge 6 ]]; then
        score=$((score + 25))
    elif [[ "$cores" -ge 4 ]]; then
        score=$((score + 20))
    else
        score=$((score + 10))
    fi

    # Thread count scoring (max 20 points)
    if [[ "$threads" -ge 16 ]]; then
        score=$((score + 20))
    elif [[ "$threads" -ge 12 ]]; then
        score=$((score + 15))
    elif [[ "$threads" -ge 8 ]]; then
        score=$((score + 10))
    else
        score=$((score + 5))
    fi

    # Frequency scoring (max 50 points)
    if [[ "$freq" -gt 4000 ]]; then
        score=$((score + 50))
    elif [[ "$freq" -gt 3500 ]]; then
        score=$((score + 40))
    elif [[ "$freq" -gt 3000 ]]; then
        score=$((score + 30))
    elif [[ "$freq" -gt 2500 ]]; then
        score=$((score + 20))
    else
        score=$((score + 10))
    fi

    echo "$score"
}

calculate_gpu_gaming_score() {
    local vendor="$1"
    local driver="$2"
    local vulkan="$3"

    local score=0

    # Vendor and driver scoring
    case "$vendor" in
        "nvidia")
            if [[ "$driver" == "nvidia-proprietary" ]]; then
                score=$((score + 40))
            else
                score=$((score + 20))
            fi
            ;;
        "amd")
            if [[ "$driver" == "amdgpu" ]]; then
                score=$((score + 35))
            else
                score=$((score + 15))
            fi
            ;;
        "intel")
            score=$((score + 25))
            ;;
        *)
            score=$((score + 10))
            ;;
    esac

    # Vulkan support bonus
    if [[ "$vulkan" == "true" ]]; then
        score=$((score + 30))
    fi

    # Driver availability bonus
    if [[ "$driver" != "none" ]]; then
        score=$((score + 30))
    fi

    echo "$score"
}

calculate_memory_gaming_score() {
    local total_gb="$1"

    local score=0

    if [[ "$total_gb" -ge 32 ]]; then
        score=100
    elif [[ "$total_gb" -ge 16 ]]; then
        score=90
    elif [[ "$total_gb" -ge 12 ]]; then
        score=75
    elif [[ "$total_gb" -ge 8 ]]; then
        score=60
    elif [[ "$total_gb" -ge 4 ]]; then
        score=40
    else
        score=20
    fi

    echo "$score"
}

calculate_storage_gaming_score() {
    local devices=("$@")
    local score=50

    # Check for SSD indicators in device information
    for device in "${devices[@]}"; do
        if echo "$device" | grep -qi "ssd\|nvme"; then
            score=100
            break
        fi
    done

    echo "$score"
}

# Recommendation Generators
generate_cpu_recommendations() {
    local cores="${1:-0}"
    local threads="${2:-0}"
    local freq="${3:-0}"

    local recommendations=()

    if [[ "$cores" -lt 4 ]]; then
        recommendations+=("\"Consider upgrading to a CPU with at least 4 cores for modern gaming\"")
    fi

    if [[ "$freq" -lt 3000 ]]; then
        recommendations+=("\"Enable CPU performance governor for gaming sessions\"")
        recommendations+=("\"Consider CPU overclocking if supported and safe\"")
    fi

    if [[ "$threads" -lt 8 ]]; then
        recommendations+=("\"Some modern games benefit from 8+ threads\"")
    fi

    recommendations+=("\"Install cpu-x or similar tool for detailed CPU monitoring\"")

    echo "[$(IFS=,; echo "${recommendations[*]}")]"
}

generate_gpu_recommendations() {
    local vendor="$1"
    local driver="$2"
    local vulkan="$3"

    local recommendations=()

    case "$vendor" in
        "nvidia")
            if [[ "$driver" != "nvidia-proprietary" ]]; then
                recommendations+=("\"Install NVIDIA proprietary drivers for best gaming performance\"")
                recommendations+=("\"Run: sudo pacman -S nvidia nvidia-utils nvidia-settings\"")
            else
                recommendations+=("\"NVIDIA drivers detected - ensure they are up to date\"")
            fi
            ;;
        "amd")
            if [[ "$driver" != "amdgpu" ]]; then
                recommendations+=("\"Ensure AMDGPU driver is loaded for modern AMD GPUs\"")
                recommendations+=("\"Run: sudo pacman -S mesa vulkan-radeon\"")
            else
                recommendations+=("\"AMD drivers detected - install additional Vulkan support\"")
                recommendations+=("\"Run: sudo pacman -S vulkan-radeon lib32-vulkan-radeon\"")
            fi
            ;;
        "intel")
            recommendations+=("\"Intel integrated graphics detected\"")
            recommendations+=("\"Run: sudo pacman -S mesa vulkan-intel lib32-vulkan-intel\"")
            ;;
    esac

    if [[ "$vulkan" != "true" ]]; then
        recommendations+=("\"Install Vulkan support for modern gaming performance\"")
        recommendations+=("\"Run: sudo pacman -S vulkan-tools\"")
    fi

    echo "[$(IFS=,; echo "${recommendations[*]}")]"
}

generate_memory_recommendations() {
    local total_gb="$1"
    local swap_gb="$2"

    local recommendations=()

    if [[ "$total_gb" -lt 8 ]]; then
        recommendations+=("\"8GB RAM minimum recommended for modern gaming\"")
        recommendations+=("\"Consider upgrading to 16GB for optimal performance\"")
    elif [[ "$total_gb" -lt 16 ]]; then
        recommendations+=("\"Consider upgrading to 16GB for optimal gaming performance\"")
    fi

    if [[ "$swap_gb" -eq 0 ]]; then
        recommendations+=("\"Configure swap space for memory management\"")
        recommendations+=("\"Consider zram for compressed swap\"")
    fi

    recommendations+=("\"Enable zswap for improved memory management\"")
    recommendations+=("\"Set vm.swappiness=10 for gaming workloads\"")

    echo "[$(IFS=,; echo "${recommendations[*]}")]"
}

generate_storage_recommendations() {
    local root_type="$1"
    shift
    local devices=("$@")

    local recommendations=()
    local has_ssd=false

    # Check for SSD
    for device in "${devices[@]}"; do
        if echo "$device" | grep -qi "ssd\|nvme"; then
            has_ssd=true
            break
        fi
    done

    if [[ "$has_ssd" == "false" ]]; then
        recommendations+=("\"Consider upgrading to SSD for significantly better gaming performance\"")
        recommendations+=("\"SSDs reduce game loading times by 50-80%\"")
    fi

    if [[ "$root_type" != "btrfs" ]] && [[ "$root_type" != "ext4" ]]; then
        recommendations+=("\"Consider btrfs or ext4 for optimal gaming performance\"")
    fi

    if [[ "$root_type" == "btrfs" ]]; then
        recommendations+=("\"Enable btrfs compression for better performance: mount -o compress=zstd\"")
    fi

    recommendations+=("\"Ensure TRIM is enabled for SSDs\"")
    recommendations+=("\"Use deadline or mq-deadline I/O scheduler for gaming\"")

    echo "[$(IFS=,; echo "${recommendations[*]}")]"
}

# Comprehensive Hardware Analysis
analyze_hardware() {
    local output_format="${1:-table}"

    echo "Performing comprehensive hardware analysis..." >&2

    # Initialize detection
    init_hardware_detection

    # Detect all hardware components
    local cpu_data=$(detect_cpu)
    local gpu_data=$(detect_gpu)
    local memory_data=$(detect_memory)
    local storage_data=$(detect_storage)

    # Calculate overall gaming score (safely handle missing values)
    local cpu_score=$(echo "$cpu_data" | jq -r '.gaming_score // 0' 2>/dev/null || echo "0")
    local gpu_score=$(echo "$gpu_data" | jq -r '.gaming_score // 0' 2>/dev/null || echo "0")
    local memory_score=$(echo "$memory_data" | jq -r '.gaming_score // 0' 2>/dev/null || echo "0")
    local storage_score=$(echo "$storage_data" | jq -r '.gaming_score // 0' 2>/dev/null || echo "0")

    local overall_score=$(( (cpu_score + gpu_score + memory_score + storage_score) / 4 ))

    # Generate output based on format
    case "$output_format" in
        "json")
            cat << EOF
{
    "analysis_date": "$(date -Iseconds)",
    "overall_gaming_score": $overall_score,
    "cpu": $cpu_data,
    "gpu": $gpu_data,
    "memory": $memory_data,
    "storage": $storage_data,
    "gaming_readiness": "$(get_gaming_readiness_level "$overall_score")"
}
EOF
            ;;
        "table")
            echo ""
            echo "🖥️  xanadOS Hardware Analysis Report"
            echo "======================================"
            echo ""
            echo "📊 Overall Gaming Score: $overall_score/100 ($(get_gaming_readiness_level "$overall_score"))"
            echo ""

            echo "🔧 CPU Analysis:"
            echo "  Name: $(echo "$cpu_data" | jq -r '.name')"
            echo "  Cores/Threads: $(echo "$cpu_data" | jq -r '.cores')/$(echo "$cpu_data" | jq -r '.threads')"
            echo "  Frequency: $(echo "$cpu_data" | jq -r '.frequency') MHz"
            echo "  Gaming Score: $(echo "$cpu_data" | jq -r '.gaming_score')/100"
            echo ""

            echo "🎮 GPU Analysis:"
            echo "  Name: $(echo "$gpu_data" | jq -r '.name')"
            echo "  Vendor: $(echo "$gpu_data" | jq -r '.vendor')"
            echo "  Driver: $(echo "$gpu_data" | jq -r '.driver')"
            echo "  Vulkan Support: $(echo "$gpu_data" | jq -r '.vulkan_support')"
            echo "  Gaming Score: $(echo "$gpu_data" | jq -r '.gaming_score')/100"
            echo ""

            echo "💾 Memory Analysis:"
            echo "  Total Memory: $(echo "$memory_data" | jq -r '.total_gb') GB"
            echo "  Available: $(echo "$memory_data" | jq -r '.available_gb') GB"
            echo "  Swap: $(echo "$memory_data" | jq -r '.swap_gb') GB"
            echo "  Gaming Score: $(echo "$memory_data" | jq -r '.gaming_score')/100"
            echo ""

            echo "💿 Storage Analysis:"
            echo "  Root Filesystem: $(echo "$storage_data" | jq -r '.root_filesystem')"
            echo "  Gaming Score: $(echo "$storage_data" | jq -r '.gaming_score')/100"
            echo ""

            echo "🎯 Recommendations:"
            echo "$cpu_data" | jq -r '.recommendations[]' | sed 's/^/  • /'
            echo "$gpu_data" | jq -r '.recommendations[]' | sed 's/^/  • /'
            echo "$memory_data" | jq -r '.recommendations[]' | sed 's/^/  • /'
            echo "$storage_data" | jq -r '.recommendations[]' | sed 's/^/  • /'
            echo ""
            ;;
        *)
            log_error "Unsupported output format: $output_format"
            return 1
            ;;
    esac

    echo "Hardware analysis complete" >&2
}

# Get gaming readiness level
get_gaming_readiness_level() {
    local score="$1"

    if [[ "$score" -ge 85 ]]; then
        echo "Excellent"
    elif [[ "$score" -ge 70 ]]; then
        echo "Good"
    elif [[ "$score" -ge 55 ]]; then
        echo "Fair"
    elif [[ "$score" -ge 40 ]]; then
        echo "Basic"
    else
        echo "Needs Improvement"
    fi
}

# Quick hardware summary
hardware_summary() {
    # Get components individually and extract data safely
    local cpu_name="Unknown CPU"
    local gpu_name="Unknown GPU"
    local memory_gb="0"
    local overall_score="0"

    # Get CPU name safely
    local cpu_data=$(detect_cpu 2>/dev/null)
    if [[ -n "$cpu_data" ]]; then
        cpu_name=$(echo "$cpu_data" | jq -r '.name // "Unknown CPU"' 2>/dev/null | cut -d' ' -f1-3)
    fi

    # Get GPU name safely
    local gpu_data=$(detect_gpu 2>/dev/null)
    if [[ -n "$gpu_data" ]]; then
        gpu_name=$(echo "$gpu_data" | jq -r '.name // "Unknown GPU"' 2>/dev/null | cut -d' ' -f1-3)
    fi

    # Get memory safely
    local memory_data=$(detect_memory 2>/dev/null)
    if [[ -n "$memory_data" ]]; then
        memory_gb=$(echo "$memory_data" | jq -r '.total_gb // 0' 2>/dev/null)
    fi

    # Calculate simple overall score from individual components
    local cpu_score=$(echo "$cpu_data" | jq -r '.gaming_score // 0' 2>/dev/null)
    local gpu_score=$(echo "$gpu_data" | jq -r '.gaming_score // 0' 2>/dev/null)
    local memory_score=$(echo "$memory_data" | jq -r '.gaming_score // 0' 2>/dev/null)
    local storage_score=50  # Simple default for summary

    overall_score=$(( (cpu_score + gpu_score + memory_score + storage_score) / 4 ))

    echo "💻 Hardware: $cpu_name | $gpu_name | ${memory_gb}GB RAM | Gaming Score: $overall_score/100"
}

# Main function for command-line usage
main() {
    local action="${1:-summary}"
    local format="${2:-table}"

    case "$action" in
        "analyze"|"analysis")
            analyze_hardware "$format"
            ;;
        "cpu")
            detect_cpu | jq .
            ;;
        "gpu")
            detect_gpu | jq .
            ;;
        "memory"|"ram")
            detect_memory | jq .
            ;;
        "storage"|"disk")
            detect_storage | jq .
            ;;
        "summary")
            hardware_summary
            ;;
        "help"|"h"|*)
            cat << EOF
xanadOS Hardware Detection Library
=================================

Usage: $0 <action> [format]

Actions:
  analyze|analysis  Full hardware analysis and recommendations
  cpu              CPU detection and analysis
  gpu              GPU detection and analysis
  memory|ram       Memory detection and analysis
  storage|disk     Storage detection and analysis
  summary          Quick hardware summary
  help|h           Show this help

Formats (for analyze):
  table (default)  Human-readable table format
  json             JSON format for scripting

Examples:
  $0 analyze
  $0 analyze json
  $0 cpu
  $0 summary

Notes:
- Requires jq for JSON processing
- Some features require root access for full hardware detection
- Gaming scores range from 0-100 for each component
EOF
            ;;
    esac
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
