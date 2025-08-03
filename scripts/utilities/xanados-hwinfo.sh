#!/bin/bash
# xanadOS Hardware Information and Optimization Status
# Personal Use License - see LICENSE file

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    xanadOS Hardware Info                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "${BLUE}${BOLD}=== $1 ===${NC}"
}

check_optimization_status() {
    local status="❌ Not Applied"
    if [[ -f /etc/xanados/hardware-params.conf ]]; then
        status="✅ Applied"
    fi
    echo -e "${BOLD}Optimization Status:${NC} $status"
}

show_cpu_info() {
    print_section "CPU Information"

    local cpu_model vendor cores threads
    cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    vendor=$(lscpu | grep "Vendor ID" | cut -d: -f2 | xargs)
    cores=$(lscpu | grep "Core(s) per socket" | cut -d: -f2 | xargs)
    threads=$(lscpu | grep "Thread(s) per core" | cut -d: -f2 | xargs)

    echo -e "${BOLD}Model:${NC} $cpu_model"
    echo -e "${BOLD}Vendor:${NC} $vendor"
    echo -e "${BOLD}Cores:${NC} $cores"
    echo -e "${BOLD}Threads per Core:${NC} $threads"
    echo -e "${BOLD}Total Threads:${NC} $(nproc)"

    # CPU Governor Status
    local governor
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    local gov_color="${RED}"
    [[ "$governor" == "performance" ]] && gov_color="${GREEN}"
    echo -e "${BOLD}Current Governor:${NC} ${gov_color}$governor${NC}"

    # CPU Frequency
    local freq
    freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "0")
    if [[ $freq -gt 0 ]]; then
        freq_mhz=$((freq / 1000))
        echo -e "${BOLD}Current Frequency:${NC} ${freq_mhz} MHz"
    fi

    echo
}

show_gpu_info() {
    print_section "GPU Information"

    local gpu_info
    gpu_info=$(lspci | grep -i "vga\|3d\|display")

    if [[ -n "$gpu_info" ]]; then
        echo -e "${BOLD}Detected GPUs:${NC}"
        echo "$gpu_info" | while read -r line; do
            echo "  • $line"
        done
    else
        echo "No GPU detected"
    fi

    # NVIDIA specific info
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "${BOLD}NVIDIA GPU Status:${NC}"
        nvidia-smi --query-gpu=name,temperature.gpu,power.draw,clocks.gr,clocks.mem --format=csv,noheader,nounits 2>/dev/null | while IFS=',' read -r name temp power gpu_clock mem_clock; do
            echo "  • Name: $name"
            echo "  • Temperature: ${temp}°C"
            echo "  • Power: ${power}W"
            echo "  • GPU Clock: ${gpu_clock} MHz"
            echo "  • Memory Clock: ${mem_clock} MHz"
        done
    fi

    echo
}

show_memory_info() {
    print_section "Memory Information"

    local total_mem available_mem used_mem
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    available_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    used_mem=$((total_mem - available_mem))

    # Convert to GB
    total_gb=$((total_mem / 1024 / 1024))
    available_gb=$((available_mem / 1024 / 1024))
    used_gb=$((used_mem / 1024 / 1024))

    echo -e "${BOLD}Total RAM:${NC} ${total_gb}GB"
    echo -e "${BOLD}Used RAM:${NC} ${used_gb}GB"
    echo -e "${BOLD}Available RAM:${NC} ${available_gb}GB"

    # Memory usage percentage
    local usage_percent
    usage_percent=$((used_mem * 100 / total_mem))
    local mem_color="${GREEN}"
    [[ $usage_percent -gt 80 ]] && mem_color="${RED}"
    [[ $usage_percent -gt 60 ]] && [[ $usage_percent -le 80 ]] && mem_color="${YELLOW}"
    echo -e "${BOLD}Memory Usage:${NC} ${mem_color}${usage_percent}%${NC}"

    echo
}

show_swap_info() {
    print_section "Swap Information"

    local swap_info
    swap_info=$(swapon --show 2>/dev/null)

    if [[ -n "$swap_info" ]]; then
        echo -e "${BOLD}Active Swap Devices:${NC}"
        echo "$swap_info"

        # Check for zram
        if echo "$swap_info" | grep -q zram; then
            echo -e "${GREEN}✅ zram compression active${NC}"
        fi
    else
        echo "No swap devices active"
    fi

    # Swappiness setting
    local swappiness
    swappiness=$(cat /proc/sys/vm/swappiness)
    local swap_color="${GREEN}"
    [[ $swappiness -gt 10 ]] && swap_color="${YELLOW}"
    [[ $swappiness -gt 60 ]] && swap_color="${RED}"
    echo -e "${BOLD}Swappiness:${NC} ${swap_color}$swappiness${NC}"

    echo
}

