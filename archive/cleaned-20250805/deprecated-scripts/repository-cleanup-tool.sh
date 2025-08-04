#!/bin/bash

# ==============================================================================
# xanadOS Repository-Wide Cleanup and Organization Tool
# ==============================================================================
# Description: Optimizes and organizes multiple directories in the xanadOS repository
# Author: xanadOS Development Team
# Version: 1.0.0
# License: MIT
# ==============================================================================

set -euo pipefail

# Source xanadOS shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header "🗂️ xanadOS Repository-Wide Cleanup and Organization"

# Create main cleanup archive
CLEANUP_DATE=$(date +%Y-%m-%d)
MAIN_ARCHIVE="$XANADOS_ROOT/archive/deprecated/$CLEANUP_DATE-repository-cleanup"
mkdir -p "$MAIN_ARCHIVE"

# Analysis functions
analyze_documentation() {
    print_status "📚 Analyzing docs/development/ directory..."

    local docs_dir="$XANADOS_ROOT/docs/development"
    local completion_reports=()
    local task_specific_docs=()
    local historical_summaries=()

    # Find completion reports
    while IFS= read -r file; do
        completion_reports+=("$file")
    done < <(find "$docs_dir" -name "*completion*" -o -name "*final-summary*" -o -name "*complete.md" 2>/dev/null)

    # Find task-specific documentation
    while IFS= read -r file; do
        task_specific_docs+=("$file")
    done < <(find "$docs_dir" -name "task-*" -o -name "phase*" 2>/dev/null)

    # Find historical summaries
    while IFS= read -r file; do
        historical_summaries+=("$file")
    done < <(find "$docs_dir" -name "*summary*" -o -name "*status*" 2>/dev/null)

    echo "  📊 Found ${#completion_reports[@]} completion reports"
    echo "  📊 Found ${#task_specific_docs[@]} task-specific documents"
    echo "  📊 Found ${#historical_summaries[@]} historical summaries"

    # Return arrays (simulate by printing)
    printf "COMPLETION:%s\n" "${completion_reports[@]}"
    printf "TASK_SPECIFIC:%s\n" "${task_specific_docs[@]}"
    printf "HISTORICAL:%s\n" "${historical_summaries[@]}"
}

analyze_demo_scripts() {
    print_status "🎮 Analyzing scripts/demo/ directory..."

    local demo_dir="$XANADOS_ROOT/scripts/demo"
    local integration_demos=()
    local feature_demos=()
    local outdated_demos=()

    # Analyze each demo script
    for demo in "$demo_dir"/*.sh; do
        if [[ -f "$demo" ]]; then
            local demo_name=$(basename "$demo")
            local demo_content=$(head -20 "$demo" 2>/dev/null || echo "")

            # Categorize based on content and name
            if [[ "$demo_name" =~ integration.*demo || "$demo_content" =~ integration ]]; then
                integration_demos+=("$demo")
            elif [[ "$demo_name" =~ gaming.*matrix || "$demo_content" =~ matrix ]]; then
                feature_demos+=("$demo")
            elif [[ "$demo_content" =~ compatibility.*demo ]]; then
                outdated_demos+=("$demo")
            else
                feature_demos+=("$demo")
            fi
        fi
    done

    echo "  📊 Found ${#integration_demos[@]} integration demos"
    echo "  📊 Found ${#feature_demos[@]} feature demos"
    echo "  📊 Found ${#outdated_demos[@]} potentially outdated demos"

    printf "INTEGRATION:%s\n" "${integration_demos[@]}"
    printf "FEATURE:%s\n" "${feature_demos[@]}"
    printf "OUTDATED:%s\n" "${outdated_demos[@]}"
}

analyze_archives() {
    print_status "📦 Analyzing archive/deprecated/ directory..."

    local archive_dir="$XANADOS_ROOT/archive/deprecated"
    local archive_dirs=()
    local total_files=0

    for dir in "$archive_dir"/*/; do
        if [[ -d "$dir" ]]; then
            archive_dirs+=("$dir")
            local file_count=$(find "$dir" -type f | wc -l)
            total_files=$((total_files + file_count))
            echo "    📁 $(basename "$dir"): $file_count files"
        fi
    done

    echo "  📊 Found ${#archive_dirs[@]} archive directories with $total_files total files"

    printf "ARCHIVES:%s\n" "${archive_dirs[@]}"
}

# Cleanup functions
cleanup_documentation() {
    print_status "📚 Organizing documentation..."

    local docs_archive="$MAIN_ARCHIVE/docs-completed-work"
    mkdir -p "$docs_archive"

    # Archive completed project documentation
    local docs_to_archive=(
        "docs/development/aur-package-integration-complete.md"
        "docs/development/build-system-modernization-complete.md"
        "docs/development/hardware-optimization-implementation-complete.md"
        "docs/development/paru-integration-completion-report.md"
        "docs/development/script-audit-completion.md"
        "docs/development/script-audit-implementation-report.md"
        "docs/development/task-3.2.3-final-summary.md"
        "docs/development/task-3.3.1-completion-report.md"
        "docs/development/task-3.3.1-final-summary.md"
        "docs/development/task-3.3.2-completion-report.md"
    )

    local count=0
    for doc in "${docs_to_archive[@]}"; do
        if [[ -f "$XANADOS_ROOT/$doc" ]]; then
            print_warning "  Archiving: $(basename "$doc")"
            mv "$XANADOS_ROOT/$doc" "$docs_archive/"
            ((count++))
        fi
    done

    # Archive completed reports from reports/ subdirectory
    local reports_archive="$MAIN_ARCHIVE/reports-completed"
    mkdir -p "$reports_archive"

    # Move completed phase and task reports
    find "$XANADOS_ROOT/docs/development/reports" -name "phase*completion*" -o -name "task*completion*" -o -name "*final-summary*" | while read -r report; do
        if [[ -f "$report" ]]; then
            print_warning "  Archiving report: $(basename "$report")"
            mv "$report" "$reports_archive/"
            ((count++))
        fi
    done

    print_success "  Archived $count documentation files"
}

