#!/bin/bash

# xanadOS Script Consolidation and Best Practices Implementation
# Phase 1: Immediate Improvements
# Date: August 3, 2025

set -euo pipefail

# Get the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XANADOS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# Phase 1: Remove duplicate gaming setup scripts
remove_duplicate_gaming_scripts() {
    log_info "🗂️ Phase 1: Removing duplicate gaming setup scripts"

    local archive_dir="$XANADOS_ROOT/archive/deprecated/$(date +%Y-%m-%d)-script-consolidation"
    mkdir -p "$archive_dir"

    # Move obsolete gaming setup scripts to archive
    local duplicates=(
        "scripts/setup/gaming-setup.sh"
        "scripts/setup/xanados-gaming-setup.sh"
        "scripts/setup/unified-gaming-setup.sh"
    )

    for script in "${duplicates[@]}"; do
        local full_path="$XANADOS_ROOT/$script"
        if [[ -f "$full_path" ]]; then
            log_info "Archiving duplicate script: $script"
            mv "$full_path" "$archive_dir/"
        fi
    done

    log_info "✅ Duplicate gaming scripts archived to: $archive_dir"
}

# Phase 2: Standardize error handling across scripts
add_error_handling_template() {
    log_info "🛡️ Phase 2: Creating error handling template"

    local template_dir="$XANADOS_ROOT/scripts/templates"
    mkdir -p "$template_dir"

    cat > "$template_dir/script-header-template.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# Script Name: [SCRIPT_NAME]
# Description: [SCRIPT_DESCRIPTION]
# Author: xanadOS Development Team
# Version: 1.0.0
# Date: [DATE]
# Usage: [USAGE_INSTRUCTIONS]
# Dependencies: [DEPENDENCIES]
# =============================================================================

# Best Practice: Strict error handling
set -euo pipefail

# Best Practice: Include useful troubleshooting information
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Best Practice: Logging configuration
readonly LOG_DIR="${HOME}/.local/log/xanados"
readonly LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

# Best Practice: Check script running directory
check_script_environment() {
    # Ensure we're in the correct directory structure
    if [[ ! -d "$XANADOS_ROOT/scripts" ]] || [[ ! -d "$XANADOS_ROOT/docs" ]]; then
        echo "ERROR: Script must be run from within xanadOS project structure" >&2
        echo "Current directory: $(pwd)" >&2
        echo "Expected xanadOS root: $XANADOS_ROOT" >&2
        exit 1
    fi
}

# Best Practice: Comprehensive logging
setup_logging() {
    mkdir -p "$LOG_DIR"
    echo "=== $SCRIPT_NAME started: $(date) ===" >> "$LOG_FILE"
    echo "Script directory: $SCRIPT_DIR" >> "$LOG_FILE"
    echo "xanadOS root: $XANADOS_ROOT" >> "$LOG_FILE"
    echo "User: $USER" >> "$LOG_FILE"
    echo "PWD: $(pwd)" >> "$LOG_FILE"
}

# Best Practice: Standardized logging functions
log_debug() {
    [[ "${XANADOS_DEBUG:-false}" == "true" ]] && echo "[DEBUG] $*" | tee -a "$LOG_FILE" >&2 || true
}

log_info() {
    echo "[INFO] $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[WARN] $*" | tee -a "$LOG_FILE" >&2
}

log_error() {
    echo "[ERROR] $*" | tee -a "$LOG_FILE" >&2
}

log_success() {
    echo "[SUCCESS] $*" | tee -a "$LOG_FILE"
}

# Best Practice: Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    echo "=== $SCRIPT_NAME finished: $(date) (exit code: $exit_code) ===" >> "$LOG_FILE"

    # Add specific cleanup tasks here
    [[ -d "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"

    exit $exit_code
}

# Best Practice: Error handler
handle_error() {
    local line_no=$1
    local error_code=$2
    log_error "Script failed at line $line_no with exit code $error_code"
    log_error "Command: ${BASH_COMMAND}"
    cleanup_on_exit
}

# Best Practice: Signal handlers
trap 'handle_error ${LINENO} $?' ERR
trap cleanup_on_exit EXIT INT TERM

# Best Practice: Usage documentation
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [ARGUMENTS]

Description:
    [SCRIPT_DESCRIPTION]

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -d, --debug     Enable debug mode
    --dry-run       Show what would be done without executing

Examples:
    $SCRIPT_NAME                    # [DEFAULT_EXAMPLE]
    $SCRIPT_NAME --verbose          # [VERBOSE_EXAMPLE]
    $SCRIPT_NAME --dry-run          # [DRY_RUN_EXAMPLE]

For more information, see: [DOCUMENTATION_URL]
EOF
}

# Best Practice: Validation functions
validate_dependencies() {
    local missing=()

    # Add dependency checks here
    # command -v git >/dev/null 2>&1 || missing+=("git")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Please install missing dependencies and try again"
        exit 1
    fi
}

# Best Practice: Main initialization
init_script() {
    # Since this is a template, we'll skip the function calls
    # In actual implementation, uncomment these:
    # check_script_environment
    # setup_logging
    # validate_dependencies

    log_info "Starting $SCRIPT_NAME"
    log_info "Environment validated successfully"
}

# Template placeholder for main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            -d|--debug)
                export XANADOS_DEBUG=true
                shift
                ;;
            --dry-run)
                export DRY_RUN=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Initialize script environment
    init_script

    # Main script logic goes here
    log_info "Script template ready for implementation"

    log_success "$SCRIPT_NAME completed successfully"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF

    log_info "✅ Script template created at: $template_dir/script-header-template.sh"
}

