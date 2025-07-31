#!/bin/bash
# xanadOS Validation & Command Detection Library
# Centralized validation and command checking functionality
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_VALIDATION_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_VALIDATION_LOADED="true"

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Command availability cache (associative array)
declare -A COMMAND_CACHE

# Gaming tools detection
declare -A GAMING_TOOLS
GAMING_TOOLS=(
    ["steam"]="Steam Gaming Platform"
    ["lutris"]="Lutris Gaming Manager"
    ["wine"]="Windows Compatibility Layer"
    ["gamemoderun"]="GameMode Performance Optimization"
    ["mangohud"]="MangoHud Performance Overlay"
    ["protonup-qt"]="Proton Version Manager"
    ["bottles"]="Windows Software Manager"
    ["heroic"]="Epic Games Store Client"
)

# Development tools
declare -A DEV_TOOLS
DEV_TOOLS=(
    ["git"]="Version Control System"
    ["gcc"]="GNU Compiler Collection"
    ["make"]="Build Automation Tool"
    ["cmake"]="Cross-platform Build System"
    ["python"]="Python Programming Language"
    ["python3"]="Python 3 Programming Language"
    ["pip"]="Python Package Installer"
    ["npm"]="Node.js Package Manager"
    ["node"]="Node.js Runtime"
    ["docker"]="Container Platform"
)

# System tools
declare -A SYSTEM_TOOLS
SYSTEM_TOOLS=(
    ["pacman"]="Arch Linux Package Manager"
    ["yay"]="AUR Helper"
    ["systemctl"]="SystemD Service Manager"
    ["ufw"]="Uncomplicated Firewall"
    ["nvidia-smi"]="NVIDIA System Management Interface"
    ["lscpu"]="CPU Information"
    ["free"]="Memory Information"
    ["df"]="Disk Space Information"
    ["lsblk"]="Block Device Information"
)

# Check if command exists (with caching)
command_exists() {
    local cmd="$1"
    local force_check="${2:-false}"
    
    if [[ -z "$cmd" ]]; then
        return 1
    fi
    
    # Check cache first (unless forced)
    if [[ "$force_check" == "false" ]] && [[ -n "${COMMAND_CACHE[$cmd]:-}" ]]; then
        [[ "${COMMAND_CACHE[$cmd]}" == "true" ]]
        return $?
    fi
    
    # Perform actual check
    if command -v "$cmd" >/dev/null 2>&1; then
        COMMAND_CACHE["$cmd"]="true"
        return 0
    else
        COMMAND_CACHE["$cmd"]="false"
        return 1
    fi
}

# Batch check commands and return results
check_commands() {
    local commands=("$@")
    local results=()
    
    for cmd in "${commands[@]}"; do
        if command_exists "$cmd"; then
            results+=("$cmd:available")
        else
            results+=("$cmd:missing")
        fi
    done
    
    printf '%s\n' "${results[@]}"
}

