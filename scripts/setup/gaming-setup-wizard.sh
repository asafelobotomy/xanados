#!/bin/bash

# ==============================================================================
# xanadOS Gaming Setup Wizard
# ==============================================================================
# Description: Comprehensive gaming setup wizard with hardware detection,
#              software installation, and optimization recommendations
# Author: xanadOS Development Team
# Version: 1.0.0
# License: MIT
# ==============================================================================

set -euo pipefail

# Source xanadOS shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gaming-env.sh"

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
    log_message "INFO" "Starting hardware detection"
    
    print_section "Hardware Detection & Analysis"
    
    # Create temp directory for detection
    mkdir -p "$TEMP_DIR"
    
    # CPU Detection
    local cpu_info=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    local cpu_cores=$(nproc)
    local cpu_threads=$(lscpu | grep "CPU(s):" | head -1 | awk '{print $2}')
    
    echo -e "  ${GEAR} CPU: ${BOLD}$cpu_info${NC}"
    echo -e "      Cores: $cpu_cores, Threads: $cpu_threads"
    
    # Memory Detection
    local mem_total=$(free -h | grep "Mem:" | awk '{print $2}')
    local mem_available=$(free -h | grep "Mem:" | awk '{print $7}')
    
    echo -e "  ${GEAR} Memory: ${BOLD}$mem_total${NC} total, $mem_available available"
    
    # GPU Detection
    detect_gpu
    
    # Storage Detection
    detect_storage
    
    # Audio Detection
    detect_audio
    
    # Controller Detection
    detect_controllers
    
    # Network Detection
    detect_network
    
    log_message "SUCCESS" "Hardware detection completed"
}

detect_gpu() {
    echo -e "  ${GEAR} Graphics:"
    
    # NVIDIA Detection
    if get_cached_command "nvidia-smi"; then
        local nvidia_gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "NVIDIA GPU")
        local nvidia_driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "Unknown")
        echo -e "      ${GREEN}NVIDIA: $nvidia_gpu (Driver: $nvidia_driver)${NC}"
        GPU_VENDOR="nvidia"
        GPU_MODEL="$nvidia_gpu"
        GPU_DRIVER="$nvidia_driver"
    fi
    
    # AMD Detection
    if lspci | grep -i "VGA.*AMD\|VGA.*ATI" &> /dev/null; then
        local amd_gpu=$(lspci | grep -i "VGA.*AMD\|VGA.*ATI" | cut -d: -f3 | xargs || echo "AMD GPU")
        echo -e "      ${RED}AMD: $amd_gpu${NC}"
        if [[ -z "${GPU_VENDOR:-}" ]]; then
            GPU_VENDOR="amd"
            GPU_MODEL="$amd_gpu"
        fi
    fi
    
    # Intel Detection
    if lspci | grep -i "VGA.*Intel" &> /dev/null; then
        local intel_gpu=$(lspci | grep -i "VGA.*Intel" | cut -d: -f3 | xargs || echo "Intel GPU")
        echo -e "      ${BLUE}Intel: $intel_gpu${NC}"
        if [[ -z "${GPU_VENDOR:-}" ]]; then
            GPU_VENDOR="intel"
            GPU_MODEL="$intel_gpu"
        fi
    fi
    
    # Vulkan Support
    if get_cached_command "vulkaninfo"; then
        echo -e "      ${GREEN}Vulkan: Supported${NC}"
        VULKAN_SUPPORT=true
    else
        echo -e "      ${YELLOW}Vulkan: Not detected${NC}"
        VULKAN_SUPPORT=false
    fi
}

detect_storage() {
    echo -e "  ${GEAR} Storage:"
    
    local storage_info
    storage_info=$(lsblk -d -o NAME,SIZE,MODEL,ROTA 2>/dev/null | grep -v "NAME" || echo "")
    
    if [[ -z "$storage_info" ]]; then
        echo -e "      ${YELLOW}Storage information unavailable${NC}"
        return
    fi
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local device=$(echo "$line" | awk '{print $1}' || echo "unknown")
            local size=$(echo "$line" | awk '{print $2}' || echo "unknown")
            local model=$(echo "$line" | awk '{$1=$2=""; print $0}' | xargs || echo "Unknown Model")
            local is_rotational=$(echo "$line" | awk '{print $NF}' || echo "1")
            
            if [[ "$is_rotational" == "0" ]]; then
                echo -e "      ${GREEN}SSD: $device ($size) - $model${NC}"
                HAS_SSD=true
            else
                echo -e "      ${YELLOW}HDD: $device ($size) - $model${NC}"
                HAS_HDD=true
            fi
        fi
    done <<< "$storage_info"
}

