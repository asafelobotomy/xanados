#!/bin/bash
# xanadOS Hardware-Specific Device Optimization Script
# Optimizes controllers, portable gaming devices, and specialized hardware

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
UDEV_RULES_DIR="/etc/udev/rules.d"
CONFIG_DIR="/etc/xanados/hardware"
LOG_FILE="/var/log/xanados-hardware-optimization.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█        🎮 xanadOS Hardware Device Optimization 🎮           █"
    echo "█                                                              █"
    echo "█     Controllers, Gaming Devices & Hardware Support          █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
}

# Function to detect gaming hardware
detect_gaming_hardware() {
    print_section "Detecting Gaming Hardware"
    
    echo "Scanning for gaming devices..."
    echo
    
    # Detect controllers
    echo "Gaming Controllers:"
    if lsusb | grep -E "(Xbox|PlayStation|DualShock|DualSense|Nintendo|8BitDo|Logitech|Razer|SteelSeries)" >/dev/null; then
        lsusb | grep -E "(Xbox|PlayStation|DualShock|DualSense|Nintendo|8BitDo|Logitech|Razer|SteelSeries)" | while read -r line; do
            echo "  ✅ $line"
        done
        HAS_CONTROLLERS=true
    else
        echo "  ❌ No gaming controllers detected"
        HAS_CONTROLLERS=false
    fi
    echo
    
    # Detect gaming mice
    echo "Gaming Mice:"
    if lsusb | grep -E "(Logitech|Razer|SteelSeries|Corsair|ROCCAT|Cooler Master|HyperX)" | grep -i mouse >/dev/null; then
        lsusb | grep -E "(Logitech|Razer|SteelSeries|Corsair|ROCCAT|Cooler Master|HyperX)" | grep -i mouse | while read -r line; do
            echo "  ✅ $line"
        done
        HAS_GAMING_MICE=true
    else
        echo "  ❌ No gaming mice detected"
        HAS_GAMING_MICE=false
    fi
    echo
    
    # Detect gaming keyboards
    echo "Gaming Keyboards:"
    if lsusb | grep -E "(Logitech|Razer|SteelSeries|Corsair|ROCCAT|Cooler Master|HyperX)" | grep -i keyboard >/dev/null; then
        lsusb | grep -E "(Logitech|Razer|SteelSeries|Corsair|ROCCAT|Cooler Master|HyperX)" | grep -i keyboard | while read -r line; do
            echo "  ✅ $line"
        done
        HAS_GAMING_KEYBOARDS=true
    else
        echo "  ❌ No gaming keyboards detected"
        HAS_GAMING_KEYBOARDS=false
    fi
    echo
    
    # Detect portable gaming devices
    echo "Portable Gaming Devices:"
    local device_model
    device_model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    case "$device_model" in
        *"Steam Deck"*)
            echo "  ✅ Valve Steam Deck detected"
            DEVICE_TYPE="steam_deck"
            ;;
        *"ROG Ally"*|*"ASUS ROG"*)
            echo "  ✅ ASUS ROG Ally detected"
            DEVICE_TYPE="rog_ally"
            ;;
        *"GPD Win"*|*"GPD Pocket"*)
            echo "  ✅ GPD handheld device detected"
            DEVICE_TYPE="gpd_device"
            ;;
        *"AYANEO"*|*"AYA"*)
            echo "  ✅ AYANEO device detected"
            DEVICE_TYPE="ayaneo"
            ;;
        *)
            echo "  ⚡ Standard desktop/laptop configuration"
            DEVICE_TYPE="desktop"
            ;;
    esac
    echo
    
    # Check for VR hardware
    echo "VR Hardware:"
    if lsusb | grep -E "(Oculus|HTC|Valve|Pico|Quest)" >/dev/null; then
        lsusb | grep -E "(Oculus|HTC|Valve|Pico|Quest)" | while read -r line; do
            echo "  ✅ $line"
        done
        HAS_VR=true
    else
        echo "  ❌ No VR hardware detected"
        HAS_VR=false
    fi
    echo
}

