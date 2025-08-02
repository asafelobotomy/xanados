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
        output_dir="$(get_results_dir "general" false)"
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
    
    echo "<div class=\"performance-metrics\">"
    echo "<h3>Performance Metrics Overview</h3>"
    
    # Parse CPU, memory, and I/O metrics from data file
    if [[ -f "$data_file" ]]; then
        echo "<div class=\"metrics-grid\">"
        
        # CPU Metrics
        echo "<div class=\"metric-card\">"
        echo "<h4>CPU Performance</h4>"
        if grep -q "CPU\|cpu\|processor" "$data_file"; then
            grep -i "cpu\|processor\|cores\|frequency" "$data_file" | head -5 | while read -r line; do
                echo "<p>$line</p>"
            done
        else
            echo "<p>No CPU metrics found</p>"
        fi
        echo "</div>"
        
        # Memory Metrics
        echo "<div class=\"metric-card\">"
        echo "<h4>Memory Performance</h4>"
        if grep -q -i "memory\|ram\|mem" "$data_file"; then
            grep -i "memory\|ram\|mem\|swap" "$data_file" | head -5 | while read -r line; do
                echo "<p>$line</p>"
            done
        else
            echo "<p>No memory metrics found</p>"
        fi
        echo "</div>"
        
        # I/O Metrics
        echo "<div class=\"metric-card\">"
        echo "<h4>I/O Performance</h4>"
        if grep -q -i "disk\|i/o\|read\|write\|iops" "$data_file"; then
            grep -i "disk\|i/o\|read\|write\|iops\|throughput" "$data_file" | head -5 | while read -r line; do
                echo "<p>$line</p>"
            done
        else
            echo "<p>No I/O metrics found</p>"
        fi
        echo "</div>"
        
        echo "</div>"
    fi
    
    echo "</div>"
    echo "<hr>"
    
    # Include generic content for the rest
    _generate_html_generic_content "$data_file"
}

_generate_json_performance_content() {
    local data_file="$1"
    
    # Create performance-specific JSON structure
    local temp_json
    temp_json=$(mktemp)
    cat > "$temp_json" << 'EOF'
{
    "performance_metrics": {
        "cpu": [],
        "memory": [],
        "io": [],
        "summary": {}
    },
    "raw_data": []
}
EOF
    
    if [[ -f "$data_file" ]]; then
        # Parse performance data and add to JSON
        local cpu_data=""
        local memory_data=""
        local io_data=""
        
        while IFS= read -r line; do
            # Categorize performance data
            if echo "$line" | grep -q -i "cpu\|processor\|cores\|frequency"; then
                cpu_data="${cpu_data}\"${line}\","
            elif echo "$line" | grep -q -i "memory\|ram\|mem\|swap"; then
                memory_data="${memory_data}\"${line}\","
            elif echo "$line" | grep -q -i "disk\|i/o\|read\|write\|iops"; then
                io_data="${io_data}\"${line}\","
            fi
        done < "$data_file"
        
        # Remove trailing commas and update JSON
        cpu_data=${cpu_data%,}
        memory_data=${memory_data%,}
        io_data=${io_data%,}
        
        # Update temp JSON with performance data
        jq --argjson cpu "[$cpu_data]" \
           --argjson mem "[$memory_data]" \
           --argjson io "[$io_data]" \
           '.performance_metrics.cpu = $cpu | .performance_metrics.memory = $mem | .performance_metrics.io = $io' \
           "$temp_json" > "${temp_json}.new" && mv "${temp_json}.new" "$temp_json"
    fi
    
    # Output the JSON content
    cat "$temp_json"
    rm -f "$temp_json"
}

_generate_markdown_performance_content() {
    local data_file="$1"
    
    echo "## Performance Metrics Overview"
    echo ""
    
    if [[ -f "$data_file" ]]; then
        echo "### CPU Performance"
        if grep -q -i "cpu\|processor\|cores" "$data_file"; then
            grep -i "cpu\|processor\|cores\|frequency" "$data_file" | head -5 | sed 's/^/- /'
        else
            echo "- No CPU metrics found"
        fi
        echo ""
        
        echo "### Memory Performance"
        if grep -q -i "memory\|ram\|mem" "$data_file"; then
            grep -i "memory\|ram\|mem\|swap" "$data_file" | head -5 | sed 's/^/- /'
        else
            echo "- No memory metrics found"
        fi
        echo ""
        
        echo "### I/O Performance"
        if grep -q -i "disk\|i/o\|read\|write" "$data_file"; then
            grep -i "disk\|i/o\|read\|write\|iops\|throughput" "$data_file" | head -5 | sed 's/^/- /'
        else
            echo "- No I/O metrics found"
        fi
        echo ""
    fi
    
    echo "---"
    echo ""
    
    # Include generic content
    _generate_markdown_generic_content "$data_file"
}

