#!/bin/bash
# xanadOS Advanced Logging Library
# Enhanced logging capabilities with file output and level management
# Version: 3.0.0 - Enhanced with 2024/2025 best practices

# Bash strict mode - 2024 best practice
set -euo pipefail
IFS=$'\n\t'

# Prevent multiple sourcing
[[ "${XANADOS_LOGGING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_LOGGING_LOADED="true"

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/directories.sh"

# Enhanced logging configuration with standardized directories
readonly XANADOS_LOG_LEVEL="${XANADOS_LOG_LEVEL:-INFO}"
readonly XANADOS_LOG_FILE="${XANADOS_LOG_FILE:-}"
readonly XANADOS_LOG_TO_CONSOLE="${XANADOS_LOG_TO_CONSOLE:-true}"
readonly XANADOS_LOG_TIMESTAMP="${XANADOS_LOG_TIMESTAMP:-true}"
readonly XANADOS_LOG_STRUCTURED="${XANADOS_LOG_STRUCTURED:-false}"
readonly XANADOS_LOG_ROTATION="${XANADOS_LOG_ROTATION:-true}"
readonly XANADOS_LOG_MAX_SIZE="${XANADOS_LOG_MAX_SIZE:-10485760}"  # 10MB default
readonly XANADOS_LOG_MAX_FILES="${XANADOS_LOG_MAX_FILES:-5}"        # Keep 5 rotated files

# Security: Restrict log file permissions
readonly XANADOS_LOG_PERMISSIONS="${XANADOS_LOG_PERMISSIONS:-600}"

# Performance: Enable async logging for high-volume scenarios
readonly XANADOS_LOG_ASYNC="${XANADOS_LOG_ASYNC:-false}"
readonly XANADOS_LOG_BUFFER_SIZE="${XANADOS_LOG_BUFFER_SIZE:-1000}"

# Log levels (numeric for comparison) - check if already defined
if [[ -z "${LOG_LEVEL_DEBUG:-}" ]]; then
    readonly LOG_LEVEL_DEBUG=0
    readonly LOG_LEVEL_INFO=1
    readonly LOG_LEVEL_SUCCESS=2
    readonly LOG_LEVEL_WARNING=3
    readonly LOG_LEVEL_ERROR=4
    readonly LOG_LEVEL_CRITICAL=5
fi

# Log buffer for async logging
declare -a LOG_BUFFER=()
declare -g LOG_BUFFER_COUNT=0

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

# Auto-initialize logging system for script (Task 3.2.3 enhancement)
auto_init_logging() {
    local script_name="${1:-${0##*/}}"
    local log_level="${2:-$XANADOS_LOG_LEVEL}"
    local script_type="${3:-general}"

    # Use standardized log directory from Task 3.2.1
    local log_file
    log_file="$(get_log_filename "${script_name%.*}" "log")"

    init_logging "$log_file" "$log_level" true
    log_script_start "$script_name" "auto-init"

    # Set up automatic script end logging
    setup_exit_logging "$script_name"

    return 0
}

# Enhanced initialization with standardized directories
init_logging() {
    local log_file="$1"
    local log_level="${2:-INFO}"
    local log_to_console="${3:-true}"

    XANADOS_LOG_LEVEL="$log_level"
    XANADOS_LOG_TO_CONSOLE="$log_to_console"

    if [[ -n "$log_file" ]]; then
        # Use standardized log directory
        local log_dir
        log_dir="$(dirname "$log_file")"

        # Ensure log directory exists using standardized function
        if ! safe_mkdir "$log_dir"; then
            print_warning "Failed to create log directory: $log_dir"
            return 1
        fi

        # Rotate log file if it exists and is large
        if [[ "$XANADOS_LOG_ROTATION" == "true" && -f "$log_file" ]]; then
            rotate_log_file "$log_file"
        fi

        XANADOS_LOG_FILE="$log_file"

        # Create log file with enhanced header
        {
            echo "# xanadOS Enhanced Log File"
            echo "# Started: $(timestamp)"
            echo "# Log Level: $log_level"
            echo "# Script: ${0##*/}"
            echo "# PID: $$"
            echo "# User: $(whoami)"
            echo "# Working Directory: $(pwd)"
            echo "# Host: $(hostname 2>/dev/null || uname -n 2>/dev/null || echo 'unknown')"
            echo "# Log Format: $(if [[ "$XANADOS_LOG_STRUCTURED" == "true" ]]; then echo "Structured JSON"; else echo "Human Readable"; fi)"
            echo ""
        } > "$log_file"

        log_message "INFO" "Advanced logging initialized: $log_file (level: $log_level)"
        log_message "DEBUG" "Log rotation: $XANADOS_LOG_ROTATION, Max size: $XANADOS_LOG_MAX_SIZE bytes"
    fi
}

# Log file rotation (Task 3.2.3 enhancement)
rotate_log_file() {
    local log_file="$1"

    if [[ ! -f "$log_file" ]]; then
        return 0
    fi

    local file_size
    file_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)

    if [[ $file_size -gt $XANADOS_LOG_MAX_SIZE ]]; then
        local base_name="${log_file%.*}"
        local extension="${log_file##*.}"

        # Rotate existing log files
        for ((i = XANADOS_LOG_MAX_FILES - 1; i >= 1; i--)); do
            local old_file="${base_name}.${i}.${extension}"
            local new_file="${base_name}.$((i + 1)).${extension}"

            if [[ -f "$old_file" ]]; then
                if [[ $i -eq $((XANADOS_LOG_MAX_FILES - 1)) ]]; then
                    rm -f "$old_file"  # Remove oldest
                else
                    mv "$old_file" "$new_file"
                fi
            fi
        done

        # Move current log to .1
        mv "$log_file" "${base_name}.1.${extension}"

        log_message "INFO" "Log file rotated: $log_file"
    fi
}

# Core enhanced logging function (Task 3.2.3 enhancement)
log_message() {
    local level="$1"
    local message="$2"
    local component="${3:-${0##*/}}"
    local extra_data="$4"  # Optional structured data

    # Check if message should be logged
    if ! should_log "$level"; then
        return 0
    fi

    local timestamp_str=""
    if [[ "$XANADOS_LOG_TIMESTAMP" == "true" ]]; then
        timestamp_str="$(timestamp) "
    fi

    # Create log entry based on format preference
    local log_entry
    if [[ "$XANADOS_LOG_STRUCTURED" == "true" ]]; then
        # Structured JSON logging for automated parsing
        log_entry=$(create_structured_log_entry "$level" "$message" "$component" "$extra_data")
    else
        # Human-readable logging
        log_entry="${timestamp_str}[${level}] ${component}: $message"
        if [[ -n "$extra_data" ]]; then
            log_entry="$log_entry | $extra_data"
        fi
    fi

    # Log to console if enabled with enhanced formatting
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
                echo "CRITICAL ERROR in $component - Check logs: $XANADOS_LOG_FILE" >&2
                ;;
        esac
    fi

    # Log to file if configured
    if [[ -n "$XANADOS_LOG_FILE" ]]; then
        echo "$log_entry" >> "$XANADOS_LOG_FILE"

        # Force sync for critical messages
        if [[ "${level^^}" == "CRITICAL" ]]; then
            sync
        fi
    fi
}

# Create structured log entry in JSON format
create_structured_log_entry() {
    local level="$1"
    local message="$2"
    local component="$3"
    local extra_data="$4"

    local timestamp_iso
    timestamp_iso=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Basic JSON structure
    local json_entry="{"
    json_entry+='"timestamp":"'$timestamp_iso'",'
    json_entry+='"level":"'$level'",'
    json_entry+='"component":"'$component'",'
    json_entry+='"message":"'${message//\"/\\\"}'\"'
    json_entry+='"pid":'$$','
    json_entry+='"user":"'$(whoami)'"'

    # Add extra structured data if provided
    if [[ -n "$extra_data" ]]; then
        json_entry+=','$extra_data''
    fi

    json_entry+="}"
    echo "$json_entry"
}

# Enhanced convenience logging functions with context support
log_debug() {
    log_message "DEBUG" "$1" "${2:-${FUNCNAME[1]:-main}}" "${3:-}"
}

log_info() {
    log_message "INFO" "$1" "${2:-${FUNCNAME[1]:-main}}" "${3:-}"
}

log_success() {
    log_message "SUCCESS" "$1" "${2:-${FUNCNAME[1]:-main}}" "${3:-}"
}

log_warning() {
    log_message "WARNING" "$1" "${2:-${FUNCNAME[1]:-main}}" "${3:-}"
}

log_warn() {
    log_warning "${1:-}" "${2:-}" "${3:-}"
}

log_error() {
    log_message "ERROR" "$1" "${2:-${FUNCNAME[1]:-main}}" "${3:-}"
}

log_critical() {
    log_message "CRITICAL" "$1" "${2:-${FUNCNAME[1]:-main}}" "${3:-}"
}

# Enhanced step/phase logging with timing
log_step() {
    local step_name="$1"
    local description="$2"
    local component="${3:-${FUNCNAME[1]}}"

    local step_data='"step_name":"'$step_name'"'
    if [[ -n "$description" ]]; then
        step_data+='"step_description":"'$description'"'
    fi

    log_message "INFO" "STEP: $step_name" "$component" "$step_data"
    if [[ -n "$description" ]]; then
        log_message "INFO" "$description" "$component"
    fi
}

# Enhanced script lifecycle logging
log_script_start() {
    local script_name="${1:-${0##*/}}"
    local script_version="$2"
    local extra_info="$3"

    local start_data='"event":"script_start","script":"'$script_name'"'
    if [[ -n "$script_version" ]]; then
        start_data+='"version":"'$script_version'"'
    fi
    start_data+='"args":"'$*'"'

    log_message "INFO" "=== Script started: $script_name ${script_version:+v$script_version} ===" "$script_name" "$start_data"
    log_message "INFO" "PID: $$" "$script_name"
    log_message "INFO" "User: $(whoami)" "$script_name"
    log_message "INFO" "Working directory: $(pwd)" "$script_name"
    log_message "INFO" "Command line: $0 $*" "$script_name"

    if [[ -n "$extra_info" ]]; then
        log_message "INFO" "$extra_info" "$script_name"
    fi

    # Log environment variables relevant to xanadOS
    log_debug "XANADOS_LOG_LEVEL: $XANADOS_LOG_LEVEL" "$script_name"
    log_debug "XANADOS_LOG_STRUCTURED: $XANADOS_LOG_STRUCTURED" "$script_name"
}

log_script_end() {
    local script_name="${1:-${0##*/}}"
    local exit_code="${2:-0}"
    local execution_time="$3"

    local end_data='"event":"script_end","script":"'$script_name'","exit_code":'$exit_code''
    if [[ -n "$execution_time" ]]; then
        end_data+='"execution_time":"'$execution_time'"'
    fi

    if [[ "$exit_code" -eq 0 ]]; then
        log_message "SUCCESS" "=== Script completed successfully: $script_name ===" "$script_name" "$end_data"
    else
        log_message "ERROR" "=== Script failed with exit code $exit_code: $script_name ===" "$script_name" "$end_data"
    fi

    if [[ -n "$execution_time" ]]; then
        log_message "INFO" "Total execution time: $execution_time" "$script_name"
    fi
}

# Enhanced command execution logging with timing
log_command() {
    local command="$1"
    local description="$2"
    local component="${3:-${FUNCNAME[1]}}"

    local start_time=$(date +%s%3N)
    log_message "DEBUG" "Executing: $command" "$component"

    if [[ -n "$description" ]]; then
        log_message "INFO" "$description" "$component"
    fi

    # Return timing data for performance logging
    echo "$start_time"
}

# Log command completion with timing
log_command_result() {
    local command="$1"
    local exit_code="$2"
    local start_time="$3"
    local component="${4:-${FUNCNAME[1]}}"

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    local result_data='"command":"'${command//\"/\\\"}'","exit_code":'$exit_code',"duration_ms":'$duration''

    if [[ $exit_code -eq 0 ]]; then
        log_message "DEBUG" "Command completed successfully: $command (${duration}ms)" "$component" "$result_data"
    else
        log_message "ERROR" "Command failed (exit $exit_code): $command (${duration}ms)" "$component" "$result_data"
    fi
}

# Enhanced file operation logging
log_file_operation() {
    local operation="$1"
    local file="$2"
    local description="$3"
    local component="${4:-${FUNCNAME[1]}}"

    local file_data='"operation":"'$operation'","file":"'$file'"'

    case "$operation" in
        create)
            log_message "INFO" "Creating file: $file${description:+ ($description)}" "$component" "$file_data"
            ;;
        delete)
            log_message "INFO" "Deleting file: $file${description:+ ($description)}" "$component" "$file_data"
            ;;
        copy)
            log_message "INFO" "Copying file: $file${description:+ ($description)}" "$component" "$file_data"
            ;;
        move)
            log_message "INFO" "Moving file: $file${description:+ ($description)}" "$component" "$file_data"
            ;;
        backup)
            log_message "INFO" "Backing up file: $file${description:+ ($description)}" "$component" "$file_data"
            ;;
        *)
            log_message "INFO" "$operation: $file${description:+ ($description)}" "$component" "$file_data"
            ;;
    esac
}

