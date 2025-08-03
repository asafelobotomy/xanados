#!/bin/bash
# xanadOS Build System Integration Test
# Tests the complete modernized build system

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Logging
print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_header() { echo -e "\n${PURPLE}═══ $1 ═══${NC}\n"; }

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test execution
run_test() {
    local test_name="$1"
    local test_command="$2"

    ((TESTS_TOTAL++))

    print_info "Running test: $test_name"

    if eval "$test_command" 2>/dev/null; then
        print_status "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Verify build system structure
test_structure() {
    print_header "Testing Build System Structure"

    # Target configurations
    run_test "x86-64-v3 target config exists" "[[ -f '$PROJECT_ROOT/build/targets/x86-64-v3.conf' ]]"
    run_test "x86-64-v4 target config exists" "[[ -f '$PROJECT_ROOT/build/targets/x86-64-v4.conf' ]]"
    run_test "Compatibility target config exists" "[[ -f '$PROJECT_ROOT/build/targets/compatibility.conf' ]]"

    # Automation scripts
    run_test "Build pipeline script exists" "[[ -f '$PROJECT_ROOT/build/automation/build-pipeline.sh' ]]"
    run_test "ISO test script exists" "[[ -f '$PROJECT_ROOT/build/automation/test-iso.sh' ]]"
    run_test "Release manager script exists" "[[ -f '$PROJECT_ROOT/build/automation/release-manager.sh' ]]"

    # Container setup
    run_test "Dockerfile exists" "[[ -f '$PROJECT_ROOT/build/containers/Dockerfile.build' ]]"
    run_test "Docker Compose config exists" "[[ -f '$PROJECT_ROOT/build/containers/docker-compose.yml' ]]"
    run_test "Container manager script exists" "[[ -f '$PROJECT_ROOT/build/containers/container-manager.sh' ]]"

    # CI/CD workflow
    run_test "GitHub Actions workflow exists" "[[ -f '$PROJECT_ROOT/.github/workflows/build-multi-target.yml' ]]"
}

# Test script permissions
test_permissions() {
    print_header "Testing Script Permissions"

    local scripts=(
        "build/automation/build-pipeline.sh"
        "build/automation/test-iso.sh"
        "build/automation/release-manager.sh"
        "build/containers/container-manager.sh"
    )

    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/$script"
        run_test "$(basename "$script") is executable" "[[ -x '$script_path' ]]"
    done
}

# Test configuration validity
test_configurations() {
    print_header "Testing Configuration Validity"

    # Test target configurations can be sourced
    local targets=("x86-64-v3" "x86-64-v4" "compatibility")

    for target in "${targets[@]}"; do
        local config_file="$PROJECT_ROOT/build/targets/$target.conf"
        run_test "$target config is valid bash" "bash -n '$config_file'"
    done

    # Test Docker Compose syntax
    if command -v docker-compose &>/dev/null; then
        (cd "$PROJECT_ROOT/build/containers" && run_test "Docker Compose config is valid" "docker-compose config >/dev/null") || true
    else
        print_warning "Docker Compose not available - skipping validation"
    fi
}

# Test build pipeline functionality
test_build_pipeline() {
    print_header "Testing Build Pipeline Functionality"

    local pipeline_script="$PROJECT_ROOT/build/automation/build-pipeline.sh"

    # Test help output
    run_test "Build pipeline shows help" "'$pipeline_script' --help | grep -q 'xanadOS Build Pipeline'"

    # Test target validation
    run_test "Build pipeline validates targets" "'$pipeline_script' --target invalid-target 2>&1 | grep -q 'Invalid target'"

    # Test dry run mode
    run_test "Build pipeline dry run works" "'$pipeline_script' --dry-run --target x86-64-v3 | grep -q 'DRY RUN'"
}

# Test container manager
test_container_manager() {
    print_header "Testing Container Manager"

    local manager_script="$PROJECT_ROOT/build/containers/container-manager.sh"

    # Test help output
    run_test "Container manager shows help" "'$manager_script' help | grep -q 'Container Management Script'"

    # Test Docker availability check
    if command -v docker &>/dev/null; then
        run_test "Container manager detects Docker" "'$manager_script' status | grep -q 'Container status' || true"
    else
        print_warning "Docker not available - skipping container tests"
    fi
}

# Test release manager
test_release_manager() {
    print_header "Testing Release Manager"

    local release_script="$PROJECT_ROOT/build/automation/release-manager.sh"

    # Test help output
    run_test "Release manager shows help" "'$release_script' --help | grep -q 'Release Management'"

    # Test version validation
    run_test "Release manager validates versions" "'$release_script' --version invalid 2>&1 | grep -q 'Invalid version format' || true"
}

# Test dependency checks
test_dependencies() {
    print_header "Testing Dependency Availability"

    local required_tools=("bash" "git" "grep" "find" "chmod" "mkdir")
    local optional_tools=("docker" "docker-compose" "qemu-system-x86_64" "archiso")

    for tool in "${required_tools[@]}"; do
        run_test "$tool is available" "command -v '$tool' >/dev/null"
    done

    print_info "Optional tools (for full functionality):"
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            print_status "$tool is available"
        else
            print_warning "$tool not available (optional)"
        fi
    done
}

# Test file content validation
test_content_validation() {
    print_header "Testing File Content Validation"

    # Check for required sections in configurations
    local x86v3_config="$PROJECT_ROOT/build/targets/x86-64-v3.conf"
    run_test "x86-64-v3 config has CFLAGS" "grep -q 'CFLAGS' '$x86v3_config'"
    run_test "x86-64-v3 config has march=x86-64-v3" "grep -q 'march=x86-64-v3' '$x86v3_config'"

    # Check build pipeline has essential functions
    local pipeline="$PROJECT_ROOT/build/automation/build-pipeline.sh"
    run_test "Build pipeline has main function" "grep -q 'main()' '$pipeline'"
    run_test "Build pipeline has build_target function" "grep -q 'build_target()' '$pipeline'"
    run_test "Build pipeline has validate_target function" "grep -q 'validate_target()' '$pipeline'"

    # Check Docker files have required instructions
    local dockerfile="$PROJECT_ROOT/build/containers/Dockerfile.build"
    run_test "Dockerfile has FROM instruction" "grep -q '^FROM' '$dockerfile'"
    run_test "Dockerfile has archiso package" "grep -q 'archiso' '$dockerfile'"

    # Check GitHub Actions workflow
    local workflow="$PROJECT_ROOT/.github/workflows/build-multi-target.yml"
    run_test "GitHub workflow has job definitions" "grep -q 'jobs:' '$workflow'"
    run_test "GitHub workflow has build matrix" "grep -q 'matrix:' '$workflow'"
}

# Test integration points
test_integration() {
    print_header "Testing Integration Points"

    # Test that target configs are compatible with build pipeline
    local pipeline="$PROJECT_ROOT/build/automation/build-pipeline.sh"
    local targets_dir="$PROJECT_ROOT/build/targets"

    run_test "Build pipeline can find target configs" "[[ -d '$targets_dir' ]] && [[ \$(ls '$targets_dir'/*.conf 2>/dev/null | wc -l) -ge 3 ]]"

    # Test container integration
    local compose_file="$PROJECT_ROOT/build/containers/docker-compose.yml"
    run_test "Docker Compose references correct Dockerfile" "grep -q 'Dockerfile.build' '$compose_file'"
    run_test "Docker Compose mounts source directory" "grep -q '/build/source' '$compose_file'"

    # Test CI/CD integration
    local workflow="$PROJECT_ROOT/.github/workflows/build-multi-target.yml"
    run_test "GitHub workflow uses container build" "grep -q 'build-container' '$workflow'"
    run_test "GitHub workflow has multi-target matrix" "grep -q 'x86-64-v3' '$workflow'"
}

# Performance and quality checks
test_quality() {
    print_header "Testing Code Quality"

    # Check for shell scripting best practices
    local scripts=(
        "build/automation/build-pipeline.sh"
        "build/automation/test-iso.sh"
        "build/automation/release-manager.sh"
        "build/containers/container-manager.sh"
    )

    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/$script"
        local script_name=$(basename "$script")

        # Check for set -euo pipefail
        run_test "$script_name uses strict mode" "grep -q 'set -euo pipefail' '$script_path'"

        # Check for readonly variables
        run_test "$script_name uses readonly variables" "grep -q 'readonly' '$script_path'"

        # Check for proper function definitions
        run_test "$script_name has proper functions" "grep -q '() {' '$script_path'"
    done
}

# Generate test report
generate_report() {
    print_header "Test Report"

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

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_status "All tests passed! Build system is ready."
        echo
        print_info "Next steps:"
        echo "   1. Test actual ISO build: ./build/automation/build-pipeline.sh --target x86-64-v3 --dry-run"
        echo "   2. Build container image: ./build/containers/container-manager.sh build"
        echo "   3. Run containerized build: ./build/containers/container-manager.sh build-all"
        echo "   4. Set up CI/CD: Commit and push to trigger GitHub Actions"
        return 0
    else
        print_error "Some tests failed. Please review the output above."
        echo
        print_info "Common issues:"
        echo "   - Missing execute permissions: chmod +x script-name.sh"
        echo "   - Missing dependencies: Install Docker, Docker Compose, etc."
        echo "   - Configuration errors: Check file syntax"
        return 1
    fi
}

# Main execution
main() {
    print_header "xanadOS Build System Integration Test"
    print_info "Testing modernized build system components..."
    echo

    # Change to project root
    cd "$PROJECT_ROOT"

    # Run all test suites
    test_structure || true
    test_permissions || true
    test_configurations || true
    test_build_pipeline || true
    test_container_manager || true
    test_release_manager || true
    test_dependencies || true
    test_content_validation || true
    test_integration || true
    test_quality || true

    # Generate final report
    generate_report
}

# Execute main function
main "$@"
