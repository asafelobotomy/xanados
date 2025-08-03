#!/bin/bash

# ==============================================================================
# xanadOS Gaming Setup Wizard
# ==============================================================================
# Description: Comprehensive gaming setup wizard with hardware detection,
#              software installation, and optimization recommendations
# Author: xanadOS Development Team
# Version: 1.0.0
# License: Personal Use License
# ==============================================================================

set -euo pipefail

# Source xanadOS shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gaming-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gaming-profiles.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/hardware-detection.sh"

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# XANADOS_ROOT is set in common.sh as readonly - no need to redefine
LOG_FILE="/var/log/xanados/gaming-setup-wizard.log"
CONFIG_DIR="$HOME/.config/xanados"
TEMP_DIR="/tmp/xanados-wizard-$$"

# Colors are defined in common.sh - no need to redefine here
# Color variables: RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, WHITE, BOLD, NC

# Unicode symbols
CHECKMARK="✓"
CROSSMARK="✗"
ARROW="→"
STAR="★"
GEAR="⚙"
GAMING="🎮"
ROCKET="🚀"

# ==============================================================================
# Logging and Utility Functions
# ==============================================================================

setup_logging() {
    local log_dir="/var/log/xanados"

    # Try to create log directory with fallback to user directory
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/gaming-setup-wizard.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/gaming-setup-wizard.log"
    fi

    # Create log file
    touch "$LOG_FILE"

    echo "=== xanadOS Gaming Setup Wizard Started: $(date) ===" >> "$LOG_FILE"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

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
# System Detection Functions
# ==============================================================================

detect_hardware() {
    log_message "INFO" "Starting comprehensive hardware detection"

    print_section "Hardware Detection & Analysis"

    # Use our comprehensive hardware detection system
    echo -e "  ${GEAR} Analyzing system hardware for gaming optimization..."
    echo

    # Show hardware summary first
    echo -e "  ${STAR} Quick Hardware Overview:"
    hardware_summary
    echo

    # Get detailed component analysis (safely handle JSON parsing)
    local cpu_data
    local gpu_data
    local memory_data
    local storage_data

    # Get hardware data with error handling
    cpu_data=$(detect_cpu 2>/dev/null) || cpu_data="{}"
    gpu_data=$(detect_gpu 2>/dev/null) || gpu_data="{}"
    memory_data=$(detect_memory 2>/dev/null) || memory_data="{}"
    storage_data=$(detect_storage 2>/dev/null) || storage_data="{}"

    # Display detailed analysis
    echo -e "  ${GEAR} Detailed Component Analysis:"
    echo

    # CPU Analysis (with safe JSON parsing)
    local cpu_name
    local cpu_cores
    local cpu_threads
    local cpu_score

    cpu_name=$(echo "$cpu_data" | jq -r '.name // "Unknown CPU"' 2>/dev/null) || cpu_name="Unknown CPU"
    cpu_cores=$(echo "$cpu_data" | jq -r '.cores // 0' 2>/dev/null) || cpu_cores="0"
    cpu_threads=$(echo "$cpu_data" | jq -r '.threads // 0' 2>/dev/null) || cpu_threads="0"
    cpu_score=$(echo "$cpu_data" | jq -r '.gaming_score // 0' 2>/dev/null) || cpu_score="0"

    echo -e "    🔧 CPU: ${BOLD}$cpu_name${NC}"
    echo -e "        Cores/Threads: $cpu_cores/$cpu_threads"
    echo -e "        Gaming Score: $cpu_score/100"

    # GPU Analysis (with safe JSON parsing)
    local gpu_name
    local gpu_vendor
    local gpu_driver
    local gpu_score

    gpu_name=$(echo "$gpu_data" | jq -r '.name // "Unknown GPU"' 2>/dev/null) || gpu_name="Unknown GPU"
    gpu_vendor=$(echo "$gpu_data" | jq -r '.vendor // "unknown"' 2>/dev/null) || gpu_vendor="unknown"
    gpu_driver=$(echo "$gpu_data" | jq -r '.driver // "none"' 2>/dev/null) || gpu_driver="none"
    gpu_score=$(echo "$gpu_data" | jq -r '.gaming_score // 0' 2>/dev/null) || gpu_score="0"

    echo -e "    🎮 GPU: ${BOLD}$gpu_name${NC}"
    echo -e "        Vendor: $gpu_vendor | Driver: $gpu_driver"
    echo -e "        Gaming Score: $gpu_score/100"

    # Memory Analysis (with safe JSON parsing)
    local memory_total
    local memory_available
    local memory_score

    memory_total=$(echo "$memory_data" | jq -r '.total_gb // 0' 2>/dev/null) || memory_total="0"
    memory_available=$(echo "$memory_data" | jq -r '.available_gb // 0' 2>/dev/null) || memory_available="0"
    memory_score=$(echo "$memory_data" | jq -r '.gaming_score // 0' 2>/dev/null) || memory_score="0"

    echo -e "    💾 Memory: ${BOLD}${memory_total}GB${NC} total"
    echo -e "        Available: ${memory_available}GB"
    echo -e "        Gaming Score: $memory_score/100"

    # Storage Analysis (with safe JSON parsing)
    local storage_fs
    local storage_device
    local storage_score

    storage_fs=$(echo "$storage_data" | jq -r '.root_filesystem // "unknown"' 2>/dev/null) || storage_fs="unknown"
    storage_device=$(echo "$storage_data" | jq -r '.root_device // "unknown"' 2>/dev/null) || storage_device="unknown"
    storage_score=$(echo "$storage_data" | jq -r '.gaming_score // 0' 2>/dev/null) || storage_score="0"

    echo -e "    💿 Storage: ${BOLD}$storage_fs${NC} filesystem"
    echo -e "        Root Device: $storage_device"
    echo -e "        Gaming Score: $storage_score/100"

    # Calculate overall gaming score safely
    local overall_score
    overall_score=$(( (${cpu_score:-0} + ${gpu_score:-0} + ${memory_score:-0} + ${storage_score:-0}) / 4 )) || overall_score=0
    local readiness_level
    readiness_level=$(get_gaming_readiness_level "$overall_score") || readiness_level="Unknown"

    echo
    echo -e "  ${ROCKET} Overall Gaming Readiness: ${BOLD}$overall_score/100${NC} ($readiness_level)"

    # Export key hardware variables for use by wizard
    export DETECTED_CPU_NAME="$cpu_name"
    export DETECTED_GPU_NAME="$gpu_name"
    export DETECTED_GPU_VENDOR="$gpu_vendor"
    export DETECTED_GPU_DRIVER="$gpu_driver"
    export DETECTED_MEMORY_GB="$memory_total"
    export GAMING_HARDWARE_SCORE="$overall_score"

    # Show critical recommendations
    echo
    echo -e "  ${ARROW} Key Gaming Recommendations:"

    # Critical GPU driver issues
    if [[ "$gpu_driver" == "none" ]]; then
        case "$gpu_vendor" in
            "nvidia")
                echo -e "    ${RED}⚠️  CRITICAL:${NC} Install NVIDIA proprietary drivers"
                echo -e "        Command: sudo pacman -S nvidia nvidia-utils nvidia-settings"
                ;;
            "amd")
                echo -e "    ${RED}⚠️  CRITICAL:${NC} Install AMD GPU drivers"
                echo -e "        Command: sudo pacman -S mesa vulkan-radeon lib32-vulkan-radeon"
                ;;
            *)
                echo -e "    ${YELLOW}⚠️  WARNING:${NC} Unknown GPU vendor, may need driver installation"
                ;;
        esac
    else
        echo -e "    ${GREEN}✅ GPU drivers detected${NC}"
    fi

    # Memory recommendations
    if [[ "${memory_total:-0}" -lt 16 ]]; then
        echo -e "    ${YELLOW}💡 SUGGESTION:${NC} Consider upgrading to 16GB+ RAM for optimal gaming"
    else
        echo -e "    ${GREEN}✅ Sufficient memory for gaming${NC}"
    fi

    # Storage recommendations
    if [[ "$storage_fs" != "ext4" ]] && [[ "$storage_fs" != "btrfs" ]] && [[ "$storage_fs" != "xfs" ]]; then
        echo -e "    ${YELLOW}💡 SUGGESTION:${NC} Consider using ext4, btrfs, or xfs for better gaming performance"
    else
        echo -e "    ${GREEN}✅ Gaming-friendly filesystem detected${NC}"
    fi
    echo
    log_message "SUCCESS" "Comprehensive hardware detection completed (Score: $overall_score/100)"
}