# Function to optimize controller support
optimize_controllers() {
    print_section "Optimizing Controller Support"
    
    print_status "Installing controller drivers and utilities..."
    
    # Install controller packages
    if command -v pacman >/dev/null 2>&1; then
        local packages=(
            "xf86-input-evdev"
            "xf86-input-libinput"
            "jstest-gtk"
            "antimicrox"
            "sc-controller"
            "ds4drv"
            "xpadneo-dkms"
            "oversteer"
        )
        
        for package in "${packages[@]}"; do
            pacman -S --needed --noconfirm "$package" 2>/dev/null || print_warning "Failed to install $package"
        done
    fi
    
    # Create controller udev rules
    sudo mkdir -p "$UDEV_RULES_DIR"
    
    # Xbox controller optimization
    sudo tee "$UDEV_RULES_DIR/99-xbox-controllers.rules" > /dev/null << 'EOF'
# Xbox Controller Optimizations
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028e", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02d1", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02dd", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02ea", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0b12", MODE="0666", TAG+="uaccess"

# Xbox Wireless Controller via USB
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0b13", MODE="0666", TAG+="uaccess"
EOF

    # PlayStation controller optimization
    sudo tee "$UDEV_RULES_DIR/99-playstation-controllers.rules" > /dev/null << 'EOF'
# PlayStation Controller Optimizations
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ba0", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666", TAG+="uaccess"

# DualShock 4 via Bluetooth
SUBSYSTEM=="input", ATTRS{name}=="*Wireless Controller*", MODE="0666", TAG+="uaccess"

# DualSense via Bluetooth
SUBSYSTEM=="input", ATTRS{name}=="*DualSense*", MODE="0666", TAG+="uaccess"
EOF

    # Nintendo Switch Pro Controller
    sudo tee "$UDEV_RULES_DIR/99-nintendo-controllers.rules" > /dev/null << 'EOF'
# Nintendo Controller Optimizations
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2017", MODE="0666", TAG+="uaccess"

# Joy-Con controllers
SUBSYSTEM=="hidraw", KERNELS=="*057E:2006*", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*057E:2007*", MODE="0666", TAG+="uaccess"
EOF

    # Gaming peripheral optimization
    sudo tee "$UDEV_RULES_DIR/99-gaming-peripherals.rules" > /dev/null << 'EOF'
# Gaming Peripheral Optimizations

# High polling rate for gaming mice
SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ENV{ID_INPUT_MOUSE}=="1", ATTR{power/autosuspend}="0"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", ENV{ID_INPUT_MOUSE}=="1", ATTR{power/autosuspend}="0"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ENV{ID_INPUT_MOUSE}=="1", ATTR{power/autosuspend}="0"

# Gaming mouse vendors
SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ACTION=="add", RUN+="/bin/sh -c 'echo on > /sys/bus/usb/devices/%k/power/control'"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", ACTION=="add", RUN+="/bin/sh -c 'echo on > /sys/bus/usb/devices/%k/power/control'"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ACTION=="add", RUN+="/bin/sh -c 'echo on > /sys/bus/usb/devices/%k/power/control'"
EOF

    # Reload udev rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    print_success "Controller optimizations applied"
}

# Function to optimize Steam Deck
optimize_steam_deck() {
    print_section "Optimizing for Steam Deck"
    
    if [ "$DEVICE_TYPE" != "steam_deck" ]; then
        print_warning "Not a Steam Deck, skipping Steam Deck optimizations"
        return
    fi
    
    print_status "Applying Steam Deck specific optimizations..."
    
    # Steam Deck specific kernel parameters
    sudo mkdir -p "$CONFIG_DIR"
    sudo tee "$CONFIG_DIR/steam-deck.conf" > /dev/null << 'EOF'
# Steam Deck Gaming Optimizations

# APU optimizations
amd_pstate=guided
amdgpu.ppfeaturemask=0xffffffff
amdgpu.gpu_recovery=1

# Audio optimizations for Steam Deck speakers
snd_acp3x.dmic_acpi_check=1

# Power management
processor.max_cstate=1
intel_idle.max_cstate=0

# Gaming performance
preempt=voluntary
rcu_nocbs=0-7
mitigations=off
EOF

    # Configure TDP management
    if command -v ryzenadj >/dev/null 2>&1; then
        # Create TDP control script
        sudo tee "/usr/local/bin/steam-deck-tdp" > /dev/null << 'EOF'
#!/bin/bash
# Steam Deck TDP Control

case "$1" in
    battery)
        ryzenadj --stapm-limit=10000 --fast-limit=10000 --slow-limit=10000
        echo "Set TDP to 10W for battery saving"
        ;;
    balanced)
        ryzenadj --stapm-limit=15000 --fast-limit=15000 --slow-limit=15000
        echo "Set TDP to 15W for balanced performance"
        ;;
    performance)
        ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000
        echo "Set TDP to 25W for maximum performance"
        ;;
    *)
        echo "Usage: $0 {battery|balanced|performance}"
        echo "Current TDP settings:"
        ryzenadj --info | grep -E "(STAPM|PPT)"
        ;;
