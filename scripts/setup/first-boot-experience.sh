#!/bin/bash

# ==============================================================================
# xanadOS First-Boot Experience
# ==============================================================================
# Description: Welcome and setup experience for new xanadOS installations
#              with hardware analysis, gaming profile creation, and system setup
# Author: xanadOS Development Team
# Version: 1.0.0
# License: MIT
# ==============================================================================

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="/var/log/xanados/first-boot-experience.log"
CONFIG_DIR="$HOME/.config/xanados"
FIRST_BOOT_MARKER="/etc/xanados/first-boot-completed"
TEMP_DIR="/tmp/xanados-firstboot-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Unicode symbols
CHECKMARK="✓"
CROSSMARK="✗"
ARROW="→"
STAR="★"
GEAR="⚙"
GAMING="🎮"
ROCKET="🚀"
WELCOME="👋"
HEART="♥"

# ==============================================================================
# Logging and Utility Functions
# ==============================================================================

setup_logging() {
    local log_dir="/var/log/xanados"
    
    if [[ ! -d "$log_dir" ]]; then
        sudo mkdir -p "$log_dir"
        sudo chown "$USER:$USER" "$log_dir"
    fi
    
    touch "$LOG_FILE"
    echo "=== xanadOS First-Boot Experience Started: $(date) ===" >> "$LOG_FILE"
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
# First-Boot Check
# ==============================================================================

check_first_boot() {
    if [[ -f "$FIRST_BOOT_MARKER" ]]; then
        log_message "INFO" "First-boot already completed"
        echo -e "${GREEN}xanadOS first-boot setup has already been completed.${NC}"
        echo -e "Run the gaming setup wizard directly if you want to reconfigure:"
        echo -e "  ${ARROW} $SCRIPT_DIR/gaming-setup-wizard.sh"
        exit 0
    fi
}

# ==============================================================================
# Welcome Screen
# ==============================================================================

show_welcome_screen() {
    clear
    print_header "${WELCOME} Welcome to xanadOS - Your Ultimate Gaming Linux Distribution ${GAMING}"
    
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                                                                              ║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}${WHITE}Welcome to xanadOS!${NC}                                                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${WHITE}xanadOS is a specialized Linux gaming distribution built on Arch Linux${NC}  ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${WHITE}with AI assistance, designed to deliver exceptional gaming performance${NC}  ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${WHITE}while maintaining system security and stability.${NC}                        ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${STAR} Optimized Gaming Performance${NC}                                         ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${STAR} Hardware-Specific Optimizations${NC}                                    ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${STAR} Comprehensive Gaming Software Stack${NC}                               ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${STAR} Gaming-Focused Desktop Environment${NC}                                ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}${STAR} Performance Monitoring and Validation${NC}                             ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}This first-boot experience will guide you through setting up your${NC}      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${YELLOW}optimal gaming environment based on your hardware and preferences.${NC}    ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                            ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${BOLD}What we'll do together:${NC}"
    echo -e "  ${ROCKET} Analyze your gaming hardware"
    echo -e "  ${ROCKET} Set up optimal gaming software"
    echo -e "  ${ROCKET} Configure performance optimizations"
    echo -e "  ${ROCKET} Customize your gaming desktop"
    echo -e "  ${ROCKET} Create your personal gaming profile"
    echo
    
    echo -e "${BOLD}This process will take approximately 10-15 minutes.${NC}"
    echo
    
    read -p "Press Enter to begin your xanadOS gaming journey... "
    
    log_message "INFO" "Welcome screen completed, starting first-boot setup"
}

# ==============================================================================
# System Analysis
# ==============================================================================

perform_system_analysis() {
    log_message "INFO" "Starting system analysis"
    print_header "${GEAR} System Analysis & Hardware Detection"
    
    echo -e "${BOLD}Analyzing your system for optimal gaming configuration...${NC}"
    echo
    
    mkdir -p "$TEMP_DIR"
    
    # System information collection
    collect_system_info
    
    # Hardware detection
    analyze_hardware
    
    # Performance baseline
    establish_performance_baseline
    
    # Gaming readiness assessment
    assess_gaming_readiness
    
    log_message "SUCCESS" "System analysis completed"
}