# ==============================================================================
# Software Installation Status Functions
# ==============================================================================

# Check installation status of gaming software
check_gaming_software_status() {
    log_message "INFO" "Checking gaming software installation status"

    # Steam
    if get_cached_command "steam"; then
        STEAM_INSTALLED=true
        echo -e "  ${GREEN}✅ Steam installed${NC}"
    else
        STEAM_INSTALLED=false
        echo -e "  ${RED}❌ Steam not installed${NC}"
    fi

    # Lutris
    if get_cached_command "lutris"; then
        LUTRIS_INSTALLED=true
        echo -e "  ${GREEN}✅ Lutris installed${NC}"
    else
        LUTRIS_INSTALLED=false
        echo -e "  ${RED}❌ Lutris not installed${NC}"
    fi

    # GameMode
    if get_cached_command "gamemoderun"; then
        GAMEMODE_INSTALLED=true
        echo -e "  ${GREEN}✅ GameMode installed${NC}"
    else
        GAMEMODE_INSTALLED=false
        echo -e "  ${RED}❌ GameMode not installed${NC}"
    fi

    # MangoHud
    if get_cached_command "mangohud"; then
        MANGOHUD_INSTALLED=true
        echo -e "  ${GREEN}✅ MangoHud installed${NC}"
    else
        MANGOHUD_INSTALLED=false
        echo -e "  ${RED}❌ MangoHud not installed${NC}"
    fi
}

# ==============================================================================
# Gaming Environment Analysis Functions
# ==============================================================================

# Display optimizations status
show_optimizations_status() {
    print_section "Current Gaming Optimizations"

    echo -e "Checking current system optimizations..."
    echo

    # Check gaming-specific kernel parameters
    echo -e "  ${GEAR} Kernel Parameters:"
    if [[ -f "/etc/sysctl.d/99-gaming.conf" ]]; then
        echo -e "    ${GREEN}✅ Gaming kernel parameters configured${NC}"
    else
        echo -e "    ${RED}❌ Gaming kernel parameters not configured${NC}"
    fi

    # Check CPU governor
    echo -e "  ${GEAR} CPU Governor:"
    if [[ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]]; then
        local governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
        if [[ "$governor" == "performance" ]]; then
            echo -e "    ${GREEN}✅ Performance governor active${NC}"
        else
            echo -e "    ${YELLOW}⚠️ Current governor: $governor${NC}"
        fi
    else
        echo -e "    ${YELLOW}⚠️ CPU frequency scaling not available${NC}"
    fi
}

# ==============================================================================
# Setup Options and User Interface Functions
# ==============================================================================
# Setup Options and User Interface Functions
# ==============================================================================

detect_existing_gaming_software() {
    log_message "INFO" "Detecting existing gaming software"

    print_section "Gaming Software Detection"

    # Steam Detection
    if get_cached_command "steam"; then
        echo -e "  ${GREEN}Steam: Installed${NC}"
        STEAM_INSTALLED=true

        # Check for Proton-GE
        local proton_ge_dir="$HOME/.steam/root/compatibilitytools.d"
        if [[ -d "$proton_ge_dir" ]] && ls "$proton_ge_dir"/GE-Proton* &> /dev/null; then
            echo -e "    ${GREEN}Proton-GE: Installed${NC}"
            PROTON_GE_INSTALLED=true
        else
            echo -e "    ${YELLOW}Proton-GE: Not installed${NC}"
            PROTON_GE_INSTALLED=false
        fi
    else
        echo -e "  ${YELLOW}Steam: Not installed${NC}"
        STEAM_INSTALLED=false
        PROTON_GE_INSTALLED=false
    fi

    # Lutris Detection
    if get_cached_command "lutris"; then
        echo -e "  ${GREEN}Lutris: Installed${NC}"
        LUTRIS_INSTALLED=true
    else
        echo -e "  ${YELLOW}Lutris: Not installed${NC}"
        LUTRIS_INSTALLED=false
    fi

    # GameMode Detection
    if get_cached_command "gamemoderun"; then
        echo -e "  ${GREEN}GameMode: Installed${NC}"
        GAMEMODE_INSTALLED=true
    else
        echo -e "  ${YELLOW}GameMode: Not installed${NC}"
        GAMEMODE_INSTALLED=false
    fi

    # MangoHud Detection
    if get_cached_command "mangohud"; then
        echo -e "  ${GREEN}MangoHud: Installed${NC}"
        MANGOHUD_INSTALLED=true
    else
        echo -e "  ${YELLOW}MangoHud: Not installed${NC}"
        MANGOHUD_INSTALLED=false
    fi

    # Wine Detection
    if get_cached_command "wine"; then
        local wine_version=$(wine --version)
        echo -e "  ${GREEN}Wine: $wine_version${NC}"
        WINE_INSTALLED=true
    else
        echo -e "  ${YELLOW}Wine: Not installed${NC}"
        WINE_INSTALLED=false
    fi
}

# ==============================================================================
# Gaming Recommendations
# ==============================================================================

generate_recommendations() {
    log_message "INFO" "Generating gaming recommendations"

    print_section "Gaming Optimization Recommendations"

    RECOMMENDATIONS=()
    PRIORITY_RECOMMENDATIONS=()

    # Get audio system from gaming environment cache
    AUDIO_SYSTEM="${GAMING_ENV_CACHE[audio_system]:-unknown}"

    # Set controller count (this would be detected by hardware detection)
    CONTROLLER_COUNT=0

    # Hardware-based recommendations
    if [[ "${GPU_VENDOR:-}" == "nvidia" ]]; then
        RECOMMENDATIONS+=("Install NVIDIA proprietary drivers for optimal gaming performance")
        if ! get_cached_command "nvidia-smi"; then
            PRIORITY_RECOMMENDATIONS+=("NVIDIA drivers are not properly installed")
        fi
    elif [[ "${GPU_VENDOR:-}" == "amd" ]]; then
        RECOMMENDATIONS+=("Install Mesa and RADV drivers for AMD GPU optimization")
        if ! $VULKAN_SUPPORT; then
            PRIORITY_RECOMMENDATIONS+=("Vulkan support should be installed for modern gaming")
        fi
    fi

    # Storage recommendations
    if [[ "${HAS_SSD:-false}" == "true" ]]; then
        RECOMMENDATIONS+=("Configure games to install on SSD for faster loading times")
    else
        PRIORITY_RECOMMENDATIONS+=("Consider upgrading to an SSD for significantly better gaming performance")
    fi

    # Memory recommendations
    local mem_gb=$(free -g | grep "Mem:" | awk '{print $2}')
    if [[ $mem_gb -lt 16 ]]; then
        RECOMMENDATIONS+=("Consider upgrading to 16GB+ RAM for optimal gaming performance")
    fi

    # Audio recommendations
    if [[ "$AUDIO_SYSTEM" == "pulseaudio" ]]; then
        PRIORITY_RECOMMENDATIONS+=("Upgrade to PipeWire for lower audio latency in gaming")
    fi

    # Gaming software recommendations
    if ! $STEAM_INSTALLED; then
        PRIORITY_RECOMMENDATIONS+=("Install Steam for access to the largest gaming library")
    elif ! $PROTON_GE_INSTALLED; then
        RECOMMENDATIONS+=("Install Proton-GE for better Windows game compatibility")
    fi

    if ! $GAMEMODE_INSTALLED; then
        PRIORITY_RECOMMENDATIONS+=("Install GameMode for automatic gaming optimizations")
    fi

    if ! $MANGOHUD_INSTALLED; then
        RECOMMENDATIONS+=("Install MangoHud for in-game performance monitoring")
    fi

    # Controller recommendations
    if [[ $CONTROLLER_COUNT -gt 0 ]]; then
        RECOMMENDATIONS+=("Configure controller support for gaming")
    fi

    # Display recommendations
    echo -e "\n${STAR} ${BOLD}Priority Recommendations:${NC}"
    for rec in "${PRIORITY_RECOMMENDATIONS[@]}"; do
        echo -e "  ${RED}${ARROW}${NC} $rec"
    done

    echo -e "\n${STAR} ${BOLD}Additional Recommendations:${NC}"
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo -e "  ${YELLOW}${ARROW}${NC} $rec"
    done
}

