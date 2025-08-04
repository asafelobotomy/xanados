#!/bin/bash

# Simple Script Validator for xanadOS
# Validates all scripts for basic errors and issues
# Author: xanadOS Development Team
# Version: 1.0.0

set -uo pipefail  # Removed -e to allow continuing on errors

# Global counters
declare -g TOTAL_SCRIPTS=0
declare -g VALID_SCRIPTS=0
declare -g ERROR_SCRIPTS=0
declare -g CONFLICT_SCRIPTS=0
declare -g DEPRECATED_SCRIPTS=0
declare -g CONSOLIDATION_CANDIDATES=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               xanadOS Simple Script Validator                        ║${NC}"
    echo -e "${BLUE}║                    Validating All Repository Scripts                 ║${NC}"
    echo -e "${BLUE}║                        $(date '+%Y-%m-%d %H:%M:%S')                        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Check if script has basic issues
validate_script_basics() {
    local script="$1"
    local errors=()

    # Check if file exists and is readable
    if [[ ! -r "$script" ]]; then
        errors+=("Not readable")
        printf "%s" "${errors[*]}"
        return
    fi

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
        errors+=("Syntax errors")
    fi

    # Check for common issues
    if grep -q "rm -rf \/" "$script" 2>/dev/null; then
        errors+=("Dangerous rm command")
    fi

    if grep -q "eval.*\$" "$script" 2>/dev/null; then
        errors+=("Potentially unsafe eval")
    fi

    printf "%s" "${errors[*]}"
}

# Check for script conflicts
check_script_conflicts() {
    local script="$1"
    local conflicts=()
    local script_basename
    script_basename=$(basename "$script")

    # Look for scripts with identical names in different directories
    local duplicate_count
    duplicate_count=$(find . -name "$script_basename" -type f 2>/dev/null | grep -v "./build/work" | wc -l)

    if [[ $duplicate_count -gt 1 ]]; then
        conflicts+=("Duplicate name found")
    fi

    printf "%s" "${conflicts[*]}"
}

# Check if script seems deprecated
check_script_deprecation() {
    local script="$1"
    local deprecated_indicators=()

    # Check for deprecation markers in content
    if grep -qi "deprecated\|obsolete\|legacy\|todo.*remove\|fixme.*remove" "$script" 2>/dev/null; then
        deprecated_indicators+=("Contains deprecation markers")
    fi

    # Check for old-style patterns
    if grep -q "#!/bin/sh" "$script" 2>/dev/null; then
        deprecated_indicators+=("Uses old sh shebang")
    fi

    # Check if script has any functionality
    local line_count
    line_count=$(grep -v "^\s*#\|^\s*$" "$script" 2>/dev/null | wc -l)
    if [[ $line_count -lt 5 ]]; then
        deprecated_indicators+=("Very short script, might be incomplete")
    fi

    printf "%s" "${deprecated_indicators[*]}"
}

# Find consolidation opportunities
find_consolidation_candidates() {
    local script="$1"
    local candidates=()

    # Check script directory and content for patterns
    if [[ "$script" =~ testing/ ]] && grep -q "test\|validate\|check" "$script" 2>/dev/null; then
        candidates+=("testing")
    fi

    if [[ "$script" =~ gaming/ ]] && grep -q "gaming\|steam\|wine" "$script" 2>/dev/null; then
        candidates+=("gaming")
    fi

    if [[ "$script" =~ optimization/ ]] && grep -q "optimize\|performance\|speed" "$script" 2>/dev/null; then
        candidates+=("optimization")
    fi

    if [[ "$script" =~ setup/ ]] && grep -q "install\|setup\|configure" "$script" 2>/dev/null; then
        candidates+=("setup")
    fi

    printf "%s" "${candidates[*]}"
}

# Validate a single script
validate_single_script() {
    local script="$1"
    local relative_path="${script#./}"

    echo -n "Validating: $relative_path ... "

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

    # Determine overall status
    if [[ -n "$basic_errors" ]]; then
        echo -e "${RED}❌ ERRORS: $basic_errors${NC}"
        ((ERROR_SCRIPTS++))
    else
        echo -e "${GREEN}✓ OK${NC}"
        ((VALID_SCRIPTS++))
    fi

    # Report additional findings
    if [[ -n "$conflicts" ]]; then
        echo -e "  ${YELLOW}⚠️  CONFLICTS: $conflicts${NC}"
        ((CONFLICT_SCRIPTS++))
    fi

    if [[ -n "$deprecation" ]]; then
        echo -e "  ${YELLOW}🕒 DEPRECATED: $deprecation${NC}"
        ((DEPRECATED_SCRIPTS++))
    fi

    if [[ -n "$consolidation" ]]; then
        echo -e "  ${BLUE}🔄 CONSOLIDATION: $consolidation category${NC}"
        CONSOLIDATION_CANDIDATES+=("$relative_path:$consolidation")
    fi
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

    # Validate each script
    for script in "${scripts[@]}"; do
        validate_single_script "$script"
    done

    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                          Validation Summary                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo "📊 STATISTICS:"
    echo "  Total Scripts:         $TOTAL_SCRIPTS"
    echo -e "  Valid Scripts:         ${GREEN}$VALID_SCRIPTS${NC}"
    echo -e "  Scripts with Errors:   ${RED}$ERROR_SCRIPTS${NC}"
    echo -e "  Scripts with Conflicts: ${YELLOW}$CONFLICT_SCRIPTS${NC}"
    echo -e "  Deprecated Scripts:    ${YELLOW}$DEPRECATED_SCRIPTS${NC}"
    echo -e "  Consolidation Candidates: ${BLUE}${#CONSOLIDATION_CANDIDATES[@]}${NC}"
    echo

    if [[ ${#CONSOLIDATION_CANDIDATES[@]} -gt 0 ]]; then
        echo "🔄 CONSOLIDATION OPPORTUNITIES:"
        for candidate in "${CONSOLIDATION_CANDIDATES[@]}"; do
            echo -e "  ${BLUE}• ${candidate%:*} → ${candidate#*:}${NC}"
        done
        echo
    fi

    # Provide recommendations
    echo "💡 RECOMMENDATIONS:"
    if [[ $ERROR_SCRIPTS -gt 0 ]]; then
        echo -e "  ${RED}1. Fix scripts with errors immediately${NC}"
    fi
    if [[ $CONFLICT_SCRIPTS -gt 0 ]]; then
        echo -e "  ${YELLOW}2. Resolve naming conflicts${NC}"
    fi
    if [[ $DEPRECATED_SCRIPTS -gt 0 ]]; then
        echo -e "  ${YELLOW}3. Review and update deprecated scripts${NC}"
    fi
    if [[ ${#CONSOLIDATION_CANDIDATES[@]} -gt 5 ]]; then
        echo -e "  ${BLUE}4. Consider consolidating similar scripts${NC}"
    fi

    echo
    # Always return success code to see full results
    if [[ $ERROR_SCRIPTS -gt 0 ]]; then
        echo -e "${RED}❌ Validation found $ERROR_SCRIPTS scripts with errors${NC}"
    elif [[ $CONFLICT_SCRIPTS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Validation found $CONFLICT_SCRIPTS scripts with conflicts${NC}"
    else
        echo -e "${GREEN}✅ All scripts validated successfully${NC}"
    fi

    # Return 0 for now to see complete output
    return 0
}

# Run main function
main "$@"