# Gaming-specific content generators
_generate_html_gaming_content() {
    local data_file="$1"
    
    echo "<div class=\"gaming-environment\">"
    echo "<h3>Gaming Environment Analysis</h3>"
    
    if [[ -f "$data_file" ]]; then
        echo "<div class=\"gaming-grid\">"
        
        # Gaming Platforms
        echo "<div class=\"gaming-card\">"
        echo "<h4>Gaming Platforms</h4>"
        if grep -q -i "steam\|lutris\|heroic\|bottles" "$data_file"; then
            grep -i "steam\|lutris\|heroic\|bottles\|epic\|gog" "$data_file" | while read -r line; do
                echo "<p class=\"platform-status\">$line</p>"
            done
        else
            echo "<p>No gaming platforms detected</p>"
        fi
        echo "</div>"
        
        # Performance Tools
        echo "<div class=\"gaming-card\">"
        echo "<h4>Performance Tools</h4>"
        if grep -q -i "gamemode\|mangohud\|goverlay" "$data_file"; then
            grep -i "gamemode\|mangohud\|goverlay\|performance" "$data_file" | while read -r line; do
                echo "<p class=\"tool-status\">$line</p>"
            done
        else
            echo "<p>No performance tools detected</p>"
        fi
        echo "</div>"
        
        # Graphics & Drivers
        echo "<div class=\"gaming-card\">"
        echo "<h4>Graphics & Drivers</h4>"
        if grep -q -i "vulkan\|opengl\|nvidia\|amd" "$data_file"; then
            grep -i "vulkan\|opengl\|nvidia\|amd\|mesa\|driver" "$data_file" | head -5 | while read -r line; do
                echo "<p class=\"graphics-info\">$line</p>"
            done
        else
            echo "<p>No graphics information found</p>"
        fi
        echo "</div>"
        
        # Wine & Compatibility
        echo "<div class=\"gaming-card\">"
        echo "<h4>Wine & Compatibility</h4>"
        if grep -q -i "wine\|proton\|dxvk\|winetricks" "$data_file"; then
            grep -i "wine\|proton\|dxvk\|winetricks\|compatibility" "$data_file" | while read -r line; do
                echo "<p class=\"compat-info\">$line</p>"
            done
        else
            echo "<p>No compatibility layer information found</p>"
        fi
        echo "</div>"
        
        echo "</div>"
    fi
    
    echo "</div>"
    echo "<hr>"
    
    # Include generic content
    _generate_html_generic_content "$data_file"
}

_generate_json_gaming_content() {
    local data_file="$1"
    
    # Create gaming-specific JSON structure
    local temp_json
    temp_json=$(mktemp)
    cat > "$temp_json" << 'EOF'
{
    "gaming_environment": {
        "platforms": [],
        "performance_tools": [],
        "graphics": [],
        "compatibility": [],
        "summary": {
            "total_platforms": 0,
            "total_tools": 0,
            "readiness_score": "unknown"
        }
    },
    "raw_data": []
}
EOF
    
    if [[ -f "$data_file" ]]; then
        # Parse gaming data
        local platforms=""
        local perf_tools=""
        local graphics=""
        local compat=""
        local platform_count=0
        local tool_count=0
        
        while IFS= read -r line; do
            if echo "$line" | grep -q -i "steam\|lutris\|heroic\|bottles\|epic\|gog"; then
                platforms="${platforms}\"${line}\","
                ((platform_count++))
            elif echo "$line" | grep -q -i "gamemode\|mangohud\|goverlay"; then
                perf_tools="${perf_tools}\"${line}\","
                ((tool_count++))
            elif echo "$line" | grep -q -i "vulkan\|opengl\|nvidia\|amd\|mesa\|driver"; then
                graphics="${graphics}\"${line}\","
            elif echo "$line" | grep -q -i "wine\|proton\|dxvk\|winetricks"; then
                compat="${compat}\"${line}\","
            fi
        done < "$data_file"
        
        # Remove trailing commas
        platforms=${platforms%,}
        perf_tools=${perf_tools%,}
        graphics=${graphics%,}
        compat=${compat%,}
        
        # Calculate readiness score
        local readiness="basic"
        if [[ $platform_count -ge 2 && $tool_count -ge 2 ]]; then
            readiness="excellent"
        elif [[ $platform_count -ge 1 && $tool_count -ge 1 ]]; then
            readiness="good"
        fi
        
        # Update JSON with gaming data
        jq --argjson platforms "[$platforms]" \
           --argjson tools "[$perf_tools]" \
           --argjson graphics "[$graphics]" \
           --argjson compat "[$compat]" \
           --arg count_p "$platform_count" \
           --arg count_t "$tool_count" \
           --arg readiness "$readiness" \
           '.gaming_environment.platforms = $platforms | 
            .gaming_environment.performance_tools = $tools | 
            .gaming_environment.graphics = $graphics | 
            .gaming_environment.compatibility = $compat |
            .gaming_environment.summary.total_platforms = ($count_p | tonumber) |
            .gaming_environment.summary.total_tools = ($count_t | tonumber) |
            .gaming_environment.summary.readiness_score = $readiness' \
           "$temp_json" > "${temp_json}.new" && mv "${temp_json}.new" "$temp_json"
    fi
    
    # Output the JSON content
    cat "$temp_json"
    rm -f "$temp_json"
}

