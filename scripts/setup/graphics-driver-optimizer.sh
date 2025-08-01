#!/bin/bash
# xanadOS Hardware-Specific Graphics Driver Optimization Script
# Automatically detects and optimizes graphics drivers for gaming performance

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/gaming-env.sh"

set -euo pipefail

# Colors are defined in common.sh - no need to redefine here
# Color variables: RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, WHITE, BOLD, NC

# Configuration
# SCRIPT_DIR already defined above
LOG_FILE="/var/log/xanados-graphics-optimization.log"
XORG_CONF_DIR="/etc/X11/xorg.conf.d"
CONFIG_DIR="/etc/xanados/graphics"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█         🎮 xanadOS Graphics Driver Optimization 🎮          █"
    echo "█                                                              █"
    echo "█        Hardware-Specific Gaming Performance Tuning          █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# Log setup with fallback
setup_logging() {
    local log_dir="/var/log/xanados"
    
    # Try to create log directory with fallback to user directory
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/graphics-optimization.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/graphics-optimization.log"
    fi
    
    # Initialize log file
    echo "=== xanadOS Graphics Optimization Started: $(date) ===" >> "$LOG_FILE"
}

# Detect graphics hardware
detect_graphics_hardware() {
    print_status "Detecting graphics hardware..."
    
    # Initialize variables
    GPU_VENDOR=""
    GPU_MODEL=""
    GPU_DRIVER=""
    VULKAN_SUPPORT=false
    
    # NVIDIA Detection
    if get_cached_command "nvidia-smi" &>/dev/null; then
        GPU_VENDOR="nvidia"
        GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "NVIDIA GPU")
        GPU_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "Unknown")
        print_info "Detected NVIDIA GPU: $GPU_MODEL (Driver: $GPU_DRIVER)"
    elif lspci | grep -i "VGA.*NVIDIA\|3D.*NVIDIA" &>/dev/null; then
        GPU_VENDOR="nvidia"
        GPU_MODEL=$(lspci | grep -i "VGA.*NVIDIA\|3D.*NVIDIA" | cut -d: -f3 | xargs || echo "NVIDIA GPU")
        print_warning "NVIDIA GPU detected but nvidia-smi not available"
        print_info "GPU: $GPU_MODEL"
    fi
    
    # AMD Detection
    if [[ -z "$GPU_VENDOR" ]] && lspci | grep -i "VGA.*AMD\|VGA.*ATI\|3D.*AMD\|3D.*ATI" &>/dev/null; then
        GPU_VENDOR="amd"
        GPU_MODEL=$(lspci | grep -i "VGA.*AMD\|VGA.*ATI\|3D.*AMD\|3D.*ATI" | cut -d: -f3 | xargs || echo "AMD GPU")
        print_info "Detected AMD GPU: $GPU_MODEL"
    fi
    
    # Intel Detection
    if [[ -z "$GPU_VENDOR" ]] && lspci | grep -i "VGA.*Intel\|3D.*Intel" &>/dev/null; then
        GPU_VENDOR="intel"
        GPU_MODEL=$(lspci | grep -i "VGA.*Intel\|3D.*Intel" | cut -d: -f3 | xargs || echo "Intel GPU")
        print_info "Detected Intel GPU: $GPU_MODEL"
    fi
    
    # Check Vulkan support
    if get_cached_command "vulkaninfo" &>/dev/null && vulkaninfo --summary &>/dev/null; then
        VULKAN_SUPPORT=true
        print_success "Vulkan support detected"
    else
        print_warning "Vulkan support not detected"
    fi
    
    # Log detection results
    echo "GPU Vendor: $GPU_VENDOR" >> "$LOG_FILE"
    echo "GPU Model: $GPU_MODEL" >> "$LOG_FILE" 
    echo "GPU Driver: $GPU_DRIVER" >> "$LOG_FILE"
    echo "Vulkan Support: $VULKAN_SUPPORT" >> "$LOG_FILE"
}

