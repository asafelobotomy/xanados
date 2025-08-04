#!/bin/bash
# xanadOS Unified Error Handling System
# Comprehensive error management with recovery strategies

set -euo pipefail

# Prevent multiple sourcing
[[ "${XANADOS_ERROR_HANDLING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_ERROR_HANDLING_LOADED="true"

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Error handling configuration
readonly ERROR_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/xanados/errors"
readonly MAX_ERROR_LOGS=50
readonly ERROR_REPORT_FILE="$ERROR_LOG_DIR/error-summary.log"

# Error categories and severity levels
declare -A ERROR_CATEGORIES=(
    ["SYSTEM"]="System-level errors"
    ["GAMING"]="Gaming-related errors"
    ["NETWORK"]="Network connectivity errors"
    ["HARDWARE"]="Hardware detection/optimization errors"
    ["CONFIG"]="Configuration errors"
    ["SECURITY"]="Security-related errors"
    ["PERFORMANCE"]="Performance optimization errors"
)

declare -A ERROR_SEVERITY=(
    ["CRITICAL"]="5"
    ["HIGH"]="4"
    ["MEDIUM"]="3"
    ["LOW"]="2"
    ["INFO"]="1"
)

# ============================================================================
# Error Handling Functions
# ============================================================================

# Initialize error handling system
init_error_handling() {
    # Create error log directory
    mkdir -p "$ERROR_LOG_DIR"

    # Set up error trap
    trap 'handle_script_error $? $LINENO $BASH_COMMAND' ERR
    trap 'handle_script_exit $?' EXIT

    # Initialize error log rotation
    rotate_error_logs

    log_debug "Error handling system initialized"
}

# Handle script errors with context
handle_script_error() {
    local exit_code="$1"
    local line_number="$2"
    local failed_command="$3"
    local script_name="${BASH_SOURCE[1]##*/}"

    # Create error context
    local error_context
    error_context=$(create_error_context "$exit_code" "$line_number" "$failed_command" "$script_name")

    # Log the error
    log_structured_error "SYSTEM" "HIGH" "Script execution error" "$error_context"

    # Attempt recovery if possible
    attempt_error_recovery "$exit_code" "$failed_command"

    return "$exit_code"
}

# Handle script exit
handle_script_exit() {
    local exit_code="$1"

    if [[ $exit_code -ne 0 ]]; then
        log_debug "Script exited with error code: $exit_code"

        # Generate error summary if multiple errors occurred
        generate_error_summary
    fi
}

# Create detailed error context
create_error_context() {
    local exit_code="$1"
    local line_number="$2"
    local failed_command="$3"
    local script_name="$4"

    cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "script": "$script_name",
  "line": $line_number,
  "exit_code": $exit_code,
  "command": "$failed_command",
  "user": "$(whoami)",
  "pwd": "$(pwd)",
  "system_info": {
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "load_average": "$(uptime | grep -o 'load average.*')",
    "memory_usage": "$(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
  }
}
EOF
}

# Log structured error with category and severity
log_structured_error() {
    local category="$1"
    local severity="$2"
    local message="$3"
    local context="${4:-{}}"
    local timestamp
    timestamp=$(date -Iseconds)

    # Validate inputs
    if [[ ! "${ERROR_CATEGORIES[$category]:-}" ]]; then
        category="SYSTEM"
    fi

    if [[ ! "${ERROR_SEVERITY[$severity]:-}" ]]; then
        severity="MEDIUM"
    fi

    # Create error log entry
    local error_entry
    error_entry=$(cat << EOF
{
  "timestamp": "$timestamp",
  "category": "$category",
  "severity": "$severity",
  "severity_level": ${ERROR_SEVERITY[$severity]},
  "message": "$message",
  "context": $context
}
EOF
    )

    # Log to category-specific file
    local category_log="$ERROR_LOG_DIR/${category,,}-errors.log"
    echo "$error_entry" >> "$category_log"

    # Log to main error log
    echo "$error_entry" >> "$ERROR_REPORT_FILE"

    # Also log to system log
    log_error "[$category:$severity] $message"

    # Trigger alerts for critical errors
    if [[ "$severity" == "CRITICAL" ]]; then
        trigger_critical_error_alert "$category" "$message" "$context"
    fi
}

# Attempt automatic error recovery
attempt_error_recovery() {
    local exit_code="$1"
    local failed_command="$2"

    log_info "Attempting error recovery for exit code $exit_code"

    case "$exit_code" in
        1)
            # General errors - try to continue
            log_warn "General error encountered, continuing execution"
            return 0
            ;;
        2)
            # Misuse of shell builtins
            log_error "Shell builtin misuse detected"
            return 2
            ;;
        126)
            # Command invoked cannot execute
            if echo "$failed_command" | grep -q "^sudo"; then
                log_error "Sudo command failed - check permissions"
                suggest_sudo_recovery
            fi
            return 126
            ;;
        127)
            # Command not found
            local missing_command
            missing_command=$(echo "$failed_command" | awk '{print $1}')
            log_error "Command not found: $missing_command"
            suggest_package_installation "$missing_command"
            return 127
            ;;
        130)
            # Ctrl+C interruption
            log_info "Operation interrupted by user"
            return 130
            ;;
        *)
            log_warn "Unknown error code: $exit_code"
            return "$exit_code"
            ;;
    esac
}