_generate_markdown_gaming_content() {
    local data_file="$1"
    
    echo "## Gaming Environment Analysis"
    echo ""
    
    if [[ -f "$data_file" ]]; then
        echo "### 🎮 Gaming Platforms"
        if grep -q -i "steam\|lutris\|heroic\|bottles" "$data_file"; then
            grep -i "steam\|lutris\|heroic\|bottles\|epic\|gog" "$data_file" | sed 's/^/- /'
        else
            echo "- No gaming platforms detected"
        fi
        echo ""
        
        echo "### ⚡ Performance Tools"
        if grep -q -i "gamemode\|mangohud\|goverlay" "$data_file"; then
            grep -i "gamemode\|mangohud\|goverlay\|performance" "$data_file" | sed 's/^/- /'
        else
            echo "- No performance tools detected"
        fi
        echo ""
        
        echo "### 🖥️ Graphics & Drivers"
        if grep -q -i "vulkan\|opengl\|nvidia\|amd" "$data_file"; then
            grep -i "vulkan\|opengl\|nvidia\|amd\|mesa\|driver" "$data_file" | head -5 | sed 's/^/- /'
        else
            echo "- No graphics information found"
        fi
        echo ""
        
        echo "### 🍷 Wine & Compatibility"
        if grep -q -i "wine\|proton\|dxvk\|winetricks" "$data_file"; then
            grep -i "wine\|proton\|dxvk\|winetricks\|compatibility" "$data_file" | sed 's/^/- /'
        else
            echo "- No compatibility layer information found"
        fi
        echo ""
    fi
    
    echo "---"
    echo ""
    
    # Include generic content
    _generate_markdown_generic_content "$data_file"
}

# System-specific content generators
_generate_html_system_content() {
    local data_file="$1"
    
    echo "<div class=\"system-analysis\">"
    echo "<h3>System Analysis Overview</h3>"
    
    if [[ -f "$data_file" ]]; then
        echo "<div class=\"system-grid\">"
        
        # Hardware Information
        echo "<div class=\"system-card\">"
        echo "<h4>Hardware Information</h4>"
        if grep -q -i "cpu\|processor\|memory\|disk" "$data_file"; then
            echo "<div class=\"hardware-specs\">"
            grep -i "cpu\|processor\|memory\|ram\|disk\|storage" "$data_file" | head -8 | while read -r line; do
                echo "<p class=\"hw-spec\">$line</p>"
            done
            echo "</div>"
        else
            echo "<p>No hardware information found</p>"
        fi
        echo "</div>"
        
        # Operating System
        echo "<div class=\"system-card\">"
        echo "<h4>Operating System</h4>"
        if grep -q -i "kernel\|distro\|version\|release" "$data_file"; then
            grep -i "kernel\|distro\|version\|release\|ubuntu\|debian\|arch" "$data_file" | head -5 | while read -r line; do
                echo "<p class=\"os-info\">$line</p>"
            done
        else
            echo "<p>No OS information found</p>"
        fi
        echo "</div>"
        
        # Services & Processes
        echo "<div class=\"system-card\">"
        echo "<h4>System Services</h4>"
        if grep -q -i "service\|daemon\|process\|systemd" "$data_file"; then
            grep -i "service\|daemon\|process\|systemd\|active\|running" "$data_file" | head -6 | while read -r line; do
                echo "<p class=\"service-status\">$line</p>"
            done
        else
            echo "<p>No service information found</p>"
        fi
        echo "</div>"
        
        # Network & Security
        echo "<div class=\"system-card\">"
        echo "<h4>Network & Security</h4>"
        if grep -q -i "network\|firewall\|security\|port" "$data_file"; then
            grep -i "network\|firewall\|security\|port\|connection\|interface" "$data_file" | head -5 | while read -r line; do
                echo "<p class=\"network-info\">$line</p>"
            done
        else
            echo "<p>No network/security information found</p>"
        fi
        echo "</div>"
        
        echo "</div>"
    fi
    
    echo "</div>"
    echo "<hr>"
    
    # Include generic content
    _generate_html_generic_content "$data_file"
}

