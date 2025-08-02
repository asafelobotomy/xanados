#!/bin/bash
# xanadOS ISO Building Script
# This script creates a bootable xanadOS ISO based on Arch Linux


# Source xanadOS shared libraries
source "../lib/common.sh"

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
WORK_DIR="$BUILD_DIR/work"
OUT_DIR="$BUILD_DIR/out"
CACHE_DIR="$BUILD_DIR/cache"

# xanadOS Configuration
XANADOS_VERSION="0.1.0-alpha"
ISO_NAME="xanadOS"
ISO_LABEL="XANADOS"
ISO_FILENAME="${ISO_NAME}-${XANADOS_VERSION}-x86_64.iso"

# Function to print colored output