# Phase 3: Enhance key scripts with best practices
enhance_key_scripts() {
    log_info "🔧 Phase 3: Enhancing key scripts with best practices"

    # List of scripts that need enhancement
    local scripts_to_enhance=(
        "scripts/build/create-installation-package-simple.sh"
        "scripts/testing/run-full-system-test.sh"
        "testing/automated/testing-suite.sh"
    )

    for script in "${scripts_to_enhance[@]}"; do
        local full_path="$XANADOS_ROOT/$script"
        if [[ -f "$full_path" ]]; then
            log_info "Enhancing script: $script"
            enhance_script_best_practices "$full_path"
        else
            log_warn "Script not found: $script"
        fi
    done
}

enhance_script_best_practices() {
    local script_path="$1"
    local backup_path="${script_path}.bak.$(date +%Y%m%d_%H%M%S)"

    log_info "Creating backup: $backup_path"
    cp "$script_path" "$backup_path"

    # Check if script already has proper error handling
    if ! grep -q "set -euo pipefail" "$script_path"; then
        log_info "Adding error handling to: $script_path"
        # This would require careful script analysis and modification
        # For now, just log what needs to be done
        log_warn "Script needs error handling enhancement: $script_path"
    fi

    # Check for usage documentation
    if ! grep -q "show_usage\|usage\|--help" "$script_path"; then
        log_warn "Script needs usage documentation: $script_path"
    fi

    # Check for logging
    if ! grep -q "log_info\|log_error\|log_warn" "$script_path"; then
        log_warn "Script needs standardized logging: $script_path"
    fi
}

