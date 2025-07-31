#!/bin/bash
# xanadOS Performance Benchmarking Suite
# Comprehensive gaming and system performance validation


# Source xanadOS shared libraries
source "../lib/common.sh"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$HOME/.local/share/xanados/benchmarks"
LOG_FILE="$RESULTS_DIR/benchmark-$(date +%Y%m%d-%H%M%S).log"
SYSTEM_INFO_FILE="$RESULTS_DIR/system-info.json"

# Benchmark configuration
BENCHMARK_DURATION=300  # 5 minutes default
WARMUP_TIME=30         # 30 seconds warmup
ITERATIONS=3           # Number of benchmark iterations

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█              🏁 xanadOS Performance Benchmarks 🏁            █"
    echo "█                                                              █"
    echo "█           Gaming & System Performance Validation             █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# Function to run network benchmarks
benchmark_network() {
    print_section "Network Performance Benchmarks"
    
    local results_file="$RESULTS_DIR/network-benchmark-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$results_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "    \"test_type\": \"network\"," >> "$results_file"
    echo "    \"tests\": {" >> "$results_file"
    
    # Network interface information
    local interface=$(ip route | grep default | awk '{print $5}' | head -1)
    echo "        \"interface_info\": {" >> "$results_file"
    echo "            \"interface\": \"$interface\"," >> "$results_file"
    echo "            \"speed\": \"$(ethtool "$interface" 2>/dev/null | grep Speed | awk '{print $2}' || echo "Unknown")\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # Latency test (ping)
    print_status "Running latency test..."
    local ping_result=$(ping -c 10 8.8.8.8 2>/dev/null | tail -1 | awk -F'/' '{print $5}' || echo "0")
    
    echo "        \"latency\": {" >> "$results_file"
    echo "            \"target\": \"8.8.8.8\"," >> "$results_file"
    echo "            \"avg_latency_ms\": \"$ping_result\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # DNS resolution test
    print_status "Running DNS resolution test..."
    local dns_start=$(date +%s.%N)
    nslookup google.com >/dev/null 2>&1
    local dns_end=$(date +%s.%N)
    local dns_time=$(echo "($dns_end - $dns_start) * 1000" | bc -l 2>/dev/null || echo "0")
    
    echo "        \"dns_resolution\": {" >> "$results_file"
    echo "            \"target\": \"google.com\"," >> "$results_file"
    echo "            \"resolution_time_ms\": \"$dns_time\"" >> "$results_file"
    echo "        }" >> "$results_file"
    
    echo "    }" >> "$results_file"
    echo "}" >> "$results_file"
    
    print_success "Network benchmarks completed"
}

# Function to run gaming-specific benchmarks
benchmark_gaming() {
    print_section "Gaming Performance Benchmarks"
    
    local results_file="$RESULTS_DIR/gaming-benchmark-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$results_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "    \"test_type\": \"gaming\"," >> "$results_file"
    echo "    \"tests\": {" >> "$results_file"
    
    # GameMode test
    if command -v gamemoderun >/dev/null 2>&1; then
        print_status "Testing GameMode functionality..."
        
        # Test GameMode activation
        local gamemode_start=$(date +%s.%N)
        gamemoderun true
        local gamemode_end=$(date +%s.%N)
        local gamemode_time=$(echo "($gamemode_end - $gamemode_start) * 1000" | bc -l 2>/dev/null || echo "0")
        
        echo "        \"gamemode\": {" >> "$results_file"
        echo "            \"available\": true," >> "$results_file"
        echo "            \"activation_time_ms\": \"$gamemode_time\"," >> "$results_file"
        echo "            \"daemon_status\": \"$(systemctl is-active gamemode 2>/dev/null || echo "unknown")\"" >> "$results_file"
        echo "        }," >> "$results_file"
    else
        echo "        \"gamemode\": {" >> "$results_file"
        echo "            \"available\": false" >> "$results_file"
        echo "        }," >> "$results_file"
    fi
    
    # MangoHud test
    if command -v mangohud >/dev/null 2>&1; then
        print_status "Testing MangoHud functionality..."
        
        echo "        \"mangohud\": {" >> "$results_file"
        echo "            \"available\": true," >> "$results_file"
        echo "            \"config_exists\": $([ -f "$HOME/.config/MangoHud/MangoHud.conf" ] && echo "true" || echo "false")" >> "$results_file"
        echo "        }," >> "$results_file"
    else
        echo "        \"mangohud\": {" >> "$results_file"
        echo "            \"available\": false" >> "$results_file"
        echo "        }," >> "$results_file"
    fi
    
    # CPU governor during gaming simulation
    print_status "Testing CPU governor optimization..."
    local current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    
    echo "        \"cpu_optimization\": {" >> "$results_file"
    echo "            \"current_governor\": \"$current_governor\"," >> "$results_file"
    echo "            \"available_governors\": \"$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "unknown")\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # Gaming libraries test
    echo "        \"gaming_libraries\": {" >> "$results_file"
    echo "            \"vulkan_available\": $(vulkaninfo >/dev/null 2>&1 && echo "true" || echo "false")," >> "$results_file"
    echo "            \"opengl_available\": $(glxinfo >/dev/null 2>&1 && echo "true" || echo "false")," >> "$results_file"
    echo "            \"steam_runtime\": $([ -d "$HOME/.steam" ] && echo "true" || echo "false")," >> "$results_file"
    echo "            \"wine_available\": $(command -v wine >/dev/null 2>&1 && echo "true" || echo "false")" >> "$results_file"
    echo "        }" >> "$results_file"
    
    echo "    }" >> "$results_file"
    echo "}" >> "$results_file"
    
    print_success "Gaming benchmarks completed"
}

