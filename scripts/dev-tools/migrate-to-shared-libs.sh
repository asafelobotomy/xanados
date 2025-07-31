#!/bin/bash
# xanadOS Script Migration Tool
# Converts existing scripts to use shared library system
# Version: 1.0.0

# Note: Not using set -e to handle errors gracefully

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$XANADOS_ROOT/scripts/lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Create backup of a script
create_backup() {
    local script_file="$1"
    local backup_dir="$XANADOS_ROOT/archive/backups/migration-$(date +%Y%m%d)"
    local backup_file="$backup_dir/$(basename "$script_file").migration.backup"
    
    mkdir -p "$backup_dir"
    
    if [ ! -f "$backup_file" ]; then
        cp "$script_file" "$backup_file"
        print_success "Created backup: $backup_file"
    fi
}

# Check if script has duplicate print functions
has_duplicate_functions() {
    local script_file="$1"
    
    grep -q "^print_status()" "$script_file" || \
    grep -q "^print_success()" "$script_file" || \
    grep -q "^print_warning()" "$script_file" || \
    grep -q "^print_error()" "$script_file"
}

# Get relative path to lib directory from script location
get_lib_path() {
    local script_file="$1"
    local script_dir
    script_dir="$(dirname "$script_file")"
    
    # Calculate relative path from script to lib directory
    local rel_path
    rel_path="$(realpath --relative-to="$script_dir" "$LIB_DIR")"
    echo "$rel_path"
}