# Enhanced performance logging with structured data
log_performance() {
    local operation="$1"
    local duration="$2"
    local unit="${3:-seconds}"
    local component="${4:-${FUNCNAME[1]}}"
    local extra_metrics="$5"

    local perf_data='"operation":"'$operation'","duration":'$duration',"unit":"'$unit'"'
    if [[ -n "$extra_metrics" ]]; then
        perf_data+=','$extra_metrics''
    fi

    log_message "INFO" "Performance: $operation completed in $duration $unit" "$component" "$perf_data"
}

# Log system resource usage
log_resource_usage() {
    local operation="$1"
    local component="${2:-${FUNCNAME[1]}}"

    if command -v ps >/dev/null 2>&1; then
        local cpu_mem
        cpu_mem=$(ps -o %cpu,%mem -p $$ | tail -1)
        local cpu=$(echo "$cpu_mem" | awk '{print $1}')
        local mem=$(echo "$cpu_mem" | awk '{print $2}')

        local resource_data='"cpu_percent":'$cpu',"memory_percent":'$mem',"pid":'$$''
        log_message "DEBUG" "Resource usage for $operation: CPU ${cpu}%, Memory ${mem}%" "$component" "$resource_data"
    fi
}

# Enhanced error logging with context and stack trace
log_error_context() {
    local error_message="$1"
    local function_name="${2:-${FUNCNAME[1]}}"
    local line_number="$3"
    local file_name="${4:-${0##*/}}"
    local component="${5:-$file_name}"

    local error_data='"error_type":"context","function":"'$function_name'","line":'${line_number:-0}',"file":"'$file_name'"'

    log_message "ERROR" "$error_message" "$component" "$error_data"
    log_message "ERROR" "Context: $file_name:$function_name():${line_number:-unknown}" "$component"

    # Log stack trace for debugging
    if [[ "$XANADOS_LOG_LEVEL" == "DEBUG" ]]; then
        log_debug "Stack trace:" "$component"
        local i=1
        while caller $i >/dev/null 2>&1; do
            local caller_info
            caller_info=$(caller $i)
            log_debug "  Frame $i: $caller_info" "$component"
            ((i++))
        done
    fi

    # Also log to stderr for immediate visibility
    echo "ERROR: $error_message" >&2
    echo "Context: $file_name:$function_name():${line_number:-unknown}" >&2
}

