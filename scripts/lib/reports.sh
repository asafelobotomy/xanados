#!/bin/bash
#
# xanadOS - Report Generation Library
# Part of Task 3.2.2: Report Generation System
#
# This library provides unified reporting infrastructure with support for
# HTML, JSON, and markdown formats, including templates and archiving.
#
# Dependencies: common.sh, directories.sh
#

# Source dependencies if not already loaded
if ! declare -f print_info >/dev/null 2>&1; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

if ! declare -f get_results_dir >/dev/null 2>&1; then
    source "$(dirname "${BASH_SOURCE[0]}")/directories.sh"
fi

# ============================================================================
# REPORT FORMAT CONSTANTS
# ============================================================================

readonly REPORT_FORMAT_HTML="html"
readonly REPORT_FORMAT_JSON="json" 
readonly REPORT_FORMAT_MARKDOWN="md"

# Default report formats if none specified
readonly DEFAULT_REPORT_FORMATS=("$REPORT_FORMAT_JSON" "$REPORT_FORMAT_MARKDOWN")

# ============================================================================
# REPORT TYPE CONSTANTS
# ============================================================================

readonly REPORT_TYPE_BENCHMARK="benchmark"
readonly REPORT_TYPE_GAMING="gaming"
readonly REPORT_TYPE_SYSTEM="system"
readonly REPORT_TYPE_PERFORMANCE="performance"
readonly REPORT_TYPE_SUMMARY="summary"

# ============================================================================
# REPORT GENERATION CORE FUNCTIONS
# ============================================================================

