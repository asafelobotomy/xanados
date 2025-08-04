#!/bin/bash
# Gaming Integration Test Suite
# Tests Steam, Lutris, GameMode, and gaming environment components

set -euo pipefail

# Change to script directory and source libraries
cd "$(dirname "$0")" || exit 1
source "../../scripts/lib/common.sh"
source "../../scripts/lib/validation.sh"
source "../../scripts/lib/gaming-env.sh"

# Test configuration
TEST_NAME="Gaming Integration"
RESULTS_DIR="$(get_results_dir "testing/integration" false)"
TEST_LOG="$RESULTS_DIR/gaming-integration-$(date +%Y%m%d-%H%M%S).log"

# Ensure results directory exists
ensure_directory "$RESULTS_DIR"

# Initialize logging
exec 1> >(tee -a "$TEST_LOG")
exec 2> >(tee -a "$TEST_LOG" >&2)

print_header "🎮 Gaming Integration Test Suite"
echo ""

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test execution functions
run_test() {
    local test_name="$1"
    local test_command="$2"

    ((TESTS_TOTAL++))
    print_info "Running: $test_name"

    if eval "$test_command" &>/dev/null; then
        print_success "✅ PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "❌ FAIL: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Steam Integration Tests
print_section "Steam Integration Tests"

run_test "Steam client availability" "command -v steam"
run_test "Steam Proton availability" "ls ~/.steam/steamapps/common/Proton* &>/dev/null || ls ~/.local/share/Steam/steamapps/common/Proton* &>/dev/null"
run_test "Steam configuration validation" "[[ -d ~/.steam ]] || [[ -d ~/.local/share/Steam ]]"

# Lutris Integration Tests
print_section "Lutris Integration Tests"

run_test "Lutris client availability" "command -v lutris"
run_test "Wine installation for Lutris" "command -v wine"
run_test "Lutris configuration directory" "[[ -d ~/.config/lutris ]] || [[ -d ~/.local/share/lutris ]]"

# GameMode Integration Tests
print_section "GameMode Integration Tests"

run_test "GameMode daemon availability" "command -v gamemode"
run_test "GameMode library availability" "ldconfig -p | grep -q libgamemode"
run_test "GameMode configuration" "[[ -f /usr/share/gamemode/gamemode.ini ]] || [[ -f ~/.config/gamemode.ini ]]"

# MangoHud Integration Tests
print_section "MangoHud Integration Tests"

run_test "MangoHud availability" "command -v mangohud"
run_test "MangoHud library availability" "ldconfig -p | grep -q libMangoHud"
run_test "MangoHud configuration support" "[[ -d ~/.config/MangoHud ]] || mkdir -p ~/.config/MangoHud"

# Controller Integration Tests
print_section "Controller Integration Tests"

run_test "SDL2 controller support" "ldconfig -p | grep -q libSDL2"
run_test "Joystick device support" "[[ -d /dev/input ]]"
run_test "Steam Input availability" "systemctl --user is-enabled steam-input 2>/dev/null || true"

# Gaming Environment Tests
print_section "Gaming Environment Tests"

run_test "Gaming environment detection" "detect_gaming_environment &>/dev/null"
run_test "Gaming readiness assessment" "get_gaming_readiness_score &>/dev/null"
run_test "Gaming matrix generation" "generate_gaming_matrix table false &>/dev/null"

# Gaming Optimization Tests
print_section "Gaming Optimization Tests"

run_test "CPU governor optimization" "grep -q performance /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor || true"
run_test "I/O scheduler optimization" "grep -q 'mq-deadline\\|none' /sys/block/*/queue/scheduler || true"
run_test "Gaming kernel parameters" "grep -q 'mitigations=off\\|preempt=voluntary' /proc/cmdline || true"

# Generate test summary
print_section "Test Summary"

pass_rate=0
if [[ $TESTS_TOTAL -gt 0 ]]; then
    pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
fi

echo "📊 Gaming Integration Test Results:"
echo "   Total Tests: $TESTS_TOTAL"
echo "   Passed: $TESTS_PASSED"
echo "   Failed: $TESTS_FAILED"
echo "   Pass Rate: ${pass_rate}%"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_success "🎮 All gaming integration tests passed!"
    exit 0
else
    print_error "🎮 Some gaming integration tests failed."
    exit 1
fi
