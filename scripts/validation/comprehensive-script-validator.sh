#!/bin/bash

# Comprehensive Script Validator for xanadOS
# Validates all scripts for errors, conflicts, and consolidation opportunities
# Author: xanadOS Development Team
# Version: 1.0.0

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"
source "${SCRIPT_DIR}/../lib/enhanced-testing.sh"

# Global counters
declare -g TOTAL_SCRIPTS=0
declare -g VALID_SCRIPTS=0
declare -g ERROR_SCRIPTS=0
declare -g CONFLICT_SCRIPTS=0
declare -g DEPRECATED_SCRIPTS=0
declare -g CONSOLIDATION_CANDIDATES=()

# Output files
VALIDATION_REPORT="/tmp/script-validation-$(date +%Y%m%d-%H%M%S).log"
ERROR_REPORT="/tmp/script-errors-$(date +%Y%m%d-%H%M%S).log"
CONFLICT_REPORT="/tmp/script-conflicts-$(date +%Y%m%d-%H%M%S).log"

print_header() {
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║               xanadOS Comprehensive Script Validator                 ║"
    echo "║                    Validating All Repository Scripts                 ║"
    echo "║                        $(date '+%Y-%m-%d %H:%M:%S')                        ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
}

# Check if script is executable and has proper shebang
validate_script_basics() {
    local script="$1"
    local errors=()

    # Check if file is executable
    if [[ ! -x "$script" ]]; then
        errors+=("Not executable")
    fi

    # Check shebang
    local first_line
    first_line=$(head -n1 "$script" 2>/dev/null || echo "")
    if [[ ! "$first_line" =~ ^#!/bin/bash|^#!/usr/bin/env\ bash ]]; then
        errors+=("Missing or invalid shebang")
    fi

    # Check for syntax errors
    if ! bash -n "$script" 2>/dev/null; then
        errors+=("Syntax errors detected")
    fi

    printf "%s" "${errors[*]}"
}

# Check for common script conflicts
check_script_conflicts() {
    local script="$1"
    local conflicts=()

    # Check for duplicate function definitions
    local script_basename
    script_basename=$(basename "$script")

    # Look for scripts with similar names that might conflict
    while IFS= read -r similar_script; do
        if [[ "$similar_script" != "$script" ]] && [[ "$(basename "$similar_script")" == "$script_basename" ]]; then
            conflicts+=("Duplicate name: $similar_script")
        fi
    done < <(find . -name "*.sh" -type f 2>/dev/null | grep -v "./build/work")

    # Check for conflicting port usage
    if grep -q ":[0-9]\{4,5\}" "$script" 2>/dev/null; then
        local ports
        ports=$(grep -o ":[0-9]\{4,5\}" "$script" 2>/dev/null | tr -d ':' | sort -u)
        for port in $ports; do
            local other_scripts
            local script_files
            script_files=$(find . -name "*.sh" -type f 2>/dev/null | grep -v "./build/work")
            other_scripts=$(grep -l ":$port" $script_files 2>/dev/null | grep -v "$script" || true)
            if [[ -n "$other_scripts" ]]; then
                conflicts+=("Port $port conflict with: $other_scripts")
            fi
        done
    fi

    printf "%s" "${conflicts[*]}"
}

# Check if script is deprecated or outdated
check_script_deprecation() {
    local script="$1"
    local deprecated_indicators=()

    # Check for deprecation markers
    if grep -qi "deprecated\|obsolete\|legacy\|old\|todo.*remove" "$script" 2>/dev/null; then
        deprecated_indicators+=("Contains deprecation markers")
    fi

    # Check last modification date (older than 1 year might be outdated)
    local mod_time
    mod_time=$(stat -c %Y "$script" 2>/dev/null || echo "0")
    local current_time
    current_time=$(date +%s)
    local age_days=$(( (current_time - mod_time) / 86400 ))

    if [[ $age_days -gt 365 ]]; then
        deprecated_indicators+=("Last modified over 1 year ago")
    fi

    # Check for old patterns (like source without proper path validation)
    if grep -q "source.*\.\." "$script" 2>/dev/null && ! grep -q "cd.*dirname" "$script" 2>/dev/null; then
        deprecated_indicators+=("Uses old sourcing patterns")
    fi

    printf "%s" "${deprecated_indicators[*]}"
}

# Find consolidation opportunities
find_consolidation_candidates() {
    local script="$1"
    local candidates=()

    # Check for similar function patterns
    if grep -q "validate_\|check_\|test_" "$script" 2>/dev/null; then
        candidates+=("validation")
    fi

    if grep -q "install_\|setup_\|configure_" "$script" 2>/dev/null; then
        candidates+=("setup")
    fi

    if grep -q "benchmark_\|performance_\|speed_" "$script" 2>/dev/null; then
        candidates+=("performance")
    fi

    if grep -q "gaming_\|game_\|steam_\|wine_" "$script" 2>/dev/null; then
        candidates+=("gaming")
    fi

    printf "%s" "${candidates[*]}"
}

# Validate a single script
validate_single_script() {
    local script="$1"
    local relative_path="${script#./}"

    echo "Validating: $relative_path" | tee -a "$VALIDATION_REPORT"

    # Basic validation
    local basic_errors
    basic_errors=$(validate_script_basics "$script")

    # Conflict check
    local conflicts
    conflicts=$(check_script_conflicts "$script")

    # Deprecation check
    local deprecation
    deprecation=$(check_script_deprecation "$script")

    # Consolidation opportunities
    local consolidation
    consolidation=$(find_consolidation_candidates "$script")

    # Report results
    if [[ -n "$basic_errors" ]]; then
        echo "  ❌ ERRORS: $basic_errors" | tee -a "$VALIDATION_REPORT" "$ERROR_REPORT"
        ((ERROR_SCRIPTS++))
    else
        echo "  ✓ Basic validation passed" | tee -a "$VALIDATION_REPORT"
        ((VALID_SCRIPTS++))
    fi

    if [[ -n "$conflicts" ]]; then
        echo "  ⚠️  CONFLICTS: $conflicts" | tee -a "$VALIDATION_REPORT" "$CONFLICT_REPORT"
        ((CONFLICT_SCRIPTS++))
    fi

    if [[ -n "$deprecation" ]]; then
        echo "  🕒 DEPRECATED: $deprecation" | tee -a "$VALIDATION_REPORT"
        ((DEPRECATED_SCRIPTS++))
    fi

    if [[ -n "$consolidation" ]]; then
        echo "  🔄 CONSOLIDATION: Could be consolidated with $consolidation scripts" | tee -a "$VALIDATION_REPORT"
        CONSOLIDATION_CANDIDATES+=("$relative_path:$consolidation")
    fi

    echo | tee -a "$VALIDATION_REPORT"
}

# Main validation function
main() {
    print_header

    echo "🔍 Scanning for shell scripts..."

    # Find all shell scripts, excluding build artifacts
    local scripts=()
    while IFS= read -r script; do
        scripts+=("$script")
    done < <(find . -name "*.sh" -type f 2>/dev/null | grep -v "./build/work" | sort)

    TOTAL_SCRIPTS=${#scripts[@]}
    echo "📋 Found $TOTAL_SCRIPTS shell scripts to validate"
    echo

    # Initialize reports
    {
        echo "xanadOS Script Validation Report"
        echo "Generated: $(date)"
        echo "Total Scripts: $TOTAL_SCRIPTS"
        echo "================================"
        echo
    } > "$VALIDATION_REPORT"

    echo "Script Errors Report" > "$ERROR_REPORT"
    echo "Script Conflicts Report" > "$CONFLICT_REPORT"

    # Validate each script
    for script in "${scripts[@]}"; do
        validate_single_script "$script"
    done

    # Generate summary
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                          Validation Summary                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    echo "📊 STATISTICS:"
    echo "  Total Scripts:      $TOTAL_SCRIPTS"
    echo "  Valid Scripts:      $VALID_SCRIPTS"
    echo "  Scripts with Errors: $ERROR_SCRIPTS"
    echo "  Scripts with Conflicts: $CONFLICT_SCRIPTS"
    echo "  Deprecated Scripts: $DEPRECATED_SCRIPTS"
    echo "  Consolidation Candidates: ${#CONSOLIDATION_CANDIDATES[@]}"
    echo

    if [[ ${#CONSOLIDATION_CANDIDATES[@]} -gt 0 ]]; then
        echo "🔄 CONSOLIDATION OPPORTUNITIES:"
        for candidate in "${CONSOLIDATION_CANDIDATES[@]}"; do
            echo "  • ${candidate%:*} → ${candidate#*:}"
        done
        echo
    fi

    echo "📄 REPORTS GENERATED:"
    echo "  Full Report:     $VALIDATION_REPORT"
    echo "  Error Report:    $ERROR_REPORT"
    echo "  Conflict Report: $CONFLICT_REPORT"
    echo

    # Exit with appropriate code
    if [[ $ERROR_SCRIPTS -gt 0 ]]; then
        echo "❌ Validation completed with errors"
        exit 1
    elif [[ $CONFLICT_SCRIPTS -gt 0 ]]; then
        echo "⚠️  Validation completed with conflicts"
        exit 2
    else
        echo "✅ All scripts validated successfully"
        exit 0
    fi
}

# Run main function
main "$@"
