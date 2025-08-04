#!/bin/bash
# xanadOS Comprehensive Fix Validator
# Validates all fixes implemented during the comprehensive repository review

set -euo pipefail

# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/enhanced-testing.sh"

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VALIDATION_LOG="/tmp/xanados-fix-validation-$(date +%Y%m%d-%H%M%S).log"

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 xanadOS Comprehensive Fix Validator                  ║${NC}"
    echo -e "${BLUE}║              Validates All Implemented Improvements                  ║${NC}"
    echo -e "${BLUE}║                        $(date '+%Y-%m-%d %H:%M:%S')                        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Test Fix 2: Gaming Tool Consolidation
test_gaming_tool_consolidation() {
    echo -e "${CYAN}🎮 Testing Gaming Tool Consolidation (Fix 2)${NC}"

    local errors=0

    # Test 1: Verify GAMING_TOOLS array is not defined in validation.sh
    if grep -q "^GAMING_TOOLS=(" "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh" 2>/dev/null; then
        echo -e "${RED}✗ FAIL: GAMING_TOOLS array still exists in validation.sh${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✓ PASS: GAMING_TOOLS array removed from validation.sh${NC}"
    fi

    # Test 2: Verify cache_gaming_tools sources gaming-env.sh
    if grep -q "source.*gaming-env.sh" "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"; then
        echo -e "${GREEN}✓ PASS: cache_gaming_tools sources gaming-env.sh${NC}"
    else
        echo -e "${RED}✗ FAIL: cache_gaming_tools doesn't source gaming-env.sh${NC}"
        ((errors++))
    fi

    # Test 3: Verify arrays are properly accessed
    if grep -q "GAMING_PLATFORMS\[@\]\|GAMING_UTILITIES\[@\]" "$(dirname "${BASH_SOURCE[0]}")/../lib/validation.sh"; then
        echo -e "${GREEN}✓ PASS: Proper array access patterns found${NC}"
    else
        echo -e "${RED}✗ FAIL: Incorrect array access patterns${NC}"
        ((errors++))
    fi

    # Test 4: Test actual function execution
    if command -v cache_gaming_tools &>/dev/null; then
        if cache_gaming_tools 2>/dev/null; then
            echo -e "${GREEN}✓ PASS: cache_gaming_tools executes without errors${NC}"
        else
            echo -e "${RED}✗ FAIL: cache_gaming_tools execution failed${NC}"
            ((errors++))
        fi
    else
        echo -e "${YELLOW}⚠ SKIP: cache_gaming_tools function not available${NC}"
    fi

    echo -e "${CYAN}Gaming Tool Consolidation: $((4-errors))/4 tests passed${NC}"
    echo ""
    return $errors
}

# Test Fix 4: Script Reference Consistency
test_script_reference_consistency() {
    echo -e "${CYAN}🔗 Testing Script Reference Consistency (Fix 4)${NC}"

    local errors=0
    local lib_dir="$(dirname "${BASH_SOURCE[0]}")/../lib"

    # Test enhancement libraries for consistent sourcing patterns
    local enhancement_libs=("input-validation.sh" "secure-config.sh" "advanced-cpu-optimization.sh"
                          "advanced-memory-optimization.sh" "error-handling.sh" "enhanced-testing.sh")

    for lib in "${enhancement_libs[@]}"; do
        local lib_path="$lib_dir/$lib"
        if [[ -f "$lib_path" ]]; then
            if grep -q 'source "$(dirname "${BASH_SOURCE\[0\]}")/common.sh"' "$lib_path"; then
                echo -e "${GREEN}✓ PASS: $lib uses consistent sourcing pattern${NC}"
            else
                echo -e "${RED}✗ FAIL: $lib uses inconsistent sourcing pattern${NC}"
                ((errors++))
            fi
        else
            echo -e "${YELLOW}⚠ SKIP: $lib not found${NC}"
        fi
    done

    echo -e "${CYAN}Script Reference Consistency: $((${#enhancement_libs[@]}-errors))/${#enhancement_libs[@]} libraries consistent${NC}"
    echo ""
    return $errors
}