cleanup_demo_scripts() {
    print_status "🎮 Organizing demo scripts..."

    local demo_archive="$MAIN_ARCHIVE/demo-scripts"
    mkdir -p "$demo_archive"

    # Archive integration demos that are no longer needed
    local demos_to_archive=(
        "scripts/demo/gaming-matrix-integration-demo.sh"
        "scripts/demo/gaming-matrix-integration-simple.sh"
        "scripts/demo/gaming-compatibility-demo.sh"
        "scripts/demo/demo-reports-integration.sh"
    )

    local count=0
    for demo in "${demos_to_archive[@]}"; do
        if [[ -f "$XANADOS_ROOT/$demo" ]]; then
            print_warning "  Archiving demo: $(basename "$demo")"
            mv "$XANADOS_ROOT/$demo" "$demo_archive/"
            ((count++))
        fi
    done

    print_success "  Archived $count demo scripts"
}

consolidate_archives() {
    print_status "📦 Consolidating archive structure..."

    # Create organized archive structure
    local organized_archive="$MAIN_ARCHIVE/consolidated-archives"
    mkdir -p "$organized_archive"/{dev-tools,cleanup-scripts,optimization-work,script-migration}

    # Note: This would be a complex consolidation - for now just document the structure
    cat > "$organized_archive/README.md" << 'EOF'
# Consolidated Archive Structure

## Organization
This directory represents a proposal for better archive organization:

- `dev-tools/` - Development tools that were single-use
- `cleanup-scripts/` - Scripts used for repository cleanup
- `optimization-work/` - Files from optimization projects
- `script-migration/` - Files from script migration work

## Current State
The existing dated archives should be reorganized into this structure for better long-term maintenance.

EOF

    print_success "  Created consolidated archive structure documentation"
}

clean_build_artifacts() {
    print_status "🏗️ Cleaning build artifacts..."

    local build_dir="$XANADOS_ROOT/build"
    local cleaned_count=0

    # Clean cache directories (but preserve structure)
    if [[ -d "$build_dir/cache" ]]; then
        find "$build_dir/cache" -type f -name "*.tmp" -delete 2>/dev/null || true
        find "$build_dir/cache" -type f -mtime +7 -delete 2>/dev/null || true
        cleaned_count=$((cleaned_count + $(find "$build_dir/cache" -type f -mtime +7 2>/dev/null | wc -l)))
    fi

    # Clean work directories
    if [[ -d "$build_dir/work" ]]; then
        find "$build_dir/work" -type f -mtime +7 -delete 2>/dev/null || true
    fi

    print_success "  Cleaned build artifacts (preserved structure)"
}

# Generate cleanup report
generate_cleanup_report() {
    print_status "📋 Generating cleanup report..."

    cat > "$MAIN_ARCHIVE/README.md" << EOF
# xanadOS Repository-Wide Cleanup Report

## Date
$(date '+%Y-%m-%d %H:%M:%S')

## Summary
This cleanup focused on organizing and archiving completed work across multiple directories.

## Actions Taken

### 📚 Documentation Cleanup (docs/development/)
- Archived completed project documentation
- Moved finished reports to archive
- Reduced clutter in active documentation

### 🎮 Demo Script Cleanup (scripts/demo/)
- Archived integration demos for completed features
- Kept useful ongoing demos
- Reduced confusion about which demos to use

### 📦 Archive Organization
- Created proposals for better archive structure
- Documented consolidation opportunities
- Improved long-term maintainability

### 🏗️ Build Artifact Cleanup
- Cleaned temporary build files
- Preserved build structure
- Removed outdated cache files

## Repository Impact
- ✅ Cleaner active directories
- ✅ Better organization of historical work
- ✅ Reduced clutter and confusion
- ✅ Preserved all important work
- ✅ Improved maintainability

## Next Steps
1. Review archived content
2. Update any documentation links
3. Consider implementing consolidated archive structure
4. Regular cleanup schedule

EOF

    print_success "  Generated comprehensive cleanup report"
}

# Main execution
main() {
    print_status "🚀 Starting repository-wide cleanup..."

    # Perform cleanup operations
    cleanup_documentation
    cleanup_demo_scripts
    consolidate_archives
    clean_build_artifacts
    generate_cleanup_report

    # Final summary
    echo
    print_header "📊 Cleanup Summary"

    local total_archived=$(find "$MAIN_ARCHIVE" -type f | wc -l)
    print_success "✅ Repository cleanup completed!"
    print_status "📦 Archive location: $MAIN_ARCHIVE"
    print_status "📊 Total files archived: $total_archived"

    echo
    print_status "🎯 Repository is now better organized with:"
    echo "  ✅ Cleaner docs/development/ directory"
    echo "  ✅ Streamlined scripts/demo/ directory"
    echo "  ✅ Organized archive structure"
    echo "  ✅ Cleaned build artifacts"
    echo "  ✅ All work preserved with documentation"

    print_success "🎉 xanadOS repository optimization complete!"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
