#!/bin/bash
# xanadOS Common Functions Library
# Shared utilities for all xanadOS shell scripts
# Version: 2.0.0 - Enhanced with 2024/2025 best practices

# Bash strict mode - 2024 best practice
set -euo pipefail
IFS=$'\n\t'

# Prevent multiple sourcing
[[ "${XANADOS_COMMON_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_COMMON_LOADED="true"

# Script metadata (2024 best practice for library identification)
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_AUTHOR="xanadOS Team"
readonly SCRIPT_DESCRIPTION="Core library for xanadOS shell scripts"
readonly SCRIPT_USE_TYPE="lib"

# Defensive programming - validate environment early
validate_environment() {
    # Check for required Bash version (4.0+)
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        echo "ERROR: Bash 4.0+ required. Current version: $BASH_VERSION" >&2
        return 1
    fi

    # Validate we're running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "WARNING: xanadOS is designed for Linux systems" >&2
    fi

    return 0
}

# Initialize environment validation
validate_environment

# Enhanced logging with structured output (2024 best practice)
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Default log level from environment or INFO
readonly LOG_LEVEL="${XANADOS_LOG_LEVEL:-$LOG_LEVEL_INFO}"

# Create log directory if it doesn't exist
readonly LOG_DIR="${XANADOS_LOG_DIR:-/tmp/xanados-logs}"
mkdir -p "$LOG_DIR" 2>/dev/null || true

log_message() {
    local level="$1"
    local level_num="$2"
    shift 2

    # Only log if level is >= current log level
    [[ $level_num -ge $LOG_LEVEL ]] || return 0

    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local caller="${BASH_SOURCE[2]:-unknown}:${BASH_LINENO[1]:-0}"

    echo "[$timestamp] [$level] [$caller] $*" >&2

    # Also log to file if LOG_DIR is writable
    if [[ -w "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] [$caller] $*" >> "$LOG_DIR/xanados.log" 2>/dev/null || true
    fi
}

log_debug() {
    log_message "DEBUG" "$LOG_LEVEL_DEBUG" "$@"
}

log_info() {
    log_message "INFO" "$LOG_LEVEL_INFO" "$@"
}

log_warn() {
    log_message "WARN" "$LOG_LEVEL_WARN" "$@"
}

log_error() {
    log_message "ERROR" "$LOG_LEVEL_ERROR" "$@"
}

# Color definitions for consistent output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly BOLD='\033[1m'
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

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
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
        log_error "This script should not be run as root"
        log_warning "Please run as a regular user"
        return 1
    fi
    return 0
}

# Check if command exists
command_exists() {
    local cmd="$1"
    local force_check="${2:-false}"

    if [[ -z "$cmd" ]]; then
        return 1
    fi

    # Simple implementation for common.sh - no caching to avoid dependencies
    command -v "$cmd" >/dev/null 2>&1
}

# Safe directory creation with error handling
safe_mkdir() {
    local dir="$1"
    local mode="${2:-755}"

    if [[ -z "$dir" ]]; then
        log_error "safe_mkdir: No directory specified"
        return 1
    fi

    if [[ -d "$dir" ]]; then
        log_debug "Directory already exists: $dir"
        return 0
    fi

    if mkdir -p "$dir" 2>/dev/null; then
        chmod "$mode" "$dir" 2>/dev/null || true
        log_debug "Created directory: $dir"
        return 0
    else
        log_error "Failed to create directory: $dir"
        return 1
    fi
}

# Safe file removal with validation
safe_remove() {
    local target="$1"

    if [[ -z "$target" ]]; then
        log_error "safe_remove: No target specified"
        return 1
    fi

    # Security check - prevent removal of important directories
    case "$target" in
        "/" | "/bin" | "/usr" | "/etc" | "/var" | "/home" | "/root" | "$HOME")
            log_error "safe_remove: Refusing to remove protected directory: $target"
            return 1
            ;;
    esac

    if [[ -e "$target" ]]; then
        rm -rf "$target"
        log_debug "Removed: $target"
    else
        log_debug "Target does not exist: $target"
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
    log_error "$1"
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

    local percent
    if [[ "$total" -eq 0 ]]; then
        percent=100
    else
        percent=$((current * 100 / total))
    fi
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

# ==============================================================================
# Task 3.3.1: Advanced Progress Indicators
# ==============================================================================

# Global variables for progress tracking
declare -g XANADOS_PROGRESS_ENABLED="${XANADOS_PROGRESS_ENABLED:-true}"
declare -g XANADOS_PROGRESS_START_TIME=""
declare -g XANADOS_PROGRESS_LAST_UPDATE=""

# Spinner animation for indeterminate progress
show_spinner() {
    local pid="$1"
    local message="${2:-Working...}"
    local delay=0.1
    local spinstr='|/-\'
    local temp

    if [[ "$XANADOS_PROGRESS_ENABLED" != "true" ]]; then
        return 0
    fi

    echo -n "$message "
    while kill -0 "$pid" 2>/dev/null; do
        temp="${spinstr#?}"
        printf "\r%s %c" "$message" "$spinstr"
        spinstr="$temp${spinstr%"$temp"}"
        sleep "$delay"
    done
    printf "\r%s ✅\n" "$message"
}

# Enhanced progress bar with ETA calculation
show_progress_advanced() {
    local message="$1"
    local current="$2"
    local total="$3"
    local show_eta="${4:-true}"
    local bar_width="${5:-40}"

    if [[ "$XANADOS_PROGRESS_ENABLED" != "true" ]]; then
        return 0
    fi

    # Initialize timing if this is the first call
    local current_time
    current_time=$(date +%s)

    if [[ -z "$XANADOS_PROGRESS_START_TIME" ]] || [[ "$current" -eq 0 ]]; then
        XANADOS_PROGRESS_START_TIME="$current_time"
        XANADOS_PROGRESS_LAST_UPDATE="$current_time"
    fi

    # Throttle updates to avoid too frequent refreshes
    if [[ $((current_time - XANADOS_PROGRESS_LAST_UPDATE)) -lt 1 ]] && [[ "$current" -ne "$total" ]]; then
        return 0
    fi
    XANADOS_PROGRESS_LAST_UPDATE="$current_time"

    local percent
    if [[ "$total" -eq 0 ]]; then
        percent=100
    else
        percent=$((current * 100 / total))
    fi
    local filled=$((percent * bar_width / 100))

    # Calculate ETA
    local eta_str=""
    if [[ "$show_eta" == "true" ]] && [[ "$current" -gt 0 ]] && [[ "$current" -lt "$total" ]]; then
        local elapsed=$((current_time - XANADOS_PROGRESS_START_TIME))
        local rate=$((current * 1000 / (elapsed * 1000 / 1000 + 1)))  # items per second
        local remaining=$((total - current))
        local eta=$((remaining / (rate + 1)))

        if [[ "$eta" -gt 3600 ]]; then
            eta_str=$(printf " ETA: %dh%dm" $((eta / 3600)) $(((eta % 3600) / 60)))
        elif [[ "$eta" -gt 60 ]]; then
            eta_str=$(printf " ETA: %dm%ds" $((eta / 60)) $((eta % 60)))
        elif [[ "$eta" -gt 0 ]]; then
            eta_str=$(printf " ETA: %ds" "$eta")
        fi
    fi

    # Build progress bar
    printf "\r${BLUE}[INFO]${NC} %s [" "$message"
    printf "${GREEN}%*s${NC}" "$filled" "" | tr ' ' '█'
    printf "%*s" $((bar_width - filled)) "" | tr ' ' '░'
    printf "] %3d%% (%d/%d)%s" "$percent" "$current" "$total" "$eta_str"

    # Clear line and add newline when complete
    if [[ "$current" -eq "$total" ]]; then
        printf "\r${BLUE}[INFO]${NC} %s [" "$message"
        printf "${GREEN}%*s${NC}" "$bar_width" "" | tr ' ' '█'
        printf "] ${GREEN}✅ Complete${NC} (%d/%d)\n" "$total" "$total"
        XANADOS_PROGRESS_START_TIME=""
    fi
}

# Progress indicator for step-based operations
show_step_progress() {
    local step_name="$1"
    local current_step="$2"
    local total_steps="$3"
    local step_message="${4:-}"

    if [[ "$XANADOS_PROGRESS_ENABLED" != "true" ]]; then
        return 0
    fi

    local percent=$((current_step * 100 / total_steps))

    printf "\r${CYAN}[STEP %d/%d]${NC} %s" "$current_step" "$total_steps" "$step_name"

    if [[ -n "$step_message" ]]; then
        printf " - %s" "$step_message"
    fi

    printf " (%d%%)" "$percent"

    if [[ "$current_step" -eq "$total_steps" ]]; then
        printf "\n${GREEN}[COMPLETE]${NC} All %d steps finished successfully!\n" "$total_steps"
    else
        printf "...\n"
    fi
}

# Progress indicator for file operations
show_file_progress() {
    local operation="$1"
    local filename="$2"
    local current_size="$3"
    local total_size="$4"

    if [[ "$XANADOS_PROGRESS_ENABLED" != "true" ]]; then
        return 0
    fi

    local percent=$((current_size * 100 / total_size))
    local current_mb=$((current_size / 1024 / 1024))
    local total_mb=$((total_size / 1024 / 1024))

    printf "\r${BLUE}[%s]${NC} %s: %d%% (%dMB/%dMB)" \
        "$operation" "$filename" "$percent" "$current_mb" "$total_mb"

    if [[ "$current_size" -eq "$total_size" ]]; then
        printf "\n${GREEN}[COMPLETE]${NC} %s finished (%dMB)\n" "$filename" "$total_mb"
    fi
}

# Multi-progress indicator for parallel operations
declare -A XANADOS_MULTI_PROGRESS

init_multi_progress() {
    local total="$1"
    local description="${2:-Processing}"

    XANADOS_MULTI_PROGRESS["default_total"]="$total"
    XANADOS_MULTI_PROGRESS["default_current"]="0"
    XANADOS_MULTI_PROGRESS["default_desc"]="$description"
}

update_multi_progress() {
    local current="$1"
    local total="$2"
    local description="${3:-Processing}"

    XANADOS_MULTI_PROGRESS["default_current"]="$current"
    XANADOS_MULTI_PROGRESS["default_total"]="$total"
    XANADOS_MULTI_PROGRESS["default_desc"]="$description"

    show_progress_advanced "$description" "$current" "$total"
}

# Timer-based progress for time-bound operations
show_timer_progress() {
    local operation="$1"
    local duration_seconds="$2"
    local update_interval="${3:-1}"

    if [[ "$XANADOS_PROGRESS_ENABLED" != "true" ]]; then
        return 0
    fi

    local start_time
    start_time=$(date +%s)
    local end_time=$((start_time + duration_seconds))

    while true; do
        local current_time
        current_time=$(date +%s)

        if [[ "$current_time" -ge "$end_time" ]]; then
            show_progress_advanced "$operation" "$duration_seconds" "$duration_seconds"
            break
        fi

        local elapsed=$((current_time - start_time))
        show_progress_advanced "$operation" "$elapsed" "$duration_seconds"

        sleep "$update_interval"
    done
}

# Disable progress indicators (useful for batch/non-interactive mode)
disable_progress() {
    XANADOS_PROGRESS_ENABLED="false"
}

# Enable progress indicators
enable_progress() {
    XANADOS_PROGRESS_ENABLED="true"
}

# Check if progress indicators are enabled
is_progress_enabled() {
    [[ "$XANADOS_PROGRESS_ENABLED" == "true" ]]
}

# Progress wrapper for command execution
run_with_progress() {
    local description="$1"
    shift
    local command=("$@")

    if [[ "$XANADOS_PROGRESS_ENABLED" != "true" ]]; then
        "${command[@]}"
        return $?
    fi

    echo "${BLUE}[INFO]${NC} Starting: $description"

    # Run command in background and show spinner
    "${command[@]}" &
    local cmd_pid=$!

    show_spinner "$cmd_pid" "$description"

    # Wait for command to complete and get exit code
    wait "$cmd_pid"
    local exit_code=$?

    if [[ "$exit_code" -eq 0 ]]; then
        echo "${GREEN}[SUCCESS]${NC} $description completed successfully"
    else
        echo "${RED}[ERROR]${NC} $description failed (exit code: $exit_code)"
    fi

    return "$exit_code"
}

# ============================================================================
# Parallel Operations Functions
# ============================================================================

# Run multiple commands in parallel
run_parallel() {
    local jobs=("$@")
    local pids=()
    local failed=false

    # Start all jobs in parallel
    for job in "${jobs[@]}"; do
        (
            eval "$job"
        ) &
        pids+=($!)
    done

    # Wait for all jobs to complete
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=true
        fi
    done

    if [ "$failed" = "false" ]; then
        return 0
    else
        return 1
    fi
}

# Run multiple jobs with progress monitoring
run_parallel_jobs() {
    local jobs=("$@")
    local pids=()
    local job_count=${#jobs[@]}
    local completed=0
    local failed=false

    print_status "Starting $job_count parallel jobs..."

    # Start all jobs in parallel
    for i in "${!jobs[@]}"; do
        (
            eval "${jobs[$i]}"
            echo "JOB_COMPLETE_$i" >&3
        ) &
        pids+=($!)
    done 3> >(
        while read -r line; do
            if [[ $line == JOB_COMPLETE_* ]]; then
                completed=$((completed + 1))
                update_multi_progress "$completed" "$job_count" "Jobs completed"
            fi
        done
    )

    # Wait for all jobs to complete
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=true
        fi
    done

    if [ "$failed" = "false" ]; then
        print_success "All $job_count parallel jobs completed successfully"
        return 0
    else
        print_error "Some parallel jobs failed"
        return 1
    fi
}

# Run parallel execution with job limiting
run_parallel_limited() {
    local max_jobs="$1"
    shift
    local jobs=("$@")
    local running_pids=()
    local failed=false

    print_status "Running ${#jobs[@]} jobs with maximum $max_jobs concurrent processes..."

    for job in "${jobs[@]}"; do
        # Wait if we've reached the maximum number of concurrent jobs
        while [ ${#running_pids[@]} -ge "$max_jobs" ]; do
            local new_pids=()
            for pid in "${running_pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new_pids+=("$pid")
                else
                    wait "$pid" || failed=true
                fi
            done
            running_pids=("${new_pids[@]}")
            sleep 0.1
        done

        # Start the next job
        (
            eval "$job"
        ) &
        running_pids+=($!)
    done

    # Wait for remaining jobs to complete
    for pid in "${running_pids[@]}"; do
        wait "$pid" || failed=true
    done

    if [ "$failed" = "false" ]; then
        return 0
    else
        return 1
    fi
}

# Install packages in parallel groups
install_packages_parallel() {
    local packages=("$@")
    local simulate=false
    local batch_size=4

    # Check for simulation flag
    if [[ "${packages[-1]}" == "--simulate" ]]; then
        simulate=true
        unset 'packages[-1]'
    fi

    if [ ${#packages[@]} -eq 0 ]; then
        print_error "No packages specified for parallel installation"
        return 1
    fi

    print_status "Installing ${#packages[@]} packages in parallel (batch size: $batch_size)..."

    if $simulate; then
        print_status "SIMULATION MODE: Would install packages in parallel"
        for package in "${packages[@]}"; do
            echo "  - $package"
        done
        return 0
    fi

    # Split packages into batches for parallel installation
    local jobs=()
    for ((i = 0; i < ${#packages[@]}; i += batch_size)); do
        local batch=("${packages[@]:$i:$batch_size}")
        local batch_str
        batch_str=$(printf " %s" "${batch[@]}")

        if command -v pacman >/dev/null 2>&1; then
            jobs+=("sudo pacman -S --noconfirm$batch_str")
        elif command -v apt >/dev/null 2>&1; then
            jobs+=("sudo apt update && sudo apt install -y$batch_str")
        else
            print_error "No supported package manager found"
            return 1
        fi
    done

    # Run package installation jobs in parallel
    if run_parallel_limited 2 "${jobs[@]}"; then
        print_success "Parallel package installation completed successfully"
        return 0
    else
        print_error "Some package installations failed"
        return 1
    fi
}

# Run benchmarks in parallel
run_benchmark_parallel() {
    local benchmarks=("$@")
    local results_dir
    results_dir="${XANADOS_RESULTS_DIR:-/tmp}/parallel-benchmarks-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$results_dir"

    print_status "Running ${#benchmarks[@]} benchmarks in parallel..."
    init_multi_progress ${#benchmarks[@]}

    local benchmark_jobs=()
    for i in "${!benchmarks[@]}"; do
        benchmark_jobs+=("(${benchmarks[$i]}) > '$results_dir/benchmark-$i.log' 2>&1 && echo 'BENCHMARK_COMPLETE_$i' >&3")
    done

    # Execute benchmarks with progress monitoring
    (
        for i in "${!benchmark_jobs[@]}"; do
            (
                eval "${benchmark_jobs[$i]}"
            ) &
        done 3> >(
            local completed=0
            while read -r line; do
                if [[ $line == BENCHMARK_COMPLETE_* ]]; then
                    completed=$((completed + 1))
                    update_multi_progress "$completed" "${#benchmarks[@]}" "Benchmarks completed"
                fi
            done
        )

        wait
    )

    print_success "Parallel benchmarks completed. Results in: $results_dir"
    return 0
}

# Parallel file processing
process_files_parallel() {
    local operation="$1"
    shift
    local files=("$@")
    local max_jobs=4

    if [ ${#files[@]} -eq 0 ]; then
        print_error "No files specified for parallel processing"
        return 1
    fi

    print_status "Processing ${#files[@]} files in parallel..."

    local jobs=()
    for file in "${files[@]}"; do
        case "$operation" in
            compress)
                jobs+=("gzip -9 '$file'")
                ;;
            decompress)
                jobs+=("gunzip '$file'")
                ;;
            checksum)
                jobs+=("sha256sum '$file' > '$file.sha256'")
                ;;
            *)
                print_error "Unknown operation: $operation"
                return 1
                ;;
        esac
    done

    run_parallel_limited "$max_jobs" "${jobs[@]}"
}

# Download files in parallel
download_parallel() {
    local urls=("$@")
    local download_dir="${XANADOS_DOWNLOADS_DIR:-/tmp/downloads}"
    local max_concurrent=3

    mkdir -p "$download_dir"

    print_status "Downloading ${#urls[@]} files in parallel..."
    init_multi_progress ${#urls[@]}

    local download_jobs=()
    for i in "${!urls[@]}"; do
        local url="${urls[$i]}"
        local filename
        filename=$(basename "$url")
        download_jobs+=("curl -L '$url' -o '$download_dir/$filename' && echo 'DOWNLOAD_COMPLETE_$i' >&3")
    done

    (
        run_parallel_limited "$max_concurrent" "${download_jobs[@]}"
    ) 3> >(
        local completed=0
        while read -r line; do
            if [[ $line == DOWNLOAD_COMPLETE_* ]]; then
                completed=$((completed + 1))
                update_multi_progress "$completed" "${#urls[@]}" "Downloads completed"
            fi
        done
    )

    print_success "Parallel downloads completed to: $download_dir"
}

# ==============================================================================
# Modern Bash Best Practices - 2024/2025 Standards
# ==============================================================================

# Enhanced error handling with retry logic (2024 best practice)
retry_command() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    local timeout="${3:-30}"
    shift 3

    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt of $max_attempts: $*"

        if timeout "$timeout" "$@"; then
            log_debug "Command succeeded on attempt $attempt"
            return 0
        fi

        local exit_code=$?
        log_warn "Command failed with exit code $exit_code (attempt $attempt/$max_attempts)"

        if [[ $attempt -lt $max_attempts ]]; then
            log_info "Retrying in ${delay}s..."
            sleep "$delay"
            ((delay *= 2))  # Exponential backoff
        fi

        ((attempt++))
    done

    log_error "Command failed after $max_attempts attempts: $*"
    return $exit_code
}

# Lock file management (2024 best practice for script concurrency)
readonly LOCK_DIR="${XANADOS_LOCK_DIR:-/tmp/xanados-locks}"
mkdir -p "$LOCK_DIR" 2>/dev/null || true

acquire_lock() {
    local lock_name="$1"
    local timeout="${2:-300}"  # 5 minutes default
    local lock_file="$LOCK_DIR/$lock_name.lock"

    local attempts=0
    local max_attempts=$((timeout / 5))

    while [[ $attempts -lt $max_attempts ]]; do
        if (set -C; echo $$ > "$lock_file") 2>/dev/null; then
            log_debug "Acquired lock: $lock_name"
            # Set up automatic cleanup on exit
            trap 'release_lock "'"$lock_name"'"' EXIT
            return 0
        fi

        if [[ -f "$lock_file" ]]; then
            local lock_pid
            lock_pid="$(cat "$lock_file" 2>/dev/null || echo "")"
            if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
                log_warn "Removing stale lock file for PID $lock_pid"
                rm -f "$lock_file"
                continue
            fi
        fi

        log_debug "Waiting for lock: $lock_name (attempt $((attempts + 1))/$max_attempts)"
        sleep 5
        ((attempts++))
    done

    log_error "Failed to acquire lock: $lock_name (timeout after ${timeout}s)"
    return 1
}

release_lock() {
    local lock_name="$1"
    local lock_file="$LOCK_DIR/$lock_name.lock"

    if [[ -f "$lock_file" ]]; then
        rm -f "$lock_file"
        log_debug "Released lock: $lock_name"
    fi
}

# Input validation functions (2024 defensive programming)
validate_string() {
    local value="$1"
    local pattern="${2:-.*}"
    local description="${3:-value}"

    if [[ -z "$value" ]]; then
        log_error "Empty $description provided"
        return 1
    fi

    if [[ ! "$value" =~ $pattern ]]; then
        log_error "Invalid $description: '$value' (must match pattern: $pattern)"
        return 1
    fi

    return 0
}

validate_file() {
    local file="$1"
    local required="${2:-true}"

    if [[ "$required" == "true" && ! -f "$file" ]]; then
        log_error "Required file not found: $file"
        return 1
    fi

    if [[ -f "$file" && ! -r "$file" ]]; then
        log_error "File not readable: $file"
        return 1
    fi

    return 0
}

validate_directory() {
    local dir="$1"
    local required="${2:-true}"
    local writable="${3:-false}"

    if [[ "$required" == "true" && ! -d "$dir" ]]; then
        log_error "Required directory not found: $dir"
        return 1
    fi

    if [[ -d "$dir" ]]; then
        if [[ ! -r "$dir" ]]; then
            log_error "Directory not readable: $dir"
            return 1
        fi

        if [[ "$writable" == "true" && ! -w "$dir" ]]; then
            log_error "Directory not writable: $dir"
            return 1
        fi
    fi

    return 0
}

# Enhanced error trap with stack trace (2024 best practice)
show_error_with_stack() {
    local exit_code=$?
    local line_no="$1"
    local bash_lineno="$2"
    local last_command="$3"
    local function_stack=("${FUNCNAME[@]:1}")

    log_error "Command failed with exit code $exit_code"
    log_error "Line: $line_no, Last command: $last_command"

    if [[ ${#function_stack[@]} -gt 1 ]]; then
        log_error "Call stack:"
        local i=0
        while [[ $i -lt ${#function_stack[@]} ]]; do
            local func="${function_stack[$i]}"
            local file="${BASH_SOURCE[$((i + 2))]:-unknown}"
            local line="${BASH_LINENO[$((i + 1))]:-0}"
            log_error "  $((i + 1)): $func() at ${file##*/}:$line"
            ((i++))
        done
    fi
}

# Modern error handling setup
set_error_handling() {
    local enable_strict="${1:-true}"

    if [[ "$enable_strict" == "true" ]]; then
        # Enable strict mode if not already set
        set -euo pipefail
        IFS=$'\n\t'
    fi

    # Set up enhanced error trap
    trap 'show_error_with_stack ${LINENO} ${BASH_LINENO[0]} "$BASH_COMMAND"' ERR

    # Set up cleanup on exit
    trap 'log_debug "Script exiting with code $?"' EXIT
}

# Performance monitoring (2024 best practice)
declare -A PERF_TIMERS

start_timer() {
    local name="$1"
    PERF_TIMERS["$name"]=$(date +%s.%N)
    log_debug "Timer started: $name"
}

stop_timer() {
    local name="$1"
    local start_time="${PERF_TIMERS[$name]:-}"

    if [[ -z "$start_time" ]]; then
        log_warn "Timer '$name' was not started"
        return 1
    fi

    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(awk "BEGIN {print $end_time - $start_time}")

    log_info "Timer '$name': ${duration}s"
    unset "PERF_TIMERS[$name]"

    echo "$duration"
}

# Resource monitoring
check_system_resources() {
    local min_free_ram="${1:-100}"  # MB
    local min_free_disk="${2:-500}" # MB
    local check_path="${3:-/tmp}"

    # Check available RAM
    local free_ram
    free_ram=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [[ $free_ram -lt $min_free_ram ]]; then
        log_warn "Low memory: ${free_ram}MB available (minimum: ${min_free_ram}MB)"
        return 1
    fi

    # Check available disk space
    local free_disk
    free_disk=$(df -m "$check_path" | awk 'NR==2{print $4}')
    if [[ $free_disk -lt $min_free_disk ]]; then
        log_warn "Low disk space: ${free_disk}MB available at $check_path (minimum: ${min_free_disk}MB)"
        return 1
    fi

    log_debug "System resources OK: ${free_ram}MB RAM, ${free_disk}MB disk at $check_path"
    return 0
}

# Library initialization message
if [[ "${XANADOS_DEBUG:-false}" == "true" ]]; then
    log_debug "xanadOS Common Library v${XANADOS_LIB_VERSION} loaded"
    log_debug "Project root: $XANADOS_ROOT"
    log_debug "Enhanced with 2024/2025 best practices"
fi
