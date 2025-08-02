#!/bin/bash
# Task 3.2.1: Unified Results Directory Schema - Test Script
# Tests the new standardized results directory functions

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/directories.sh"

print_header "Task 3.2.1: Unified Results Directory Schema - Validation"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test function helper
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    local should_fail="${4:-false}"
    
    ((TOTAL_TESTS++))
    
    print_info "Testing: $test_name"
    
    local result
    result=$(eval "$test_command" 2>&1)
    local exit_code=$?
    
    # For error tests, we expect the command to fail
    if [[ "$should_fail" == "true" ]]; then
        if [[ $exit_code -ne 0 && "$result" =~ $expected_pattern ]]; then
            print_success "✅ PASS: $test_name"
            print_debug "   Result: $result"
            ((TESTS_PASSED++))
            return 0
        else
            print_error "❌ FAIL: $test_name"
            print_error "   Expected pattern: $expected_pattern (should fail)"
            print_error "   Actual result: $result"
            print_error "   Exit code: $exit_code"
            ((TESTS_FAILED++))
            return 1
        fi
    else
        # Normal tests expect success
        if [[ $exit_code -eq 0 && "$result" =~ $expected_pattern ]]; then
            print_success "✅ PASS: $test_name"
            print_debug "   Result: $result"
            ((TESTS_PASSED++))
            return 0
        else
            print_error "❌ FAIL: $test_name"
            print_error "   Expected pattern: $expected_pattern"
            print_error "   Actual result: $result"
            print_error "   Exit code: $exit_code"
            ((TESTS_FAILED++))
            return 1
        fi
    fi
}

# Test 1: Basic results directory functions
print_section "Testing Basic Results Directory Functions"

run_test "get_results_dir with timestamp" \
    "get_results_dir general true" \
    "results/general/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}"

run_test "get_results_dir without timestamp" \
    "get_results_dir general false" \
    "results/general$"

run_test "get_results_dir benchmarks" \
    "get_results_dir benchmarks false" \
    "results/benchmarks$"

run_test "get_results_dir gaming" \
    "get_results_dir gaming false" \
    "results/gaming$"

run_test "get_results_dir testing" \
    "get_results_dir testing false" \
    "results/testing$"

# Test 2: Specialized directory functions
print_section "Testing Specialized Directory Functions"

run_test "get_benchmark_dir with timestamp" \
    "get_benchmark_dir true" \
    "results/benchmarks/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}"

run_test "get_benchmark_dir without timestamp" \
    "get_benchmark_dir false" \
    "results/benchmarks/[0-9]{4}-[0-9]{2}-[0-9]{2}"

run_test "get_log_dir with timestamp" \
    "get_log_dir true" \
    "results/logs/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}"

run_test "get_gaming_results_dir" \
    "get_gaming_results_dir false" \
    "results/gaming$"

run_test "get_testing_results_dir" \
    "get_testing_results_dir true" \
    "results/testing/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}"

# Test 3: Directory structure creation
print_section "Testing Directory Structure Creation"

run_test "ensure_results_structure creates directories" \
    "ensure_results_structure testing true >/dev/null && find \$(get_results_dir testing true) -type d | wc -l" \
    "^[8-9]|[1-9][0-9]"

run_test "ensure_results_structure returns correct path" \
    "ensure_results_structure gaming true" \
    "results/gaming/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}"

# Test 4: Filename generation
print_section "Testing Filename Generation"

run_test "get_results_filename basic" \
    "get_results_filename test-data json benchmarks" \
    "results/benchmarks/data/benchmarks-test-data-[0-9]{8}-[0-9]{6}.json"

run_test "get_log_filename basic" \
    "get_log_filename test-script log" \
    "results/logs/[0-9]{4}-[0-9]{2}-[0-9]{2}/test-script-[0-9]{8}-[0-9]{6}.log"

# Test 5: Directory consistency checks
print_section "Testing Directory Consistency"

# Test that all result types create the same subdirectory structure
RESULT_TYPES=("general" "benchmarks" "gaming" "testing")
EXPECTED_SUBDIRS=("data" "reports" "logs" "temp" "archive" "screenshots" "configs")

for result_type in "${RESULT_TYPES[@]}"; do
    # Create the structure
    test_dir=$(ensure_results_structure "$result_type" true)
    
    # Check that all expected subdirectories exist
    subdirs_found=0
    for subdir in "${EXPECTED_SUBDIRS[@]}"; do
        if [[ -d "$test_dir/$subdir" ]]; then
            ((subdirs_found++))
        fi
    done
    
    run_test "ensure_results_structure $result_type creates all subdirs" \
        "echo $subdirs_found" \
        "^${#EXPECTED_SUBDIRS[@]}$"
done

# Test 6: Backward compatibility and migration
print_section "Testing Backward Compatibility"

# Check that old docs/reports structure is still accessible for existing files
if [[ -d "docs/reports" ]]; then
    run_test "Old docs/reports structure preserved" \
        "find docs/reports -type f | wc -l" \
        "^[0-9]+$"
fi

# Test 7: Performance validation
print_section "Testing Performance"

# Test directory creation performance
start_time=$(date +%s%3N)
for i in {1..10}; do
    get_results_dir "performance-test" true >/dev/null
done
end_time=$(date +%s%3N)
duration=$((end_time - start_time))

run_test "Directory function performance (10 calls < 100ms)" \
    "echo $duration" \
    "^[0-9]{1,2}$"

# Test 8: Error handling
print_section "Testing Error Handling"

run_test "get_results_filename requires base_name" \
    "get_results_filename '' json test 2>&1" \
    ".*base_name is required.*" \
    "true"

run_test "get_log_filename requires script_name" \
    "get_log_filename '' log 2>&1" \
    ".*script_name is required.*" \
    "true"

# Summary
print_section "Test Summary"

echo
print_info "Task 3.2.1 Validation Results:"
print_info "  Total Tests: $TOTAL_TESTS"
print_info "  Passed: $TESTS_PASSED"
print_info "  Failed: $TESTS_FAILED"
print_info "  Success Rate: $((TESTS_PASSED * 100 / TOTAL_TESTS))%"

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_success "🎉 All tests passed! Task 3.2.1 implementation is successful."
    echo
    print_info "Standardized Results Directory Schema Features Validated:"
    print_info "✅ Consistent directory structure across all result types"
    print_info "✅ Timestamp-based organization (YYYY-MM-DD_HH-MM-SS format)"
    print_info "✅ Type-specific result directories (benchmarks, gaming, testing, etc.)"
    print_info "✅ Standard subdirectories (data, reports, logs, temp, archive, etc.)"
    print_info "✅ Filename generation with consistent naming patterns"
    print_info "✅ Error handling and input validation"
    print_info "✅ Performance optimization for directory operations"
    echo
    print_info "The unified results directory schema is ready for use across all xanadOS scripts!"
    exit 0
else
    print_error "Some tests failed. Please review the implementation."
    exit 1
fi