# Task 3.2.3: Migration helper functions
# These functions help scripts migrate from basic print_* functions to advanced logging

# Initialize advanced logging for any script (auto-migration helper)
enable_advanced_logging() {
    local script_name="${1:-${0##*/}}"
    local log_level="${2:-INFO}"

    # Auto-initialize with standardized logging
    auto_init_logging "$script_name" "$log_level"

    # Create aliases for gradual migration
    create_logging_aliases

    log_info "Advanced logging enabled for $script_name" "migration"
}

# Create aliases for gradual migration from print_* functions
create_logging_aliases() {
    # Backward compatibility aliases
    alias migrate_print_info='log_info'
    alias migrate_print_success='log_success'
    alias migrate_print_warning='log_warning'
    alias migrate_print_error='log_error'
    alias migrate_print_debug='log_debug'

    log_debug "Migration aliases created for print_* functions" "migration"
}

# Bulk migration function to convert print_* calls to log_* calls
migrate_script_logging() {
    local script_file="$1"
    local backup="${2:-true}"

    if [[ ! -f "$script_file" ]]; then
        log_error "Script file not found: $script_file" "migration"
        return 1
    fi

    log_info "Migrating logging in script: $script_file" "migration"

    # Create backup if requested
    if [[ "$backup" == "true" ]]; then
        cp "$script_file" "${script_file}.backup"
        log_info "Backup created: ${script_file}.backup" "migration"
    fi

    # Perform migration
    sed -i.tmp \
        -e 's/print_info/log_info/g' \
        -e 's/print_success/log_success/g' \
        -e 's/print_warning/log_warning/g' \
        -e 's/print_error/log_error/g' \
        -e 's/print_debug/log_debug/g' \
        "$script_file"

    rm -f "${script_file}.tmp"

    log_success "Script migration completed: $script_file" "migration"
}

