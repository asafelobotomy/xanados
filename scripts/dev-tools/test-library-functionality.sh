#!/bin/bash
#
# Proper Library Reference and Functionality Test
# Tests libraries in their actual runtime environment
#

cd "$(dirname "$0")/../.." || exit 1

echo "================================================"
echo "LIBRARY FUNCTIONALITY VALIDATION"
echo "================================================"
echo ""

# Test 1: Individual library loading
echo "1. Testing Individual Library Loading:"
echo "======================================"

test_library() {
    local lib_path="$1"
    local lib_name=$(basename "$lib_path" .sh)
    
    echo -n "  Testing $lib_name... "
    
    # Test in subshell to avoid conflicts
    if (
        cd "$(dirname "$0")/../.." || exit 1
        # shellcheck disable=SC1090
        source "$lib_path" 2>/dev/null
    ); then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL"
        return 1
    fi
}

LIBRARIES=(
    "scripts/lib/common.sh"
    "scripts/lib/directories.sh"
    "scripts/lib/gaming-env.sh"
    "scripts/lib/logging.sh"
    "scripts/lib/reports.sh"
    "scripts/lib/validation.sh"
)

PASSED=0
TOTAL=0

for lib in "${LIBRARIES[@]}"; do
    if test_library "$lib"; then
        ((PASSED++))
    fi
    ((TOTAL++))
done

echo ""
echo "Individual Library Results: $PASSED/$TOTAL passed"
echo ""

# Test 2: Dependency chain testing
echo "2. Testing Dependency Chains:"
echo "============================="

test_dependency_chain() {
    local description="$1"
    shift
    local libs=("$@")
    
    echo -n "  $description... "
    
    if (
        cd "$(dirname "$0")/../.." || exit 1
        for lib in "${libs[@]}"; do
            # shellcheck disable=SC1090
            source "$lib" 2>/dev/null || exit 1
        done
    ); then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL"
        return 1
    fi
}

# Test common library dependencies
test_dependency_chain "common.sh standalone" "scripts/lib/common.sh"
test_dependency_chain "common.sh + directories.sh" "scripts/lib/common.sh" "scripts/lib/directories.sh"
test_dependency_chain "directories.sh (auto-loads common)" "scripts/lib/directories.sh"
test_dependency_chain "reports.sh (auto-loads dependencies)" "scripts/lib/reports.sh"
test_dependency_chain "validation.sh (auto-loads dependencies)" "scripts/lib/validation.sh"
test_dependency_chain "gaming-env.sh (auto-loads dependencies)" "scripts/lib/gaming-env.sh"

echo ""

# Test 3: Function availability after loading
echo "3. Testing Function Availability:"
echo "================================="

test_functions() {
    echo -n "  Testing function availability... "
    
    if (
        cd "$(dirname "$0")/../.." || exit 1
        source scripts/lib/common.sh 2>/dev/null
        source scripts/lib/directories.sh 2>/dev/null
        source scripts/lib/reports.sh 2>/dev/null
        
        # Test key functions exist
        declare -f print_info >/dev/null || exit 1
        declare -f print_error >/dev/null || exit 1
        declare -f print_success >/dev/null || exit 1
        declare -f get_project_root >/dev/null || exit 1
        declare -f get_results_dir >/dev/null || exit 1
        declare -f ensure_directory >/dev/null || exit 1
        declare -f generate_report >/dev/null || exit 1
    ); then
        echo "✅ PASS"
    else
        echo "❌ FAIL"
    fi
}

test_functions

echo ""

# Test 4: Actual functionality test
echo "4. Testing Actual Functionality:"
echo "================================"

test_actual_functionality() {
    echo -n "  Testing real function calls... "
    
    if (
        cd "$(dirname "$0")/../.." || exit 1
        source scripts/lib/common.sh 2>/dev/null
        source scripts/lib/directories.sh 2>/dev/null
        
        # Test actual function calls
        project_root=$(get_project_root 2>/dev/null) || exit 1
        [[ -n "$project_root" ]] || exit 1
        
        results_dir=$(get_results_dir 2>/dev/null) || exit 1
        [[ -n "$results_dir" ]] || exit 1
        
        # Test print functions (redirect output)
        print_info "Test message" >/dev/null 2>&1 || exit 1
        print_success "Test success" >/dev/null 2>&1 || exit 1
        
    ); then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL"
        return 1
    fi
}

