#!/bin/bash
# ============================================================================
# xanadOS Build System - Priority 3 Hardware Optimization Integration
# 
# Description: Comprehensive hardware optimization orchestration system
# Version: 2.0.0
# Author: xanadOS Team
# 
# Features:
# - Unified hardware optimization interface
# - Graphics driver optimization integration
# - Hardware device optimization integration
# - System performance tuning
# - Gaming-specific hardware configurations
# - Comprehensive status reporting
# ============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || {
    echo "Error: Could not source common utilities from $SCRIPT_DIR/../lib/common.sh"
    exit 1
}

# Source validation utilities
source "$SCRIPT_DIR/../lib/validation.sh" 2>/dev/null || {
    echo "Warning: Could not source validation utilities"
}

# Source gaming environment utilities
source "$SCRIPT_DIR/../lib/gaming-env.sh" 2>/dev/null || {
    echo "Warning: Could not source gaming environment utilities"
}

# Script configuration
readonly SCRIPT_NAME="Priority 3 Hardware Optimization Integration"
readonly SCRIPT_VERSION="2.0.0"
readonly LOG_FILE="/var/log/xanados/hardware-optimization.log"
readonly CONFIG_DIR="$HOME/.config/xanados/hardware"
readonly OPTIMIZATION_SCRIPTS_DIR="$SCRIPT_DIR"

# Hardware optimization components
readonly GRAPHICS_OPTIMIZER="$OPTIMIZATION_SCRIPTS_DIR/graphics-driver-optimizer.sh"
readonly DEVICE_OPTIMIZER="$OPTIMIZATION_SCRIPTS_DIR/hardware-device-optimizer.sh"

# Performance tuning configuration
readonly KERNEL_PARAMS_FILE="/etc/sysctl.d/99-xanados-hardware-optimization.conf"
readonly SYSTEMD_CONFIG_DIR="/etc/systemd/system"

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")" "$CONFIG_DIR"

# ============================================================================
# Logging Functions
# ============================================================================
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log_message "INFO" "$@"; }
log_warn() { log_message "WARN" "$@"; }
log_error() { log_message "ERROR" "$@"; }
log_success() { log_message "SUCCESS" "$@"; }

# ============================================================================
# Display Banner
# ============================================================================
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    xanadOS Hardware Optimization Integration                 ║"
    echo "║                                   Version 2.0.0                             ║"
    echo "║──────────────────────────────────────────────────────────────────────────────║"
    echo "║         Comprehensive hardware optimization orchestration system             ║"
    echo "║                    Graphics • Devices • Performance • Gaming                 ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# ============================================================================
# Help Display
# ============================================================================
show_help() {
    cat << 'EOF'
xanadOS Hardware Optimization Integration System

USAGE:
    priority3-hardware-optimization.sh [OPTIONS] [COMMAND]

COMMANDS:
    install             Run complete hardware optimization suite
    graphics            Optimize graphics drivers only
    devices             Optimize hardware devices only
    performance         Apply system performance tuning
    gaming              Apply gaming-specific optimizations
    status              Show optimization status
    verify              Verify all optimizations
    reset               Reset all hardware optimizations
    clean               Clean optimization artifacts

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -q, --quiet         Suppress non-error output
    -f, --force         Force operations without prompts
    --dry-run           Show what would be done without executing
    --skip-checks       Skip prerequisite checks
    --config-only       Generate configuration without applying

EXAMPLES:
    priority3-hardware-optimization.sh install
    priority3-hardware-optimization.sh graphics --verbose
    priority3-hardware-optimization.sh gaming --force
    priority3-hardware-optimization.sh status
    priority3-hardware-optimization.sh verify --quiet

EOF
}

