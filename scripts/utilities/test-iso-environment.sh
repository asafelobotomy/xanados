#!/bin/bash
# xanadOS ISO Build Environment Test
# Quick verification of build environment without requiring root

set -euo pipefail

echo "🧪 xanadOS ISO Build Environment Test"
echo "======================================"

# Check essential tools
echo "📋 Checking essential tools..."
tools=("mkarchiso" "pacman" "makepkg" "git")
for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "✓ $tool: $(which $tool)"
    else
        echo "✗ $tool: NOT FOUND"
    fi
done

# Check disk space
echo ""
echo "💾 Checking available disk space..."
df -h /home/vm/Documents/xanadOS

# Check archiso templates
echo ""
echo "📦 Checking archiso templates..."
if [[ -d /usr/share/archiso/configs/releng ]]; then
    echo "✓ archiso releng template found"
    ls -la /usr/share/archiso/configs/releng/ | head -10
else
    echo "✗ archiso releng template not found"
fi

# Check our xanadOS configuration
echo ""
echo "⚙️  Checking xanadOS configuration..."
if [[ -f /home/vm/Documents/xanadOS/build/packages.x86_64 ]]; then
    echo "✓ xanadOS package list found"
    echo "📊 Package count: $(wc -l < /home/vm/Documents/xanadOS/build/packages.x86_64)"
else
    echo "✗ xanadOS package list not found"
fi

if [[ -d /home/vm/Documents/xanadOS/configs ]]; then
    echo "✓ xanadOS configurations found"
    find /home/vm/Documents/xanadOS/configs -name "*.conf" | wc -l | xargs echo "📊 Config files:"
else
    echo "✗ xanadOS configurations not found"
fi

# Check build targets
echo ""
echo "🎯 Checking build targets..."
for target in x86-64-v3 x86-64-v4 compatibility; do
    if [[ -f "/home/vm/Documents/xanadOS/build/targets/${target}.conf" ]]; then
        echo "✓ $target target configuration found"
    else
        echo "✗ $target target configuration missing"
    fi
done

# Test CPU features
echo ""
echo "🖥️  Checking CPU features..."
if [[ -f /proc/cpuinfo ]]; then
    cpu_flags=$(grep '^flags' /proc/cpuinfo | head -1 | cut -d: -f2 || echo "none")
    if echo "$cpu_flags" | grep -q "avx2"; then
        echo "✓ CPU supports x86-64-v3 (AVX2 found)"
    else
        echo "⚠ CPU may not support x86-64-v3 optimizations"
    fi

    if echo "$cpu_flags" | grep -q "avx512f"; then
        echo "✓ CPU supports x86-64-v4 (AVX-512 found)"
    else
        echo "ℹ CPU does not support x86-64-v4 optimizations"
    fi
else
    echo "⚠ Cannot detect CPU features"
fi

echo ""
echo "🎉 Environment test complete!"
echo ""
echo "To build the ISO, run:"
echo "  sudo ./build/automation/build-pipeline.sh --target x86-64-v3"
echo ""
echo "💡 Note: ISO creation requires root privileges for mkarchiso"
