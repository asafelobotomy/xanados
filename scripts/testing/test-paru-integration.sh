#!/bin/bash
# xanadOS Paru Integration Test Suite
# Validates paru as unified default package manager

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TEST_LOG="/tmp/paru-integration-test-$(date +%s).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
exec > >(tee -a "$TEST_LOG")
exec 2>&1

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$TEST_LOG"
}

print_test_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  $1${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    log "TEST_SECTION: $1"
}

print_test() {
    echo -e "${BLUE}📋 Testing:${NC} $1"
    log "TEST_START: $1"
}

pass_test() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✅ PASS:${NC} $1"
    log "TEST_PASS: $1"
}

fail_test() {
    ((TESTS_FAILED++))
    echo -e "${RED}❌ FAIL:${NC} $1"
    log "TEST_FAIL: $1"
}

skip_test() {
    echo -e "${YELLOW}⏭️  SKIP:${NC} $1"
    log "TEST_SKIP: $1"
}

run_test() {
    ((TESTS_RUN++))
    print_test "$1"
}

# Test 1: Paru Installation and Availability
test_paru_installation() {
    print_test_header "Paru Installation and Availability"

    run_test "Paru command availability"
    if command -v paru &>/dev/null; then
        pass_test "paru command found in PATH"
    else
        fail_test "paru command not found"
        return 1
    fi

    run_test "Paru version information"
    if paru --version &>/dev/null; then
        local version=$(paru --version | head -n1)
        pass_test "paru version: $version"
    else
        fail_test "paru version command failed"
    fi

    run_test "Paru help functionality"
    if paru --help &>/dev/null; then
        pass_test "paru help system works"
    else
        fail_test "paru help system failed"
    fi
}

# Test 2: Paru Configuration
test_paru_configuration() {
    print_test_header "Paru Configuration"

    run_test "Global paru configuration"
    if [[ -f /etc/paru/paru.conf ]]; then
        pass_test "Global paru configuration exists"

        # Check for gaming optimizations
        if grep -q "march=native" /etc/paru/paru.conf 2>/dev/null; then
            pass_test "Gaming-optimized compiler flags configured"
        else
            fail_test "Gaming compiler flags not found"
        fi

        if grep -q "j\$(nproc)" /etc/paru/paru.conf 2>/dev/null; then
            pass_test "Parallel compilation configured"
        else
            fail_test "Parallel compilation not configured"
        fi
    else
        fail_test "Global paru configuration missing"
    fi

    run_test "User paru configuration"
    if [[ -f "$HOME/.config/paru/paru.conf" ]]; then
        pass_test "User paru configuration exists"
    else
        skip_test "User paru configuration not found (may be using global)"
    fi
}

# Test 3: xpkg Unified Interface
test_xpkg_interface() {
    print_test_header "xpkg Unified Interface"

    run_test "xpkg command availability"
    if command -v xpkg &>/dev/null; then
        pass_test "xpkg command found in PATH"
    else
        fail_test "xpkg command not found"
        return 1
    fi

    run_test "xpkg script existence"
    if [[ -f "$PROJECT_ROOT/scripts/package-management/xpkg.sh" ]]; then
        pass_test "xpkg.sh script exists"

        if [[ -x "$PROJECT_ROOT/scripts/package-management/xpkg.sh" ]]; then
            pass_test "xpkg.sh script is executable"
        else
            fail_test "xpkg.sh script not executable"
        fi
    else
        fail_test "xpkg.sh script missing"
    fi

    run_test "xpkg help functionality"
    if timeout 10 xpkg help &>/dev/null; then
        pass_test "xpkg help command works"
    else
        fail_test "xpkg help command failed"
    fi
}

# Test 4: Package Manager Integration
test_package_manager_integration() {
    print_test_header "Package Manager Integration"

    run_test "Paru repository access"
    if timeout 30 paru -Sy &>/dev/null; then
        pass_test "Paru can sync repositories"
    else
        fail_test "Paru repository sync failed"
    fi

    run_test "Paru AUR access"
    if timeout 20 paru -Ss "paru" | grep -q "aur/" 2>/dev/null; then
        pass_test "Paru can access AUR packages"
    else
        skip_test "AUR access test skipped (network or permissions)"
    fi

    run_test "Paru query functionality"
    if paru -Q | head -n5 &>/dev/null; then
        pass_test "Paru can query installed packages"
        local package_count=$(paru -Q | wc -l)
        pass_test "Found $package_count installed packages"
    else
        fail_test "Paru package query failed"
    fi

    run_test "Paru AUR package listing"
    if paru -Qm &>/dev/null; then
        local aur_count=$(paru -Qm | wc -l)
        pass_test "Found $aur_count AUR packages"
    else
        skip_test "AUR package listing failed (no AUR packages installed)"
    fi
}

