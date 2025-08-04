#!/bin/bash
# xanadOS Unified Testing Framework
# Consolidates all testing functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Test categories
declare -A TEST_CATEGORIES=(
    ["unit"]="Unit tests for individual components"
    ["integration"]="Integration tests for system components"
    ["automated"]="Automated performance and validation tests"
    ["validation"]="Script and system validation tests"
)

show_help() {
    echo "xanadOS Unified Testing Framework"
    echo "Usage: $0 [category|all] [options]"
    echo
    echo "Test categories:"
    for category in "${!TEST_CATEGORIES[@]}"; do
        printf "  %-12s - %s\n" "$category" "${TEST_CATEGORIES[$category]}"
    done
    echo
    echo "  all              - Run all test categories"
    echo
    echo "Options:"
    echo "  --help          - Show this help"
    echo "  --verbose       - Verbose output"
    echo "  --parallel      - Run tests in parallel"
}

run_category_tests() {
    local category="$1"
    local test_dir="${SCRIPT_DIR}/${category}"
    
    if [[ ! -d "$test_dir" ]]; then
        echo "Test directory not found: $test_dir"
        return 1
    fi
    
    echo "Running $category tests..."
    local test_count=0
    local passed_count=0
    
    while IFS= read -r test_script; do
        if [[ -x "$test_script" ]]; then
            echo "  Running: $(basename "$test_script")"
            if "$test_script"; then
                ((passed_count++))
            fi
            ((test_count++))
        fi
    done < <(find "$test_dir" -name "*.sh" -type f)
    
    echo "  Results: $passed_count/$test_count tests passed"
}

main() {
    local category="${1:-help}"
    
    case "$category" in
        help|--help|-h)
            show_help
            ;;
        all)
            for cat in "${!TEST_CATEGORIES[@]}"; do
                run_category_tests "$cat"
            done
            ;;
        unit|integration|automated|validation)
            run_category_tests "$category"
            ;;
        *)
            echo "Unknown test category: $category"
            show_help
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
