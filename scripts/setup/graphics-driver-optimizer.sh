#!/bin/bash
# xanadOS Hardware-Specific Graphics Driver Optimization Script
# Automatically detects and optimizes graphics drivers for gaming performance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
}

# Function to detect graphics hardware
detect_graphics_hardware() {
    print_section "Detecting Graphics Hardware"
    
    local gpu_info
    gpu_info=$(lspci | grep -E "(VGA|3D|Display)" | head -10)
    
    echo "Detected Graphics Hardware:"
    echo "$gpu_info"
    echo
    
    # Detect NVIDIA GPUs
    if lspci | grep -qi nvidia; then
        print_status "NVIDIA GPU detected"
        HAS_NVIDIA=true
        NVIDIA_MODEL=$(lspci | grep -i nvidia | grep -i vga | head -1 | cut -d: -f3 | xargs)
        echo "  Model: $NVIDIA_MODEL"
    else
        HAS_NVIDIA=false
    fi
    
    # Detect AMD GPUs
    if lspci | grep -qi "advanced micro devices\|amd"; then
        print_status "AMD GPU detected"
        HAS_AMD=true
        AMD_MODEL=$(lspci | grep -E "(AMD|Advanced Micro Devices)" | grep -E "(VGA|3D|Display)" | head -1 | cut -d: -f3 | xargs)
        echo "  Model: $AMD_MODEL"
    else
        HAS_AMD=false
    fi
    
    # Detect Intel GPUs
    if lspci | grep -qi intel | grep -E "(VGA|3D|Display)"; then
        print_status "Intel GPU detected"
        HAS_INTEL=true
        INTEL_MODEL=$(lspci | grep -i intel | grep -E "(VGA|3D|Display)" | head -1 | cut -d: -f3 | xargs)
        echo "  Model: $INTEL_MODEL"
    else
        HAS_INTEL=false
    fi
    
    # Check for multiple GPUs
    local gpu_count
    gpu_count=$(lspci | grep -E "(VGA|3D|Display)" | wc -l)
    if [ "$gpu_count" -gt 1 ]; then
        print_warning "Multiple GPUs detected - hybrid graphics configuration"
        HAS_HYBRID=true
    else
        HAS_HYBRID=false
    fi
    
    echo
}

# Function to check current driver status
check_driver_status() {
    print_section "Current Driver Status"
    
    echo "Loaded Graphics Modules:"
    lsmod | grep -E "(nvidia|amdgpu|radeon|i915|xe)" | while read -r module _; do
        echo "  • $module"
    done
    echo
    
    echo "Graphics Driver Information:"
    if command -v glxinfo >/dev/null 2>&1; then
        echo "  OpenGL Renderer: $(glxinfo | grep "OpenGL renderer string" | cut -d: -f2 | xargs)"
        echo "  OpenGL Version: $(glxinfo | grep "OpenGL version string" | cut -d: -f2 | xargs)"
        echo "  Graphics Driver: $(glxinfo | grep "OpenGL vendor string" | cut -d: -f2 | xargs)"
    else
        print_warning "glxinfo not available - install mesa-utils for detailed info"
    fi
    
    if command -v vulkaninfo >/dev/null 2>&1; then
        echo "  Vulkan Support: Available"
        echo "  Vulkan Devices:"
        vulkaninfo --summary 2>/dev/null | grep "deviceName" | sed 's/^/    /'
    else
        print_warning "vulkaninfo not available - install vulkan-tools for detailed info"
    fi
    
    echo
}

