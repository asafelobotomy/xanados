#!/bin/bash
# Continuous Integration Test Runner
# Automated testing for CI/CD pipelines

set -euo pipefail

# Change to script directory and source libraries
cd "$(dirname "$0")" || exit 1
source "../../scripts/lib/common.sh"
source "../../scripts/lib/validation.sh"

# Test configuration
TEST_NAME="CI Integration"
RESULTS_DIR="$(get_results_dir "testing/integration" false)"
TEST_LOG="$RESULTS_DIR/ci-integration-$(date +%Y%m%d-%H%M%S).log"

# Ensure results directory exists
ensure_directory "$RESULTS_DIR"

# Initialize logging
exec 1> >(tee -a "$TEST_LOG")
exec 2> >(tee -a "$TEST_LOG" >&2)

print_header "🔄 Continuous Integration Test Runner"
echo ""

# Parse command line arguments
CI_MODE="${1:-standard}"
QUICK_MODE=false
VERBOSE_MODE=false

case "$CI_MODE" in
    "quick"|"fast")
        QUICK_MODE=true
        print_info "🚀 Running in quick mode for rapid CI feedback"
        ;;
    "full"|"complete")
        print_info "🔬 Running comprehensive CI test suite"
        ;;
    "standard"|*)
        print_info "⚙️ Running standard CI test suite"
        ;;
esac

echo ""

# Test execution for CI environments
OVERALL_SUCCESS=true
CRITICAL_FAILURES=0
WARNING_FAILURES=0

# Critical Tests (Must Pass)
print_section "Critical Tests (CI Required)"

print_info "📚 Testing core libraries..."
if ../../testing/unit/test-shared-libs.sh &>/dev/null; then
    print_success "✅ Core libraries: PASS"
else
    print_error "❌ Core libraries: CRITICAL FAILURE"
    OVERALL_SUCCESS=false
    ((CRITICAL_FAILURES++))
fi

print_info "🔧 Testing basic functionality..."
if ../../testing/unit/test-library-functionality.sh &>/dev/null; then
    print_success "✅ Library functionality: PASS"
else
    print_error "❌ Library functionality: CRITICAL FAILURE"
    OVERALL_SUCCESS=false
    ((CRITICAL_FAILURES++))
fi

# Standard Tests (Should Pass)
if [[ "$QUICK_MODE" != "true" ]]; then
    print_section "Standard Tests (CI Recommended)"

    print_info "⚙️ Testing system integration..."
    if ./test-system-integration.sh &>/dev/null; then
        print_success "✅ System integration: PASS"
    else
        print_warning "⚠️ System integration: WARNING"
        ((WARNING_FAILURES++))
    fi

    print_info "🎮 Testing gaming integration..."
    if ./test-gaming-integration.sh &>/dev/null; then
        print_success "✅ Gaming integration: PASS"
    else
        print_warning "⚠️ Gaming integration: WARNING"
        ((WARNING_FAILURES++))
    fi
fi

# Extended Tests (Full Mode Only)
if [[ "$CI_MODE" == "full" ]] || [[ "$CI_MODE" == "complete" ]]; then
    print_section "Extended Tests (Full CI)"

    if [[ -x "../../scripts/testing/run-full-system-test.sh" ]]; then
        print_info "🧪 Running full system validation..."
        if ../../scripts/testing/run-full-system-test.sh &>/dev/null; then
            print_success "✅ Full system validation: PASS"
        else
            print_warning "⚠️ Full system validation: WARNING"
            ((WARNING_FAILURES++))
        fi
    fi

    if [[ -x "../../testing/automated/performance-benchmark.sh" ]]; then
        print_info "📊 Running performance validation..."
        if timeout 300 ../../testing/automated/performance-benchmark.sh --non-interactive &>/dev/null; then
            print_success "✅ Performance validation: PASS"
        else
            print_warning "⚠️ Performance validation: WARNING (timeout or failure)"
            ((WARNING_FAILURES++))
        fi
    fi
fi

# Generate CI report
print_section "CI Test Results"

echo "📊 CI Integration Results Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Critical Failures: $CRITICAL_FAILURES"
echo "   Warning Failures: $WARNING_FAILURES"
echo "   Overall Status: $(if [[ "$OVERALL_SUCCESS" == "true" ]]; then echo "PASS"; else echo "FAIL"; fi)"
echo ""

# Determine CI exit status
if [[ "$OVERALL_SUCCESS" == "true" ]]; then
    if [[ $WARNING_FAILURES -eq 0 ]]; then
        print_success "🎉 CI PASS: All tests successful"
        echo "✅ Build can proceed to next stage"
        CI_EXIT_CODE=0
    else
        print_info "⚠️ CI PASS WITH WARNINGS: Critical tests passed"
        echo "✅ Build can proceed with warnings"
        echo "📋 $WARNING_FAILURES non-critical test(s) failed"
        CI_EXIT_CODE=0
    fi
else
    print_error "❌ CI FAIL: Critical tests failed"
    echo "🚫 Build should not proceed"
    echo "🔧 $CRITICAL_FAILURES critical failure(s) must be resolved"
    CI_EXIT_CODE=1
fi

echo ""
echo "📄 CI test log: $TEST_LOG"
echo "🕐 CI testing completed at $(date)"

# Generate CI-friendly output for parsing
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]; then
    echo ""
    echo "::group::CI Test Summary"
    echo "CRITICAL_FAILURES=$CRITICAL_FAILURES"
    echo "WARNING_FAILURES=$WARNING_FAILURES"
    echo "OVERALL_SUCCESS=$OVERALL_SUCCESS"
    echo "CI_EXIT_CODE=$CI_EXIT_CODE"
    echo "::endgroup::"
fi

exit $CI_EXIT_CODE
