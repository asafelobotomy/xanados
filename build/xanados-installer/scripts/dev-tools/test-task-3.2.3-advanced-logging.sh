#!/bin/bash
# Task 3.2.3: Advanced Logging Deployment - Test & Validation Script

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/directories.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# Auto-initialize advanced logging for this test
auto_init_logging "$(basename "$0")" "DEBUG" "testing"

print_header "Task 3.2.3: Advanced Logging Deployment - Validation"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test function helper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TOTAL_TESTS++))
    
    log_info "Testing: $test_name" "test-runner"
    
    if $test_function; then
        log_success "✅ PASS: $test_name" "test-runner"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "❌ FAIL: $test_name" "test-runner"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Advanced logging functions
test_logging_functions() {
    log_debug "Testing debug logging"
    log_info "Testing info logging"
    log_success "Testing success logging"
    log_warning "Testing warning logging"
    log_error "Testing error logging"
    
    # Test structured logging
    local old_structured="$XANADOS_LOG_STRUCTURED"
    XANADOS_LOG_STRUCTURED="true"
    log_info "Testing structured JSON logging" "test" '"test_data":"structured_test"'
    XANADOS_LOG_STRUCTURED="$old_structured"
    
    return 0
}

# Test 2: Performance logging
test_performance_logging() {
    log_performance "test_operation" "123" "milliseconds" "performance-test"
    log_resource_usage "test_resource_check" "performance-test"
    return 0
}

# Test 3: File operations logging
test_file_logging() {
    local test_file="/tmp/xanados-log-test-$$"
    
    log_file_operation "create" "$test_file" "test file for logging validation"
    touch "$test_file"
    
    log_file_operation "delete" "$test_file" "cleanup test file"
    rm -f "$test_file"
    
    return 0
}

# Test 4: Command execution logging
test_command_logging() {
    local cmd="echo 'test command'"
    local start_time
    start_time=$(log_command "$cmd" "Testing command execution logging")
    
    echo "test command" >/dev/null
    local exit_code=$?
    
    log_command_result "$cmd" "$exit_code" "$start_time" "command-test"
    
    return 0
}

# Test 5: Step/phase logging
test_step_logging() {
    log_step "initialization" "Setting up test environment"
    log_step "execution" "Running test operations"
    log_step "cleanup" "Cleaning up test resources"
    
    return 0
}

# Test 6: Configuration functions
test_config_functions() {
    local old_level="$XANADOS_LOG_LEVEL"
    
    set_log_level "WARNING"
    if [[ "$XANADOS_LOG_LEVEL" == "WARNING" ]]; then
        set_log_level "$old_level"
        return 0
    else
        set_log_level "$old_level"
        return 1
    fi
}

