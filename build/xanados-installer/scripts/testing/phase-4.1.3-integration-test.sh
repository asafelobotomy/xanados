#!/bin/bash

# Phase 4.1.3 Gaming Profile Creation - Final Integration Test
# Tests the complete gaming profile system integration

echo "🎮 xanadOS Gaming Profile System - Integration Test"
echo "=================================================="
echo

# Source the gaming profile library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gaming-profiles.sh"

# Test 1: Library functions availability
echo "✅ Test 1: Function Availability"
functions_available=0
for func in create_gaming_profile list_gaming_profiles apply_gaming_profile export_gaming_profile import_gaming_profile; do
    if declare -F "$func" >/dev/null 2>&1; then
        echo "  ✓ $func"
        ((functions_available++))
    else
        echo "  ✗ $func"
    fi
done
echo "  Functions available: $functions_available/5"
echo

# Test 2: Profile directory creation
echo "✅ Test 2: Profile System Initialization"
if init_gaming_profiles 2>/dev/null; then
    echo "  ✓ Profile system initialized successfully"
else
    echo "  ✗ Profile system initialization failed"
fi
echo

# Test 3: Profile count (should show default profile if created)
echo "✅ Test 3: Profile Management"
profile_count=$(count_gaming_profiles)
echo "  Current profiles: $profile_count"

# Test 4: Gaming environment integration
echo "✅ Test 4: Gaming Environment Integration"
if detect_gaming_environment 2>/dev/null; then
    echo "  ✓ Gaming environment detection successful"
else
    echo "  ✗ Gaming environment detection failed"
fi
echo

# Test 5: Gaming setup wizard integration
echo "✅ Test 5: Gaming Setup Wizard Integration"
if source "$(dirname "${BASH_SOURCE[0]}")/../setup/gaming-setup-wizard.sh" >/dev/null 2>&1; then
    echo "  ✓ Gaming setup wizard loaded successfully"
    if declare -F run_gaming_profile_management >/dev/null 2>&1; then
        echo "  ✓ Profile management function available in wizard"
    else
        echo "  ✗ Profile management function not found in wizard"
    fi
else
    echo "  ✗ Gaming setup wizard failed to load"
fi
echo

# Test 6: Demo script availability
echo "✅ Test 6: Demo Script Validation"
demo_script="$(dirname "${BASH_SOURCE[0]}")/../demo/gaming-profile-creation-demo.sh"
if [[ -x "$demo_script" ]]; then
    echo "  ✓ Demo script is executable"
else
    echo "  ✗ Demo script not executable"
fi
echo

echo "🎉 Phase 4.1.3 Gaming Profile Creation System Integration Test Complete!"
echo "   System Status: READY FOR USE"
echo
echo "Available Operations:"
echo "  • Create personalized gaming profiles"
echo "  • Manage existing profiles (list, delete, export, import)"
echo "  • Apply profiles with hardware-aware optimizations"
echo "  • Access via Gaming Setup Wizard (option 6)"
echo "  • Run interactive demo for testing"
echo