# ============================================================================
# System Detection Functions
# ============================================================================
detect_hardware() {
    log_info "Detecting hardware configuration..."
    
    # Graphics hardware detection
    if command -v lspci >/dev/null 2>&1; then
        local gpu_info=$(lspci | grep -i vga || true)
        if [[ -n "$gpu_info" ]]; then
            log_info "GPU detected: $gpu_info"
            echo "$gpu_info" > "$CONFIG_DIR/gpu_info.txt"
        fi
    fi
    
    # CPU detection
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        if [[ -n "$cpu_info" ]]; then
            log_info "CPU detected: $cpu_info"
            echo "$cpu_info" > "$CONFIG_DIR/cpu_info.txt"
        fi
    fi
    
    # Memory detection
    if command -v free >/dev/null 2>&1; then
        local mem_info=$(free -h | grep "Mem:" | awk '{print $2}')
        if [[ -n "$mem_info" ]]; then
            log_info "Memory detected: $mem_info"
            echo "$mem_info" > "$CONFIG_DIR/memory_info.txt"
        fi
    fi
    
    # Gaming devices detection
    if command -v lsusb >/dev/null 2>&1; then
        local gaming_devices=$(lsusb | grep -iE "(gaming|controller|joystick|xbox|playstation)" || true)
        if [[ -n "$gaming_devices" ]]; then
            log_info "Gaming devices detected"
            echo "$gaming_devices" > "$CONFIG_DIR/gaming_devices.txt"
        fi
    fi
}

# ============================================================================
# Component Management Functions
# ============================================================================
check_component_availability() {
    local component="$1"
    
    case "$component" in
        graphics)
            if [[ ! -x "$GRAPHICS_OPTIMIZER" ]]; then
                log_error "Graphics optimizer not found or not executable: $GRAPHICS_OPTIMIZER"
                return 1
            fi
            ;;
        devices)
            if [[ ! -x "$DEVICE_OPTIMIZER" ]]; then
                log_error "Device optimizer not found or not executable: $DEVICE_OPTIMIZER"
                return 1
            fi
            ;;
        *)
            log_error "Unknown component: $component"
            return 1
            ;;
    esac
    
    return 0
}

run_graphics_optimization() {
    log_info "Running graphics optimization..."
    
    if ! check_component_availability "graphics"; then
        return 1
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        "$GRAPHICS_OPTIMIZER" --verbose
    elif [[ "$QUIET" == "true" ]]; then
        "$GRAPHICS_OPTIMIZER" --quiet
    else
        "$GRAPHICS_OPTIMIZER"
    fi
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_success "Graphics optimization completed successfully"
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$CONFIG_DIR/graphics_optimized.timestamp"
    else
        log_error "Graphics optimization failed with exit code: $exit_code"
        return $exit_code
    fi
}

run_device_optimization() {
    log_info "Running device optimization..."
    
    if ! check_component_availability "devices"; then
        return 1
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        "$DEVICE_OPTIMIZER" --verbose
    elif [[ "$QUIET" == "true" ]]; then
        "$DEVICE_OPTIMIZER" --quiet
    else
        "$DEVICE_OPTIMIZER"
    fi
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_success "Device optimization completed successfully"
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$CONFIG_DIR/devices_optimized.timestamp"
    else
        log_error "Device optimization failed with exit code: $exit_code"
        return $exit_code
    fi
}

# ============================================================================
# Performance Tuning Functions
# ============================================================================
apply_performance_tuning() {
    log_info "Applying system performance tuning..."
    
    # Create kernel parameters configuration
    if [[ "$DRY_RUN" != "true" ]]; then
        sudo tee "$KERNEL_PARAMS_FILE" >/dev/null << 'EOF'
# xanadOS Hardware Optimization - Performance Tuning
# Gaming and hardware performance optimizations

# CPU performance
kernel.sched_migration_cost_ns = 500000
kernel.sched_autogroup_enabled = 0

# Memory management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Network performance
net.core.netdev_max_backlog = 5000
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# I/O performance
kernel.io_delay_type = 3
EOF
        
        if [[ $? -eq 0 ]]; then
            log_success "Performance tuning parameters configured"
            echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$CONFIG_DIR/performance_tuned.timestamp"
        else
            log_error "Failed to configure performance tuning parameters"
            return 1
        fi
        
        # Apply the parameters
        if command -v sysctl >/dev/null 2>&1; then
            sudo sysctl -p "$KERNEL_PARAMS_FILE" >/dev/null 2>&1 || {
                log_warn "Some kernel parameters could not be applied immediately"
            }
        fi
    else
        log_info "[DRY RUN] Would configure performance tuning parameters"
    fi
}