# Function to optimize NVIDIA drivers
optimize_nvidia_drivers() {
    print_section "Optimizing NVIDIA Drivers"
    
    if [ "$HAS_NVIDIA" != "true" ]; then
        print_warning "No NVIDIA GPU detected, skipping NVIDIA optimizations"
        return
    fi
    
    print_status "Configuring NVIDIA driver optimizations..."
    
    # Create NVIDIA-specific Xorg configuration
    mkdir -p "$XORG_CONF_DIR"
    cat > "$XORG_CONF_DIR/20-nvidia.conf" << 'EOF'
Section "Device"
    Identifier "NVIDIA Graphics"
    Driver "nvidia"
    Option "Coolbits" "28"
    Option "RegistryDwords" "PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x1; PowerMizerDefault=0x1; PowerMizerDefaultAC=0x1"
    Option "TripleBuffer" "true"
    Option "UseEDID" "true"
    Option "NoLogo" "true"
    Option "AllowIndirectGLXProtocol" "false"
    Option "Stereo" "0"
    Option "nvidiaXineramaInfoOrder" "DFP-2"
    Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option "AllowIndirectPixmaps" "true"
    Option "BackingStore" "true"
    Option "PixmapCacheSize" "1000000"
    Option "OnDemandVBlankInterrupts" "true"
EOF

    # Add gaming-specific options based on GPU generation
    if echo "$NVIDIA_MODEL" | grep -qE "(RTX 40|RTX 30|GTX 16)"; then
        cat >> "$XORG_CONF_DIR/20-nvidia.conf" << 'EOF'
    # Modern GPU optimizations
    Option "AllowGSYNCCompatible" "true"
    Option "VRR" "true"
EndSection
EOF
    else
        cat >> "$XORG_CONF_DIR/20-nvidia.conf" << 'EOF'
EndSection
EOF
    fi
    
    # Create NVIDIA gaming environment variables
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/nvidia-gaming.env" << 'EOF'
# NVIDIA Gaming Environment Variables
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH=/tmp
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SYNC_TO_VBLANK=0
export __GL_ALLOW_UNOFFICIAL_PROTOCOL=1
export KWIN_TRIPLE_BUFFER=1
export LIBVA_DRIVER_NAME=nvidia
export MOZ_DISABLE_RDD_SANDBOX=1
export EGL_PLATFORM=wayland
EOF
    
    # Configure NVIDIA module parameters
    cat > "/etc/modprobe.d/nvidia-gaming.conf" << 'EOF'
# NVIDIA Gaming Module Parameters
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_InitializeSystemMemoryAllocations=0
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/tmp
EOF
    
    # Create NVIDIA performance script
    cat > "/usr/local/bin/nvidia-gaming-performance" << 'EOF'
#!/bin/bash
# NVIDIA Gaming Performance Script

# Set maximum performance mode
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi -pm 1 2>/dev/null || true
    nvidia-smi -pl $(nvidia-smi --query-gpu=power.max_limit --format=csv,noheader,nounits | head -1) 2>/dev/null || true
fi

# Set GPU performance level if nvidia-settings available
if command -v nvidia-settings >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1" 2>/dev/null || true
    nvidia-settings -a "[gpu:0]/GPUMemoryTransferRateOffset[3]=1000" 2>/dev/null || true
    nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffset[3]=100" 2>/dev/null || true
fi
EOF
    chmod +x "/usr/local/bin/nvidia-gaming-performance"
    
    print_success "NVIDIA driver optimizations configured"
    print_status "Run 'nvidia-gaming-performance' to apply performance settings"
}

# Function to optimize AMD drivers
optimize_amd_drivers() {
    print_section "Optimizing AMD Drivers"
    
    if [ "$HAS_AMD" != "true" ]; then
        print_warning "No AMD GPU detected, skipping AMD optimizations"
        return
    fi
    
    print_status "Configuring AMD driver optimizations..."
    
    # Create AMD-specific Xorg configuration
    mkdir -p "$XORG_CONF_DIR"
    cat > "$XORG_CONF_DIR/20-amdgpu.conf" << 'EOF'
Section "Device"
    Identifier "AMD Graphics"
    Driver "amdgpu"
    Option "TearFree" "true"
    Option "DRI" "3"
    Option "VariableRefresh" "true"
    Option "EnablePageFlip" "true"
    Option "SwapbuffersWait" "false"
    Option "AccelMethod" "glamor"
    Option "ShadowPrimary" "false"
EndSection

Section "Screen"
    Identifier "AMD Screen"
    Device "AMD Graphics"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080" "1680x1050" "1280x1024" "1024x768"
    EndSubSection
EndSection
EOF
    
    # Create AMD gaming environment variables
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/amd-gaming.env" << 'EOF'
# AMD Gaming Environment Variables
export MESA_GLTHREAD=true
export mesa_glthread=true
export RADV_PERFTEST=aco,sam,nggc,rt
export RADV_DEBUG=llvm,nocompute
export ACO_DEBUG=validateir,validatera
export AMD_VULKAN_ICD=RADV
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
export GALLIUM_DRIVER=radeonsi
export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi
export KWIN_TRIPLE_BUFFER=1
export __GL_THREADED_OPTIMIZATIONS=1
export MESA_LOADER_DRIVER_OVERRIDE=radeonsi
EOF
    
    # Configure AMDGPU module parameters
    cat > "/etc/modprobe.d/amdgpu-gaming.conf" << 'EOF'
# AMDGPU Gaming Module Parameters
options amdgpu si_support=1
options amdgpu cik_support=1
options amdgpu dc=1
options amdgpu dpm=1
options amdgpu audio=1
options amdgpu runpm=0
options amdgpu bapm=0
options amdgpu deep_color=1
options amdgpu vrr=1
options amdgpu freesync_video=1
EOF
    
    # Create AMD performance script
    cat > "/usr/local/bin/amd-gaming-performance" << 'EOF'
#!/bin/bash
# AMD Gaming Performance Script

# Set power profile for gaming
if [ -f "/sys/class/drm/card0/device/power_dpm_force_performance_level" ]; then
    echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level >/dev/null 2>&1 || true
fi

# Set GPU power state
for gpu_path in /sys/class/drm/card*/device/power_dpm_state; do
    if [ -f "$gpu_path" ]; then
        echo "performance" | sudo tee "$gpu_path" >/dev/null 2>&1 || true
    fi
done

# Enable GPU scheduling if available
for gpu_path in /sys/class/drm/card*/device/gpu_scheduler_enabled; do
    if [ -f "$gpu_path" ]; then
        echo "1" | sudo tee "$gpu_path" >/dev/null 2>&1 || true
    fi
done

# Set memory clock to maximum if available
for gpu_path in /sys/class/drm/card*/device/pp_mclk_od; do
    if [ -f "$gpu_path" ]; then
        echo "10" | sudo tee "$gpu_path" >/dev/null 2>&1 || true
    fi
done
EOF
    chmod +x "/usr/local/bin/amd-gaming-performance"
    
    print_success "AMD driver optimizations configured"
    print_status "Run 'amd-gaming-performance' to apply performance settings"
}

