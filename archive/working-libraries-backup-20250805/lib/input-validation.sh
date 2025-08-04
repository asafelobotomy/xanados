#!/bin/bash
# xanadOS Input Validation Library
# Secure input handling following OWASP guidelines

set -euo pipefail

# Prevent multiple sourcing
[[ "${XANADOS_INPUT_VALIDATION_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_INPUT_VALIDATION_LOADED="true"

# Source logging for security events
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# Input Validation Functions (OWASP A03: Injection Prevention)
# ============================================================================

# Validate alphanumeric input with safe character set
validate_alphanum() {
    local input="$1"
    local max_length="${2:-50}"

    # Check length first
    if [[ ${#input} -gt $max_length ]]; then
        log_error "Input too long: ${#input} > $max_length characters"
        return 1
    fi

    # Allow only alphanumeric, dash, underscore, and dot
    if [[ ! $input =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "Invalid characters in input. Only alphanumeric, dash, underscore, and dot allowed"
        return 1
    fi

    log_debug "Input validation passed: $input"
    return 0
}

# Validate file path to prevent directory traversal (OWASP A01: Broken Access Control)
validate_file_path() {
    local path="$1"
    local base_dir="${2:-/home}"

    # Resolve absolute path and check for traversal attempts
    local resolved_path
    resolved_path=$(realpath -m "$path" 2>/dev/null) || {
        log_error "Invalid file path: $path"
        return 1
    }

    # Ensure path is within allowed base directory
    if [[ ! $resolved_path =~ ^$base_dir ]]; then
        log_error "Path traversal detected: $resolved_path not in $base_dir"
        return 1
    fi

    # Additional check for dangerous patterns
    if [[ $path =~ \.\./|\.\.\\ ]]; then
        log_error "Directory traversal pattern detected in: $path"
        return 1
    fi

    log_debug "File path validation passed: $resolved_path"
    return 0
}

# Validate URL to prevent SSRF (OWASP A10: Server-Side Request Forgery)
validate_url() {
    local url="$1"
    local allowed_schemes="${2:-https}"

    # Basic URL format validation
    if [[ ! $url =~ ^https?:// ]]; then
        log_error "Invalid URL scheme. Only HTTP/HTTPS allowed: $url"
        return 1
    fi

    # Extract hostname
    local hostname
    hostname=$(echo "$url" | sed -E 's|^https?://([^/]+).*|\1|')

    # Prevent localhost/internal network access
    if [[ $hostname =~ ^(localhost|127\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.) ]]; then
        log_error "SSRF prevention: Internal network access blocked for $hostname"
        return 1
    fi

    # Prevent IPv6 localhost
    if [[ $hostname =~ ^(\[::1\]|\[::ffff:127\.0\.0\.1\]) ]]; then
        log_error "SSRF prevention: IPv6 localhost access blocked"
        return 1
    fi

    log_debug "URL validation passed: $url"
    return 0
}

# Sanitize command arguments to prevent injection
sanitize_command_args() {
    local arg="$1"

    # Remove or escape dangerous characters
    arg="${arg//\$/\\$}"      # Escape dollar signs
    arg="${arg//\`/\\\`}"     # Escape backticks
    arg="${arg//;/}"          # Remove semicolons
    arg="${arg//&/}"          # Remove ampersands
    arg="${arg//|/}"          # Remove pipes
    arg="${arg//>/}"          # Remove redirections
    arg="${arg//</}"          # Remove redirections

    echo "$arg"
}

# Secure read function with validation
secure_read() {
    local prompt="$1"
    local validator="${2:-validate_alphanum}"
    local max_attempts="${3:-3}"
    local value

    for ((i=1; i<=max_attempts; i++)); do
        echo -n "$prompt: "
        read -r value

        if $validator "$value"; then
            echo "$value"
            return 0
        fi

        if [[ $i -lt $max_attempts ]]; then
            echo "Invalid input. Please try again ($((max_attempts - i)) attempts remaining)."
        fi
    done

    log_error "Maximum validation attempts exceeded"
    return 1
}

# Export validation functions
export -f validate_alphanum
export -f validate_file_path
export -f validate_url
export -f sanitize_command_args
export -f secure_read

log_debug "Input validation library loaded"
