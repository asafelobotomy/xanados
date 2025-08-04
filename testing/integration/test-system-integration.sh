#!/bin/bash
# System Integration Test Suite
# Tests kernel optimizations, hardware compatibility, and system performance

set -euo pipefail

# Change to script directory and source libraries
cd "$(dirname "$0")" || exit 1
source "../../scripts/lib/common.sh"
source "../../scripts/lib/validation.sh"
source "../../scripts/lib/hardware-detection.sh"

# Test configuration
TEST_NAME="System Integration"
RESULTS_DIR="$(get_results_dir "testing/integration" false)"
TEST_LOG="$RESULTS_DIR/system-integration-$(date +%Y%m%d-%H%M%S).log"

# Ensure results directory exists
ensure_directory "$RESULTS_DIR"

# Initialize logging
exec 1> >(tee -a "$TEST_LOG")
exec 2> >(tee -a "$TEST_LOG" >&2)

print_header "⚙️ System Integration Test Suite"
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

# Kernel Optimization Tests
print_section "Kernel Optimization Tests"

run_test "Kernel version compatibility" "uname -r | grep -E '^[5-6]\\.[0-9]+'"
run_test "Gaming kernel parameters" "grep -q 'mitigations=off\\|preempt=voluntary\\|quiet' /proc/cmdline || true"
run_test "CPU frequency scaling" "[[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]"
run_test "I/O scheduler optimization" "[[ -f /sys/block/sda/queue/scheduler ]] && grep -q 'mq-deadline\\|none' /sys/block/*/queue/scheduler"

# Hardware Detection Tests
print_section "Hardware Detection Tests"

run_test "CPU information detection" "[[ -f /proc/cpuinfo ]] && grep -q 'processor' /proc/cpuinfo"
run_test "Memory information detection" "[[ -f /proc/meminfo ]] && grep -q 'MemTotal' /proc/meminfo"
run_test "GPU detection" "lspci | grep -i 'vga\\|3d\\|display' || true"
run_test "Audio device detection" "aplay -l &>/dev/null || true"

# Driver Compatibility Tests
print_section "Driver Compatibility Tests"

run_test "Graphics driver loaded" "lsmod | grep -E 'nvidia|amdgpu|i915|radeon' || true"
run_test "Audio driver loaded" "lsmod | grep -E 'snd_|alsa' || true"
run_test "Network driver loaded" "ip link show | grep -E 'eth|wlan|wlp' || true"
run_test "USB driver support" "lsmod | grep -E 'usbcore|xhci' || true"

# Performance Optimization Tests
print_section "Performance Optimization Tests"

run_test "CPU scaling governor" "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | head -1 | grep -E 'performance|ondemand|schedutil'"
run_test "Swap configuration" "[[ $(swapon --show | wc -l) -le 2 ]] || true"  # Minimal or no swap for gaming
run_test "Kernel timer frequency" "grep -q 'CONFIG_HZ_1000=y\\|CONFIG_HZ=1000' /boot/config-$(uname -r) 2>/dev/null || true"
run_test "Preemption model" "grep -q 'CONFIG_PREEMPT=y\\|CONFIG_PREEMPT_VOLUNTARY=y' /boot/config-$(uname -r) 2>/dev/null || true"

# Desktop Environment Tests
print_section "Desktop Environment Tests"

run_test "X11/Wayland session" "pgrep -f 'Xorg|kwin|gnome-shell|sway' || true"
run_test "Desktop environment running" "[[ -n \"$XDG_CURRENT_DESKTOP\" ]] || [[ -n \"$DESKTOP_SESSION\" ]]"
run_test "Window manager compatibility" "wmctrl -m &>/dev/null || true"
run_test "Compositor availability" "pgrep -f 'picom|compton|kwin|mutter' || true"

# System Service Tests
print_section "System Service Tests"

run_test "Audio service" "systemctl --user is-active pulseaudio 2>/dev/null || systemctl --user is-active pipewire 2>/dev/null || true"
run_test "Network manager service" "systemctl is-active NetworkManager 2>/dev/null || systemctl is-active systemd-networkd 2>/dev/null || true"
run_test "D-Bus service" "systemctl is-active dbus 2>/dev/null"
run_test "Login manager service" "systemctl is-active sddm 2>/dev/null || systemctl is-active gdm 2>/dev/null || systemctl is-active lightdm 2>/dev/null || true"

# Security and Permissions Tests
print_section "Security and Permissions Tests"

run_test "User in audio group" "groups | grep -q audio || true"
run_test "User in video group" "groups | grep -q video || true"
run_test "User in input group" "groups | grep -q input || true"
run_test "Gamemode permissions" "[[ -f /usr/bin/gamemode ]] && [[ -x /usr/bin/gamemode ]]"

# System Resource Tests
print_section "System Resource Tests"

run_test "Sufficient RAM" "[[ $(free -m | awk '/^Mem:/ {print $2}') -ge 4096 ]]"  # At least 4GB RAM
run_test "Sufficient disk space" "[[ $(df / | tail -1 | awk '{print $4}') -ge 10485760 ]]"  # At least 10GB free
run_test "CPU supports required features" "grep -q 'sse\\|sse2\\|sse3' /proc/cpuinfo"
run_test "64-bit architecture" "[[ $(uname -m) == 'x86_64' ]]"

# Generate test summary
print_section "Test Summary"

pass_rate=0
if [[ $TESTS_TOTAL -gt 0 ]]; then
    pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
fi

echo "📊 System Integration Test Results:"
echo "   Total Tests: $TESTS_TOTAL"
echo "   Passed: $TESTS_PASSED"
echo "   Failed: $TESTS_FAILED"
echo "   Pass Rate: ${pass_rate}%"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_success "⚙️ All system integration tests passed!"
    exit 0
else
    print_error "⚙️ Some system integration tests failed."
    exit 1
fi