#
# Generate a unified report in specified format(s)
#
# Usage: generate_report <report_type> <data_file> [format1,format2,...] [output_dir]
#
# Parameters:
#   report_type: Type of report (benchmark, gaming, system, performance, summary)
#   data_file: Path to data file containing report content
#   formats: Comma-separated list of formats (html,json,md) - optional
#   output_dir: Output directory - optional, uses get_results_dir if not specified
#
# Returns: 0 on success, 1 on error
#
generate_report() {
    local report_type="$1"
    local data_file="$2"
    local formats="${3:-$(IFS=','; echo "${DEFAULT_REPORT_FORMATS[*]}")}"
    local output_dir="$4"
    
    # Validation
    if [[ -z "$report_type" || -z "$data_file" ]]; then
        print_error "Usage: generate_report <report_type> <data_file> [formats] [output_dir]"
        return 1
    fi
    
    if [[ ! -f "$data_file" ]]; then
        print_error "Data file not found: $data_file"
        return 1
    fi
    
    # Set default output directory if not provided
    if [[ -z "$output_dir" ]]; then
        output_dir="$(get_results_dir false)"
        if [[ $? -ne 0 ]]; then
            print_error "Failed to get default output directory"
            return 1
        fi
    fi
    
    # Ensure output directory exists
    ensure_directory "$output_dir"
    
    print_info "Generating $report_type report from: $data_file"
    print_info "Output directory: $output_dir"
    print_info "Formats: $formats"
    
    # Parse formats and generate each one
    local format_array
    IFS=',' read -ra format_array <<< "$formats"
    
    local success_count=0
    local total_count=${#format_array[@]}
    
    for format in "${format_array[@]}"; do
        format=$(echo "$format" | tr -d ' ') # Remove whitespace
        
        case "$format" in
            "$REPORT_FORMAT_HTML")
                if _generate_html_report "$report_type" "$data_file" "$output_dir"; then
                    ((success_count++))
                fi
                ;;
            "$REPORT_FORMAT_JSON")
                if _generate_json_report "$report_type" "$data_file" "$output_dir"; then
                    ((success_count++))
                fi
                ;;
            "$REPORT_FORMAT_MARKDOWN")
                if _generate_markdown_report "$report_type" "$data_file" "$output_dir"; then
                    ((success_count++))
                fi
                ;;
            *)
                print_warning "Unknown report format: $format"
                ;;
        esac
    done
    
    print_info "Report generation complete: $success_count/$total_count formats successful"
    
    # Archive reports if configured
    _archive_reports "$report_type" "$output_dir"
    
    if [[ $success_count -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# FORMAT-SPECIFIC GENERATION FUNCTIONS
# ============================================================================

#
# Generate HTML report
#
_generate_html_report() {
    local report_type="$1"
    local data_file="$2"
    local output_dir="$3"
    
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local output_file="$output_dir/${report_type}_report_${timestamp}.html"
    
    print_info "Generating HTML report: $output_file"
    
    # Generate HTML content and capture result
    local html_result=0
    {
        _generate_html_header "$report_type"
        _generate_html_body "$report_type" "$data_file"
        _generate_html_footer
    } > "$output_file" || html_result=$?
    
    if [[ $html_result -eq 0 ]]; then
        print_success "HTML report generated: $output_file"
        return 0
    else
        print_error "Failed to generate HTML report"
        return 1
    fi
}

#
# Generate JSON report
#
_generate_json_report() {
    local report_type="$1"
    local data_file="$2"
    local output_dir="$3"
    
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local output_file="$output_dir/${report_type}_report_${timestamp}.json"
    
    print_info "Generating JSON report: $output_file"
    
    # Generate JSON content 
    if {
        echo "{"
        echo "  \"report\": {"
        echo "    \"type\": \"$report_type\","
        echo "    \"timestamp\": \"$(date -Iseconds)\","
        echo "    \"generated_by\": \"xanadOS Report System\","
        echo "    \"version\": \"1.0\","
        _generate_json_content "$report_type" "$data_file"
        echo "  }"
        echo "}"
    } > "$output_file"; then
        print_success "JSON report generated: $output_file"
        return 0
    else
        print_error "Failed to generate JSON report"
        return 1
    fi
}

#
# Generate Markdown report
#
_generate_markdown_report() {
    local report_type="$1"
    local data_file="$2"
    local output_dir="$3"
    
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local output_file="$output_dir/${report_type}_report_${timestamp}.md"
    
    print_info "Generating Markdown report: $output_file"
    
    # Generate Markdown content
    {
        _generate_markdown_header "$report_type"
        _generate_markdown_body "$report_type" "$data_file"
        _generate_markdown_footer
    } > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        print_success "Markdown report generated: $output_file"
        return 0
    else
        print_error "Failed to generate Markdown report"
        return 1
    fi
}

# ============================================================================
# HTML TEMPLATE FUNCTIONS
# ============================================================================

_generate_html_header() {
    local report_type="$1"
    local title
    title="xanadOS $(echo "$report_type" | sed 's/.*/\u&/') Report"
    
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { border-bottom: 3px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #007acc; margin: 0; font-size: 2.5em; }
        .header .meta { color: #666; font-size: 0.9em; margin-top: 10px; }
        .section { margin: 30px 0; }
        .section h2 { color: #333; border-left: 4px solid #007acc; padding-left: 15px; }
        .metric { background: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #28a745; }
        .metric .label { font-weight: bold; color: #333; }
        .metric .value { color: #007acc; font-family: monospace; }
        .warning { border-left-color: #ffc107; background: #fff3cd; }
        .error { border-left-color: #dc3545; background: #f8d7da; }
        .success { border-left-color: #28a745; background: #d4edda; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #007acc; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .footer { margin-top: 50px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 0.8em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$title</h1>
            <div class="meta">
                Generated: $(date '+%Y-%m-%d %H:%M:%S')<br>
                System: $(hostname)<br>
                xanadOS Report System v1.0
            </div>
        </div>
EOF
}

_generate_html_body() {
    local report_type="$1"
    local data_file="$2"
    
    echo '        <div class="section">'
    echo '            <h2>Report Data</h2>'
    
    case "$report_type" in
        "$REPORT_TYPE_BENCHMARK"|"$REPORT_TYPE_PERFORMANCE")
            _generate_html_performance_content "$data_file"
            ;;
        "$REPORT_TYPE_GAMING")
            _generate_html_gaming_content "$data_file"
            ;;
        "$REPORT_TYPE_SYSTEM")
            _generate_html_system_content "$data_file"
            ;;
        *)
            _generate_html_generic_content "$data_file"
            ;;
    esac
    
    echo '        </div>'
}

_generate_html_footer() {
    cat << EOF
        <div class="footer">
            <p>This report was generated by the xanadOS Report Generation System.</p>
            <p>For more information, visit the xanadOS documentation.</p>
        </div>
    </div>
</body>
</html>
EOF
}

# ============================================================================
# JSON TEMPLATE FUNCTIONS
# ============================================================================

_generate_json_content() {
    local report_type="$1"
    local data_file="$2"
    
    echo "    \"data\": {"
    
    case "$report_type" in
        "$REPORT_TYPE_BENCHMARK"|"$REPORT_TYPE_PERFORMANCE")
            _generate_json_performance_content "$data_file"
            ;;
        "$REPORT_TYPE_GAMING")
            _generate_json_gaming_content "$data_file"
            ;;
        "$REPORT_TYPE_SYSTEM")
            _generate_json_system_content "$data_file"
            ;;
        *)
            _generate_json_generic_content "$data_file"
            ;;
    esac
    
    echo "    }"
}

# ============================================================================
# MARKDOWN TEMPLATE FUNCTIONS
# ============================================================================

_generate_markdown_header() {
    local report_type="$1"
    local title
    title="xanadOS $(echo "$report_type" | sed 's/.*/\u&/') Report"
    
    cat << EOF
# $title

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**System:** $(hostname)  
**xanadOS Report System:** v1.0

---

EOF
}

_generate_markdown_body() {
    local report_type="$1"
    local data_file="$2"
    
    echo "## Report Data"
    echo ""
    
    case "$report_type" in
        "$REPORT_TYPE_BENCHMARK"|"$REPORT_TYPE_PERFORMANCE")
            _generate_markdown_performance_content "$data_file"
            ;;
        "$REPORT_TYPE_GAMING")
            _generate_markdown_gaming_content "$data_file"
            ;;
        "$REPORT_TYPE_SYSTEM")
            _generate_markdown_system_content "$data_file"
            ;;
        *)
            _generate_markdown_generic_content "$data_file"
            ;;
    esac
}