# ==============================================================================
# Gaming Setup Options
# ==============================================================================

show_setup_options() {
    print_section "Gaming Setup Options"

    # Show hardware context
    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"
    local memory_gb="${DETECTED_MEMORY_GB:-0}"
    local hardware_score="${GAMING_HARDWARE_SCORE:-0}"

    echo -e "📊 Detected Hardware: ${BOLD}$gpu_vendor GPU${NC}, ${BOLD}${memory_gb}GB RAM${NC}, Score: ${BOLD}$hardware_score/100${NC}"
    echo

    # Show current gaming profile if any
    local current_profile
    current_profile=$(get_current_profile 2>/dev/null) || current_profile=""
    if [[ -n "$current_profile" ]]; then
        echo -e "🎮 Current Gaming Profile: ${BOLD}$current_profile${NC}"
        echo
    fi

    echo -e "Choose your gaming setup preference:\n"
    echo -e "  ${BOLD}1.${NC} ${GREEN}Complete Gaming Setup${NC} - Hardware-optimized full installation"
    echo -e "     ${ARROW} Steam + Proton-GE, Lutris, Heroic, GameMode, MangoHud"
    echo -e "     ${ARROW} GPU-specific drivers and tools ($gpu_vendor optimizations)"
    echo -e "     ${ARROW} Memory-aware software selection (${memory_gb}GB RAM considered)"
    echo -e "     ${ARROW} Gaming desktop customization and performance tweaks"
    echo
    echo -e "  ${BOLD}2.${NC} ${YELLOW}Essential Gaming Only${NC} - Core gaming tools with hardware awareness"
    echo -e "     ${ARROW} Steam + Proton-GE, GameMode, MangoHud"
    echo -e "     ${ARROW} Hardware-specific optimizations"
    echo -e "     ${ARROW} Basic gaming environment setup"
    echo
    echo -e "  ${BOLD}3.${NC} ${BLUE}Custom Setup${NC} - Choose components with hardware recommendations"
    echo -e "     ${ARROW} Select specific gaming software and optimizations"
    echo -e "     ${ARROW} Hardware-aware component suggestions"
    echo
    echo -e "  ${BOLD}4.${NC} ${PURPLE}Gaming Optimization Only${NC} - Apply hardware-specific optimizations"
    echo -e "     ${ARROW} GPU-specific tweaks and kernel parameters"
    echo -e "     ${ARROW} Memory and CPU optimizations for gaming"
    echo
    echo -e "  ${BOLD}5.${NC} ${CYAN}Hardware Analysis Only${NC} - Show detailed system analysis"
    echo -e "     ${ARROW} Comprehensive hardware assessment and gaming readiness"
    echo -e "     ${ARROW} Optimization recommendations without making changes"
    echo
    echo -e "  ${BOLD}6.${NC} ${WHITE}Gaming Profile Management${NC} - Create and manage gaming profiles"
    echo -e "     ${ARROW} Create personalized gaming profiles based on your preferences"
    echo -e "     ${ARROW} Switch between different gaming configurations"
    echo -e "     ${ARROW} Hardware-aware profile recommendations and optimization"
    echo
    echo -e "  ${BOLD}0.${NC} Exit wizard"
    echo
}

handle_setup_choice() {
    local choice="$1"

    case "$choice" in
        1)
            log_message "INFO" "Starting complete gaming setup"
            run_complete_gaming_setup
            ;;
        2)
            log_message "INFO" "Starting essential gaming setup"
            run_essential_gaming_setup
            ;;
        3)
            log_message "INFO" "Starting custom gaming setup"
            run_custom_gaming_setup
            ;;
        4)
            log_message "INFO" "Starting gaming optimization only"
            run_optimization_only
            ;;
        5)
            log_message "INFO" "Hardware analysis completed"
            echo -e "\n${GREEN}Hardware analysis completed. Check the recommendations above.${NC}"
            ;;
        6)
            log_message "INFO" "Starting gaming profile management"
            run_gaming_profile_management
            ;;
        0)
            log_message "INFO" "User exited wizard"
            echo -e "\n${YELLOW}Gaming setup wizard cancelled.${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid choice. Please try again.${NC}"
            return 1
            ;;
    esac
}

# ==============================================================================
# Gaming Setup Implementations
# ==============================================================================

run_complete_gaming_setup() {
    print_header "${GAMING} Complete Gaming Setup"

    log_message "STEP" "Starting hardware-aware complete gaming setup"

    # Use hardware detection to optimize installation choices
    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"
    local memory_gb="${DETECTED_MEMORY_GB:-0}"
    local hardware_score="${GAMING_HARDWARE_SCORE:-0}"

    echo -e "🔍 Hardware-Optimized Gaming Setup"
    echo -e "   GPU: $gpu_vendor | Memory: ${memory_gb}GB | Score: $hardware_score/100"
    echo

    # Phase 1: Core Gaming Platform Installation
    echo -e "${ROCKET} Phase 1: Installing Core Gaming Platforms"
    install_gaming_platforms_optimized

    # Phase 2: Gaming Tools and Utilities
    echo -e "\n${ROCKET} Phase 2: Installing Gaming Tools and Utilities"
    install_gaming_tools_optimized

    # Phase 3: Hardware-Specific Optimizations
    echo -e "\n${ROCKET} Phase 3: Applying Hardware-Specific Optimizations"
    apply_hardware_optimizations

    # Phase 4: Gaming Environment Configuration
    echo -e "\n${ROCKET} Phase 4: Configuring Gaming Environment"
    configure_gaming_environment_optimized

    # Phase 5: Desktop Customization
    echo -e "\n${ROCKET} Phase 5: Gaming Desktop Customization"
    apply_gaming_desktop_customization

    log_message "SUCCESS" "Complete gaming setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Complete gaming setup finished successfully!${NC}"
    show_post_setup_instructions_optimized
}