# Function to optimize Intel drivers
optimize_intel_drivers() {
    print_section "Optimizing Intel Drivers"
    
    if [ "$HAS_INTEL" != "true" ]; then
        print_warning "No Intel GPU detected, skipping Intel optimizations"
        return
    fi
    
    print_status "Configuring Intel driver optimizations..."
    
    # Create Intel-specific Xorg configuration
    mkdir -p "$XORG_CONF_DIR"
    cat > "$XORG_CONF_DIR/20-intel.conf" << 'EOF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
    Option "DRI" "3"
    Option "AccelMethod" "sna"
    Option "Backlight" "intel_backlight"
    Option "CustomEDID" "eDP1:/sys/class/drm/card0-eDP-1/edid"
    Option "VSync" "true"
    Option "PageFlip" "true"
    Option "SwapbuffersWait" "false"
EndSection

Section "Screen"
    Identifier "Intel Screen"
    Device "Intel Graphics"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
    EndSubSection
EndSection
EOF
    
    # Create Intel gaming environment variables
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/intel-gaming.env" << 'EOF'
# Intel Gaming Environment Variables
export MESA_GLTHREAD=true
export mesa_glthread=true
export INTEL_DEBUG=reemit,perf
export INTEL_PRECISE_TRIG=1
export LIBVA_DRIVER_NAME=iHD
export KWIN_TRIPLE_BUFFER=1
export __GL_THREADED_OPTIMIZATIONS=1
export MESA_LOADER_DRIVER_OVERRIDE=iris
EOF
    
    # Configure Intel module parameters
    cat > "/etc/modprobe.d/i915-gaming.conf" << 'EOF'
# Intel Gaming Module Parameters
options i915 enable_guc=2
options i915 enable_fbc=1
options i915 enable_psr=1
options i915 disable_power_well=0
options i915 semaphores=1
options i915 modeset=1
options i915 enable_dc=1
options i915 enable_hangcheck=0
options i915 error_capture=0
EOF
    
    # Create Intel performance script
    cat > "/usr/local/bin/intel-gaming-performance" << 'EOF'
#!/bin/bash
# Intel Gaming Performance Script

# Set GPU frequency governor to performance
for gpu_path in /sys/class/drm/card*/gt_min_freq_mhz; do
    if [ -f "$gpu_path" ]; then
        max_freq=$(cat "${gpu_path%min*}max_freq_mhz")
        echo "$max_freq" | sudo tee "$gpu_path" >/dev/null 2>&1 || true
    fi
done

# Disable power saving features during gaming
echo "0" | sudo tee /sys/module/i915/parameters/enable_dc >/dev/null 2>&1 || true
echo "0" | sudo tee /sys/module/i915/parameters/enable_psr >/dev/null 2>&1 || true
EOF
    chmod +x "/usr/local/bin/intel-gaming-performance"
    
    print_success "Intel driver optimizations configured"
    print_status "Run 'intel-gaming-performance' to apply performance settings"
}

