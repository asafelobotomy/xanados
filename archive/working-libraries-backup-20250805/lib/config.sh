#!/bin/bash
# xanadOS Configuration Management Library
# Modern configuration handling with validation and security
# Version: 1.0.0 - 2024/2025 best practices

# Bash strict mode - 2024 best practice
set -euo pipefail
IFS=$'\n\t'

# Prevent multiple sourcing
[[ "${XANADOS_CONFIG_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_CONFIG_LOADED="true"

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# Configuration management settings
readonly CONFIG_DIR="${XANADOS_CONFIG_DIR:-/etc/xanados}"
readonly CONFIG_USER_DIR="${XANADOS_USER_CONFIG_DIR:-$HOME/.config/xanados}"
readonly CONFIG_CACHE_DIR="${XANADOS_CONFIG_CACHE_DIR:-/tmp/xanados-config}"
readonly CONFIG_BACKUP_DIR="${XANADOS_CONFIG_BACKUP_DIR:-$CONFIG_DIR/backups}"

# Configuration file permissions (security best practice)
readonly CONFIG_FILE_PERMISSIONS="644"
readonly CONFIG_SECRET_PERMISSIONS="600"
readonly CONFIG_DIR_PERMISSIONS="755"

# Configuration validation patterns
declare -A CONFIG_PATTERNS=(
    ["email"]="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    ["url"]="^https?://[a-zA-Z0-9.-]+[a-zA-Z0-9.-]*/?.*$"
    ["port"]="^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"
    ["ipv4"]="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    ["path"]="^(/[^/\0]+)*/?$"
    ["bool"]="^(true|false|yes|no|on|off|1|0)$"
    ["number"]="^[0-9]+$"
    ["version"]="^[0-9]+\.[0-9]+\.[0-9]+$"
)

# Global configuration cache
declare -A CONFIG_CACHE=()
declare -A CONFIG_METADATA=()

# Initialize configuration management
init_config_management() {
    log_debug "Initializing configuration management"

    # Create necessary directories
    for dir in "$CONFIG_DIR" "$CONFIG_USER_DIR" "$CONFIG_CACHE_DIR" "$CONFIG_BACKUP_DIR"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir" 2>/dev/null; then
                chmod "$CONFIG_DIR_PERMISSIONS" "$dir"
                log_debug "Created config directory: $dir"
            else
                log_warn "Could not create config directory: $dir"
            fi
        fi
    done

    # Set up configuration file watchers if inotify is available
    if command_exists inotifywait; then
        setup_config_watchers &
    fi

    log_info "Configuration management initialized"
}

# Load configuration from file with validation
load_config() {
    local config_file="$1"
    local namespace="${2:-default}"
    local required="${3:-false}"
    local cache_key="${namespace}:$(basename "$config_file")"

    validate_file "$config_file" "$required"

    # Check cache first
    if [[ -n "${CONFIG_CACHE[$cache_key]:-}" ]]; then
        log_debug "Using cached config: $cache_key"
        return 0
    fi

    if [[ ! -f "$config_file" ]]; then
        if [[ "$required" == "true" ]]; then
            log_error "Required configuration file not found: $config_file"
            return 1
        else
            log_debug "Optional configuration file not found: $config_file"
            return 0
        fi
    fi

    log_debug "Loading configuration from: $config_file"

    # Validate file permissions
    local file_perms
    file_perms=$(stat -c %a "$config_file")
    if [[ "$file_perms" -gt 644 ]]; then
        log_warn "Configuration file has overly permissive permissions: $file_perms"
    fi

    # Parse configuration file
    local line_num=0
    while IFS= read -r line; do
        ((line_num++))

        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Parse key=value pairs
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Remove quotes if present
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"

            # Store in cache with namespace
            CONFIG_CACHE["${namespace}.${key}"]="$value"
            CONFIG_METADATA["${namespace}.${key}"]="$config_file:$line_num"

            log_debug "Loaded config: ${namespace}.${key} = $value"
        else
            log_warn "Invalid config line in $config_file:$line_num: $line"
        fi

    done < "$config_file"

    # Mark as loaded
    CONFIG_CACHE["$cache_key"]="loaded"

    log_info "Configuration loaded from: $config_file"
    return 0
}

# Get configuration value with optional validation
get_config() {
    local key="$1"
    local default_value="${2:-}"
    local validation_type="${3:-}"
    local namespace="${4:-default}"

    local full_key="${namespace}.${key}"
    local value="${CONFIG_CACHE[$full_key]:-$default_value}"

    # Validate value if pattern is specified
    if [[ -n "$validation_type" ]] && [[ -n "$value" ]]; then
        if ! validate_config_value "$value" "$validation_type"; then
            log_error "Invalid value for config key '$full_key': $value"
            return 1
        fi
    fi

    echo "$value"
    return 0
}

# Set configuration value with validation
set_config() {
    local key="$1"
    local value="$2"
    local validation_type="${3:-}"
    local namespace="${4:-default}"
    local persistent="${5:-false}"

    local full_key="${namespace}.${key}"

    # Validate value if pattern is specified
    if [[ -n "$validation_type" ]]; then
        if ! validate_config_value "$value" "$validation_type"; then
            log_error "Invalid value for config key '$full_key': $value"
            return 1
        fi
    fi

    # Update cache
    CONFIG_CACHE["$full_key"]="$value"
    CONFIG_METADATA["$full_key"]="runtime:$(date +%s)"

    log_debug "Set config: $full_key = $value"

    # Persist to file if requested
    if [[ "$persistent" == "true" ]]; then
        persist_config "$namespace"
    fi

    return 0
}

# Validate configuration value against pattern
validate_config_value() {
    local value="$1"
    local validation_type="$2"

    local pattern="${CONFIG_PATTERNS[$validation_type]:-}"

    if [[ -z "$pattern" ]]; then
        log_warn "Unknown validation type: $validation_type"
        return 0  # Allow unknown validation types
    fi

    if [[ "$value" =~ $pattern ]]; then
        return 0
    else
        return 1
    fi
}

# Persist configuration to file
persist_config() {
    local namespace="${1:-default}"
    local config_file="${2:-$CONFIG_USER_DIR/${namespace}.conf}"

    # Create backup if file exists
    if [[ -f "$config_file" ]]; then
        backup_config_file "$config_file"
    fi

    log_debug "Persisting configuration to: $config_file"

    # Create directory if needed
    local config_dir
    config_dir="$(dirname "$config_file")"
    mkdir -p "$config_dir"

    # Write configuration
    {
        echo "# xanadOS Configuration File"
        echo "# Generated: $(date)"
        echo "# Namespace: $namespace"
        echo ""

        # Write all keys for this namespace
        for key in "${!CONFIG_CACHE[@]}"; do
            if [[ "$key" =~ ^${namespace}\. ]]; then
                local config_key="${key#${namespace}.}"
                local config_value="${CONFIG_CACHE[$key]}"

                # Skip special cache keys
                [[ "$config_key" =~ : ]] && continue

                # Escape quotes in value
                config_value="${config_value//\"/\\\"}"

                echo "${config_key}=\"${config_value}\""
            fi
        done

    } > "$config_file"

    # Set appropriate permissions
    chmod "$CONFIG_FILE_PERMISSIONS" "$config_file"

    log_info "Configuration persisted to: $config_file"
    return 0
}

# Backup configuration file
backup_config_file() {
    local config_file="$1"
    local backup_file="$CONFIG_BACKUP_DIR/$(basename "$config_file").$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$CONFIG_BACKUP_DIR"

    if cp "$config_file" "$backup_file" 2>/dev/null; then
        log_debug "Created config backup: $backup_file"

        # Clean old backups (keep last 10)
        local backup_pattern="$CONFIG_BACKUP_DIR/$(basename "$config_file").*"
        # shellcheck disable=SC2086
        ls -t $backup_pattern 2>/dev/null | tail -n +11 | xargs -r rm -f

        return 0
    else
        log_warn "Failed to create config backup: $backup_file"
        return 1
    fi
}

# Validate entire configuration namespace
validate_config_namespace() {
    local namespace="${1:-default}"
    local schema_file="${2:-}"

    log_debug "Validating configuration namespace: $namespace"

    local validation_errors=0

    if [[ -n "$schema_file" ]] && [[ -f "$schema_file" ]]; then
        # Load validation schema
        log_debug "Using validation schema: $schema_file"
        # Schema format: key:type:required
        while IFS=: read -r key validation_type required; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue

            local full_key="${namespace}.${key}"
            local value="${CONFIG_CACHE[$full_key]:-}"

            if [[ "$required" == "true" ]] && [[ -z "$value" ]]; then
                log_error "Required configuration key missing: $full_key"
                ((validation_errors++))
                continue
            fi

            if [[ -n "$value" ]] && [[ -n "$validation_type" ]]; then
                if ! validate_config_value "$value" "$validation_type"; then
                    log_error "Invalid value for key '$full_key': $value (expected: $validation_type)"
                    ((validation_errors++))
                fi
            fi

        done < "$schema_file"
    else
        # Basic validation for all keys in namespace
        for key in "${!CONFIG_CACHE[@]}"; do
            if [[ "$key" =~ ^${namespace}\. ]]; then
                local config_key="${key#${namespace}.}"
                local config_value="${CONFIG_CACHE[$key]}"

                # Skip special cache keys
                [[ "$config_key" =~ : ]] && continue

                # Basic validation (non-empty)
                if [[ -z "$config_value" ]]; then
                    log_warn "Empty configuration value: $key"
                fi
            fi
        done
    fi

    if [[ $validation_errors -eq 0 ]]; then
        log_info "Configuration validation passed for namespace: $namespace"
        return 0
    else
        log_error "Configuration validation failed with $validation_errors errors"
        return 1
    fi
}

# Watch configuration files for changes
setup_config_watchers() {
    log_debug "Setting up configuration file watchers"

    local watch_dirs=("$CONFIG_DIR" "$CONFIG_USER_DIR")

    for dir in "${watch_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            (
                inotifywait -m -e modify,create,delete "$dir" 2>/dev/null | while read -r path event file; do
                    if [[ "$file" =~ \.conf$ ]]; then
                        log_info "Configuration file changed: $path$file ($event)"
                        # Reload configuration
                        local namespace
                        namespace="${file%.conf}"
                        reload_config_namespace "$namespace" "$path$file"
                    fi
                done
            ) &
        fi
    done
}

# Reload configuration namespace
reload_config_namespace() {
    local namespace="$1"
    local config_file="$2"

    log_info "Reloading configuration namespace: $namespace"

    # Clear existing cache for namespace
    for key in "${!CONFIG_CACHE[@]}"; do
        if [[ "$key" =~ ^${namespace}\. ]]; then
            unset "CONFIG_CACHE[$key]"
            unset "CONFIG_METADATA[$key]"
        fi
    done

    # Reload from file
    load_config "$config_file" "$namespace" false
}

# Export configuration as environment variables
export_config_as_env() {
    local namespace="${1:-default}"
    local prefix="${2:-XANADOS}"

    log_debug "Exporting configuration as environment variables (prefix: $prefix)"

    for key in "${!CONFIG_CACHE[@]}"; do
        if [[ "$key" =~ ^${namespace}\. ]]; then
            local config_key="${key#${namespace}.}"
            local config_value="${CONFIG_CACHE[$key]}"

            # Skip special cache keys
            [[ "$config_key" =~ : ]] && continue

            # Convert to uppercase and replace dots/dashes with underscores
            local env_var="${prefix}_${config_key^^}"
            env_var="${env_var//./_}"
            env_var="${env_var//-/_}"

            export "$env_var"="$config_value"
            log_debug "Exported: $env_var=$config_value"
        fi
    done
}

# Clear configuration cache
clear_config_cache() {
    local namespace="${1:-}"

    if [[ -n "$namespace" ]]; then
        log_debug "Clearing configuration cache for namespace: $namespace"
        for key in "${!CONFIG_CACHE[@]}"; do
            if [[ "$key" =~ ^${namespace}\. ]]; then
                unset "CONFIG_CACHE[$key]"
                unset "CONFIG_METADATA[$key]"
            fi
        done
    else
        log_debug "Clearing entire configuration cache"
        CONFIG_CACHE=()
        CONFIG_METADATA=()
    fi
}

# Display configuration summary
show_config_summary() {
    local namespace="${1:-}"

    echo ""
    print_header "Configuration Summary"

    local count=0
    for key in "${!CONFIG_CACHE[@]}"; do
        # Skip special cache keys
        [[ "$key" =~ : ]] && continue

        if [[ -z "$namespace" ]] || [[ "$key" =~ ^${namespace}\. ]]; then
            local display_key="$key"
            if [[ -n "$namespace" ]]; then
                display_key="${key#${namespace}.}"
            fi

            local value="${CONFIG_CACHE[$key]}"
            local metadata="${CONFIG_METADATA[$key]:-unknown}"

            # Mask sensitive values
            if [[ "$display_key" =~ (password|secret|key|token) ]]; then
                value="***masked***"
            fi

            printf "%-30s: %s\n" "$display_key" "$value"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "No configuration found"
        if [[ -n "$namespace" ]]; then
            echo "for namespace: $namespace"
        fi
    else
        echo ""
        echo "Total configuration entries: $count"
    fi
    echo ""
}

# Library initialization
init_config_management
log_debug "xanadOS Configuration Management Library v1.0.0 loaded"
