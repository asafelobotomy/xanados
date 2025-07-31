#!/bin/bash
# xanadOS Lutris & Wine Installation Script
# Automated setup for Lutris with Wine optimizations


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
LUTRIS_CONFIG_DIR="$HOME/.config/lutris"
WINE_PREFIX_DIR="$HOME/Games/wine-prefixes"
DXVK_CACHE_DIR="$HOME/.cache/dxvk"

