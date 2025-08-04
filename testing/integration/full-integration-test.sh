#!/bin/bash
# Full Integration Test Suite
# Comprehensive end-to-end testing of all xanadOS components

set -euo pipefail

# Change to script directory and source libraries
cd "$(dirname "$0")" || exit 1
source "../../scripts/lib/common.sh"
source "../../scripts/lib/validation.sh"

# Test configuration
TEST_NAME="Full Integration"
RESULTS_DIR="$(get_results_dir "testing/integration" false)"
TEST_LOG="$RESULTS_DIR/full-integration-$(date +%Y%m%d-%H%M%S).log"

# Ensure results directory exists
ensure_directory "$RESULTS_DIR"

# Initialize logging
exec 1> >(tee -a "$TEST_LOG")
exec 2> >(tee -a "$TEST_LOG" >&2)

print_header "🔬 Full Integration Test Suite"
echo ""

# Test counters
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Test execution function
run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    local description="$3"

    ((TOTAL_SUITES++))

    print_section "$suite_name"
    print_info "$description"
    echo ""

    if [[ -x "$suite_script" ]] && "$suite_script"; then
        print_success "✅ $suite_name: PASSED"
        ((PASSED_SUITES++))
        echo ""
        return 0
    else
        print_error "❌ $suite_name: FAILED"
        ((FAILED_SUITES++))
        echo ""
        return 1
    fi
}

# Start comprehensive testing
print_info "🚀 Starting comprehensive integration testing..."
echo ""

# Core System Tests
run_test_suite \
    "Core Library Tests" \
    "../../testing/unit/test-shared-libs.sh" \
    "Testing shared library functionality and dependencies"

run_test_suite \
    "System Integration Tests" \
    "./test-system-integration.sh" \
    "Testing kernel optimizations, drivers, and system performance"

run_test_suite \
    "Gaming Integration Tests" \
    "./test-gaming-integration.sh" \
    "Testing gaming environment, Steam, Lutris, and gaming tools"

# Extended Integration Tests
if [[ -x "./test-package-integration.sh" ]]; then
    run_test_suite \
        "Package Integration Tests" \
        "./test-package-integration.sh" \
        "Testing AUR integration, package management, and dependencies"
fi

if [[ -x "./test-build-integration.sh" ]]; then
    run_test_suite \
        "Build Integration Tests" \
        "./test-build-integration.sh" \
        "Testing ISO creation, build system, and release automation"
fi

# Performance and Validation Tests
if [[ -x "../../testing/automated/performance-benchmark.sh" ]]; then
    print_section "Performance Validation"
    print_info "Running performance benchmarks for validation..."
    echo ""

    if ../../testing/automated/performance-benchmark.sh --non-interactive &>/dev/null; then
        print_success "✅ Performance benchmarks: PASSED"
        ((PASSED_SUITES++))
    else
        print_error "❌ Performance benchmarks: FAILED"
        ((FAILED_SUITES++))
    fi
    ((TOTAL_SUITES++))
    echo ""
fi

# System Validation Tests
if [[ -x "../../scripts/testing/run-full-system-test.sh" ]]; then
    run_test_suite \
        "Full System Validation" \
        "../../scripts/testing/run-full-system-test.sh" \
        "Comprehensive system validation and component testing"
fi

# Generate comprehensive report
print_section "Integration Test Report"

pass_rate=0
if [[ $TOTAL_SUITES -gt 0 ]]; then
    pass_rate=$((PASSED_SUITES * 100 / TOTAL_SUITES))
fi

echo "📊 Full Integration Test Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Total Test Suites: $TOTAL_SUITES"
echo "   Passed Suites: $PASSED_SUITES"
echo "   Failed Suites: $FAILED_SUITES"
echo "   Success Rate: ${pass_rate}%"
echo ""

# System status assessment
if [[ $FAILED_SUITES -eq 0 ]]; then
    print_success "🎉 EXCELLENT: All integration tests passed!"
    echo ""
    echo "🎯 xanadOS Status: FULLY OPERATIONAL"
    echo "🎮 Gaming Environment: OPTIMIZED"
    echo "⚙️ System Integration: COMPLETE"
    echo "📊 Performance: VALIDATED"
    echo "🚀 Ready for gaming workloads"

elif [[ $pass_rate -ge 80 ]]; then
    print_info "✅ GOOD: Most integration tests passed"
    echo ""
    echo "🎯 xanadOS Status: MOSTLY OPERATIONAL"
    echo "⚠️ Minor Issues: $FAILED_SUITES component(s) need attention"
    echo "🔧 Review failed test logs for optimization opportunities"

elif [[ $pass_rate -ge 60 ]]; then
    print_warning "⚠️ FAIR: Some integration issues detected"
    echo ""
    echo "🎯 xanadOS Status: PARTIALLY OPERATIONAL"
    echo "🔧 Moderate Issues: $FAILED_SUITES component(s) need resolution"
    echo "📋 System may function but with reduced performance"

else
    print_error "❌ POOR: Significant integration issues"
    echo ""
    echo "🎯 xanadOS Status: NEEDS ATTENTION"
    echo "🚨 Major Issues: $FAILED_SUITES component(s) require immediate attention"
    echo "⚠️ Gaming performance may be severely impacted"
fi

echo ""
echo "📄 Detailed results: $TEST_LOG"
echo "📊 Integration testing completed at $(date)"

# Return appropriate exit code
if [[ $FAILED_SUITES -eq 0 ]]; then
    exit 0
elif [[ $pass_rate -ge 60 ]]; then
    exit 1
else
    exit 2
fi