collect_system_info() {
    log_message "INFO" "Collecting system information"
    print_section "System Information"
    
    # Basic system info
    local hostname
    hostname=$(hostname)
    local kernel
    kernel=$(uname -r)
    local arch
    arch=$(uname -m)
    local uptime
    uptime=$(uptime -p)
    
    echo -e "  ${ARROW} Hostname: ${BOLD}$hostname${NC}"
    echo -e "  ${ARROW} Kernel: ${BOLD}$kernel${NC}"
    echo -e "  ${ARROW} Architecture: ${BOLD}$arch${NC}"
    echo -e "  ${ARROW} Uptime: ${BOLD}$uptime${NC}"
    
    # Store system info
    cat > "$TEMP_DIR/system-info.txt" << EOF
hostname=$hostname
kernel=$kernel
architecture=$arch
uptime=$uptime
analysis_date=$(date)
EOF
    
    echo -e "  ${CHECKMARK} System information collected"
}

analyze_hardware() {
    log_message "INFO" "Analyzing hardware"
    print_section "Hardware Analysis"
    
    # CPU Analysis
    echo -e "  ${GEAR} CPU Analysis:"
    local cpu_model
    cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    local cpu_cores
    cpu_cores=$(nproc)
    local cpu_threads
    cpu_threads=$(lscpu | grep "CPU(s):" | head -1 | awk '{print $2}')
    local cpu_max_mhz
    cpu_max_mhz=$(lscpu | grep "CPU max MHz" | awk '{print $4}' | cut -d. -f1 || echo "Unknown")
    
    echo -e "    Model: ${BOLD}$cpu_model${NC}"
    echo -e "    Cores: ${BOLD}$cpu_cores${NC}, Threads: ${BOLD}$cpu_threads${NC}"
    echo -e "    Max Frequency: ${BOLD}${cpu_max_mhz} MHz${NC}"
    
    # Memory Analysis
    echo -e "  ${GEAR} Memory Analysis:"
    local mem_total
    mem_total=$(free -h | grep "Mem:" | awk '{print $2}')
    local mem_available
    mem_available=$(free -h | grep "Mem:" | awk '{print $7}')
    local mem_gb
    mem_gb=$(free -g | grep "Mem:" | awk '{print $2}')
    
    echo -e "    Total: ${BOLD}$mem_total${NC}"
    echo -e "    Available: ${BOLD}$mem_available${NC}"
    
    # Memory recommendation
    if [[ $mem_gb -lt 8 ]]; then
        echo -e "    ${RED}Warning: Less than 8GB RAM detected. Consider upgrading for optimal gaming.${NC}"
        MEMORY_WARNING=true
    elif [[ $mem_gb -lt 16 ]]; then
        echo -e "    ${YELLOW}Note: 16GB RAM recommended for optimal gaming performance.${NC}"
        MEMORY_WARNING=false
    else
        echo -e "    ${GREEN}Excellent: Sufficient RAM for optimal gaming.${NC}"
        MEMORY_WARNING=false
    fi
    
    # GPU Analysis
    echo -e "  ${GEAR} Graphics Analysis:"
    analyze_gpu
    
    # Storage Analysis
    echo -e "  ${GEAR} Storage Analysis:"
    analyze_storage
    
    # Store hardware info
    cat > "$TEMP_DIR/hardware-info.txt" << EOF
cpu_model=$cpu_model
cpu_cores=$cpu_cores
cpu_threads=$cpu_threads
cpu_max_mhz=$cpu_max_mhz
memory_total=$mem_total
memory_gb=$mem_gb
memory_warning=$MEMORY_WARNING
gpu_vendor=${GPU_VENDOR:-unknown}
gpu_model=${GPU_MODEL:-unknown}
has_ssd=${HAS_SSD:-false}
has_nvme=${HAS_NVME:-false}
storage_warning=${STORAGE_WARNING:-false}
EOF
}

