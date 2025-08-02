#!/bin/bash
# xanadOS Shared Library Test Suite
# Validates that all shared libraries work correctly
# Version: 1.0.0

# Note: Not using set -e to allow test failures without script exit

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$XANADOS_ROOT/scripts/lib"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

# Simple test framework
test_start() {
    echo "🧪 Testing: $1"
}

test_pass() {
    echo "  ✅ PASS: $1"
    ((TESTS_PASSED++))
    TEST_RESULTS+=("PASS: $1")
}

test_fail() {
    echo "  ❌ FAIL: $1"
    ((TESTS_FAILED++))
    TEST_RESULTS+=("FAIL: $1")
}

test_info() {
    echo "  ℹ️  INFO: $1"
}

# Test that all library files exist
test_library_files() {
    test_start "Library files exist"
    
    local libraries=("common.sh" "logging.sh" "validation.sh" "directories.sh" "gaming-env.sh")
    
    for lib in "${libraries[@]}"; do
        if [[ -f "$LIB_DIR/$lib" ]]; then
            test_pass "Found $lib"
        else
            test_fail "Missing $lib"
        fi
    done
}

# Test common.sh library
test_common_library() {
    test_start "Common library functionality"
    
    # Source the library
    if source "$LIB_DIR/common.sh"; then
        test_pass "Successfully sourced common.sh"
    else
        test_fail "Failed to source common.sh"
        return 1
    fi
    
    # Test print functions exist
    if declare -f print_status >/dev/null; then
        test_pass "print_status function available"
    else
        test_fail "print_status function missing"
    fi
    
    if declare -f print_success >/dev/null; then
        test_pass "print_success function available"
    else
        test_fail "print_success function missing"
    fi
    
    # Test utility functions
    if declare -f command_exists >/dev/null; then
        test_pass "command_exists function available"
    else
        test_fail "command_exists function missing"
    fi
    
    if declare -f safe_mkdir >/dev/null; then
        test_pass "safe_mkdir function available"
    else
        test_fail "safe_mkdir function missing"
    fi
    
    # Test XANADOS_ROOT is set
    if [[ -n "$XANADOS_ROOT" ]]; then
        test_pass "XANADOS_ROOT is set: $XANADOS_ROOT"
    else
        test_fail "XANADOS_ROOT is not set"
    fi
}

# Test logging.sh library
test_logging_library() {
    test_start "Logging library functionality"
    
    # Source the library
    if source "$LIB_DIR/logging.sh"; then
        test_pass "Successfully sourced logging.sh"
    else
        test_fail "Failed to source logging.sh"
        return 1
    fi
    
    # Test logging functions exist
    if declare -f log_message >/dev/null; then
        test_pass "log_message function available"
    else
        test_fail "log_message function missing"
    fi
    
    if declare -f init_logging >/dev/null; then
        test_pass "init_logging function available"
    else
        test_fail "init_logging function missing"
    fi
    
    # Test logging levels
    local log_file="/tmp/xanados-test-$(date +%s).log"
    
    if init_logging "$log_file" "INFO" "false"; then
        test_pass "Logging initialization successful"
        
        # Test logging to file
        log_message "INFO" "Test message"
        
        if [[ -f "$log_file" ]] && grep -q "Test message" "$log_file"; then
            test_pass "Log file creation and writing works"
        else
            test_fail "Log file creation or writing failed"
        fi
        
        # Cleanup
        rm -f "$log_file"
    else
        test_fail "Logging initialization failed"
    fi
}

# Test validation.sh library
test_validation_library() {
    test_start "Validation library functionality"
    
    # Source the library
    if source "$LIB_DIR/validation.sh"; then
        test_pass "Successfully sourced validation.sh"
    else
        test_fail "Failed to source validation.sh"
        return 1
    fi
    
    # Test command detection functions
    if declare -f command_exists >/dev/null; then
        test_pass "command_exists function available"
        
        # Test with a command that should exist
        if command_exists "bash"; then
            test_pass "command_exists works for existing command (bash)"
        else
            test_fail "command_exists failed for bash"
        fi
        
        # Test with a command that shouldn't exist
        if ! command_exists "this-command-should-not-exist-12345"; then
            test_pass "command_exists correctly reports missing command"
        else
            test_fail "command_exists incorrectly reports missing command as available"
        fi
    else
        test_fail "command_exists function missing from validation.sh"
    fi
    
    # Test validation functions
    if declare -f validate_input >/dev/null; then
        test_pass "validate_input function available"
    else
        test_fail "validate_input function missing"
    fi
    
    # Test gaming environment detection
    if declare -f check_gaming_environment >/dev/null; then
        test_pass "check_gaming_environment function available"
    else
        test_fail "check_gaming_environment function missing"
    fi
}

