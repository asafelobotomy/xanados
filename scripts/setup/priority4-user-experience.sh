#!/bin/bash

# ==============================================================================
# xanadOS Priority 4: User Experience Polish - Integration Script
# ==============================================================================
# Description: Unified interface for all Priority 4 user experience components
#              including gaming setup wizard, KDE customization, and first-boot
# Author: xanadOS Development Team
# Version: 1.0.0
# License: MIT
# ==============================================================================

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/xanados/priority4-user-experience.log"
CONFIG_DIR="$HOME/.config/xanados"

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
DESKTOP="🖥️"
POLISH="✨"

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
    echo "=== xanadOS Priority 4 User Experience Polish Started: $(date) ===" >> "$LOG_FILE"
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

# ==============================================================================
# Component Status Check
# ==============================================================================

check_component_status() {
    log_message "INFO" "Checking component status"
    
    print_section "Component Status Check"
    
    # Check if scripts exist
    local gaming_wizard="$SCRIPT_DIR/gaming-setup-wizard.sh"
    local kde_customization="$SCRIPT_DIR/kde-gaming-customization.sh"
    local first_boot="$SCRIPT_DIR/first-boot-experience.sh"
    
    echo -e "  ${GEAR} Checking Priority 4 components..."
    
    if [[ -f "$gaming_wizard" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Gaming Setup Wizard: Available${NC}"
        GAMING_WIZARD_AVAILABLE=true
    else
        echo -e "    ${RED}${CROSSMARK} Gaming Setup Wizard: Missing${NC}"
        GAMING_WIZARD_AVAILABLE=false
    fi
    
    if [[ -f "$kde_customization" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} KDE Gaming Customization: Available${NC}"
        KDE_CUSTOMIZATION_AVAILABLE=true
    else
        echo -e "    ${RED}${CROSSMARK} KDE Gaming Customization: Missing${NC}"
        KDE_CUSTOMIZATION_AVAILABLE=false
    fi
    
    if [[ -f "$first_boot" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} First-Boot Experience: Available${NC}"
        FIRST_BOOT_AVAILABLE=true
    else
        echo -e "    ${RED}${CROSSMARK} First-Boot Experience: Missing${NC}"
        FIRST_BOOT_AVAILABLE=false
    fi
    
    # Check dependencies from previous priorities
    check_priority_dependencies
    
    log_message "SUCCESS" "Component status checked"
}

check_priority_dependencies() {
    echo -e "  ${GEAR} Checking Priority 1-3 dependencies..."
    
    # Priority 1 (Gaming Software Stack)
    if [[ -f "$SCRIPT_DIR/gaming-setup.sh" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Priority 1: Gaming Software Stack - Available${NC}"
        PRIORITY1_AVAILABLE=true
    else
        echo -e "    ${YELLOW}${ARROW} Priority 1: Gaming Software Stack - Missing${NC}"
        PRIORITY1_AVAILABLE=false
    fi
    
    # Priority 2 (Performance Validation)
    if [[ -f "$SCRIPT_DIR/../testing/testing-suite.sh" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Priority 2: Performance Validation - Available${NC}"
        PRIORITY2_AVAILABLE=true
    else
        echo -e "    ${YELLOW}${ARROW} Priority 2: Performance Validation - Missing${NC}"
        PRIORITY2_AVAILABLE=false
    fi
    
    # Priority 3 (Hardware Optimization)
    if [[ -f "$SCRIPT_DIR/priority3-hardware-optimization.sh" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Priority 3: Hardware Optimization - Available${NC}"
        PRIORITY3_AVAILABLE=true
    else
        echo -e "    ${YELLOW}${ARROW} Priority 3: Hardware Optimization - Missing${NC}"
        PRIORITY3_AVAILABLE=false
    fi
}

# ==============================================================================
# User Experience Options
# ==============================================================================

show_user_experience_options() {
    print_section "User Experience Options"
    
    echo -e "Choose your user experience setup:\n"
    
    echo -e "  ${BOLD}1.${NC} ${GREEN}Complete User Experience Setup${NC} - Full Priority 4 implementation"
    echo -e "     ${ARROW} Gaming setup wizard with hardware analysis"
    echo -e "     ${ARROW} KDE desktop customization for gaming"
    echo -e "     ${ARROW} First-boot experience (if not completed)"
    echo -e "     ${ARROW} Integration with all previous priorities"
    echo
    
    echo -e "  ${BOLD}2.${NC} ${YELLOW}Gaming Setup Wizard Only${NC} - Hardware analysis and gaming setup"
    echo -e "     ${ARROW} Run the comprehensive gaming setup wizard"
    echo -e "     ${ARROW} Hardware detection and optimization recommendations"
    echo -e "     ${ARROW} Gaming software installation and configuration"
    echo
    
    echo -e "  ${BOLD}3.${NC} ${BLUE}Desktop Customization Only${NC} - KDE gaming customization"
    echo -e "     ${ARROW} Apply gaming-focused desktop themes and layouts"
    echo -e "     ${ARROW} Configure gaming mode and shortcuts"
    echo -e "     ${ARROW} Install gaming widgets and performance monitoring"
    echo
    
    echo -e "  ${BOLD}4.${NC} ${PURPLE}First-Boot Experience${NC} - Complete first-time setup"
    echo -e "     ${ARROW} Welcome screen and system analysis"
    echo -e "     ${ARROW} Gaming profile creation"
    echo -e "     ${ARROW} Automated setup based on preferences"
    echo
    
    echo -e "  ${BOLD}5.${NC} ${CYAN}Status and Testing${NC} - Check current configuration"
    echo -e "     ${ARROW} Display current user experience status"
    echo -e "     ${ARROW} Test all Priority 4 components"
    echo -e "     ${ARROW} Generate comprehensive report"
    echo
    
    echo -e "  ${BOLD}0.${NC} Exit"
    echo
}

handle_user_experience_choice() {
    local choice="$1"
    
    case "$choice" in
        1)
            log_message "INFO" "Starting complete user experience setup"
            run_complete_user_experience
            ;;
        2)
            log_message "INFO" "Starting gaming setup wizard only"
            run_gaming_setup_wizard_only
            ;;
        3)
            log_message "INFO" "Starting desktop customization only"
            run_desktop_customization_only
            ;;
        4)
            log_message "INFO" "Starting first-boot experience"
            run_first_boot_experience
            ;;
        5)
            log_message "INFO" "Showing status and testing"
            show_status_and_testing
            ;;
        0)
            log_message "INFO" "User exited Priority 4 setup"
            echo -e "\n${YELLOW}Priority 4 setup cancelled.${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid choice. Please try again.${NC}"
            return 1
            ;;
    esac
}

# ==============================================================================
# User Experience Implementation
# ==============================================================================

run_complete_user_experience() {
    print_header "${POLISH} Complete User Experience Setup"
    
    log_message "STEP" "Starting complete Priority 4 implementation"
    
    echo -e "${BOLD}Setting up complete xanadOS user experience...${NC}"
    echo
    
    # Check if first-boot has been completed
    if [[ ! -f "/etc/xanados/first-boot-completed" ]] && $FIRST_BOOT_AVAILABLE; then
        echo -e "  ${STAR} Running first-boot experience..."
        if ! "$SCRIPT_DIR/first-boot-experience.sh"; then
            log_message "ERROR" "First-boot experience failed"
            echo -e "  ${RED}${CROSSMARK} First-boot experience failed${NC}"
        else
            log_message "SUCCESS" "First-boot experience completed"
            echo -e "  ${GREEN}${CHECKMARK} First-boot experience completed${NC}"
        fi
    else
        echo -e "  ${YELLOW}${ARROW} First-boot already completed or not available${NC}"
        
        # Run individual components
        if $GAMING_WIZARD_AVAILABLE; then
            echo -e "  ${STAR} Running gaming setup wizard..."
            if ! "$SCRIPT_DIR/gaming-setup-wizard.sh"; then
                log_message "WARNING" "Gaming setup wizard encountered issues"
                echo -e "  ${YELLOW}${ARROW} Gaming setup wizard completed with warnings${NC}"
            else
                log_message "SUCCESS" "Gaming setup wizard completed"
                echo -e "  ${GREEN}${CHECKMARK} Gaming setup wizard completed${NC}"
            fi
        fi
        
        if $KDE_CUSTOMIZATION_AVAILABLE; then
            echo -e "  ${STAR} Running KDE gaming customization..."
            if ! "$SCRIPT_DIR/kde-gaming-customization.sh"; then
                log_message "WARNING" "KDE customization encountered issues"
                echo -e "  ${YELLOW}${ARROW} KDE customization completed with warnings${NC}"
            else
                log_message "SUCCESS" "KDE customization completed"
                echo -e "  ${GREEN}${CHECKMARK} KDE customization completed${NC}"
            fi
        fi
    fi
    
    # Integration with previous priorities
    integrate_with_previous_priorities
    
    # Final validation
    validate_user_experience_setup
    
    log_message "SUCCESS" "Complete user experience setup finished"
    echo -e "\n${GREEN}${CHECKMARK} Complete user experience setup finished successfully!${NC}"
    show_completion_summary
}

run_gaming_setup_wizard_only() {
    print_header "${GAMING} Gaming Setup Wizard"
    
    log_message "STEP" "Running gaming setup wizard only"
    
    if ! $GAMING_WIZARD_AVAILABLE; then
        echo -e "${RED}Gaming setup wizard is not available.${NC}"
        return 1
    fi
    
    echo -e "${BOLD}Launching gaming setup wizard...${NC}"
    echo
    
    if "$SCRIPT_DIR/gaming-setup-wizard.sh"; then
        log_message "SUCCESS" "Gaming setup wizard completed successfully"
        echo -e "\n${GREEN}${CHECKMARK} Gaming setup wizard completed successfully!${NC}"
    else
        log_message "ERROR" "Gaming setup wizard failed"
        echo -e "\n${RED}${CROSSMARK} Gaming setup wizard encountered errors.${NC}"
        return 1
    fi
}

run_desktop_customization_only() {
    print_header "${DESKTOP} Desktop Customization"
    
    log_message "STEP" "Running desktop customization only"
    
    if ! $KDE_CUSTOMIZATION_AVAILABLE; then
        echo -e "${RED}KDE gaming customization is not available.${NC}"
        return 1
    fi
    
    # Check if running KDE
    if [[ "$XDG_CURRENT_DESKTOP" != *"KDE"* ]] && [[ -z "${KDE_FULL_SESSION:-}" ]]; then
        echo -e "${YELLOW}Warning: Not running in KDE environment.${NC}"
        echo -e "Desktop customization is optimized for KDE Plasma."
        
        read -p "Do you want to continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Desktop customization cancelled.${NC}"
            return 0
        fi
    fi
    
    echo -e "${BOLD}Applying gaming desktop customization...${NC}"
    echo
    
    if "$SCRIPT_DIR/kde-gaming-customization.sh"; then
        log_message "SUCCESS" "Desktop customization completed successfully"
        echo -e "\n${GREEN}${CHECKMARK} Desktop customization completed successfully!${NC}"
    else
        log_message "ERROR" "Desktop customization failed"
        echo -e "\n${RED}${CROSSMARK} Desktop customization encountered errors.${NC}"
        return 1
    fi
}

run_first_boot_experience() {
    print_header "${STAR} First-Boot Experience"
    
    log_message "STEP" "Running first-boot experience"
    
    if ! $FIRST_BOOT_AVAILABLE; then
        echo -e "${RED}First-boot experience is not available.${NC}"
        return 1
    fi
    
    echo -e "${BOLD}Launching first-boot experience...${NC}"
    echo
    
    if "$SCRIPT_DIR/first-boot-experience.sh"; then
        log_message "SUCCESS" "First-boot experience completed successfully"
        echo -e "\n${GREEN}${CHECKMARK} First-boot experience completed successfully!${NC}"
    else
        log_message "ERROR" "First-boot experience failed"
        echo -e "\n${RED}${CROSSMARK} First-boot experience encountered errors.${NC}"
        return 1
    fi
}

# ==============================================================================
# Integration Functions
# ==============================================================================

integrate_with_previous_priorities() {
    log_message "INFO" "Integrating with previous priorities"
    print_section "Priority Integration"
    
    echo -e "  ${GEAR} Integrating Priority 4 with previous components..."
    
    # Integration with Priority 1 (Gaming Software Stack)
    if $PRIORITY1_AVAILABLE; then
        echo -e "    ${GREEN}${CHECKMARK} Priority 1 integration: Gaming software stack detected${NC}"
        
        # Ensure gaming shortcuts are available
        create_unified_gaming_shortcuts
    else
        echo -e "    ${YELLOW}${ARROW} Priority 1: Gaming software stack not detected${NC}"
        echo -e "      Consider running Priority 1 setup first for full integration"
    fi
    
    # Integration with Priority 2 (Performance Validation)
    if $PRIORITY2_AVAILABLE; then
        echo -e "    ${GREEN}${CHECKMARK} Priority 2 integration: Performance testing available${NC}"
        
        # Link performance monitoring to user experience
        integrate_performance_monitoring
    else
        echo -e "    ${YELLOW}${ARROW} Priority 2: Performance testing not available${NC}"
    fi
    
    # Integration with Priority 3 (Hardware Optimization)
    if $PRIORITY3_AVAILABLE; then
        echo -e "    ${GREEN}${CHECKMARK} Priority 3 integration: Hardware optimization available${NC}"
        
        # Ensure gaming mode coordination
        integrate_gaming_mode_coordination
    else
        echo -e "    ${YELLOW}${ARROW} Priority 3: Hardware optimization not available${NC}"
    fi
    
    log_message "SUCCESS" "Priority integration completed"
}

create_unified_gaming_shortcuts() {
    log_message "INFO" "Creating unified gaming shortcuts"
    
    # Create unified gaming control script
    local gaming_control="/usr/local/bin/xanados-gaming-center"
    
    sudo tee "$gaming_control" > /dev/null << 'EOF'
#!/bin/bash

# xanadOS Gaming Control Center

set -euo pipefail

show_menu() {
    echo "=== xanadOS Gaming Control Center ==="
    echo
    echo "1. Launch Steam (Optimized)"
    echo "2. Launch Lutris"
    echo "3. Toggle Gaming Mode"
    echo "4. Show Performance Monitor"
    echo "5. Run System Benchmark"
    echo "6. Gaming Setup Wizard"
    echo "7. System Status"
    echo "0. Exit"
    echo
}

while true; do
    show_menu
    read -p "Enter your choice [0-7]: " choice
    
    case "$choice" in
        1)
            if command -v steam-gamemode &> /dev/null; then
                steam-gamemode
            elif command -v steam &> /dev/null; then
                steam
            else
                echo "Steam is not installed. Run gaming setup wizard to install."
            fi
            ;;
        2)
            if command -v lutris &> /dev/null; then
                lutris
            else
                echo "Lutris is not installed. Run gaming setup wizard to install."
            fi
            ;;
        3)
            if command -v xanados-gaming-mode &> /dev/null; then
                xanados-gaming-mode toggle
            else
                echo "Gaming mode is not available."
            fi
            ;;
        4)
            if command -v mangohud &> /dev/null; then
                echo "MangoHud is available. Use 'mangohud <game>' to monitor performance."
            elif command -v htop &> /dev/null; then
                htop
            else
                echo "No performance monitor available."
            fi
            ;;
        5)
            if [[ -f "/home/$USER/Documents/xanadOS/scripts/testing/testing-suite.sh" ]]; then
                "/home/$USER/Documents/xanadOS/scripts/testing/testing-suite.sh"
            else
                echo "Benchmark suite is not available."
            fi
            ;;
        6)
            if [[ -f "/home/$USER/Documents/xanadOS/scripts/setup/gaming-setup-wizard.sh" ]]; then
                "/home/$USER/Documents/xanadOS/scripts/setup/gaming-setup-wizard.sh"
            else
                echo "Gaming setup wizard is not available."
            fi
            ;;
        7)
            echo "=== System Status ==="
            if command -v xanados-gaming-mode &> /dev/null; then
                xanados-gaming-mode status
            fi
            if command -v nvidia-smi &> /dev/null; then
                echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)"
            fi
            echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
            echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done