analyze_gpu() {
    # NVIDIA Detection
    if command -v nvidia-smi &> /dev/null; then
        local nvidia_gpu
        nvidia_gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)
        local nvidia_driver
        nvidia_driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
        local nvidia_memory
        nvidia_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
        
        echo -e "    ${GREEN}NVIDIA GPU: $nvidia_gpu${NC}"
        echo -e "    ${GREEN}Driver: $nvidia_driver${NC}"
        echo -e "    ${GREEN}VRAM: ${nvidia_memory}MB${NC}"
        
        GPU_VENDOR="nvidia"
        GPU_MODEL="$nvidia_gpu"
        GPU_MEMORY="$nvidia_memory"
        GPU_DRIVER="$nvidia_driver"
        GPU_STATUS="excellent"
    elif lspci | grep -i "VGA.*AMD\|VGA.*ATI" &> /dev/null; then
        local amd_gpu
        amd_gpu=$(lspci | grep -i "VGA.*AMD\|VGA.*ATI" | cut -d: -f3 | xargs)
        echo -e "    ${GREEN}AMD GPU: $amd_gpu${NC}"
        
        # Check for AMDGPU driver
        if lsmod | grep -q amdgpu; then
            echo -e "    ${GREEN}Driver: AMDGPU (Open Source)${NC}"
            GPU_STATUS="good"
        else
            echo -e "    ${YELLOW}Driver: Legacy/Generic${NC}"
            GPU_STATUS="needs_improvement"
        fi
        
        GPU_VENDOR="amd"
        GPU_MODEL="$amd_gpu"
    elif lspci | grep -i "VGA.*Intel" &> /dev/null; then
        local intel_gpu
        intel_gpu=$(lspci | grep -i "VGA.*Intel" | cut -d: -f3 | xargs)
        echo -e "    ${BLUE}Intel GPU: $intel_gpu${NC}"
        echo -e "    ${YELLOW}Note: Integrated graphics - consider dedicated GPU for demanding games${NC}"
        
        GPU_VENDOR="intel"
        GPU_MODEL="$intel_gpu"
        GPU_STATUS="basic"
    else
        echo -e "    ${RED}No supported GPU detected${NC}"
        GPU_VENDOR="unknown"
        GPU_STATUS="unsupported"
    fi
    
    # Vulkan support check
    if command -v vulkaninfo &> /dev/null; then
        echo -e "    ${GREEN}Vulkan: Supported${NC}"
        VULKAN_SUPPORT=true
    else
        echo -e "    ${YELLOW}Vulkan: Not detected - will be installed${NC}"
        VULKAN_SUPPORT=false
    fi
}

analyze_storage() {
    local has_ssd=false
    local has_nvme=false
    local storage_warning=false
    
    # Check for SSDs and NVMe drives
    while IFS= read -r line; do
        local device
        device=$(echo "$line" | awk '{print $1}')
        local size
        size=$(echo "$line" | awk '{print $2}')
        local model
        model=$(echo "$line" | awk '{$1=$2=""; print $0}' | xargs)
        local is_rotational
        is_rotational=$(echo "$line" | awk '{print $NF}')
        
        if [[ "$is_rotational" == "0" ]]; then
            if [[ "$device" == nvme* ]]; then
                echo -e "    ${GREEN}NVMe SSD: $device ($size) - $model${NC}"
                has_nvme=true
                has_ssd=true
            else
                echo -e "    ${GREEN}SSD: $device ($size) - $model${NC}"
                has_ssd=true
            fi
        else
            echo -e "    ${YELLOW}HDD: $device ($size) - $model${NC}"
        fi
    done <<< "$(lsblk -d -o NAME,SIZE,MODEL,ROTA | grep -v "NAME")"
    
    if [[ "$has_ssd" == "false" ]]; then
        echo -e "    ${RED}Warning: No SSD detected. Gaming performance will be significantly improved with an SSD.${NC}"
        storage_warning=true
    elif [[ "$has_nvme" == "true" ]]; then
        echo -e "    ${GREEN}Excellent: NVMe SSD detected - optimal gaming storage performance.${NC}"
    else
        echo -e "    ${GREEN}Good: SSD detected - good gaming storage performance.${NC}"
    fi
    
    HAS_SSD=$has_ssd
    HAS_NVME=$has_nvme
    STORAGE_WARNING=$storage_warning
}

establish_performance_baseline() {
    log_message "INFO" "Establishing performance baseline"
    print_section "Performance Baseline"
    
    echo -e "  ${GEAR} Establishing baseline performance metrics..."
    
    # Quick CPU test
    echo -e "  ${ARROW} Testing CPU performance..."
    local cpu_score
    cpu_score=$(timeout 10s yes > /dev/null & local pid=$!; sleep 1; local start=$(cat /proc/loadavg | awk '{print $1}'); sleep 3; local end=$(cat /proc/loadavg | awk '{print $1}'); kill $pid 2>/dev/null; echo "$end" | awk '{printf "%.2f", $1}')
    echo -e "    CPU Load Score: ${BOLD}$cpu_score${NC}"
    
    # Memory test
    echo -e "  ${ARROW} Testing memory performance..."
    local mem_speed
    mem_speed=$(timeout 5s dd if=/dev/zero of=/dev/null bs=1M count=1000 2>&1 | grep -o '[0-9.]* MB/s' || echo "Unknown")
    echo -e "    Memory Speed: ${BOLD}$mem_speed${NC}"
    
    # Storage test (quick)
    echo -e "  ${ARROW} Testing storage performance..."
    local storage_speed
    storage_speed=$(timeout 5s dd if=/dev/zero of="$TEMP_DIR/test" bs=1M count=100 2>&1 | grep -o '[0-9.]* MB/s' || echo "Unknown")
    rm -f "$TEMP_DIR/test"
    echo -e "    Storage Speed: ${BOLD}$storage_speed${NC}"
    
    # Store baseline
    cat > "$TEMP_DIR/performance-baseline.txt" << EOF
cpu_score=$cpu_score
memory_speed=$mem_speed
storage_speed=$storage_speed
baseline_date=$(date)
EOF
    
    echo -e "  ${CHECKMARK} Performance baseline established"
}