# Set up enhanced trap for logging script exit with timing
setup_exit_logging() {
    local script_name="${1:-${0##*/}}"
    local start_time="${2:-$(date +%s)}"

    trap 'local exit_code=$?; local end_time=$(date +%s); local duration=$((end_time - '"$start_time"')); log_script_end "'"$script_name"'" $exit_code "${duration}s"' EXIT
}

# Log system information for debugging (enhanced)
log_system_info() {
    local component="${1:-system}"

    log_message "DEBUG" "System Information:" "$component"
    log_message "DEBUG" "  OS: $(uname -s) $(uname -r)" "$component"
    log_message "DEBUG" "  Architecture: $(uname -m)" "$component"
    log_message "DEBUG" "  Hostname: $(hostname 2>/dev/null || uname -n 2>/dev/null || echo 'unknown')" "$component"
    log_message "DEBUG" "  User: $(whoami) (UID: $(id -u))" "$component"
    log_message "DEBUG" "  Shell: $SHELL" "$component"
    log_message "DEBUG" "  Working Directory: $(pwd)" "$component"
    log_message "DEBUG" "  PATH: $PATH" "$component"

    # Enhanced system info
    if command -v free >/dev/null 2>&1; then
        local mem_info
        mem_info=$(free -h | grep '^Mem:')
        log_message "DEBUG" "  Memory: $mem_info" "$component"
    fi

    if command -v df >/dev/null 2>&1; then
        local disk_info
        disk_info=$(df -h . | tail -1)
        log_message "DEBUG" "  Disk Space (current dir): $disk_info" "$component"
    fi
}

