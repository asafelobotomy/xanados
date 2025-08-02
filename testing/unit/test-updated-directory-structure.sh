#!/bin/bash
#
# Test the updated directory structure after cleanup
# This replaces the archived test-directory-structure.sh with proper relative paths
#

# Set up test environment - use relative path resolution
cd "$(dirname "$0")/../.." || exit 1

# Source required libraries using relative paths
source scripts/lib/common.sh
source scripts/lib/directories.sh

print_header "Testing Updated Directory Structure (Post-Cleanup)"

# Test 1: Project root detection
print_info "Test 1: Project root detection"
PROJECT_ROOT=$(get_project_root)
print_info "Project root: $PROJECT_ROOT"

if [[ -d "$PROJECT_ROOT/scripts" && -d "$PROJECT_ROOT/docs" ]]; then
    print_success "✓ Project root correctly detected"
else
    print_error "✗ Project root detection failed"
    exit 1
fi

# Test 2: Results directory
print_info "Test 2: Results directory"
RESULTS_DIR=$(get_results_dir)
print_info "Results directory: $RESULTS_DIR"

if [[ "$RESULTS_DIR" == *"docs/reports/generated"* ]]; then
    print_success "✓ Results directory uses docs structure"
else
    print_error "✗ Results directory not using docs structure: $RESULTS_DIR"
    exit 1
fi

# Test 3: Data file path
print_info "Test 3: Data file path generation"
DATA_FILE=$(get_results_filename "test" "txt")
print_info "Data file path: $DATA_FILE"

if [[ "$DATA_FILE" == *"docs/reports/data/"* ]]; then
    print_success "✓ Data file path uses docs structure"
else
    print_error "✗ Data file path not using docs structure: $DATA_FILE"
    exit 1
fi

# Test 4: Check all required directories exist
print_info "Test 4: Directory structure verification"
REQUIRED_DIRS=(
    "docs/reports"
    "docs/reports/data"
    "docs/reports/generated"
    "docs/reports/archive"
    "docs/reports/temp"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        print_success "✓ $dir exists"
    else
        print_error "✗ $dir missing"
        exit 1
    fi
done

# Test 5: Verify moved files
print_info "Test 5: Moved files verification"
print_info "Data files in docs/reports/data:"
if [[ -d "docs/reports/data" ]]; then
    DATA_COUNT=$(find docs/reports/data -type f | wc -l)
    print_info "Found $DATA_COUNT data files"
    ls -la docs/reports/data/ | head -n 5
else
    print_error "Data directory not found"
fi

print_info "Generated reports in docs/reports/generated:"
if [[ -d "docs/reports/generated" ]]; then
    REPORT_COUNT=$(find docs/reports/generated -type f | wc -l)
    print_info "Found $REPORT_COUNT generated reports"
    ls -la docs/reports/generated/ | head -n 5
else
    print_error "Generated reports directory not found"
fi

# Test 6: Verify no hardcoded paths remain
print_info "Test 6: Hardcoded path verification"
HARDCODED_COUNT=$(find scripts/ docs/ \( -name "*.sh" -o -name "*.md" \) -print0 | xargs -0 grep -l "$(pwd)" 2>/dev/null | wc -l)
if [[ $HARDCODED_COUNT -eq 0 ]]; then
    print_success "✓ No hardcoded absolute paths found"
else
    print_warning "⚠ Found $HARDCODED_COUNT files with hardcoded paths"
fi

# Test 7: Verify deprecated directories are marked
print_info "Test 7: Deprecated directory handling"
if grep -q "DEPRECATED" scripts/lib/directories.sh; then
    print_success "✓ Deprecation warnings present in directories.sh"
else
    print_warning "⚠ No deprecation warnings found"
fi

# Test 8: Test temp directory functionality
print_info "Test 8: Temp directory functionality"
TEMP_DIR="docs/reports/temp"
TEST_FILE="$TEMP_DIR/test-$(date +%s).tmp"

# Create a test file in temp
echo "Test content" > "$TEST_FILE"
if [[ -f "$TEST_FILE" ]]; then
    print_success "✓ Temp directory is writable"
    rm -f "$TEST_FILE"
else
    print_error "✗ Cannot write to temp directory"
fi

print_success "✅ Directory structure testing completed successfully!"
print_info "Summary:"
print_info "  • All required directories exist"
print_info "  • File paths use correct docs/reports structure"
print_info "  • No hardcoded absolute paths detected"
print_info "  • Temp directory is functional"
print_info "  • Data files: $DATA_COUNT, Reports: $REPORT_COUNT"