_generate_json_system_content() {
    local data_file="$1"
    
    # Create system-specific JSON structure
    local temp_json
    temp_json=$(mktemp)
    cat > "$temp_json" << 'EOF'
{
    "system_analysis": {
        "hardware": {
            "cpu": [],
            "memory": [],
            "storage": []
        },
        "operating_system": [],
        "services": [],
        "network_security": [],
        "summary": {
            "total_services": 0,
            "system_health": "unknown"
        }
    },
    "raw_data": []
}
EOF
    
    if [[ -f "$data_file" ]]; then
        # Parse system data
        local cpu_info=""
        local memory_info=""
        local storage_info=""
        local os_info=""
        local services=""
        local network=""
        local service_count=0
        
        while IFS= read -r line; do
            if echo "$line" | grep -q -i "cpu\|processor"; then
                cpu_info="${cpu_info}\"${line}\","
            elif echo "$line" | grep -q -i "memory\|ram"; then
                memory_info="${memory_info}\"${line}\","
            elif echo "$line" | grep -q -i "disk\|storage"; then
                storage_info="${storage_info}\"${line}\","
            elif echo "$line" | grep -q -i "kernel\|distro\|version\|release"; then
                os_info="${os_info}\"${line}\","
            elif echo "$line" | grep -q -i "service\|daemon\|systemd"; then
                services="${services}\"${line}\","
                ((service_count++))
            elif echo "$line" | grep -q -i "network\|firewall\|security"; then
                network="${network}\"${line}\","
            fi
        done < "$data_file"
        
        # Remove trailing commas
        cpu_info=${cpu_info%,}
        memory_info=${memory_info%,}
        storage_info=${storage_info%,}
        os_info=${os_info%,}
        services=${services%,}
        network=${network%,}
        
        # Determine system health
        local health="good"
        if [[ $service_count -gt 10 ]]; then
            health="excellent"
        elif [[ $service_count -eq 0 ]]; then
            health="unknown"
        fi
        
        # Update JSON with system data
        jq --argjson cpu "[$cpu_info]" \
           --argjson mem "[$memory_info]" \
           --argjson storage "[$storage_info]" \
           --argjson os "[$os_info]" \
           --argjson services "[$services]" \
           --argjson network "[$network]" \
           --arg count_s "$service_count" \
           --arg health "$health" \
           '.system_analysis.hardware.cpu = $cpu | 
            .system_analysis.hardware.memory = $mem | 
            .system_analysis.hardware.storage = $storage |
            .system_analysis.operating_system = $os |
            .system_analysis.services = $services |
            .system_analysis.network_security = $network |
            .system_analysis.summary.total_services = ($count_s | tonumber) |
            .system_analysis.summary.system_health = $health' \
           "$temp_json" > "${temp_json}.new" && mv "${temp_json}.new" "$temp_json"
    fi
    
    # Output the JSON content
    cat "$temp_json"
    rm -f "$temp_json"
}

_generate_markdown_system_content() {
    local data_file="$1"
    
    echo "## System Analysis Overview"
    echo ""
    
    if [[ -f "$data_file" ]]; then
        echo "### 💻 Hardware Information"
        if grep -q -i "cpu\|processor\|memory\|disk" "$data_file"; then
            echo "#### CPU & Processing"
            grep -i "cpu\|processor" "$data_file" | head -3 | sed 's/^/- /'
            echo ""
            echo "#### Memory & Storage"
            grep -i "memory\|ram\|disk\|storage" "$data_file" | head -4 | sed 's/^/- /'
        else
            echo "- No hardware information found"
        fi
        echo ""
        
        echo "### 🐧 Operating System"
        if grep -q -i "kernel\|distro\|version" "$data_file"; then
            grep -i "kernel\|distro\|version\|release\|ubuntu\|debian\|arch" "$data_file" | head -4 | sed 's/^/- /'
        else
            echo "- No OS information found"
        fi
        echo ""
        
        echo "### ⚙️ System Services"
        if grep -q -i "service\|daemon\|process" "$data_file"; then
            grep -i "service\|daemon\|process\|systemd\|active\|running" "$data_file" | head -6 | sed 's/^/- /'
        else
            echo "- No service information found"
        fi
        echo ""
        
        echo "### 🌐 Network & Security"
        if grep -q -i "network\|firewall\|security" "$data_file"; then
            grep -i "network\|firewall\|security\|port\|connection\|interface" "$data_file" | head -5 | sed 's/^/- /'
        else
            echo "- No network/security information found"
        fi
        echo ""
    fi
    
    echo "---"
    echo ""
    
    # Include generic content
    _generate_markdown_generic_content "$data_file"
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