# Test directories.sh library
test_directories_library() {
    test_start "Directories library functionality"
    
    # Source the library
    if source "$LIB_DIR/directories.sh"; then
        test_pass "Successfully sourced directories.sh"
    else
        test_fail "Failed to source directories.sh"
        return 1
    fi
    
    # Test directory functions
    if declare -f get_results_dir >/dev/null; then
        test_pass "get_results_dir function available"
        
        # Test results directory paths
        local results_dir
        results_dir="$(get_results_dir "benchmarks")"
        if [[ "$results_dir" == *"benchmarks"* ]]; then
            test_pass "get_results_dir returns correct path for benchmarks"
        else
            test_fail "get_results_dir returned unexpected path: $results_dir"
        fi
    else
        test_fail "get_results_dir function missing"
    fi
    
    if declare -f ensure_directory >/dev/null; then
        test_pass "ensure_directory function available"
    else
        test_fail "ensure_directory function missing"
    fi
    
    if declare -f is_safe_directory >/dev/null; then
        test_pass "is_safe_directory function available"
        
        # Test safety checks
        if ! is_safe_directory "/"; then
            test_pass "is_safe_directory correctly rejects root directory"
        else
            test_fail "is_safe_directory incorrectly allows root directory"
        fi
    else
        test_fail "is_safe_directory function missing"
    fi
}

# Test gaming-env.sh library
test_gaming_env_library() {
    test_start "Gaming environment library functionality"
    
    # Source the library
    if source "$LIB_DIR/gaming-env.sh"; then
        test_pass "Successfully sourced gaming-env.sh"
    else
        test_fail "Failed to source gaming-env.sh"
        return 1
    fi
    
    # Test gaming detection functions
    if declare -f detect_gaming_environment >/dev/null; then
        test_pass "detect_gaming_environment function available"
    else
        test_fail "detect_gaming_environment function missing"
    fi
    
    if declare -f get_gaming_environment_report >/dev/null; then
        test_pass "get_gaming_environment_report function available"
        
        # Test report generation
        local report
        report="$(get_gaming_environment_report "summary" 2>/dev/null)"
        if [[ "$report" == *"Gaming Environment"* ]]; then
            test_pass "Gaming environment report generation works"
        else
            test_fail "Gaming environment report generation failed"
        fi
    else
        test_fail "get_gaming_environment_report function missing"
    fi
    
    if declare -f get_gaming_readiness_score >/dev/null; then
        test_pass "get_gaming_readiness_score function available"
    else
        test_fail "get_gaming_readiness_score function missing"
    fi
}

# Test library integration
test_library_integration() {
    test_start "Library integration and compatibility"
    
    # Test that libraries can be sourced together
    if source "$LIB_DIR/common.sh" && \
       source "$LIB_DIR/logging.sh" && \
       source "$LIB_DIR/validation.sh" && \
       source "$LIB_DIR/directories.sh" && \
       source "$LIB_DIR/gaming-env.sh"; then
        test_pass "All libraries can be sourced together"
    else
        test_fail "Libraries have conflicts when sourced together"
    fi
    
    # Test that common functions work after all libraries are loaded
    if declare -f print_status >/dev/null && \
       declare -f log_message >/dev/null && \
       declare -f command_exists >/dev/null; then
        test_pass "Functions remain available after loading all libraries"
    else
        test_fail "Function conflicts detected between libraries"
    fi
    
    # Test that variables don't conflict
    if [[ -n "$XANADOS_COMMON_LOADED" ]] && \
       [[ -n "$XANADOS_LOGGING_LOADED" ]] && \
       [[ -n "$XANADOS_VALIDATION_LOADED" ]]; then
        test_pass "Library loading indicators set correctly"
    else
        test_fail "Library loading indicators missing or conflicting"
    fi
}

# Test real-world usage scenario
test_real_world_scenario() {
    test_start "Real-world usage scenario"
    
    # Source all libraries
    source "$LIB_DIR/common.sh"
    source "$LIB_DIR/logging.sh"
    source "$LIB_DIR/validation.sh"
    source "$LIB_DIR/directories.sh"
    
    # Create a temporary test environment
    local test_dir="/tmp/xanados-test-$$"
    local log_file="$test_dir/test.log"
    
    # Test directory creation
    if safe_mkdir "$test_dir"; then
        test_pass "Directory creation works"
        
        # Test logging initialization
        if init_logging "$log_file" "DEBUG" "false"; then
            test_pass "Logging initialization works"
            
            # Test combined logging and print functions
            log_message "INFO" "Testing combined functionality"
            print_status "This is a status message"
            
            if [[ -f "$log_file" ]] && grep -q "Testing combined functionality" "$log_file"; then
                test_pass "Combined logging and print functions work"
            else
                test_fail "Combined functionality test failed"
            fi
        else
            test_fail "Logging initialization failed"
        fi
        
        # Test validation functions
        if validate_input "$test_dir" "directory"; then
            test_pass "Input validation works for existing directory"
        else
            test_fail "Input validation failed for existing directory"
        fi
        
        # Cleanup
        rm -rf "$test_dir"
    else
        test_fail "Directory creation failed"
    fi
}