detect_audio() {
    echo -e "  ${GEAR} Audio:"
    
    # PipeWire Detection
    if systemctl --user is-active pipewire &> /dev/null; then
        echo -e "      ${GREEN}PipeWire: Active${NC}"
        AUDIO_SYSTEM="pipewire"
    elif systemctl --user is-active pulseaudio &> /dev/null; then
        echo -e "      ${YELLOW}PulseAudio: Active${NC}"
        AUDIO_SYSTEM="pulseaudio"
    else
        echo -e "      ${RED}No audio system detected${NC}"
        AUDIO_SYSTEM="none"
    fi
    
    # Audio Devices
    local audio_devices
    audio_devices=$(aplay -l 2>/dev/null | grep -c "card" || echo "0")
    echo -e "      Audio Devices: $audio_devices"
}

detect_controllers() {
    echo -e "  ${GEAR} Controllers:"
    
    local controllers_found=0
    
    # Xbox Controllers
    if lsusb | grep -i "microsoft.*xbox\|microsoft.*controller" &> /dev/null; then
        echo -e "      ${GREEN}Xbox Controller detected${NC}"
        ((controllers_found++))
        XBOX_CONTROLLER=true
    fi
    
    # PlayStation Controllers
    if lsusb | grep -i "sony.*interactive\|sony.*computer\|sony.*playstation" &> /dev/null; then
        echo -e "      ${GREEN}PlayStation Controller detected${NC}"
        ((controllers_found++))
        PS_CONTROLLER=true
    fi
    
    # Nintendo Controllers
    if lsusb | grep -i "nintendo" &> /dev/null; then
        echo -e "      ${GREEN}Nintendo Controller detected${NC}"
        ((controllers_found++))
        NINTENDO_CONTROLLER=true
    fi
    
    # Generic Controllers
    local js_devices
    js_devices=$(find /dev/input -name "js*" 2>/dev/null | wc -l || echo "0")
    if [[ $js_devices -gt 0 ]]; then
        echo -e "      Generic Controllers: $js_devices"
        ((controllers_found += js_devices))
    fi
    
    if [[ $controllers_found -eq 0 ]]; then
        echo -e "      ${YELLOW}No controllers detected${NC}"
    fi
    
    CONTROLLER_COUNT=$controllers_found
}

detect_network() {
    echo -e "  ${GEAR} Network:"
    
    # Check for ethernet
    if ip link show | grep -q "enp\|eth"; then
        echo -e "      ${GREEN}Ethernet: Available${NC}"
        HAS_ETHERNET=true
    fi
    
    # Check for WiFi
    if ip link show | grep -q "wlp\|wlan"; then
        echo -e "      ${GREEN}WiFi: Available${NC}"
        HAS_WIFI=true
    fi
    
    # Internet connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "      ${GREEN}Internet: Connected${NC}"
        HAS_INTERNET=true
    else
        echo -e "      ${YELLOW}Internet: Not connected${NC}"
        HAS_INTERNET=false
    fi
}

# ==============================================================================
# Gaming Software Detection
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
    
    echo -e "Choose your gaming setup preference:\n"
    echo -e "  ${BOLD}1.${NC} ${GREEN}Complete Gaming Setup${NC} - Install everything for optimal gaming"
    echo -e "     ${ARROW} Steam + Proton-GE, Lutris, GameMode, MangoHud, Wine"
    echo -e "     ${ARROW} All gaming optimizations and hardware-specific tweaks"
    echo -e "     ${ARROW} Gaming desktop customization and widgets"
    echo
    echo -e "  ${BOLD}2.${NC} ${YELLOW}Essential Gaming Only${NC} - Core gaming tools only"
    echo -e "     ${ARROW} Steam + Proton-GE, GameMode, MangoHud"
    echo -e "     ${ARROW} Basic gaming optimizations"
    echo
    echo -e "  ${BOLD}3.${NC} ${BLUE}Custom Setup${NC} - Choose individual components"
    echo -e "     ${ARROW} Select specific gaming software and optimizations"
    echo
    echo -e "  ${BOLD}4.${NC} ${PURPLE}Gaming Optimization Only${NC} - Just optimize existing setup"
    echo -e "     ${ARROW} Apply optimizations without installing new software"
    echo
    echo -e "  ${BOLD}5.${NC} ${CYAN}Hardware Analysis Only${NC} - Show recommendations without changes"
    echo -e "     ${ARROW} Analyze system and provide optimization recommendations"
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
    
    log_message "STEP" "Starting complete gaming setup"
    
    # Check if we need to run existing setup scripts
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    
    # Run gaming software installation
    if [[ -f "$setup_dir/gaming-setup.sh" ]]; then
        log_message "INFO" "Running gaming software installation"
        echo -e "\n${ROCKET} Installing gaming software stack..."
        "$setup_dir/gaming-setup.sh" complete 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Run hardware optimizations
    if [[ -f "$setup_dir/priority3-hardware-optimization.sh" ]]; then
        log_message "INFO" "Running hardware optimizations"
        echo -e "\n${ROCKET} Applying hardware optimizations..."
        "$setup_dir/priority3-hardware-optimization.sh" complete 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Run KDE gaming customization
    if [[ -f "$setup_dir/kde-gaming-customization.sh" ]]; then
        log_message "INFO" "Running KDE gaming customization"
        echo -e "\n${ROCKET} Customizing desktop for gaming..."
        "$setup_dir/kde-gaming-customization.sh" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Apply gaming-specific configurations
    configure_gaming_environment
    
    # Create gaming profile
    create_gaming_profile
    
    log_message "SUCCESS" "Complete gaming setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Complete gaming setup finished successfully!${NC}"
    show_post_setup_instructions
}