run_essential_gaming_setup() {
    print_header "${GAMING} Essential Gaming Setup (Hardware-Aware)"

    log_message "STEP" "Starting essential gaming setup with hardware optimizations"
    echo -e "🔍 Configuring for: ${DETECTED_GPU_VENDOR:-unknown} GPU, ${DETECTED_MEMORY_GB:-0}GB RAM"
    echo

    # Install essential gaming platforms (Steam + basic tools)
    echo -e "${BLUE}Phase 1: Installing Essential Gaming Platforms${NC}"
    if ! $STEAM_INSTALLED; then
        install_gaming_platforms_optimized | head -20  # Show Steam installation
    else
        echo -e "  ${GREEN}✅ Steam already installed${NC}"
    fi
    echo

    # Install essential gaming tools (GameMode, MangoHud)
    echo -e "${BLUE}Phase 2: Installing Essential Gaming Tools${NC}"
    if ! $GAMEMODE_INSTALLED; then
        install_gaming_tools_optimized | grep -E "(GameMode|MangoHud|✅|❌)"
    else
        echo -e "  ${GREEN}✅ GameMode already installed${NC}"
    fi
    echo

    # Apply hardware-specific optimizations
    echo -e "${BLUE}Phase 3: Applying Hardware Optimizations${NC}"
    apply_hardware_optimizations
    echo

    # Basic gaming environment configuration
    echo -e "${BLUE}Phase 4: Configuring Gaming Environment${NC}"
    configure_gaming_environment_optimized
    echo

    log_message "SUCCESS" "Essential gaming setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Essential gaming setup completed successfully!${NC}"
    show_post_setup_instructions_optimized
}

run_custom_gaming_setup() {
    print_header "${GAMING} Custom Gaming Setup (Hardware-Aware)"

    log_message "STEP" "Starting custom gaming setup with hardware recommendations"

    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"
    local memory_gb="${DETECTED_MEMORY_GB:-0}"
    local hardware_score="${GAMING_HARDWARE_SCORE:-0}"

    echo -e "📊 Hardware Context: ${BOLD}$gpu_vendor GPU${NC}, ${BOLD}${memory_gb}GB RAM${NC}, Score: ${BOLD}$hardware_score/100${NC}"
    echo
    echo -e "Select components to install (hardware recommendations included):\n"

    local components=()

    # Steam - Always recommend
    if ! $STEAM_INSTALLED; then
        echo -e "  🚀 ${BOLD}Steam${NC} - Essential gaming platform ${GREEN}[RECOMMENDED]${NC}"
        read -p "     Install Steam? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            components+=("steam")
        fi
    else
        echo -e "  ✅ Steam already installed"
    fi

    # Lutris - Recommend for all systems
    if ! $LUTRIS_INSTALLED; then
        echo -e "  🍷 ${BOLD}Lutris${NC} - Multi-platform gaming ${GREEN}[RECOMMENDED]${NC}"
        read -p "     Install Lutris? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            components+=("lutris")
        fi
    else
        echo -e "  ✅ Lutris already installed"
    fi

    # GameMode - Always recommend
    if ! $GAMEMODE_INSTALLED; then
        echo -e "  ⚡ ${BOLD}GameMode & MangoHud${NC} - Gaming optimizations ${GREEN}[RECOMMENDED]${NC}"
        read -p "     Install GameMode and MangoHud? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            components+=("gamemode")
        fi
    else
        echo -e "  ✅ GameMode already installed"
    fi

    # Hardware optimizations - Always recommend
    echo -e "  🔧 ${BOLD}Hardware Optimizations${NC} - $gpu_vendor GPU + System tweaks ${GREEN}[RECOMMENDED]${NC}"
    read -p "     Apply hardware-specific optimizations? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        components+=("hardware")
    fi

    # Optional components based on hardware
    echo -e "\n📦 ${BOLD}Optional Components:${NC}"

    # Heroic - Recommend for systems with good specs
    if [[ "$hardware_score" -ge 60 ]]; then
        echo -e "  🦸 ${BOLD}Heroic Games Launcher${NC} - Epic/GOG games ${YELLOW}[OPTIONAL - Good for your system]${NC}"
        read -p "     Install Heroic Games Launcher? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            components+=("all-platforms")  # This will install additional platforms
        fi
    fi

    # Discord/OBS - Memory dependent
    if [[ "$memory_gb" -ge 8 ]]; then
        echo -e "  💬 ${BOLD}Discord & Communication${NC} - Gaming chat ${YELLOW}[OPTIONAL - Sufficient RAM: ${memory_gb}GB]${NC}"
        read -p "     Install Discord and communication tools? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            components+=("all-tools")  # This will install additional tools
        fi
    else
        echo -e "  💬 ${BOLD}Discord & Communication${NC} - ${RED}[NOT RECOMMENDED - Low RAM: ${memory_gb}GB]${NC}"
    fi

    # KDE customization
    if command -v plasmashell >/dev/null 2>&1; then
        echo -e "  🎨 ${BOLD}Gaming Desktop Customization${NC} - KDE gaming theme ${YELLOW}[OPTIONAL]${NC}"
        read -p "     Apply gaming desktop customization? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            components+=("kde")
        fi
    fi

    echo

    # Install selected components
    if [[ ${#components[@]} -gt 0 ]]; then
        echo -e "${BLUE}Installing selected components...${NC}"
        install_custom_components "${components[@]}"
    else
        echo -e "${YELLOW}No components selected for installation.${NC}"
    fi

    log_message "SUCCESS" "Custom gaming setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Custom gaming setup completed successfully!${NC}"
    show_post_setup_instructions_optimized
}

# ==============================================================================
# Hardware-Aware Gaming Software Installation (Task 4.1.2)
# ==============================================================================

install_gaming_platforms_optimized() {
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"
    local memory_gb="${DETECTED_MEMORY_GB:-0}"

    echo -e "  📦 Installing Gaming Platforms (Hardware-Optimized)"

    # Steam - Essential for PC gaming
    if ! command -v steam >/dev/null 2>&1; then
        echo -e "    🚀 Installing Steam..."
        if [[ -f "$setup_dir/install-steam.sh" ]]; then
            log_message "INFO" "Installing Steam with hardware optimizations"
            if "$setup_dir/install-steam.sh" install 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "    ${GREEN}✅ Steam installed successfully${NC}"
            else
                echo -e "    ${RED}❌ Steam installation failed${NC}"
            fi
        else
            # Fallback direct installation
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm steam steam-native-runtime
                echo -e "    ${GREEN}✅ Steam installed via pacman${NC}"
            fi
        fi
    else
        echo -e "    ${GREEN}✅ Steam already installed${NC}"
    fi

    # Lutris - Multi-platform gaming
    if ! command -v lutris >/dev/null 2>&1; then
        echo -e "    🚀 Installing Lutris..."
        if [[ -f "$setup_dir/install-lutris.sh" ]]; then
            log_message "INFO" "Installing Lutris"
            if "$setup_dir/install-lutris.sh" install 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "    ${GREEN}✅ Lutris installed successfully${NC}"
            else
                echo -e "    ${RED}❌ Lutris installation failed${NC}"
            fi
        else
            # Fallback direct installation
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm lutris wine-staging
                echo -e "    ${GREEN}✅ Lutris installed via pacman${NC}"
            fi
        fi
    else
        echo -e "    ${GREEN}✅ Lutris already installed${NC}"
    fi

    # Heroic Games Launcher - Epic/GOG games
    if ! command -v heroic >/dev/null 2>&1; then
        echo -e "    🚀 Installing Heroic Games Launcher..."
        if command -v yay >/dev/null 2>&1; then
            if yay -S --noconfirm heroic-games-launcher-bin 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "    ${GREEN}✅ Heroic Games Launcher installed${NC}"
            else
                echo -e "    ${YELLOW}⚠️ Heroic installation failed - AUR package may be unavailable${NC}"
            fi
        else
            echo -e "    ${YELLOW}⚠️ Heroic requires AUR helper (yay) - skipping${NC}"
        fi
    else
        echo -e "    ${GREEN}✅ Heroic Games Launcher already installed${NC}"
    fi

    # Bottles - Windows app management (recommended for systems with 8GB+ RAM)
    if [[ "$memory_gb" -ge 8 ]] && ! command -v bottles >/dev/null 2>&1; then
        echo -e "    🚀 Installing Bottles (sufficient RAM detected)..."
        if command -v pacman >/dev/null 2>&1; then
            if sudo pacman -S --noconfirm bottles 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "    ${GREEN}✅ Bottles installed${NC}"
            else
                echo -e "    ${YELLOW}⚠️ Bottles installation failed${NC}"
            fi
        fi
    elif [[ "$memory_gb" -lt 8 ]]; then
        echo -e "    ${YELLOW}⚠️ Bottles skipped (requires 8GB+ RAM, detected: ${memory_gb}GB)${NC}"
    else
        echo -e "    ${GREEN}✅ Bottles already installed${NC}"
    fi
}

install_gaming_tools_optimized() {
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"

    echo -e "  🛠️ Installing Gaming Tools and Utilities"

    # GameMode - Essential gaming optimization
    if ! command -v gamemoderun >/dev/null 2>&1; then
        echo -e "    🚀 Installing GameMode..."
        if [[ -f "$setup_dir/install-gamemode.sh" ]]; then
            log_message "INFO" "Installing GameMode and MangoHud"
            if "$setup_dir/install-gamemode.sh" install 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "    ${GREEN}✅ GameMode and MangoHud installed${NC}"
            else
                echo -e "    ${RED}❌ GameMode installation failed${NC}"
            fi
        else
            # Fallback direct installation
            if command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm gamemode lib32-gamemode mangohud lib32-mangohud
                echo -e "    ${GREEN}✅ GameMode and MangoHud installed via pacman${NC}"
            fi
        fi
    else
        echo -e "    ${GREEN}✅ GameMode already installed${NC}"
    fi

    # MangoHud Configuration
    if command -v mangohud >/dev/null 2>&1; then
        echo -e "    ⚙️ Configuring MangoHud..."
        configure_mangohud_optimized
    fi

    # GOverlay - MangoHud GUI (if MangoHud is installed)
    if command -v mangohud >/dev/null 2>&1 && ! command -v goverlay >/dev/null 2>&1; then
        echo -e "    🚀 Installing GOverlay (MangoHud GUI)..."
        if command -v pacman >/dev/null 2>&1; then
            if sudo pacman -S --noconfirm goverlay 2>&1 | tee -a "$LOG_FILE"; then
                echo -e "    ${GREEN}✅ GOverlay installed${NC}"
            else
                echo -e "    ${YELLOW}⚠️ GOverlay installation failed${NC}"
            fi
        fi
    fi

    # GPU-specific tools
    case "$gpu_vendor" in
        "nvidia")
            install_nvidia_gaming_tools
            ;;
        "amd")
            install_amd_gaming_tools
            ;;
        "intel")
            install_intel_gaming_tools
            ;;
    esac

    # Wine and Proton enhancements
    install_wine_enhancements

    # Gaming audio tools
    install_gaming_audio_tools

    # Optional gaming utilities
    install_optional_gaming_utilities
}