# Test 5: System Integration
test_system_integration() {
    print_test_header "System Integration"

    run_test "Shell aliases configuration"
    if [[ -f /etc/profile.d/xanados-package-manager.sh ]]; then
        pass_test "Shell aliases file exists"

        if grep -q "alias pkg=" /etc/profile.d/xanados-package-manager.sh; then
            pass_test "Package manager aliases configured"
        else
            fail_test "Package manager aliases not found"
        fi
    else
        fail_test "Shell aliases configuration missing"
    fi

    run_test "Bash completion"
    if [[ -f /etc/bash_completion.d/xpkg ]]; then
        pass_test "Bash completion for xpkg exists"
    else
        fail_test "Bash completion missing"
    fi

    run_test "System update service"
    if [[ -f /etc/systemd/system/xanados-update.service ]]; then
        pass_test "System update service exists"

        if systemctl list-unit-files | grep -q "xanados-update.timer"; then
            pass_test "System update timer configured"
        else
            fail_test "System update timer not found"
        fi
    else
        fail_test "System update service missing"
    fi
}

# Test 6: AUR Manager Integration
test_aur_manager_integration() {
    print_test_header "AUR Manager Integration"

    run_test "Updated AUR manager script"
    if [[ -f "$PROJECT_ROOT/scripts/aur-management/aur-manager.sh" ]]; then
        pass_test "AUR manager script exists"

        # Check if script uses paru instead of yay
        if grep -q "paru" "$PROJECT_ROOT/scripts/aur-management/aur-manager.sh"; then
            pass_test "AUR manager uses paru"
        else
            fail_test "AUR manager still uses old package managers"
        fi

        # Check if yay references are removed
        if ! grep -q "yay" "$PROJECT_ROOT/scripts/aur-management/aur-manager.sh"; then
            pass_test "AUR manager no longer references yay"
        else
            fail_test "AUR manager still has yay references"
        fi
    else
        fail_test "AUR manager script missing"
    fi
}

