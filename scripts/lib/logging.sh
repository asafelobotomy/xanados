#!/bin/bash
# xanadOS Advanced Logging Library
# Enhanced logging capabilities with file output and level management
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_LOGGING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_LOGGING_LOADED="true"

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Logging configuration
XANADOS_LOG_LEVEL="${XANADOS_LOG_LEVEL:-INFO}"
XANADOS_LOG_FILE="${XANADOS_LOG_FILE:-}"
XANADOS_LOG_TO_CONSOLE="${XANADOS_LOG_TO_CONSOLE:-true}"
XANADOS_LOG_TIMESTAMP="${XANADOS_LOG_TIMESTAMP:-true}"

# Log levels (numeric for comparison)
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_SUCCESS=2
readonly LOG_LEVEL_WARNING=3
readonly LOG_LEVEL_ERROR=4
readonly LOG_LEVEL_CRITICAL=5

# Convert log level name to number
log_level_to_number() {
    case "${1^^}" in
        DEBUG) echo $LOG_LEVEL_DEBUG ;;
        INFO) echo $LOG_LEVEL_INFO ;;
        SUCCESS) echo $LOG_LEVEL_SUCCESS ;;
        WARNING|WARN) echo $LOG_LEVEL_WARNING ;;
        ERROR) echo $LOG_LEVEL_ERROR ;;
        CRITICAL) echo $LOG_LEVEL_CRITICAL ;;
        *) echo $LOG_LEVEL_INFO ;;
    esac
}

# Get current log level as number
get_current_log_level() {
    log_level_to_number "$XANADOS_LOG_LEVEL"
}

# Check if message should be logged
should_log() {
    local message_level="$1"
    local current_level
    current_level=$(get_current_log_level)
    local msg_level_num
    msg_level_num=$(log_level_to_number "$message_level")
    
    [[ $msg_level_num -ge $current_level ]]
}

# Initialize logging system
init_logging() {
    local log_file="$1"
    local log_level="${2:-INFO}"
    local log_to_console="${3:-true}"
    
    XANADOS_LOG_FILE="$log_file"
    XANADOS_LOG_LEVEL="$log_level"
    XANADOS_LOG_TO_CONSOLE="$log_to_console"
    
    if [[ -n "$log_file" ]]; then
        local log_dir
        log_dir="$(dirname "$log_file")"
        safe_mkdir "$log_dir"
        
        # Create log file with header
        {
            echo "# xanadOS Log File"
            echo "# Started: $(timestamp)"
            echo "# Log Level: $log_level"
            echo "# Script: ${0##*/}"
            echo ""
        } > "$log_file"
        
        log_message "INFO" "Logging initialized: $log_file (level: $log_level)"
    fi
}

# Core logging function
log_message() {
    local level="$1"
    local message="$2"
    local component="${3:-${0##*/}}"
    
    # Check if message should be logged
    if ! should_log "$level"; then
        return 0
    fi
    
    local timestamp_str=""
    if [[ "$XANADOS_LOG_TIMESTAMP" == "true" ]]; then
        timestamp_str="$(timestamp) "
    fi
    
    local log_entry="${timestamp_str}[${level}] ${component}: $message"
    
    # Log to console if enabled
    if [[ "$XANADOS_LOG_TO_CONSOLE" == "true" ]]; then
        case "${level^^}" in
            DEBUG)
                print_debug "$message"
                ;;
            INFO)
                print_status "$message"
                ;;
            SUCCESS)
                print_success "$message"
                ;;
            WARNING|WARN)
                print_warning "$message"
                ;;
            ERROR)
                print_error "$message"
                ;;
            CRITICAL)
                print_error "[CRITICAL] $message"
                ;;
        esac
    fi
    
    # Log to file if configured
    if [[ -n "$XANADOS_LOG_FILE" ]]; then
        echo "$log_entry" >> "$XANADOS_LOG_FILE"
    fi
}

# Convenience logging functions
log_debug() {
    log_message "DEBUG" "$1" "$2"
}

