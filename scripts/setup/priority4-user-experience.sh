#!/bin/bash
# ==============================================================================
# xanadOS Priority 4: User Experience Polish - Integration Script (Optimized)
# ==============================================================================
# Description: Unified interface for all Priority 4 user experience components
#              including gaming setup wizard, KDE customization, and first-boot
# Author: xanadOS Development Team
# Version: 1.1.0 (Optimized)
# License: MIT
# ==============================================================================

set -euo pipefail

# Source shared setup library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/setup-common.sh" || {
    echo "Error: Could not source setup-common library"
    exit 1
}

# Script configuration
readonly SCRIPT_NAME="Priority 4 User Experience Polish"
readonly SCRIPT_VERSION="1.1.0"

# Component scripts
readonly FIRST_BOOT_SCRIPT="$SCRIPT_DIR/first-boot-experience.sh"
readonly GAMING_WIZARD_SCRIPT="$SCRIPT_DIR/gaming-setup-wizard.sh"
readonly KDE_CUSTOMIZATION_SCRIPT="$SCRIPT_DIR/kde-customization.sh"

# Unicode symbols for enhanced display
readonly GAMING="🎮"
readonly DESKTOP="🖥️"
readonly POLISH="✨"

# Initialize logging with standard setup
setup_standard_logging "priority4-user-experience"

# ==============================================================================
# Component Management Functions
# ==============================================================================
check_component_status() {
    log_info "Checking component status"
    
    echo -e "${BLUE}═══ Component Availability ═══${NC}"
    
    # First-boot experience
    if [[ -x "$FIRST_BOOT_SCRIPT" ]]; then
        echo -e "${GREEN}✓${NC} First-boot experience script available"
    else
        echo -e "${RED}✗${NC} First-boot experience script not found: $FIRST_BOOT_SCRIPT"
    fi
    
    # Gaming setup wizard
    if [[ -x "$GAMING_WIZARD_SCRIPT" ]]; then
        echo -e "${GREEN}✓${NC} Gaming setup wizard available"
    else
        echo -e "${RED}✗${NC} Gaming setup wizard not found: $GAMING_WIZARD_SCRIPT"
    fi
    
    # KDE customization
    if [[ -x "$KDE_CUSTOMIZATION_SCRIPT" ]]; then
        echo -e "${GREEN}✓${NC} KDE customization script available"
    else
        echo -e "${RED}✗${NC} KDE customization script not found: $KDE_CUSTOMIZATION_SCRIPT"
    fi
    
    echo
    echo -e "${BLUE}═══ System Status ═══${NC}"
    
    # Desktop environment detection
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]] || [[ "${DESKTOP_SESSION:-}" == *"plasma"* ]]; then
        echo -e "${GREEN}✓${NC} KDE Plasma desktop environment detected"
    else
        echo -e "${YELLOW}!${NC} KDE Plasma not detected (current: ${XDG_CURRENT_DESKTOP:-unknown})"
    fi
    
    # Gaming environment
    cache_hardware_info
    show_hardware_summary
    
    log_success "Component status checked"
}

show_main_menu() {
    clear
    print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
    
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                        Priority 4: User Experience Polish${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}${POLISH} What would you like to do?${NC}"
    echo
    echo -e "${GREEN}  1)${NC} Complete User Experience Setup      ${GRAY}(Recommended for new installations)${NC}"
    echo -e "${GREEN}  2)${NC} Gaming Setup Wizard Only           ${GRAY}(Gaming environment configuration)${NC}"
    echo -e "${GREEN}  3)${NC} Desktop Customization Only         ${GRAY}(KDE Plasma customization)${NC}"
    echo -e "${GREEN}  4)${NC} First-Boot Experience              ${GRAY}(Initial system setup)${NC}"
    echo -e "${GREEN}  5)${NC} Status and Testing                 ${GRAY}(View configuration status)${NC}"
    echo -e "${GREEN}  6)${NC} Exit                               ${GRAY}(Return to terminal)${NC}"
    echo
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo
}

