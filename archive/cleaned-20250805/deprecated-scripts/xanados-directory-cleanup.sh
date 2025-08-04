#!/bin/bash
# ============================================================================
# xanadOS Directory Organization and Cleanup Script
# Organizes project structure and cleans temporary files
# ============================================================================

set -euo pipefail

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Configuration
readonly SCRIPT_NAME="xanadOS Directory Organization"
readonly SCRIPT_VERSION="1.0.0"
readonly CLEANUP_DATE=$(date +%Y%m%d-%H%M%S)

# Use XANADOS_ROOT from common.sh (already defined)

# Cleanup statistics
CLEANED_FILES=0
ORGANIZED_FILES=0
ARCHIVED_FILES=0
TOTAL_SIZE_CLEANED=0

# ============================================================================
# Helper Functions
# ============================================================================

print_banner() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     xanadOS Directory Cleanup & Organization             ║${NC}"
    echo -e "${BLUE}║                               $(date)                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

cleanup_file() {
    local file="$1"
    local reason="$2"
    
    if [[ -f "$file" ]]; then
        local size
        size=$(get_file_size "$file")
        TOTAL_SIZE_CLEANED=$((TOTAL_SIZE_CLEANED + size))
        CLEANED_FILES=$((CLEANED_FILES + 1))
        
        echo "  🗑️  Removing: $(basename "$file") (${reason})"
        rm -f "$file"
    fi
}

move_file() {
    local source="$1"
    local destination="$2"
    local reason="$3"
    
    if [[ -f "$source" ]]; then
        mkdir -p "$(dirname "$destination")"
        ORGANIZED_FILES=$((ORGANIZED_FILES + 1))
        
        echo "  📦 Moving: $(basename "$source") → $(dirname "$destination") (${reason})"
        mv "$source" "$destination"
    fi
}

archive_file() {
    local source="$1"
    local destination="$2"
    local reason="$3"
    
    if [[ -f "$source" ]]; then
        mkdir -p "$(dirname "$destination")"
        ARCHIVED_FILES=$((ARCHIVED_FILES + 1))
        
        echo "  📚 Archiving: $(basename "$source") → $(dirname "$destination") (${reason})"
        mv "$source" "$destination"
    fi
}

# ============================================================================
# Cleanup Functions
# ============================================================================

cleanup_temporary_files() {
    print_status "Cleaning temporary and cache files..."
    
    # Find and remove common temporary files
    find "$XANADOS_ROOT" -type f \( \
        -name "*.tmp" -o \
        -name "*.temp" -o \
        -name "*~" -o \
        -name "*.bak" -o \
        -name "*.old" -o \
        -name "*.orig" -o \
        -name ".DS_Store" -o \
        -name "Thumbs.db" -o \
        -name "*.swp" -o \
        -name "*.swo" -o \
        -name "core.*" \
    \) | while read -r file; do
        cleanup_file "$file" "temporary file"
    done
    
    # Clean up empty directories
    find "$XANADOS_ROOT" -type d -empty -not -path "*/.git/*" | while read -r dir; do
        if [[ "$dir" != "$XANADOS_ROOT" ]]; then
            echo "  🗑️  Removing empty directory: $(basename "$dir")"
            rmdir "$dir" 2>/dev/null || true
        fi
    done
}

organize_development_reports() {
    print_status "Organizing development reports and documentation..."
    
    local dev_reports_dir="$XANADOS_ROOT/docs/development/reports"
    mkdir -p "$dev_reports_dir"
    
    # Organize scattered development reports
    find "$XANADOS_ROOT/docs/development" -maxdepth 1 -name "*-report.md" -o -name "*-completion*.md" -o -name "*-summary.md" | while read -r file; do
        if [[ "$(dirname "$file")" != "$dev_reports_dir" ]]; then
            move_file "$file" "$dev_reports_dir/$(basename "$file")" "development report"
        fi
    done
    
    # Organize task completion reports
    find "$XANADOS_ROOT/docs/development" -maxdepth 1 -name "task-*.md" | while read -r file; do
        if [[ "$(dirname "$file")" != "$dev_reports_dir" ]]; then
            move_file "$file" "$dev_reports_dir/$(basename "$file")" "task report"
        fi
    done
}

organize_test_results() {
    print_status "Organizing test results and logs..."
    
    local results_archive="$XANADOS_ROOT/results/archive/$(date +%Y-%m)"
    mkdir -p "$results_archive"
    
    # Archive old test results (older than 7 days)
    find "$XANADOS_ROOT/results" -type f -name "*.log" -mtime +7 | while read -r file; do
        local relative_path="${file#$XANADOS_ROOT/results/}"
        archive_file "$file" "$results_archive/$relative_path" "old log file"
    done
    
    # Clean up very old logs (older than 30 days)
    find "$XANADOS_ROOT/results" -type f -name "*.log" -mtime +30 | while read -r file; do
        cleanup_file "$file" "old log file (>30 days)"
    done
}

