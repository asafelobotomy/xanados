#!/bin/bash
# Quick test for library loading
set -euo pipefail

echo "Testing enhanced libraries..."

# Test common.sh only first
echo "Loading common.sh..."
source "$(dirname "$0")/lib/common.sh"
echo "✓ Common library loaded"

# Test basic logging
log_info "Testing basic logging"
echo "✓ Basic logging works"

echo "All tests passed!"