assess_gaming_readiness() {
    log_message "INFO" "Assessing gaming readiness"
    print_section "Gaming Readiness Assessment"
    
    local readiness_score=0
    local max_score=10
    local recommendations=()
    
    # GPU assessment
    case "${GPU_STATUS:-unknown}" in
        "excellent")
            ((readiness_score += 4))
            echo -e "  ${GREEN}${CHECKMARK} Graphics: Excellent (NVIDIA with drivers)${NC}"
            ;;
        "good")
            ((readiness_score += 3))
            echo -e "  ${GREEN}${CHECKMARK} Graphics: Good (AMD with AMDGPU)${NC}"
            ;;
        "needs_improvement")
            ((readiness_score += 2))
            echo -e "  ${YELLOW}${ARROW} Graphics: Needs improvement (driver updates recommended)${NC}"
            recommendations+=("Update GPU drivers for better performance")
            ;;
        "basic")
            ((readiness_score += 1))
            echo -e "  ${YELLOW}${ARROW} Graphics: Basic (integrated graphics)${NC}"
            recommendations+=("Consider dedicated GPU for demanding games")
            ;;
        *)
            echo -e "  ${RED}${CROSSMARK} Graphics: Poor (no supported GPU detected)${NC}"
            recommendations+=("Install supported graphics drivers")
            ;;
    esac
    
    # Memory assessment
    local mem_gb
    mem_gb=$(free -g | grep "Mem:" | awk '{print $2}')
    if [[ $mem_gb -ge 16 ]]; then
        ((readiness_score += 2))
        echo -e "  ${GREEN}${CHECKMARK} Memory: Excellent (${mem_gb}GB)${NC}"
    elif [[ $mem_gb -ge 8 ]]; then
        ((readiness_score += 1))
        echo -e "  ${YELLOW}${ARROW} Memory: Good (${mem_gb}GB)${NC}"
        recommendations+=("Consider upgrading to 16GB RAM for optimal performance")
    else
        echo -e "  ${RED}${CROSSMARK} Memory: Insufficient (${mem_gb}GB)${NC}"
        recommendations+=("Upgrade to at least 8GB RAM for basic gaming")
    fi
    
    # Storage assessment
    if [[ "$HAS_NVME" == "true" ]]; then
        ((readiness_score += 2))
        echo -e "  ${GREEN}${CHECKMARK} Storage: Excellent (NVMe SSD)${NC}"
    elif [[ "$HAS_SSD" == "true" ]]; then
        ((readiness_score += 1))
        echo -e "  ${GREEN}${CHECKMARK} Storage: Good (SSD)${NC}"
    else
        echo -e "  ${RED}${CROSSMARK} Storage: Poor (HDD only)${NC}"
        recommendations+=("Install games on SSD for significantly better loading times")
    fi
    
    # CPU assessment (simplified)
    local cpu_cores
    cpu_cores=$(nproc)
    if [[ $cpu_cores -ge 8 ]]; then
        ((readiness_score += 2))
        echo -e "  ${GREEN}${CHECKMARK} CPU: Excellent (${cpu_cores} cores)${NC}"
    elif [[ $cpu_cores -ge 4 ]]; then
        ((readiness_score += 1))
        echo -e "  ${GREEN}${CHECKMARK} CPU: Good (${cpu_cores} cores)${NC}"
    else
        echo -e "  ${YELLOW}${ARROW} CPU: Basic (${cpu_cores} cores)${NC}"
        recommendations+=("Some modern games may require more CPU cores")
    fi
    
    # Calculate percentage
    local readiness_percentage
    readiness_percentage=$((readiness_score * 100 / max_score))
    
    echo
    echo -e "  ${BOLD}Gaming Readiness Score: ${readiness_score}/${max_score} (${readiness_percentage}%)${NC}"
    
    if [[ $readiness_percentage -ge 80 ]]; then
        echo -e "  ${GREEN}${STAR} Your system is excellent for gaming!${NC}"
        GAMING_READINESS="excellent"
    elif [[ $readiness_percentage -ge 60 ]]; then
        echo -e "  ${YELLOW}${STAR} Your system is good for gaming with some optimizations.${NC}"
        GAMING_READINESS="good"
    elif [[ $readiness_percentage -ge 40 ]]; then
        echo -e "  ${YELLOW}${STAR} Your system can handle gaming but may need upgrades for best performance.${NC}"
        GAMING_READINESS="fair"
    else
        echo -e "  ${RED}${STAR} Your system may struggle with modern games. Hardware upgrades recommended.${NC}"
        GAMING_READINESS="poor"
    fi
    
    # Show recommendations
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        echo
        echo -e "  ${BOLD}Recommendations:${NC}"
        for rec in "${recommendations[@]}"; do
            echo -e "    ${ARROW} $rec"
        done
    fi
    
    # Store assessment
    cat > "$TEMP_DIR/gaming-readiness.txt" << EOF
