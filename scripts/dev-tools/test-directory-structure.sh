#!/bin/bash
#
# Test the updated directory structure
#

# Set up test environment
cd "$(dirname "$0")/.." || exit 1

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/directories.sh"

print_header "Testing Updated Directory Structure"

# Test 1: Project root detection
print_info "Test 1: Project root detection"
PROJECT_ROOT=$(get_project_root)
print_info "Project root: $PROJECT_ROOT"

if [[ -d "$PROJECT_ROOT/scripts" && -d "$PROJECT_ROOT/docs" ]]; then
    print_success "✓ Project root correctly detected"
else
    print_error "✗ Project root detection failed"
fi

# Test 2: Results directory
print_info "Test 2: Results directory"
RESULTS_DIR=$(get_results_dir)
print_info "Results directory: $RESULTS_DIR"

if [[ "$RESULTS_DIR" == *"docs/reports/generated"* ]]; then
    print_success "✓ Results directory uses docs structure"
else
    print_error "✗ Results directory not using docs structure: $RESULTS_DIR"
fi

# Test 3: Data file path
print_info "Test 3: Data file path generation"
DATA_FILE=$(get_results_filename "test" "txt")
print_info "Data file path: $DATA_FILE"

if [[ "$DATA_FILE" == *"docs/reports/data/"* ]]; then
    print_success "✓ Data file path uses docs structure"
else
    print_error "✗ Data file path not using docs structure: $DATA_FILE"
fi

# Test 4: Check directory existence
print_info "Test 4: Directory structure verification"
print_info "Checking docs/reports structure:"
ls -la docs/reports/

# Test 5: Verify moved files
print_info "Test 5: Moved files verification"
print_info "Data files in docs/reports/data:"
ls -la docs/reports/data/ | head -n 5

print_info "Generated reports in docs/reports/generated:"
ls -la docs/reports/generated/ | head -n 5

print_success "Directory structure testing completed!"