# Check gaming environment
check_gaming_environment() {
    local output_format="${1:-summary}"  # summary, detailed, json
    local available=()
    local missing=()
    
    for tool in "${!GAMING_TOOLS[@]}"; do
        if command_exists "$tool"; then
            available+=("$tool")
        else
            missing+=("$tool")
        fi
    done
    
    case "$output_format" in
        "json")
            echo "{"
            echo "  \"available\": [$(printf '"%s",' "${available[@]}" | sed 's/,$//')],"
            echo "  \"missing\": [$(printf '"%s",' "${missing[@]}" | sed 's/,$//')],"
            echo "  \"total_tools\": ${#GAMING_TOOLS[@]},"
            echo "  \"available_count\": ${#available[@]},"
            echo "  \"missing_count\": ${#missing[@]}"
            echo "}"
            ;;
        "detailed")
            echo "Gaming Environment Status:"
            echo ""
            echo "Available Tools (${#available[@]}/${#GAMING_TOOLS[@]}):"
            for tool in "${available[@]}"; do
                echo "  ✓ $tool - ${GAMING_TOOLS[$tool]}"
            done
            echo ""
            echo "Missing Tools (${#missing[@]}/${#GAMING_TOOLS[@]}):"
            for tool in "${missing[@]}"; do
                echo "  ✗ $tool - ${GAMING_TOOLS[$tool]}"
            done
            ;;
        "summary"|*)
            local percentage=$((${#available[@]} * 100 / ${#GAMING_TOOLS[@]}))
            echo "Gaming Environment: ${#available[@]}/${#GAMING_TOOLS[@]} tools available ($percentage%)"
            if [[ ${#missing[@]} -gt 0 ]]; then
                echo "Missing: ${missing[*]}"
            fi
            ;;
    esac
}

# Check development environment
check_development_environment() {
    local output_format="${1:-summary}"
    local available=()
    local missing=()
    
    for tool in "${!DEV_TOOLS[@]}"; do
        if command_exists "$tool"; then
            available+=("$tool")
        else
            missing+=("$tool")
        fi
    done
    
    case "$output_format" in
        "detailed")
            echo "Development Environment Status:"
            echo ""
            echo "Available Tools (${#available[@]}/${#DEV_TOOLS[@]}):"
            for tool in "${available[@]}"; do
                echo "  ✓ $tool - ${DEV_TOOLS[$tool]}"
            done
            echo ""
            echo "Missing Tools (${#missing[@]}/${#DEV_TOOLS[@]}):"
            for tool in "${missing[@]}"; do
                echo "  ✗ $tool - ${DEV_TOOLS[$tool]}"
            done
            ;;
        "summary"|*)
            local percentage=$((${#available[@]} * 100 / ${#DEV_TOOLS[@]}))
            echo "Development Environment: ${#available[@]}/${#DEV_TOOLS[@]} tools available ($percentage%)"
            if [[ ${#missing[@]} -gt 0 ]]; then
                echo "Missing: ${missing[*]}"
            fi
            ;;
    esac
}

# Validate input parameters
validate_input() {
    local input="$1"
    local type="$2"
    local required="${3:-true}"
    
    # Check if input is required but empty
    if [[ "$required" == "true" ]] && [[ -z "$input" ]]; then
        print_error "Required parameter is empty"
        return 1
    fi
    
    # Skip validation if input is empty and not required
    if [[ -z "$input" ]]; then
        return 0
    fi
    
    case "$type" in
        "file")
            if [[ ! -f "$input" ]]; then
                print_error "File does not exist: $input"
                return 1
            fi
            ;;
        "directory")
            if [[ ! -d "$input" ]]; then
                print_error "Directory does not exist: $input"
                return 1
            fi
            ;;
        "executable")
            if [[ ! -x "$input" ]]; then
                print_error "File is not executable: $input"
                return 1
            fi
            ;;
        "path")
            if [[ ! -e "$input" ]]; then
                print_error "Path does not exist: $input"
                return 1
            fi
            ;;
        "url")
            if ! [[ "$input" =~ ^https?:// ]]; then
                print_error "Invalid URL format: $input"
                return 1
            fi
            ;;
        "email")
            if ! [[ "$input" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                print_error "Invalid email format: $input"
                return 1
            fi
            ;;
        "number")
            if ! [[ "$input" =~ ^[0-9]+$ ]]; then
                print_error "Input is not a valid number: $input"
                return 1
            fi
            ;;
        "port")
            if ! [[ "$input" =~ ^[0-9]+$ ]] || [[ "$input" -lt 1 ]] || [[ "$input" -gt 65535 ]]; then
                print_error "Invalid port number: $input (must be 1-65535)"
                return 1
            fi
            ;;
        *)
            print_warning "Unknown validation type: $type"
            ;;
    esac
    
    return 0
}

# Validate path safety (prevent directory traversal)
validate_safe_path() {
    local path="$1"
    local base_dir="$2"
    
    # Resolve absolute paths
    local abs_path
    abs_path="$(realpath "$path" 2>/dev/null)" || abs_path="$path"
    
    if [[ -n "$base_dir" ]]; then
        local abs_base
        abs_base="$(realpath "$base_dir" 2>/dev/null)" || abs_base="$base_dir"
        
        # Check if path is within base directory
        if [[ "$abs_path" != "$abs_base"* ]]; then
            print_error "Path traversal detected: $path is outside $base_dir"
            return 1
        fi
    fi
    
    # Check for dangerous patterns
    if [[ "$abs_path" =~ \.\./|/\.\./|/\.\.$ ]]; then
        print_error "Unsafe path pattern detected: $path"
        return 1
    fi
    
    return 0
}

# Check system requirements
check_system_requirements() {
    local requirements=("$@")
    local failed=()
    
    for req in "${requirements[@]}"; do
        case "$req" in
            "arch")
                if ! [[ -f "/etc/arch-release" ]]; then
                    failed+=("Arch Linux")
                fi
                ;;
            "root")
                if [[ "$EUID" -ne 0 ]]; then
                    failed+=("Root privileges")
                fi
                ;;
            "user")
                if [[ "$EUID" -eq 0 ]]; then
                    failed+=("Non-root user")
                fi
                ;;
            "desktop")
                if [[ -z "$DISPLAY" ]]; then
                    failed+=("Desktop environment")
                fi
                ;;
            "internet")
                if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
                    failed+=("Internet connection")
                fi
                ;;
            *)
                if ! command_exists "$req"; then
                    failed+=("Command: $req")
                fi
                ;;
        esac
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_error "System requirements not met:"
        for fail in "${failed[@]}"; do
            print_error "  - $fail"
        done
        return 1
    fi
    
    return 0
}