# NVIDIA optimizations
optimize_nvidia() {
    print_status "Applying NVIDIA gaming optimizations..."
    
    # Check if NVIDIA drivers are properly installed
    if ! get_cached_command "nvidia-smi" &>/dev/null; then
        print_error "NVIDIA drivers not properly installed"
        print_info "Please install NVIDIA proprietary drivers first"
        return 1
    fi
    
    # Create xorg configuration directory
    sudo mkdir -p "$XORG_CONF_DIR" 2>/dev/null || true
    
    # Create NVIDIA X11 configuration
    local nvidia_conf="$XORG_CONF_DIR/20-nvidia.conf"
    print_status "Creating NVIDIA X11 configuration..."
    
    sudo tee "$nvidia_conf" > /dev/null << 'EOF'
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
    VendorName "NVIDIA Corporation"
    Option "NoLogo" "true"
    Option "UseEDID" "false"
    Option "ConnectedMonitor" "DFP"
    Option "CustomEDID" "DFP:/etc/X11/edid.bin"
    Option "IgnoreEDID" "false"
    Option "NoBandWidthTest" "true"
    Option "RegistryDwords" "PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1"
    Option "TripleBuffer" "true"
    Option "Coolbits" "28"
    Option "AllowEmptyInitialConfiguration" "true"
EndSection

Section "Screen"
    Identifier "NVIDIA Screen"
    Device "NVIDIA Card"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
    Option "metamodes" "nvidia-auto-select +0+0 { ForceFullCompositionPipeline = On }"
EndSection
EOF
    
    # Set NVIDIA power management to maximum performance
    print_status "Setting NVIDIA power management..."
    for pci_device in /sys/bus/pci/devices/*/power/control; do
        if [[ -w "$pci_device" ]]; then
            echo "on" | sudo tee "$pci_device" > /dev/null 2>&1 || true
        fi
    done
    
    # Create NVIDIA persistence daemon service
    print_status "Configuring NVIDIA persistence daemon..."
    sudo systemctl enable nvidia-persistenced 2>/dev/null || true
    sudo systemctl start nvidia-persistenced 2>/dev/null || true
    
    print_success "NVIDIA optimizations applied"
}

# AMD optimizations  
optimize_amd() {
    print_status "Applying AMD gaming optimizations..."
    
    # Create xorg configuration directory
    sudo mkdir -p "$XORG_CONF_DIR" 2>/dev/null || true
    
    # Create AMD X11 configuration
    local amd_conf="$XORG_CONF_DIR/20-amdgpu.conf"
    print_status "Creating AMD X11 configuration..."
    
    sudo tee "$amd_conf" > /dev/null << 'EOF'
Section "Device"
    Identifier "AMD Graphics"
    Driver "amdgpu"
    Option "DRI" "3"
    Option "TearFree" "true"
    Option "VariableRefresh" "true"
    Option "AsyncFlipSecondaries" "true"
EndSection

Section "Screen"
    Identifier "AMD Screen"
    Device "AMD Graphics"
EndSection
EOF
    
    # Set AMD GPU power profile for gaming
    print_status "Setting AMD power profile for gaming..."
    local power_profiles=(
        "/sys/class/drm/card0/device/power_dpm_force_performance_level"
        "/sys/class/drm/card1/device/power_dpm_force_performance_level"
    )
    
    for profile in "${power_profiles[@]}"; do
        if [[ -w "$profile" ]]; then
            echo "high" | sudo tee "$profile" > /dev/null 2>&1 || true
        fi
    done
    
    # Enable AMD GPU overclocking if supported
    local amdgpu_paths=(
        "/sys/class/drm/card0/device/pp_sclk_od"
        "/sys/class/drm/card1/device/pp_sclk_od" 
    )
    
    for path in "${amdgpu_paths[@]}"; do
        if [[ -w "$path" ]]; then
            echo "1" | sudo tee "$path" > /dev/null 2>&1 || true
        fi
    done
    
    print_success "AMD optimizations applied"
}

# Intel optimizations
optimize_intel() {
    print_status "Applying Intel gaming optimizations..."
    
    # Create xorg configuration directory
    sudo mkdir -p "$XORG_CONF_DIR" 2>/dev/null || true
    
    # Create Intel X11 configuration
    local intel_conf="$XORG_CONF_DIR/20-intel.conf"
    print_status "Creating Intel X11 configuration..."
    
    sudo tee "$intel_conf" > /dev/null << 'EOF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "AccelMethod" "sna"
    Option "TearFree" "true"
    Option "DRI" "3"
    Option "TripleBuffer" "true"
EndSection
EOF
    
    print_success "Intel optimizations applied"
}

# Install missing graphics packages
install_graphics_packages() {
    print_status "Installing graphics optimization packages..."
    
    local packages=()
    
    # Common packages
    packages+=("mesa-utils" "vulkan-tools" "glxinfo")
    
    # GPU-specific packages
    case "$GPU_VENDOR" in
        nvidia)
            packages+=("nvidia-settings" "nvidia-prime")
            ;;
        amd)
            packages+=("radeontop" "mesa-vulkan-drivers")
            ;;
        intel)
            packages+=("intel-gpu-tools" "mesa-vulkan-drivers")
            ;;
    esac
    
    # Install packages
    if [[ ${#packages[@]} -gt 0 ]]; then
        print_status "Installing: ${packages[*]}"
        if sudo apt update &>/dev/null && sudo apt install -y "${packages[@]}" &>/dev/null; then
            print_success "Graphics packages installed successfully"
        else
            print_warning "Some packages may not have been installed"
        fi
    fi
}

# Create graphics configuration backup
backup_graphics_config() {
    print_status "Creating graphics configuration backup..."
    
    local backup_dir
    backup_dir="$HOME/.config/xanados/backups/graphics-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing configurations
    if [[ -d "$XORG_CONF_DIR" ]]; then
        sudo cp -r "$XORG_CONF_DIR" "$backup_dir/" 2>/dev/null || true
    fi
    
    if [[ -f "/etc/X11/xorg.conf" ]]; then
        sudo cp "/etc/X11/xorg.conf" "$backup_dir/" 2>/dev/null || true
    fi
    
    print_info "Graphics configuration backed up to: $backup_dir"
    echo "Backup location: $backup_dir" >> "$LOG_FILE"
}

# Apply all optimizations
apply_optimizations() {
    print_status "Applying graphics optimizations for $GPU_VENDOR GPU..."
    
    # Create backup first
    backup_graphics_config
    
    # Install necessary packages
    install_graphics_packages
    
    # Apply vendor-specific optimizations
    case "$GPU_VENDOR" in
        nvidia)
            optimize_nvidia
            ;;
        amd)
            optimize_amd
            ;;
        intel)
            optimize_intel
            ;;
        *)
            print_warning "Unknown or unsupported GPU vendor: $GPU_VENDOR"
            print_info "Applying generic optimizations..."
            ;;
    esac
    
    print_success "Graphics optimizations applied successfully!"
    print_info "Please reboot your system for changes to take effect."
}

# Remove optimizations 
remove_optimizations() {
    print_status "Removing graphics optimizations..."
    
    local config_files=(
        "$XORG_CONF_DIR/20-nvidia.conf"
        "$XORG_CONF_DIR/20-amdgpu.conf"
        "$XORG_CONF_DIR/20-intel.conf"
    )
    
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            sudo rm -f "$config"
            print_info "Removed: $config"
        fi
    done
    
    print_success "Graphics optimizations removed"
    print_info "Please reboot your system for changes to take effect."
}

# Show current status
show_status() {
    print_status "Graphics optimization status:"
    echo
    
    # Show detected hardware
    echo "Hardware Information:"
    echo "  GPU Vendor: ${GPU_VENDOR:-Unknown}"
    echo "  GPU Model: ${GPU_MODEL:-Unknown}" 
    echo "  Vulkan Support: ${VULKAN_SUPPORT:-Unknown}"
    echo
    
    # Check for optimization files
    echo "Optimization Status:"
    local config_files=(
        "$XORG_CONF_DIR/20-nvidia.conf"
        "$XORG_CONF_DIR/20-amdgpu.conf"
        "$XORG_CONF_DIR/20-intel.conf"
    )
    
    local optimizations_found=false
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            echo "  ✅ $(basename "$config") applied"
            optimizations_found=true
        fi
    done
    
    if ! $optimizations_found; then
        echo "  ❌ No optimizations currently applied"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [apply|remove|status|help]"
    echo
    echo "Options:"
    echo "  apply    - Detect hardware and apply graphics optimizations"
    echo "  remove   - Remove all graphics optimizations"
    echo "  status   - Show current optimization status"
    echo "  help     - Show this help message"
    echo
    echo "This script automatically detects your graphics hardware and applies"
    echo "vendor-specific optimizations for gaming performance."
}

# Main function
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        print_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Setup logging
    setup_logging
    
    # Initialize command cache
    cache_system_tools &>/dev/null || true
    
    # Handle command line arguments
    local action="${1:-help}"
    
    case "$action" in
        apply)
            print_banner
            detect_graphics_hardware
            if [[ -n "$GPU_VENDOR" ]]; then
                apply_optimizations
            else
                print_error "No supported graphics hardware detected"
                exit 1
            fi
            ;;
        remove)
            print_banner
            remove_optimizations
            ;;
        status)
            print_banner
            detect_graphics_hardware
            show_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown option: $action"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