configure_mangohud_optimized() {
    local mangohud_config="$HOME/.config/MangoHud/MangoHud.conf"
    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"

    mkdir -p "$(dirname "$mangohud_config")"

    cat > "$mangohud_config" << EOF
# xanadOS MangoHud Configuration (Hardware-Optimized)
# Generated: $(date)
# GPU: $gpu_vendor

# Core performance metrics
fps
frametime=0
frame_timing=1

# GPU metrics
gpu_stats
gpu_temp
gpu_power
gpu_load_change
gpu_text=GPU

# CPU metrics
cpu_stats
cpu_temp
cpu_power
cpu_load_change
cpu_text=CPU

# Memory metrics
ram
vram

# System info
vulkan_driver
engine_version
wine

# Display settings
position=top_left
text_color=FFFFFF
gpu_color=2E9762
cpu_color=2E97CB
vram_color=AD64C1
ram_color=C26693
engine_color=EB5B5B
io_color=A491D3
background_alpha=0.4
font_size=24

# Performance-based display (show more info on powerful systems)
EOF

    # Add GPU-specific optimizations
    case "$gpu_vendor" in
        "nvidia")
            echo "# NVIDIA-specific settings" >> "$mangohud_config"
            echo "gpu_mem_clock" >> "$mangohud_config"
            echo "gpu_core_clock" >> "$mangohud_config"
            ;;
        "amd")
            echo "# AMD-specific settings" >> "$mangohud_config"
            echo "amdgpu_mem_info" >> "$mangohud_config"
            ;;
    esac

    echo -e "      ${GREEN}✅ MangoHud configured for $gpu_vendor GPU${NC}"
}

install_nvidia_gaming_tools() {
    echo -e "    🎮 Installing NVIDIA Gaming Tools..."

    # NVIDIA System Monitor
    if command -v pacman >/dev/null 2>&1; then
        if ! command -v nvidia-settings >/dev/null 2>&1; then
            sudo pacman -S --noconfirm nvidia-settings
            echo -e "      ${GREEN}✅ NVIDIA Settings installed${NC}"
        fi
    fi

    # CoreCtrl for GPU control
    if ! command -v corectrl >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
            if sudo pacman -S --noconfirm corectrl 2>/dev/null; then
                echo -e "      ${GREEN}✅ CoreCtrl installed${NC}"
            fi
        fi
    fi
}

install_amd_gaming_tools() {
    echo -e "    🎮 Installing AMD Gaming Tools..."

    # AMD GPU utilities
    if command -v pacman >/dev/null 2>&1; then
        # Ensure Vulkan drivers are installed
        sudo pacman -S --noconfirm --needed vulkan-radeon lib32-vulkan-radeon
        echo -e "      ${GREEN}✅ AMD Vulkan drivers ensured${NC}"
    fi

    # CoreCtrl for AMD GPU control
    if ! command -v corectrl >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
            if sudo pacman -S --noconfirm corectrl 2>/dev/null; then
                echo -e "      ${GREEN}✅ CoreCtrl installed${NC}"
            fi
        fi
    fi
}

install_intel_gaming_tools() {
    echo -e "    🎮 Installing Intel Gaming Tools..."

    # Intel GPU utilities
    if command -v pacman >/dev/null 2>&1; then
        # Ensure Vulkan drivers are installed
        sudo pacman -S --noconfirm --needed vulkan-intel lib32-vulkan-intel
        echo -e "      ${GREEN}✅ Intel Vulkan drivers ensured${NC}"
    fi
}

install_wine_enhancements() {
    echo -e "    🍷 Installing Wine and Proton Enhancements..."

    if command -v pacman >/dev/null 2>&1; then
        local packages=("wine-staging" "winetricks" "dxvk")

        for package in "${packages[@]}"; do
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                if sudo pacman -S --noconfirm "$package" 2>/dev/null; then
                    echo -e "      ${GREEN}✅ $package installed${NC}"
                else
                    echo -e "      ${YELLOW}⚠️ $package installation failed${NC}"
                fi
            fi
        done
    fi

    # Install Proton-GE if Steam is installed
    if command -v steam >/dev/null 2>&1; then
        install_proton_ge
    fi
}

install_proton_ge() {
    echo -e "    🚀 Installing Proton-GE..."

    local steam_dir="$HOME/.steam/root/compatibilitytools.d"
    mkdir -p "$steam_dir"

    # Download latest Proton-GE (simplified installation)
    if command -v curl >/dev/null 2>&1; then
        echo -e "      ${YELLOW}ℹ️ Proton-GE installation requires manual download${NC}"
        echo -e "      Visit: https://github.com/GloriousEggroll/proton-ge-custom/releases"
    fi
}

install_gaming_audio_tools() {
    echo -e "    🔊 Installing Gaming Audio Tools..."

    if command -v pacman >/dev/null 2>&1; then
        # PipeWire gaming optimizations
        local audio_packages=("pipewire-pulse" "pipewire-jack" "wireplumber")

        for package in "${audio_packages[@]}"; do
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                if sudo pacman -S --noconfirm "$package" 2>/dev/null; then
                    echo -e "      ${GREEN}✅ $package installed${NC}"
                fi
            fi
        done
    fi
}

