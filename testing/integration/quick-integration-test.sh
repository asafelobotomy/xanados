#!/bin/bash
# Quick Integration Test Suite
# Runs essential integration tests for rapid validation

set -euo pipefail

# Change to script directory and source libraries
cd "$(dirname "$0")" || exit 1
source "../../scripts/lib/common.sh"
source "../../scripts/lib/validation.sh"

# Test configuration
TEST_NAME="Quick Integration"
RESULTS_DIR="$(get_results_dir "testing/integration" false)"
TEST_LOG="$RESULTS_DIR/quick-integration-$(date +%Y%m%d-%H%M%S).log"

# Ensure results directory exists
ensure_directory "$RESULTS_DIR"

# Initialize logging
exec 1> >(tee -a "$TEST_LOG")
exec 2> >(tee -a "$TEST_LOG" >&2)

print_header "⚡ Quick Integration Test Suite"
echo ""

# Test execution
print_section "Running Essential Integration Tests"

# Track overall success
OVERALL_SUCCESS=true

# Gaming Integration (Essential)
print_info "🎮 Running essential gaming integration tests..."
if ./test-gaming-integration.sh --quick 2>/dev/null || ./test-gaming-integration.sh 2>/dev/null; then
    print_success "✅ Gaming integration: PASS"
else
    print_error "❌ Gaming integration: FAIL"
    OVERALL_SUCCESS=false
fi

# System Integration (Essential)
print_info "⚙️ Running essential system integration tests..."
if ./test-system-integration.sh --quick 2>/dev/null || ./test-system-integration.sh 2>/dev/null; then
    print_success "✅ System integration: PASS"
else
    print_error "❌ System integration: FAIL"
    OVERALL_SUCCESS=false
fi

# Core Library Tests (Critical)
print_info "📚 Running core library tests..."
if ../../testing/unit/test-shared-libs.sh &>/dev/null; then
    print_success "✅ Core libraries: PASS"
else
    print_error "❌ Core libraries: FAIL"
    OVERALL_SUCCESS=false
fi

# Results summary
print_section "Quick Integration Results"

if [[ "$OVERALL_SUCCESS" == "true" ]]; then
    print_success "⚡ Quick integration test: ALL PASS"
    echo ""
    echo "🎯 System Status: Ready for gaming"
    echo "📊 All essential components validated"
    echo "🚀 xanadOS gaming environment: OPERATIONAL"
    exit 0
else
    print_error "⚡ Quick integration test: SOME FAILURES"
    echo ""
    echo "⚠️ System Status: Issues detected"
    echo "📊 Some components need attention"
    echo "🔧 Review detailed logs for resolution steps"
    exit 1
fi
