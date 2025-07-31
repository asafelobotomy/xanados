#!/bin/bash
# xanadOS Priority 3: Hardware-Specific Optimizations Integration Script
# Unified interface for all hardware optimization tools

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
LOG_FILE="/var/log/xanados-priority3-optimization.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█      🔧 xanadOS Priority 3: Hardware Optimizations 🔧       █"
    echo "█                                                              █"
    echo "█    Graphics Drivers • Audio Latency • Hardware Support      █"
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

# Function to check optimization components
check_optimization_components() {
    print_section "Checking Hardware Optimization Components"
    
    # Check for optimization scripts
    local required_scripts=(
        "$SCRIPT_DIR/graphics-driver-optimizer.sh"
        "$SCRIPT_DIR/audio-latency-optimizer.sh"
        "$SCRIPT_DIR/hardware-device-optimizer.sh"
    )
    
    local missing_scripts=()
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            missing_scripts+=("$(basename "$script")")
        elif [ ! -x "$script" ]; then
            print_warning "Making script executable: $(basename "$script")"
            chmod +x "$script"
        fi
    done
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        print_error "Missing optimization scripts: ${missing_scripts[*]}"
        return 1
    fi
    
    print_success "All optimization components available"
}

# Function to show system hardware overview
show_hardware_overview() {
    print_section "System Hardware Overview"
    
    echo "System Information:"
    echo "  • Hostname: $(hostname)"
    echo "  • Kernel: $(uname -r)"
    echo "  • Architecture: $(uname -m)"
    echo "  • Device Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")"
    echo
    
    echo "Graphics Hardware:"
    if lspci | grep -E "(VGA|3D|Display)" >/dev/null; then
        lspci | grep -E "(VGA|3D|Display)" | while read -r line; do
            echo "  • $line"
        done
    else
        echo "  • No graphics hardware detected"
    fi
    echo
    
    echo "Audio Hardware:"
    if lspci | grep -i audio >/dev/null; then
        lspci | grep -i audio | while read -r line; do
            echo "  • $line"
        done
    else
        echo "  • No audio hardware detected"
    fi
    echo
    
    echo "Gaming Controllers:"
    if lsusb | grep -E "(Xbox|PlayStation|Nintendo|Controller)" >/dev/null; then
        lsusb | grep -E "(Xbox|PlayStation|Nintendo|Controller)" | while read -r line; do
            echo "  • $line"
        done
    else
        echo "  • No gaming controllers detected"
    fi
    echo
    
    echo "Gaming Peripherals:"
    if lsusb | grep -E "(Logitech|Razer|SteelSeries|Corsair|HyperX)" >/dev/null; then
        lsusb | grep -E "(Logitech|Razer|SteelSeries|Corsair|HyperX)" | while read -r line; do
            echo "  • $line"
        done
    else
        echo "  • No gaming peripherals detected"
    fi
    echo
}

# Function to run graphics optimization
run_graphics_optimization() {
    print_section "Running Graphics Driver Optimization"
    
    print_status "Launching graphics driver optimizer..."
    if "$SCRIPT_DIR/graphics-driver-optimizer.sh" all; then
        print_success "Graphics optimization completed successfully"
    else
        print_error "Graphics optimization failed"
        return 1
    fi
}

# Function to run audio optimization
run_audio_optimization() {
    print_section "Running Audio Latency Optimization"
    
    print_status "Launching audio latency optimizer..."
    if "$SCRIPT_DIR/audio-latency-optimizer.sh" all; then
        print_success "Audio optimization completed successfully"
    else
        print_error "Audio optimization failed"
        return 1
    fi
}

# Function to run hardware device optimization
run_hardware_optimization() {
    print_section "Running Hardware Device Optimization"
    
    print_status "Launching hardware device optimizer..."
    if "$SCRIPT_DIR/hardware-device-optimizer.sh" all; then
        print_success "Hardware device optimization completed successfully"
    else
        print_error "Hardware device optimization failed"
        return 1
    fi
}

