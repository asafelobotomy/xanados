#!/bin/bash
# xanadOS Hardware-Specific Device Optimization Script
# Optimizes controllers, portable gaming devices, and specialized hardware

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

# Log setup with fallback
setup_logging() {
    local log_dir="/var/log/xanados"
    
    # Try to create log directory with fallback to user directory
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/hardware-optimization.log"
    else
        # Fall back to user directory if system directory creation fails
        log_dir="$HOME/.local/log/xanados"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/hardware-optimization.log"
    fi
    
    # Initialize log file
    echo "=== xanadOS Hardware Device Optimization Started: $(date) ===" >> "$LOG_FILE"
}

# Detect gaming controllers and input devices
detect_gaming_hardware() {
    print_status "Detecting gaming hardware devices..."
    
    # Initialize detection variables
    XBOX_CONTROLLERS=()
    PS_CONTROLLERS=()
    NINTENDO_CONTROLLERS=()
    GENERIC_CONTROLLERS=()
    GAMING_MICE=()
    GAMING_KEYBOARDS=()
    
    # Detect Xbox controllers
    local xbox_devices
    xbox_devices=$(lsusb | grep -i "microsoft.*xbox\|microsoft.*controller" || true)
    if [[ -n "$xbox_devices" ]]; then
        print_success "Xbox controllers detected"
        XBOX_CONTROLLERS+=("$xbox_devices")
        echo "Xbox Controllers: $xbox_devices" >> "$LOG_FILE"
    fi
    
    # Detect PlayStation controllers
    local ps_devices
    ps_devices=$(lsusb | grep -i "sony.*interactive\|sony.*computer\|sony.*playstation\|sony.*dualshock\|sony.*dualsense" || true)
    if [[ -n "$ps_devices" ]]; then
        print_success "PlayStation controllers detected"
        PS_CONTROLLERS+=("$ps_devices")
        echo "PlayStation Controllers: $ps_devices" >> "$LOG_FILE"
    fi
    
    # Detect Nintendo controllers
    local nintendo_devices
    nintendo_devices=$(lsusb | grep -i "nintendo" || true)
    if [[ -n "$nintendo_devices" ]]; then
        print_success "Nintendo controllers detected"
        NINTENDO_CONTROLLERS+=("$nintendo_devices")
        echo "Nintendo Controllers: $nintendo_devices" >> "$LOG_FILE"
    fi
    
    # Detect generic controllers via input devices
    local js_devices
    js_devices=$(find /dev/input -name "js*" 2>/dev/null | wc -l || echo "0")
    if [[ $js_devices -gt 0 ]]; then
        print_info "Generic joystick devices found: $js_devices"
        GENERIC_CONTROLLERS=("$js_devices devices")
    fi
    
    # Detect gaming mice (high DPI mice, gaming brands)
    local gaming_mice
    gaming_mice=$(lsusb | grep -i "logitech\|razer\|steelseries\|corsair\|roccat\|hyperx\|glorious" | grep -i "mouse\|gaming" || true)
    if [[ -n "$gaming_mice" ]]; then
        print_success "Gaming mice detected"
        GAMING_MICE+=("$gaming_mice")
        echo "Gaming Mice: $gaming_mice" >> "$LOG_FILE"
    fi
    
    # Detect gaming keyboards
    local gaming_keyboards
    gaming_keyboards=$(lsusb | grep -i "logitech\|razer\|steelseries\|corsair\|roccat\|hyperx" | grep -i "keyboard\|gaming" || true)
    if [[ -n "$gaming_keyboards" ]]; then
        print_success "Gaming keyboards detected"
        GAMING_KEYBOARDS+=("$gaming_keyboards")
        echo "Gaming Keyboards: $gaming_keyboards" >> "$LOG_FILE"
    fi
    
    # Summary
    local total_devices=0
    total_devices=$((${#XBOX_CONTROLLERS[@]} + ${#PS_CONTROLLERS[@]} + ${#NINTENDO_CONTROLLERS[@]} + ${#GAMING_MICE[@]} + ${#GAMING_KEYBOARDS[@]}))
    
    if [[ $total_devices -gt 0 ]]; then
        print_success "Total gaming devices detected: $total_devices"
    else
        print_warning "No specific gaming hardware detected"
    fi
}

# Create Xbox controller optimizations
optimize_xbox_controllers() {
    if [[ ${#XBOX_CONTROLLERS[@]} -eq 0 ]]; then
        return 0
    fi
    
    print_status "Optimizing Xbox controllers..."
    
    # Create udev rule for Xbox controllers
    local xbox_rule="$UDEV_RULES_DIR/99-xbox-controllers.rules"
    sudo mkdir -p "$UDEV_RULES_DIR" 2>/dev/null || true
    
    sudo tee "$xbox_rule" > /dev/null << 'EOF'
# Xbox Controller udev rules for gaming optimization

# Xbox 360 Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028e", MODE="0666", GROUP="input"

# Xbox One Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02d1", MODE="0666", GROUP="input"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02dd", MODE="0666", GROUP="input"

# Xbox Series X/S Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0b12", MODE="0666", GROUP="input"

# Xbox Elite Controllers
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="02e3", MODE="0666", GROUP="input"
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="0b00", MODE="0666", GROUP="input"

# Set CPU governor to performance when Xbox controller is connected
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028e|02d1|02dd|0b12|02e3|0b00", RUN+="/usr/bin/cpupower frequency-set -g performance"
EOF
    
    print_success "Xbox controller optimization applied"
}

# Create PlayStation controller optimizations
optimize_ps_controllers() {
    if [[ ${#PS_CONTROLLERS[@]} -eq 0 ]]; then
        return 0
    fi
    
    print_status "Optimizing PlayStation controllers..."
    
    # Create udev rule for PlayStation controllers
    local ps_rule="$UDEV_RULES_DIR/99-playstation-controllers.rules"
    sudo mkdir -p "$UDEV_RULES_DIR" 2>/dev/null || true
    
    sudo tee "$ps_rule" > /dev/null << 'EOF'
# PlayStation Controller udev rules for gaming optimization

# DualShock 3
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268", MODE="0666", GROUP="input"

# DualShock 4
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666", GROUP="input"
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666", GROUP="input"

# DualSense (PS5)
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666", GROUP="input"

# Set low latency when PlayStation controller is connected
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268|05c4|09cc|0ce6", RUN+="/bin/echo 1 > /sys/class/rtc/rtc0/max_user_freq"
EOF
    
    print_success "PlayStation controller optimization applied"
}

# Create Nintendo controller optimizations
optimize_nintendo_controllers() {
    if [[ ${#NINTENDO_CONTROLLERS[@]} -eq 0 ]]; then
        return 0
    fi
    
    print_status "Optimizing Nintendo controllers..."
    
    # Create udev rule for Nintendo controllers
    local nintendo_rule="$UDEV_RULES_DIR/99-nintendo-controllers.rules"
    sudo mkdir -p "$UDEV_RULES_DIR" 2>/dev/null || true
    
    sudo tee "$nintendo_rule" > /dev/null << 'EOF'
# Nintendo Controller udev rules for gaming optimization

# Nintendo Switch Pro Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666", GROUP="input"

# Nintendo Switch Joy-Con (L)
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2006", MODE="0666", GROUP="input"

# Nintendo Switch Joy-Con (R)
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2007", MODE="0666", GROUP="input"

# Wii U GameCube Controller Adapter
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666", GROUP="input"
EOF
    
    print_success "Nintendo controller optimization applied"
}

# Optimize gaming mice
optimize_gaming_mice() {
    if [[ ${#GAMING_MICE[@]} -eq 0 ]]; then
        return 0
    fi
    
    print_status "Optimizing gaming mice..."
    
    # Create gaming mouse configuration
    local mouse_config="$CONFIG_DIR/gaming-mouse.conf"
    sudo mkdir -p "$CONFIG_DIR" 2>/dev/null || true
    
    sudo tee "$mouse_config" > /dev/null << 'EOF'
# Gaming Mouse Optimization Configuration

# Disable mouse acceleration for precise gaming
Section "InputClass"
    Identifier "Gaming Mouse"
    MatchIsPointer "on"
    Option "AccelerationProfile" "-1"
    Option "AccelerationScheme" "none"
    Option "AccelSpeed" "-1"
EndSection
EOF
    
    # Create udev rule for gaming mice
    local mouse_rule="$UDEV_RULES_DIR/99-gaming-mice.rules"
    
    sudo tee "$mouse_rule" > /dev/null << 'EOF'
# Gaming Mouse udev rules for optimization

# Logitech Gaming Mice
SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{bInterfaceClass}=="03", MODE="0666", GROUP="input"

# Razer Gaming Mice  
SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", ATTRS{bInterfaceClass}=="03", MODE="0666", GROUP="input"

# SteelSeries Gaming Mice
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{bInterfaceClass}=="03", MODE="0666", GROUP="input"

# Corsair Gaming Mice
SUBSYSTEM=="usb", ATTRS{idVendor}=="1b1c", ATTRS{bInterfaceClass}=="03", MODE="0666", GROUP="input"

# Set high polling rate for gaming mice
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d|1532|1038|1b1c", ATTRS{bInterfaceClass}=="03", RUN+="/bin/echo 1 > /sys/module/usbhid/parameters/mousepoll"
EOF
    
    print_success "Gaming mouse optimization applied"
}

# Optimize gaming keyboards
optimize_gaming_keyboards() {
    if [[ ${#GAMING_KEYBOARDS[@]} -eq 0 ]]; then
        return 0
    fi
    
    print_status "Optimizing gaming keyboards..."
    
    # Create udev rule for gaming keyboards
    local keyboard_rule="$UDEV_RULES_DIR/99-gaming-keyboards.rules"
    sudo mkdir -p "$UDEV_RULES_DIR" 2>/dev/null || true
    
    sudo tee "$keyboard_rule" > /dev/null << 'EOF'
# Gaming Keyboard udev rules for optimization

# Logitech Gaming Keyboards
SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", MODE="0666", GROUP="input"

# Razer Gaming Keyboards
SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", MODE="0666", GROUP="input"

# SteelSeries Gaming Keyboards
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", MODE="0666", GROUP="input"

# Corsair Gaming Keyboards
SUBSYSTEM=="usb", ATTRS{idVendor}=="1b1c", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", MODE="0666", GROUP="input"

# Disable key repeat delay for gaming keyboards
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d|1532|1038|1b1c", ATTRS{bInterfaceClass}=="03", ATTRS{bInterfaceSubClass}=="01", RUN+="/usr/bin/xset r rate 200 30"
EOF
    
    print_success "Gaming keyboard optimization applied"
}

# Install required packages for gaming hardware
install_hardware_packages() {
    print_status "Installing gaming hardware support packages..."
    
    local packages=(
        "joystick"           # Joystick testing utilities
        "jstest-gtk"         # Joystick testing GUI
        "antimicrox"         # Keyboard/mouse mapping for controllers
        "gamemode"           # Gaming optimizations
        "input-utils"        # Input device utilities
        "evtest"             # Input device event testing
        "libinput-tools"     # Modern input stack tools
    )
    
    # Controller-specific packages
    if [[ ${#XBOX_CONTROLLERS[@]} -gt 0 ]]; then
        packages+=("xboxdrv")  # Xbox controller driver
    fi
    
    if [[ ${#PS_CONTROLLERS[@]} -gt 0 ]]; then
        packages+=("ds4drv")   # DualShock 4 driver
    fi
    
    # Install packages
    if [[ ${#packages[@]} -gt 0 ]]; then
        print_status "Installing: ${packages[*]}"
        if sudo apt update &>/dev/null && sudo apt install -y "${packages[@]}" &>/dev/null; then
            print_success "Hardware support packages installed successfully"
        else
            print_warning "Some packages may not have been installed"
        fi
    fi
}

# Create system-wide gaming hardware configuration
create_hardware_config() {
    print_status "Creating gaming hardware configuration..."
    
    sudo mkdir -p "$CONFIG_DIR" 2>/dev/null || true
    
    # Create main hardware configuration
    local hardware_config="$CONFIG_DIR/hardware-optimization.conf"
    
    sudo tee "$hardware_config" > /dev/null << EOF
# xanadOS Gaming Hardware Optimization Configuration
# Generated: $(date)

[Controllers]
Xbox_Controllers=${#XBOX_CONTROLLERS[@]}
PlayStation_Controllers=${#PS_CONTROLLERS[@]}
Nintendo_Controllers=${#NINTENDO_CONTROLLERS[@]}
Generic_Controllers=${#GENERIC_CONTROLLERS[@]}

[Input_Devices]
Gaming_Mice=${#GAMING_MICE[@]}
Gaming_Keyboards=${#GAMING_KEYBOARDS[@]}

[Optimizations]
Controller_Rules=enabled
Mouse_Acceleration=disabled
Keyboard_Repeat=optimized
High_Polling_Rate=enabled
Low_Latency=enabled

[System]
Optimization_Date=$(date)
Last_Modified=$(date)
EOF
    
    print_success "Hardware configuration created"
}

# Backup existing udev rules
backup_udev_rules() {
    print_status "Creating backup of existing udev rules..."
    
    local backup_dir
    backup_dir="$HOME/.config/xanados/backups/udev-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing gaming-related rules
    local rules_to_backup=(
        "99-xbox-controllers.rules"
        "99-playstation-controllers.rules"
        "99-nintendo-controllers.rules"
        "99-gaming-mice.rules"
        "99-gaming-keyboards.rules"
    )
    
    for rule in "${rules_to_backup[@]}"; do
        if [[ -f "$UDEV_RULES_DIR/$rule" ]]; then
            sudo cp "$UDEV_RULES_DIR/$rule" "$backup_dir/" 2>/dev/null || true
        fi
    done
    
    print_info "Udev rules backed up to: $backup_dir"
    echo "Backup location: $backup_dir" >> "$LOG_FILE"
}

# Apply all hardware optimizations
apply_optimizations() {
    print_status "Applying gaming hardware optimizations..."
    
    # Create backup first
    backup_udev_rules
    
    # Install necessary packages
    install_hardware_packages
    
    # Apply device-specific optimizations
    optimize_xbox_controllers
    optimize_ps_controllers
    optimize_nintendo_controllers
    optimize_gaming_mice
    optimize_gaming_keyboards
    
    # Create system configuration
    create_hardware_config
    
    # Reload udev rules
    print_status "Reloading udev rules..."
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger 2>/dev/null || true
    
    print_success "Gaming hardware optimizations applied successfully!"
    print_info "Please reconnect your gaming devices for optimizations to take effect."
}

# Remove hardware optimizations
remove_optimizations() {
    print_status "Removing gaming hardware optimizations..."
    
    local rules_to_remove=(
        "$UDEV_RULES_DIR/99-xbox-controllers.rules"
        "$UDEV_RULES_DIR/99-playstation-controllers.rules"
        "$UDEV_RULES_DIR/99-nintendo-controllers.rules"
        "$UDEV_RULES_DIR/99-gaming-mice.rules"
        "$UDEV_RULES_DIR/99-gaming-keyboards.rules"
    )
    
    for rule in "${rules_to_remove[@]}"; do
        if [[ -f "$rule" ]]; then
            sudo rm -f "$rule"
            print_info "Removed: $(basename "$rule")"
        fi
    done
    
    # Remove configuration
    if [[ -f "$CONFIG_DIR/hardware-optimization.conf" ]]; then
        sudo rm -f "$CONFIG_DIR/hardware-optimization.conf"
        print_info "Removed hardware configuration"
    fi
    
    # Reload udev rules
    sudo udevadm control --reload-rules 2>/dev/null || true
    sudo udevadm trigger 2>/dev/null || true
    
    print_success "Gaming hardware optimizations removed"
    print_info "Please reconnect your gaming devices for changes to take effect."
}

# Show current status
show_status() {
    print_status "Gaming hardware optimization status:"
    echo
    
    # Show detected hardware
    echo "Detected Gaming Hardware:"
    echo "  Xbox Controllers: ${#XBOX_CONTROLLERS[@]}"
    echo "  PlayStation Controllers: ${#PS_CONTROLLERS[@]}"
    echo "  Nintendo Controllers: ${#NINTENDO_CONTROLLERS[@]}"
    echo "  Gaming Mice: ${#GAMING_MICE[@]}"
    echo "  Gaming Keyboards: ${#GAMING_KEYBOARDS[@]}"
    echo
    
    # Check for optimization files
    echo "Optimization Status:"
    local rules_to_check=(
        "$UDEV_RULES_DIR/99-xbox-controllers.rules"
        "$UDEV_RULES_DIR/99-playstation-controllers.rules"
        "$UDEV_RULES_DIR/99-nintendo-controllers.rules"
        "$UDEV_RULES_DIR/99-gaming-mice.rules"
        "$UDEV_RULES_DIR/99-gaming-keyboards.rules"
    )
    
    local optimizations_found=false
    for rule in "${rules_to_check[@]}"; do
        if [[ -f "$rule" ]]; then
            echo "  ✅ $(basename "$rule") applied"
            optimizations_found=true
        fi
    done
    
    if ! $optimizations_found; then
        echo "  ❌ No optimizations currently applied"
    fi
    
    # Show configuration status
    if [[ -f "$CONFIG_DIR/hardware-optimization.conf" ]]; then
        echo "  ✅ Hardware configuration active"
    else
        echo "  ❌ Hardware configuration not found"
    fi
}

# Test gaming hardware
test_hardware() {
    print_status "Testing gaming hardware functionality..."
    
    # Test joystick devices
    local js_devices
    js_devices=$(find /dev/input -name "js*" 2>/dev/null || true)
    
    if [[ -n "$js_devices" ]]; then
        print_info "Available joystick devices:"
        echo "$js_devices"
        echo
        print_info "Use 'jstest /dev/input/js0' to test your controller"
    else
        print_warning "No joystick devices found"
    fi
    
    # Test input events
    if get_cached_command "evtest" &>/dev/null; then
        print_info "Input event testing available with 'evtest'"
    fi
    
    # Show input device information
    if [[ -d /proc/bus/input/devices ]]; then
        print_info "Input devices information:"
        grep -E "Name|Handlers" /proc/bus/input/devices 2>/dev/null || true
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [apply|remove|status|test|help]"
    echo
    echo "Options:"
    echo "  apply    - Detect hardware and apply gaming optimizations"
    echo "  remove   - Remove all gaming hardware optimizations"
    echo "  status   - Show current optimization status"
    echo "  test     - Test gaming hardware functionality"
    echo "  help     - Show this help message"
    echo
    echo "This script automatically detects gaming hardware and applies"
    echo "device-specific optimizations for controllers, mice, and keyboards."
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
            detect_gaming_hardware
            apply_optimizations
            ;;
        remove)
            print_banner
            remove_optimizations
            ;;
        status)
            print_banner
            detect_gaming_hardware
            show_status
            ;;
        test)
            print_banner
            detect_gaming_hardware
            test_hardware
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