# Run performance tests
test_performance() {
    test_start "Performance characteristics"
    
    source "$LIB_DIR/common.sh"
    
    # Test library loading time
    local start_time
    start_time="$(date +%s%N)"
    
    source "$LIB_DIR/logging.sh"
    source "$LIB_DIR/validation.sh"
    source "$LIB_DIR/directories.sh"
    source "$LIB_DIR/gaming-env.sh"
    
    local end_time
    end_time="$(date +%s%N)"
    local load_time=$(((end_time - start_time) / 1000000))  # Convert to milliseconds
    
    if [[ $load_time -lt 1000 ]]; then
        test_pass "Library loading time acceptable: ${load_time}ms"
    else
        test_fail "Library loading too slow: ${load_time}ms"
    fi
    
    # Test function call performance
    start_time="$(date +%s%N)"
    for i in {1..100}; do
        command_exists "bash" >/dev/null
    done
    end_time="$(date +%s%N)"
    local call_time=$(((end_time - start_time) / 1000000))
    
    test_info "100 command_exists calls took ${call_time}ms"
}

# Generate test report
generate_test_report() {
    local report_file="$XANADOS_ROOT/archive/reports/$(date +%Y%m%d)/library-test-report.md"
    mkdir -p "$(dirname "$report_file")"
    
    {
        echo "# xanadOS Shared Library Test Report"
        echo ""
        echo "**Date**: $(date)"
        echo "**Test Suite Version**: 1.0.0"
        echo ""
        echo "## Test Results Summary"
        echo ""
        echo "- **Tests Passed**: $TESTS_PASSED"
        echo "- **Tests Failed**: $TESTS_FAILED"
        echo "- **Total Tests**: $((TESTS_PASSED + TESTS_FAILED))"
        echo "- **Success Rate**: $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))%"
        echo ""
        echo "## Detailed Results"
        echo ""
        
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" == "PASS:"* ]]; then
                echo "✅ ${result#PASS: }"
            else
                echo "❌ ${result#FAIL: }"
            fi
        done
        
        echo ""
        echo "## Library Status"
        echo ""
        echo "| Library | Status | Functions |"
        echo "|---------|--------|-----------|"
        echo "| common.sh | $([ -f "$LIB_DIR/common.sh" ] && echo "✅ Available" || echo "❌ Missing") | print_*, command_exists, safe_* |"
        echo "| logging.sh | $([ -f "$LIB_DIR/logging.sh" ] && echo "✅ Available" || echo "❌ Missing") | log_*, init_logging |"
        echo "| validation.sh | $([ -f "$LIB_DIR/validation.sh" ] && echo "✅ Available" || echo "❌ Missing") | validate_*, check_* |"
        echo "| directories.sh | $([ -f "$LIB_DIR/directories.sh" ] && echo "✅ Available" || echo "❌ Missing") | get_*_dir, ensure_directory |"
        echo "| gaming-env.sh | $([ -f "$LIB_DIR/gaming-env.sh" ] && echo "✅ Available" || echo "❌ Missing") | detect_gaming_environment |"
        
    } > "$report_file"
    
    echo "📊 Test report generated: $report_file"
}

# Main test runner
main() {
    echo "🚀 Starting xanadOS Shared Library Test Suite"
    echo ""
    
    # Verify library directory exists
    if [[ ! -d "$LIB_DIR" ]]; then
        echo "❌ Library directory not found: $LIB_DIR"
        exit 1
    fi
    
    # Run all tests
    test_library_files
    test_common_library
    test_logging_library
    test_validation_library
    test_directories_library
    test_gaming_env_library
    test_library_integration
    test_real_world_scenario
    test_performance
    
    echo ""
    echo "📊 Test Results:"
    echo "  ✅ Passed: $TESTS_PASSED"
    echo "  ❌ Failed: $TESTS_FAILED"
    echo "  📈 Success Rate: $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))%"
    
    # Generate report
    generate_test_report
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All tests passed! Shared libraries are ready for use."
        exit 0
    else
        echo ""
        echo "⚠️  Some tests failed. Please review the issues before proceeding."
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