handle_menu_selection() {
    local choice="$1"
    
    case "$choice" in
        1)
            log_info "Starting complete user experience setup"
            run_complete_setup
            ;;
        2)
            log_info "Starting gaming setup wizard only"
            run_gaming_wizard
            ;;
        3)
            log_info "Starting desktop customization only"
            run_kde_customization
            ;;
        4)
            log_info "Starting first-boot experience"
            run_first_boot_experience
            ;;
        5)
            log_info "Showing status and testing"
            check_component_status
            ;;
        6)
            log_info "User exited Priority 4 setup"
            echo -e "${GREEN}Thank you for using xanadOS Priority 4 User Experience Polish!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please choose 1-6.${NC}"
            sleep 2
            ;;
    esac
}

# ==============================================================================
# Component Execution Functions
# ==============================================================================
run_complete_setup() {
    print_section_header "${POLISH} Complete User Experience Setup"
    
    log_info "Starting complete Priority 4 implementation"
    
    local success=true
    
    # Step 1: First-boot experience
    echo -e "${CYAN}Step 1: First-Boot Experience${NC}"
    if run_first_boot_experience; then
        log_success "First-boot experience completed"
    else
        log_error "First-boot experience failed"
        success=false
    fi
    
    # Step 2: Gaming setup wizard
    echo -e "${CYAN}Step 2: Gaming Setup Wizard${NC}"
    if run_gaming_wizard; then
        log_success "Gaming setup wizard completed"
    else
        log_warn "Gaming setup wizard encountered issues"
        success=false
    fi
    
    # Step 3: KDE customization
    echo -e "${CYAN}Step 3: KDE Customization${NC}"
    if run_kde_customization; then
        log_success "KDE customization completed"
    else
        log_warn "KDE customization encountered issues"
        success=false
    fi
    
    # Summary
    echo
    if [[ "$success" == "true" ]]; then
        echo -e "${GREEN}${CHECKMARK} Complete user experience setup finished successfully!${NC}"
        log_success "Complete user experience setup finished"
    else
        echo -e "${YELLOW}⚠  Complete user experience setup finished with some issues${NC}"
        echo -e "${GRAY}   Check the log file for details: $LOG_FILE${NC}"
        log_warn "Complete user experience setup finished with warnings"
    fi
    
    echo
    read -p "Press Enter to return to menu..."
}

run_gaming_wizard() {
    print_section_header "${GAMING} Gaming Setup Wizard"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY RUN] Would run gaming setup wizard"
        return 0
    fi
    
    if [[ ! -x "$GAMING_WIZARD_SCRIPT" ]]; then
        log_error "Gaming setup wizard script not found or not executable: $GAMING_WIZARD_SCRIPT"
        return 1
    fi
    
    log_info "Executing gaming setup wizard"
    
    if "$GAMING_WIZARD_SCRIPT" "${GAMING_ARGS[@]:-}"; then
        log_success "Gaming setup wizard completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "Gaming setup wizard failed with exit code: $exit_code"
        return $exit_code
    fi
}

run_kde_customization() {
    print_section_header "${DESKTOP} KDE Plasma Customization"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY RUN] Would run KDE customization"
        return 0
    fi
    
    if [[ ! -x "$KDE_CUSTOMIZATION_SCRIPT" ]]; then
        log_error "KDE customization script not found or not executable: $KDE_CUSTOMIZATION_SCRIPT"
        return 1
    fi
    
    log_info "Executing KDE customization"
    
    if "$KDE_CUSTOMIZATION_SCRIPT" "${KDE_ARGS[@]:-}"; then
        log_success "KDE customization completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "KDE customization failed with exit code: $exit_code"
        return $exit_code
    fi
}

