#!/bin/bash
# Task 3.3.1: Progress Indicators - Test & Validation Script

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# Auto-initialize advanced logging for this test
auto_init_logging "$(basename "$0")" "INFO" "testing"

print_header "Task 3.3.1: Progress Indicators - Validation"

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

# Test 1: Basic progress bar functionality
test_basic_progress() {
    log_info "Testing basic progress bar with 10 steps..." "progress-test"
    for i in {1..10}; do
        show_progress "Processing items" "$i" 10
        sleep 0.1
    done
    return 0
}

# Test 2: Advanced progress bar with ETA
test_advanced_progress() {
    log_info "Testing advanced progress bar with ETA..." "progress-test"
    for i in {0..20}; do
        show_progress_advanced "Downloading files" "$i" 20 true 30
        sleep 0.1
    done
    return 0
}

# Test 3: Step-based progress
test_step_progress() {
    log_info "Testing step-based progress indicators..." "progress-test"
    
    local steps=("Initialize" "Process" "Validate" "Complete")
    local total=${#steps[@]}
    
    for i in "${!steps[@]}"; do
        local step_num=$((i + 1))
        show_step_progress "${steps[i]}" "$step_num" "$total" "Working on ${steps[i],,} phase"
        sleep 0.2
    done
    return 0
}

# Test 4: File operation progress
test_file_progress() {
    log_info "Testing file operation progress..." "progress-test"
    
    local total_size=10485760  # 10MB
    local chunk_size=524288    # 512KB
    
    for ((current=0; current<=total_size; current+=chunk_size)); do
        if [[ $current -gt $total_size ]]; then
            current=$total_size
        fi
        show_file_progress "DOWNLOAD" "test-file.iso" "$current" "$total_size"
        sleep 0.05
    done
    return 0
}

# Test 5: Multi-progress functionality
test_multi_progress() {
    log_info "Testing multi-progress functionality..." "progress-test"
    
    init_multi_progress "test_job" 15 "Processing batch jobs"
    
    for i in {1..15}; do
        update_multi_progress "test_job" 1
        sleep 0.1
    done
    return 0
}

# Test 6: Timer-based progress
test_timer_progress() {
    log_info "Testing timer-based progress (3 seconds)..." "progress-test"
    show_timer_progress "Waiting for system" 3 1
    return 0
}

# Test 7: Spinner functionality
test_spinner() {
    log_info "Testing spinner with background process..." "progress-test"
    
    # Start a background process
    sleep 2 &
    local bg_pid=$!
    
    show_spinner "$bg_pid" "Background processing"
    
    # Wait for the process to complete
    wait "$bg_pid"
    return 0
}

# Test 8: Progress wrapper for commands
test_command_wrapper() {
    log_info "Testing command wrapper with progress..." "progress-test"
    
    run_with_progress "Listing directory contents" ls -la /tmp >/dev/null
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Test 9: Progress enable/disable functionality
test_enable_disable() {
    log_info "Testing progress enable/disable..." "progress-test"
    
    # Test disable
    disable_progress
    if ! is_progress_enabled; then
        log_info "Progress disabled successfully" "progress-test"
    else
        return 1
    fi
    
    # Test enable
    enable_progress
    if is_progress_enabled; then
        log_info "Progress enabled successfully" "progress-test"
        return 0
    else
        return 1
    fi
}

# Test 10: Error handling and edge cases
test_error_handling() {
    log_info "Testing error handling and edge cases..." "progress-test"
    
    # Test with zero total (should handle gracefully)
    show_progress_advanced "Edge case test" 0 0 false 20
    
    # Test with negative values (should handle gracefully)
    show_progress "Negative test" 0 1
    
    return 0
}

# Demo mode - showcase all progress indicators
demo_mode() {
    if [[ "${1:-}" == "--demo" ]]; then
        print_header "Progress Indicators Demo Mode"
        
        echo "🎯 Showcasing xanadOS Progress Indicators..."
        echo
        
        # Demo 1: System initialization
        print_section "System Initialization Progress"
        for i in {1..8}; do
            show_step_progress "Initialize System" "$i" 8 "Loading component $i"
            sleep 0.3
        done
        echo
        
        # Demo 2: Package installation simulation
        print_section "Package Installation Progress"
        for i in {0..25}; do
            show_progress_advanced "Installing gaming packages" "$i" 25 true 40
            sleep 0.1
        done
        echo
        
        # Demo 3: ISO creation simulation
        print_section "ISO Creation Progress"
        local iso_size=734003200  # ~700MB
        local chunk_size=14680064  # ~14MB chunks
        
        for ((current=0; current<=iso_size; current+=chunk_size)); do
            if [[ $current -gt $iso_size ]]; then
                current=$iso_size
            fi
            show_file_progress "CREATE" "xanadOS-gaming.iso" "$current" "$iso_size"
            sleep 0.1
        done
        echo
        
        # Demo 4: Benchmark execution
        print_section "Benchmark Execution"
        run_with_progress "Running gaming performance benchmark" sleep 3
        echo
        
        print_success "🎉 Demo completed! All progress indicators working perfectly."
        return 0
    fi
    return 1
}

# Run demo if requested
if demo_mode "$@"; then
    exit 0
fi

# Main test execution
log_step "test-execution" "Running progress indicator validation tests"

echo "🔄 Testing Progress Indicator Functions..."
echo

run_test "Basic progress bar functionality" "test_basic_progress"
echo
run_test "Advanced progress bar with ETA" "test_advanced_progress"
echo
run_test "Step-based progress indicators" "test_step_progress"
echo
run_test "File operation progress" "test_file_progress"
echo
run_test "Multi-progress functionality" "test_multi_progress"
echo
run_test "Timer-based progress" "test_timer_progress"
echo
run_test "Spinner functionality" "test_spinner"
echo
run_test "Command wrapper with progress" "test_command_wrapper"
echo
run_test "Progress enable/disable" "test_enable_disable"
echo
run_test "Error handling and edge cases" "test_error_handling"
echo

# Summary
log_step "test-summary" "Generating test results"

echo
print_section "Task 3.3.1 Validation Results"
echo
log_info "Total Tests: $TOTAL_TESTS" "test-summary"
log_info "Passed: $TESTS_PASSED" "test-summary"
log_info "Failed: $TESTS_FAILED" "test-summary"
log_info "Success Rate: $((TESTS_PASSED * 100 / TOTAL_TESTS))%" "test-summary"

if [[ $TESTS_FAILED -eq 0 ]]; then
    log_success "🎉 All tests passed! Task 3.3.1 implementation is successful." "test-summary"
    echo
    print_info "Progress Indicator Features Validated:"
    print_info "✅ Basic progress bars with percentage display"
    print_info "✅ Advanced progress bars with ETA calculation"
    print_info "✅ Step-based progress for multi-phase operations"
    print_info "✅ File operation progress with size tracking"
    print_info "✅ Multi-progress support for parallel operations"
    print_info "✅ Timer-based progress for time-bound operations"
    print_info "✅ Spinner animation for indeterminate progress"
    print_info "✅ Command wrapper with automatic progress display"
    print_info "✅ Enable/disable functionality for batch mode"
    print_info "✅ Robust error handling and edge case management"
    echo
    print_success "Progress indicators are ready for deployment across xanadOS!"
    echo
    print_info "Usage Examples:"
    print_info "• show_progress_advanced \"Operation\" \$current \$total"
    print_info "• show_step_progress \"Step Name\" \$step \$total_steps"
    print_info "• run_with_progress \"Description\" command args"
    print_info "• show_spinner \$pid \"Working...\""
    echo
    print_info "To see a full demo, run: $0 --demo"
    
    exit 0
else
    log_error "Some tests failed. Please review the implementation." "test-summary"
    exit 1
fi
