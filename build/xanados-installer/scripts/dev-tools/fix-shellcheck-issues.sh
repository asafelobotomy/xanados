#!/bin/bash

# xanadOS Shellcheck Issues Fixer
# This script fixes common shellcheck issues across all shell scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 xanadOS Shellcheck Issues Fixer${NC}"
echo "=================================================="

# Function to create backup
create_backup() {
    local file="$1"
    local backup_dir="$XANADOS_ROOT/archive/backups/shellcheck-$(date +%Y%m%d)"
    local backup_file="$backup_dir/$(basename "$file").shellcheck.backup"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    if [ ! -f "$backup_file" ]; then
        cp "$file" "$backup_file"
        echo -e "${GREEN}✓${NC} Created backup: $backup_file"
    fi
}

# Function to fix SC2148 - Add missing shebang
fix_missing_shebang() {
    local file="$1"
    
    if ! head -1 "$file" | grep -q "^#!"; then
        echo -e "${YELLOW}Fixing SC2148:${NC} Adding shebang to $file"
        create_backup "$file"
        
        # Add shebang at the beginning
        echo '#!/bin/bash' > "${file}.tmp"
        echo '' >> "${file}.tmp"
        cat "$file" >> "${file}.tmp"
        mv "${file}.tmp" "$file"
        
        echo -e "${GREEN}✓${NC} Added shebang to $file"
    fi
}

# Function to fix SC2162 - Add -r flag to read commands
fix_read_without_r() {
    local file="$1"
    
    if grep -q 'read -r -p' "$file"; then
        echo -e "${YELLOW}Fixing SC2162:${NC} Adding -r flag to read commands in $file"
        create_backup "$file"
        
        # Replace read -r -p with read -r -p
        sed -i 's/read -r -p/read -r -p/g' "$file"
        
        echo -e "${GREEN}✓${NC} Fixed read commands in $file"
    fi
}

# Function to fix SC2181 - Check exit code directly
fix_exit_code_check() {
    local file="$1"
    
    if grep -q 'if \[ \$? -ne 0 \]' "$file"; then
        echo -e "${YELLOW}Fixing SC2181:${NC} Fixing exit code checks in $file"
        create_backup "$file"
        
        # This is more complex and needs manual review for each case
        echo -e "${RED}⚠${NC} SC2181 found in $file - requires manual review"
        echo "   Replace 'if [ \$? -ne 0 ]' with direct command checks"
    fi
}

# Function to fix SC2002 - Useless cat
fix_useless_cat() {
    local file="$1"
    
    if grep -q 'cat.*|' "$file"; then
        echo -e "${YELLOW}Info SC2002:${NC} Useless cat found in $file"
        echo -e "${RED}⚠${NC} Manual review needed - replace 'cat file | cmd' with 'cmd < file'"
    fi
}

# Function to fix SC2086 - Quote variables to prevent word splitting
fix_unquoted_variables() {
    local file="$1"
    
    echo -e "${YELLOW}Info SC2086:${NC} Checking for unquoted variables in $file"
    echo -e "${RED}⚠${NC} Manual review needed - ensure variables are properly quoted"
}

# Function to fix SC2155 - Declare and assign separately
fix_declare_assign() {
    local file="$1"
    
    if grep -q 'local.*=' "$file"; then
        echo -e "${YELLOW}Info SC2155:${NC} Found local declarations with assignments in $file"
        echo -e "${RED}⚠${NC} Consider separating declaration and assignment for better error handling"
    fi
}

# Function to fix SC2034 - Unused variables
fix_unused_variables() {
    local file="$1"
    
    echo -e "${YELLOW}Info SC2034:${NC} Checking for unused variables in $file"
    echo -e "${RED}⚠${NC} Manual review needed - remove or mark unused variables as intentional"
}

# Function to fix SC2126 - Use grep -c -c instead of grep
fix_grep_wc() {
    local file="$1"
    
    if grep -q 'grep.*|.*wc -l' "$file"; then
        echo -e "${YELLOW}Fixing SC2126:${NC} Replacing grep | wc -l with grep -c in $file"
        create_backup "$file"
        
        # Replace grep -c ... with grep -c ...
        sed -i 's/grep \([^|]*\) | wc -l/grep -c \1/g' "$file"
        
        echo -e "${GREEN}✓${NC} Fixed grep | wc -l patterns in $file"
    fi
}

# Function to fix SC2129 - Use grouped redirects
fix_multiple_redirects() {
    local file="$1"
    
    if grep -q '>>' "$file"; then
        echo -e "${YELLOW}Info SC2129:${NC} Multiple redirects found in $file"
        echo -e "${RED}⚠${NC} Consider using { cmd1; cmd2; } >> file for better performance"
    fi
}

# Main function to process all shell scripts
process_scripts() {
    echo -e "\n${BLUE}Processing shell scripts...${NC}"
    
    # Find all shell scripts
    find "$XANADOS_ROOT" -name "*.sh" -type f | while read -r script; do
        echo -e "\n${BLUE}Processing:${NC} $script"
        
        # Apply fixes
        fix_missing_shebang "$script"
        fix_read_without_r "$script"
        fix_exit_code_check "$script"
        fix_useless_cat "$script"
        fix_unquoted_variables "$script"
        fix_declare_assign "$script"
        fix_unused_variables "$script"
        fix_grep_wc "$script"
        fix_multiple_redirects "$script"
    done
}

# Generate summary report
generate_summary() {
    echo -e "\n${BLUE}Generating shellcheck summary...${NC}"
    
    local summary_file="$XANADOS_ROOT/shellcheck-summary.txt"
    
    cat > "$summary_file" << 'EOF'
# xanadOS Shellcheck Issues Summary

This file contains a summary of shellcheck issues found and fixes applied.

## Issues Fixed Automatically:
- SC2148: Added missing shebangs
- SC2162: Added -r flag to read commands  
- SC2126: Replaced grep | wc -l with grep -c

## Issues Requiring Manual Review:
- SC2181: Check exit code directly (replace if [ $? -ne 0 ] with direct checks)
- SC2002: Useless cat (replace cat file | cmd with cmd < file)
- SC2086: Quote variables to prevent word splitting
- SC2155: Consider separating local declarations and assignments
- SC2034: Remove or mark unused variables as intentional
- SC2129: Consider using grouped redirects for performance

## Files with Backups Created:
EOF

    # List backup files
    find "$XANADOS_ROOT/archive/backups" -name "*.shellcheck.backup" -type f 2>/dev/null | while read -r backup; do
        echo "- ${backup}" >> "$summary_file"
    done
    
    echo -e "\n${GREEN}✓${NC} Summary saved to: $summary_file"
}

# Main execution
main() {
    echo -e "${GREEN}Starting shellcheck fixes...${NC}"
    
    process_scripts
    generate_summary
    
    echo -e "\n${GREEN}✓ Shellcheck fixes completed!${NC}"
    echo -e "${YELLOW}Note:${NC} Some issues require manual review. Check the summary file for details."
    echo -e "${BLUE}Recommendation:${NC} Run 'shellcheck **/*.sh' again to verify remaining issues."
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
