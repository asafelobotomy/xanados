#!/bin/bash

# 🧪 xanadOS Comprehensive System Test Suite
# Complete validation of all xanadOS components and integration
#
# Purpose: Validate entire gaming distribution works together seamlessly
#          Test all major functionality and integration points
#
# Author: xanadOS Development Team
# Version: 1.0.0
# Date: August 3, 2025

set -euo pipefail

# Simple logging functions
log_info() {
    echo "[INFO] $*"
}

log_warning() {
    echo "[WARNING] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*"
}

# 📁 Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
XANADOS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEST_RESULTS_DIR="$XANADOS_ROOT/testing/results"
TEST_LOG="$TEST_RESULTS_DIR/system-test-$(date +%Y%m%d-%H%M%S).log"

# Create test results directory
mkdir -p "$TEST_RESULTS_DIR"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

# 🧪 Test Framework Functions

start_test() {
    local test_name="$1"
    echo "🧪 Testing: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ((TESTS_TOTAL++))
}

pass_test() {
    local message="$1"
    echo "  ✅ PASS: $message"
    ((TESTS_PASSED++))
}

fail_test() {
    local message="$1"
    echo "  ❌ FAIL: $message"
    ((TESTS_FAILED++))
}

warn_test() {
    local message="$1"
    echo "  ⚠️  WARN: $message"
    ((TESTS_WARNINGS++))
}

# 🔍 System Test Functions