apply_gaming_optimizations() {
    log_info "Applying gaming-specific optimizations..."
    
    # Gaming scheduler optimizations
    if [[ "$DRY_RUN" != "true" ]]; then
        # Create gaming performance service
        sudo tee "$SYSTEMD_CONFIG_DIR/xanados-gaming-performance.service" >/dev/null << 'EOF'
[Unit]
Description=xanadOS Gaming Performance Optimization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
ExecStart=/bin/bash -c 'echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable the service
        sudo systemctl daemon-reload
        sudo systemctl enable xanados-gaming-performance.service >/dev/null 2>&1 || {
            log_warn "Could not enable gaming performance service"
        }
        
        log_success "Gaming optimizations configured"
        echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$CONFIG_DIR/gaming_optimized.timestamp"
    else
        log_info "[DRY RUN] Would configure gaming optimizations"
    fi
}

# ============================================================================
# Status and Verification Functions
# ============================================================================
show_optimization_status() {
    echo -e "${YELLOW}Hardware Optimization Status:${NC}"
    echo "==============================="
    
    # Graphics optimization status
    if [[ -f "$CONFIG_DIR/graphics_optimized.timestamp" ]]; then
        local graphics_time=$(cat "$CONFIG_DIR/graphics_optimized.timestamp")
        echo -e "${GREEN}✓${NC} Graphics optimization: Applied on $graphics_time"
    else
        echo -e "${RED}✗${NC} Graphics optimization: Not applied"
    fi
    
    # Device optimization status
    if [[ -f "$CONFIG_DIR/devices_optimized.timestamp" ]]; then
        local devices_time=$(cat "$CONFIG_DIR/devices_optimized.timestamp")
        echo -e "${GREEN}✓${NC} Device optimization: Applied on $devices_time"
    else
        echo -e "${RED}✗${NC} Device optimization: Not applied"
    fi
    
    # Performance tuning status
    if [[ -f "$CONFIG_DIR/performance_tuned.timestamp" ]]; then
        local performance_time=$(cat "$CONFIG_DIR/performance_tuned.timestamp")
        echo -e "${GREEN}✓${NC} Performance tuning: Applied on $performance_time"
    else
        echo -e "${RED}✗${NC} Performance tuning: Not applied"
    fi
    
    # Gaming optimization status
    if [[ -f "$CONFIG_DIR/gaming_optimized.timestamp" ]]; then
        local gaming_time=$(cat "$CONFIG_DIR/gaming_optimized.timestamp")
        echo -e "${GREEN}✓${NC} Gaming optimizations: Applied on $gaming_time"
    else
        echo -e "${RED}✗${NC} Gaming optimizations: Not applied"
    fi
    
    echo
    
    # Hardware detection status
    if [[ -f "$CONFIG_DIR/gpu_info.txt" ]]; then
        echo -e "${BLUE}Hardware Information:${NC}"
        echo "===================="
        echo "GPU: $(cat "$CONFIG_DIR/gpu_info.txt")"
        [[ -f "$CONFIG_DIR/cpu_info.txt" ]] && echo "CPU: $(cat "$CONFIG_DIR/cpu_info.txt")"
        [[ -f "$CONFIG_DIR/memory_info.txt" ]] && echo "Memory: $(cat "$CONFIG_DIR/memory_info.txt")"
        echo
    fi
}

verify_optimizations() {
    log_info "Verifying hardware optimizations..."
    local errors=0
    
    # Verify graphics optimization
    if [[ -f "$CONFIG_DIR/graphics_optimized.timestamp" ]]; then
        if check_component_availability "graphics"; then
            log_success "Graphics optimizer is available and configured"
        else
            log_error "Graphics optimizer verification failed"
            ((errors++))
        fi
    fi
    
    # Verify device optimization
    if [[ -f "$CONFIG_DIR/devices_optimized.timestamp" ]]; then
        if check_component_availability "devices"; then
            log_success "Device optimizer is available and configured"
        else
            log_error "Device optimizer verification failed"
            ((errors++))
        fi
    fi
    
    # Verify performance tuning
    if [[ -f "$KERNEL_PARAMS_FILE" ]]; then
        log_success "Performance tuning configuration exists"
    else
        log_warn "Performance tuning configuration not found"
    fi
    
    # Verify gaming optimizations
    if systemctl is-enabled xanados-gaming-performance.service >/dev/null 2>&1; then
        log_success "Gaming performance service is enabled"
    else
        log_warn "Gaming performance service not enabled"
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "All verifications passed"
        return 0
    else
        log_error "Verification failed with $errors errors"
        return 1
    fi
}

