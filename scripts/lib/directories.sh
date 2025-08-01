#!/bin/bash
# xanadOS Directory Management Library
# Safe directory operations and path management
# Version: 1.0.0

# Prevent multiple sourcing
[[ "${XANADOS_DIRECTORIES_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_DIRECTORIES_LOADED="true"

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Standard xanadOS directory structure
readonly XANADOS_DIRECTORIES=(
    "archive"
    "archive/backups"
    "archive/reports"
    "build"
    "configs"
    "docs"
    "docs/user"
    "docs/development"
    "packages"
    "scripts"
    "scripts/setup"
    "scripts/testing"
    "scripts/build"
    "scripts/dev-tools"
    "scripts/lib"
    "testing"
    "workflows"
)

# User data directories - DEPRECATED: Kept for backward compatibility only
# New projects should use docs/reports/ structure instead
readonly USER_DATA_DIRS=(
    "$HOME/.local/share/xanados"
    "$HOME/.local/share/xanados/benchmarks"
    "$HOME/.local/share/xanados/gaming-validation"
    "$HOME/.local/share/xanados/automated-benchmarks"
    "$HOME/.local/share/xanados/logs"
    "$HOME/.local/share/xanados/configs"
    "$HOME/.local/share/xanados/temp"
    "$HOME/.config/xanados"
)

# Get the project root directory
get_project_root() {
    # Try to find the project root by looking for characteristic files
    local current_dir
    local script_dir
    
    current_dir="$(pwd)"
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Start from script directory and work up
    local search_dir="$script_dir"
    while [[ "$search_dir" != "/" ]]; do
        # Look for project indicators
        if [[ -d "$search_dir/scripts" && -d "$search_dir/docs" ]]; then
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    # Fallback to current directory if in xanadOS structure
    if [[ "$current_dir" == *"xanadOS"* ]]; then
        # Extract the xanadOS root path
        echo "${current_dir%%/xanadOS/*}/xanadOS"
        return 0
    fi
    
    # Last fallback
    echo "$current_dir"
}

# Get standard results directory with optional timestamping
get_results_dir() {
    local script_type="${1:-general}"
    local use_timestamp="${2:-false}"
    
    # Use docs/reports structure within the project
    local project_root
    project_root="$(get_project_root)"
    local base_dir="$project_root/docs/reports"
    local type_dir
    
    case "$script_type" in
        "benchmarks"|"performance")
            type_dir="$base_dir/generated"
            ;;
        "gaming"|"validation")
            type_dir="$base_dir/generated"
            ;;
        "automated"|"monitoring")
            type_dir="$base_dir/generated"
            ;;
        "testing"|"suite")
            type_dir="$base_dir/generated"
            ;;
        "logs")
            type_dir="$base_dir/generated"
            ;;
        *)
            type_dir="$base_dir/generated"
            ;;
    esac
    
    if [[ "$use_timestamp" == "true" ]]; then
        echo "$type_dir/$(date +%Y-%m-%d_%H-%M-%S)"
    else
        echo "$type_dir"
    fi
}

# Get timestamped benchmark directory
get_benchmark_dir() {
    local use_timestamp="${1:-true}"
    
    get_results_dir "benchmarks" "$use_timestamp"
}

# Get timestamped log directory  
get_log_dir() {
    local use_timestamp="${1:-true}"
    local project_root
    project_root="$(get_project_root)"
    local base_dir="$project_root/docs/reports/generated"
    
    if [[ "$use_timestamp" == "true" ]]; then
        echo "$base_dir/$(date +%Y-%m-%d)"
    else
        echo "$base_dir"
    fi
}

# Ensure complete results directory structure exists
ensure_results_structure() {
    local script_type="${1:-general}"
    local use_timestamp="${2:-true}"
    
    print_debug "Creating results directory structure for: $script_type"
    
    # Get the appropriate results directory
    local results_dir
    results_dir="$(get_results_dir "$script_type" "$use_timestamp")"
    
    # Create the main results directory
    if ! safe_mkdir "$results_dir"; then
        print_error "Failed to create results directory: $results_dir"
        return 1
    fi
    
    # Create standard subdirectories
    local subdirs=(
        "data"
        "reports" 
        "logs"
        "temp"
        "archive"
    )
    
    for subdir in "${subdirs[@]}"; do
        if ! safe_mkdir "$results_dir/$subdir"; then
            print_warning "Failed to create subdirectory: $results_dir/$subdir"
        fi
    done
    
    # Create logs directory with timestamp
    local log_dir
    log_dir="$(get_log_dir "$use_timestamp")"
    if ! safe_mkdir "$log_dir"; then
        print_warning "Failed to create log directory: $log_dir"
    fi
    
    # Only return the directory path (no print statements for clean output)
    echo "$results_dir"
}

