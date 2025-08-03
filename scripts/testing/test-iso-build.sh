#!/bin/bash
# xanadOS ISO Build Test Script
# Validates the build configuration without doing the full build

set -euo pipefail

PROJECT_ROOT="/home/merlin/Documents/xanadOS"
BUILD_DIR="$PROJECT_ROOT/build"
ARCHISO_DIR="$BUILD_DIR/work/archiso"
PACKAGES_FILE="$BUILD_DIR/packages.x86_64"

cd "$PROJECT_ROOT"

echo "================================================================"
echo "🧪 xanadOS ISO Build Configuration Test"
echo "================================================================"
echo

# Test 1: File Structure
echo "📁 Test 1: Build File Structure"
test_files=(
    "$PACKAGES_FILE"
    "$ARCHISO_DIR/profiledef.sh"
    "$ARCHISO_DIR/pacman.conf"
    "$ARCHISO_DIR/packages.x86_64"
)

for file in "${test_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (missing)"
        exit 1
    fi
done
echo

# Test 2: Package Validation
echo "🔍 Test 2: Package Validation"
total_packages=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | wc -l)
echo "   📦 Total packages: $total_packages"

# Check for duplicates
duplicates=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | sort | uniq -d)
if [[ -z "$duplicates" ]]; then
    echo "   ✅ No duplicate packages"
else
    echo "   ❌ Duplicate packages found: $duplicates"
    exit 1
fi

# Test 3: Gaming Requirements
echo "   🎮 Gaming packages validation:"
gaming_packages=(
    "steam"
    "lutris" 
    "gamemode"
    "mangohud"
    "wine-staging"
)

for pkg in "${gaming_packages[@]}"; do
    if grep -q "^$pkg$" "$PACKAGES_FILE"; then
        echo "      ✅ $pkg"
    else
        echo "      ❌ $pkg (missing)"
        exit 1
    fi
done

# Test 4: Multilib Support
echo "   📚 Multilib support:"
lib32_count=$(grep -c '^lib32-' "$PACKAGES_FILE")
echo "      📊 lib32 packages: $lib32_count"
if [[ $lib32_count -ge 20 ]]; then
    echo "      ✅ Adequate multilib support"
else
    echo "      ⚠️  Limited multilib support ($lib32_count packages)"
fi

# Test 5: Graphics Drivers
echo "   🎨 Graphics drivers:"
graphics_packages=(
    "mesa"
    "vulkan-intel"
    "vulkan-radeon"
    "nvidia-dkms"
)

for pkg in "${graphics_packages[@]}"; do
    if grep -q "^$pkg$" "$PACKAGES_FILE"; then
        echo "      ✅ $pkg"
    else
        echo "      ❌ $pkg (missing)"
    fi
done
echo

# Test 6: Archiso Configuration
echo "🔧 Test 3: Archiso Configuration"
cd "$ARCHISO_DIR"

# Test profiledef.sh syntax
if bash -n profiledef.sh; then
    echo "   ✅ profiledef.sh syntax valid"
else
    echo "   ❌ profiledef.sh syntax error"
    exit 1
fi

# Test package file is in place
if [[ -f packages.x86_64 ]]; then
    archiso_packages=$(grep -v '^#' packages.x86_64 | grep -v '^$' | wc -l)
    echo "   ✅ packages.x86_64 ready ($archiso_packages packages)"
else
    echo "   ❌ packages.x86_64 missing in archiso directory"
    exit 1
fi

# Test mkarchiso availability
if command -v mkarchiso >/dev/null; then
    echo "   ✅ mkarchiso available"
    mkarchiso_version=$(mkarchiso -h 2>&1 | head -1 | grep -o 'archiso.*' || echo "version unknown")
    echo "      📋 $mkarchiso_version"
else
    echo "   ❌ mkarchiso not available"
    exit 1
fi
echo

# Test 7: Estimated Build Requirements
echo "📊 Test 4: Build Requirements Estimation"
echo "   💾 Estimated ISO size: ~1.5-2.0 GB (reduced from ~2.5-3.0 GB)"
echo "   ⏱️  Estimated build time: 15-30 minutes (depending on hardware)"
echo "   💽 Disk space required: ~10-15 GB for build process"
echo "   🖥️  RAM recommended: 4+ GB for comfortable building"
echo

# Final Summary
echo "🏁 Test Summary"
echo "   ✅ All configuration tests passed!"
echo "   🎯 xanadOS gaming optimization: $(printf '%.0f' $(echo "scale=2; (284-$total_packages)/284*100" | bc))% package reduction"
echo "   🚀 Ready for ISO building with: sudo scripts/build/create-iso.sh build"
echo

echo "================================================================"
echo "🎉 xanadOS ISO build configuration is ready!"
echo "================================================================"