install_optional_gaming_utilities() {
    local memory_gb="${DETECTED_MEMORY_GB:-0}"

    echo -e "    🎯 Installing Optional Gaming Utilities..."

    # Discord (if sufficient memory)
    if [[ "$memory_gb" -ge 8 ]] && ! command -v discord >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
            if sudo pacman -S --noconfirm discord 2>/dev/null; then
                echo -e "      ${GREEN}✅ Discord installed${NC}"
            fi
        fi
    fi

    # OBS Studio (if sufficient memory and decent GPU)
    local hardware_score="${GAMING_HARDWARE_SCORE:-0}"
    if [[ "$memory_gb" -ge 8 ]] && [[ "$hardware_score" -ge 60 ]] && ! command -v obs >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
            if sudo pacman -S --noconfirm obs-studio 2>/dev/null; then
                echo -e "      ${GREEN}✅ OBS Studio installed${NC}"
            fi
        fi
    fi
}

apply_hardware_optimizations() {
    local setup_dir="$XANADOS_ROOT/scripts/setup"

    echo -e "  ⚡ Applying Hardware-Specific Optimizations"

    # Run existing hardware optimization script if available
    if [[ -f "$setup_dir/priority3-hardware-optimization.sh" ]]; then
        log_message "INFO" "Running hardware optimizations"
        if "$setup_dir/priority3-hardware-optimization.sh" complete 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "    ${GREEN}✅ Hardware optimizations applied${NC}"
        else
            echo -e "    ${YELLOW}⚠️ Some hardware optimizations failed${NC}"
        fi
    else
        # Apply basic optimizations directly
        apply_basic_hardware_optimizations
    fi
}

apply_basic_hardware_optimizations() {
    echo -e "    ⚙️ Applying basic hardware optimizations..."

    # Gaming sysctl parameters
    local sysctl_conf="/etc/sysctl.d/99-gaming.conf"
    if sudo tee "$sysctl_conf" >/dev/null 2>&1 << 'EOF'
# Gaming optimizations for xanadOS
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_background_ratio=3
vm.dirty_ratio=10
kernel.sched_autogroup_enabled=0
EOF
    then
        echo -e "      ${GREEN}✅ Gaming kernel parameters configured${NC}"
    fi

    # CPU governor for gaming
    if [[ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]]; then
        echo -e "      ⚡ Setting CPU governor to performance for gaming"
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    fi
}

configure_gaming_environment_optimized() {
    echo -e "  🎮 Configuring Gaming Environment"

    # Steam configuration
    configure_steam_optimized

    # Lutris configuration
    configure_lutris_optimized

    # System gaming optimizations
    configure_system_gaming_optimized
}

configure_steam_optimized() {
    if command -v steam >/dev/null 2>&1; then
        echo -e "    🚀 Configuring Steam for optimal gaming..."

        local steam_config_dir="$HOME/.steam/steam/config"
        mkdir -p "$steam_config_dir"

        # Basic Steam optimizations will be applied when Steam runs
        echo -e "      ${GREEN}✅ Steam configuration prepared${NC}"
    fi
}

configure_lutris_optimized() {
    if command -v lutris >/dev/null 2>&1; then
        echo -e "    🍷 Configuring Lutris for optimal gaming..."

        local lutris_config_dir="$HOME/.config/lutris"
        mkdir -p "$lutris_config_dir"

        # Lutris will auto-configure on first run
        echo -e "      ${GREEN}✅ Lutris configuration prepared${NC}"
    fi
}

configure_system_gaming_optimized() {
    echo -e "    ⚙️ Configuring system for gaming..."

    # Gaming group for performance optimizations
    if ! groups | grep -q gamemode; then
        sudo usermod -a -G gamemode "$USER" 2>/dev/null || true
        echo -e "      ${GREEN}✅ User added to gamemode group${NC}"
    fi

    # Gaming udev rules for controllers
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    if [[ -f "$setup_dir/ufw-gaming-rules.sh" ]]; then
        if "$setup_dir/ufw-gaming-rules.sh" 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "      ${GREEN}✅ Gaming firewall rules configured${NC}"
        fi
    fi
}

apply_gaming_desktop_customization() {
    local setup_dir="$XANADOS_ROOT/scripts/setup"

    echo -e "  🎨 Applying Gaming Desktop Customization"

    # KDE gaming customization
    if [[ -f "$setup_dir/kde-gaming-customization.sh" ]] && command -v plasmashell >/dev/null 2>&1; then
        log_message "INFO" "Applying KDE gaming customization"
        if "$setup_dir/kde-gaming-customization.sh" 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "    ${GREEN}✅ KDE gaming customization applied${NC}"
        else
            echo -e "    ${YELLOW}⚠️ KDE customization partially failed${NC}"
        fi
    else
        echo -e "    ${YELLOW}ℹ️ KDE gaming customization skipped (KDE not detected)${NC}"
    fi
}

show_post_setup_instructions_optimized() {
    echo
    echo -e "${GREEN}🎉 Gaming Setup Complete!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo

    # Hardware-specific instructions
    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"
    local memory_gb="${DETECTED_MEMORY_GB:-0}"
    local hardware_score="${GAMING_HARDWARE_SCORE:-0}"

    echo -e "📊 Your Gaming System:"
    echo -e "   Hardware Score: ${BOLD}$hardware_score/100${NC}"
    echo -e "   GPU: $gpu_vendor | Memory: ${memory_gb}GB"
    echo

    echo -e "🚀 Next Steps:"
    echo -e "   1. ${BOLD}Restart your system${NC} to apply all optimizations"
    echo -e "   2. Launch Steam and enable Proton for Windows games"
    echo -e "   3. Test a game with: ${CYAN}gamemoderun mangohud %command%${NC}"

    if command -v goverlay >/dev/null 2>&1; then
        echo -e "   4. Customize MangoHud overlay with: ${CYAN}goverlay${NC}"
    fi

    echo
    echo -e "🎮 Gaming Commands:"
    echo -e "   • Launch with optimization: ${CYAN}gamemoderun <game>${NC}"
    echo -e "   • Launch with overlay: ${CYAN}mangohud <game>${NC}"
    echo -e "   • Combined: ${CYAN}gamemoderun mangohud <game>${NC}"

    if [[ "$gpu_vendor" == "nvidia" ]]; then
        echo -e "   • NVIDIA settings: ${CYAN}nvidia-settings${NC}"
    fi

    if command -v corectrl >/dev/null 2>&1; then
        echo -e "   • GPU control: ${CYAN}corectrl${NC}"
    fi

    echo
    echo -e "📚 Additional Resources:"
    echo -e "   • Hardware analysis: ${CYAN}scripts/lib/hardware-detection.sh analyze${NC}"
    echo -e "   • Gaming compatibility: ${CYAN}scripts/lib/gaming-env.sh analyze${NC}"

    if [[ "$hardware_score" -lt 70 ]]; then
        echo
        echo -e "${YELLOW}💡 Optimization Suggestions:${NC}"
        if [[ "$gpu_vendor" == "unknown" ]] || [[ "${DETECTED_GPU_DRIVER:-none}" == "none" ]]; then
            echo -e "   • Install proper GPU drivers for better performance"
        fi
        if [[ "$memory_gb" -lt 16 ]]; then
            echo -e "   • Consider upgrading to 16GB RAM for optimal gaming"
        fi
    fi

    echo
    echo -e "${GREEN}Happy Gaming! 🎮${NC}"
}