# Configuration management for logging
set_log_level() {
    local new_level="$1"
    local old_level="$XANADOS_LOG_LEVEL"

    XANADOS_LOG_LEVEL="$new_level"
    log_info "Log level changed from $old_level to $new_level" "config"
}

enable_structured_logging() {
    XANADOS_LOG_STRUCTURED="true"
    log_info "Structured JSON logging enabled" "config"
}

disable_structured_logging() {
    XANADOS_LOG_STRUCTURED="false"
    log_info "Structured logging disabled, using human-readable format" "config"
}

# Log cleanup and maintenance
cleanup_old_logs() {
    local log_dir="${1:-$(get_log_dir false)}"
    local days_old="${2:-30}"

    if [[ ! -d "$log_dir" ]]; then
        log_warning "Log directory does not exist: $log_dir" "cleanup"
        return 0
    fi

    log_info "Cleaning logs older than $days_old days in $log_dir" "cleanup"

    local cleaned_count
    cleaned_count=$(find "$log_dir" -name "*.log*" -type f -mtime +${days_old} -delete -print | wc -l)

    log_info "Cleaned $cleaned_count old log files" "cleanup"
}

# Export commonly used functions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Advanced Logging Library v2.0.0 - Task 3.2.3"
    echo "This library should be sourced, not executed directly."
    exit 1
fi

# ========================================
# Task 3.2.3: Advanced Logging Deployment
# Migration and deployment helpers
# ========================================

# Auto-detect and migrate legacy logging patterns
migrate_script_logging() {
    local script_file="$1"
    local backup="${2:-true}"

    if [[ ! -f "$script_file" ]]; then
        log_error "Script file does not exist: $script_file" "migration"
        return 1
    fi

    log_info "Migrating script to advanced logging: $script_file" "migration"

    # Create backup if requested
    if [[ "$backup" == "true" ]]; then
        local backup_file="${script_file}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$script_file" "$backup_file"
        log_info "Created backup: $backup_file" "migration"
    fi

    # Migration patterns
    local temp_file="/tmp/xanados-migration-$$"

    # Replace common logging patterns
    sed -e 's/echo "\[INFO\]/log_info "/g' \
        -e 's/echo "\[ERROR\]/log_error "/g' \
        -e 's/echo "\[SUCCESS\]/log_success "/g' \
        -e 's/echo "\[WARNING\]/log_warning "/g' \
        -e 's/echo "\[DEBUG\]/log_debug "/g' \
        -e 's/print_info /log_info /g' \
        -e 's/print_error /log_error /g' \
        -e 's/print_success /log_success /g' \
        -e 's/print_warning /log_warning /g' \
        -e 's/print_debug /log_debug /g' \
        "$script_file" > "$temp_file"

    # Check if migration made changes
    if ! diff -q "$script_file" "$temp_file" >/dev/null 2>&1; then
        mv "$temp_file" "$script_file"
        log_success "Script logging migration completed: $script_file" "migration"
        return 0
    else
        rm -f "$temp_file"
        log_info "No migration needed for: $script_file" "migration"
        return 0
    fi
}