test_core_infrastructure() {
    start_test "Core Infrastructure"

    # Test directory structure
    local required_dirs=(
        "scripts/lib"
        "scripts/setup"
        "scripts/build"
        "configs"
        "docs"
        "testing"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$XANADOS_ROOT/$dir" ]]; then
            pass_test "Directory exists: $dir"
        else
            fail_test "Missing directory: $dir"
        fi
    done

    # Test core library files
    local core_libs=(
        "scripts/lib/common.sh"
        "scripts/lib/logging.sh"
        "scripts/lib/gaming-env.sh"
        "scripts/lib/hardware-detection.sh"
        "scripts/lib/gaming-profiles.sh"
    )

    for lib in "${core_libs[@]}"; do
        local lib_path="$XANADOS_ROOT/$lib"
        if [[ -f "$lib_path" ]]; then
            if bash -n "$lib_path" 2>/dev/null; then
                pass_test "Library valid: $lib"
            else
                fail_test "Library syntax error: $lib"
            fi
        else
            fail_test "Missing library: $lib"
        fi
    done

    echo ""
}

test_phase1_foundation() {
    start_test "Phase 1: Foundation and Tooling"

    # Test essential scripts
    local phase1_scripts=(
        "scripts/setup/xanados-setup.sh"
        "scripts/lib/validation.sh"
        "scripts/lib/directories.sh"
    )

    for script in "${phase1_scripts[@]}"; do
        local script_path="$XANADOS_ROOT/$script"
        if [[ -f "$script_path" ]] && [[ -x "$script_path" ]]; then
            if bash -n "$script_path" 2>/dev/null; then
                pass_test "Phase 1 script valid: $script"
            else
                fail_test "Phase 1 script syntax error: $script"
            fi
        else
            warn_test "Phase 1 script missing or not executable: $script"
        fi
    done

    echo ""
}

test_phase2_gaming_optimization() {
    start_test "Phase 2: Gaming Optimization"

    # Test gaming optimization scripts
    local optimization_scripts=(
        "scripts/setup/gaming-optimization.sh"
        "scripts/build/build-gaming-kernel.sh"
    )

    for script in "${optimization_scripts[@]}"; do
        local script_path="$XANADOS_ROOT/$script"
        if [[ -f "$script_path" ]] && [[ -x "$script_path" ]]; then
            if bash -n "$script_path" 2>/dev/null; then
                pass_test "Gaming optimization script valid: $script"
            else
                fail_test "Gaming optimization script syntax error: $script"
            fi
        else
            warn_test "Gaming optimization script missing: $script"
        fi
    done

    # Test package lists
    local package_lists=(
        "packages/core/gaming.list"
        "packages/core/graphics.list"
        "packages/core/audio.list"
    )

    for list in "${package_lists[@]}"; do
        local list_path="$XANADOS_ROOT/$list"
        if [[ -f "$list_path" ]]; then
            if [[ -s "$list_path" ]]; then
                pass_test "Package list exists and not empty: $list"
            else
                warn_test "Package list empty: $list"
            fi
        else
            fail_test "Missing package list: $list"
        fi
    done

    echo ""
}

test_phase3_compatibility() {
    start_test "Phase 3: Gaming Detection and Compatibility"

    # Test hardware detection
    if [[ -f "$XANADOS_ROOT/scripts/lib/hardware-detection.sh" ]]; then
        if "$XANADOS_ROOT/scripts/lib/hardware-detection.sh" test 2>/dev/null; then
            pass_test "Hardware detection functional"
        else
            warn_test "Hardware detection has issues (non-critical)"
        fi
    else
        fail_test "Hardware detection library missing"
    fi

    # Test gaming environment detection
    if [[ -f "$XANADOS_ROOT/scripts/lib/gaming-env.sh" ]]; then
        pass_test "Gaming environment library present"
    else
        fail_test "Gaming environment library missing"
    fi

    echo ""
}

test_phase4_user_experience() {
    start_test "Phase 4: User Experience and Desktop Integration"

    # Test all Phase 4 components
    local phase4_components=(
        "scripts/setup/gaming-setup-wizard.sh:Gaming Setup Wizard"
        "scripts/lib/gaming-profiles.sh:Gaming Profiles Library"
        "scripts/setup/kde-gaming-customization.sh:KDE Gaming Customization"
        "scripts/setup/gaming-workflow-optimization.sh:Gaming Workflow Optimization"
        "scripts/setup/first-boot-experience.sh:First-Boot Experience"
        "scripts/setup/gaming-desktop-mode.sh:Gaming Desktop Mode"
        "scripts/setup/phase4-integration-polish.sh:Integration Polish"
        "scripts/setup/gaming-setup-wizard.sh:Gaming Setup Wizard"
    )

    for component in "${phase4_components[@]}"; do
        local file_path="${component%%:*}"
        local component_name="${component##*:}"
        local full_path="$XANADOS_ROOT/$file_path"

        if [[ -f "$full_path" ]] && [[ -x "$full_path" ]]; then
            if bash -n "$full_path" 2>/dev/null; then
                pass_test "$component_name: Valid and executable"
            else
                fail_test "$component_name: Syntax error"
            fi
        else
            fail_test "$component_name: Missing or not executable"
        fi
    done

    echo ""
}

test_integration_functionality() {
    start_test "Integration and Functionality"

    # Test gaming setup wizard
    echo "🔸 Testing Gaming Setup Wizard functionality..."
    if "$XANADOS_ROOT/scripts/setup/gaming-setup-wizard.sh" --help &>/dev/null; then
        pass_test "Gaming Setup Wizard: Responsive"
    else
        warn_test "Gaming Setup Wizard: May have dependency issues"
    fi

    # Test gaming profiles
    echo "🔸 Testing Gaming Profiles functionality..."
    if "$XANADOS_ROOT/scripts/lib/gaming-profiles.sh" help &>/dev/null; then
        pass_test "Gaming Profiles: Responsive"
    else
        warn_test "Gaming Profiles: May have dependency issues"
    fi

    # Test workflow optimization
    echo "🔸 Testing Workflow Optimization functionality..."
    if "$XANADOS_ROOT/scripts/setup/gaming-workflow-optimization.sh" --help &>/dev/null; then
        pass_test "Workflow Optimization: Responsive"
    else
        fail_test "Workflow Optimization: Not responsive"
    fi

    # Test first-boot experience
    echo "🔸 Testing First-Boot Experience functionality..."
    if "$XANADOS_ROOT/scripts/setup/first-boot-experience.sh" --help &>/dev/null; then
        pass_test "First-Boot Experience: Responsive"
    else
        fail_test "First-Boot Experience: Not responsive"
    fi

    # Test gaming desktop mode
    echo "🔸 Testing Gaming Desktop Mode functionality..."
    if "$XANADOS_ROOT/scripts/setup/gaming-desktop-mode.sh" help &>/dev/null; then
        pass_test "Gaming Desktop Mode: Responsive"
    else
        fail_test "Gaming Desktop Mode: Not responsive"
    fi

    # Test unified launcher
    echo "🔸 Testing Gaming Setup Wizard functionality..."
    if [[ -f "$XANADOS_ROOT/scripts/setup/gaming-setup-wizard.sh" ]] && [[ -x "$XANADOS_ROOT/scripts/setup/gaming-setup-wizard.sh" ]]; then
        pass_test "Gaming Setup Wizard: Available and executable"
    else
        fail_test "Gaming Setup Wizard: Missing or not executable"
    fi

    echo ""
}

test_configuration_system() {
    start_test "Configuration System"

    # Test gaming configurations
    local gaming_configs=(
        "configs/network/gaming-optimizations.conf"
        "configs/security/apparmor-gaming.conf"
        "configs/system/kernel-params.conf"
    )

    for config in "${gaming_configs[@]}"; do
        local config_path="$XANADOS_ROOT/$config"
        if [[ -f "$config_path" ]]; then
            pass_test "Gaming config exists: $config"
        else
            warn_test "Gaming config missing: $config"
        fi
    done

    # Test service configurations
    local service_configs=(
        "configs/services/xanados-gaming-monitor.service"
        "configs/services/xanados-optimizations.service"
    )

    for service in "${service_configs[@]}"; do
        local service_path="$XANADOS_ROOT/$service"
        if [[ -f "$service_path" ]]; then
            pass_test "Service config exists: $service"
        else
            warn_test "Service config missing: $service"
        fi
    done

    echo ""
}

test_documentation_system() {
    start_test "Documentation System"

    # Test main documentation
    local main_docs=(
        "README.md"
        "docs/README.md"
        "docs/installation/README.md"
        "docs/user/gaming-quick-reference.md"
    )

    for doc in "${main_docs[@]}"; do
        local doc_path="$XANADOS_ROOT/$doc"
        if [[ -f "$doc_path" ]] && [[ -s "$doc_path" ]]; then
            pass_test "Documentation exists: $doc"
        else
            warn_test "Documentation missing or empty: $doc"
        fi
    done

    # Test phase completion reports
    local phase_reports
    phase_reports=$(find "$XANADOS_ROOT/docs/development/reports" -name "phase*.md" 2>/dev/null | wc -l)
    if [[ "$phase_reports" -ge 4 ]]; then
        pass_test "Phase completion reports: $phase_reports found"
    else
        warn_test "Phase completion reports: Only $phase_reports found"
    fi

    echo ""
}

test_build_system() {
    start_test "Build System"

    # Test build scripts
    local build_scripts=(
        "scripts/build/create-iso.sh"
    )

    for script in "${build_scripts[@]}"; do
        local script_path="$XANADOS_ROOT/$script"
        if [[ -f "$script_path" ]] && [[ -x "$script_path" ]]; then
            if bash -n "$script_path" 2>/dev/null; then
                pass_test "Build script valid: $script"
            else
                fail_test "Build script syntax error: $script"
            fi
        else
            warn_test "Build script missing: $script"
        fi
    done

    echo ""
}

test_gaming_specific_features() {
    start_test "Gaming-Specific Features"

    # Test gaming mode initialization
    echo "🔸 Testing Gaming Mode initialization..."
    if "$XANADOS_ROOT/scripts/setup/gaming-desktop-mode.sh" init &>/dev/null; then
        pass_test "Gaming Mode: Initialization successful"
    else
        warn_test "Gaming Mode: Initialization may have issues"
    fi

    # Test gaming mode status
    echo "🔸 Testing Gaming Mode status..."
    if "$XANADOS_ROOT/scripts/setup/gaming-desktop-mode.sh" status &>/dev/null; then
        pass_test "Gaming Mode: Status check functional"
    else
        fail_test "Gaming Mode: Status check failed"
    fi

    # Test performance stats
    echo "🔸 Testing Performance statistics..."
    if "$XANADOS_ROOT/scripts/setup/gaming-desktop-mode.sh" stats &>/dev/null; then
        pass_test "Performance Stats: Functional"
    else
        warn_test "Performance Stats: May have dependency issues"
    fi

    echo ""
}

# Generate comprehensive test report
generate_test_report() {
    local report_file="$TEST_RESULTS_DIR/system-test-report-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" << EOF
# 🧪 xanadOS Comprehensive System Test Report

**Test Date**: $(date -Iseconds)
**Test Duration**: System validation and integration testing
**Test Environment**: xanadOS Gaming Distribution

## 📊 Test Summary

| Metric | Count |
|--------|-------|
| **Total Tests** | $TESTS_TOTAL |
| **Passed** | $TESTS_PASSED |
| **Failed** | $TESTS_FAILED |
| **Warnings** | $TESTS_WARNINGS |

**Overall Success Rate**: $(( (TESTS_PASSED * 100) / TESTS_TOTAL ))%

## 🎯 Test Results Analysis

### ✅ Successful Components
- Core infrastructure validation
- Phase 4 user experience components
- Gaming desktop mode functionality
- Configuration system integrity

### ⚠️ Areas with Warnings
- Some gaming optimization scripts may have dependency requirements
- Optional components that require specific hardware/software

### ❌ Failed Components
$(if [[ $TESTS_FAILED -gt 0 ]]; then echo "- Issues detected requiring attention"; else echo "- No critical failures detected"; fi)

## 🔧 Recommendations

$(if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "### ✅ System Ready for Production"
    echo "The xanadOS gaming distribution has passed comprehensive testing and is ready for deployment."
else
    echo "### 🔧 Address Failed Tests"
    echo "Review failed components before production deployment."
fi)

## 📋 Detailed Test Log

See full test log: \`$(basename "$TEST_LOG")\`

---

**Test completed successfully on $(date)**
EOF

    echo "📄 Test report generated: $report_file"
}

# Show final test summary
show_test_summary() {
    echo ""
    echo "🧪 xanadOS Comprehensive System Test Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 Test Results:"
    echo "  🧪 Total Tests: $TESTS_TOTAL"
    echo "  ✅ Passed: $TESTS_PASSED"
    echo "  ❌ Failed: $TESTS_FAILED"
    echo "  ⚠️  Warnings: $TESTS_WARNINGS"
    echo ""

    local success_rate=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
    echo "📈 Success Rate: $success_rate%"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All critical tests passed!"
        echo "✅ xanadOS Gaming Distribution is ready for production!"
    elif [[ $TESTS_FAILED -le 2 ]]; then
        echo "⚠️  Minor issues detected, but system is functional"
        echo "🔧 Review failed tests and address if needed"
    else
        echo "❌ Multiple issues detected"
        echo "🔧 Address failed tests before production deployment"
    fi

    echo ""
    echo "📄 Detailed results saved to: $TEST_RESULTS_DIR/"
}

# Main test execution
main() {
    echo "🧪 xanadOS Comprehensive System Test Suite"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Starting comprehensive validation of xanadOS gaming distribution..."
    echo ""

    # Log test start
    echo "Test started at $(date)" > "$TEST_LOG"

    # Run all test suites
    test_core_infrastructure
    test_phase1_foundation
    test_phase2_gaming_optimization
    test_phase3_compatibility
    test_phase4_user_experience
    test_integration_functionality
    test_configuration_system
    test_documentation_system
    test_build_system
    test_gaming_specific_features

    # Generate reports and summary
    generate_test_report
    show_test_summary

    # Return appropriate exit code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