_generate_markdown_footer() {
    cat << EOF

---

*This report was generated by the xanadOS Report Generation System.*  
*For more information, visit the xanadOS documentation.*
EOF
}

# ============================================================================
# CONTENT GENERATION HELPERS
# ============================================================================

# Generic content generators that work with any data file
_generate_html_generic_content() {
    local data_file="$1"
    
    echo '            <div class="metric">'
    echo '                <div class="label">Source Data File:</div>'
    echo "                <div class=\"value\">$data_file</div>"
    echo '            </div>'
    echo '            <div class="metric">'
    echo '                <div class="label">Raw Content:</div>'
    echo '                <pre style="background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto;">'
    
    if [[ -r "$data_file" ]]; then
        cat "$data_file" | head -n 50 # Limit to first 50 lines for HTML
    else
        echo "Unable to read data file: $data_file"
    fi
    
    echo '                </pre>'
    echo '            </div>'
}

_generate_json_generic_content() {
    local data_file="$1"
    
    echo "      \"source_file\": \"$data_file\","
    echo "      \"content\": ["
    
    if [[ -r "$data_file" ]]; then
        local line_count=0
        while IFS= read -r line && [[ $line_count -lt 50 ]]; do
            # Escape JSON special characters
            local escaped_line
            escaped_line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
            if [[ $line_count -gt 0 ]]; then
                echo ","
            fi
            echo -n "        \"$escaped_line\""
            ((line_count++))
        done < "$data_file"
        echo ""
    else
        echo "        \"Unable to read data file: $data_file\""
    fi
    
    echo "      ]"
}

_generate_markdown_generic_content() {
    local data_file="$1"
    
    echo "**Source Data File:** \`$data_file\`"
    echo ""
    echo "### Raw Content"
    echo ""
    echo '```'
    
    if [[ -r "$data_file" ]]; then
        cat "$data_file" | head -n 50 # Limit to first 50 lines
    else
        echo "Unable to read data file: $data_file"
    fi
    
    echo '```'
    echo ""
}