# Deploy advanced logging to a script (adds initialization)
deploy_advanced_logging() {
    local script_file="$1"
    local script_type="${2:-general}"
    local log_level="${3:-INFO}"

    if [[ ! -f "$script_file" ]]; then
        log_error "Script file does not exist: $script_file" "deployment"
        return 1
    fi

    log_info "Deploying advanced logging to: $script_file" "deployment"

    # Check if script already has advanced logging
    if grep -q "auto_init_logging" "$script_file"; then
        log_info "Script already has advanced logging: $script_file" "deployment"
        return 0
    fi

    # Create deployment content
    local deployment_content='
# ========================================
# Task 3.2.3: Advanced Logging Deployment
# ========================================

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/directories.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"

# Auto-initialize advanced logging
auto_init_logging "$(basename "$0")" "'$log_level'" "'$script_type'"

# Enhanced error handling with logging
set -eE
trap '\''log_error "Script failed at line $LINENO: $(sed -n "${LINENO}p" "$0")" "$(basename "$0")"'\'' ERR
trap '\''log_script_end "$(basename "$0")" $? "$SECONDS"'\'' EXIT

'

    # Insert deployment content after shebang
    local temp_file="/tmp/xanados-deploy-$$"
    {
        head -1 "$script_file"  # Preserve shebang
        echo "$deployment_content"
        tail -n +2 "$script_file"  # Rest of the script
    } > "$temp_file"

    mv "$temp_file" "$script_file"
    chmod +x "$script_file"

    log_success "Advanced logging deployed to: $script_file" "deployment"
}

# Bulk migration of scripts in a directory
bulk_migrate_scripts() {
    local directory="$1"
    local pattern="${2:-*.sh}"
    local backup="${3:-true}"

    if [[ ! -d "$directory" ]]; then
        log_error "Directory does not exist: $directory" "bulk-migration"
        return 1
    fi

    log_info "Starting bulk migration in: $directory (pattern: $pattern)" "bulk-migration"

    local migrated_count=0
    local failed_count=0

    while IFS= read -r -d '' script_file; do
        if migrate_script_logging "$script_file" "$backup"; then
            ((migrated_count++))
        else
            ((failed_count++))
            log_warning "Migration failed for: $script_file" "bulk-migration"
        fi
    done < <(find "$directory" -name "$pattern" -type f -print0)

    log_success "Bulk migration completed: $migrated_count migrated, $failed_count failed" "bulk-migration"
}

# Generate logging configuration for a project
generate_logging_config() {
    local config_file="${1:-$HOME/.config/xanados/logging.conf}"
    local config_dir
    config_dir="$(dirname "$config_file")"

    # Ensure config directory exists
    mkdir -p "$config_dir"

    log_info "Generating logging configuration: $config_file" "config"

    cat > "$config_file" << 'EOF'
# xanadOS Advanced Logging Configuration
# Task 3.2.3: Advanced Logging Deployment

# Default log level (DEBUG, INFO, SUCCESS, WARNING, ERROR, CRITICAL)
XANADOS_LOG_LEVEL=INFO

# Enable/disable console logging
XANADOS_LOG_TO_CONSOLE=true

# Enable/disable timestamps in logs
XANADOS_LOG_TIMESTAMP=true

# Enable structured JSON logging (for automated parsing)
XANADOS_LOG_STRUCTURED=false

# Enable log file rotation
XANADOS_LOG_ROTATION=true

# Maximum log file size before rotation (bytes)
XANADOS_LOG_MAX_SIZE=10485760

# Maximum number of rotated log files to keep
XANADOS_LOG_MAX_FILES=5

# Custom log file path (optional - uses standardized directories if empty)
XANADOS_LOG_FILE=

# Environment-specific settings
# Uncomment and modify as needed:

# Development environment
# XANADOS_LOG_LEVEL=DEBUG
# XANADOS_LOG_STRUCTURED=false

# Production environment
# XANADOS_LOG_LEVEL=WARNING
# XANADOS_LOG_STRUCTURED=true
# XANADOS_LOG_TO_CONSOLE=false

# Performance monitoring
# XANADOS_LOG_LEVEL=INFO
# XANADOS_LOG_STRUCTURED=true
EOF

    log_success "Logging configuration created: $config_file" "config"
    log_info "To use this configuration, source it before running scripts:" "config"
    log_info "  source $config_file" "config"
}