# Function to configure hybrid graphics
configure_hybrid_graphics() {
    print_section "Configuring Hybrid Graphics"
    
    if [ "$HAS_HYBRID" != "true" ]; then
        return
    fi
    
    print_status "Configuring hybrid graphics setup..."
    
    # Install hybrid graphics tools if available
    if command -v pacman >/dev/null 2>&1; then
        pacman -S --needed --noconfirm optimus-manager envycontrol 2>/dev/null || true
    fi
    
    # Create hybrid graphics switching script
    cat > "/usr/local/bin/gpu-switch" << 'EOF'
#!/bin/bash
# GPU Switching Script for Hybrid Graphics

usage() {
    echo "Usage: $0 {nvidia|amd|intel|hybrid|auto}"
    echo "  nvidia  - Use NVIDIA GPU exclusively"
    echo "  amd     - Use AMD GPU exclusively"
    echo "  intel   - Use Intel GPU for power saving"
    echo "  hybrid  - Use hybrid mode (requires restart)"
    echo "  auto    - Auto-detect best GPU for current task"
    exit 1
}

case "$1" in
    nvidia)
        if command -v optimus-manager >/dev/null 2>&1; then
            optimus-manager --switch nvidia --no-confirm
        elif command -v envycontrol >/dev/null 2>&1; then
            envycontrol -s nvidia
        fi
        ;;
    amd)
        if command -v envycontrol >/dev/null 2>&1; then
            envycontrol -s hybrid
        fi
        ;;
    intel)
        if command -v optimus-manager >/dev/null 2>&1; then
            optimus-manager --switch intel --no-confirm
        elif command -v envycontrol >/dev/null 2>&1; then
            envycontrol -s integrated
        fi
        ;;
    hybrid)
        if command -v optimus-manager >/dev/null 2>&1; then
            optimus-manager --switch hybrid --no-confirm
        elif command -v envycontrol >/dev/null 2>&1; then
            envycontrol -s hybrid
        fi
        ;;
    auto)
        echo "Auto-detection not yet implemented"
        ;;
    *)
        usage
        ;;
esac
EOF
    chmod +x "/usr/local/bin/gpu-switch"
    
    print_success "Hybrid graphics configuration completed"
    print_status "Use 'gpu-switch nvidia|intel|hybrid' to switch GPU modes"
}

# Function to install graphics optimization tools
install_optimization_tools() {
    print_section "Installing Graphics Optimization Tools"
    
    print_status "Installing essential graphics tools..."
    
    # Check package manager and install tools
    if command -v pacman >/dev/null 2>&1; then
        # Arch Linux packages
        local packages=(
            "mesa-utils"
            "vulkan-tools"
            "glxinfo"
            "mesa"
            "lib32-mesa"
            "vulkan-icd-loader"
            "lib32-vulkan-icd-loader"
        )
        
        # GPU-specific packages
        if [ "$HAS_NVIDIA" = "true" ]; then
            packages+=(
                "nvidia-utils"
                "lib32-nvidia-utils"
                "nvidia-settings"
            )
        fi
        
        if [ "$HAS_AMD" = "true" ]; then
            packages+=(
                "mesa"
                "lib32-mesa"
                "vulkan-radeon"
                "lib32-vulkan-radeon"
                "libva-mesa-driver"
                "lib32-libva-mesa-driver"
            )
        fi
        
        if [ "$HAS_INTEL" = "true" ]; then
            packages+=(
                "vulkan-intel"
                "lib32-vulkan-intel"
                "libva-intel-driver"
                "intel-media-driver"
            )
        fi
        
        for package in "${packages[@]}"; do
            pacman -S --needed --noconfirm "$package" 2>/dev/null || print_warning "Failed to install $package"
        done
    fi
    
    print_success "Graphics optimization tools installed"
}