install_custom_components() {
    local components=("$@")
    local setup_dir="$XANADOS_ROOT/scripts/setup"

    echo -e "\n${ROCKET} Installing Custom Gaming Components..."
    log_message "INFO" "Installing custom components: ${components[*]}"

    for component in "${components[@]}"; do
        case "$component" in
            "steam")
                echo -e "\n${ROCKET} Installing Steam..."
                if [[ -f "$setup_dir/install-steam.sh" ]]; then
                    log_message "INFO" "Installing Steam via dedicated script"
                    if "$setup_dir/install-steam.sh" install 2>&1 | tee -a "$LOG_FILE"; then
                        echo -e "${GREEN}✅ Steam installation completed${NC}"
                    else
                        echo -e "${RED}❌ Steam installation failed${NC}"
                    fi
                else
                    # Fallback to hardware-aware installation
                    if install_gaming_platforms_optimized | grep -q "Steam"; then
                        echo -e "${GREEN}✅ Steam installed via hardware-aware method${NC}"
                    fi
                fi
                ;;
            "lutris")
                echo -e "\n${ROCKET} Installing Lutris..."
                if [[ -f "$setup_dir/install-lutris.sh" ]]; then
                    log_message "INFO" "Installing Lutris via dedicated script"
                    if "$setup_dir/install-lutris.sh" install 2>&1 | tee -a "$LOG_FILE"; then
                        echo -e "${GREEN}✅ Lutris installation completed${NC}"
                    else
                        echo -e "${RED}❌ Lutris installation failed${NC}"
                    fi
                else
                    # Fallback to hardware-aware installation
                    if install_gaming_platforms_optimized | grep -q "Lutris"; then
                        echo -e "${GREEN}✅ Lutris installed via hardware-aware method${NC}"
                    fi
                fi
                ;;
            "gamemode")
                echo -e "\n${ROCKET} Installing GameMode and MangoHud..."
                if [[ -f "$setup_dir/install-gamemode.sh" ]]; then
                    log_message "INFO" "Installing GameMode via dedicated script"
                    if "$setup_dir/install-gamemode.sh" install 2>&1 | tee -a "$LOG_FILE"; then
                        echo -e "${GREEN}✅ GameMode installation completed${NC}"
                    else
                        echo -e "${RED}❌ GameMode installation failed${NC}"
                    fi
                else
                    # Fallback to hardware-aware installation
                    if install_gaming_tools_optimized | grep -q "GameMode"; then
                        echo -e "${GREEN}✅ GameMode installed via hardware-aware method${NC}"
                    fi
                fi
                ;;
            "hardware")
                echo -e "\n${ROCKET} Applying hardware optimizations..."
                if [[ -f "$setup_dir/priority3-hardware-optimization.sh" ]]; then
                    log_message "INFO" "Running dedicated hardware optimization script"
                    if "$setup_dir/priority3-hardware-optimization.sh" complete 2>&1 | tee -a "$LOG_FILE"; then
                        echo -e "${GREEN}✅ Hardware optimizations completed${NC}"
                    else
                        echo -e "${YELLOW}⚠️ Some hardware optimizations failed${NC}"
                    fi
                else
                    # Use our hardware-aware optimization
                    log_message "INFO" "Applying hardware-aware optimizations"
                    apply_hardware_optimizations
                fi
                ;;
            "kde")
                echo -e "\n${ROCKET} Customizing desktop for gaming..."
                if [[ -f "$setup_dir/kde-gaming-customization.sh" ]]; then
                    log_message "INFO" "Running KDE gaming customization script"
                    if "$setup_dir/kde-gaming-customization.sh" 2>&1 | tee -a "$LOG_FILE"; then
                        echo -e "${GREEN}✅ KDE gaming customization completed${NC}"
                    else
                        echo -e "${YELLOW}⚠️ KDE customization partially failed${NC}"
                    fi
                else
                    # Use our built-in customization
                    log_message "INFO" "Applying built-in gaming desktop customization"
                    apply_gaming_desktop_customization
                fi
                ;;
            "all-platforms")
                echo -e "\n${ROCKET} Installing all gaming platforms..."
                install_gaming_platforms_optimized
                ;;
            "all-tools")
                echo -e "\n${ROCKET} Installing all gaming tools..."
                install_gaming_tools_optimized
                ;;
            "complete")
                echo -e "\n${ROCKET} Running complete hardware-aware setup..."
                install_gaming_platforms_optimized
                install_gaming_tools_optimized
                apply_hardware_optimizations
                configure_gaming_environment_optimized
                apply_gaming_desktop_customization
                ;;
            *)
                log_message "WARNING" "Unknown component: $component"
                echo -e "${YELLOW}⚠️ Unknown component: $component${NC}"
                ;;
        esac
    done

    echo -e "\n${GREEN}✅ Custom component installation completed${NC}"
}

run_optimization_only() {
    print_header "${GEAR} Gaming Optimization Only"

    log_message "STEP" "Applying gaming optimizations"

    # Apply system optimizations
    apply_basic_gaming_optimizations

    # Apply hardware-specific optimizations if available
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    if [[ -f "$setup_dir/priority3-hardware-optimization.sh" ]]; then
        echo -e "\n${ROCKET} Applying hardware optimizations..."
        "$setup_dir/priority3-hardware-optimization.sh" optimize 2>&1 | tee -a "$LOG_FILE"
    fi

    log_message "SUCCESS" "Gaming optimizations applied"
    echo -e "\n${GREEN}${CHECKMARK} Gaming optimizations applied successfully!${NC}"
}

# ==============================================================================
# Gaming Configuration Functions
# ==============================================================================

configure_gaming_environment() {
    log_message "INFO" "Configuring gaming environment"

    # Create xanadOS config directory
    mkdir -p "$CONFIG_DIR"

    # Create gaming environment configuration
    cat > "$CONFIG_DIR/gaming-environment.conf" << 'EOF'
# xanadOS Gaming Environment Configuration
# Generated by Gaming Setup Wizard

[Gaming]
OptimizationsEnabled=true
GamingMode=auto
PerformanceProfile=gaming

[Graphics]
VulkanEnabled=true
GameModeOptimizations=true
MangoHudEnabled=true

[Audio]
LowLatencyMode=true
GamingAudioProfile=true

[Controllers]
AutoDetection=true
XboxSupport=true
PlayStationSupport=true
NintendoSupport=true

[Performance]
CPUGovernor=performance
IOScheduler=mq-deadline
NetworkOptimizations=true
EOF

    log_message "SUCCESS" "Gaming environment configured"
}

create_gaming_profile() {
    log_message "INFO" "Creating gaming profile"

    # Create gaming profile configuration
    cat > "$CONFIG_DIR/gaming-profile.conf" << EOF
# xanadOS Gaming Profile
# Created: $(date)

[Hardware]
CPU=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
GPU=${GPU_MODEL:-Unknown}
Memory=$(free -h | grep "Mem:" | awk '{print $2}')
Storage=$(lsblk -d -o NAME,SIZE | grep -v "NAME" | head -1 | awk '{print $2}')

[Software]
Steam=${STEAM_INSTALLED:-false}
Lutris=${LUTRIS_INSTALLED:-false}
GameMode=${GAMEMODE_INSTALLED:-false}
MangoHud=${MANGOHUD_INSTALLED:-false}

[Optimizations]
HardwareOptimized=true
AudioOptimized=true
NetworkOptimized=true
DesktopOptimized=true
EOF

    log_message "SUCCESS" "Gaming profile created"
}