# Suggest sudo recovery options
suggest_sudo_recovery() {
    log_info "Sudo recovery suggestions:"
    echo "  1. Check if you have sudo privileges: sudo -l"
    echo "  2. Refresh sudo credentials: sudo -v"
    echo "  3. Check if the target file/command exists"
}

# Suggest package installation for missing commands
suggest_package_installation() {
    local missing_command="$1"

    log_info "Package installation suggestions for '$missing_command':"

    # Common command-to-package mappings
    case "$missing_command" in
        "curl")
            echo "  sudo pacman -S curl"
            ;;
        "wget")
            echo "  sudo pacman -S wget"
            ;;
        "git")
            echo "  sudo pacman -S git"
            ;;
        "make")
            echo "  sudo pacman -S make"
            ;;
        "gcc")
            echo "  sudo pacman -S gcc"
            ;;
        "python3")
            echo "  sudo pacman -S python"
            ;;
        *)
            echo "  Search for package: pacman -Ss $missing_command"
            echo "  Or install with AUR helper: paru -S $missing_command"
            ;;
    esac
}

# Trigger critical error alerts
trigger_critical_error_alert() {
    local category="$1"
    local message="$2"
    local context="$3"

    log_error "CRITICAL ERROR ALERT: [$category] $message"

    # Create alert file for system monitoring
    local alert_file="$ERROR_LOG_DIR/critical-alert-$(date +%s).json"
    cat > "$alert_file" << EOF
{
  "alert_type": "critical_error",
  "timestamp": "$(date -Iseconds)",
  "category": "$category",
  "message": "$message",
  "context": $context,
  "requires_attention": true
}
EOF

    # Send desktop notification if available
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "xanadOS Critical Error" "[$category] $message" -u critical 2>/dev/null || true
    fi
}

# Generate error summary report
generate_error_summary() {
    local summary_file="$ERROR_LOG_DIR/summary-$(date +%Y%m%d-%H%M%S).json"

    log_info "Generating error summary report"

    # Count errors by category and severity
    echo "{" > "$summary_file"
    echo "  \"report_timestamp\": \"$(date -Iseconds)\"," >> "$summary_file"
    echo "  \"period\": \"session\"," >> "$summary_file"
    echo "  \"error_counts\": {" >> "$summary_file"

    # Add category counts
    local first_category=true
    for category in "${!ERROR_CATEGORIES[@]}"; do
        local count=0
        local category_file="$ERROR_LOG_DIR/${category,,}-errors.log"
        if [[ -f "$category_file" ]]; then
            count=$(wc -l < "$category_file" 2>/dev/null || echo "0")
        fi

        if [[ "$first_category" == "true" ]]; then
            first_category=false
        else
            echo "," >> "$summary_file"
        fi
        echo -n "    \"$category\": $count" >> "$summary_file"
    done

    echo "" >> "$summary_file"
    echo "  }" >> "$summary_file"
    echo "}" >> "$summary_file"

    log_success "Error summary generated: $summary_file"
}

# Rotate error logs to prevent disk space issues
rotate_error_logs() {
    log_debug "Rotating error logs"

    # Remove old error logs if we exceed the limit
    local log_count
    log_count=$(find "$ERROR_LOG_DIR" -name "*.log" -type f | wc -l)

    if [[ $log_count -gt $MAX_ERROR_LOGS ]]; then
        log_info "Rotating error logs (current: $log_count, max: $MAX_ERROR_LOGS)"

        # Remove oldest logs
        find "$ERROR_LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' | \
            sort -n | \
            head -n $((log_count - MAX_ERROR_LOGS)) | \
            cut -d' ' -f2- | \
            xargs rm -f

        log_success "Error log rotation completed"
    fi
}

# Get error statistics
get_error_stats() {
    local category="${1:-all}"
    local hours="${2:-24}"

    log_info "Getting error statistics for $category (last ${hours}h)"

    local since_timestamp
    since_timestamp=$(date -d "$hours hours ago" -Iseconds)

    if [[ "$category" == "all" ]]; then
        # Count all errors since timestamp
        find "$ERROR_LOG_DIR" -name "*.log" -type f -exec grep -l "$since_timestamp" {} \; | wc -l
    else
        # Count category-specific errors
        local category_file="$ERROR_LOG_DIR/${category,,}-errors.log"
        if [[ -f "$category_file" ]]; then
            grep -c "$since_timestamp" "$category_file" 2>/dev/null || echo "0"
        else
            echo "0"
        fi
    fi
}

# Clear error logs
clear_error_logs() {
    local confirm="${1:-false}"

    if [[ "$confirm" != "true" ]]; then
        log_warn "This will clear all error logs. Use clear_error_logs true to confirm."
        return 1
    fi

    log_info "Clearing all error logs"

    # Archive current logs before clearing
    local archive_file="$ERROR_LOG_DIR/archived-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$archive_file" -C "$ERROR_LOG_DIR" --exclude="archived-*.tar.gz" . 2>/dev/null || true

    # Clear log files
    find "$ERROR_LOG_DIR" -name "*.log" -type f -delete

    log_success "Error logs cleared and archived to: $archive_file"
}

# Export functions
export -f init_error_handling
export -f log_structured_error
export -f get_error_stats
export -f clear_error_logs
export -f generate_error_summary

# Initialize error handling
init_error_handling

log_debug "Unified error handling system loaded"