# Validate logging deployment across project
validate_logging_deployment() {
    local project_root="${1:-$(get_project_root)}"
    local validation_report="${2:-validation-report.txt}"

    log_info "Validating logging deployment in: $project_root" "validation"

    local report_file
    report_file="$(get_results_filename "logging-validation" "txt" "validation")"

    {
        echo "# xanadOS Logging Deployment Validation Report"
        echo "# Generated: $(date)"
        echo "# Project Root: $project_root"
        echo

        echo "## Scripts with Advanced Logging"
        find "$project_root/scripts" -name "*.sh" -type f -exec grep -l "auto_init_logging" {} \; | while read -r script; do
            echo "✅ $script"
        done

        echo
        echo "## Scripts Needing Migration"
        find "$project_root/scripts" -name "*.sh" -type f -exec grep -L "auto_init_logging" {} \; | while read -r script; do
            if grep -q "echo.*\[INFO\]\|echo.*\[ERROR\]\|print_info\|print_error" "$script"; then
                echo "⚠️  $script (has legacy logging patterns)"
            else
                echo "📋 $script (minimal logging)"
            fi
        done

        echo
        echo "## Logging Configuration Status"
        if [[ -f "$HOME/.config/xanados/logging.conf" ]]; then
            echo "✅ Logging configuration exists: $HOME/.config/xanados/logging.conf"
        else
            echo "❌ No logging configuration found"
        fi

        echo
        echo "## Log Directory Structure"
        local log_dir
        log_dir="$(get_log_dir false)"
        if [[ -d "$log_dir" ]]; then
            echo "✅ Log directory exists: $log_dir"
            echo "   Files: $(find "$log_dir" -name "*.log*" -type f | wc -l)"
            echo "   Size: $(du -sh "$log_dir" 2>/dev/null | cut -f1)"
        else
            echo "❌ Log directory not found: $log_dir"
        fi

    } | tee "$report_file"

    log_success "Validation report created: $report_file" "validation"
    return 0
}

# Performance monitoring for logging system
monitor_logging_performance() {
    local test_iterations="${1:-1000}"
    local component="logging-performance"

    log_info "Monitoring logging performance ($test_iterations iterations)" "$component"

    local start_time end_time duration

    # Test console logging performance
    start_time=$(date +%s%3N)
    for ((i=1; i<=test_iterations; i++)); do
        log_debug "Performance test message $i" "$component" > /dev/null 2>&1
    done
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))

    log_performance "console_logging_${test_iterations}_calls" "$duration" "milliseconds" "$component"

    # Test file logging performance
    local temp_log="/tmp/xanados-perf-test-$$.log"
    init_logging "$temp_log" "DEBUG" false

    start_time=$(date +%s%3N)
    for ((i=1; i<=test_iterations; i++)); do
        log_debug "File performance test message $i" "$component"
    done
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))

    log_performance "file_logging_${test_iterations}_calls" "$duration" "milliseconds" "$component"

    # Cleanup
    rm -f "$temp_log"

    log_success "Logging performance monitoring completed" "$component"
}

# Setup automatic exit logging for any script
setup_exit_logging() {
    local script_name="${1:-${0##*/}}"
    local start_time="${2:-$SECONDS}"

    # Enhanced exit trap that logs execution time and exit status
    trap "
        local exit_code=\$?
        local execution_time=\$((SECONDS - $start_time))
        log_script_end '$script_name' \$exit_code \"\${execution_time}s\"
        exit \$exit_code
    " EXIT
}