# Function to run complete benchmark suite
run_complete_benchmark() {
    print_section "Running Complete Benchmark Suite"
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Initialize log file
    echo "xanadOS Performance Benchmark Suite - $(date)" > "$LOG_FILE"
    
    # Collect system information
    collect_system_info
    
    # Run all benchmark categories
    benchmark_cpu
    benchmark_memory
    benchmark_storage
    benchmark_graphics
    benchmark_network
    benchmark_gaming
    
    # Generate summary report
    generate_summary_report
    
    print_success "Complete benchmark suite finished"
}

# Function to generate summary report
generate_summary_report() {
    print_section "Generating Summary Report"
    
    local summary_file="$RESULTS_DIR/benchmark-summary-$(date +%Y%m%d-%H%M%S).html"
    
    cat > "$summary_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>xanadOS Performance Benchmark Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            margin-bottom: 30px;
        }
        .section {
            background: white;
            margin: 20px 0;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .benchmark-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .metric {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #007bff;
        }
        .score {
            font-size: 24px;
            font-weight: bold;
            color: #007bff;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: 600;
        }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏁 xanadOS Performance Benchmark Report</h1>
        <p>Gaming & System Performance Validation</p>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="section">
        <h2>System Information</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
EOF

    # Add system information to HTML report
    if [ -f "$SYSTEM_INFO_FILE" ]; then
        echo "            <tr><td>Hostname</td><td>$(jq -r '.hostname' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "Unknown")</td></tr>" >> "$summary_file"
        echo "            <tr><td>Kernel</td><td>$(jq -r '.kernel' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "Unknown")</td></tr>" >> "$summary_file"
        echo "            <tr><td>CPU</td><td>$(jq -r '.cpu.model' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "Unknown")</td></tr>" >> "$summary_file"
        echo "            <tr><td>Memory</td><td>$(jq -r '.memory.total' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "Unknown")</td></tr>" >> "$summary_file"
        echo "            <tr><td>Graphics</td><td>$(jq -r '.graphics.renderer' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "Unknown")</td></tr>" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << 'EOF'
        </table>
    </div>
    
    <div class="section">
        <h2>Benchmark Results</h2>
        <div class="benchmark-grid">
            <div class="metric">
                <h3>CPU Performance</h3>
                <div class="score">Click to view detailed results</div>
            </div>
            <div class="metric">
                <h3>Memory Performance</h3>
                <div class="score">Click to view detailed results</div>
            </div>
            <div class="metric">
                <h3>Storage Performance</h3>
                <div class="score">Click to view detailed results</div>
            </div>
            <div class="metric">
                <h3>Graphics Performance</h3>
                <div class="score">Click to view detailed results</div>
            </div>
            <div class="metric">
                <h3>Network Performance</h3>
                <div class="score">Click to view detailed results</div>
            </div>
            <div class="metric">
                <h3>Gaming Optimizations</h3>
                <div class="score">Click to view detailed results</div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Gaming Optimization Status</h2>
        <table>
EOF

    # Add gaming optimization status
    if [ -f "$SYSTEM_INFO_FILE" ]; then
        local gamemode_status=$(jq -r '.gaming_optimizations.gamemode_available' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "false")
        local mangohud_status=$(jq -r '.gaming_optimizations.mangohud_available' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "false")
        local steam_status=$(jq -r '.gaming_optimizations.steam_installed' "$SYSTEM_INFO_FILE" 2>/dev/null || echo "false")
        
        echo "            <tr><td>GameMode</td><td class=\"$([ "$gamemode_status" = "true" ] && echo "success" || echo "error")\">$([ "$gamemode_status" = "true" ] && echo "✓ Available" || echo "✗ Not Available")</td></tr>" >> "$summary_file"
        echo "            <tr><td>MangoHud</td><td class=\"$([ "$mangohud_status" = "true" ] && echo "success" || echo "error")\">$([ "$mangohud_status" = "true" ] && echo "✓ Available" || echo "✗ Not Available")</td></tr>" >> "$summary_file"
        echo "            <tr><td>Steam</td><td class=\"$([ "$steam_status" = "true" ] && echo "success" || echo "error")\">$([ "$steam_status" = "true" ] && echo "✓ Installed" || echo "✗ Not Installed")</td></tr>" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << 'EOF'
        </table>
    </div>
    
    <div class="section">
        <h2>Detailed Results</h2>
        <p>Individual benchmark result files:</p>
        <ul>
EOF

    # List all benchmark result files
    for file in "$RESULTS_DIR"/*-benchmark-*.json; do
        if [ -f "$file" ]; then
            echo "            <li>$(basename "$file")</li>" >> "$summary_file"
        fi
    done
    
    cat >> "$summary_file" << 'EOF'
        </ul>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <p>Based on benchmark results, consider the following optimizations:</p>
        <ul>
            <li>Enable GameMode for CPU optimization during gaming</li>
            <li>Configure MangoHud for performance monitoring</li>
            <li>Optimize storage I/O scheduler for gaming workloads</li>
            <li>Enable appropriate CPU governor for gaming sessions</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Next Steps</h2>
        <p>To improve gaming performance:</p>
        <ol>
            <li>Run individual benchmarks for specific analysis</li>
            <li>Compare results after applying optimizations</li>
            <li>Test real-world gaming scenarios</li>
            <li>Monitor system during actual gaming sessions</li>
        </ol>
    </div>
</body>
</html>
EOF

    print_success "Summary report generated: $summary_file"
    
    # Open report if GUI available
    if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        xdg-open "$summary_file" 2>/dev/null &
    fi
}

# Function to show benchmark menu
show_menu() {
    print_section "Benchmark Menu"
    
    echo "Choose benchmark type:"
    echo
    echo "1) Complete Benchmark Suite (Recommended)"
    echo "   - All performance tests"
    echo "   - System information collection"
    echo "   - Comprehensive report generation"
    echo
    echo "2) CPU Benchmarks Only"
    echo "   - Stress testing"
    echo "   - Multi-core performance"
    echo "   - Compression benchmarks"
    echo
    echo "3) Memory Benchmarks Only"
    echo "   - Memory throughput"
    echo "   - Memory latency"
    echo "   - Memory stress testing"
    echo
    echo "4) Storage Benchmarks Only"
    echo "   - Sequential read/write"
    echo "   - Random I/O performance"
    echo "   - Disk throughput testing"
    echo
    echo "5) Graphics Benchmarks Only"
    echo "   - OpenGL performance"
    echo "   - GPU information"
    echo "   - Graphics driver testing"
    echo
    echo "6) Network Benchmarks Only"
    echo "   - Latency testing"
    echo "   - DNS resolution"
    echo "   - Network interface info"
    echo
    echo "7) Gaming Benchmarks Only"
    echo "   - GameMode testing"
    echo "   - Gaming library availability"
    echo "   - Optimization verification"
    echo
    echo "8) View Previous Results"
    echo
    echo "9) Exit"
    echo
}

# Function to view previous results
view_previous_results() {
    print_section "Previous Benchmark Results"
    
    if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        print_warning "No previous benchmark results found"
        return
    fi
    
    echo "Available benchmark results:"
    echo
    
    local count=1
    for file in "$RESULTS_DIR"/*.json; do
        if [ -f "$file" ]; then
            local timestamp=$(jq -r '.timestamp // "Unknown"' "$file" 2>/dev/null)
            local test_type=$(jq -r '.test_type // "Unknown"' "$file" 2>/dev/null)
            echo "$count) $(basename "$file") - Type: $test_type, Time: $timestamp"
            ((count++))
        fi
    done
    
    echo
    echo "HTML Reports:"
    for file in "$RESULTS_DIR"/*.html; do
        if [ -f "$file" ]; then
            echo "• $(basename "$file")"
        fi
    done
    
    echo
    read -r -p "Press Enter to continue..."
}

# Main function
main() {
    print_banner
    check_dependencies
    
    while true; do
        show_menu
        read -r -p "Select option [1-9]: " choice
        
        case $choice in
            1)
                run_complete_benchmark
                break
                ;;
            2)
                collect_system_info
                benchmark_cpu
                break
                ;;
            3)
                collect_system_info
                benchmark_memory
                break
                ;;
            4)
                collect_system_info
                benchmark_storage
                break
                ;;
            5)
                collect_system_info
                benchmark_graphics
                break
                ;;
            6)
                collect_system_info
                benchmark_network
                break
                ;;
            7)
                collect_system_info
                benchmark_gaming
                break
                ;;
            8)
                view_previous_results
                continue
                ;;
            9)
                print_status "Exiting benchmark suite"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                continue
                ;;
        esac
    done
    
    print_success "Benchmark session completed"
    print_status "Results saved in: $RESULTS_DIR"
    print_status "Log file: $LOG_FILE"
}

# Handle interruption
trap 'print_error "Benchmark interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