esac
EOF
        sudo chmod +x "/usr/local/bin/steam-deck-tdp"
    fi
    
    # Configure display scaling
    if [ -n "$XDG_SESSION_TYPE" ] && [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        echo "Setting up Wayland scaling for Steam Deck..."
        mkdir -p "$HOME/.config/environment.d"
        cat > "$HOME/.config/environment.d/steam-deck.conf" << 'EOF'
# Steam Deck Wayland optimizations
GDK_SCALE=1.25
QT_SCALE_FACTOR=1.25
STEAM_FORCE_DESKTOPUI_SCALING=1.25
EOF
    fi
    
    print_success "Steam Deck optimizations applied"
}

# Function to optimize ROG Ally
optimize_rog_ally() {
    print_section "Optimizing for ASUS ROG Ally"
    
    if [ "$DEVICE_TYPE" != "rog_ally" ]; then
        print_warning "Not a ROG Ally, skipping ROG Ally optimizations"
        return
    fi
    
    print_status "Applying ROG Ally specific optimizations..."
    
    # ROG Ally specific packages
    if command -v pacman >/dev/null 2>&1; then
        local packages=(
            "rog-control-center"
            "asusctl"
            "supergfxctl"
        )
        
        for package in "${packages[@]}"; do
            pacman -S --needed --noconfirm "$package" 2>/dev/null || print_warning "Failed to install $package"
        done
    fi
    
    # ROG Ally kernel parameters
    sudo mkdir -p "$CONFIG_DIR"
    sudo tee "$CONFIG_DIR/rog-ally.conf" > /dev/null << 'EOF'
# ROG Ally Gaming Optimizations

# ASUS specific
asus_wmi.fnlock_default=0
asus_nb_wmi.wapf=4

# AMD APU optimizations
amd_pstate=guided
amdgpu.ppfeaturemask=0xffffffff
amdgpu.gpu_recovery=1

# Audio for ROG Ally
snd_hda_intel.power_save=0
snd_hda_intel.power_save_controller=0

# Gaming performance
preempt=voluntary
rcu_nocbs=0-7
mitigations=off
EOF

    # Configure ASUS services
    if systemctl list-unit-files | grep -q "asusd"; then
        sudo systemctl enable asusd
        sudo systemctl start asusd
        print_status "ASUS daemon enabled"
    fi
    
    if systemctl list-unit-files | grep -q "supergfxd"; then
        sudo systemctl enable supergfxd
        sudo systemctl start supergfxd
        print_status "SuperGFX daemon enabled"
    fi
    
    print_success "ROG Ally optimizations applied"
}

# Function to create hardware monitoring tools
create_hardware_monitoring() {
    print_section "Creating Hardware Monitoring Tools"
    
    # Create controller monitoring script
    cat > "/usr/local/bin/controller-monitor" << 'EOF'
#!/bin/bash
# Controller Monitoring Script

show_controllers() {
    echo "=== Connected Controllers ==="
    echo "Date: $(date)"
    echo
    
    # Show joystick devices
    echo "Joystick Devices:"
    if ls /dev/input/js* >/dev/null 2>&1; then
        for js in /dev/input/js*; do
            if [ -c "$js" ]; then
                echo "  $js: $(cat /sys/class/input/$(basename "$js")/device/name 2>/dev/null || echo "Unknown")"
            fi
        done
    else
        echo "  No joystick devices found"
    fi
    echo
    
    # Show event devices
    echo "Input Event Devices:"
    for event in /dev/input/event*; do
        if [ -c "$event" ]; then
            device_name=$(cat "/sys/class/input/$(basename "$event")/device/name" 2>/dev/null || echo "Unknown")
            if echo "$device_name" | grep -qE "(Xbox|PlayStation|Controller|Gamepad|Joy)"; then
                echo "  $event: $device_name"
            fi
        fi
    done
    echo
    
    # Show USB controllers
    echo "USB Gaming Devices:"
    lsusb | grep -E "(Xbox|PlayStation|Nintendo|8BitDo|Logitech|Razer|SteelSeries)" || echo "  No USB gaming devices found"
    echo
}

test_controller() {
    local js_device="$1"
    
    if [ ! -c "$js_device" ]; then
        echo "Error: $js_device not found or not accessible"
        return 1
    fi
    
    echo "Testing controller: $js_device"
    echo "Press Ctrl+C to stop testing"
    echo
    
    if command -v jstest >/dev/null 2>&1; then
        jstest "$js_device"
    else
        echo "jstest not available - install joystick package"
    fi
}

case "$1" in
    list)
        show_controllers
        ;;
    test)
        if [ -n "$2" ]; then
            test_controller "$2"
        else
            echo "Usage: $0 test /dev/input/jsX"
        fi
        ;;
    *)
        echo "Usage: $0 {list|test}"
        echo "  list          - Show connected controllers"
        echo "  test <device> - Test controller input"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/controller-monitor"
    
    # Create hardware info script
    cat > "/usr/local/bin/gaming-hardware-info" << 'EOF'