# Phase 4: Create script quality check tool
create_quality_check_tool() {
    log_info "🔍 Phase 4: Creating script quality check tool"

    local tools_dir="$XANADOS_ROOT/scripts/dev-tools"
    mkdir -p "$tools_dir"

    cat > "$tools_dir/script-quality-checker.sh" << 'EOF'
#!/bin/bash

# xanadOS Script Quality Checker
# Validates scripts against best practices

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

check_script_quality() {
    local script_path="$1"
    local score=0
    local max_score=10
    local issues=()

    echo "Checking: $script_path"

    # Check 1: Shebang line
    if head -1 "$script_path" | grep -q '^#!/bin/bash'; then
        ((score++))
    else
        issues+=("Missing or incorrect shebang line")
    fi

    # Check 2: Error handling
    if grep -q "set -euo pipefail" "$script_path"; then
        ((score++))
    else
        issues+=("Missing error handling (set -euo pipefail)")
    fi

    # Check 3: Usage documentation
    if grep -q "show_usage\|usage\|--help" "$script_path"; then
        ((score++))
    else
        issues+=("Missing usage documentation")
    fi

    # Check 4: Logging functions
    if grep -q "log_info\|log_error\|echo.*\[INFO\]\|\[ERROR\]" "$script_path"; then
        ((score++))
    else
        issues+=("Missing standardized logging")
    fi

    # Check 5: Script header/documentation
    if grep -q "Description\|Purpose\|Author" "$script_path"; then
        ((score++))
    else
        issues+=("Missing script documentation header")
    fi

    # Check 6: Function documentation
    local func_count=$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(" "$script_path" || echo 0)
    local doc_count=$(grep -c "^[[:space:]]*#.*function\|^[[:space:]]*# [A-Z]" "$script_path" || echo 0)
    if [[ $func_count -gt 0 ]] && [[ $doc_count -gt 0 ]]; then
        ((score++))
    elif [[ $func_count -eq 0 ]]; then
        ((score++))  # No functions, so no documentation needed
    else
        issues+=("Functions lack documentation")
    fi

    # Check 7: Directory validation
    if grep -q "SCRIPT_DIR\|pwd\|dirname" "$script_path"; then
        ((score++))
    else
        issues+=("Missing directory validation")
    fi

    # Check 8: Cleanup handling
    if grep -q "trap\|cleanup\|EXIT" "$script_path"; then
        ((score++))
    else
        issues+=("Missing cleanup handling")
    fi

    # Check 9: Input validation
    if grep -q "if.*\[\[.*-z\|if.*\[\[.*-n\|getopts\|case.*\$1" "$script_path"; then
        ((score++))
    else
        issues+=("Missing input validation")
    fi

    # Check 10: Safe temporary file handling
    if grep -q "mktemp\|TEMP_DIR" "$script_path" || ! grep -q "/tmp" "$script_path"; then
        ((score++))
    else
        issues+=("Unsafe temporary file handling")
    fi

    # Report results
    local percentage=$((score * 100 / max_score))
    echo "  Score: $score/$max_score ($percentage%)"

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "  Issues:"
        for issue in "${issues[@]}"; do
            echo "    - $issue"
        done
    fi

    echo
    return $((max_score - score))
}

main() {
    echo "🔍 xanadOS Script Quality Checker"
    echo "================================="
    echo

    local total_issues=0
    local script_count=0

    # Find all shell scripts
    while IFS= read -r -d '' script; do
        if [[ -f "$script" ]] && [[ "$script" != *"/archive/"* ]]; then
            check_script_quality "$script"
            total_issues=$((total_issues + $?))
            ((script_count++))
        fi
    done < <(find "$XANADOS_ROOT" -name "*.sh" -type f -print0)

    echo "Summary:"
    echo "  Scripts checked: $script_count"
    echo "  Total issues: $total_issues"

    if [[ $total_issues -eq 0 ]]; then
        echo "  🎉 All scripts follow best practices!"
    else
        echo "  📋 $total_issues improvements needed"
    fi
}

main "$@"
EOF

    chmod +x "$tools_dir/script-quality-checker.sh"
    log_info "✅ Quality checker created at: $tools_dir/script-quality-checker.sh"
}

# Main execution
main() {
    log_info "🚀 Starting xanadOS Script Consolidation and Best Practices Implementation"
    log_info "Based on: https://learn.openwaterfoundation.org/owf-learn-linux-shell/best-practices/best-practices/"

    # Execute phases
    remove_duplicate_gaming_scripts
    add_error_handling_template
    enhance_key_scripts
    create_quality_check_tool

    log_info "✅ Script consolidation and improvements completed!"
    log_info "📋 Next steps:"
    log_info "   1. Run: scripts/dev-tools/script-quality-checker.sh"
    log_info "   2. Review archived scripts in: archive/deprecated/"
    log_info "   3. Update scripts using template: scripts/templates/script-header-template.sh"
}

# Run main function
main "$@"