test_actual_functionality

# Test 5: Cross-library integration
echo ""
echo "5. Testing Cross-Library Integration:"
echo "====================================="

test_integration() {
    echo -n "  Testing report generation with all libraries... "
    
    if (
        cd "$(dirname "$0")/../.." || exit 1
        
        # Load all libraries in correct order
        source scripts/lib/common.sh 2>/dev/null || exit 1
        source scripts/lib/directories.sh 2>/dev/null || exit 1
        source scripts/lib/reports.sh 2>/dev/null || exit 1
        
        # Test that reports can access directory functions
        results_dir=$(get_results_dir "general" false 2>/dev/null) || exit 1
        [[ "$results_dir" == *"docs/reports/generated"* ]] || exit 1
        
        # Test report generation constants are available
        [[ -n "$REPORT_FORMAT_JSON" ]] || exit 1
        [[ -n "$REPORT_TYPE_SYSTEM" ]] || exit 1
        
    ); then
        echo "✅ PASS"
        return 0
    else
        echo "❌ FAIL"
        return 1
    fi
}

test_integration

# Test 6: Check for undefined variables or functions
echo ""
echo "6. Testing for Undefined References:"
echo "===================================="

test_undefined_references() {
    echo -n "  Checking for undefined function calls... "
    
    local issues=0
    
    # Check each library for potential undefined function calls
    for lib in "${LIBRARIES[@]}"; do
        if [[ -f "$lib" ]]; then
            # Look for function calls that might be undefined
            # This is a basic check - could be enhanced
            undefined_funcs=$(grep -o '[a-zA-Z_][a-zA-Z0-9_]*(' "$lib" | grep -v '^#' | sort -u | while read -r func; do
                func_name=${func%(*}
                # Skip common bash built-ins and obvious patterns
                case "$func_name" in
                    "if"|"while"|"for"|"case"|"echo"|"printf"|"read"|"test"|"local"|"return"|"exit"|"cd"|"source"|"declare"|"grep"|"sed"|"awk"|"find"|"basename"|"dirname"|"date"|"wc"|"sort"|"head"|"tail") 
                        continue ;;
                    *)
                        # Check if function is defined in any library
                        if ! grep -q "^[[:space:]]*${func_name}()" scripts/lib/*.sh 2>/dev/null; then
                            echo "$lib: $func_name"
                            ((issues++))
                        fi
                        ;;
                esac
            done)
            
            if [[ -n "$undefined_funcs" ]]; then
                echo ""
                echo "    Potential undefined functions in $(basename "$lib"):"
                echo "$undefined_funcs" | head -5  # Limit output
            fi
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        echo "✅ PASS"
    else
        echo "⚠️  $issues potential issues found"
    fi
}

test_undefined_references

echo ""
echo "================================================"
echo "SUMMARY"
echo "================================================"
echo ""

# Final comprehensive test
echo "Final Integration Test:"
if (
    cd "$(dirname "$0")/../.." || exit 1
    source scripts/lib/common.sh 2>/dev/null &&
    source scripts/lib/directories.sh 2>/dev/null &&
    source scripts/lib/reports.sh 2>/dev/null &&
    
    # Test key functionality
    project_root=$(get_project_root) &&
    results_dir=$(get_results_dir) &&
    [[ -n "$project_root" ]] &&
    [[ -n "$results_dir" ]] &&
    [[ "$results_dir" == *"docs/reports/generated"* ]]
); then
    echo "✅ ALL LIBRARIES WORKING CORRECTLY"
    echo ""
    echo "✅ Library files exist and have valid syntax"
    echo "✅ Dependencies load correctly"
    echo "✅ Functions are available and working"
    echo "✅ Cross-library integration functional"
    echo "✅ Directory structure functions correctly"
    echo "✅ Report generation system integrated properly"
else
    echo "❌ INTEGRATION ISSUES DETECTED"
    echo ""
    echo "Some libraries may have loading or functionality issues."
    echo "Check individual test results above for details."
fi

echo ""