# Performance-specific content generators
_generate_html_performance_content() {
    local data_file="$1"
    _generate_html_generic_content "$data_file"
    # TODO: Add performance-specific parsing and formatting
}

_generate_json_performance_content() {
    local data_file="$1"
    _generate_json_generic_content "$data_file"
    # TODO: Add performance-specific parsing and formatting
}

_generate_markdown_performance_content() {
    local data_file="$1"
    _generate_markdown_generic_content "$data_file"
    # TODO: Add performance-specific parsing and formatting
}

# Gaming-specific content generators
_generate_html_gaming_content() {
    local data_file="$1"
    _generate_html_generic_content "$data_file"
    # TODO: Add gaming-specific parsing and formatting
}

_generate_json_gaming_content() {
    local data_file="$1"
    _generate_json_generic_content "$data_file"
    # TODO: Add gaming-specific parsing and formatting
}

_generate_markdown_gaming_content() {
    local data_file="$1"
    _generate_markdown_generic_content "$data_file"
    # TODO: Add gaming-specific parsing and formatting
}

# System-specific content generators
_generate_html_system_content() {
    local data_file="$1"
    _generate_html_generic_content "$data_file"
    # TODO: Add system-specific parsing and formatting
}

_generate_json_system_content() {
    local data_file="$1"
    _generate_json_generic_content "$data_file"
    # TODO: Add system-specific parsing and formatting
}

_generate_markdown_system_content() {
    local data_file="$1"
    _generate_markdown_generic_content "$data_file"
    # TODO: Add system-specific parsing and formatting
}

# ============================================================================
# REPORT ARCHIVING AND CLEANUP
# ============================================================================

#
# Archive old reports and clean up based on configuration
#
_archive_reports() {
    local report_type="$1"
    local output_dir="$2"
    
    # Get archiving configuration (defaults)
    local max_reports=${XANADOS_MAX_REPORTS:-10}
    # Note: archive_older_than_days reserved for future use
    # local archive_older_than_days=${XANADOS_ARCHIVE_DAYS:-7}
    
    print_info "Checking for old reports to archive (keeping $max_reports recent reports)"
    
    # Find and count reports of this type
    local report_files=()
    while IFS= read -r -d '' file; do
        report_files+=("$file")
    done < <(find "$output_dir" -name "${report_type}_report_*" -type f -print0 | sort -z)
    
    local total_reports=${#report_files[@]}
    
    if [[ $total_reports -gt $max_reports ]]; then
        local reports_to_archive=$((total_reports - max_reports))
        print_info "Found $total_reports reports, archiving oldest $reports_to_archive"
        
        # Archive the oldest reports
        for ((i=0; i<reports_to_archive; i++)); do
            local file_to_archive="${report_files[$i]}"
            local archive_dir="$output_dir/archive"
            
            ensure_directory "$archive_dir"
            
            if mv "$file_to_archive" "$archive_dir/"; then
                print_info "Archived: $(basename "$file_to_archive")"
            else
                print_warning "Failed to archive: $file_to_archive"
            fi
        done
    else
        print_info "Report count ($total_reports) within limits, no archiving needed"
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

#
# Get available report types
#
get_report_types() {
    echo "$REPORT_TYPE_BENCHMARK $REPORT_TYPE_GAMING $REPORT_TYPE_SYSTEM $REPORT_TYPE_PERFORMANCE $REPORT_TYPE_SUMMARY"
}

#
# Get available report formats
#
get_report_formats() {
    echo "$REPORT_FORMAT_HTML $REPORT_FORMAT_JSON $REPORT_FORMAT_MARKDOWN"
}

#
# Validate report type
#
is_valid_report_type() {
    local report_type="$1"
    local valid_types
    valid_types=$(get_report_types)
    
    [[ " $valid_types " =~ \ $report_type\  ]]
}

#
# Validate report format
#
is_valid_report_format() {
    local format="$1"
    local valid_formats
    valid_formats=$(get_report_formats)
    
    [[ " $valid_formats " =~ \ $format\  ]]
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Export main functions for use by other scripts
export -f generate_report
export -f get_report_types
export -f get_report_formats
export -f is_valid_report_type
export -f is_valid_report_format