log_info() {
    log_message "INFO" "$1" "$2"
}

log_success() {
    log_message "SUCCESS" "$1" "$2"
}

log_warning() {
    log_message "WARNING" "$1" "$2"
}

log_warn() {
    log_warning "$1" "$2"
}

log_error() {
    log_message "ERROR" "$1" "$2"
}

log_critical() {
    log_message "CRITICAL" "$1" "$2"
}

# Log step/phase information
log_step() {
    local step_name="$1"
    local description="$2"
    
    log_message "INFO" "STEP: $step_name" "$3"
    if [[ -n "$description" ]]; then
        log_message "INFO" "$description" "$3"
    fi
}

# Log script start/end
log_script_start() {
    local script_name="${1:-${0##*/}}"
    local script_version="$2"
    
    log_message "INFO" "=== Script started: $script_name ${script_version:+v$script_version} ==="
    log_message "INFO" "PID: $$"
    log_message "INFO" "User: $(whoami)"
    log_message "INFO" "Working directory: $(pwd)"
    log_message "INFO" "Command line: $0 $*"
}

log_script_end() {
    local script_name="${1:-${0##*/}}"
    local exit_code="${2:-0}"
    
    if [[ "$exit_code" -eq 0 ]]; then
        log_message "SUCCESS" "=== Script completed successfully: $script_name ==="
    else
        log_message "ERROR" "=== Script failed with exit code $exit_code: $script_name ==="
    fi
}

# Log command execution
log_command() {
    local command="$1"
    local description="$2"
    
    log_message "DEBUG" "Executing: $command" "${3:-cmd}"
    if [[ -n "$description" ]]; then
        log_message "INFO" "$description"
    fi
}

# Log file operations
log_file_operation() {
    local operation="$1"
    local file="$2"
    local description="$3"
    
    case "$operation" in
        create)
            log_message "INFO" "Creating file: $file${description:+ ($description)}"
            ;;
        delete)
            log_message "INFO" "Deleting file: $file${description:+ ($description)}"
            ;;
        copy)
            log_message "INFO" "Copying file: $file${description:+ ($description)}"
            ;;
        move)
            log_message "INFO" "Moving file: $file${description:+ ($description)}"
            ;;
        *)
            log_message "INFO" "$operation: $file${description:+ ($description)}"
            ;;
    esac
}

# Log performance metrics
log_performance() {
    local operation="$1"
    local duration="$2"
    local unit="${3:-seconds}"
    
    log_message "INFO" "Performance: $operation completed in $duration $unit"
}

# Create a structured log entry for errors with context
log_error_context() {
    local error_message="$1"
    local function_name="$2"
    local line_number="$3"
    local file_name="${4:-${0##*/}}"
    
    log_message "ERROR" "$error_message"
    log_message "ERROR" "Context: $file_name:$function_name():$line_number"
    
    # Also log to stderr for immediate visibility
    echo "ERROR: $error_message" >&2
    echo "Context: $file_name:$function_name():$line_number" >&2
}

# Set up trap for logging script exit
setup_exit_logging() {
    local script_name="${1:-${0##*/}}"
    
    trap 'log_script_end '"'"'$script_name'"'"' $?' EXIT
}

# Log system information for debugging
log_system_info() {
    log_message "DEBUG" "System Information:"
    log_message "DEBUG" "  OS: $(uname -s) $(uname -r)"
    log_message "DEBUG" "  Architecture: $(uname -m)"
    log_message "DEBUG" "  Hostname: $(hostname)"
    log_message "DEBUG" "  User: $(whoami) (UID: $(id -u))"
    log_message "DEBUG" "  Shell: $SHELL"
    log_message "DEBUG" "  Working Directory: $(pwd)"
    log_message "DEBUG" "  PATH: $PATH"
}

# Export commonly used functions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Logging Library v1.0.0"
    echo "This library should be sourced, not executed directly."
    exit 1
fi
