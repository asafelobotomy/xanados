#!/bin/bash
# xanadOS Archive Utility
# Archives files/directories to the archive directory with proper organization

set -euo pipefail

# Source common functions
source "$(dirname "$0")/../lib/common.sh"

# Archive utility functions
archive_file() {
    local source_path="$1"
    local archive_type="${2:-deprecated}"  # deprecated, backups, reports
    local description="${3:-}"

    if [[ ! -e "$source_path" ]]; then
        log_error "Source path does not exist: $source_path"
        return 1
    fi

    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local basename=$(basename "$source_path")
    local archive_subdir="archive/$archive_type"
    local archive_path="$archive_subdir/${timestamp}-${basename}"

    # Create archive subdirectory if it doesn't exist
    mkdir -p "$archive_subdir"

    # Move or copy the file/directory
    if [[ -d "$source_path" ]]; then
        log_info "Archiving directory: $source_path -> $archive_path"
        cp -r "$source_path" "$archive_path"
    else
        log_info "Archiving file: $source_path -> $archive_path"
        cp "$source_path" "$archive_path"
    fi

    # Create archive metadata
    cat > "${archive_path}.info" << EOF
Archive Information
==================
Original Path: $source_path
Archive Date: $(date)
Archive Type: $archive_type
Description: $description
Archived By: $(whoami)
EOF

    # Confirm archival
    if [[ -e "$archive_path" ]]; then
        log_success "Successfully archived to: $archive_path"

        # Ask if user wants to remove original
        if confirm_action "Remove original file/directory? (y/N)"; then
            rm -rf "$source_path"
            log_success "Original removed: $source_path"
        else
            log_info "Original preserved: $source_path"
        fi
    else
        log_error "Failed to archive: $source_path"
        return 1
    fi
}

# List archived items
list_archived() {
    local archive_type="${1:-}"

    if [[ -n "$archive_type" ]]; then
        local search_path="archive/$archive_type"
    else
        local search_path="archive"
    fi

    if [[ ! -d "$search_path" ]]; then
        log_info "No archived items found in: $search_path"
        return 0
    fi

    log_info "Archived items in $search_path:"
    echo "========================================"

    find "$search_path" -name "*.info" -type f | sort | while read -r info_file; do
        local archive_path="${info_file%.info}"
        local archive_name=$(basename "$archive_path")

        echo "📁 $archive_name"
        if [[ -f "$info_file" ]]; then
            grep "Archive Date\|Original Path\|Description" "$info_file" | sed 's/^/   /'
        fi
        echo ""
    done
}

# Restore archived item
restore_archived() {
    local archive_name="$1"
    local restore_path="${2:-}"

    # Find the archived item
    local archive_file=$(find archive -name "*${archive_name}*" -not -name "*.info" | head -1)
    local info_file="${archive_file}.info"

    if [[ -z "$archive_file" || ! -e "$archive_file" ]]; then
        log_error "Archived item not found: $archive_name"
        return 1
    fi

    # Get original path if no restore path specified
    if [[ -z "$restore_path" && -f "$info_file" ]]; then
        restore_path=$(grep "Original Path:" "$info_file" | cut -d' ' -f3-)
    fi

    if [[ -z "$restore_path" ]]; then
        log_error "No restore path specified and cannot determine original path"
        return 1
    fi

    # Confirm restoration
    if ! confirm_action "Restore $archive_file to $restore_path? (y/N)"; then
        log_info "Restoration cancelled"
        return 0
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$restore_path")"

    # Restore the item
    if [[ -d "$archive_file" ]]; then
        cp -r "$archive_file" "$restore_path"
    else
        cp "$archive_file" "$restore_path"
    fi

    if [[ -e "$restore_path" ]]; then
        log_success "Successfully restored to: $restore_path"
    else
        log_error "Failed to restore: $archive_file"
        return 1
    fi
}

# Main function
main() {
    local action="${1:-help}"

    case "$action" in
        "archive"|"a")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 archive <source_path> [archive_type] [description]"
                exit 1
            fi
            archive_file "$2" "${3:-deprecated}" "${4:-}"
            ;;
        "list"|"l")
            list_archived "${2:-}"
            ;;
        "restore"|"r")
            if [[ $# -lt 2 ]]; then
                log_error "Usage: $0 restore <archive_name> [restore_path]"
                exit 1
            fi
            restore_archived "$2" "${3:-}"
            ;;
        "help"|"h"|*)
            cat << EOF
xanadOS Archive Utility
======================

Usage: $0 <action> [options]

Actions:
  archive|a <source_path> [type] [description]  Archive a file or directory
  list|l [type]                                 List archived items
  restore|r <archive_name> [restore_path]       Restore an archived item
  help|h                                        Show this help

Archive Types:
  - deprecated (default)  For outdated code/configs
  - backups              For backup files
  - reports              For old reports/logs

Examples:
  $0 archive old-script.sh deprecated "Replaced by new implementation"
  $0 list backups
  $0 restore old-script.sh scripts/utilities/old-script.sh

Notes:
- Archives preserve metadata about original location and timestamp
- The archive directory is excluded from development tools but remains accessible
- Original files can be optionally removed after archiving
EOF
            ;;
    esac
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