#!/bin/bash
# Gaming Hardware Information Script

show_hardware_info() {
    echo "=== Gaming Hardware Information ==="
    echo "Date: $(date)"
    echo
    
    # System information
    echo "System Information:"
    echo "  Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")"
    echo "  Manufacturer: $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")"
    echo "  BIOS: $(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo "Unknown")"
    echo
    
    # CPU information
    echo "CPU Information:"
    echo "  Model: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
    echo "  Cores: $(nproc)"
    echo "  Architecture: $(uname -m)"
    echo
    
    # GPU information
    echo "GPU Information:"
    lspci | grep -E "(VGA|3D|Display)" | while read -r line; do
        echo "  $line"
    done
    echo
    
    # Memory information
    echo "Memory Information:"
    echo "  Total: $(free -h | grep Mem | awk '{print $2}')"
    echo "  Available: $(free -h | grep Mem | awk '{print $7}')"
    echo
    
    # Storage information
    echo "Storage Information:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "(disk|part)" | head -10
    echo
    
    # USB devices
    echo "Connected USB Devices:"
    lsusb | grep -E "(Gaming|Controller|Xbox|PlayStation|Nintendo|Logitech|Razer|SteelSeries|Corsair)" || echo "  No gaming USB devices found"
    echo
    
    # Audio devices
    echo "Audio Devices:"
    if [ -f "/proc/asound/cards" ]; then
        cat /proc/asound/cards | grep -E "^\s*[0-9]" | head -5
    fi
    echo
}

show_performance_info() {
    echo "=== Performance Information ==="
    echo
    
    # CPU frequency
    echo "CPU Frequency:"
    if [ -f "/proc/cpuinfo" ]; then
        grep "cpu MHz" /proc/cpuinfo | head -4
    fi
    echo
    
    # GPU status
    echo "GPU Status:"
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu --format=csv,noheader,nounits | head -1
    elif [ -f "/sys/class/drm/card0/device/gpu_busy_percent" ]; then
        echo "  AMD GPU Utilization: $(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "N/A")%"
    fi
    echo
    
    # Memory usage
    echo "Memory Usage:"
    free -h | grep -E "(Mem|Swap)"
    echo
    
    # Load average
    echo "System Load:"
    uptime
    echo
}

case "$1" in
    hardware)
        show_hardware_info
        ;;
    performance)
        show_performance_info
        ;;
    all)
        show_hardware_info
        show_performance_info
        ;;
    *)
        echo "Usage: $0 {hardware|performance|all}"
        echo "  hardware    - Show hardware information"
        echo "  performance - Show performance information"
        echo "  all         - Show both hardware and performance info"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/gaming-hardware-info"
    
    print_success "Hardware monitoring tools created"
}

