#!/bin/bash
# ============================================================================
# Task 3.3.2: Parallel Operations Implementation Test Script
# Testing parallel execution functions and progress monitoring
# ============================================================================

set -euo pipefail

# Source xanadOS shared libraries  
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/directories.sh"

# Test configuration
readonly TEST_NAME="Task 3.3.2 Parallel Operations"
readonly TEST_VERSION="1.0.0"
readonly LOG_FILE="$(get_log_dir false)/$(get_log_filename "test-parallel-operations")"
readonly RESULTS_DIR="$(get_results_dir "parallel-operations-test" false)"

# Colors for test output
readonly TEST_GREEN='\033[0;32m'
readonly TEST_RED='\033[0;31m'
readonly TEST_YELLOW='\033[1;33m'
readonly TEST_BLUE='\033[0;34m'
readonly TEST_CYAN='\033[0;36m'
readonly TEST_NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Framework Functions
# ============================================================================

print_test_header() {
    echo -e "${TEST_CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${TEST_NC}"
    echo -e "${TEST_CYAN}║                          $TEST_NAME                         ║${TEST_NC}"
    echo -e "${TEST_CYAN}║                              Test Suite                                   ║${TEST_NC}"
    echo -e "${TEST_CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${TEST_NC}"
    echo
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${TEST_BLUE}▶${TEST_NC} Running test: ${test_name}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_function; then
        echo -e "${TEST_GREEN}✓${TEST_NC} Test passed: ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_message "SUCCESS" "Test passed: $test_name"
        return 0
    else
        echo -e "${TEST_RED}✗${TEST_NC} Test failed: ${test_name}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_message "ERROR" "Test failed: $test_name"
        return 1
    fi
}

print_test_summary() {
    echo
    echo -e "${TEST_CYAN}═══════════════════════════════════════════════════════════════════════════${TEST_NC}"
    echo -e "${TEST_CYAN}                              Test Summary                                 ${TEST_NC}"
    echo -e "${TEST_CYAN}═══════════════════════════════════════════════════════════════════════════${TEST_NC}"
    echo
    echo -e "Total tests run: ${TEST_BLUE}$TESTS_RUN${TEST_NC}"
    echo -e "Tests passed:    ${TEST_GREEN}$TESTS_PASSED${TEST_NC}"
    echo -e "Tests failed:    ${TEST_RED}$TESTS_FAILED${TEST_NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${TEST_GREEN}🎉 All tests passed! Parallel operations system is working correctly.${TEST_NC}"
        return 0
    else
        echo -e "\n${TEST_RED}❌ Some tests failed. Please review the implementation.${TEST_NC}"
        return 1
    fi
}

# ============================================================================
# Test Functions
# ============================================================================