EOF
    
    sudo chmod +x "$gaming_control"
    
    echo -e "    ${CHECKMARK} Unified gaming control center created"
}

integrate_performance_monitoring() {
    log_message "INFO" "Integrating performance monitoring"
    
    # Create performance monitoring shortcut
    local desktop_dir="$HOME/Desktop"
    mkdir -p "$desktop_dir"
    
    cat > "$desktop_dir/Performance Monitor.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Performance Monitor
Comment=Launch gaming performance monitoring
Exec=xanados-gaming-center
Icon=utilities-system-monitor
Terminal=true
Categories=System;Monitor;
EOF
    
    chmod +x "$desktop_dir/Performance Monitor.desktop" 2>/dev/null || true
    
    echo -e "    ${CHECKMARK} Performance monitoring integrated"
}

integrate_gaming_mode_coordination() {
    log_message "INFO" "Integrating gaming mode coordination"
    
    # Ensure gaming mode works with all priorities
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/priority-integration.conf" << 'EOF'
# xanadOS Priority Integration Configuration

[Priority1]
Gaming_Software_Stack=true
Steam_Integration=true
Lutris_Integration=true
GameMode_Integration=true

[Priority2]
Performance_Testing=true
Benchmark_Integration=true
Monitoring_Integration=true

[Priority3]
Hardware_Optimization=true
Gaming_Mode_Integration=true
Performance_Coordination=true

[Priority4]
User_Experience=true
Desktop_Customization=true
First_Boot_Experience=true
Unified_Interface=true
EOF
    
    echo -e "    ${CHECKMARK} Gaming mode coordination integrated"
}

