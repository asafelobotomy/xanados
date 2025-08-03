#!/bin/bash
#
# xanadOS Report Integration Example
# Shows how to integrate the new report generation system with existing scripts
#

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/directories.sh" 
source "$ROOT_DIR/lib/reports.sh"

print_header "xanadOS Report Integration Example"

# Example 1: Performance Benchmark with Report Generation
print_info "Example 1: Enhanced Performance Benchmark"

# Simulate running a performance benchmark
BENCHMARK_DATA_FILE="$(get_results_filename "benchmark" "performance_data")"
ensure_results_structure

# Create sample benchmark data
cat > "$BENCHMARK_DATA_FILE" << EOF
xanadOS Performance Benchmark Results
====================================
Timestamp: $(date -Iseconds)
System: $(uname -a)
Host: $(hostname 2>/dev/null || echo "unknown")

CPU Performance:
- Single-core score: 1247
- Multi-core score: 4892
- Gaming performance index: 95.3%

Memory Performance:
- Bandwidth: 23.4 GB/s
- Latency: 67.2 ns
- Gaming optimization: ENABLED

Graphics Performance:
- FPS (1080p): 87.3 avg
- Frame time: 11.5ms
- VSync compatibility: GOOD

Gaming Optimizations Applied:
- CPU governor: performance
- Scheduler: gaming-optimized
- I/O priority: real-time
- Memory prefetch: enabled

Overall Score: 92.7/100
Status: OPTIMAL FOR GAMING
EOF

print_success "Benchmark data generated: $BENCHMARK_DATA_FILE"

# Generate comprehensive reports
print_info "Generating performance reports in all formats..."
if generate_report "performance" "$BENCHMARK_DATA_FILE" "html,json,md"; then
    print_success "✓ Performance reports generated successfully"
    
    # Show where reports were saved
    RESULTS_DIR=$(get_results_dir false)
    print_info "Reports saved to: $RESULTS_DIR"
    
    # List generated files
    print_info "Generated report files:"
    find "$RESULTS_DIR" -name "performance_report_*" -type f | while read -r file; do
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        print_info "  $(basename "$file") (${size} bytes)"
    done
else
    print_error "✗ Report generation failed"
fi

# Example 2: Gaming Validation with Targeted Report
print_info "Example 2: Gaming Validation Report"

GAMING_DATA_FILE="$(get_results_filename "gaming" "validation_results")"

# Create gaming validation data
cat > "$GAMING_DATA_FILE" << EOF
xanadOS Gaming Validation Results
================================
Validation Run: $(date)
Profile: Gaming Optimized

Gaming Tools Status:
- Steam: INSTALLED AND OPTIMIZED
- Lutris: CONFIGURED
- GameMode: ACTIVE
- MangoHud: AVAILABLE

System Optimizations:
- CPU Frequency Scaling: performance
- GPU Power Management: maximum performance  
- Memory Overcommit: optimized for gaming
- I/O Scheduler: deadline (recommended for gaming)

Performance Validation:
- Game Launch Time: -23% improvement
- Frame Rate Stability: +15% improvement
- Input Latency: -8% improvement
- Loading Times: -31% improvement

Compatibility Tests:
- DirectX 11: PASSED
- DirectX 12: PASSED  
- Vulkan: PASSED
- OpenGL: PASSED

Overall Gaming Score: 94.2/100
Recommendation: EXCELLENT FOR GAMING
EOF

print_success "Gaming validation data generated: $GAMING_DATA_FILE"

# Generate focused gaming report (JSON only for integration)
print_info "Generating gaming validation report..."
if generate_report "gaming" "$GAMING_DATA_FILE" "json,md"; then
    print_success "✓ Gaming reports generated successfully"
else
    print_error "✗ Gaming report generation failed"
fi

# Example 3: System Summary Report
print_info "Example 3: System Summary Report Generation"

SUMMARY_DATA_FILE="$(get_results_filename "summary" "system_overview")"

# Create system summary
cat > "$SUMMARY_DATA_FILE" << EOF
xanadOS System Summary
=====================
Generated: $(date)
Version: xanadOS Gaming Edition v1.0

System Information:
- Kernel: $(uname -r)
- Architecture: $(uname -m)
- Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')

Gaming Readiness Score: 92.7/100

Quick Stats:
- Performance benchmarks: PASSED
- Gaming tools: CONFIGURED
- System optimizations: ACTIVE
- Compatibility: EXCELLENT

Recent Activity:
- Last benchmark: $(date)
- Last gaming session: Yesterday
- System health: OPTIMAL

Recommendations:
1. System is optimally configured for gaming
2. All performance targets met
3. No action required

Status: READY FOR GAMING
EOF

print_success "System summary data generated: $SUMMARY_DATA_FILE"

# Generate summary report with all formats for dashboard
print_info "Generating comprehensive system summary..."
if generate_report "summary" "$SUMMARY_DATA_FILE" "html,json,md"; then
    print_success "✓ System summary reports generated successfully"
else
    print_error "✗ Summary report generation failed"
fi

# Example 4: Show Integration with Existing Scripts
print_info "Example 4: Integration Pattern for Existing Scripts"

print_info "Integration pattern for performance-benchmark.sh:"
echo "
# At the end of your existing performance-benchmark.sh:
if command -v generate_report >/dev/null 2>&1; then
    print_info \"Generating performance report...\"
    generate_report \"performance\" \"\$LOG_FILE\" \"html,json\" \"\$RESULTS_DIR\"
fi
"

print_info "Integration pattern for gaming-validator.sh:"
echo "
# At the end of your existing gaming-validator.sh:
if command -v generate_report >/dev/null 2>&1; then
    print_info \"Generating gaming validation report...\"
    generate_report \"gaming\" \"\$VALIDATION_LOG\" \"json,md\" \"\$RESULTS_DIR\"
fi
"

# Show final summary
print_header "Integration Results Summary"

TOTAL_REPORTS=$(find "$(get_results_dir false)" -name "*_report_*" -type f | wc -l)
print_info "Total reports generated in this session: $TOTAL_REPORTS"

# Show the directory structure
RESULTS_DIR=$(get_results_dir false)
print_info "Report directory structure:"
ls -la "$RESULTS_DIR"/*_report_* 2>/dev/null | head -n 10

print_success "🎯 Task 3.2.2 Report Generation System - Integration examples completed!"
print_info "Next steps:"
print_info "1. Update existing testing scripts to include report generation"
print_info "2. Configure report archiving settings via XANADOS_MAX_REPORTS"
print_info "3. Set up automated report cleanup via XANADOS_ARCHIVE_DAYS"
print_info "4. Consider adding web dashboard to view HTML reports"

print_info "Available report functions:"
print_info "- generate_report <type> <data_file> [formats] [output_dir]"
print_info "- get_report_types, get_report_formats"
print_info "- is_valid_report_type, is_valid_report_format"