# Get standardized filename with timestamp (returns full path to data directory)
get_results_filename() {
    local base_name="$1"
    local extension="${2:-json}"
    local script_type="${3:-general}"
    
    if [[ -z "$base_name" ]]; then
        print_error "get_results_filename: base_name is required"
        return 1
    fi
    
    local project_root
    project_root="$(get_project_root)"
    local data_dir="$project_root/docs/reports/data"
    
    # Ensure data directory exists
    safe_mkdir "$data_dir"
    
    local filename
    filename="${script_type}-${base_name}-$(date +%Y%m%d-%H%M%S).${extension}"
    echo "$data_dir/$filename"
}

# Get standardized log filename (returns full path to log directory)
get_log_filename() {
    local script_name="$1"
    local extension="${2:-log}"
    
    if [[ -z "$script_name" ]]; then
        print_error "get_log_filename: script_name is required" 
        return 1
    fi
    
    local log_dir
    log_dir="$(get_log_dir false)"
    safe_mkdir "$log_dir"
    
    local filename
    filename="${script_name}-$(date +%Y%m%d-%H%M%S).${extension}"
    echo "$log_dir/$filename"
}

# Get standard config directory
get_config_dir() {
    echo "$HOME/.config/xanados"
}

# Get standard temp directory
get_xanados_temp_dir() {
    local project_root
    project_root="$(get_project_root)"
    local temp_base="$project_root/docs/reports/temp"
    safe_mkdir "$temp_base"
    mktemp -d "$temp_base/tmp.XXXXXXXX"
}

# Create all standard user directories
create_user_directories() {
    local failed=()
    
    print_status "Creating xanadOS user directories..."
    
    for dir in "${USER_DATA_DIRS[@]}"; do
        if safe_mkdir "$dir"; then
            print_debug "Created: $dir"
        else
            failed+=("$dir")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_error "Failed to create directories:"
        printf '  - %s\n' "${failed[@]}"
        return 1
    fi
    
    print_success "All user directories created successfully"
    return 0
}

# Create project directory structure
create_project_directories() {
    local project_root="${1:-$XANADOS_ROOT}"
    local failed=()
    
    print_status "Creating xanadOS project directories..."
    
    for dir in "${XANADOS_DIRECTORIES[@]}"; do
        local full_path="$project_root/$dir"
        if safe_mkdir "$full_path"; then
            print_debug "Created: $full_path"
        else
            failed+=("$full_path")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        print_error "Failed to create project directories:"
        printf '  - %s\n' "${failed[@]}"
        return 1
    fi
    
    print_success "All project directories created successfully"
    return 0
}

# Ensure a specific directory exists with proper permissions
ensure_directory() {
    local dir="$1"
    local mode="${2:-755}"
    local owner="${3:-}"
    
    if [[ -z "$dir" ]]; then
        print_error "ensure_directory: No directory specified"
        return 1
    fi
    
    # Create directory if it doesn't exist
    if ! safe_mkdir "$dir" "$mode"; then
        return 1
    fi
    
    # Set ownership if specified
    if [[ -n "$owner" ]] && [[ "$EUID" -eq 0 ]]; then
        if ! chown "$owner" "$dir" 2>/dev/null; then
            print_warning "Failed to set ownership of $dir to $owner"
        fi
    fi
    
    return 0
}

# Clean up old files in a directory
cleanup_old_files() {
    local dir="$1"
    local days_old="${2:-7}"
    local pattern="${3:-*}"
    local dry_run="${4:-false}"
    
    if [[ ! -d "$dir" ]]; then
        print_error "Directory does not exist: $dir"
        return 1
    fi
    
    print_status "Cleaning up files older than $days_old days in: $dir"
    
    local find_cmd="find '$dir' -name '$pattern' -type f -mtime +$days_old"
    
    if [[ "$dry_run" == "true" ]]; then
        print_status "Dry run - files that would be deleted:"
        eval "$find_cmd" | while read -r file; do
            echo "  - $file"
        done
    else
        local deleted_count=0
        eval "$find_cmd" | while read -r file; do
            if rm -f "$file" 2>/dev/null; then
                print_debug "Deleted: $file"
                ((deleted_count++))
            else
                print_warning "Failed to delete: $file"
            fi
        done
        print_success "Cleanup completed: $deleted_count files deleted"
    fi
}

# Archive old results
archive_old_results() {
    local results_dir="$1"
    local archive_dir="${2:-$XANADOS_ROOT/archive/results}"
    local days_old="${3:-30}"
    
    if [[ ! -d "$results_dir" ]]; then
        print_warning "Results directory does not exist: $results_dir"
        return 0
    fi
    
    local archive_subdir
    archive_subdir="$archive_dir/$(date +%Y%m%d)"
    ensure_directory "$archive_subdir"
    
    print_status "Archiving results older than $days_old days..."
    
    find "$results_dir" -type f -mtime "+$days_old" | while read -r file; do
        local rel_path="${file#$results_dir/}"
        local target_dir
        target_dir="$archive_subdir/$(dirname "$rel_path")"
        
        ensure_directory "$target_dir"
        
        if mv "$file" "$target_dir/" 2>/dev/null; then
            print_debug "Archived: $file"
        else
            print_warning "Failed to archive: $file"
        fi
    done
    
    print_success "Archival completed"
}

