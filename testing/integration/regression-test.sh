#!/bin/bash
# Regression Test Suite
# Detects performance and functionality regressions

set -euo pipefail

# Change to script directory and source libraries
cd "$(dirname "$0")" || exit 1
source "../../scripts/lib/common.sh"
source "../../scripts/lib/validation.sh"
source "../../scripts/lib/reports.sh"

# Test configuration
TEST_NAME="Regression Tests"
RESULTS_DIR="$(get_results_dir "testing/regression" false)"
TEST_LOG="$RESULTS_DIR/regression-$(date +%Y%m%d-%H%M%S).log"
BASELINE_DIR="$RESULTS_DIR/baseline"
CURRENT_DIR="$RESULTS_DIR/current"

# Ensure directories exist
ensure_directory "$RESULTS_DIR"
ensure_directory "$BASELINE_DIR"
ensure_directory "$CURRENT_DIR"

# Initialize logging
exec 1> >(tee -a "$TEST_LOG")
exec 2> >(tee -a "$TEST_LOG" >&2)

print_header "📈 Regression Test Suite"
echo ""

# Configuration
REGRESSION_THRESHOLD=10  # 10% performance degradation threshold
BASELINE_FILE="$BASELINE_DIR/performance-baseline.json"
CURRENT_FILE="$CURRENT_DIR/performance-current.json"

# Test execution functions
create_baseline() {
    print_section "Creating Performance Baseline"

    print_info "🎯 Running baseline performance tests..."

    # Run performance benchmarks
    if [[ -x "../../testing/automated/performance-benchmark.sh" ]]; then
        print_info "📊 Executing performance benchmarks..."
        ../../testing/automated/performance-benchmark.sh --json-output "$CURRENT_FILE" &>/dev/null || true

        if [[ -f "$CURRENT_FILE" ]]; then
            cp "$CURRENT_FILE" "$BASELINE_FILE"
            print_success "✅ Baseline created: $BASELINE_FILE"
        else
            print_error "❌ Failed to create performance baseline"
            return 1
        fi
    else
        print_warning "⚠️ Performance benchmark script not found"
        return 1
    fi

    # Run integration tests for functional baseline
    print_info "🔧 Creating functional baseline..."
    ./full-integration-test.sh > "$BASELINE_DIR/integration-baseline.log" 2>&1 || true

    print_success "📊 Regression test baseline created"
    return 0
}

run_regression_tests() {
    print_section "Running Regression Tests"

    if [[ ! -f "$BASELINE_FILE" ]]; then
        print_warning "⚠️ No baseline found. Creating baseline first..."
        create_baseline
        return 0
    fi

    print_info "📊 Running current performance tests..."

    # Run current performance tests
    if [[ -x "../../testing/automated/performance-benchmark.sh" ]]; then
        ../../testing/automated/performance-benchmark.sh --json-output "$CURRENT_FILE" &>/dev/null || true
    fi

    # Run current integration tests
    print_info "🔧 Running current integration tests..."
    ./full-integration-test.sh > "$CURRENT_DIR/integration-current.log" 2>&1 || true

    # Compare results
    compare_results
}