# Check disk space
check_disk_space() {
    local path="$1"
    local required_mb="$2"
    
    local available_kb
    available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_mb=$((available_kb / 1024))
    
    if [[ $available_mb -lt $required_mb ]]; then
        print_error "Insufficient disk space: ${available_mb}MB available, ${required_mb}MB required"
        return 1
    fi
    
    print_debug "Disk space check passed: ${available_mb}MB available (${required_mb}MB required)"
    return 0
}

# Check memory requirements
check_memory_requirements() {
    local required_mb="$1"
    
    local available_kb
    available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local available_mb=$((available_kb / 1024))
    
    if [[ $available_mb -lt $required_mb ]]; then
        print_error "Insufficient memory: ${available_mb}MB available, ${required_mb}MB required"
        return 1
    fi
    
    print_debug "Memory check passed: ${available_mb}MB available (${required_mb}MB required)"
    return 0
}

# Clear command cache
clear_command_cache() {
    COMMAND_CACHE=()
    print_debug "Command cache cleared"
}

# Print command cache status
print_command_cache() {
    echo "Command Cache Status:"
    for cmd in "${!COMMAND_CACHE[@]}"; do
        echo "  $cmd: ${COMMAND_CACHE[$cmd]}"
    done
}

# Validate script environment
validate_script_environment() {
    local script_name="${1:-${0##*/}}"
    
    print_debug "Validating environment for: $script_name"
    
    # Basic checks
    if ! check_system_requirements "user"; then
        return 1
    fi
    
    # Check if we're in a reasonable location
    if [[ ! -w "$(pwd)" ]]; then
        print_warning "Current directory is not writable: $(pwd)"
    fi
    
    # Check for common tools
    local essential_tools=("bash" "mkdir" "chmod" "grep" "awk" "sed")
    if ! check_system_requirements "${essential_tools[@]}"; then
        return 1
    fi
    
    print_debug "Script environment validation passed"
    return 0
}

# Export functions for other scripts to use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Validation Library v1.0.0"
    echo "This library should be sourced, not executed directly."
    echo ""
    echo "Available functions:"
    echo "  - command_exists, check_commands"
    echo "  - check_gaming_environment, check_development_environment"
    echo "  - validate_input, validate_safe_path"
    echo "  - check_system_requirements, check_disk_space, check_memory_requirements"
    exit 1
fi