# Function to create device-specific optimization launcher
create_optimization_launcher() {
    print_section "Creating Hardware Optimization Launcher"
    
    # Create unified hardware optimization script
    cat > "/usr/local/bin/hardware-gaming-mode" << 'EOF'
#!/bin/bash
# Hardware Gaming Mode Script

enable_hardware_optimizations() {
    echo "Enabling hardware gaming optimizations..."
    
    # Disable USB autosuspend for gaming peripherals
    for device in /sys/bus/usb/devices/*/; do
        if [ -f "$device/idVendor" ] && [ -f "$device/idProduct" ]; then
            vendor=$(cat "$device/idVendor")
            product=$(cat "$device/idProduct")
            
            # Gaming peripheral vendors
            case "$vendor" in
                "046d"|"1532"|"1038"|"045e"|"054c"|"057e"|"2833")
                    echo on > "$device/power/control" 2>/dev/null || true
                    ;;
            esac
        fi
    done
    
    # Set high performance for gaming mice (high polling rate)
    for mouse in /sys/class/input/mouse*; do
        if [ -f "$mouse/device/power/control" ]; then
            echo on > "$mouse/device/power/control" 2>/dev/null || true
        fi
    done
    
    # Optimize controller input
    for js in /dev/input/js*; do
        if [ -c "$js" ]; then
            # Set high priority for controller input
            controller_pid=$(ps aux | grep "$(basename "$js")" | grep -v grep | awk '{print $2}' | head -1)
            if [ -n "$controller_pid" ]; then
                sudo renice -10 "$controller_pid" 2>/dev/null || true
            fi
        fi
    done
    
    # Device-specific optimizations
    device_model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    case "$device_model" in
        *"Steam Deck"*)
            [ -x "/usr/local/bin/steam-deck-tdp" ] && /usr/local/bin/steam-deck-tdp performance
            ;;
        *"ROG Ally"*)
            if command -v asusctl >/dev/null 2>&1; then
                asusctl profile -P Performance 2>/dev/null || true
            fi
            ;;
    esac
    
    echo "Hardware gaming optimizations enabled"
}

disable_hardware_optimizations() {
    echo "Restoring default hardware settings..."
    
    # Restore USB power management
    for device in /sys/bus/usb/devices/*/; do
        if [ -f "$device/power/control" ]; then
            echo auto > "$device/power/control" 2>/dev/null || true
        fi
    done
    
    # Device-specific restoration
    device_model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    case "$device_model" in
        *"Steam Deck"*)
            [ -x "/usr/local/bin/steam-deck-tdp" ] && /usr/local/bin/steam-deck-tdp balanced
            ;;
        *"ROG Ally"*)
            if command -v asusctl >/dev/null 2>&1; then
                asusctl profile -P Balanced 2>/dev/null || true
            fi
            ;;
    esac
    
    echo "Default hardware settings restored"
}

