#!/bin/bash
#
# Library Testing and Reference Validation
# Tests all libraries for functionality and correct cross-references
#

cd "$(dirname "$0")/../.." || exit 1

print_test_header() {
    echo ""
    echo "================================================"
    echo "$1"
    echo "================================================"
}

print_test_result() {
    local test_name="$1"
    local result="$2"
    if [[ "$result" == "PASS" ]]; then
        echo "  ✅ $test_name"
    else
        echo "  ❌ $test_name: $result"
    fi
}

print_test_header "LIBRARY FUNCTIONALITY AND REFERENCE VALIDATION"

# Test 1: Check all library files exist
print_test_header "1. Library File Existence"
LIBRARIES=(
    "scripts/lib/common.sh"
    "scripts/lib/directories.sh" 
    "scripts/lib/gaming-env.sh"
    "scripts/lib/logging.sh"
    "scripts/lib/reports.sh"
    "scripts/lib/validation.sh"
)

for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        print_test_result "$(basename "$lib")" "PASS"
    else
        print_test_result "$(basename "$lib")" "FILE NOT FOUND"
    fi
done

# Test 2: Check sourcing syntax
print_test_header "2. Library Syntax Validation"
for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        if bash -n "$lib" 2>/dev/null; then
            print_test_result "$(basename "$lib") syntax" "PASS"
        else
            print_test_result "$(basename "$lib") syntax" "SYNTAX ERROR"
        fi
    fi
done

# Test 3: Check library dependencies
print_test_header "3. Library Dependencies and Cross-References"

echo "Checking source statements in each library:"
for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        echo ""
        echo "📁 $(basename "$lib"):"
        
        # Look for source statements
        sources=$(grep -n "^[[:space:]]*source" "$lib" 2>/dev/null || true)
        if [[ -n "$sources" ]]; then
            echo "$sources" | while read -r line; do
                echo "    📂 $line"
            done
        else
            echo "    ℹ️  No dependencies"
        fi
        
        # Check if sourced files exist
        source_files=$(grep -o 'source[[:space:]]*"[^"]*"' "$lib" 2>/dev/null | sed 's/source[[:space:]]*"//g' | sed 's/"//g' || true)
        if [[ -n "$source_files" ]]; then
            echo "$source_files" | while read -r source_file; do
                # Handle relative paths
                if [[ "$source_file" =~ ^\. ]]; then
                    # Relative to library directory
                    full_path="scripts/lib/$(basename "$source_file")"
                elif [[ "$source_file" =~ ^scripts/ ]]; then
                    full_path="$source_file"
                else
                    full_path="scripts/lib/$source_file"
                fi
                
                if [[ -f "$full_path" ]]; then
                    print_test_result "Dependency: $source_file" "PASS"
                else
                    print_test_result "Dependency: $source_file" "NOT FOUND: $full_path"
                fi
            done
        fi
    fi
done

# Test 4: Test library loading
print_test_header "4. Library Loading Test"

test_library_loading() {
    local lib="$1"
    local lib_name
    lib_name=$(basename "$lib" .sh)
    
    # Try to source the library in a subshell
    # shellcheck disable=SC1090
    if (source "$lib" 2>/dev/null); then
        print_test_result "$lib_name loading" "PASS"
        return 0
    else
        print_test_result "$lib_name loading" "FAILED"
        return 1
    fi
}

for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        test_library_loading "$lib"
    fi
done

# Test 5: Test key functions from each library
print_test_header "5. Key Function Testing"

echo "Testing common.sh functions:"
if source scripts/lib/common.sh 2>/dev/null; then
    # Test print functions
    if declare -f print_info >/dev/null 2>&1; then
        print_test_result "print_info function" "PASS"
    else
        print_test_result "print_info function" "NOT FOUND"
    fi
    
    if declare -f print_error >/dev/null 2>&1; then
        print_test_result "print_error function" "PASS"
    else
        print_test_result "print_error function" "NOT FOUND"
    fi
    
    if declare -f print_success >/dev/null 2>&1; then
        print_test_result "print_success function" "PASS"
    else
        print_test_result "print_success function" "NOT FOUND"
    fi
else
    print_test_result "common.sh sourcing" "FAILED"
fi

echo ""
echo "Testing directories.sh functions:"
if source scripts/lib/directories.sh 2>/dev/null; then
    if declare -f get_project_root >/dev/null 2>&1; then
        print_test_result "get_project_root function" "PASS"
    else
        print_test_result "get_project_root function" "NOT FOUND"
    fi
    
    if declare -f get_results_dir >/dev/null 2>&1; then
        print_test_result "get_results_dir function" "PASS"
    else
        print_test_result "get_results_dir function" "NOT FOUND"
    fi
    
    if declare -f ensure_directory >/dev/null 2>&1; then
        print_test_result "ensure_directory function" "PASS"
    else
        print_test_result "ensure_directory function" "NOT FOUND"
    fi
else
    print_test_result "directories.sh sourcing" "FAILED"
fi

echo ""
echo "Testing reports.sh functions:"
if source scripts/lib/reports.sh 2>/dev/null; then
    if declare -f generate_report >/dev/null 2>&1; then
        print_test_result "generate_report function" "PASS"
    else
        print_test_result "generate_report function" "NOT FOUND"
    fi
else
    print_test_result "reports.sh sourcing" "FAILED"
fi

# Test 6: Check for circular dependencies
print_test_header "6. Circular Dependency Check"

echo "Analyzing dependency chain:"
for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        lib_name=$(basename "$lib")
        echo ""
        echo "📁 $lib_name dependencies:"
        
        # Get direct dependencies
        deps=$(grep -o 'source[[:space:]]*"[^"]*"' "$lib" 2>/dev/null | sed 's/source[[:space:]]*"//g' | sed 's/"//g' || true)
        if [[ -n "$deps" ]]; then
            echo "$deps" | while read -r dep; do
                dep_basename=$(basename "$dep")
                echo "    → $dep_basename"
                
                # Check if dependency also sources this library
                if [[ -f "scripts/lib/$dep_basename" ]]; then
                    circular=$(grep -o "source.*$(basename "$lib")" "scripts/lib/$dep_basename" 2>/dev/null || true)
                    if [[ -n "$circular" ]]; then
                        echo "      ⚠️  CIRCULAR: $dep_basename sources $(basename "$lib")"
                    fi
                fi
            done
        else
            echo "    ℹ️  No dependencies"
        fi
    fi
done

# Test 7: Runtime functionality test
print_test_header "7. Runtime Functionality Test"

echo "Testing complete library chain:"
if (
    source scripts/lib/common.sh &&
    source scripts/lib/directories.sh &&
    source scripts/lib/reports.sh 2>/dev/null &&
    print_info "Library chain test" >/dev/null 2>&1 &&
    get_project_root >/dev/null 2>&1
); then
    print_test_result "Complete library chain" "PASS"
else
    print_test_result "Complete library chain" "FAILED"
fi

print_test_header "LIBRARY VALIDATION COMPLETE"
echo ""
echo "💡 Next steps if issues found:"
echo "   1. Fix any syntax errors in libraries"
echo "   2. Resolve missing dependencies"
echo "   3. Address circular dependencies"
echo "   4. Verify function definitions"
echo ""