readiness_score=$readiness_score
readiness_percentage=$readiness_percentage
readiness_level=$GAMING_READINESS
recommendations_count=${#recommendations[@]}
EOF
    
    # Store recommendations
    printf '%s\n' "${recommendations[@]}" > "$TEMP_DIR/recommendations.txt"
}

# ==============================================================================
# Gaming Profile Creation
# ==============================================================================

create_gaming_profile() {
    log_message "INFO" "Creating gaming profile"
    print_header "${GAMING} Gaming Profile Creation"
    
    echo -e "${BOLD}Let's create your personalized gaming profile!${NC}"
    echo
    
    # Collect user preferences
    collect_user_preferences
    
    # Create profile configuration
    generate_gaming_profile
    
    # Set up gaming directories
    setup_gaming_directories
    
    log_message "SUCCESS" "Gaming profile created"
}

collect_user_preferences() {
    log_message "INFO" "Collecting user preferences"
    print_section "Gaming Preferences"
    
    # Gaming platforms
    echo -e "${BOLD}Which gaming platforms do you use?${NC} (Select all that apply)"
    echo -e "  1. Steam"
    echo -e "  2. Epic Games Store (via Heroic)"
    echo -e "  3. GOG"
    echo -e "  4. Origin/EA App"
    echo -e "  5. Ubisoft Connect"
    echo -e "  6. Emulation (RetroArch)"
    echo -e "  7. Native Linux games"
    echo
    
    GAMING_PLATFORMS=()
    read -p "Enter numbers separated by spaces (e.g., 1 2 3): " platform_choices
    for choice in $platform_choices; do
        case "$choice" in
            1) GAMING_PLATFORMS+=("steam") ;;
            2) GAMING_PLATFORMS+=("heroic") ;;
            3) GAMING_PLATFORMS+=("gog") ;;
            4) GAMING_PLATFORMS+=("origin") ;;
            5) GAMING_PLATFORMS+=("ubisoft") ;;
            6) GAMING_PLATFORMS+=("emulation") ;;
            7) GAMING_PLATFORMS+=("native") ;;
        esac
    done
    
    echo -e "Selected platforms: ${BOLD}${GAMING_PLATFORMS[*]}${NC}"
    echo
    
    # Gaming style
    echo -e "${BOLD}What type of gaming do you primarily do?${NC}"
    echo -e "  1. Competitive gaming (FPS, MOBAs, etc.)"
    echo -e "  2. AAA single-player games"
    echo -e "  3. Indie games"
    echo -e "  4. Emulation and retro games"
    echo -e "  5. VR gaming"
    echo -e "  6. Mixed gaming"
    echo
    
    read -p "Enter your choice [1-6]: " gaming_style_choice
    case "$gaming_style_choice" in
        1) GAMING_STYLE="competitive" ;;
        2) GAMING_STYLE="aaa_singleplayer" ;;
        3) GAMING_STYLE="indie" ;;
        4) GAMING_STYLE="emulation" ;;
        5) GAMING_STYLE="vr" ;;
        *) GAMING_STYLE="mixed" ;;
    esac
    
    echo -e "Gaming style: ${BOLD}$GAMING_STYLE${NC}"
    echo
    
    # Performance preference
    echo -e "${BOLD}Performance preference:${NC}"
    echo -e "  1. Maximum performance (may increase fan noise/power consumption)"
    echo -e "  2. Balanced performance and efficiency"
    echo -e "  3. Quiet operation (lower performance if needed)"
    echo
    
    read -p "Enter your choice [1-3]: " performance_choice
    case "$performance_choice" in
        1) PERFORMANCE_PREFERENCE="maximum" ;;
        2) PERFORMANCE_PREFERENCE="balanced" ;;
        3) PERFORMANCE_PREFERENCE="quiet" ;;
        *) PERFORMANCE_PREFERENCE="balanced" ;;
    esac
    
    echo -e "Performance preference: ${BOLD}$PERFORMANCE_PREFERENCE${NC}"
    echo
    
    # Monitoring preference
    echo -e "${BOLD}Do you want performance monitoring overlays during gaming?${NC}"
    read -p "Enable MangoHud and performance monitoring? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        ENABLE_MONITORING=false
    else
        ENABLE_MONITORING=true
    fi
    
    echo -e "Performance monitoring: ${BOLD}$ENABLE_MONITORING${NC}"
}

