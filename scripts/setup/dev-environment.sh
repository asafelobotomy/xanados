#!/bin/bash
# xanadOS Development Environment Setup Script
# This script sets up the development environment for building xanadOS


# Source xanadOS shared libraries
source "../lib/common.sh"

set -e  # Exit on any error

echo "=== xanadOS Development Environment Setup ==="
echo "Setting up development environment for xanadOS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