organize_build_artifacts() {
    print_status "Organizing build artifacts..."
    
    local build_dir="$XANADOS_ROOT/build"
    
    if [[ -d "$build_dir" ]]; then
        # Clean up old build cache
        find "$build_dir/cache" -type f -mtime +14 2>/dev/null | while read -r file; do
            cleanup_file "$file" "old build cache"
        done
        
        # Archive old ISOs
        local iso_archive="$build_dir/archive/isos"
        mkdir -p "$iso_archive"
        find "$build_dir/iso" -name "*.iso" -mtime +7 2>/dev/null | while read -r file; do
            archive_file "$file" "$iso_archive/$(basename "$file")" "old ISO build"
        done
    fi
}

organize_scripts() {
    print_status "Organizing and validating scripts..."
    
    # Ensure all scripts are executable
    find "$XANADOS_ROOT/scripts" -name "*.sh" -type f ! -executable | while read -r script; do
        echo "  🔧 Making executable: $(basename "$script")"
        chmod +x "$script"
        ORGANIZED_FILES=$((ORGANIZED_FILES + 1))
    done
    
    # Move any misplaced scripts
    find "$XANADOS_ROOT" -maxdepth 2 -name "*.sh" -not -path "*/scripts/*" -not -path "*/.git/*" | while read -r script; do
        local target_dir="$XANADOS_ROOT/scripts/utilities"
        mkdir -p "$target_dir"
        move_file "$script" "$target_dir/$(basename "$script")" "misplaced script"
    done
}

organize_archive_directory() {
    print_status "Organizing archive directory..."
    
    local archive_dir="$XANADOS_ROOT/archive"
    
    if [[ -d "$archive_dir" ]]; then
        # Compress old backups
        find "$archive_dir/backups" -type d -name "*-2025*" -mtime +14 2>/dev/null | while read -r backup_dir; do
            if [[ -d "$backup_dir" && ! -f "${backup_dir}.tar.gz" ]]; then
                echo "  📦 Compressing backup: $(basename "$backup_dir")"
                tar -czf "${backup_dir}.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")"
                rm -rf "$backup_dir"
                ORGANIZED_FILES=$((ORGANIZED_FILES + 1))
            fi
        done
        
        # Clean up very old deprecated files (older than 60 days)
        find "$archive_dir/deprecated" -type f -mtime +60 2>/dev/null | while read -r file; do
            cleanup_file "$file" "very old deprecated file"
        done
    fi
}