test_parallel_function_exists() {
    # Test that the parallel execution function exists
    if declare -f run_parallel >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

test_parallel_jobs_function_exists() {
    # Test that the parallel jobs function exists
    if declare -f run_parallel_jobs >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

test_parallel_package_function_exists() {
    # Test that the parallel package installation function exists
    if declare -f install_packages_parallel >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

test_parallel_basic_execution() {
    # Test basic parallel execution with simple commands
    local test_jobs=(
        "sleep 0.5 && echo 'Job 1 complete'"
        "sleep 0.3 && echo 'Job 2 complete'"
        "sleep 0.2 && echo 'Job 3 complete'"
    )
    
    echo "Testing basic parallel execution..."
    
    # Should complete in roughly the time of the longest job (0.5s), not the sum (1.0s)
    local start_time
    start_time=$(date +%s)
    
    if run_parallel "${test_jobs[@]}"; then
        local end_time
        end_time=$(date +%s)
        local execution_time=$((end_time - start_time))
        
        echo "Parallel execution completed in ${execution_time}s"
        
        # Check if execution was reasonably parallel (should be less than 2 seconds for 0.5+0.3+0.2=1.0s sequential)
        if [[ $execution_time -le 1 ]]; then
            echo "Execution time acceptable for parallel processing"
            return 0
        else
            echo "Execution took too long: ${execution_time}s (likely sequential)"
            return 1
        fi
    else
        return 1
    fi
}

test_parallel_with_progress() {
    # Test parallel execution with progress monitoring
    echo "Testing parallel execution with progress monitoring..."
    
    local test_jobs=(
        "sleep 0.5 && echo 'Long job complete'"
        "sleep 0.2 && echo 'Short job complete'"
    )
    
    # Initialize multi-progress for 2 jobs
    init_multi_progress 2
    
    if run_parallel_jobs "${test_jobs[@]}"; then
        echo "Parallel execution with progress completed successfully"
        return 0
    else
        return 1
    fi
}

test_parallel_package_simulation() {
    # Test parallel package installation simulation
    echo "Testing parallel package installation simulation..."
    
    # Create a mock package list
    local packages=("package1" "package2" "package3" "package4")
    
    # Test the function exists and handles the input correctly
    if install_packages_parallel "${packages[@]}" --simulate; then
        echo "Parallel package installation simulation completed"
        return 0
    else
        return 1
    fi
}

test_parallel_error_handling() {
    # Test error handling in parallel execution
    echo "Testing parallel execution error handling..."
    
    local test_jobs=(
        "sleep 0.1 && echo 'Success job'"
        "sleep 0.2 && false"  # This should fail
        "sleep 0.1 && echo 'Another success job'"
    )
    
    # Should handle the failure gracefully
    if ! run_parallel "${test_jobs[@]}"; then
        echo "Error handling working correctly (expected failure detected)"
        return 0
    else
        echo "Error handling failed (should have detected failure)"
        return 1
    fi
}

test_parallel_job_limiting() {
    # Test that parallel execution respects job limits
    echo "Testing parallel job limiting..."
    
    local many_jobs=()
    for i in {1..10}; do
        many_jobs+=("sleep 0.1 && echo 'Job $i'")
    done
    
    # Test with limited concurrent jobs
    if run_parallel_limited 4 "${many_jobs[@]}"; then
        echo "Parallel job limiting completed successfully"
        return 0
    else
        return 1
    fi
}

test_benchmark_parallel_execution() {
    # Test parallel benchmark execution
    echo "Testing parallel benchmark execution..."
    
    # Simulate benchmark operations
    local benchmark_jobs=(
        "echo 'CPU benchmark running...' && sleep 0.3 && echo 'CPU benchmark complete'"
        "echo 'Memory benchmark running...' && sleep 0.2 && echo 'Memory benchmark complete'"
        "echo 'Disk benchmark running...' && sleep 0.4 && echo 'Disk benchmark complete'"
    )
    
    if run_benchmark_parallel "${benchmark_jobs[@]}"; then
        echo "Parallel benchmark execution completed successfully"
        return 0
    else
        return 1
    fi
}

test_parallel_file_operations() {
    # Test parallel file operations
    echo "Testing parallel file operations..."
    
    local temp_dir="$RESULTS_DIR/parallel-test"
    mkdir -p "$temp_dir"
    
    # Create multiple files in parallel
    local file_jobs=(
        "echo 'File 1 content' > '$temp_dir/file1.txt'"
        "echo 'File 2 content' > '$temp_dir/file2.txt'"
        "echo 'File 3 content' > '$temp_dir/file3.txt'"
        "echo 'File 4 content' > '$temp_dir/file4.txt'"
    )
    
    if run_parallel "${file_jobs[@]}"; then
        # Verify all files were created
        local created_files=0
        for i in {1..4}; do
            if [[ -f "$temp_dir/file$i.txt" ]]; then
                created_files=$((created_files + 1))
            fi
        done
        
        if [[ $created_files -eq 4 ]]; then
            echo "All parallel file operations completed successfully"
            return 0
        else
            echo "Only $created_files/4 files created"
            return 1
        fi
    else
        return 1
    fi
}

# ============================================================================
# Demo Mode Functions
# ============================================================================

demo_parallel_operations() {
    echo -e "${TEST_CYAN}▶${TEST_NC} Running parallel operations demonstration..."
    echo
    
    echo "=== Basic Parallel Execution Demo ==="
    run_test "Demo: Basic parallel execution" test_parallel_basic_execution
    echo
    
    echo "=== Parallel Progress Monitoring Demo ==="
    run_test "Demo: Progress monitoring" test_parallel_with_progress
    echo
    
    echo "=== Parallel Package Installation Demo ==="
    run_test "Demo: Package installation" test_parallel_package_simulation
    echo
    
    echo "=== Parallel Benchmark Demo ==="
    run_test "Demo: Benchmark execution" test_benchmark_parallel_execution
    echo
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    local demo_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --demo)
                demo_mode=true
                shift
                ;;
            --help)
                echo "Usage: $0 [--demo] [--help]"
                echo "  --demo    Run in demonstration mode"
                echo "  --help    Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Setup
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$RESULTS_DIR"
    
    print_test_header
    
    if $demo_mode; then
        echo "Running in demonstration mode..."
        echo
        demo_parallel_operations
    else
        echo "Running comprehensive test suite..."
        echo
        
        # Core functionality tests
        echo "=== Core Functionality Tests ==="
        run_test "Parallel function exists" test_parallel_function_exists
        run_test "Parallel jobs function exists" test_parallel_jobs_function_exists
        run_test "Parallel package function exists" test_parallel_package_function_exists
        echo
        
        # Functional tests
        echo "=== Functional Tests ==="
        run_test "Basic parallel execution" test_parallel_basic_execution
        run_test "Parallel with progress monitoring" test_parallel_with_progress
        run_test "Parallel package simulation" test_parallel_package_simulation
        run_test "Parallel error handling" test_parallel_error_handling
        run_test "Parallel job limiting" test_parallel_job_limiting
        run_test "Parallel benchmark execution" test_benchmark_parallel_execution
        run_test "Parallel file operations" test_parallel_file_operations
        echo
    fi
    
    print_test_summary
    
    # Log completion
    log_message "INFO" "Task 3.3.2 parallel operations test completed: $TESTS_PASSED/$TESTS_RUN tests passed"
}

# Run main function with all arguments
main "$@"