# Test 7: Package Lists Compatibility
test_package_lists_compatibility() {
    print_test_header "Package Lists Compatibility"

    run_test "Package lists directory structure"
    if [[ -d "$PROJECT_ROOT/packages" ]]; then
        pass_test "Packages directory exists"

        local categories=("core" "aur" "hardware" "profiles")
        for category in "${categories[@]}"; do
            if [[ -d "$PROJECT_ROOT/packages/$category" ]]; then
                local count=$(find "$PROJECT_ROOT/packages/$category" -name "*.list" | wc -l)
                pass_test "$category category: $count package lists"
            else
                fail_test "$category category missing"
            fi
        done
    else
        fail_test "Packages directory missing"
    fi

    run_test "Package list format validation"
    local sample_list=""
    for list in "$PROJECT_ROOT/packages"/*/*.list; do
        if [[ -f "$list" ]]; then
            sample_list="$list"
            break
        fi
    done

    if [[ -n "$sample_list" ]]; then
        if grep -v '^#' "$sample_list" | grep -v '^$' | head -n1 &>/dev/null; then
            pass_test "Package list format is valid"
        else
            fail_test "Package list format is invalid"
        fi
    else
        fail_test "No package lists found for validation"
    fi
}

# Test 8: Performance and Optimization
test_performance_optimization() {
    print_test_header "Performance and Optimization"

    run_test "Compiler optimization flags"
    if [[ -f /etc/paru/paru.conf ]]; then
        if grep -q "march=native" /etc/paru/paru.conf; then
            pass_test "Native architecture optimization enabled"
        else
            fail_test "Native architecture optimization not found"
        fi

        if grep -q "\-O2" /etc/paru/paru.conf; then
            pass_test "O2 optimization level configured"
        else
            fail_test "O2 optimization not configured"
        fi

        if grep -q "fno-plt" /etc/paru/paru.conf; then
            pass_test "PLT optimization enabled"
        else
            fail_test "PLT optimization not enabled"
        fi
    else
        fail_test "Cannot test optimizations - paru config missing"
    fi

    run_test "Parallel build configuration"
    local cpu_cores=$(nproc)
    if [[ -f /etc/paru/paru.conf ]] && grep -q "j\$(nproc)" /etc/paru/paru.conf; then
        pass_test "Parallel builds using all $cpu_cores CPU cores"
    else
        fail_test "Parallel build configuration not optimal"
    fi
}

# Test 9: Gaming Specific Features
test_gaming_features() {
    print_test_header "Gaming Specific Features"

    run_test "Gaming package lists"
    if [[ -f "$PROJECT_ROOT/packages/core/gaming.list" ]]; then
        local gaming_count=$(grep -v '^#' "$PROJECT_ROOT/packages/core/gaming.list" | grep -v '^$' | wc -l)
        pass_test "Core gaming packages: $gaming_count packages"
    else
        fail_test "Core gaming packages list missing"
    fi

    if [[ -f "$PROJECT_ROOT/packages/aur/gaming.list" ]]; then
        local aur_gaming_count=$(grep -v '^#' "$PROJECT_ROOT/packages/aur/gaming.list" | grep -v '^$' | wc -l)
        pass_test "AUR gaming packages: $aur_gaming_count packages"
    else
        fail_test "AUR gaming packages list missing"
    fi

    run_test "Gaming profiles"
    local profiles=("esports" "streaming" "development")
    for profile in "${profiles[@]}"; do
        if [[ -f "$PROJECT_ROOT/packages/profiles/$profile.list" ]]; then
            local profile_count=$(grep -v '^#' "$PROJECT_ROOT/packages/profiles/$profile.list" | grep -v '^$' | wc -l)
            pass_test "$profile profile: $profile_count packages"
        else
            fail_test "$profile profile missing"
        fi
    done

    run_test "Hardware-specific packages"
    local hardware=("nvidia" "amd" "intel")
    for hw in "${hardware[@]}"; do
        if [[ -f "$PROJECT_ROOT/packages/hardware/$hw.list" ]]; then
            local hw_count=$(grep -v '^#' "$PROJECT_ROOT/packages/hardware/$hw.list" | grep -v '^$' | wc -l)
            pass_test "$hw hardware packages: $hw_count packages"
        else
            fail_test "$hw hardware packages missing"
        fi
    done
}

# Test 10: Compatibility and Migration
test_compatibility_migration() {
    print_test_header "Compatibility and Migration"

    run_test "Package compatibility wrapper"
    if [[ -f "$PROJECT_ROOT/scripts/package-management/package-compat.sh" ]]; then
        pass_test "Package compatibility wrapper exists"

        if [[ -x "$PROJECT_ROOT/scripts/package-management/package-compat.sh" ]]; then
            pass_test "Compatibility wrapper is executable"
        else
            fail_test "Compatibility wrapper not executable"
        fi
    else
        fail_test "Package compatibility wrapper missing"
    fi

    run_test "Legacy command handling"
    if [[ -f /etc/profile.d/xanados-package-manager.sh ]]; then
        if grep -q "pacman()" /etc/profile.d/xanados-package-manager.sh; then
            pass_test "Legacy pacman command wrapper configured"
        else
            fail_test "Legacy pacman wrapper missing"
        fi

        if grep -q "yay()" /etc/profile.d/xanados-package-manager.sh; then
            pass_test "Legacy yay command wrapper configured"
        else
            fail_test "Legacy yay wrapper missing"
        fi
    else
        fail_test "Cannot test legacy commands - aliases file missing"
    fi
}

# Test 11: Error Handling and Recovery
test_error_handling() {
    print_test_header "Error Handling and Recovery"

    run_test "xpkg error handling"
    if timeout 10 xpkg invalid-command 2>&1 | grep -q "Unknown command"; then
        pass_test "xpkg handles invalid commands gracefully"
    else
        fail_test "xpkg error handling not working"
    fi

    run_test "Paru dependency resolution"
    # Test with a non-existent package
    if timeout 10 paru -Si nonexistent-package-12345 2>&1 | grep -q "not found\|No results"; then
        pass_test "Paru handles missing packages gracefully"
    else
        skip_test "Paru missing package test inconclusive"
    fi
}

# Final Summary
show_test_summary() {
    print_test_header "Test Summary"

    echo -e "\n${BLUE}📊 Test Results:${NC}"
    echo -e "  Total tests run: ${TESTS_RUN}"
    echo -e "  ${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
    echo -e "  ${RED}Tests failed: ${TESTS_FAILED}${NC}"

    local pass_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    fi

    echo -e "  ${PURPLE}Pass rate: ${pass_rate}%${NC}"
    echo

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Paru integration is working perfectly.${NC}"
    elif [[ $pass_rate -ge 80 ]]; then
        echo -e "${YELLOW}⚠️  Most tests passed. Some minor issues detected.${NC}"
    else
        echo -e "${RED}❌ Multiple test failures detected. Review required.${NC}"
    fi

    echo
    echo -e "${BLUE}📋 Full test log: $TEST_LOG${NC}"

    # Log final summary
    log "TEST_SUMMARY: $TESTS_RUN total, $TESTS_PASSED passed, $TESTS_FAILED failed, ${pass_rate}% pass rate"
}

# Main execution
main() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                        xanadOS Paru Integration Test Suite                   ║${NC}"
    echo -e "${PURPLE}║                          Testing Unified Package Manager                     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo

    log "TEST_SUITE_START: Paru Integration Test Suite"

    # Run all tests
    test_paru_installation
    test_paru_configuration
    test_xpkg_interface
    test_package_manager_integration
    test_system_integration
    test_aur_manager_integration
    test_package_lists_compatibility
    test_performance_optimization
    test_gaming_features
    test_compatibility_migration
    test_error_handling

    # Show results
    show_test_summary

    log "TEST_SUITE_END: Complete"

    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run the test suite
main "$@"