# Function to create graphics performance monitoring
create_graphics_monitoring() {
    print_section "Setting Up Graphics Performance Monitoring"
    
    # Create graphics monitoring script
    cat > "/usr/local/bin/gpu-monitor" << 'EOF'
#!/bin/bash
# GPU Performance Monitoring Script

print_gpu_status() {
    echo "=== GPU Performance Status ==="
    echo "Date: $(date)"
    echo
    
    # NVIDIA monitoring
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "NVIDIA GPU Status:"
        nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw --format=csv,noheader,nounits
        echo
    fi
    
    # AMD monitoring
    if [ -f "/sys/class/drm/card0/device/gpu_busy_percent" ]; then
        echo "AMD GPU Status:"
        echo "  Utilization: $(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "N/A")%"
        if [ -f "/sys/class/hwmon/hwmon0/temp1_input" ]; then
            temp=$(($(cat /sys/class/hwmon/hwmon0/temp1_input) / 1000))
            echo "  Temperature: ${temp}°C"
        fi
        echo
    fi
    
    # Intel monitoring
    if [ -d "/sys/class/drm/card0/gt" ]; then
        echo "Intel GPU Status:"
        if [ -f "/sys/class/drm/card0/gt_cur_freq_mhz" ]; then
            echo "  Current Frequency: $(cat /sys/class/drm/card0/gt_cur_freq_mhz)MHz"
        fi
        echo
    fi
    
    # General GPU info
    echo "Graphics Driver Info:"
    if command -v glxinfo >/dev/null 2>&1; then
        echo "  Renderer: $(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs)"
        echo "  Version: $(glxinfo | grep "OpenGL version" | cut -d: -f2 | xargs)"
    fi
    echo
}

case "$1" in
    --continuous)
        while true; do
            clear
            print_gpu_status
            sleep 5
        done
        ;;
    *)
        print_gpu_status
        ;;
esac
EOF
    chmod +x "/usr/local/bin/gpu-monitor"
    
    print_success "Graphics monitoring tools created"
    print_status "Use 'gpu-monitor' for status or 'gpu-monitor --continuous' for live monitoring"
}

# Function to apply graphics optimizations
apply_graphics_optimizations() {
    print_section "Applying Graphics Optimizations"
    
    optimize_nvidia_drivers
    optimize_amd_drivers  
    optimize_intel_drivers
    configure_hybrid_graphics
    
    # Create unified graphics optimization script
    cat > "/usr/local/bin/graphics-gaming-mode" << 'EOF'
#!/bin/bash
# Unified Graphics Gaming Mode Script

apply_optimizations() {
    echo "Applying graphics gaming optimizations..."
    
    # Apply GPU-specific optimizations
    [ -x "/usr/local/bin/nvidia-gaming-performance" ] && /usr/local/bin/nvidia-gaming-performance
    [ -x "/usr/local/bin/amd-gaming-performance" ] && /usr/local/bin/amd-gaming-performance  
    [ -x "/usr/local/bin/intel-gaming-performance" ] && /usr/local/bin/intel-gaming-performance
    
    # Load optimized environment variables
    [ -f "/etc/xanados/graphics/nvidia-gaming.env" ] && source /etc/xanados/graphics/nvidia-gaming.env
    [ -f "/etc/xanados/graphics/amd-gaming.env" ] && source /etc/xanados/graphics/amd-gaming.env
    [ -f "/etc/xanados/graphics/intel-gaming.env" ] && source /etc/xanados/graphics/intel-gaming.env
    
    echo "Graphics gaming optimizations applied"
}

restore_defaults() {
    echo "Restoring default graphics settings..."
    
    # Reset GPU power states to auto
    for gpu_path in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
        [ -f "$gpu_path" ] && echo "auto" | sudo tee "$gpu_path" >/dev/null 2>&1 || true
    done
    
    echo "Default graphics settings restored"
}

case "$1" in
    enable|on)
        apply_optimizations
        ;;
    disable|off)
        restore_defaults
        ;;
    *)
        echo "Usage: $0 {enable|disable}"
        echo "  enable  - Apply gaming graphics optimizations"
        echo "  disable - Restore default graphics settings"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/graphics-gaming-mode"
    
    print_success "Graphics optimization scripts created"
}

