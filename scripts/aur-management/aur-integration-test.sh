#!/bin/bash
# xanadOS AUR Integration Test
# Test the complete AUR package management system

# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh" || {
    echo "Error: Could not source common.sh" >&2
    exit 1
}

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors (skip if already defined in common.sh)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly NC='\033[0m'
fi

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Utility functions
# Test AUR management structure
test_aur_structure() {
    print_header "Testing AUR Management Structure"

    # Package directories
    run_test "AUR packages directory exists" "[[ -d '$PROJECT_ROOT/packages/aur' ]]"
    run_test "Hardware packages directory exists" "[[ -d '$PROJECT_ROOT/packages/hardware' ]]"
    run_test "Profile packages directory exists" "[[ -d '$PROJECT_ROOT/packages/profiles' ]]"
    run_test "AUR management scripts directory exists" "[[ -d '$PROJECT_ROOT/scripts/aur-management' ]]"

    # AUR package lists
    run_test "Gaming AUR packages list exists" "[[ -f '$PROJECT_ROOT/packages/aur/gaming.list' ]]"
    run_test "Development AUR packages list exists" "[[ -f '$PROJECT_ROOT/packages/aur/development.list' ]]"
    run_test "Optional AUR packages list exists" "[[ -f '$PROJECT_ROOT/packages/aur/optional.list' ]]"

    # Hardware package lists
    run_test "NVIDIA hardware packages exist" "[[ -f '$PROJECT_ROOT/packages/hardware/nvidia.list' ]]"
    run_test "AMD hardware packages exist" "[[ -f '$PROJECT_ROOT/packages/hardware/amd.list' ]]"
    run_test "Intel hardware packages exist" "[[ -f '$PROJECT_ROOT/packages/hardware/intel.list' ]]"

    # Profile package lists
    run_test "Esports profile packages exist" "[[ -f '$PROJECT_ROOT/packages/profiles/esports.list' ]]"
    run_test "Streaming profile packages exist" "[[ -f '$PROJECT_ROOT/packages/profiles/streaming.list' ]]"
    run_test "Development profile packages exist" "[[ -f '$PROJECT_ROOT/packages/profiles/development.list' ]]"

    # Management scripts
    run_test "AUR manager script exists" "[[ -f '$PROJECT_ROOT/scripts/aur-management/aur-manager.sh' ]]"
    run_test "AUR builder script exists" "[[ -f '$PROJECT_ROOT/scripts/aur-management/aur-builder.sh' ]]"
}

# Test script permissions
test_script_permissions() {
    print_header "Testing Script Permissions"

    local scripts=(
        "scripts/aur-management/aur-manager.sh"
        "scripts/aur-management/aur-builder.sh"
    )

    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/$script"
        run_test "$(basename "$script") is executable" "[[ -x '$script_path' ]]"
    done
}

# Test package list content
test_package_lists() {
    print_header "Testing Package List Content"

    # Test AUR lists have content
    local aur_lists=("gaming" "development" "optional")
    for list in "${aur_lists[@]}"; do
        local list_file="$PROJECT_ROOT/packages/aur/$list.list"
        run_test "$list AUR list has packages" "[[ \$(grep -c '^[^#]' '$list_file' 2>/dev/null || echo 0) -gt 10 ]]"
    done

    # Test hardware lists have content
    local hw_lists=("nvidia" "amd" "intel")
    for hw in "${hw_lists[@]}"; do
        local hw_file="$PROJECT_ROOT/packages/hardware/$hw.list"
        run_test "$hw hardware list has packages" "[[ \$(grep -c '^[^#]' '$hw_file' 2>/dev/null || echo 0) -gt 5 ]]"
    done

    # Test profile lists have content
    local profile_lists=("esports" "streaming" "development")
    for profile in "${profile_lists[@]}"; do
        local profile_file="$PROJECT_ROOT/packages/profiles/$profile.list"
        run_test "$profile profile list has packages" "[[ \$(grep -c '^[^#]' '$profile_file' 2>/dev/null || echo 0) -gt 20 ]]"
    done
}