# ============================================================================
# Reset and Cleanup Functions
# ============================================================================
reset_optimizations() {
    log_info "Resetting hardware optimizations..."
    
    if [[ "$FORCE" != "true" ]]; then
        echo -e "${YELLOW}This will reset all hardware optimizations. Continue? (y/N):${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Reset cancelled"
            return 0
        fi
    fi
    
    # Remove configuration files
    if [[ -f "$KERNEL_PARAMS_FILE" ]]; then
        sudo rm -f "$KERNEL_PARAMS_FILE"
        log_info "Removed performance tuning configuration"
    fi
    
    # Remove gaming service
    if systemctl is-enabled xanados-gaming-performance.service >/dev/null 2>&1; then
        sudo systemctl disable xanados-gaming-performance.service >/dev/null 2>&1
        sudo rm -f "$SYSTEMD_CONFIG_DIR/xanados-gaming-performance.service"
        sudo systemctl daemon-reload
        log_info "Removed gaming performance service"
    fi
    
    # Clean configuration directory
    rm -rf "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    
    log_success "Hardware optimizations reset successfully"
}

clean_artifacts() {
    log_info "Cleaning optimization artifacts..."
    
    # Clean temporary files
    find "$CONFIG_DIR" -name "*.tmp" -delete 2>/dev/null || true
    find "$CONFIG_DIR" -name "*.backup" -mtime +7 -delete 2>/dev/null || true
    
    # Clean old log entries (keep last 1000 lines)
    if [[ -f "$LOG_FILE" ]]; then
        tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
    
    log_success "Cleanup completed"
}

# ============================================================================
# Main Installation Function
# ============================================================================
run_complete_optimization() {
    log_info "Starting complete hardware optimization suite..."
    
    # Detect hardware
    detect_hardware
    
    # Run graphics optimization
    if ! run_graphics_optimization; then
        log_error "Graphics optimization failed"
        return 1
    fi
    
    # Run device optimization
    if ! run_device_optimization; then
        log_error "Device optimization failed"
        return 1
    fi
    
    # Apply performance tuning
    if ! apply_performance_tuning; then
        log_error "Performance tuning failed"
        return 1
    fi
    
    # Apply gaming optimizations
    if ! apply_gaming_optimizations; then
        log_error "Gaming optimizations failed"
        return 1
    fi
    
    log_success "Complete hardware optimization suite completed successfully!"
    echo
    show_optimization_status
}

# ============================================================================
# Main Function
# ============================================================================
main() {
    # Initialize variables
    local command="${1:-}"
    VERBOSE="false"
    QUIET="false"
    FORCE="false"
    DRY_RUN="false"
    SKIP_CHECKS="false"
    CONFIG_ONLY="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -q|--quiet)
                QUIET="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --skip-checks)
                SKIP_CHECKS="true"
                shift
                ;;
            --config-only)
                CONFIG_ONLY="true"
                shift
                ;;
            install|graphics|devices|performance|gaming|status|verify|reset|clean)
                command="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set quiet mode for logging
    if [[ "$QUIET" == "true" ]]; then
        exec 1>/dev/null
    fi
    
    # Show banner unless quiet
    if [[ "$QUIET" != "true" ]]; then
        show_banner
    fi
    
    # Prerequisite checks
    if [[ "$SKIP_CHECKS" != "true" ]]; then
        if [[ $EUID -eq 0 ]]; then
            log_error "This script should not be run as root"
            exit 1
        fi
        
        # Check sudo access
        if ! sudo -n true 2>/dev/null; then
            log_info "This script requires sudo access for system modifications"
            sudo -v || {
                log_error "Could not obtain sudo access"
                exit 1
            }
        fi
    fi
    
    # Execute command
    case "$command" in
        ""|install)
            run_complete_optimization
            ;;
        graphics)
            detect_hardware
            run_graphics_optimization
            ;;
        devices)
            detect_hardware
            run_device_optimization
            ;;
        performance)
            apply_performance_tuning
            ;;
        gaming)
            apply_gaming_optimizations
            ;;
        status)
            show_optimization_status
            ;;
        verify)
            verify_optimizations
            ;;
        reset)
            reset_optimizations
            ;;
        clean)
            clean_artifacts
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