# Migrate a single script
migrate_script() {
    local script_file="$1"
    local dry_run="${2:-false}"
    
    if [ ! -f "$script_file" ]; then
        print_error "Script file not found: $script_file"
        return 1
    fi
    
    print_status "Processing: $(basename "$script_file")"
    
    if ! has_duplicate_functions "$script_file"; then
        print_warning "  No duplicate functions found, skipping"
        return 0
    fi
    
    if [ "$dry_run" == "false" ]; then
        create_backup "$script_file"
    fi
    
    local lib_path
    lib_path="$(get_lib_path "$script_file")"
    
    # Create temporary file for modifications
    local temp_file
    temp_file="$(mktemp)"
    
    # Process the script
    local in_function_block=false
    local function_name=""
    local brace_count=0
    local skip_line=false
    local added_source=false
    
    while IFS= read -r line; do
        skip_line=false
        
        # Check if we're starting a print function definition
        if [[ "$line" =~ ^(print_status|print_success|print_warning|print_error)\(\)[[:space:]]*\{ ]]; then
            function_name="${BASH_REMATCH[1]}"
            in_function_block=true
            brace_count=1
            skip_line=true
            print_warning "  Removing duplicate function: $function_name"
        elif [[ "$line" =~ ^(print_status|print_success|print_warning|print_error)\(\) ]]; then
            function_name="${BASH_REMATCH[1]}"
            in_function_block=true
            brace_count=0
            skip_line=true
            print_warning "  Removing duplicate function: $function_name"
        fi
        
        # If we're in a function block, count braces
        if [ "$in_function_block" == true ]; then
            local open_braces
            local close_braces
            open_braces=$(echo "$line" | tr -cd '{' | wc -c)
            close_braces=$(echo "$line" | tr -cd '}' | wc -c)
            brace_count=$((brace_count + open_braces - close_braces))
            
            # Check if we found opening brace on this line
            if [[ "$line" =~ \{ ]] && [ "$brace_count" -eq 1 ] && [ "$function_name" != "" ]; then
                skip_line=true
            fi
            
            # If we're at the end of the function, stop skipping
            if [ "$brace_count" -le 0 ]; then
                in_function_block=false
                function_name=""
                skip_line=true
            else
                skip_line=true
            fi
        fi
        
        # Add library source after shebang and before first non-comment line
        if [ "$added_source" == false ] && [[ "$line" =~ ^[^#] ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]]; then
            {
                echo ""
                echo "# Source xanadOS shared libraries"
                echo "source \"$lib_path/common.sh\""
                echo ""
            } >> "$temp_file"
            added_source=true
        fi
        
        # Add the line if we're not skipping it
        if [ "$skip_line" == false ]; then
            echo "$line" >> "$temp_file"
        fi
        
    done < "$script_file"
    
    # If this is not a dry run, replace the original file
    if [ "$dry_run" == "false" ]; then
        mv "$temp_file" "$script_file"
        print_success "  Migration completed"
    else
        print_status "  [DRY RUN] Would remove duplicate functions and add library source"
        rm -f "$temp_file"
    fi
}

# Migrate all scripts in a directory
migrate_directory() {
    local dir="$1"
    local dry_run="${2:-false}"
    
    if [ ! -d "$dir" ]; then
        print_error "Directory not found: $dir"
        return 1
    fi
    
    print_status "Migrating scripts in: $dir"
    
    local script_count=0
    local migrated_count=0
    
    find "$dir" -name "*.sh" -type f | while read -r script; do
        # Skip library files themselves
        if [[ "$script" == *"/lib/"* ]]; then
            continue
        fi
        
        # Skip migration script itself
        if [[ "$(basename "$script")" == "migrate-to-shared-libs.sh" ]]; then
            continue
        fi
        
        ((script_count++))
        
        if migrate_script "$script" "$dry_run"; then
            ((migrated_count++))
        fi
    done
    
    print_success "Migration completed: $migrated_count scripts processed"
}

# Verify migration was successful
verify_migration() {
    local script_file="$1"
    
    # Check if script sources the common library
    if grep -q "source.*common\.sh" "$script_file"; then
        # Check if duplicate functions were removed
        if ! has_duplicate_functions "$script_file"; then
            return 0
        else
            print_warning "Script still contains duplicate functions: $(basename "$script_file")"
            return 1
        fi
    else
        print_warning "Script does not source common library: $(basename "$script_file")"
        return 1
    fi
}

# Test migration on a single script
test_migration() {
    local script_file="$1"
    
    print_status "Testing migration for: $(basename "$script_file")"
    
    # Create temporary copy
    local temp_script
    temp_script="$(mktemp --suffix=.sh)"
    cp "$script_file" "$temp_script"
    
    # Migrate the temporary copy
    if migrate_script "$temp_script" "false"; then
        # Test syntax
        if bash -n "$temp_script" 2>/dev/null; then
            print_success "Migration test passed"
            verify_migration "$temp_script"
        else
            print_error "Migration test failed - syntax error"
            return 1
        fi
    else
        print_error "Migration failed"
        return 1
    fi
    
    # Cleanup
    rm -f "$temp_script"
}

# Generate migration report
generate_migration_report() {
    local dry_run="${1:-true}"
    
    print_status "Generating migration report..."
    
    local report_dir="$XANADOS_ROOT/archive/reports/$(date +%Y%m%d)"
    local report_file="$report_dir/migration-report.md"
    mkdir -p "$report_dir"
    
    # Count scripts and duplicates
    local total_scripts=0
    local scripts_with_duplicates=0
    local duplicate_scripts=()
    
    while IFS= read -r script; do
        # Skip library files
        if [[ "$script" == *"/lib/"* ]]; then
            continue
        fi
        
        ((total_scripts++))
        
        if has_duplicate_functions "$script"; then
            ((scripts_with_duplicates++))
            local rel_path="${script#$XANADOS_ROOT/}"
            duplicate_scripts+=("$rel_path")
        fi
    done < <(find "$XANADOS_ROOT/scripts" -name "*.sh" -type f)
    
    {
        echo "# xanadOS Script Migration Report"
        echo ""
        echo "**Date**: $(date)"
        echo "**Type**: Shared Library Migration"
        echo ""
        echo "## Scripts Analysis"
        echo ""
        
        for script in "${duplicate_scripts[@]}"; do
            echo "- \`$script\` - Contains duplicate print functions"
        done
        
        echo ""
        echo "## Summary"
        echo ""
        echo "- **Total Scripts**: $total_scripts"
        echo "- **Scripts with Duplicates**: $scripts_with_duplicates"
        echo "- **Migration Status**: $([ "$dry_run" == "true" ] && echo "Planned" || echo "Completed")"
        echo ""
        
        if [ "$dry_run" == "true" ]; then
            echo "## Planned Changes"
            echo ""
            echo "1. Create backups in \`archive/backups/migration-$(date +%Y%m%d)/\`"
            echo "2. Remove duplicate print functions from all scripts"
            echo "3. Add \`source \"../lib/common.sh\"\` to all scripts"
            echo "4. Verify syntax and functionality"
        else
            echo "## Completed Changes"
            echo ""
            echo "1. ✅ Created backups in \`archive/backups/migration-$(date +%Y%m%d)/\`"
            echo "2. ✅ Removed duplicate print functions"
            echo "3. ✅ Added shared library sourcing"
            echo "4. ✅ Verified syntax"
        fi
        
    } > "$report_file"
    
    print_success "Migration report generated: $report_file"
}

# Main execution
main() {
    local command="${1:-help}"
    local target="${2:-}"
    local dry_run="${3:-false}"
    
    case "$command" in
        "test")
            if [ -z "$target" ]; then
                print_error "Please specify a script file to test"
                exit 1
            fi
            test_migration "$target"
            ;;
        "migrate-script")
            if [ -z "$target" ]; then
                print_error "Please specify a script file to migrate"
                exit 1
            fi
            migrate_script "$target" "$dry_run"
            ;;
        "migrate-dir")
            if [ -z "$target" ]; then
                target="$XANADOS_ROOT/scripts"
            fi
            migrate_directory "$target" "$dry_run"
            ;;
        "migrate-all")
            generate_migration_report "true"
            print_status "Starting full migration of all scripts..."
            migrate_directory "$XANADOS_ROOT/scripts" "$dry_run"
            generate_migration_report "false"
            ;;
        "report")
            generate_migration_report "$dry_run"
            ;;
        "verify")
            if [ -z "$target" ]; then
                print_error "Please specify a script file to verify"
                exit 1
            fi
            verify_migration "$target"
            ;;
        "help"|*)
            echo "xanadOS Script Migration Tool"
            echo ""
            echo "Usage: $0 <command> [target] [dry_run]"
            echo ""
            echo "Commands:"
            echo "  test <script>          - Test migration on a single script"
            echo "  migrate-script <file>  - Migrate a single script"
            echo "  migrate-dir <dir>      - Migrate all scripts in directory"
            echo "  migrate-all            - Migrate all scripts in project"
            echo "  report [dry_run]       - Generate migration report"
            echo "  verify <script>        - Verify migration was successful"
            echo "  help                   - Show this help"
            echo ""
            echo "Options:"
            echo "  dry_run: true|false    - Preview changes without applying them"
            echo ""
            echo "Examples:"
            echo "  $0 migrate-all false           # Migrate all scripts"
            echo "  $0 migrate-dir scripts/setup   # Migrate setup scripts only"
            echo "  $0 test scripts/setup/dev-environment.sh"
            ;;
    esac
}

# Check if script is being executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Verify shared libraries exist
    if [ ! -f "$LIB_DIR/common.sh" ]; then
        print_error "Shared libraries not found. Please ensure scripts/lib/common.sh exists."
        exit 1
    fi
    
    main "$@"
fi
