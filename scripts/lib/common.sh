#!/bin/bash
# xanadOS Common Functions Library
# Shared utilities for all xanadOS shell scripts
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_COMMON_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_COMMON_LOADED="true"

# Color definitions for consistent output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'  # No Color

# Global configuration
readonly XANADOS_LIB_VERSION="1.0.0"

# Get the root directory of xanadOS project
get_xanados_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    
    # Walk up the directory tree to find xanadOS root
    local current_dir="$script_dir"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/README.md" ]] && [[ -d "$current_dir/scripts" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Fallback - assume we're in scripts subdirectory
    echo "$(cd "$script_dir/.." && pwd)"
}

# Export XANADOS_ROOT for use by other functions
readonly XANADOS_ROOT="${XANADOS_ROOT:-$(get_xanados_root)}"

# Basic print functions - replaces 72 duplicate definitions across scripts
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    if [[ "${XANADOS_DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

print_header() {
    echo ""
    echo -e "${CYAN}================================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
    echo ""
}

# Utility functions
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Check if running as root
is_root() {
    [[ "$EUID" -eq 0 ]]
}

# Check if running as regular user
check_not_root() {
    if is_root; then
        print_error "This script should not be run as root"
        print_warning "Please run as a regular user"
        return 1
    fi
    return 0
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Safe directory creation with error handling
safe_mkdir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [[ -z "$dir" ]]; then
        print_error "safe_mkdir: No directory specified"
        return 1
    fi
    
    if [[ -d "$dir" ]]; then
        print_debug "Directory already exists: $dir"
        return 0
    fi
    
    if mkdir -p "$dir" 2>/dev/null; then
        chmod "$mode" "$dir" 2>/dev/null || true
        print_debug "Created directory: $dir"
        return 0
    else
        print_error "Failed to create directory: $dir"
        return 1
    fi
}

# Safe file removal with validation
safe_remove() {
    local target="$1"
    
    if [[ -z "$target" ]]; then
        print_error "safe_remove: No target specified"
        return 1
    fi
    
    # Security check - prevent removal of important directories
    case "$target" in
        "/" | "/bin" | "/usr" | "/etc" | "/var" | "/home" | "/root" | "$HOME")
            print_error "safe_remove: Refusing to remove protected directory: $target"
            return 1
            ;;
    esac
    
    if [[ -e "$target" ]]; then
        rm -rf "$target"
        print_debug "Removed: $target"
    else
        print_debug "Target does not exist: $target"
    fi
}

# Get temporary directory
get_temp_dir() {
    local prefix="${1:-xanados}"
    mktemp -d -t "${prefix}.XXXXXXXX"
}

# Cleanup function for temporary files
cleanup_temp() {
    local temp_dir="$1"
    if [[ -n "$temp_dir" ]] && [[ -d "$temp_dir" ]] && [[ "$temp_dir" =~ ^/tmp/ ]]; then
        safe_remove "$temp_dir"
    fi
}

# Exit with error message
die() {
    local exit_code="${2:-1}"
    print_error "$1"
    exit "$exit_code"
}

# Confirm user action
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        echo -n "$message [Y/n]: "
    else
        echo -n "$message [y/N]: "
    fi
    
    read -r response
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        [Nn]|[Nn][Oo])
            return 1
            ;;
        "")
            [[ "$default" == "y" ]] && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Progress indicator for long operations
show_progress() {
    local message="$1"
    local current="$2"
    local total="$3"
    
    local percent=$((current * 100 / total))
    local bar_length=20
    local filled=$((percent * bar_length / 100))
    
    printf "\r${BLUE}[INFO]${NC} %s [" "$message"
    printf "%*s" "$filled" "" | tr ' ' '='
    printf "%*s" $((bar_length - filled)) "" | tr ' ' '-'
    printf "] %d%%" "$percent"
    
    if [[ "$current" -eq "$total" ]]; then
        echo ""
    fi
}

# Library initialization message
if [[ "${XANADOS_DEBUG:-false}" == "true" ]]; then
    print_debug "xanadOS Common Library v${XANADOS_LIB_VERSION} loaded"
    print_debug "Project root: $XANADOS_ROOT"
fi