create_directory_index() {
    print_status "Creating directory structure index..."
    
    local index_file="$XANADOS_ROOT/docs/project_structure_$(date +%Y%m%d).md"
    
    cat > "$index_file" << 'EOF'
# xanadOS Project Structure

*Generated automatically on $(date)*

## Directory Overview

```
xanadOS/
├── archive/           # Archived and deprecated files
│   ├── backups/       # System backups and migrations
│   ├── deprecated/    # Deprecated code and configurations
│   └── releases/      # Historical release artifacts
├── build/             # Build system and artifacts
│   ├── iso/          # ISO generation and storage
│   ├── cache/        # Build cache files
│   └── makefiles/    # Build configuration
├── configs/           # System configuration files
│   ├── system/       # System-level configurations
│   ├── desktop/      # Desktop environment configs
│   ├── network/      # Network optimizations
│   └── security/     # Security configurations
├── docs/              # Documentation
│   ├── development/  # Development documentation
│   ├── user/         # User guides and manuals
│   └── api/          # API documentation
├── packages/          # Package definitions and lists
│   ├── core/         # Core system packages
│   ├── desktop/      # Desktop environment packages
│   └── gaming/       # Gaming-specific packages
├── results/           # Test results and logs
│   ├── logs/         # System and test logs
│   ├── reports/      # Generated reports
│   └── benchmarks/   # Performance benchmarks
├── scripts/           # Automation scripts
│   ├── build/        # Build automation
│   ├── setup/        # System setup scripts
│   ├── lib/          # Shared libraries
│   ├── testing/      # Testing frameworks
│   └── utilities/    # System utilities
├── testing/           # Test suites and validation
│   ├── automated/    # Automated test suites
│   ├── integration/  # Integration tests
│   └── performance/  # Performance tests
└── workflows/         # CI/CD and automation workflows
    ├── ci-cd/        # Continuous integration
    └── release/      # Release automation
```

## File Statistics

EOF

    # Add directory statistics
    echo "### Directory Sizes" >> "$index_file"
    echo "" >> "$index_file"
    echo "\`\`\`" >> "$index_file"
    du -sh "$XANADOS_ROOT"/*/ 2>/dev/null | sort -hr >> "$index_file"
    echo "\`\`\`" >> "$index_file"
    echo "" >> "$index_file"
    
    # Add file counts
    echo "### File Counts by Type" >> "$index_file"
    echo "" >> "$index_file"
    echo "\`\`\`" >> "$index_file"
    echo "Shell Scripts: $(find "$XANADOS_ROOT" -name "*.sh" | wc -l)"
    echo "Markdown Files: $(find "$XANADOS_ROOT" -name "*.md" | wc -l)"
    echo "Configuration Files: $(find "$XANADOS_ROOT" -name "*.conf" -o -name "*.cfg" -o -name "*.ini" | wc -l)"
    echo "Log Files: $(find "$XANADOS_ROOT" -name "*.log" | wc -l)"
    echo "\`\`\`" >> "$index_file"
    
    echo "  📋 Created project structure index: $index_file"
    ORGANIZED_FILES=$((ORGANIZED_FILES + 1))
}

update_gitignore() {
    print_status "Updating .gitignore for better organization..."
    
    local gitignore="$XANADOS_ROOT/.gitignore"
    
    # Backup existing .gitignore
    if [[ -f "$gitignore" ]]; then
        cp "$gitignore" "${gitignore}.backup"
    fi
    
    cat >> "$gitignore" << 'EOF'

# xanadOS specific ignores
results/logs/*
results/temp/*
build/cache/*
build/work/*
*.tmp
*.temp
*~
*.bak
*.old
*.orig
.DS_Store
Thumbs.db
core.*

# But keep structure
!results/logs/.gitkeep
!results/temp/.gitkeep
!build/cache/.gitkeep
!build/work/.gitkeep
EOF

    echo "  📝 Updated .gitignore with cleanup patterns"
    ORGANIZED_FILES=$((ORGANIZED_FILES + 1))
}

create_directory_keepers() {
    print_status "Creating .gitkeep files for empty directories..."
    
    # Important directories that should be preserved even when empty
    local keeper_dirs=(
        "results/logs"
        "results/temp"
        "results/benchmarks" 
        "results/reports"
        "build/cache"
        "build/work"
        "build/iso"
        "testing/results"
        "archive/backups"
        "docs/api"
    )
    
    for dir in "${keeper_dirs[@]}"; do
        local full_path="$XANADOS_ROOT/$dir"
        mkdir -p "$full_path"
        if [[ ! -f "$full_path/.gitkeep" ]]; then
            touch "$full_path/.gitkeep"
            echo "  📌 Created keeper: $dir/.gitkeep"
            ORGANIZED_FILES=$((ORGANIZED_FILES + 1))
        fi
    done
}

# ============================================================================
# Report Functions
# ============================================================================

print_cleanup_summary() {
    local size_mb=$((TOTAL_SIZE_CLEANED / 1024 / 1024))
    
    echo
    print_header "🧹 Cleanup and Organization Summary"
    echo
    echo -e "${GREEN}📊 Statistics:${NC}"
    echo "  🗑️  Files cleaned: $CLEANED_FILES"
    echo "  📦 Files organized: $ORGANIZED_FILES"  
    echo "  📚 Files archived: $ARCHIVED_FILES"
    echo "  💾 Space freed: ${size_mb} MB"
    echo
    echo -e "${GREEN}📁 Directory Structure:${NC}"
    echo "  ✅ Temporary files removed"
    echo "  ✅ Development reports organized"
    echo "  ✅ Test results archived"
    echo "  ✅ Build artifacts cleaned"
    echo "  ✅ Scripts validated and organized"
    echo "  ✅ Archive directory optimized"
    echo "  ✅ Project structure documented"
    echo "  ✅ .gitignore updated"
    echo "  ✅ Directory keepers created"
    echo
    print_success "xanadOS directory organization complete!"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    print_banner
    
    print_status "Starting xanadOS directory cleanup and organization..."
    echo
    
    # Change to xanadOS directory
    cd "$XANADOS_ROOT"
    
    # Execute cleanup and organization tasks
    cleanup_temporary_files
    organize_development_reports
    organize_test_results
    organize_build_artifacts
    organize_scripts
    organize_archive_directory
    create_directory_index
    update_gitignore
    create_directory_keepers
    
    # Final summary
    print_cleanup_summary
    
    echo
    print_status "Directory organization completed successfully!"
    print_status "Project is now clean and well-organized for Phase 4 development."
}

# Execute main function
main "$@"
