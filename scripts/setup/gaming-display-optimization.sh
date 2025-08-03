#!/bin/bash
# xanadOS Gaming Display Optimization Script

set -euo pipefail

source_display_configs() {
    # Source HDR configuration
    if [[ -f /etc/xanados/display/hdr-gaming.conf ]]; then
        source /etc/xanados/display/hdr-gaming.conf
        echo "HDR gaming configuration loaded"
    fi

    # Source VRR configuration
    if [[ -f /etc/xanados/display/vrr-gaming.conf ]]; then
        source /etc/xanados/display/vrr-gaming.conf
        echo "VRR gaming configuration loaded"
    fi
}

configure_gaming_display() {
    echo "Configuring gaming display optimizations..."

    # Enable VRR in KDE if available
    if command -v kwriteconfig5 &>/dev/null; then
        kwriteconfig5 --file kwinrc --group Compositing --key AllowTearing true
        kwriteconfig5 --file kwinrc --group Wayland --key InputMethod ""
        echo "KDE VRR configuration applied"
    fi

    # Configure X11 display settings for gaming
    if [[ -n "${DISPLAY:-}" ]]; then
        # Enable tearing for performance
        nvidia-settings -a "[gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=50" 2>/dev/null || true
        nvidia-settings -a "[gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=100" 2>/dev/null || true
    fi
}

main() {
    source_display_configs
    configure_gaming_display
    echo "Gaming display optimization completed"
}

main "$@"
