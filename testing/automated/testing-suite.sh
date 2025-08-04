#!/bin/bash
# xanadOS Performance Testing Suite
# Comprehensive system performance testing and validation

# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/directories.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/enhanced-testing.sh"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$(get_results_dir "testing" false)"  # Use standardized function
LOG_FILE="$(get_log_dir false)/$(get_log_filename "testing-suite")"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█            🧪 xanadOS Performance Testing Suite 🧪           █"
    echo "█                                                              █"
    echo "█        Unified Performance Testing & Validation Hub          █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