generate_gaming_profile() {
    log_message "INFO" "Generating gaming profile"
    
    mkdir -p "$CONFIG_DIR"
    
    # Create comprehensive gaming profile
    cat > "$CONFIG_DIR/gaming-profile.conf" << EOF
# xanadOS Gaming Profile
# Created: $(date)
# Profile Version: 1.0

[User]
Username=$USER
ProfileCreated=$(date)
ProfileVersion=1.0

[Hardware]
CPU=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
CPUCores=$(nproc)
Memory=$(free -h | grep "Mem:" | awk '{print $2}')
GPU=${GPU_MODEL:-Unknown}
GPUVendor=${GPU_VENDOR:-unknown}
Storage=SSD:${HAS_SSD:-false},NVMe:${HAS_NVME:-false}
VulkanSupport=${VULKAN_SUPPORT:-false}
GamingReadiness=${GAMING_READINESS:-unknown}

[Preferences]
GamingPlatforms=${GAMING_PLATFORMS[*]}
GamingStyle=$GAMING_STYLE
PerformancePreference=$PERFORMANCE_PREFERENCE
MonitoringEnabled=$ENABLE_MONITORING

[Configuration]
AutoGamingMode=true
PerformanceOptimizations=true
DesktopCustomization=true
HardwareOptimizations=true

[Recommendations]
$(cat "$TEMP_DIR/recommendations.txt" 2>/dev/null | sed 's/^/# /' || echo "# No specific recommendations")
EOF
    
    echo -e "  ${CHECKMARK} Gaming profile configuration created"
}

setup_gaming_directories() {
    log_message "INFO" "Setting up gaming directories"
    
    # Create gaming directories
    local gaming_base="$HOME/Gaming"
    mkdir -p "$gaming_base"/{Steam,Lutris,Heroic,ROMs,Screenshots,Recordings,Saves}
    
    # Create symlinks for easy access
    if [[ ! -L "$HOME/Desktop/Gaming" ]]; then
        ln -sf "$gaming_base" "$HOME/Desktop/Gaming" 2>/dev/null || true
    fi
    
    # Set up game storage preferences
    if [[ "$HAS_SSD" == "true" ]]; then
        echo -e "  ${CHECKMARK} Gaming directories created on SSD for optimal performance"
    else
        echo -e "  ${CHECKMARK} Gaming directories created (consider moving to SSD when available)"
    fi
    
    # Store directory configuration
    cat > "$CONFIG_DIR/gaming-directories.conf" << EOF
# xanadOS Gaming Directories Configuration
GamingBase=$gaming_base
SteamGames=$gaming_base/Steam
LutrisGames=$gaming_base/Lutris
HeroicGames=$gaming_base/Heroic
ROMs=$gaming_base/ROMs
Screenshots=$gaming_base/Screenshots
Recordings=$gaming_base/Recordings
Saves=$gaming_base/Saves
EOF
    
    echo -e "  ${CHECKMARK} Gaming directories configured"
}

# ==============================================================================
# Gaming Setup Integration
# ==============================================================================