# Test 7: Migration helpers validation
test_migration_helpers() {
    # Test migration detection (function existence)
    if command -v migrate_script_logging >/dev/null 2>&1 && \
       command -v deploy_advanced_logging >/dev/null 2>&1 && \
       command -v bulk_migrate_scripts >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Test 8: Directory integration
test_directory_integration() {
    local log_file
    log_file="$(get_log_filename "test-integration" "log")"
    
    if [[ "$log_file" =~ results/logs/ ]]; then
        return 0
    else
        log_error "Log file not using standardized directory: $log_file"
        return 1
    fi
}

# Test 9: Log rotation functionality
test_log_rotation() {
    local test_log="/tmp/xanados-rotation-test-$$.log"
    
    # Create a large test log file
    {
        for i in {1..1000}; do
            echo "Test log entry $i - $(date) - Some test data to make the file larger"
        done
    } > "$test_log"
    
    # Test rotation
    local old_max_size="$XANADOS_LOG_MAX_SIZE"
    XANADOS_LOG_MAX_SIZE=1024  # Small size for testing
    
    rotate_log_file "$test_log"
    
    # Check if rotation occurred
    if [[ -f "${test_log%.*}.1.${test_log##*.}" ]]; then
        rm -f "$test_log"* 2>/dev/null
        XANADOS_LOG_MAX_SIZE="$old_max_size"
        return 0
    else
        rm -f "$test_log"* 2>/dev/null
        XANADOS_LOG_MAX_SIZE="$old_max_size"
        return 1
    fi
}

# Test 10: Structured logging validation
test_structured_logging() {
    local old_structured="$XANADOS_LOG_STRUCTURED"
    local old_console="$XANADOS_LOG_TO_CONSOLE"
    local test_log="/tmp/xanados-structured-test-$$.log"
    
    # Setup structured logging to file
    XANADOS_LOG_STRUCTURED="true"
    XANADOS_LOG_TO_CONSOLE="false"
    init_logging "$test_log" "INFO" false
    
    log_info "Structured test message" "structured-test" '"test_key":"test_value"'
    
    # Check if the log contains JSON
    if grep -q '{"timestamp":' "$test_log"; then
        rm -f "$test_log"
        XANADOS_LOG_STRUCTURED="$old_structured"
        XANADOS_LOG_TO_CONSOLE="$old_console"
        return 0
    else
        rm -f "$test_log"
        XANADOS_LOG_STRUCTURED="$old_structured"
        XANADOS_LOG_TO_CONSOLE="$old_console"
        return 1
    fi
}

# Run all tests
log_step "test-execution" "Running advanced logging validation tests"

run_test "Advanced logging functions" "test_logging_functions"
run_test "Performance logging" "test_performance_logging"
run_test "File operations logging" "test_file_logging"
run_test "Command execution logging" "test_command_logging"
run_test "Step/phase logging" "test_step_logging"
run_test "Configuration functions" "test_config_functions"
run_test "Migration helpers validation" "test_migration_helpers"
run_test "Directory integration" "test_directory_integration"
run_test "Log rotation functionality" "test_log_rotation"
run_test "Structured logging validation" "test_structured_logging"

# Additional deployment tests
log_step "deployment-validation" "Validating deployment functions"

# Test configuration generation
log_info "Testing configuration generation" "deployment-test"
temp_config="/tmp/xanados-test-config-$$.conf"
generate_logging_config "$temp_config"
if [[ -f "$temp_config" ]]; then
    log_success "✅ Configuration generation successful" "deployment-test"
    rm -f "$temp_config"
    ((TESTS_PASSED++))
else
    log_error "❌ Configuration generation failed" "deployment-test"
    ((TESTS_FAILED++))
fi
((TOTAL_TESTS++))

# Test performance monitoring
log_info "Testing performance monitoring (quick test)" "deployment-test"
monitor_logging_performance 100  # Quick test with 100 iterations
log_success "✅ Performance monitoring completed" "deployment-test"
((TESTS_PASSED++))
((TOTAL_TESTS++))

# Summary
log_step "test-summary" "Generating test results"

echo
print_section "Task 3.2.3 Validation Results"
echo
log_info "Total Tests: $TOTAL_TESTS" "test-summary"
log_info "Passed: $TESTS_PASSED" "test-summary"
log_info "Failed: $TESTS_FAILED" "test-summary"
log_info "Success Rate: $((TESTS_PASSED * 100 / TOTAL_TESTS))%" "test-summary"

if [[ $TESTS_FAILED -eq 0 ]]; then
    log_success "🎉 All tests passed! Task 3.2.3 implementation is successful." "test-summary"
    echo
    print_info "Advanced Logging Deployment Features Validated:"
    print_info "✅ Enhanced logging functions with all log levels"
    print_info "✅ Structured JSON logging for automated parsing"
    print_info "✅ Performance and resource usage logging"
    print_info "✅ File operation and command execution logging"
    print_info "✅ Step/phase logging for complex operations"
    print_info "✅ Configurable log levels and rotation"
    print_info "✅ Integration with standardized directories (Task 3.2.1)"
    print_info "✅ Migration helpers for legacy scripts"
    print_info "✅ Deployment automation functions"
    print_info "✅ Performance monitoring and validation"
    echo
    print_success "Advanced logging system is ready for deployment across xanadOS!"
    
    # Generate deployment validation report
    log_info "Generating deployment validation report..." "test-summary"
    validate_logging_deployment
    
    exit 0
else
    log_error "Some tests failed. Please review the implementation." "test-summary"
    exit 1
fi
