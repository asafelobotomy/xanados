#!/bin/bash
# xanadOS Steam & Proton-GE Installation Script
# Automated setup for Steam with gaming optimizations


# Source xanadOS shared libraries
source "../lib/common.sh"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
STEAM_USER_DIR="$HOME/.local/share/Steam"
PROTON_GE_DIR="$STEAM_USER_DIR/compatibilitytools.d"
PROTON_GE_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"