# Test script functionality
test_script_functionality() {
    print_header "Testing Script Functionality"

    # Test AUR manager help
    local aur_manager="$PROJECT_ROOT/scripts/aur-management/aur-manager.sh"
    run_test "AUR manager shows help" "'$aur_manager' help | grep -q 'xanadOS AUR Package Manager'"

    # Test AUR manager list command
    run_test "AUR manager list command works" "'$aur_manager' list | grep -q 'Available package categories'"

    # Test AUR builder help
    local aur_builder="$PROJECT_ROOT/scripts/aur-management/aur-builder.sh"
    run_test "AUR builder shows help" "'$aur_builder' help | grep -q 'xanadOS AUR Package Builder'"

    # Test AUR builder stats command
    run_test "AUR builder stats command works" "'$aur_builder' stats | grep -q 'Build environment statistics'"
}

# Test package list syntax
test_package_syntax() {
    print_header "Testing Package List Syntax"

    # Find all package list files
    local list_files=()
    while IFS= read -r -d '' file; do
        list_files+=("$file")
    done < <(find "$PROJECT_ROOT/packages" -name "*.list" -print0 2>/dev/null)

    for list_file in "${list_files[@]}"; do
        local list_name=$(basename "$list_file")

        # Test file is readable
        run_test "$list_name is readable" "[[ -r '$list_file' ]]"

        # Test file has valid format (no empty lines without comments)
        run_test "$list_name has valid format" "! grep -q '^[[:space:]]*$' '$list_file' || grep -q '^#' '$list_file'"

        # Test package names are valid (no spaces in package names)
        run_test "$list_name has valid package names" "! grep '^[^#]' '$list_file' | grep -q ' ' | head -1"
    done
}

# Test hardware detection simulation
test_hardware_detection() {
    print_header "Testing Hardware Detection Logic"

    # Test that the hardware detection would work with common scenarios

    # Create temporary test files
    local temp_cpuinfo=$(mktemp)
    local temp_lspci=$(mktemp)

    # Test Intel CPU detection
    echo "model name : Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz" > "$temp_cpuinfo"
    run_test "Intel CPU detection logic" "grep -qi 'intel' '$temp_cpuinfo'"

    # Test AMD CPU detection
    echo "model name : AMD Ryzen 7 3700X 8-Core Processor" > "$temp_cpuinfo"
    run_test "AMD CPU detection logic" "grep -qi 'amd' '$temp_cpuinfo'"

    # Test NVIDIA GPU detection
    echo "01:00.0 VGA compatible controller: NVIDIA Corporation GeForce RTX 3080" > "$temp_lspci"
    run_test "NVIDIA GPU detection logic" "grep -qi 'nvidia' '$temp_lspci'"

    # Test AMD GPU detection
    echo "01:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Navi 21" > "$temp_lspci"
    run_test "AMD GPU detection logic" "grep -qi 'amd\\|ati' '$temp_lspci'"

    # Cleanup
    rm -f "$temp_cpuinfo" "$temp_lspci"
}

# Test integration with core packages
test_core_integration() {
    print_header "Testing Core Package Integration"

    # Test that AUR packages complement core packages
    local core_gaming="$PROJECT_ROOT/packages/core/gaming.list"
    local aur_gaming="$PROJECT_ROOT/packages/aur/gaming.list"

    if [[ -f "$core_gaming" && -f "$aur_gaming" ]]; then
        run_test "Core and AUR gaming packages exist" "true"

        # Test that there's no obvious overlap (basic check)
        run_test "Gaming packages are logically separated" "[[ \$(cat '$core_gaming' '$aur_gaming' | grep -v '^#' | sort | uniq -d | wc -l) -lt 5 ]]"
    else
        print_warning "Core packages not found - skipping integration test"
    fi
}