show_hardware_status() {
    echo "=== Hardware Gaming Mode Status ==="
    
    echo "Connected Gaming Controllers:"
    if ls /dev/input/js* >/dev/null 2>&1; then
        for js in /dev/input/js*; do
            if [ -c "$js" ]; then
                echo "  $(basename "$js"): $(cat /sys/class/input/$(basename "$js")/device/name 2>/dev/null || echo "Unknown")"
            fi
        done
    else
        echo "  No controllers detected"
    fi
    echo
    
    echo "USB Gaming Device Power States:"
    for device in /sys/bus/usb/devices/*/; do
        if [ -f "$device/idVendor" ] && [ -f "$device/product" ]; then
            vendor=$(cat "$device/idVendor")
            product=$(cat "$device/product" 2>/dev/null || echo "Unknown")
            control=$(cat "$device/power/control" 2>/dev/null || echo "unknown")
            
            case "$vendor" in
                "046d"|"1532"|"1038"|"045e"|"054c"|"057e"|"2833")
                    echo "  $product: $control"
                    ;;
            esac
        fi
    done
    echo
    
    device_model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
    echo "Device Type: $device_model"
    echo
}

case "$1" in
    enable|on)
        enable_hardware_optimizations
        ;;
    disable|off)
        disable_hardware_optimizations
        ;;
    status)
        show_hardware_status
        ;;
    *)
        echo "Usage: $0 {enable|disable|status}"
        echo "  enable  - Enable hardware gaming optimizations"
        echo "  disable - Disable hardware gaming optimizations"
        echo "  status  - Show current hardware status"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/hardware-gaming-mode"
    
    print_success "Hardware optimization launcher created"
}

# Function to show optimization summary
show_optimization_summary() {
    print_section "Hardware Optimization Summary"
    
    echo "Detected Hardware:"
    [ "$HAS_CONTROLLERS" = "true" ] && echo "  ✅ Gaming controllers detected"
    [ "$HAS_GAMING_MICE" = "true" ] && echo "  ✅ Gaming mice detected"
    [ "$HAS_GAMING_KEYBOARDS" = "true" ] && echo "  ✅ Gaming keyboards detected"
    [ "$HAS_VR" = "true" ] && echo "  ✅ VR hardware detected"
    echo "  🖥️  Device type: $DEVICE_TYPE"
    echo
    
    echo "Optimizations Applied:"
    echo "  ✅ Controller drivers and udev rules configured"
    echo "  ✅ Gaming peripheral power management optimized"
    echo "  ✅ Device-specific optimizations applied"
    echo "  ✅ Hardware monitoring tools installed"
    echo "  ✅ Gaming mode scripts created"
    echo
    
    echo "Available Commands:"
    echo "  • hardware-gaming-mode enable    - Enable hardware optimizations"
    echo "  • hardware-gaming-mode disable   - Disable hardware optimizations"
    echo "  • controller-monitor list         - List connected controllers"
    echo "  • gaming-hardware-info all        - Show complete hardware info"
    [ "$DEVICE_TYPE" = "steam_deck" ] && echo "  • steam-deck-tdp performance      - Set Steam Deck to performance mode"
    echo
    
    echo "Configuration Files:"
    echo "  • Udev rules: $UDEV_RULES_DIR/"
    echo "  • Device configs: $CONFIG_DIR/"
    echo "  • Log file: $LOG_FILE"
    echo
}

# Function to show interactive menu
show_menu() {
    print_section "Hardware Device Optimization Menu"
    
    echo "Choose an action:"
    echo
    echo "1) 🔍 Detect Gaming Hardware"
    echo "2) 🎮 Optimize Controller Support"
    echo "3) 🕹️  Configure Steam Deck Optimizations"
    echo "4) 🎯 Configure ROG Ally Optimizations"
    echo "5) 📊 Create Hardware Monitoring Tools"
    echo "6) 🚀 Create Optimization Launcher"
    echo "7) ✅ Apply All Hardware Optimizations"
    echo "8) 📋 Show Optimization Summary"
    echo "9) 🚪 Exit"
    echo
}

# Main function
main() {
    # Initialize log file
    sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    sudo touch "$LOG_FILE" 2>/dev/null || true
    
    print_banner
    
    if [ "$#" -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option [1-9]: " choice
            
            case $choice in
                1)
                    detect_gaming_hardware
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    optimize_controllers
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    detect_gaming_hardware
                    optimize_steam_deck
                    read -p "Press Enter to continue..."
                    ;;
                4)
                    detect_gaming_hardware
                    optimize_rog_ally
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    create_hardware_monitoring
                    read -p "Press Enter to continue..."
                    ;;
                6)
                    create_optimization_launcher
                    read -p "Press Enter to continue..."
                    ;;
                7)
                    detect_gaming_hardware
                    optimize_controllers
                    optimize_steam_deck
                    optimize_rog_ally
                    create_hardware_monitoring
                    create_optimization_launcher
                    show_optimization_summary
                    break
                    ;;
                8)
                    detect_gaming_hardware
                    show_optimization_summary
                    read -p "Press Enter to continue..."
                    ;;
                9)
                    print_status "Exiting hardware optimization"
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
                detect_gaming_hardware
                ;;
            controllers)
                optimize_controllers
                ;;
            steamdeck)
                detect_gaming_hardware
                optimize_steam_deck
                ;;
            rogally)
                detect_gaming_hardware
                optimize_rog_ally
                ;;
            monitor)
                create_hardware_monitoring
                ;;
            all)
                detect_gaming_hardware
                optimize_controllers
                optimize_steam_deck
                optimize_rog_ally
                create_hardware_monitoring
                create_optimization_launcher
                show_optimization_summary
                ;;
            *)
                echo "Usage: $0 [detect|controllers|steamdeck|rogally|monitor|all]"
                echo "  detect      - Detect gaming hardware"
                echo "  controllers - Optimize controller support"
                echo "  steamdeck   - Apply Steam Deck optimizations"
                echo "  rogally     - Apply ROG Ally optimizations"
                echo "  monitor     - Create monitoring tools"
                echo "  all         - Run complete optimization"
                echo
                echo "Run without arguments for interactive mode"
                exit 1
                ;;
        esac
    fi
    
    print_success "Hardware device optimization completed"
}

# Handle interruption
trap 'print_warning "Hardware optimization interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
