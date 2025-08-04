#!/bin/bash
# xanadOS Enhanced Testing Framework
# Comprehensive testing system with coverage and reporting

set -euo pipefail

# Prevent multiple sourcing
[[ "${XANADOS_TESTING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_TESTING_LOADED="true"

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/error-handling.sh"

# Testing configuration
readonly TEST_DIR="${XANADOS_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}/testing"
readonly TEST_RESULTS_DIR="$TEST_DIR/results"
readonly TEST_REPORTS_DIR="$TEST_RESULTS_DIR/reports"
readonly TEST_COVERAGE_DIR="$TEST_RESULTS_DIR/coverage"

# Test framework globals
declare -g TESTS_TOTAL=0
declare -g TESTS_PASSED=0
declare -g TESTS_FAILED=0
declare -g TESTS_SKIPPED=0
declare -g TEST_START_TIME=""
declare -g CURRENT_TEST_SUITE=""

# Test result arrays
declare -ga FAILED_TESTS=()
declare -ga PASSED_TESTS=()
declare -ga SKIPPED_TESTS=()

# ============================================================================
# Enhanced Testing Framework
# ============================================================================

# Initialize testing framework
init_testing_framework() {
    log_info "Initializing enhanced testing framework"

    # Create test directories
    mkdir -p "$TEST_RESULTS_DIR" "$TEST_REPORTS_DIR" "$TEST_COVERAGE_DIR"

    # Reset counters
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0

    # Clear result arrays
    FAILED_TESTS=()
    PASSED_TESTS=()
    SKIPPED_TESTS=()

    # Record start time
    TEST_START_TIME=$(date +%s)

    log_success "Testing framework initialized"
}

# Start a test suite
start_test_suite() {
    local suite_name="$1"
    local description="${2:-$suite_name test suite}"

    CURRENT_TEST_SUITE="$suite_name"

    log_info "Starting test suite: $suite_name"
    echo "🧪 $description"
    echo "==============================="

    # Create suite-specific result file
    local suite_file="$TEST_RESULTS_DIR/${suite_name}-results.json"
    cat > "$suite_file" << EOF
{
  "suite_name": "$suite_name",
  "description": "$description",
  "start_time": "$(date -Iseconds)",
  "tests": []
}
EOF
}

# Run a single test with enhanced reporting
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    local description="${4:-$test_name}"
    local timeout="${5:-30}"

    ((TESTS_TOTAL++))

    log_info "Running test: $test_name"

    local test_start
    test_start=$(date +%s.%N)

    local test_result=0
    local test_output=""
    local test_error=""

    # Run test with timeout and capture output
    if timeout "$timeout" bash -c "$test_command" >/tmp/test_output 2>/tmp/test_error; then
        test_result=0
        test_output=$(cat /tmp/test_output 2>/dev/null || echo "")
        test_error=$(cat /tmp/test_error 2>/dev/null || echo "")
    else
        test_result=$?
        test_output=$(cat /tmp/test_output 2>/dev/null || echo "")
        test_error=$(cat /tmp/test_error 2>/dev/null || echo "")
    fi

    local test_end
    test_end=$(date +%s.%N)
    local test_duration
    test_duration=$(echo "$test_end - $test_start" | bc -l 2>/dev/null || echo "0")

    # Evaluate test result
    local test_status
    if [[ $test_result -eq $expected_result ]]; then
        test_status="PASSED"
        ((TESTS_PASSED++))
        PASSED_TESTS+=("$test_name")
        echo "  ✅ $test_name (${test_duration}s)"
    else
        test_status="FAILED"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        echo "  ❌ $test_name (${test_duration}s)"
        echo "     Expected: $expected_result, Got: $test_result"
        if [[ -n "$test_error" ]]; then
            echo "     Error: $test_error"
        fi
    fi

    # Record test result
    record_test_result "$test_name" "$test_status" "$test_duration" "$test_output" "$test_error" "$description"

    # Cleanup
    rm -f /tmp/test_output /tmp/test_error

    return $test_result
}

# Run test with retry capability
run_test_with_retry() {
    local test_name="$1"
    local test_command="$2"
    local max_attempts="${3:-3}"
    local retry_delay="${4:-2}"

    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Test attempt $attempt/$max_attempts: $test_name"

        if run_test "$test_name" "$test_command"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Test failed, retrying in ${retry_delay}s..."
            sleep "$retry_delay"
        fi

        ((attempt++))
    done

    log_error "Test failed after $max_attempts attempts: $test_name"
    return 1
}

# Skip a test with reason
skip_test() {
    local test_name="$1"
    local reason="${2:-Test skipped}"

    ((TESTS_TOTAL++))
    ((TESTS_SKIPPED++))
    SKIPPED_TESTS+=("$test_name")

    echo "  ⏭️  $test_name (SKIPPED: $reason)"

    # Record skipped test
    record_test_result "$test_name" "SKIPPED" "0" "" "" "$reason"
}

# Record test result to JSON
record_test_result() {
    local test_name="$1"
    local status="$2"
    local duration="$3"
    local output="$4"
    local error="$5"
    local description="$6"

    local suite_file="$TEST_RESULTS_DIR/${CURRENT_TEST_SUITE:-default}-results.json"

    # Create test result entry
    local test_entry
    test_entry=$(cat << EOF
{
  "name": "$test_name",
  "description": "$description",
  "status": "$status",
  "duration": $duration,
  "timestamp": "$(date -Iseconds)",
  "output": "$(echo "$output" | sed 's/"/\\"/g')",
  "error": "$(echo "$error" | sed 's/"/\\"/g')"
}
EOF
    )

    # Append to suite results (simplified approach)
    echo "$test_entry" >> "${suite_file}.tmp"
}

# End test suite and generate report
end_test_suite() {
    local suite_name="${1:-$CURRENT_TEST_SUITE}"

    log_info "Ending test suite: $suite_name"

    # Calculate statistics
    local total_duration
    local current_time
    current_time=$(date +%s)
    total_duration=$((current_time - TEST_START_TIME))

    # Generate suite summary
    echo ""
    echo "📊 Test Suite Summary: $suite_name"
    echo "==============================="
    echo "Total Tests:  $TESTS_TOTAL"
    echo "Passed:       $TESTS_PASSED"
    echo "Failed:       $TESTS_FAILED"
    echo "Skipped:      $TESTS_SKIPPED"
    echo "Duration:     ${total_duration}s"

    local success_rate=0
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        success_rate=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
    fi
    echo "Success Rate: ${success_rate}%"

    # Generate detailed report
    generate_test_report "$suite_name"

    # Return appropriate exit code
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# Generate comprehensive test report
generate_test_report() {
    local suite_name="$1"
    local report_file="$TEST_REPORTS_DIR/${suite_name}-report-$(date +%Y%m%d-%H%M%S).html"

    log_info "Generating test report: $report_file"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>xanadOS Test Report - $suite_name</title>
    <style>
        body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { border-bottom: 3px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #007acc; margin: 0; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; color: #007acc; }
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .skipped { color: #ffc107; }
        .test-list { margin: 20px 0; }
        .test-item { padding: 10px; margin: 5px 0; border-radius: 4px; }
        .test-passed { background: #d4edda; border-left: 4px solid #28a745; }
        .test-failed { background: #f8d7da; border-left: 4px solid #dc3545; }
        .test-skipped { background: #fff3cd; border-left: 4px solid #ffc107; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6; text-align: center; color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 xanadOS Test Report</h1>
            <h2>Suite: $suite_name</h2>
            <p>Generated: $(date)</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-number">$TESTS_TOTAL</div>
                <div>Total Tests</div>
            </div>
            <div class="stat-card">
                <div class="stat-number passed">$TESTS_PASSED</div>
                <div>Passed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number failed">$TESTS_FAILED</div>
                <div>Failed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number skipped">$TESTS_SKIPPED</div>
                <div>Skipped</div>
            </div>
        </div>

        <h3>Test Results</h3>
        <div class="test-list">
EOF

    # Add passed tests
    if [[ ${#PASSED_TESTS[@]} -gt 0 ]]; then
        echo "            <h4>✅ Passed Tests</h4>" >> "$report_file"
        for test in "${PASSED_TESTS[@]}"; do
            echo "            <div class=\"test-item test-passed\">$test</div>" >> "$report_file"
        done
    fi

    # Add failed tests
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo "            <h4>❌ Failed Tests</h4>" >> "$report_file"
        for test in "${FAILED_TESTS[@]}"; do
            echo "            <div class=\"test-item test-failed\">$test</div>" >> "$report_file"
        done
    fi

    # Add skipped tests
    if [[ ${#SKIPPED_TESTS[@]} -gt 0 ]]; then
        echo "            <h4>⏭️ Skipped Tests</h4>" >> "$report_file"
        for test in "${SKIPPED_TESTS[@]}"; do
            echo "            <div class=\"test-item test-skipped\">$test</div>" >> "$report_file"
        done
    fi

    cat >> "$report_file" << EOF
        </div>

        <div class="footer">
            <p>xanadOS Testing Framework v2.0.0</p>
            <p>Report generated: $(date -Iseconds)</p>
        </div>
    </div>
</body>
</html>
EOF

    log_success "Test report generated: $report_file"
}

# Run integration tests
run_integration_tests() {
    log_info "Running xanadOS integration tests"

    start_test_suite "integration" "xanadOS Integration Test Suite"

    # Test core libraries
    run_test "common_library_load" "source '$(dirname "${BASH_SOURCE[0]}")/common.sh'"
    run_test "logging_library_load" "source '$(dirname "${BASH_SOURCE[0]}")/logging.sh'"
    run_test "gaming_env_load" "source '$(dirname "${BASH_SOURCE[0]}")/gaming-env.sh'"

    # Test gaming stack
    if command -v steam >/dev/null 2>&1; then
        run_test "steam_available" "command -v steam"
    else
        skip_test "steam_available" "Steam not installed"
    fi

    if command -v lutris >/dev/null 2>&1; then
        run_test "lutris_available" "command -v lutris"
    else
        skip_test "lutris_available" "Lutris not installed"
    fi

    # Test system optimizations
    run_test "cpu_governor_check" "[[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]"
    run_test "memory_info_available" "[[ -f /proc/meminfo ]]"

    # Test configuration
    run_test "xanados_config_dir" "[[ -d \"\${XDG_CONFIG_HOME:-\$HOME/.config}/xanados\" ]]"

    end_test_suite "integration"
}

# Run performance benchmarks
run_performance_tests() {
    log_info "Running xanadOS performance tests"

    start_test_suite "performance" "xanadOS Performance Test Suite"

    # CPU performance test
    run_test "cpu_benchmark" "timeout 10 yes > /dev/null" 0 "Basic CPU stress test"

    # Memory test
    run_test "memory_test" "timeout 5 dd if=/dev/zero of=/dev/null bs=1M count=100" 0 "Memory bandwidth test"

    # Disk I/O test
    run_test "disk_io_test" "timeout 5 dd if=/dev/zero of=/tmp/test_file bs=1M count=10 && rm -f /tmp/test_file" 0 "Disk I/O test"

    end_test_suite "performance"
}

# Export functions
export -f init_testing_framework
export -f start_test_suite
export -f run_test
export -f run_test_with_retry
export -f skip_test
export -f end_test_suite
export -f run_integration_tests
export -f run_performance_tests

log_debug "Enhanced testing framework loaded"