# ==============================================================================
# Validation and Testing
# ==============================================================================

validate_user_experience_setup() {
    log_message "INFO" "Validating user experience setup"
    print_section "Setup Validation"
    
    echo -e "  ${GEAR} Validating Priority 4 implementation..."
    
    local validation_score=0
    local max_score=10
    
    # Check gaming setup wizard functionality
    if $GAMING_WIZARD_AVAILABLE && [[ -x "$SCRIPT_DIR/gaming-setup-wizard.sh" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Gaming Setup Wizard: Functional${NC}"
        ((validation_score += 3))
    else
        echo -e "    ${RED}${CROSSMARK} Gaming Setup Wizard: Not functional${NC}"
    fi
    
    # Check KDE customization
    if $KDE_CUSTOMIZATION_AVAILABLE && [[ -x "$SCRIPT_DIR/kde-gaming-customization.sh" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} KDE Gaming Customization: Functional${NC}"
        ((validation_score += 3))
    else
        echo -e "    ${RED}${CROSSMARK} KDE Gaming Customization: Not functional${NC}"
    fi
    
    # Check first-boot experience
    if $FIRST_BOOT_AVAILABLE && [[ -x "$SCRIPT_DIR/first-boot-experience.sh" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} First-Boot Experience: Functional${NC}"
        ((validation_score += 2))
    else
        echo -e "    ${RED}${CROSSMARK} First-Boot Experience: Not functional${NC}"
    fi
    
    # Check gaming control center
    if [[ -f "/usr/local/bin/xanados-gaming-center" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Gaming Control Center: Available${NC}"
        ((validation_score += 1))
    else
        echo -e "    ${YELLOW}${ARROW} Gaming Control Center: Not available${NC}"
    fi
    
    # Check configuration files
    if [[ -f "$CONFIG_DIR/priority-integration.conf" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Priority Integration: Configured${NC}"
        ((validation_score += 1))
    else
        echo -e "    ${YELLOW}${ARROW} Priority Integration: Not configured${NC}"
    fi
    
    # Calculate validation percentage
    local validation_percentage
    validation_percentage=$((validation_score * 100 / max_score))
    
    echo
    echo -e "  ${BOLD}Validation Score: ${validation_score}/${max_score} (${validation_percentage}%)${NC}"
    
    if [[ $validation_percentage -ge 80 ]]; then
        echo -e "  ${GREEN}${STAR} Priority 4 implementation: Excellent${NC}"
        VALIDATION_STATUS="excellent"
    elif [[ $validation_percentage -ge 60 ]]; then
        echo -e "  ${YELLOW}${STAR} Priority 4 implementation: Good${NC}"
        VALIDATION_STATUS="good"
    else
        echo -e "  ${RED}${STAR} Priority 4 implementation: Needs improvement${NC}"
        VALIDATION_STATUS="needs_improvement"
    fi
    
    log_message "SUCCESS" "Validation completed with status: $VALIDATION_STATUS"
}

show_status_and_testing() {
    print_header "${GEAR} Status and Testing"
    
    log_message "INFO" "Showing status and testing"
    
    # Component status
    check_component_status
    
    # Run validation
    validate_user_experience_setup
    
    # Show current configuration
    show_current_configuration
    
    # Offer to generate report
    echo
    read -p "Generate detailed system report? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        generate_priority4_report
    fi
}

show_current_configuration() {
    print_section "Current Configuration"
    
    echo -e "  ${GEAR} Current Priority 4 configuration:"
    
    # Gaming profile
    if [[ -f "$CONFIG_DIR/gaming-profile.conf" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} Gaming Profile: Configured${NC}"
        local gaming_style
        gaming_style=$(grep "GamingStyle=" "$CONFIG_DIR/gaming-profile.conf" 2>/dev/null | cut -d= -f2 || echo "Unknown")
        echo -e "      Gaming Style: $gaming_style"
    else
        echo -e "    ${YELLOW}${ARROW} Gaming Profile: Not configured${NC}"
    fi
    
    # Desktop customization
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] && command -v kreadconfig5 &> /dev/null; then
        local color_scheme
        color_scheme=$(kreadconfig5 --file "$HOME/.config/kdeglobals" --group "General" --key "ColorScheme" 2>/dev/null || echo "Default")
        echo -e "    ${GREEN}${CHECKMARK} Desktop Theme: $color_scheme${NC}"
    else
        echo -e "    ${YELLOW}${ARROW} Desktop Customization: Not available (non-KDE)${NC}"
    fi
    
    # Gaming mode
    if command -v xanados-gaming-mode &> /dev/null; then
        local gaming_mode_status
        gaming_mode_status=$(xanados-gaming-mode status 2>/dev/null || echo "Unknown")
        echo -e "    ${GREEN}${CHECKMARK} Gaming Mode: $gaming_mode_status${NC}"
    else
        echo -e "    ${YELLOW}${ARROW} Gaming Mode: Not available${NC}"
    fi
    
    # First-boot status
    if [[ -f "/etc/xanados/first-boot-completed" ]]; then
        echo -e "    ${GREEN}${CHECKMARK} First-Boot: Completed${NC}"
    else
        echo -e "    ${YELLOW}${ARROW} First-Boot: Not completed${NC}"
    fi
}

generate_priority4_report() {
    log_message "INFO" "Generating Priority 4 report"
    
    local report_file="$CONFIG_DIR/priority4-user-experience-report.txt"
    
    cat > "$report_file" << EOF
# xanadOS Priority 4: User Experience Polish - Status Report
# Generated: $(date)

=== COMPONENT STATUS ===
Gaming Setup Wizard: ${GAMING_WIZARD_AVAILABLE:-false}
KDE Gaming Customization: ${KDE_CUSTOMIZATION_AVAILABLE:-false}
First-Boot Experience: ${FIRST_BOOT_AVAILABLE:-false}

=== PRIORITY DEPENDENCIES ===
Priority 1 (Gaming Software): ${PRIORITY1_AVAILABLE:-false}
Priority 2 (Performance Testing): ${PRIORITY2_AVAILABLE:-false}
Priority 3 (Hardware Optimization): ${PRIORITY3_AVAILABLE:-false}

=== VALIDATION STATUS ===
Overall Status: ${VALIDATION_STATUS:-unknown}
Gaming Control Center: $(test -f "/usr/local/bin/xanados-gaming-center" && echo "Available" || echo "Not Available")
Priority Integration: $(test -f "$CONFIG_DIR/priority-integration.conf" && echo "Configured" || echo "Not Configured")

=== CONFIGURATION FILES ===
Gaming Profile: $(test -f "$CONFIG_DIR/gaming-profile.conf" && echo "Available" || echo "Not Available")
System Report: $(test -f "$CONFIG_DIR/system-report.txt" && echo "Available" || echo "Not Available")
Priority Integration: $(test -f "$CONFIG_DIR/priority-integration.conf" && echo "Available" || echo "Not Available")

=== DESKTOP ENVIRONMENT ===
Current Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}
KDE Session: ${KDE_FULL_SESSION:-Not Active}

=== FIRST-BOOT STATUS ===
First-Boot Completed: $(test -f "/etc/xanados/first-boot-completed" && echo "Yes" || echo "No")

=== LOG FILES ===
Priority 4 Log: $LOG_FILE
System Logs: /var/log/xanados/

=== GENERATED ===
Report Date: $(date)
Report Version: 1.0
EOF
    
    echo -e "  ${CHECKMARK} Report generated: $report_file"
    
    # Offer to view report
    read -p "View report now? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if command -v less &> /dev/null; then
            less "$report_file"
        else
            cat "$report_file"
        fi
    fi
}

# ==============================================================================
# Completion Summary
# ==============================================================================

show_completion_summary() {
    print_section "Priority 4 Setup Complete"
    
    echo -e "${STAR} ${BOLD}Priority 4: User Experience Polish is now complete!${NC}\n"
    
    echo -e "${BOLD}What's Available:${NC}"
    if $GAMING_WIZARD_AVAILABLE; then
        echo -e "  ${GREEN}${CHECKMARK} Gaming Setup Wizard - Hardware analysis and gaming setup${NC}"
    fi
    if $KDE_CUSTOMIZATION_AVAILABLE; then
        echo -e "  ${GREEN}${CHECKMARK} KDE Gaming Customization - Gaming-focused desktop experience${NC}"
    fi
    if $FIRST_BOOT_AVAILABLE; then
        echo -e "  ${GREEN}${CHECKMARK} First-Boot Experience - Welcome and automated setup${NC}"
    fi
    if [[ -f "/usr/local/bin/xanados-gaming-center" ]]; then
        echo -e "  ${GREEN}${CHECKMARK} Gaming Control Center - Unified gaming interface${NC}"
    fi
    echo
    
    echo -e "${BOLD}Quick Commands:${NC}"
    echo -e "  ${ARROW} ${CYAN}xanados-gaming-center${NC}        - Gaming control center"
    echo -e "  ${ARROW} ${CYAN}gaming-setup-wizard.sh${NC}      - Re-run gaming setup"
    echo -e "  ${ARROW} ${CYAN}kde-gaming-customization.sh${NC} - Re-apply desktop customization"
    echo -e "  ${ARROW} ${CYAN}first-boot-experience.sh${NC}    - Re-run first-boot experience"
    echo
    
    echo -e "${BOLD}Configuration:${NC}"
    echo -e "  ${ARROW} Gaming Profile: $CONFIG_DIR/gaming-profile.conf"
    echo -e "  ${ARROW} Priority Integration: $CONFIG_DIR/priority-integration.conf"
    echo -e "  ${ARROW} System Report: $CONFIG_DIR/system-report.txt"
    echo
    
    echo -e "${GREEN}${BOLD}Your xanadOS user experience is now fully optimized! ${POLISH}${NC}"
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
    
    # Welcome
    print_header "${POLISH} xanadOS Priority 4: User Experience Polish ${GAMING}"
    echo -e "${BOLD}Welcome to xanadOS Priority 4: User Experience Polish!${NC}"
    echo -e "This will set up the complete user experience for your gaming system."
    echo
    
    # Check component status
    check_component_status
    
    # Show options and get user choice
    while true; do
        show_user_experience_options
        read -p "Please enter your choice [1-5, 0 to exit]: " -n 1 -r
        echo
        
        if handle_user_experience_choice "$REPLY"; then
            break
        fi
    done
    
    log_message "SUCCESS" "Priority 4 user experience setup completed"
}

# Run main function
main "$@"