# Get directory size in MB
get_directory_size() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        echo "0"
        return 1
    fi
    
    du -sm "$dir" 2>/dev/null | awk '{print $1}'
}

# Check if directory is safe to operate on
is_safe_directory() {
    local dir="$1"
    
    # Resolve to absolute path
    local abs_dir
    abs_dir="$(realpath "$dir" 2>/dev/null)" || abs_dir="$dir"
    
    # List of protected directories
    local protected=(
        "/"
        "/bin"
        "/boot"
        "/dev"
        "/etc"
        "/lib"
        "/lib64"
        "/proc"
        "/root"
        "/run"
        "/sbin"
        "/sys"
        "/usr"
        "/var"
        "/home"
    )
    
    for protected_dir in "${protected[@]}"; do
        if [[ "$abs_dir" == "$protected_dir" ]]; then
            print_error "Cannot operate on protected directory: $abs_dir"
            return 1
        fi
    done
    
    return 0
}

# Create timestamped backup directory
create_backup_dir() {
    local base_name="$1"
    local base_dir="${2:-$XANADOS_ROOT/archive/backups}"
    
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup_dir="$base_dir/${base_name}-${timestamp}"
    
    ensure_directory "$backup_dir"
    echo "$backup_dir"
}

# Create directory with gitkeep file
create_dir_with_gitkeep() {
    local dir="$1"
    
    if ensure_directory "$dir"; then
        touch "$dir/.gitkeep"
        print_debug "Created directory with .gitkeep: $dir"
        return 0
    fi
    
    return 1
}

# Sync directory contents
sync_directories() {
    local source="$1"
    local target="$2"
    local delete_extra="${3:-false}"
    
    if [[ ! -d "$source" ]]; then
        print_error "Source directory does not exist: $source"
        return 1
    fi
    
    ensure_directory "$target"
    
    local rsync_opts="-av"
    if [[ "$delete_extra" == "true" ]]; then
        rsync_opts+=" --delete"
    fi
    
    if command_exists "rsync"; then
        rsync $rsync_opts "$source/" "$target/"
    else
        # Fallback to cp if rsync is not available
        cp -r "$source"/* "$target/" 2>/dev/null || true
    fi
}

# List directory contents with details
list_directory_contents() {
    local dir="$1"
    local show_hidden="${2:-false}"
    
    if [[ ! -d "$dir" ]]; then
        print_error "Directory does not exist: $dir"
        return 1
    fi
    
    echo "Contents of: $dir"
    echo "Size: $(get_directory_size "$dir")MB"
    echo ""
    
    local ls_opts="-la"
    if [[ "$show_hidden" == "false" ]]; then
        ls_opts="-l"
    fi
    
    ls $ls_opts "$dir" 2>/dev/null || print_error "Failed to list directory contents"
}

# Check if directory is empty
is_directory_empty() {
    local dir="$1"
    
    [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]
}

# Remove empty directories recursively
remove_empty_directories() {
    local base_dir="$1"
    local dry_run="${2:-false}"
    
    if [[ ! -d "$base_dir" ]]; then
        print_error "Base directory does not exist: $base_dir"
        return 1
    fi
    
    if ! is_safe_directory "$base_dir"; then
        return 1
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        print_status "Dry run - empty directories that would be removed:"
        find "$base_dir" -type d -empty | while read -r dir; do
            echo "  - $dir"
        done
    else
        local removed_count=0
        find "$base_dir" -type d -empty -delete 2>/dev/null || {
            # Fallback for systems where find -delete doesn't work
            find "$base_dir" -type d -empty | while read -r dir; do
                if rmdir "$dir" 2>/dev/null; then
                    print_debug "Removed empty directory: $dir"
                    ((removed_count++))
                fi
            done
        }
        print_success "Removed $removed_count empty directories"
    fi
}

# Export functions for other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "xanadOS Directory Management Library v1.0.0"
    echo "This library should be sourced, not executed directly."
    echo ""
    echo "Available functions:"
    echo "  - get_results_dir, get_benchmark_dir, get_log_dir, get_config_dir"
    echo "  - ensure_results_structure, get_results_filename, get_log_filename"
    echo "  - create_user_directories, create_project_directories"
    echo "  - ensure_directory, cleanup_old_files, archive_old_results"
    echo "  - get_directory_size, is_safe_directory, sync_directories"
    exit 1
fi