compare_results() {
    print_section "Regression Analysis"

    local regressions_found=false
    local performance_regressions=0
    local functional_regressions=0

    # Performance regression analysis
    if [[ -f "$BASELINE_FILE" ]] && [[ -f "$CURRENT_FILE" ]]; then
        print_info "📊 Analyzing performance regressions..."

        # Simple JSON comparison (would need jq for complex analysis)
        if command -v jq &>/dev/null; then
            # Extract key performance metrics and compare
            local baseline_cpu baseline_memory baseline_io
            local current_cpu current_memory current_io

            baseline_cpu=$(jq -r '.cpu.score // 0' "$BASELINE_FILE" 2>/dev/null || echo "0")
            current_cpu=$(jq -r '.cpu.score // 0' "$CURRENT_FILE" 2>/dev/null || echo "0")

            baseline_memory=$(jq -r '.memory.score // 0' "$BASELINE_FILE" 2>/dev/null || echo "0")
            current_memory=$(jq -r '.memory.score // 0' "$CURRENT_FILE" 2>/dev/null || echo "0")

            # Check for significant performance degradation
            if [[ "$baseline_cpu" != "0" ]] && [[ "$current_cpu" != "0" ]]; then
                local cpu_change=$(( (current_cpu - baseline_cpu) * 100 / baseline_cpu ))
                if [[ $cpu_change -lt -$REGRESSION_THRESHOLD ]]; then
                    print_error "❌ CPU Performance Regression: ${cpu_change}% degradation"
                    regressions_found=true
                    ((performance_regressions++))
                else
                    print_success "✅ CPU Performance: Stable (${cpu_change}% change)"
                fi
            fi

            if [[ "$baseline_memory" != "0" ]] && [[ "$current_memory" != "0" ]]; then
                local memory_change=$(( (current_memory - baseline_memory) * 100 / baseline_memory ))
                if [[ $memory_change -lt -$REGRESSION_THRESHOLD ]]; then
                    print_error "❌ Memory Performance Regression: ${memory_change}% degradation"
                    regressions_found=true
                    ((performance_regressions++))
                else
                    print_success "✅ Memory Performance: Stable (${memory_change}% change)"
                fi
            fi
        else
            print_warning "⚠️ jq not available for detailed performance analysis"
        fi
    else
        print_warning "⚠️ Performance data incomplete for comparison"
    fi

    # Functional regression analysis
    print_info "🔧 Analyzing functional regressions..."

    if [[ -f "$BASELINE_DIR/integration-baseline.log" ]] && [[ -f "$CURRENT_DIR/integration-current.log" ]]; then
        local baseline_passes baseline_failures
        local current_passes current_failures

        baseline_passes=$(grep -c "PASS" "$BASELINE_DIR/integration-baseline.log" 2>/dev/null || echo "0")
        baseline_failures=$(grep -c "FAIL" "$BASELINE_DIR/integration-baseline.log" 2>/dev/null || echo "0")

        current_passes=$(grep -c "PASS" "$CURRENT_DIR/integration-current.log" 2>/dev/null || echo "0")
        current_failures=$(grep -c "FAIL" "$CURRENT_DIR/integration-current.log" 2>/dev/null || echo "0")

        if [[ $current_failures -gt $baseline_failures ]]; then
            local regression_count=$((current_failures - baseline_failures))
            print_error "❌ Functional Regression: $regression_count additional test failure(s)"
            regressions_found=true
            functional_regressions=$regression_count
        else
            print_success "✅ Functional Tests: No regressions detected"
        fi
    fi

    # Generate regression report
    print_section "Regression Test Summary"

    echo "📊 Regression Analysis Results:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Performance Regressions: $performance_regressions"
    echo "   Functional Regressions: $functional_regressions"
    echo "   Regression Threshold: ${REGRESSION_THRESHOLD}%"
    echo ""

    if [[ "$regressions_found" == "false" ]]; then
        print_success "🎉 No regressions detected!"
        echo "✅ System performance and functionality stable"
        return 0
    else
        print_error "⚠️ Regressions detected!"
        echo "🔧 Review changes and optimize before release"
        return 1
    fi
}

# Parse command line arguments
case "${1:-run}" in
    "baseline"|"create-baseline")
        create_baseline
        ;;
    "run"|"test")
        run_regression_tests
        ;;
    "compare"|"analysis")
        compare_results
        ;;
    "help"|"--help")
        echo "Usage: $0 [baseline|run|compare|help]"
        echo ""
        echo "Commands:"
        echo "  baseline    Create performance and functional baseline"
        echo "  run         Run regression tests against baseline"
        echo "  compare     Compare existing results for regression analysis"
        echo "  help        Show this help message"
        exit 0
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