# Function to run complete Priority 3 optimization
run_complete_optimization() {
    print_section "Running Complete Priority 3 Optimization"
    
    local optimization_start_time
    optimization_start_time=$(date +%s)
    
    print_status "Starting complete hardware-specific optimization..."
    print_warning "This may take 15-30 minutes to complete"
    
    read -p "Continue with complete Priority 3 optimization? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    # Phase 1: Graphics optimization
    print_status "Phase 1: Graphics driver optimization..."
    if ! run_graphics_optimization; then
        print_error "Graphics optimization failed - continuing with other components"
    fi
    
    # Phase 2: Audio optimization
    print_status "Phase 2: Audio latency optimization..."
    if ! run_audio_optimization; then
        print_error "Audio optimization failed - continuing with other components"
    fi
    
    # Phase 3: Hardware device optimization
    print_status "Phase 3: Hardware device optimization..."
    if ! run_hardware_optimization; then
        print_error "Hardware device optimization failed"
    fi
    
    # Phase 4: Integration testing
    print_status "Phase 4: Testing integrated optimizations..."
    test_integrated_optimizations
    
    local optimization_end_time
    local optimization_duration
    optimization_end_time=$(date +%s)
    optimization_duration=$((optimization_end_time - optimization_start_time))
    
    print_success "Complete Priority 3 optimization finished in $(echo "scale=1; $optimization_duration/60" | bc -l) minutes"
}

# Function to test integrated optimizations
test_integrated_optimizations() {
    print_section "Testing Integrated Hardware Optimizations"
    
    print_status "Testing graphics optimizations..."
    
    # Test graphics
    if command -v glxinfo >/dev/null 2>&1; then
        echo "Graphics Driver Status:"
        echo "  Renderer: $(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs)"
        echo "  Version: $(glxinfo | grep "OpenGL version" | cut -d: -f2 | xargs)"
    fi
    
    # Test audio
    print_status "Testing audio optimizations..."
    if systemctl --user is-active pipewire >/dev/null 2>&1; then
        echo "Audio System Status:"
        echo "  PipeWire: Running"
        if command -v pw-metadata >/dev/null 2>&1; then
            quantum=$(pw-metadata -n settings 2>/dev/null | grep "default.clock.quantum" | awk '{print $3}' | tr -d '"')
            rate=$(pw-metadata -n settings 2>/dev/null | grep "default.clock.rate" | awk '{print $3}' | tr -d '"')
            echo "  Quantum: ${quantum:-"Unknown"}"
            echo "  Sample Rate: ${rate:-"Unknown"} Hz"
        fi
    else
        echo "Audio System Status: PipeWire not running"
    fi
    
    # Test hardware devices
    print_status "Testing hardware device optimizations..."
    if ls /dev/input/js* >/dev/null 2>&1; then
        echo "Controller Status:"
        for js in /dev/input/js*; do
            if [ -c "$js" ]; then
                controller_name=$(cat "/sys/class/input/$(basename "$js")/device/name" 2>/dev/null || echo "Unknown")
                echo "  $(basename "$js"): $controller_name"
            fi
        done
    else
        echo "Controller Status: No controllers detected"
    fi
    
    print_success "Integration testing completed"
}