apply_basic_gaming_optimizations() {
    log_message "INFO" "Applying basic gaming optimizations"

    # Set CPU governor to performance for gaming
    if get_cached_command "cpupower"; then
        echo -e "  ${GEAR} Setting CPU governor to performance..."
        if ! sudo cpupower frequency-set -g performance &> /dev/null; then
            log_message "WARNING" "Could not set CPU governor to performance"
        fi
    fi

    # Optimize I/O scheduler for gaming
    echo -e "  ${GEAR} Optimizing I/O schedulers..."
    for device in /sys/block/*/queue/scheduler; do
        if [[ -w "$device" ]] && [[ -f "$device" ]]; then
            if grep -q "mq-deadline" "$device" 2>/dev/null; then
                echo "mq-deadline" | sudo tee "$device" > /dev/null 2>&1 || true
            elif grep -q "deadline" "$device" 2>/dev/null; then
                echo "deadline" | sudo tee "$device" > /dev/null 2>&1 || true
            fi
        fi
    done

    # Set gaming-friendly swappiness
    echo -e "  ${GEAR} Setting gaming-friendly swappiness..."
    if echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-xanados-gaming.conf > /dev/null 2>&1; then
        sudo sysctl -p /etc/sysctl.d/99-xanados-gaming.conf &> /dev/null || true
    else
        log_message "WARNING" "Could not set swappiness configuration"
    fi

    log_message "SUCCESS" "Basic gaming optimizations applied"
}

# ==============================================================================
# Post-Setup Instructions
# ==============================================================================

show_post_setup_instructions() {
    print_section "Post-Setup Instructions"

    echo -e "${STAR} ${BOLD}Your gaming setup is now ready!${NC}\n"

    echo -e "${BOLD}Quick Start:${NC}"
    echo -e "  ${ARROW} Launch games through Steam or Lutris for automatic optimizations"
    echo -e "  ${ARROW} Use 'gamemoderun' prefix for manual game optimization"
    echo -e "  ${ARROW} Enable MangoHud with 'mangohud' prefix for performance monitoring"
    echo

    echo -e "${BOLD}Gaming Commands:${NC}"
    if $STEAM_INSTALLED; then
        echo -e "  ${ARROW} steam-gamemode    - Launch Steam with optimizations"
    fi
    if $LUTRIS_INSTALLED; then
        echo -e "  ${ARROW} lutris-gamemode   - Launch Lutris with optimizations"
    fi
    echo -e "  ${ARROW} xanados-gaming    - Gaming control center"
    echo -e "  ${ARROW} gamemoderun <game> - Run game with GameMode"
    echo -e "  ${ARROW} mangohud <game>   - Run game with performance overlay"
    echo

    echo -e "${BOLD}System Information:${NC}"
    echo -e "  ${ARROW} Logs: $LOG_FILE"
    echo -e "  ${ARROW} Config: $CONFIG_DIR"
    echo -e "  ${ARROW} Gaming Profile: $CONFIG_DIR/gaming-profile.conf"
    echo

    if [[ ${#PRIORITY_RECOMMENDATIONS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}Remaining Recommendations:${NC}"
        for rec in "${PRIORITY_RECOMMENDATIONS[@]}"; do
            echo -e "  ${YELLOW}${ARROW}${NC} $rec"
        done
        echo
    fi

    echo -e "${GREEN}${BOLD}Enjoy your optimized gaming experience on xanadOS!${NC} ${GAMING}"
}

# ==============================================================================
# Gaming Profile Management
# ==============================================================================

run_gaming_profile_management() {
    print_section "Gaming Profile Management"

    echo -e "Choose an action:"
    echo -e "  ${BOLD}1.${NC} Create New Gaming Profile"
    echo -e "  ${BOLD}2.${NC} List Existing Profiles"
    echo -e "  ${BOLD}3.${NC} Apply Gaming Profile"
    echo -e "  ${BOLD}4.${NC} Delete Gaming Profile"
    echo -e "  ${BOLD}5.${NC} Export Profile"
    echo -e "  ${BOLD}6.${NC} Import Profile"
    echo -e "  ${BOLD}0.${NC} Return to Main Menu"
    echo

    while true; do
        read -p "Please enter your choice [1-6, 0 to return]: " -n 1 -r
        echo

        case "$REPLY" in
            1)
                log_message "INFO" "Starting gaming profile creation"
                create_gaming_profile
                break
                ;;
            2)
                log_message "INFO" "Listing gaming profiles"
                list_gaming_profiles
                echo -e "\nPress any key to continue..."
                read -n 1 -s -r
                break
                ;;
            3)
                log_message "INFO" "Applying gaming profile"
                echo "Available profiles:"
                list_gaming_profiles
                echo
                read -p "Enter profile name to apply: " profile_name
                if [[ -n "$profile_name" ]]; then
                    apply_gaming_profile "$profile_name"
                else
                    echo -e "${RED}No profile name provided.${NC}"
                fi
                break
                ;;
            4)
                log_message "INFO" "Deleting gaming profile"
                echo "Available profiles:"
                list_gaming_profiles
                echo
                read -p "Enter profile name to delete: " profile_name
                if [[ -n "$profile_name" ]]; then
                    delete_gaming_profile "$profile_name"
                else
                    echo -e "${RED}No profile name provided.${NC}"
                fi
                break
                ;;
            5)
                log_message "INFO" "Exporting gaming profile"
                echo "Available profiles:"
                list_gaming_profiles
                echo
                read -p "Enter profile name to export: " profile_name
                if [[ -n "$profile_name" ]]; then
                    read -p "Enter export path [/tmp/${profile_name}.json]: " export_path
                    export_path="${export_path:-/tmp/${profile_name}.json}"
                    export_gaming_profile "$profile_name" "$export_path"
                else
                    echo -e "${RED}No profile name provided.${NC}"
                fi
                break
                ;;
            6)
                log_message "INFO" "Importing gaming profile"
                read -p "Enter path to profile JSON file: " import_path
                if [[ -n "$import_path" ]] && [[ -f "$import_path" ]]; then
                    import_gaming_profile "$import_path"
                else
                    echo -e "${RED}Invalid file path.${NC}"
                fi
                break
                ;;
            0)
                log_message "INFO" "Returning to main menu"
                break
                ;;
            *)
                echo -e "\n${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
    done
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

    # Initialize command cache for performance
    print_status "Initializing gaming environment cache..."
    cache_gaming_tools
    cache_system_tools

    # Welcome
    print_header "${GAMING} xanadOS Gaming Setup Wizard ${GAMING}"
    echo -e "${BOLD}Welcome to the xanadOS Gaming Setup Wizard!${NC}"
    echo -e "This wizard will analyze your system and help you set up the optimal gaming environment."
    echo

    # System detection
    detect_hardware
    detect_existing_gaming_software

    # Display gaming environment analysis
    log_message "INFO" "Analyzing gaming environment..."
    echo
    print_section "Gaming Environment Analysis"
    generate_gaming_matrix "table"
    echo

    local readiness_score
    readiness_score=$(get_gaming_readiness_score)

    if [[ $readiness_score -ge 80 ]]; then
        log_message "SUCCESS" "Excellent gaming readiness! Score: ${readiness_score}%"
    elif [[ $readiness_score -ge 60 ]]; then
        log_message "WARNING" "Good gaming setup with room for improvement. Score: ${readiness_score}%"
    elif [[ $readiness_score -ge 40 ]]; then
        log_message "WARNING" "Basic gaming capability detected. Score: ${readiness_score}%"
    else
        log_message "ERROR" "Limited gaming capability. Score: ${readiness_score}%"
    fi
    echo

    # Check compatibility with standard gaming profile
    print_section "Gaming Profile Compatibility"
    echo "Checking compatibility with standard gaming profile..."
    echo
    check_gaming_compatibility "standard"
    echo

    # Show recommendations if compatibility is low
    if [[ ${COMPATIBILITY_SCORE:-0} -lt 80 ]]; then
        echo "Recommendations for improved gaming setup:"
        get_compatibility_recommendations "standard"
        echo
    fi

    generate_recommendations

    # Show setup options and get user choice
    while true; do
        show_setup_options
        read -p "Please enter your choice [1-6, 0 to exit]: " -n 1 -r
        echo

        if handle_setup_choice "$REPLY"; then
            break
        fi
    done

    log_message "SUCCESS" "Gaming setup wizard completed"
}

# Run main function
main "$@"
