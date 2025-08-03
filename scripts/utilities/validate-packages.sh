#!/bin/bash
# Package validation script for xanadOS packages.x86_64
# Checks for common package naming issues and provides statistics

set -euo pipefail

PACKAGES_FILE="build/packages.x86_64"

echo "=== xanadOS Package List Validation ==="
echo

# Check if packages file exists
if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "❌ Error: $PACKAGES_FILE not found!"
    exit 1
fi

echo "📁 Package file: $PACKAGES_FILE"
echo

# Count packages
TOTAL_PACKAGES=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | wc -l)
echo "📦 Total packages: $TOTAL_PACKAGES"
echo

# Check for common issues
echo "🔍 Validation checks:"

# Check for duplicate packages
DUPLICATES=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | sort | uniq -d)
if [[ -n "$DUPLICATES" ]]; then
    echo "❌ Duplicate packages found:"
    echo "$DUPLICATES"
else
    echo "✅ No duplicate packages"
fi

# Check for packages with invalid characters
INVALID_CHARS=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | grep -E '[^a-zA-Z0-9_+-]' || true)
if [[ -n "$INVALID_CHARS" ]]; then
    echo "❌ Packages with invalid characters:"
    echo "$INVALID_CHARS"
else
    echo "✅ All package names use valid characters"
fi

# Show category breakdown
echo
echo "📊 Package categories:"
grep '^# ===' "$PACKAGES_FILE" | sed 's/^# === //' | sed 's/ ===//' | while read -r category; do
    echo "  • $category"
done

echo
echo "🎯 Key gaming packages included:"
echo "  • Steam: $(grep -q '^steam$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • Lutris: $(grep -q '^lutris$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • GameMode: $(grep -q '^gamemode$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • MangoHUD: $(grep -q '^mangohud$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • Wine: $(grep -q '^wine-staging$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • Vulkan: $(grep -q 'vulkan' "$PACKAGES_FILE" && echo "✅" || echo "❌")"

echo
echo "🔧 Essential lib32 packages:"
LIB32_COUNT=$(grep -c '^lib32-' "$PACKAGES_FILE" || echo "0")
echo "  • Count: $LIB32_COUNT lib32 packages"
echo "  • Gaming essentials: $(grep -q '^lib32-gamemode$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • Audio support: $(grep -q '^lib32-pipewire$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"
echo "  • Graphics support: $(grep -q '^lib32-mesa$' "$PACKAGES_FILE" && echo "✅" || echo "❌")"

echo
echo "🏁 Validation complete!"
echo "The optimized package list is ready for ISO building."