# Function to create unified gaming mode
create_unified_gaming_mode() {
    print_section "Creating Unified Gaming Mode"
    
    # Create unified gaming mode script
    cat > "/usr/local/bin/xanados-gaming-mode" << 'EOF'
#!/bin/bash
# xanadOS Unified Gaming Mode Script

enable_gaming_mode() {
    echo "🎮 Enabling xanadOS Gaming Mode..."
    
    # Graphics optimizations
    if [ -x "/usr/local/bin/graphics-gaming-mode" ]; then
        /usr/local/bin/graphics-gaming-mode enable
    fi
    
    # Audio optimizations
    if [ -x "/usr/local/bin/audio-gaming-mode" ]; then
        /usr/local/bin/audio-gaming-mode enable
    fi
    
    # Hardware optimizations
    if [ -x "/usr/local/bin/hardware-gaming-mode" ]; then
        /usr/local/bin/hardware-gaming-mode enable
    fi
    
    # System optimizations (from Priority 1)
    if [ -x "/usr/local/bin/xanados-gaming-optimizer" ]; then
        sudo /usr/local/bin/xanados-gaming-optimizer optimize
    fi
    
    echo "✅ xanadOS Gaming Mode enabled"
    echo "All hardware and system optimizations are now active for gaming"
}

disable_gaming_mode() {
    echo "🔄 Disabling xanadOS Gaming Mode..."
    
    # Graphics optimizations
    if [ -x "/usr/local/bin/graphics-gaming-mode" ]; then
        /usr/local/bin/graphics-gaming-mode disable
    fi
    
    # Audio optimizations
    if [ -x "/usr/local/bin/audio-gaming-mode" ]; then
        /usr/local/bin/audio-gaming-mode disable
    fi
    
    # Hardware optimizations
    if [ -x "/usr/local/bin/hardware-gaming-mode" ]; then
        /usr/local/bin/hardware-gaming-mode disable
    fi
    
    # System optimizations (from Priority 1)
    if [ -x "/usr/local/bin/xanados-gaming-optimizer" ]; then
        sudo /usr/local/bin/xanados-gaming-optimizer restore
    fi
    
    echo "✅ xanadOS Gaming Mode disabled"
    echo "System restored to default performance settings"
}

show_gaming_status() {
    echo "=== xanadOS Gaming Mode Status ==="
    echo
    
    # Graphics status
    echo "Graphics Optimization:"
    if [ -x "/usr/local/bin/graphics-gaming-mode" ]; then
        /usr/local/bin/graphics-gaming-mode status 2>/dev/null || echo "  Status: Unknown"
    else
        echo "  Status: Not available"
    fi
    echo
    
    # Audio status
    echo "Audio Optimization:"
    if [ -x "/usr/local/bin/audio-gaming-mode" ]; then
        /usr/local/bin/audio-gaming-mode status 2>/dev/null || echo "  Status: Unknown"
    else
        echo "  Status: Not available"
    fi
    echo
    
    # Hardware status
    echo "Hardware Optimization:"
    if [ -x "/usr/local/bin/hardware-gaming-mode" ]; then
        /usr/local/bin/hardware-gaming-mode status 2>/dev/null || echo "  Status: Unknown"
    else
        echo "  Status: Not available"
    fi
    echo
    
    # System status
    echo "System Optimization:"
    if [ -x "/usr/local/bin/xanados-gaming-optimizer" ]; then
        /usr/local/bin/xanados-gaming-optimizer status 2>/dev/null || echo "  Status: Unknown"
    else
        echo "  Status: Not available"
    fi
    echo
}

case "$1" in
    enable|on)
        enable_gaming_mode
        ;;
    disable|off)
        disable_gaming_mode
        ;;
    status)
        show_gaming_status
        ;;
    *)
        echo "Usage: $0 {enable|disable|status}"
        echo
        echo "xanadOS Unified Gaming Mode - Hardware & System Optimizations"
        echo
        echo "Commands:"
        echo "  enable   - Enable all gaming optimizations (graphics, audio, hardware, system)"
        echo "  disable  - Disable all gaming optimizations and restore defaults"
        echo "  status   - Show current optimization status across all components"
        echo
        echo "This script coordinates all xanadOS gaming optimizations:"
        echo "  • Graphics driver optimizations (NVIDIA/AMD/Intel)"
        echo "  • Audio latency optimizations (PipeWire low-latency)"
        echo "  • Hardware device optimizations (controllers, peripherals)"
        echo "  • System performance optimizations (CPU, memory, I/O)"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/xanados-gaming-mode"
    
    print_success "Unified gaming mode script created"
}

# Function to show optimization summary
show_optimization_summary() {
    print_section "Priority 3 Optimization Summary"
    
    echo "Hardware Optimization Components:"
    echo "  ✅ Graphics driver optimization (NVIDIA, AMD, Intel)"
    echo "  ✅ Audio latency optimization (PipeWire low-latency)"
    echo "  ✅ Hardware device optimization (controllers, peripherals)"
    echo "  ✅ Portable gaming device support (Steam Deck, ROG Ally)"
    echo "  ✅ Unified gaming mode integration"
    echo
    
    echo "Optimization Scripts Available:"
    echo "  • graphics-driver-optimizer.sh    - Graphics hardware optimization"
    echo "  • audio-latency-optimizer.sh      - Audio latency optimization"
    echo "  • hardware-device-optimizer.sh    - Controller and device optimization"
    echo "  • xanados-gaming-mode             - Unified gaming mode control"
    echo
    
    echo "Gaming Mode Commands:"
    echo "  • xanados-gaming-mode enable      - Enable all optimizations"
    echo "  • xanados-gaming-mode disable     - Disable all optimizations"
    echo "  • xanados-gaming-mode status      - Show optimization status"
    echo
    
    echo "Individual Component Commands:"
    echo "  • graphics-gaming-mode enable     - Graphics optimizations only"
    echo "  • audio-gaming-mode enable        - Audio optimizations only"
    echo "  • hardware-gaming-mode enable     - Hardware optimizations only"
    echo
    
    echo "Monitoring and Testing:"
    echo "  • gpu-monitor                     - Graphics performance monitoring"
    echo "  • audio-latency-test full         - Audio latency testing"
    echo "  • controller-monitor list         - Controller detection"
    echo "  • gaming-hardware-info all        - Complete hardware information"
    echo
}