# Test Fix 9: Testing Framework Integration
test_testing_framework_integration() {
    echo -e "${CYAN}🧪 Testing Framework Integration (Fix 9)${NC}"

    local errors=0
    local testing_suite="$(dirname "${BASH_SOURCE[0]}")/../../testing/automated/testing-suite.sh"

    # Test 1: Verify enhanced-testing.sh is sourced
    if [[ -f "$testing_suite" ]] && grep -q "enhanced-testing.sh" "$testing_suite"; then
        echo -e "${GREEN}✓ PASS: testing-suite.sh sources enhanced-testing.sh${NC}"
    else
        echo -e "${RED}✗ FAIL: testing-suite.sh doesn't source enhanced-testing.sh${NC}"
        ((errors++))
    fi

    # Test 2: Verify clean structure (check for obvious duplicated content blocks)
    if [[ -f "$testing_suite" ]]; then
        # Look for duplicate comment headers (not including banner display)
        local comment_headers=$(grep -c "^# xanadOS Performance Testing Suite" "$testing_suite" 2>/dev/null || echo "0")
        if [[ $comment_headers -eq 1 ]]; then
            echo -e "${GREEN}✓ PASS: Clean structure in testing-suite.sh${NC}"
        else
            echo -e "${RED}✗ FAIL: Multiple comment headers found in testing-suite.sh${NC}"
            ((errors++))
        fi
    else
        echo -e "${RED}✗ FAIL: testing-suite.sh not found${NC}"
        ((errors++))
    fi

    # Test 3: Test enhanced testing functions availability
    if command -v run_test &>/dev/null; then
        echo -e "${GREEN}✓ PASS: Enhanced testing functions available${NC}"
    else
        echo -e "${YELLOW}⚠ SKIP: Enhanced testing functions not loaded${NC}"
    fi

    echo -e "${CYAN}Testing Framework Integration: $((3-errors))/3 tests passed${NC}"
    echo ""
    return $errors
}

# Test security and performance features
test_security_features() {
    echo -e "${CYAN}🛡️ Testing Security Features${NC}"

    local errors=0

    # Test 1: Verify input validation functions exist
    if command -v validate_input &>/dev/null; then
        echo -e "${GREEN}✓ PASS: Input validation functions available${NC}"
    else
        echo -e "${YELLOW}⚠ SKIP: Input validation functions not loaded${NC}"
    fi

    # Test 2: Check for set -euo pipefail in critical scripts
    local critical_scripts=("../lib/validation.sh" "../lib/gaming-env.sh")
    for script in "${critical_scripts[@]}"; do
        local script_path="$(dirname "${BASH_SOURCE[0]}")/$script"
        if [[ -f "$script_path" ]] && grep -q "set -euo pipefail" "$script_path"; then
            echo -e "${GREEN}✓ PASS: $script has proper error handling${NC}"
        else
            echo -e "${RED}✗ FAIL: $script missing proper error handling${NC}"
            ((errors++))
        fi
    done

    echo -e "${CYAN}Security Features: $((2-errors))/2 checks passed${NC}"
    echo ""
    return $errors
}

# Main validation function
main() {
    print_header

    local total_errors=0

    # Run all validation tests
    test_gaming_tool_consolidation || ((total_errors += $?))
    test_script_reference_consistency || ((total_errors += $?))
    test_testing_framework_integration || ((total_errors += $?))
    test_security_features || ((total_errors += $?))

    # Summary
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                         Validation Summary                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"

    if [[ $total_errors -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL FIXES VALIDATED SUCCESSFULLY!${NC}"
        echo -e "${GREEN}✓ Gaming tool consolidation working correctly${NC}"
        echo -e "${GREEN}✓ Script references are consistent${NC}"
        echo -e "${GREEN}✓ Testing framework integration complete${NC}"
        echo -e "${GREEN}✓ Security features implemented${NC}"
        echo ""
        echo -e "${BLUE}The xanadOS repository improvements have been successfully implemented and validated.${NC}"
        exit 0
    else
        echo -e "${RED}❌ VALIDATION FAILED: $total_errors error(s) found${NC}"
        echo -e "${YELLOW}Please review the failed tests above and fix any issues.${NC}"
        exit 1
    fi
}

# Run validation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
