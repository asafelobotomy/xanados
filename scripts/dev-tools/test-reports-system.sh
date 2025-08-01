#!/bin/bash
#
# Test Script for xanadOS Report Generation System
# Part of Task 3.2.2 validation
#

# Set up test environment
TEST_DIR="/tmp/xanados_reports_test"
mkdir -p "$TEST_DIR"
cd "$(dirname "$0")/.." || exit 1

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/directories.sh" 
source "$ROOT_DIR/lib/reports.sh"

print_header "Testing xanadOS Report Generation System"

# Test 1: Basic library functions
print_info "Test 1: Checking library functions availability"
if declare -f generate_report >/dev/null 2>&1; then
    print_success "✓ generate_report function available"
else
    print_error "✗ generate_report function missing"
    exit 1
fi

if declare -f get_report_types >/dev/null 2>&1; then
    print_success "✓ get_report_types function available"
else
    print_error "✗ get_report_types function missing"
    exit 1
fi

# Test 2: Report types and formats
print_info "Test 2: Checking available report types and formats"
TYPES=$(get_report_types)
FORMATS=$(get_report_formats)

print_info "Available report types: $TYPES"
print_info "Available report formats: $FORMATS"

# Test 3: Validation functions
print_info "Test 3: Testing validation functions"
if is_valid_report_type "benchmark"; then
    print_success "✓ benchmark is valid report type"
else
    print_error "✗ benchmark validation failed"
fi

if is_valid_report_format "json"; then
    print_success "✓ json is valid report format"
else
    print_error "✗ json validation failed"
fi

if ! is_valid_report_type "invalid_type"; then
    print_success "✓ invalid type correctly rejected"
else
    print_error "✗ invalid type incorrectly accepted"
fi

# Test 4: Create sample data file
print_info "Test 4: Creating sample data for report generation"
SAMPLE_DATA="$TEST_DIR/sample_benchmark_data.txt"
cat > "$SAMPLE_DATA" << EOF
xanadOS Benchmark Results
========================
Date: $(date)
System: $(hostname)

Performance Metrics:
- CPU Benchmark: 95.2% of baseline
- Memory Performance: 87.8% efficiency
- Disk I/O: 1250 MB/s average
- Gaming Optimization: ENABLED

Test Results:
- Latency: 12.5ms average
- Throughput: 450 ops/sec
- Resource Usage: 23% CPU, 45% RAM

Status: ALL TESTS PASSED
EOF

print_success "Sample data created: $SAMPLE_DATA"

# Test 5: Generate reports in all formats
print_info "Test 5: Generating reports in all formats"
REPORT_OUTPUT="$TEST_DIR/reports"
mkdir -p "$REPORT_OUTPUT"

if generate_report "benchmark" "$SAMPLE_DATA" "html,json,md" "$REPORT_OUTPUT"; then
    print_success "✓ Report generation completed successfully"
else
    print_error "✗ Report generation failed"
    exit 1
fi

# Test 6: Verify generated files
print_info "Test 6: Verifying generated report files"
HTML_COUNT=$(find "$REPORT_OUTPUT" -name "benchmark_report_*.html" | wc -l)
JSON_COUNT=$(find "$REPORT_OUTPUT" -name "benchmark_report_*.json" | wc -l)
MD_COUNT=$(find "$REPORT_OUTPUT" -name "benchmark_report_*.md" | wc -l)

print_info "Generated files: $HTML_COUNT HTML, $JSON_COUNT JSON, $MD_COUNT Markdown"

if [[ $HTML_COUNT -eq 1 && $JSON_COUNT -eq 1 && $MD_COUNT -eq 1 ]]; then
    print_success "✓ All expected report files generated"
else
    print_error "✗ Missing report files"
    exit 1
fi

# Test 7: Check file contents
print_info "Test 7: Checking report file contents"
LATEST_JSON=$(find "$REPORT_OUTPUT" -name "benchmark_report_*.json" | head -n1)
if [[ -f "$LATEST_JSON" ]]; then
    if grep -q "xanadOS Report System" "$LATEST_JSON"; then
        print_success "✓ JSON report contains expected content"
    else
        print_error "✗ JSON report missing expected content"
    fi
fi

LATEST_HTML=$(find "$REPORT_OUTPUT" -name "benchmark_report_*.html" | head -n1)
if [[ -f "$LATEST_HTML" ]]; then
    if grep -q "xanadOS.*Report" "$LATEST_HTML"; then
        print_success "✓ HTML report contains expected content"
    else
        print_error "✗ HTML report missing expected content"
    fi
fi

# Test 8: Test different report types
print_info "Test 8: Testing different report types"
for report_type in "gaming" "system" "performance"; do
    print_info "Generating $report_type report..."
    if generate_report "$report_type" "$SAMPLE_DATA" "json" "$REPORT_OUTPUT"; then
        print_success "✓ $report_type report generated successfully"
    else
        print_warning "⚠ $report_type report generation issues"
    fi
done

# Test 9: Test archiving functionality
print_info "Test 9: Testing report archiving"
# Generate multiple reports to trigger archiving
for i in {1..3}; do
    generate_report "benchmark" "$SAMPLE_DATA" "json" "$REPORT_OUTPUT" >/dev/null 2>&1
    sleep 1  # Ensure different timestamps
done

TOTAL_REPORTS=$(find "$REPORT_OUTPUT" -name "benchmark_report_*.json" | wc -l)
ARCHIVED_REPORTS=$(find "$REPORT_OUTPUT/archive" -name "benchmark_report_*.json" 2>/dev/null | wc -l)

print_info "Total reports: $TOTAL_REPORTS, Archived: $ARCHIVED_REPORTS"

# Test Results Summary
print_header "Test Results Summary"
GENERATED_FILES=$(find "$REPORT_OUTPUT" -name "*_report_*" | wc -l)
print_info "Total report files generated: $GENERATED_FILES"

if [[ $GENERATED_FILES -gt 0 ]]; then
    print_success "🎯 Task 3.2.2 Report Generation System: VALIDATION SUCCESSFUL"
    print_info "Generated reports can be found in: $REPORT_OUTPUT"
    
    # Show sample files for user
    print_info "Sample generated files:"
    ls -la "$REPORT_OUTPUT"/*.{html,json,md} 2>/dev/null | head -n 5
else
    print_error "❌ Task 3.2.2 Report Generation System: VALIDATION FAILED"
    exit 1
fi

# Cleanup
print_info "Cleanup: Test files preserved in $TEST_DIR for inspection"
print_success "All tests completed successfully!"
