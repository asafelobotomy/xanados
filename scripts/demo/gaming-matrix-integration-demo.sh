#!/bin/bash
# ==============================================================================
# Gaming Matrix Integration Demo
# 
# Demonstrates the integrated gaming environment analysis across multiple
# xanadOS setup scripts.
# ==============================================================================

set -euo pipefail

# Source xanadOS shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gaming-env.sh"

# ==============================================================================
# Demo Functions
# ==============================================================================

demo_gaming_setup_wizard() {
    print_header "🎮 Gaming Setup Wizard Integration"
    echo "Simulating gaming setup wizard experience..."
    echo
    
    # Initialize cache (as done in the real script)
    print_status "Initializing gaming wizard cache..."
    cache_gaming_tools
    cache_system_tools
    echo
    
    # Gaming environment analysis (as integrated)
    log_message "INFO" "Analyzing gaming environment..."
    echo
    print_section_header "Gaming Environment Analysis"
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
    
    echo -e "${GREEN}✓ Gaming matrix successfully integrated into gaming-setup-wizard.sh${NC}"
    echo
}

demo_first_boot_experience() {
    print_header "🚀 First-Boot Experience Integration"
    echo "Simulating first-boot gaming assessment experience..."
    echo
    
    print_section "Gaming Readiness Assessment"
    
    # Use comprehensive gaming matrix analysis (as integrated)
    echo -e "  ${GEAR} Analyzing gaming environment..."
    echo
    generate_gaming_matrix "table"
    echo
    
    local readiness_score
    readiness_score=$(get_gaming_readiness_score)
    
    echo -e "  ${GEAR} Overall Gaming Readiness: ${BOLD}${readiness_score}%${NC}"
    echo
    
    if [[ $readiness_score -ge 80 ]]; then
        echo -e "  ${GREEN}${CHECKMARK} Excellent gaming setup! Your system is ready for high-end gaming.${NC}"
    elif [[ $readiness_score -ge 60 ]]; then
        echo -e "  ${GREEN}${CHECKMARK} Good gaming capability with room for improvement.${NC}"
    elif [[ $readiness_score -ge 40 ]]; then
        echo -e "  ${YELLOW}${ARROW} Basic gaming capability detected.${NC}"
    else
        echo -e "  ${RED}${CROSSMARK} Limited gaming capability.${NC}"
    fi
    echo
    
    echo -e "${GREEN}✓ Gaming matrix successfully integrated into first-boot-experience.sh${NC}"
    echo
}

demo_priority4_integration() {
    print_header "✨ Priority 4 User Experience Integration"
    echo "Simulating Priority 4 gaming environment overview..."
    echo
    
    print_section "Gaming Environment Overview"
    echo -e "  ${GEAR} Quick gaming readiness assessment..."
    echo
    generate_gaming_matrix "table"
    echo
    
    local readiness_score
    readiness_score=$(get_gaming_readiness_score)
    echo -e "  ${GAMING} Gaming Readiness: ${BOLD}${readiness_score}%${NC}"
    
    if [[ $readiness_score -ge 80 ]]; then
        echo -e "  ${GREEN}${CHECKMARK} Excellent! Your system is well-configured for gaming.${NC}"
    elif [[ $readiness_score -ge 60 ]]; then
        echo -e "  ${YELLOW}${ARROW} Good setup with room for enhancement.${NC}"
    elif [[ $readiness_score -ge 40 ]]; then
        echo -e "  ${YELLOW}${ARROW} Basic gaming capability. Consider additional setup.${NC}"
    else
        echo -e "  ${RED}${CROSSMARK} Limited gaming setup. Recommended to run full configuration.${NC}"
    fi
    echo
    
    echo -e "${GREEN}✓ Gaming matrix successfully integrated into priority4-user-experience.sh${NC}"
    echo
}

# ==============================================================================
# Main Demo Function
# ==============================================================================

main() {
    print_header "🎮 Gaming Matrix Integration Demo"
    echo -e "Demonstrating gaming environment analysis integration across xanadOS scripts"
    echo
    
    echo -e "This demo shows how the gaming tool availability matrix has been"
    echo -e "integrated into key xanadOS setup scripts for immediate user feedback."
    echo
    
    # Demo each integration
    demo_gaming_setup_wizard
    demo_first_boot_experience
    demo_priority4_integration
    
    # Summary
    print_header "📊 Integration Summary"
    echo -e "Gaming Matrix Integration Complete!"
    echo
    echo -e "The gaming tool availability matrix is now integrated into:"
    echo -e "  ✓ gaming-setup-wizard.sh - Full gaming environment analysis with scoring"
    echo -e "  ✓ first-boot-experience.sh - Comprehensive gaming readiness assessment"  
    echo -e "  ✓ priority4-user-experience.sh - Quick gaming environment overview"
    echo
    echo -e "Benefits:"
    echo -e "  → Immediate gaming environment feedback to users"
    echo -e "  → Consistent gaming assessment across all scripts"
    echo -e "  → Performance optimized with command caching"
    echo -e "  → Multiple output formats (table, JSON, detailed)"
    echo
    echo -e "Users now get comprehensive gaming environment insights during setup!"
}

# Run the demo
main "$@"