run_first_boot_experience() {
    print_section_header "${POLISH} First-Boot Experience"
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY RUN] Would run first-boot experience"
        return 0
    fi
    
    if [[ ! -x "$FIRST_BOOT_SCRIPT" ]]; then
        log_error "First-boot experience script not found or not executable: $FIRST_BOOT_SCRIPT"
        return 1
    fi
    
    log_info "Executing first-boot experience"
    
    if "$FIRST_BOOT_SCRIPT" "${FIRST_BOOT_ARGS[@]:-}"; then
        log_success "First-boot experience completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "First-boot experience failed with exit code: $exit_code"
        return $exit_code
    fi
}

# ==============================================================================
# Configuration and Testing Functions
# ==============================================================================
run_configuration_test() {
    print_section_header "🧪 Configuration Testing"
    
    log_info "Running configuration tests"
    
    echo -e "${BLUE}═══ Testing Components ═══${NC}"
    
    # Test gaming environment
    echo -e "${CYAN}Testing gaming environment...${NC}"
    if command -v steam >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Steam installed"
    else
        echo -e "${YELLOW}!${NC} Steam not found"
    fi
    
    if command -v lutris >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Lutris installed"
    else
        echo -e "${YELLOW}!${NC} Lutris not found"
    fi
    
    # Test desktop environment
    echo -e "${CYAN}Testing desktop environment...${NC}"
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
        echo -e "${GREEN}✓${NC} KDE Plasma active"
    else
        echo -e "${YELLOW}!${NC} KDE Plasma not active"
    fi
    
    # Test system resources
    echo -e "${CYAN}Testing system resources...${NC}"
    local mem_total
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    if [[ "$mem_total" -gt 4096 ]]; then
        echo -e "${GREEN}✓${NC} Sufficient memory: ${mem_total}MB"
    else
        echo -e "${YELLOW}!${NC} Limited memory: ${mem_total}MB"
    fi
    
    log_success "Configuration testing completed"
    
    echo
    read -p "Press Enter to return to menu..."
}

# ==============================================================================
# Help and Usage Functions
# ==============================================================================
show_help() {
    cat << 'EOF'
xanadOS Priority 4: User Experience Polish (Optimized)

USAGE:
    priority4-user-experience.sh [OPTIONS] [COMMAND]

COMMANDS:
    interactive         Show interactive menu (default)
    complete           Run complete user experience setup
    gaming             Run gaming setup wizard only
    desktop            Run desktop customization only
    first-boot         Run first-boot experience
    status             Show component status
    test               Run configuration tests

OPTIONS:
    -h, --help         Show this help message
    -v, --verbose      Enable verbose output
    -q, --quiet        Suppress non-error output
    -f, --force        Force operations without prompts
    --dry-run          Show what would be done without executing
    --skip-checks      Skip prerequisite checks

EXAMPLES:
    priority4-user-experience.sh interactive
    priority4-user-experience.sh complete --verbose
    priority4-user-experience.sh gaming --force
    priority4-user-experience.sh status

EOF
}

# ==============================================================================
# Main Function
# ==============================================================================
main() {
    # Parse command line arguments
    parse_common_args "$@"
    
    # Handle help
    if [[ "${SHOW_HELP:-false}" == "true" ]]; then
        show_help
        exit 0
    fi
    
    # Get command
    local command="${1:-interactive}"
    shift 2>/dev/null || true
    
    # Perform prerequisite checks
    if [[ "${SKIP_CHECKS:-false}" != "true" ]]; then
        check_system_requirements || {
            log_error "System requirements not met"
            exit 1
        }
    fi
    
    # Execute command
    case "$command" in
        interactive|menu)
            # Interactive menu mode
            while true; do
                show_main_menu
                read -p "Please enter your choice (1-6): " choice
                echo
                handle_menu_selection "$choice"
            done
            ;;
        complete)
            print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
            run_complete_setup
            ;;
        gaming)
            print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
            run_gaming_wizard
            ;;
        desktop)
            print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
            run_kde_customization
            ;;
        first-boot)
            print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
            run_first_boot_experience
            ;;
        status)
            print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
            check_component_status
            ;;
        test)
            print_standard_banner "$SCRIPT_NAME" "$SCRIPT_VERSION"
            run_configuration_test
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