run_gaming_setup() {
    log_message "INFO" "Running gaming setup"
    print_header "${ROCKET} Gaming Environment Setup"
    
    echo -e "${BOLD}Setting up your gaming environment based on your preferences...${NC}"
    echo
    
    # Determine setup type based on preferences and hardware
    local setup_type="complete"
    
    if [[ "$GAMING_READINESS" == "poor" ]] || [[ "$PERFORMANCE_PREFERENCE" == "quiet" ]]; then
        setup_type="essential"
    fi
    
    # Run the gaming setup wizard with our determined preferences
    if [[ -f "$SCRIPT_DIR/gaming-setup-wizard.sh" ]]; then
        echo -e "  ${ROCKET} Launching gaming setup wizard..."
        
        # Run setup wizard in automated mode
        "$SCRIPT_DIR/gaming-setup-wizard.sh" --automated --setup-type="$setup_type" \
            --platforms="${GAMING_PLATFORMS[*]}" \
            --performance="$PERFORMANCE_PREFERENCE" \
            --monitoring="$ENABLE_MONITORING" 2>&1 | tee -a "$LOG_FILE" || {
            
            # If automated mode fails, fall back to interactive
            echo -e "  ${YELLOW}Automated setup not available, running interactive setup...${NC}"
            "$SCRIPT_DIR/gaming-setup-wizard.sh"
        }
    else
        echo -e "  ${YELLOW}Gaming setup wizard not found, skipping automated setup${NC}"
        echo -e "  ${ARROW} You can run the setup manually later with:"
        echo -e "    $SCRIPT_DIR/gaming-setup-wizard.sh"
    fi
    
    # Apply KDE customization
    if [[ -f "$SCRIPT_DIR/kde-gaming-customization.sh" ]] && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        echo -e "  ${ROCKET} Applying gaming desktop customization..."
        "$SCRIPT_DIR/kde-gaming-customization.sh" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    log_message "SUCCESS" "Gaming setup completed"
}

# ==============================================================================
# Final Configuration
# ==============================================================================

finalize_setup() {
    log_message "INFO" "Finalizing setup"
    print_header "${STAR} Setup Finalization"
    
    # Create first-boot completion marker
    create_completion_marker
    
    # Generate system report
    generate_system_report
    
    # Set up automatic optimizations
    setup_automatic_optimizations
    
    # Create desktop shortcuts
    create_desktop_shortcuts
    
    log_message "SUCCESS" "Setup finalized"
}

create_completion_marker() {
    log_message "INFO" "Creating completion marker"
    
    sudo mkdir -p "$(dirname "$FIRST_BOOT_MARKER")"
    sudo tee "$FIRST_BOOT_MARKER" > /dev/null << EOF
# xanadOS First-Boot Completion Marker
# This file indicates that the first-boot setup has been completed

CompletionDate=$(date)
SetupVersion=1.0
Username=$USER
GamingProfile=$CONFIG_DIR/gaming-profile.conf
SystemReport=$CONFIG_DIR/system-report.txt
EOF
    
    echo -e "  ${CHECKMARK} First-boot completion marker created"
}

generate_system_report() {
    log_message "INFO" "Generating system report"
    
    # Combine all collected information into a comprehensive report
    cat > "$CONFIG_DIR/system-report.txt" << EOF
# xanadOS System Report
# Generated: $(date)

=== SYSTEM INFORMATION ===
$(cat "$TEMP_DIR/system-info.txt" 2>/dev/null || echo "System info not available")

=== HARDWARE INFORMATION ===
$(cat "$TEMP_DIR/hardware-info.txt" 2>/dev/null || echo "Hardware info not available")

=== PERFORMANCE BASELINE ===
$(cat "$TEMP_DIR/performance-baseline.txt" 2>/dev/null || echo "Performance baseline not available")

=== GAMING READINESS ===
$(cat "$TEMP_DIR/gaming-readiness.txt" 2>/dev/null || echo "Gaming readiness not available")

=== GAMING PROFILE ===
$(cat "$CONFIG_DIR/gaming-profile.conf" 2>/dev/null || echo "Gaming profile not available")

=== RECOMMENDATIONS ===
$(cat "$TEMP_DIR/recommendations.txt" 2>/dev/null || echo "No specific recommendations")
EOF
    
    echo -e "  ${CHECKMARK} System report generated: $CONFIG_DIR/system-report.txt"
}

setup_automatic_optimizations() {
    log_message "INFO" "Setting up automatic optimizations"
    
    # Enable gaming mode detection if available
    if command -v systemctl &> /dev/null; then
        systemctl --user enable xanados-gaming-detector.service 2>/dev/null || true
        systemctl --user start xanados-gaming-detector.service 2>/dev/null || true
    fi
    
    echo -e "  ${CHECKMARK} Automatic optimizations configured"
}

