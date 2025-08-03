#!/bin/bash

# xanadOS Script Quality Checker
# Based on Linux Shell Best Practices from OWF
# https://learn.openwaterfoundation.org/owf-learn-linux-shell/best-practices/best-practices/

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*" >&2
}

check_script_quality() {
    local script_path="$1"
    local score=0
    local max_score=10
    local issues=()

    echo "📋 Checking: $(basename "$script_path")"

    # Check 1: Shebang line (Best Practice: Indicate shell)
    if head -1 "$script_path" | grep -q '^#!/bin/bash'; then
        ((score++))
    else
        issues+=("Missing or incorrect shebang line")
    fi

    # Check 2: Error handling (Best Practice: Proper error handling)
    if grep -q "set -euo pipefail" "$script_path"; then
        ((score++))
    else
        issues+=("Missing error handling (set -euo pipefail)")
    fi

    # Check 3: Usage documentation (Best Practice: Create documentation)
    if grep -q "show_usage\|usage\|--help\|Usage:" "$script_path"; then
        ((score++))
    else
        issues+=("Missing usage documentation")
    fi

    # Check 4: Logging (Best Practice: Consider options for logging)
    if grep -q "log_info\|log_error\|echo.*\[INFO\]\|\[ERROR\]" "$script_path"; then
        ((score++))
    else
        issues+=("Missing standardized logging")
    fi

    # Check 5: Script header documentation (Best Practice: Write understandable code)
    if grep -q "Description\|Purpose\|Author\|Version" "$script_path"; then
        ((score++))
    else
        issues+=("Missing script documentation header")
    fi

    # Check 6: Directory validation (Best Practice: Check script running folder)
    if grep -q "SCRIPT_DIR\|pwd\|dirname.*BASH_SOURCE" "$script_path"; then
        ((score++))
    else
        issues+=("Missing directory/path validation")
    fi

    # Check 7: Function documentation (Best Practice: Write understandable code)
    local func_count=$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(" "$script_path" 2>/dev/null || echo 0)
    if [[ $func_count -gt 0 ]]; then
        if grep -q "^[[:space:]]*#.*function\|^[[:space:]]*# [A-Z]" "$script_path"; then
            ((score++))
        else
            issues+=("Functions lack documentation comments")
        fi
    else
        ((score++))  # No functions, so no documentation needed
    fi

    # Check 8: Cleanup handling (Best Practice: Cleanup resources)
    if grep -q "trap\|cleanup\|EXIT\|mktemp" "$script_path"; then
        ((score++))
    else
        issues+=("Missing cleanup/trap handling")
    fi

    # Check 9: Input validation (Best Practice: Validate inputs)
    if grep -q "if.*\[\[.*-z\|if.*\[\[.*-n\|getopts\|case.*\$1\|\$#" "$script_path"; then
        ((score++))
    else
        issues+=("Missing input validation")
    fi

    # Check 10: Troubleshooting info (Best Practice: Echo useful troubleshooting information)
    if grep -q "echo.*started\|echo.*finished\|echo.*version\|echo.*environment" "$script_path"; then
        ((score++))
    else
        issues+=("Missing troubleshooting/status information")
    fi

    # Report results
    local percentage=$((score * 100 / max_score))

    if [[ $percentage -ge 80 ]]; then
        echo "  ✅ Score: $score/$max_score ($percentage%) - EXCELLENT"
    elif [[ $percentage -ge 60 ]]; then
        echo "  ⚠️  Score: $score/$max_score ($percentage%) - GOOD"
    elif [[ $percentage -ge 40 ]]; then
        echo "  ⚠️  Score: $score/$max_score ($percentage%) - NEEDS IMPROVEMENT"
    else
        echo "  ❌ Score: $score/$max_score ($percentage%) - POOR"
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "     Issues found:"
        for issue in "${issues[@]}"; do
            echo "     - $issue"
        done
    fi

    echo
    return $((max_score - score))
}

generate_quality_report() {
    local output_file="$XANADOS_ROOT/docs/development/script-quality-report-$(date +%Y%m%d).md"

    cat > "$output_file" << EOF
# xanadOS Script Quality Report

**Generated:** $(date)
**Based on:** [Linux Shell Best Practices](https://learn.openwaterfoundation.org/owf-learn-linux-shell/best-practices/best-practices/)

## Quality Criteria

1. ✅ **Shebang Line** - Proper shell specification (\`#!/bin/bash\`)
2. ✅ **Error Handling** - Strict mode (\`set -euo pipefail\`)
3. ✅ **Usage Documentation** - Help/usage functions
4. ✅ **Logging** - Standardized logging functions
5. ✅ **Script Documentation** - Header with description, author, version
6. ✅ **Directory Validation** - Proper path handling
7. ✅ **Function Documentation** - Comments for functions
8. ✅ **Cleanup Handling** - Trap handlers and resource cleanup
9. ✅ **Input Validation** - Parameter checking
10. ✅ **Troubleshooting Info** - Status and environment information

## Script Analysis Results

EOF

    echo "# xanadOS Script Quality Report" > "$output_file.tmp"
    echo "" >> "$output_file.tmp"
    echo "**Generated:** $(date)" >> "$output_file.tmp"
    echo "**Based on:** [Linux Shell Best Practices](https://learn.openwaterfoundation.org/owf-learn-linux-shell/best-practices/best-practices/)" >> "$output_file.tmp"
    echo "" >> "$output_file.tmp"

    local total_issues=0
    local script_count=0
    local excellent=0
    local good=0
    local needs_improvement=0
    local poor=0

    echo "### Excellent Scripts (80%+)" >> "$output_file.tmp"
    echo "" >> "$output_file.tmp"

    # Find and analyze all shell scripts
    while IFS= read -r -d '' script; do
        if [[ -f "$script" ]] && [[ "$script" != *"/archive/"* ]] && [[ "$script" != *"/build/xanados-installer/"* ]]; then
            local issues_count
            issues_count=$(check_script_quality "$script" 2>/dev/null || echo 10)
            total_issues=$((total_issues + issues_count))
            ((script_count++))

            local score=$((10 - issues_count))
            local percentage=$((score * 100 / 10))
            local relative_path="${script#$XANADOS_ROOT/}"

            if [[ $percentage -ge 80 ]]; then
                echo "- \`$relative_path\` - $score/10 ($percentage%)" >> "$output_file.tmp"
                ((excellent++))
            elif [[ $percentage -ge 60 ]]; then
                if [[ $good -eq 0 ]]; then
                    echo "" >> "$output_file.tmp"
                    echo "### Good Scripts (60-79%)" >> "$output_file.tmp"
                    echo "" >> "$output_file.tmp"
                fi
                echo "- \`$relative_path\` - $score/10 ($percentage%)" >> "$output_file.tmp"
                ((good++))
            elif [[ $percentage -ge 40 ]]; then
                if [[ $needs_improvement -eq 0 ]]; then
                    echo "" >> "$output_file.tmp"
                    echo "### Scripts Needing Improvement (40-59%)" >> "$output_file.tmp"
                    echo "" >> "$output_file.tmp"
                fi
                echo "- \`$relative_path\` - $score/10 ($percentage%)" >> "$output_file.tmp"
                ((needs_improvement++))
            else
                if [[ $poor -eq 0 ]]; then
                    echo "" >> "$output_file.tmp"
                    echo "### Poor Quality Scripts (<40%)" >> "$output_file.tmp"
                    echo "" >> "$output_file.tmp"
                fi
                echo "- \`$relative_path\` - $score/10 ($percentage%)" >> "$output_file.tmp"
                ((poor++))
            fi
        fi
    done < <(find "$XANADOS_ROOT" -name "*.sh" -type f -print0)

    # Add summary
    cat >> "$output_file.tmp" << EOF

## Summary

- **Total Scripts:** $script_count
- **Excellent (80%+):** $excellent
- **Good (60-79%):** $good
- **Needs Improvement (40-59%):** $needs_improvement
- **Poor (<40%):** $poor
- **Total Issues:** $total_issues

## Recommendations

### Immediate Actions (Priority 1)

1. **Add Error Handling** - All scripts should include \`set -euo pipefail\`
2. **Add Usage Documentation** - All scripts should have help/usage functions
3. **Standardize Logging** - Use consistent logging functions across all scripts

### Short-term Actions (Priority 2)

1. **Enhance Documentation** - Add proper script headers with description, author, version
2. **Add Input Validation** - Validate all command-line parameters and inputs
3. **Implement Cleanup** - Add trap handlers for proper resource cleanup

### Long-term Actions (Priority 3)

1. **Create Script Templates** - Standardized templates for new scripts
2. **Automated Quality Checks** - CI/CD integration for script quality validation
3. **Function Documentation** - Document all functions with proper comments

## Next Steps

1. Run this quality checker regularly: \`scripts/dev-tools/script-quality-checker.sh\`
2. Use the script template: \`scripts/templates/script-header-template.sh\`
3. Focus on scripts with scores below 60% first
4. Gradually improve all scripts to 80%+ quality score
EOF

    mv "$output_file.tmp" "$output_file"
    log_info "📊 Quality report generated: $output_file"
}

main() {
    echo "🔍 xanadOS Script Quality Checker"
    echo "Based on Linux Shell Best Practices"
    echo "================================="
    echo

    local total_issues=0
    local script_count=0
    local test_script="$XANADOS_ROOT/scripts/setup/gaming-setup-wizard.sh"

    echo "🧪 Testing with sample script: $(basename "$test_script")"
    if [[ -f "$test_script" ]]; then
        check_script_quality "$test_script"
        ((script_count++))
    fi

    echo "📊 Summary:"
    echo "   Scripts checked: $script_count"

    echo "✅ Script quality check completed!"
}

main "$@"