show_gaming_optimizations() {
    print_section "Gaming Optimizations"

    # GameMode status
    if command -v gamemoded >/dev/null 2>&1; then
        if systemctl is-active --quiet gamemoded; then
            echo -e "${GREEN}✅ GameMode service active${NC}"
        else
            echo -e "${RED}❌ GameMode service inactive${NC}"
        fi
    else
        echo -e "${RED}❌ GameMode not installed${NC}"
    fi

    # Check for gaming-specific kernel parameters
    local cmdline
    cmdline=$(cat /proc/cmdline)

    echo -e "${BOLD}Gaming Kernel Parameters:${NC}"

    # Check mitigations
    if echo "$cmdline" | grep -q "mitigations="; then
        local mitigation
        mitigation=$(echo "$cmdline" | grep -o "mitigations=[^ ]*" | cut -d= -f2)
        case "$mitigation" in
            "off") echo -e "  • Mitigations: ${YELLOW}$mitigation (max performance, security risk)${NC}" ;;
            "auto") echo -e "  • Mitigations: ${GREEN}$mitigation (balanced)${NC}" ;;
            *) echo -e "  • Mitigations: ${CYAN}$mitigation${NC}" ;;
        esac
    else
        echo -e "  • Mitigations: ${CYAN}default${NC}"
    fi

    # Check max_map_count for gaming
    local max_map_count
    max_map_count=$(cat /proc/sys/vm/max_map_count)
    if [[ $max_map_count -ge 2147483642 ]]; then
        echo -e "  • VM Max Map Count: ${GREEN}$max_map_count (optimized)${NC}"
    else
        echo -e "  • VM Max Map Count: ${YELLOW}$max_map_count (default)${NC}"
    fi

    echo
}

show_thermal_info() {
    print_section "Thermal Information"

    # CPU temperature (if available)
    if [[ -d /sys/class/hwmon ]]; then
        local temp_found=false
        for hwmon in /sys/class/hwmon/hwmon*; do
            if [[ -f "$hwmon/temp1_input" ]]; then
                local temp
                temp=$(cat "$hwmon/temp1_input")
                temp_c=$((temp / 1000))
                local temp_color="${GREEN}"
                [[ $temp_c -gt 70 ]] && temp_color="${YELLOW}"
                [[ $temp_c -gt 85 ]] && temp_color="${RED}"
                echo -e "${BOLD}CPU Temperature:${NC} ${temp_color}${temp_c}°C${NC}"
                temp_found=true
                break
            fi
        done
        [[ $temp_found == false ]] && echo "CPU temperature sensors not available"
    fi

    echo
}

show_optimization_suggestions() {
    print_section "Optimization Suggestions"

    local suggestions=()

    # Check if hardware optimization has been run
    if [[ ! -f /etc/xanados/hardware-params.conf ]]; then
        suggestions+=("Run hardware optimization: sudo /usr/local/bin/xanados-hardware-optimization.sh")
    fi

    # Check CPU governor
    local governor
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    if [[ "$governor" != "performance" ]]; then
        suggestions+=("Set CPU governor to performance for gaming")
    fi

    # Check GameMode
    if ! command -v gamemoded >/dev/null 2>&1; then
        suggestions+=("Install GameMode for per-game optimizations")
    fi

    # Check zram
    if ! swapon --show | grep -q zram; then
        suggestions+=("Enable zram for better memory management")
    fi

    if [[ ${#suggestions[@]} -eq 0 ]]; then
        echo -e "${GREEN}✅ System appears well optimized for gaming!${NC}"
    else
        echo -e "${YELLOW}💡 Suggested optimizations:${NC}"
        for suggestion in "${suggestions[@]}"; do
            echo "  • $suggestion"
        done
    fi

    echo
}

main() {
    print_header
    check_optimization_status
    echo
    show_cpu_info
    show_gpu_info
    show_memory_info
    show_swap_info
    show_gaming_optimizations
    show_thermal_info
    show_optimization_suggestions
}

main "$@"
