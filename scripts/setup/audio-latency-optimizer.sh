#!/bin/bash
# xanadOS Audio Latency Optimization Script
# Optimizes PipeWire and audio stack for low-latency gaming


# Source xanadOS shared libraries
source "../lib/common.sh"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PIPEWIRE_CONFIG_DIR="$HOME/.config/pipewire"
PIPEWIRE_SYSTEM_CONFIG="/etc/pipewire"
WIREPLUMBER_CONFIG_DIR="$HOME/.config/wireplumber"
LOG_FILE="/var/log/xanados-audio-optimization.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█          🎵 xanadOS Audio Latency Optimization 🎵           █"
    echo "█                                                              █"
    echo "█         Low-Latency Audio for Gaming Performance            █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