# Function to show interactive menu
show_menu() {
    print_section "Priority 3: Hardware-Specific Optimizations"
    
    echo "Choose optimization category:"
    echo
    echo "1) 🎨 Graphics Driver Optimization"
    echo "   - NVIDIA, AMD, Intel driver tuning"
    echo "   - Gaming-specific graphics settings"
    echo "   - Hybrid graphics configuration"
    echo
    echo "2) 🎵 Audio Latency Optimization"
    echo "   - PipeWire low-latency configuration"
    echo "   - Gaming audio optimizations"
    echo "   - Real-time audio permissions"
    echo
    echo "3) 🎮 Hardware Device Optimization"
    echo "   - Controller and peripheral support"
    echo "   - Portable gaming device tuning"
    echo "   - Hardware-specific optimizations"
    echo
    echo "4) 🚀 Complete Priority 3 Optimization"
    echo "   - All hardware optimizations"
    echo "   - Integrated testing and validation"
    echo "   - Unified gaming mode setup"
    echo
    echo "5) 🧪 Test Current Optimizations"
    echo "   - Validate graphics, audio, hardware"
    echo "   - Performance and functionality testing"
    echo
    echo "6) 📊 Show Hardware Overview"
    echo "   - Current system hardware status"
    echo "   - Detected gaming devices"
    echo
    echo "7) 📋 Show Optimization Summary"
    echo "   - Available tools and commands"
    echo "   - Configuration status"
    echo
    echo "8) 🚪 Exit"
    echo
}

# Main function
main() {
    # Initialize log file
    sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    sudo touch "$LOG_FILE" 2>/dev/null || true
    
    print_banner
    check_optimization_components
    
    if [ "$#" -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option [1-8]: " choice
            
            case $choice in
                1)
                    run_graphics_optimization
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    run_audio_optimization
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    run_hardware_optimization
                    read -p "Press Enter to continue..."
                    ;;
                4)
                    run_complete_optimization
                    create_unified_gaming_mode
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    test_integrated_optimizations
                    read -p "Press Enter to continue..."
                    ;;
                6)
                    show_hardware_overview
                    read -p "Press Enter to continue..."
                    ;;
                7)
                    show_optimization_summary
                    read -p "Press Enter to continue..."
                    ;;
                8)
                    print_status "Exiting Priority 3 optimization"
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
            graphics)
                run_graphics_optimization
                ;;
            audio)
                run_audio_optimization
                ;;
            hardware)
                run_hardware_optimization
                ;;
            complete|all)
                run_complete_optimization
                create_unified_gaming_mode
                ;;
            test)
                test_integrated_optimizations
                ;;
            overview)
                show_hardware_overview
                ;;
            summary)
                show_optimization_summary
                ;;
            *)
                echo "Usage: $0 [graphics|audio|hardware|complete|test|overview|summary]"
                echo "  graphics  - Run graphics driver optimization"
                echo "  audio     - Run audio latency optimization"
                echo "  hardware  - Run hardware device optimization"
                echo "  complete  - Run complete Priority 3 optimization"
                echo "  test      - Test current optimizations"
                echo "  overview  - Show hardware overview"
                echo "  summary   - Show optimization summary"
                echo
                echo "Run without arguments for interactive mode"
                exit 1
                ;;
        esac
    fi
    
    print_success "Priority 3 optimization session completed"
}

# Handle interruption
trap 'print_warning "Priority 3 optimization interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