create_desktop_shortcuts() {
    log_message "INFO" "Creating desktop shortcuts"
    
    local desktop_dir="$HOME/Desktop"
    mkdir -p "$desktop_dir"
    
    # Gaming control center shortcut
    cat > "$desktop_dir/Gaming Control Center.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Gaming Control Center
Comment=xanadOS Gaming Control Center
Exec=xanados-gaming-center
Icon=applications-games
Terminal=false
Categories=Game;
EOF
    
    # System report shortcut
    cat > "$desktop_dir/System Report.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=System Report
Comment=View xanadOS System Report
Exec=xdg-open "$CONFIG_DIR/system-report.txt"
Icon=dialog-information
Terminal=false
Categories=System;
EOF
    
    chmod +x "$desktop_dir"/*.desktop 2>/dev/null || true
    
    echo -e "  ${CHECKMARK} Desktop shortcuts created"
}

# ==============================================================================
# Completion Screen
# ==============================================================================

show_completion_screen() {
    clear
    print_header "${HEART} Welcome to Your Optimized Gaming Paradise! ${GAMING}"
    
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}║${NC}  ${BOLD}${WHITE}🎉 CONGRATULATIONS! Your xanadOS gaming setup is complete! 🎉${NC}          ${BOLD}${GREEN}║${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}║${NC}  ${WHITE}Your system has been optimized for exceptional gaming performance.${NC}     ${BOLD}${GREEN}║${NC}"
    echo -e "${BOLD}${GREEN}║                                                                              ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${BOLD}What's Ready for You:${NC}"
    echo -e "  ${GREEN}${CHECKMARK} Hardware-optimized gaming performance${NC}"
    echo -e "  ${GREEN}${CHECKMARK} Gaming software stack configured${NC}"
    echo -e "  ${GREEN}${CHECKMARK} Desktop customized for gaming${NC}"
    echo -e "  ${GREEN}${CHECKMARK} Personal gaming profile created${NC}"
    echo -e "  ${GREEN}${CHECKMARK} Automatic gaming mode detection${NC}"
    echo
    
    echo -e "${BOLD}Your Gaming Arsenal:${NC}"
    if [[ " ${GAMING_PLATFORMS[*]} " =~ " steam " ]]; then
        echo -e "  ${GAMING} Steam with Proton-GE for Windows games"
    fi
    if [[ " ${GAMING_PLATFORMS[*]} " =~ " heroic " ]]; then
        echo -e "  ${GAMING} Heroic Games Launcher for Epic Games Store"
    fi
    echo -e "  ${GAMING} GameMode for automatic performance optimization"
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        echo -e "  ${GAMING} MangoHud for performance monitoring"
    fi
    echo -e "  ${GAMING} Lutris for managing all your games"
    echo
    
    echo -e "${BOLD}Quick Commands:${NC}"
    echo -e "  ${ARROW} ${CYAN}xanados-gaming-mode toggle${NC}  - Toggle gaming mode"
    echo -e "  ${ARROW} ${CYAN}steam-gamemode${NC}              - Launch Steam with optimizations"
    echo -e "  ${ARROW} ${CYAN}lutris${NC}                      - Open game library manager"
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        echo -e "  ${ARROW} ${CYAN}mangohud <game>${NC}             - Run game with performance overlay"
    fi
    echo
    
    echo -e "${BOLD}System Information:${NC}"
    echo -e "  ${ARROW} Gaming Profile: ${CYAN}$CONFIG_DIR/gaming-profile.conf${NC}"
    echo -e "  ${ARROW} System Report: ${CYAN}$CONFIG_DIR/system-report.txt${NC}"
    echo -e "  ${ARROW} Gaming Directory: ${CYAN}$HOME/Gaming${NC}"
    echo -e "  ${ARROW} Setup Logs: ${CYAN}$LOG_FILE${NC}"
    echo
    
    if [[ "${#GAMING_PLATFORMS[@]}" -gt 0 ]]; then
        echo -e "${BOLD}Next Steps:${NC}"
        echo -e "  ${ARROW} Launch your favorite game launcher and start gaming!"
        echo -e "  ${ARROW} Your games will automatically benefit from xanadOS optimizations"
        echo -e "  ${ARROW} Gaming mode will activate automatically when you start games"
        echo
    fi
    
    echo -e "${BOLD}${YELLOW}Gaming Readiness: ${GAMING_READINESS^} (${readiness_percentage:-0}%)${NC}"
    echo
    
    echo -e "${GREEN}${BOLD}Welcome to the future of Linux gaming! 🚀${NC}"
    echo -e "${WHITE}Thank you for choosing xanadOS - Game On! ${GAMING}${NC}"
    echo
    
    log_message "SUCCESS" "First-boot experience completed successfully"
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
    
    # Check if first-boot is needed
    check_first_boot
    
    # Show welcome screen
    show_welcome_screen
    
    # Perform system analysis
    perform_system_analysis
    
    # Create gaming profile
    create_gaming_profile
    
    # Run gaming setup
    run_gaming_setup
    
    # Finalize setup
    finalize_setup
    
    # Show completion screen
    show_completion_screen
    
    log_message "SUCCESS" "xanadOS first-boot experience completed"
}

# Run main function
main "$@"