run_essential_gaming_setup() {
    print_header "${GAMING} Essential Gaming Setup"
    
    log_message "STEP" "Starting essential gaming setup"
    
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    
    # Install essential gaming components
    if ! $STEAM_INSTALLED; then
        if [[ -f "$setup_dir/install-steam.sh" ]]; then
            echo -e "\n${ROCKET} Installing Steam..."
            "$setup_dir/install-steam.sh" install 2>&1 | tee -a "$LOG_FILE"
        fi
    fi
    
    if ! $GAMEMODE_INSTALLED; then
        if [[ -f "$setup_dir/install-gamemode.sh" ]]; then
            echo -e "\n${ROCKET} Installing GameMode and MangoHud..."
            "$setup_dir/install-gamemode.sh" install 2>&1 | tee -a "$LOG_FILE"
        fi
    fi
    
    # Apply basic optimizations
    apply_basic_gaming_optimizations
    
    log_message "SUCCESS" "Essential gaming setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Essential gaming setup finished successfully!${NC}"
    show_post_setup_instructions
}

run_custom_gaming_setup() {
    print_header "${GAMING} Custom Gaming Setup"
    
    log_message "STEP" "Starting custom gaming setup"
    
    echo -e "Select components to install:\n"
    
    local components=()
    
    # Steam
    if ! $STEAM_INSTALLED; then
        read -p "Install Steam? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            components+=("steam")
        fi
    fi
    
    # Lutris
    if ! $LUTRIS_INSTALLED; then
        read -p "Install Lutris? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            components+=("lutris")
        fi
    fi
    
    # GameMode
    if ! $GAMEMODE_INSTALLED; then
        read -p "Install GameMode and MangoHud? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            components+=("gamemode")
        fi
    fi
    
    # Hardware optimizations
    read -p "Apply hardware-specific optimizations? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        components+=("hardware")
    fi
    
    # KDE customization
    read -p "Apply gaming desktop customization? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        components+=("kde")
    fi
    
    # Install selected components
    install_custom_components "${components[@]}"
    
    log_message "SUCCESS" "Custom gaming setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Custom gaming setup finished successfully!${NC}"
    show_post_setup_instructions
}

install_custom_components() {
    local components=("$@")
    local setup_dir="$XANADOS_ROOT/scripts/setup"
    
    for component in "${components[@]}"; do
        case "$component" in
            "steam")
                if [[ -f "$setup_dir/install-steam.sh" ]]; then
                    echo -e "\n${ROCKET} Installing Steam..."
                    "$setup_dir/install-steam.sh" install 2>&1 | tee -a "$LOG_FILE"
                fi
                ;;
            "lutris")
                if [[ -f "$setup_dir/install-lutris.sh" ]]; then
                    echo -e "\n${ROCKET} Installing Lutris..."
                    "$setup_dir/install-lutris.sh" install 2>&1 | tee -a "$LOG_FILE"
                fi
                ;;
            "gamemode")
                if [[ -f "$setup_dir/install-gamemode.sh" ]]; then
                    echo -e "\n${ROCKET} Installing GameMode and MangoHud..."
                    "$setup_dir/install-gamemode.sh" install 2>&1 | tee -a "$LOG_FILE"
                fi
                ;;
            "hardware")
                if [[ -f "$setup_dir/priority3-hardware-optimization.sh" ]]; then
                    echo -e "\n${ROCKET} Applying hardware optimizations..."
                    "$setup_dir/priority3-hardware-optimization.sh" complete 2>&1 | tee -a "$LOG_FILE"
                fi
                ;;
            "kde")
                if [[ -f "$setup_dir/kde-gaming-customization.sh" ]]; then
                    echo -e "\n${ROCKET} Customizing desktop for gaming..."
                    "$setup_dir/kde-gaming-customization.sh" 2>&1 | tee -a "$LOG_FILE"
                fi
                ;;
        esac
    done
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
    generate_compatibility_report "standard" "table"
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
        read -p "Please enter your choice [1-5, 0 to exit]: " -n 1 -r
        echo
        
        if handle_setup_choice "$REPLY"; then
            break
        fi
    done
    
    log_message "SUCCESS" "Gaming setup wizard completed"
}

# Run main function
main "$@"