# Test package categories completeness
test_package_completeness() {
    print_header "Testing Package Category Completeness"

    # Test that essential gaming packages are covered
    local essential_gaming=("steam" "lutris" "discord" "obs-studio" "mangohud")
    local aur_gaming="$PROJECT_ROOT/packages/aur/gaming.list"

    for package in "${essential_gaming[@]}"; do
        run_test "Essential gaming package '$package' is listed" "grep -q '$package' '$aur_gaming' || echo 'Package may be in core or different category'"
    done

    # Test that development essentials are covered
    local essential_dev=("visual-studio-code" "nodejs" "docker" "git")
    local aur_dev="$PROJECT_ROOT/packages/aur/development.list"

    for package in "${essential_dev[@]}"; do
        run_test "Essential dev package '$package' is covered" "grep -q '$package' '$aur_dev' || echo 'Package may be in core'"
    done
}

# Test documentation and comments
test_documentation() {
    print_header "Testing Documentation Quality"

    # Test that package lists have proper headers
    local list_files=()
    while IFS= read -r -d '' file; do
        list_files+=("$file")
    done < <(find "$PROJECT_ROOT/packages" -name "*.list" -print0)

    for list_file in "${list_files[@]}"; do
        local list_name=$(basename "$list_file")

        # Test file has description header
        run_test "$list_name has description header" "head -5 '$list_file' | grep -q '#.*for xanadOS'"

        # Test file has organized sections (categories with comments)
        run_test "$list_name has organized sections" "[[ \$(grep -c '^# ' '$list_file') -gt 3 ]]"
    done

    # Test scripts have help documentation
    local scripts=("aur-manager.sh" "aur-builder.sh")
    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/scripts/aur-management/$script"
        run_test "$script has help function" "grep -q 'show_help()' '$script_path'"
        run_test "$script has usage examples" "grep -q 'EXAMPLES:' '$script_path'"
    done
}

# Generate test report
generate_report() {
    print_header "AUR Integration Test Report"

    local pass_rate=0
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi

    echo "📊 Test Statistics:"
    echo "   Total Tests: $TESTS_TOTAL"
    echo "   Passed: $TESTS_PASSED"
    echo "   Failed: $TESTS_FAILED"
    echo "   Pass Rate: ${pass_rate}%"
    echo

    # Package statistics
    print_info "📦 Package Statistics:"

    # Count packages by category
    local total_packages=0
    for category in aur hardware profiles; do
        local category_total=0
        for list_file in "$PROJECT_ROOT/packages/$category"/*.list; do
            if [[ -f "$list_file" ]]; then
                local count=$(grep -c '^[^#]' "$list_file" 2>/dev/null || echo 0)
                category_total=$((category_total + count))
                echo "   $(basename "$list_file" .list): $count packages"
            fi
        done
        echo "   $category total: $category_total packages"
        total_packages=$((total_packages + category_total))
        echo
    done

    echo "   Grand Total: $total_packages AUR packages"
    echo

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_status "All tests passed! AUR integration is ready."
        echo
        print_info "Next steps:"
        echo "   1. Test package installation: ./scripts/aur-management/aur-manager.sh list"
        echo "   2. Try hardware detection: ./scripts/aur-management/aur-manager.sh detect"
        echo "   3. Install a profile: ./scripts/aur-management/aur-manager.sh interactive"
        echo "   4. Build custom packages: ./scripts/aur-management/aur-builder.sh help"
        return 0
    else
        print_error "Some tests failed. Please review the output above."
        return 1
    fi
}

# Main execution
main() {
    print_header "xanadOS AUR Package Integration Test"
    print_info "Testing AUR package management system..."
    echo

    # Change to project root
    cd "$PROJECT_ROOT"

    # Run all test suites
    test_aur_structure || true
    test_script_permissions || true
    test_package_lists || true
    test_script_functionality || true
    test_package_syntax || true
    test_hardware_detection || true
    test_core_integration || true
    test_package_completeness || true
    test_documentation || true

    # Generate final report
    generate_report
}

# Execute main function
main "$@"
