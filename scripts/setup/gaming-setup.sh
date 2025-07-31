#!/bin/bash
# xanadOS Master Gaming Setup Script
# Complete automated gaming software stack installation


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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/xanados-gaming-setup.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█                    🎮 xanadOS Gaming Setup 🎮                █"
    echo "█                                                              █"
    echo "█              Complete Gaming Software Stack                  █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