# Function to show optimization summary
show_optimization_summary() {
    print_section "Graphics Optimization Summary"
    
    echo "Hardware Configuration:"
    [ "$HAS_NVIDIA" = "true" ] && echo "  ✅ NVIDIA GPU: $NVIDIA_MODEL"
    [ "$HAS_AMD" = "true" ] && echo "  ✅ AMD GPU: $AMD_MODEL"
    [ "$HAS_INTEL" = "true" ] && echo "  ✅ Intel GPU: $INTEL_MODEL"
    [ "$HAS_HYBRID" = "true" ] && echo "  ⚡ Hybrid Graphics Configuration Detected"
    echo
    
    echo "Optimizations Applied:"
    [ "$HAS_NVIDIA" = "true" ] && echo "  ✅ NVIDIA driver optimizations configured"
    [ "$HAS_AMD" = "true" ] && echo "  ✅ AMD driver optimizations configured"
    [ "$HAS_INTEL" = "true" ] && echo "  ✅ Intel driver optimizations configured"
    [ "$HAS_HYBRID" = "true" ] && echo "  ✅ Hybrid graphics switching configured"
    echo "  ✅ Performance monitoring tools installed"
    echo "  ✅ Gaming mode scripts created"
    echo
    
    echo "Available Commands:"
    echo "  • graphics-gaming-mode enable    - Enable gaming optimizations"
    echo "  • graphics-gaming-mode disable   - Disable gaming optimizations"
    echo "  • gpu-monitor                     - Check GPU status"
    echo "  • gpu-monitor --continuous        - Live GPU monitoring"
    [ "$HAS_HYBRID" = "true" ] && echo "  • gpu-switch nvidia|intel|hybrid     - Switch GPU modes"
    echo
    
    echo "Configuration Files:"
    echo "  • Xorg configs: $XORG_CONF_DIR/"
    echo "  • Environment variables: $CONFIG_DIR/"
    echo "  • Module parameters: /etc/modprobe.d/"
    echo "  • Log file: $LOG_FILE"
    echo
}

# Function to show interactive menu
show_menu() {
    print_section "Graphics Driver Optimization Menu"
    
    echo "Choose an action:"
    echo
    echo "1) 🔍 Detect Graphics Hardware"
    echo "2) 📊 Check Current Driver Status"
    echo "3) 🎮 Apply Gaming Optimizations"
    echo "4) ⚙️  Install Optimization Tools"
    echo "5) 📈 Setup Performance Monitoring"
    echo "6) 🔄 Configure Hybrid Graphics"
    echo "7) ✅ Apply All Optimizations"
    echo "8) 📋 Show Optimization Summary"
    echo "9) 🚪 Exit"
    echo
}

# Main function
main() {
    # Initialize log file
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    sudo touch "$LOG_FILE"
    
    print_banner
    
    if [ "$#" -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -r -p "Select option [1-9]: " choice
            
            case $choice in
                1)
                    detect_graphics_hardware
                    read -r -p "Press Enter to continue..."
                    ;;
                2)
                    check_driver_status
                    read -r -p "Press Enter to continue..."
                    ;;
                3)
                    detect_graphics_hardware
                    apply_graphics_optimizations
                    read -r -p "Press Enter to continue..."
                    ;;
                4)
                    install_optimization_tools
                    read -r -p "Press Enter to continue..."
                    ;;
                5)
                    create_graphics_monitoring
                    read -r -p "Press Enter to continue..."
                    ;;
                6)
                    detect_graphics_hardware
                    configure_hybrid_graphics
                    read -r -p "Press Enter to continue..."
                    ;;
                7)
                    detect_graphics_hardware
                    install_optimization_tools
                    apply_graphics_optimizations
                    create_graphics_monitoring
                    show_optimization_summary
                    break
                    ;;
                8)
                    detect_graphics_hardware
                    show_optimization_summary
                    read -r -p "Press Enter to continue..."
                    ;;
                9)
                    print_status "Exiting graphics optimization"
                    exit 0
                    ;;
                *)
                    print_error "Invalid option. Please try again."
                    ;;
            esac
        done
    else
        # Command-line mode
        case "$1" in
            detect)
                detect_graphics_hardware
                ;;
            status)
                check_driver_status
                ;;
            optimize)
                detect_graphics_hardware
                apply_graphics_optimizations
                ;;
            install)
                install_optimization_tools
                ;;
            monitor)
                create_graphics_monitoring
                ;;
            all)
                detect_graphics_hardware
                install_optimization_tools
                apply_graphics_optimizations
                create_graphics_monitoring
                show_optimization_summary
                ;;
            *)
                echo "Usage: $0 [detect|status|optimize|install|monitor|all]"
                echo "  detect   - Detect graphics hardware"
                echo "  status   - Check driver status"
                echo "  optimize - Apply gaming optimizations"
                echo "  install  - Install optimization tools"
                echo "  monitor  - Setup performance monitoring"
                echo "  all      - Run complete optimization"
                echo
                echo "Run without arguments for interactive mode"
                exit 1
                ;;
        esac
    fi
    
    print_success "Graphics driver optimization completed"
}

# Handle interruption
trap 'print_warning "Graphics optimization interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
