#!/bin/bash
# xanadOS Secure Configuration Management
# Handles sensitive configuration data securely

set -euo pipefail

# Prevent multiple sourcing
[[ "${XANADOS_CONFIG_SECURITY_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_CONFIG_SECURITY_LOADED="true"

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Configuration security settings
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xanados"
readonly SECRET_DIR="${CONFIG_DIR}/secrets"
readonly CONFIG_FILE_MODE="600"
readonly CONFIG_DIR_MODE="700"

# ============================================================================
# Secure Configuration Management
# ============================================================================

# Initialize secure configuration directory
init_secure_config() {
    log_info "Initializing secure configuration directory"

    # Create directories with proper permissions
    mkdir -p "$CONFIG_DIR" "$SECRET_DIR"
    chmod "$CONFIG_DIR_MODE" "$CONFIG_DIR" "$SECRET_DIR"

    # Set SELinux context if available
    if command -v selinux >/dev/null 2>&1 && selinuxenabled 2>/dev/null; then
        chcon -R -t user_home_dir_t "$CONFIG_DIR" 2>/dev/null || true
    fi

    log_success "Secure configuration initialized"
}

# Store configuration securely
store_config() {
    local config_name="$1"
    local config_data="$2"
    local is_secret="${3:-false}"

    # Validate input
    if ! validate_alphanum "$config_name"; then
        log_error "Invalid configuration name: $config_name"
        return 1
    fi

    # Determine storage location
    local config_path
    if [[ "$is_secret" == "true" ]]; then
        config_path="$SECRET_DIR/${config_name}.conf"
    else
        config_path="$CONFIG_DIR/${config_name}.conf"
    fi

    # Store with secure permissions
    echo "$config_data" > "$config_path"
    chmod "$CONFIG_FILE_MODE" "$config_path"

    # Clear from memory (best effort)
    config_data=""

    log_info "Configuration stored securely: $config_name"
}

# Retrieve configuration securely
get_config() {
    local config_name="$1"
    local is_secret="${2:-false}"

    # Validate input
    if ! validate_alphanum "$config_name"; then
        log_error "Invalid configuration name: $config_name"
        return 1
    fi

    # Determine storage location
    local config_path
    if [[ "$is_secret" == "true" ]]; then
        config_path="$SECRET_DIR/${config_name}.conf"
    else
        config_path="$CONFIG_DIR/${config_name}.conf"
    fi

    # Check file exists and has correct permissions
    if [[ ! -f "$config_path" ]]; then
        log_error "Configuration not found: $config_name"
        return 1
    fi

    # Verify file permissions
    local file_perms
    file_perms=$(stat -c "%a" "$config_path")
    if [[ "$file_perms" != "600" ]]; then
        log_warn "Insecure permissions on config file: $config_path ($file_perms)"
        chmod "$CONFIG_FILE_MODE" "$config_path"
    fi

    # Return content
    cat "$config_path"
}

# Remove configuration securely
remove_config() {
    local config_name="$1"
    local is_secret="${2:-false}"

    # Validate input
    if ! validate_alphanum "$config_name"; then
        log_error "Invalid configuration name: $config_name"
        return 1
    fi

    # Determine storage location
    local config_path
    if [[ "$is_secret" == "true" ]]; then
        config_path="$SECRET_DIR/${config_name}.conf"
    else
        config_path="$CONFIG_DIR/${config_name}.conf"
    fi

    # Secure deletion
    if [[ -f "$config_path" ]]; then
        # Overwrite with random data before deletion (best effort)
        if command -v shred >/dev/null 2>&1; then
            shred -vfz -n 3 "$config_path" 2>/dev/null || rm -f "$config_path"
        else
            rm -f "$config_path"
        fi
        log_info "Configuration securely removed: $config_name"
    else
        log_warn "Configuration not found for removal: $config_name"
    fi
}

# Backup configurations securely
backup_configs() {
    local backup_path="${1:-$CONFIG_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz}"

    log_info "Creating secure configuration backup"

    # Create encrypted backup
    if command -v gpg >/dev/null 2>&1; then
        tar -czf - -C "$CONFIG_DIR" . | gpg --symmetric --cipher-algo AES256 --output "$backup_path"
        chmod "$CONFIG_FILE_MODE" "$backup_path"
        log_success "Encrypted backup created: $backup_path"
    else
        # Fallback to regular compressed backup with secure permissions
        tar -czf "$backup_path" -C "$CONFIG_DIR" .
        chmod "$CONFIG_FILE_MODE" "$backup_path"
        log_warn "Backup created without encryption (GPG not available): $backup_path"
    fi
}

# Validate configuration integrity
validate_config_integrity() {
    log_info "Validating configuration integrity"

    local issues=0

    # Check directory permissions
    local dir_perms
    dir_perms=$(stat -c "%a" "$CONFIG_DIR")
    if [[ "$dir_perms" != "700" ]]; then
        log_warn "Insecure directory permissions: $CONFIG_DIR ($dir_perms)"
        chmod "$CONFIG_DIR_MODE" "$CONFIG_DIR"
        ((issues++))
    fi

    # Check file permissions
    while IFS= read -r -d '' config_file; do
        local file_perms
        file_perms=$(stat -c "%a" "$config_file")
        if [[ "$file_perms" != "600" ]]; then
            log_warn "Insecure file permissions: $config_file ($file_perms)"
            chmod "$CONFIG_FILE_MODE" "$config_file"
            ((issues++))
        fi
    done < <(find "$CONFIG_DIR" -type f -print0 2>/dev/null)

    if [[ $issues -eq 0 ]]; then
        log_success "Configuration integrity validated"
    else
        log_warn "Fixed $issues configuration security issues"
    fi

    return 0
}

# Export functions
export -f init_secure_config
export -f store_config
export -f get_config
export -f remove_config
export -f backup_configs
export -f validate_config_integrity

# Initialize on load
init_secure_config

log_debug "Secure configuration management loaded"
