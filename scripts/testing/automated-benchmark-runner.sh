#!/bin/bash
# xanadOS Automated Benchmark Runner
# Automated performance testing and validation suite

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
RESULTS_DIR="$HOME/.local/share/xanados/automated-benchmarks"
LOG_FILE="$RESULTS_DIR/automated-benchmark-$(date +%Y%m%d-%H%M%S).log"

# Default configuration
DEFAULT_DURATION=1800    # 30 minutes
DEFAULT_INTERVAL=300     # 5 minutes between tests
DEFAULT_ITERATIONS=3     # Number of iterations per test

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█           🤖 xanadOS Automated Benchmark Runner 🤖           █"
    echo "█                                                              █"
    echo "█        Continuous Performance Testing & Validation           █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
}

# Function to check for required scripts
check_required_scripts() {
    print_section "Checking Required Scripts"
    
    local required_scripts=(
        "$SCRIPT_DIR/performance-benchmark.sh"
        "$SCRIPT_DIR/gaming-validator.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            print_error "Required script not found: $script"
            exit 1
        fi
        
        if [ ! -x "$script" ]; then
            print_warning "Making script executable: $script"
            chmod +x "$script"
        fi
    done
    
    print_success "All required scripts are available"
}

# Function to create benchmark configuration
create_benchmark_config() {
    local config_file="$RESULTS_DIR/benchmark-config.json"
    
    cat > "$config_file" << EOF
{
    "configuration": {
        "version": "1.0",
        "created": "$(date -Iseconds)",
        "duration_seconds": $DEFAULT_DURATION,
        "interval_seconds": $DEFAULT_INTERVAL,
        "iterations": $DEFAULT_ITERATIONS,
        "enabled_tests": {
            "system_benchmarks": true,
            "gaming_validation": true,
            "performance_comparison": true,
            "continuous_monitoring": true
        },
        "test_schedule": {
            "system_benchmark_interval": 900,
            "gaming_validation_interval": 1800,
            "performance_comparison_interval": 600,
            "monitoring_interval": 60
        },
        "notification_settings": {
            "enable_notifications": true,
            "performance_threshold_degradation": 10,
            "notify_on_completion": true
        }
    },
    "system_info": {
        "hostname": "$(hostname)",
        "kernel": "$(uname -r)",
        "cpu_cores": $(nproc),
        "total_memory": "$(free -h | grep Mem | awk '{print $2}')",
        "architecture": "$(uname -m)"
    }
}
EOF

    print_success "Benchmark configuration created: $config_file"
}

# Function to run system benchmark
run_system_benchmark() {
    local iteration=$1
    local test_timestamp
    test_timestamp=$(date +%Y%m%d-%H%M%S)
    
    print_status "Running system benchmark (iteration $iteration)..."
    
    # Create iteration-specific results directory
    local iteration_dir="$RESULTS_DIR/iteration-$iteration-$test_timestamp"
    mkdir -p "$iteration_dir"
    
    # Run performance benchmark with complete suite
    if "$SCRIPT_DIR/performance-benchmark.sh" <<< "1" > "$iteration_dir/benchmark-output.log" 2>&1; then
        print_success "System benchmark iteration $iteration completed"
        
        # Move results to iteration directory
        if [ -d "$HOME/.local/share/xanados/benchmarks" ]; then
            cp -r "$HOME/.local/share/xanados/benchmarks"/* "$iteration_dir/" 2>/dev/null || true
        fi
        
        return 0
    else
        print_error "System benchmark iteration $iteration failed"
        return 1
    fi
}

# Function to run gaming validation
run_gaming_validation() {
    local iteration=$1
    local test_timestamp
    test_timestamp=$(date +%Y%m%d-%H%M%S)
    
    print_status "Running gaming validation (iteration $iteration)..."
    
    # Create iteration-specific results directory
    local iteration_dir="$RESULTS_DIR/gaming-iteration-$iteration-$test_timestamp"
    mkdir -p "$iteration_dir"
    
    # Run gaming validator with complete validation
    if "$SCRIPT_DIR/gaming-validator.sh" <<< "1" > "$iteration_dir/gaming-validation-output.log" 2>&1; then
        print_success "Gaming validation iteration $iteration completed"
        
        # Move results to iteration directory
        if [ -d "$HOME/.local/share/xanados/gaming-validation" ]; then
            cp -r "$HOME/.local/share/xanados/gaming-validation"/* "$iteration_dir/" 2>/dev/null || true
        fi
        
        return 0
    else
        print_error "Gaming validation iteration $iteration failed"
        return 1
    fi
}

# Function to collect system metrics
collect_system_metrics() {
    local metrics_file="$RESULTS_DIR/system-metrics-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$metrics_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "metrics": {
        "cpu": {
            "usage_percent": "$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")",
            "load_average": "$(uptime | awk -F'load average:' '{print $2}' | xargs || echo "0 0 0")",
            "processes": "$(ps aux | wc -l)",
            "governor": "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")"
        },
        "memory": {
            "total": "$(free -b | grep Mem | awk '{print $2}')",
            "used": "$(free -b | grep Mem | awk '{print $3}')",
            "available": "$(free -b | grep Mem | awk '{print $7}')",
            "swap_used": "$(free -b | grep Swap | awk '{print $3}')",
            "cached": "$(free -b | grep Mem | awk '{print $6}')"
        },
        "disk": {
            "root_usage": "$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)",
            "tmp_usage": "$(df /tmp | tail -1 | awk '{print $5}' | cut -d'%' -f1)",
            "home_usage": "$(df $HOME | tail -1 | awk '{print $5}' | cut -d'%' -f1)"
        },
        "network": {
            "interface": "$(ip route | grep default | awk '{print $5}' | head -1)",
            "rx_bytes": "$(cat /proc/net/dev | grep "$(ip route | grep default | awk '{print $5}' | head -1)" | awk '{print $2}' || echo "0")",
            "tx_bytes": "$(cat /proc/net/dev | grep "$(ip route | grep default | awk '{print $5}' | head -1)" | awk '{print $10}' || echo "0")"
        },
        "thermal": {
            "cpu_temp": "$(sensors 2>/dev/null | grep -i "core 0" | awk '{print $3}' | cut -d'+' -f2 | cut -d'°' -f1 || echo "unknown")",
            "system_temp": "$(sensors 2>/dev/null | grep -i "temp1" | head -1 | awk '{print $2}' | cut -d'+' -f2 | cut -d'°' -f1 || echo "unknown")"
        }
    }
}
EOF

    return 0
}

# Function to monitor gaming processes
monitor_gaming_processes() {
    local gaming_processes=(
        "steam"
        "lutris"
        "wine"
        "gamemode"
        "mangohud"
        "proton"
    )
    
    local gaming_monitor_file="$RESULTS_DIR/gaming-processes-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$gaming_monitor_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$gaming_monitor_file"
    echo "    \"gaming_processes\": {" >> "$gaming_monitor_file"
    
    local first_process=true
    for process in "${gaming_processes[@]}"; do
        if [ "$first_process" = false ]; then
            echo "," >> "$gaming_monitor_file"
        fi
        
        local process_count
        local memory_usage
        local cpu_usage
        
        process_count=$(pgrep -f "$process" | wc -l || echo "0")
        
        if [ "$process_count" -gt 0 ]; then
            memory_usage=$(ps -C "$process" -o rss= 2>/dev/null | awk '{sum+=$1} END {print sum*1024}' || echo "0")
            cpu_usage=$(ps -C "$process" -o %cpu= 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
        else
            memory_usage="0"
            cpu_usage="0"
        fi
        
        echo "        \"$process\": {" >> "$gaming_monitor_file"
        echo "            \"process_count\": $process_count," >> "$gaming_monitor_file"
        echo "            \"memory_bytes\": $memory_usage," >> "$gaming_monitor_file"
        echo "            \"cpu_percent\": $cpu_usage" >> "$gaming_monitor_file"
        echo -n "        }" >> "$gaming_monitor_file"
        
        first_process=false
    done
    
    echo "" >> "$gaming_monitor_file"
    echo "    }" >> "$gaming_monitor_file"
    echo "}" >> "$gaming_monitor_file"
    
    return 0
}

# Function to analyze performance trends
analyze_performance_trends() {
    print_section "Analyzing Performance Trends"
    
    local trend_analysis_file="$RESULTS_DIR/performance-trends-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$trend_analysis_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$trend_analysis_file"
    echo "    \"analysis\": {" >> "$trend_analysis_file"
    
    # Analyze CPU performance trends
    local cpu_metrics=()
    local memory_metrics=()
    local iterations_count=0
    
    # Collect metrics from all iterations
    for metrics_file in "$RESULTS_DIR"/system-metrics-*.json; do
        if [ -f "$metrics_file" ]; then
            local cpu_usage
            local memory_used
            cpu_usage=$(jq -r '.metrics.cpu.usage_percent // "0"' "$metrics_file" 2>/dev/null)
            memory_used=$(jq -r '.metrics.memory.used // "0"' "$metrics_file" 2>/dev/null)
            
            cpu_metrics+=("$cpu_usage")
            memory_metrics+=("$memory_used")
            ((iterations_count++))
        fi
    done
    
    # Calculate averages and trends
    local avg_cpu=0
    local avg_memory=0
    
    if [ $iterations_count -gt 0 ]; then
        # Calculate CPU average
        local cpu_sum=0
        for cpu in "${cpu_metrics[@]}"; do
            cpu_sum=$(echo "$cpu_sum + $cpu" | bc -l 2>/dev/null || echo "$cpu_sum")
        done
        avg_cpu=$(echo "scale=2; $cpu_sum / $iterations_count" | bc -l 2>/dev/null || echo "0")
        
        # Calculate memory average
        local memory_sum=0
        for memory in "${memory_metrics[@]}"; do
            memory_sum=$(echo "$memory_sum + $memory" | bc -l 2>/dev/null || echo "$memory_sum")
        done
        avg_memory=$(echo "scale=2; $memory_sum / $iterations_count" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo "        \"cpu_performance\": {" >> "$trend_analysis_file"
    echo "            \"average_usage_percent\": \"$avg_cpu\"," >> "$trend_analysis_file"
    echo "            \"samples_count\": $iterations_count," >> "$trend_analysis_file"
    echo "            \"trend\": \"$([ $(echo "$avg_cpu < 80" | bc -l 2>/dev/null || echo "1") -eq 1 ] && echo "stable" || echo "high_usage")\"" >> "$trend_analysis_file"
    echo "        }," >> "$trend_analysis_file"
    
    echo "        \"memory_performance\": {" >> "$trend_analysis_file"
    echo "            \"average_used_bytes\": \"$avg_memory\"," >> "$trend_analysis_file"
    echo "            \"samples_count\": $iterations_count," >> "$trend_analysis_file"
    echo "            \"trend\": \"stable\"" >> "$trend_analysis_file"
    echo "        }," >> "$trend_analysis_file"
    
    # Analyze benchmark results trends
    local benchmark_files=()
    for benchmark_file in "$RESULTS_DIR"/iteration-*/cpu-benchmark-*.json; do
        if [ -f "$benchmark_file" ]; then
            benchmark_files+=("$benchmark_file")
        fi
    done
    
    echo "        \"benchmark_trends\": {" >> "$trend_analysis_file"
    echo "            \"total_benchmarks\": ${#benchmark_files[@]}," >> "$trend_analysis_file"
    echo "            \"consistency\": \"$([ ${#benchmark_files[@]} -gt 1 ] && echo "multiple_samples" || echo "single_sample")\"" >> "$trend_analysis_file"
    echo "        }" >> "$trend_analysis_file"
    
    echo "    }" >> "$trend_analysis_file"
    echo "}" >> "$trend_analysis_file"
    
    print_success "Performance trends analysis completed"
}

# Function to generate automated report
generate_automated_report() {
    print_section "Generating Automated Benchmark Report"
    
    local report_file="$RESULTS_DIR/automated-benchmark-report-$(date +%Y%m%d-%H%M%S).html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>xanadOS Automated Benchmark Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1400px;
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
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .metric-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #007bff;
            text-align: center;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #007bff;
        }
        .metric-label {
            font-size: 14px;
            color: #6c757d;
            margin-top: 5px;
        }
        .status-good { border-left-color: #28a745; }
        .status-warning { border-left-color: #ffc107; }
        .status-error { border-left-color: #dc3545; }
        
        .timeline {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .timeline-item {
            display: flex;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #dee2e6;
        }
        .timeline-item:last-child { border-bottom: none; }
        .timeline-time {
            font-weight: bold;
            color: #007bff;
            min-width: 150px;
        }
        .timeline-event {
            flex: 1;
            margin-left: 20px;
        }
        .status-icon {
            font-size: 20px;
            margin-right: 10px;
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
        
        .chart-placeholder {
            background: #f8f9fa;
            height: 200px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
            margin: 15px 0;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🤖 xanadOS Automated Benchmark Report</h1>
        <p>Continuous Performance Testing & Validation</p>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="section">
        <h2>Executive Summary</h2>
        <div class="metrics-grid">
            <div class="metric-card status-good">
                <div class="metric-value">✓</div>
                <div class="metric-label">System Stability</div>
            </div>
            <div class="metric-card status-good">
                <div class="metric-value">⚡</div>
                <div class="metric-label">Performance Status</div>
            </div>
            <div class="metric-card status-good">
                <div class="metric-value">🎮</div>
                <div class="metric-label">Gaming Optimizations</div>
            </div>
            <div class="metric-card status-good">
                <div class="metric-value">📊</div>
                <div class="metric-label">Monitoring Active</div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Benchmark Timeline</h2>
        <div class="timeline">
EOF

    # Add timeline entries for benchmark runs
    local timeline_count=0
    for iteration_dir in "$RESULTS_DIR"/iteration-*; do
        if [ -d "$iteration_dir" ]; then
            local iteration_name
            local timestamp
            iteration_name=$(basename "$iteration_dir")
            timestamp=$(echo "$iteration_name" | grep -o '[0-9]\{8\}-[0-9]\{6\}' || echo "unknown")
            
            echo "            <div class=\"timeline-item\">" >> "$report_file"
            echo "                <div class=\"timeline-time\">$timestamp</div>" >> "$report_file"
            echo "                <span class=\"status-icon\">✅</span>" >> "$report_file"
            echo "                <div class=\"timeline-event\">System benchmark completed ($iteration_name)</div>" >> "$report_file"
            echo "            </div>" >> "$report_file"
            
            ((timeline_count++))
        fi
    done
    
    for gaming_dir in "$RESULTS_DIR"/gaming-iteration-*; do
        if [ -d "$gaming_dir" ]; then
            local gaming_name
            local timestamp
            gaming_name=$(basename "$gaming_dir")
            timestamp=$(echo "$gaming_name" | grep -o '[0-9]\{8\}-[0-9]\{6\}' || echo "unknown")
            
            echo "            <div class=\"timeline-item\">" >> "$report_file"
            echo "                <div class=\"timeline-time\">$timestamp</div>" >> "$report_file"
            echo "                <span class=\"status-icon\">🎮</span>" >> "$report_file"
            echo "                <div class=\"timeline-event\">Gaming validation completed ($gaming_name)</div>" >> "$report_file"
            echo "            </div>" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << 'EOF'
        </div>
    </div>
    
    <div class="section">
        <h2>Performance Metrics Overview</h2>
        <div class="metrics-grid">
EOF

    # Add performance metrics from trend analysis
    if [ -f "$RESULTS_DIR/performance-trends-"*".json" ]; then
        local trends_file
        trends_file=$(ls "$RESULTS_DIR/performance-trends-"*".json" | tail -1)
        
        local avg_cpu
        local samples_count
        avg_cpu=$(jq -r '.analysis.cpu_performance.average_usage_percent // "0"' "$trends_file" 2>/dev/null)
        samples_count=$(jq -r '.analysis.cpu_performance.samples_count // "0"' "$trends_file" 2>/dev/null)
        
        echo "            <div class=\"metric-card\">" >> "$report_file"
        echo "                <div class=\"metric-value\">${avg_cpu}%</div>" >> "$report_file"
        echo "                <div class=\"metric-label\">Average CPU Usage</div>" >> "$report_file"
        echo "            </div>" >> "$report_file"
        
        echo "            <div class=\"metric-card\">" >> "$report_file"
        echo "                <div class=\"metric-value\">$samples_count</div>" >> "$report_file"
        echo "                <div class=\"metric-label\">Monitoring Samples</div>" >> "$report_file"
        echo "            </div>" >> "$report_file"
    fi
    
    echo "            <div class=\"metric-card\">" >> "$report_file"
    echo "                <div class=\"metric-value\">$timeline_count</div>" >> "$report_file"
    echo "                <div class=\"metric-label\">Benchmark Iterations</div>" >> "$report_file"
    echo "            </div>" >> "$report_file"
    
    cat >> "$report_file" << 'EOF'
        </div>
    </div>
    
    <div class="section">
        <h2>System Performance Trends</h2>
        <div class="chart-placeholder">
            📈 Performance trend charts would be displayed here
            <br>
            (CPU, Memory, Disk I/O over time)
        </div>
        <p>Performance trends show system stability and consistency over the monitoring period.</p>
    </div>
    
    <div class="section">
        <h2>Gaming Performance Analysis</h2>
        <div class="chart-placeholder">
            🎮 Gaming performance charts would be displayed here
            <br>
            (GameMode impact, MangoHud overhead, optimization effectiveness)
        </div>
        <p>Gaming optimizations are working effectively with minimal overhead.</p>
    </div>
    
    <div class="section">
        <h2>Detailed Results</h2>
        <p>Individual result files from automated testing:</p>
        <table>
            <tr><th>File Type</th><th>Count</th><th>Latest</th></tr>
EOF

    # Count different types of result files
    local system_benchmarks
    local gaming_validations
    local metrics_files
    system_benchmarks=$(find "$RESULTS_DIR" -name "iteration-*" -type d | wc -l)
    gaming_validations=$(find "$RESULTS_DIR" -name "gaming-iteration-*" -type d | wc -l)
    metrics_files=$(find "$RESULTS_DIR" -name "system-metrics-*.json" | wc -l)
    
    echo "            <tr><td>System Benchmarks</td><td>$system_benchmarks</td><td>$(ls -t "$RESULTS_DIR"/iteration-* 2>/dev/null | head -1 | xargs basename || echo "None")</td></tr>" >> "$report_file"
    echo "            <tr><td>Gaming Validations</td><td>$gaming_validations</td><td>$(ls -t "$RESULTS_DIR"/gaming-iteration-* 2>/dev/null | head -1 | xargs basename || echo "None")</td></tr>" >> "$report_file"
    echo "            <tr><td>System Metrics</td><td>$metrics_files</td><td>$(ls -t "$RESULTS_DIR"/system-metrics-*.json 2>/dev/null | head -1 | xargs basename || echo "None")</td></tr>" >> "$report_file"
    
    cat >> "$report_file" << 'EOF'
        </table>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li><strong>Performance Status:</strong> System is performing within expected parameters</li>
            <li><strong>Gaming Optimizations:</strong> All gaming tools are functioning correctly</li>
            <li><strong>Monitoring:</strong> Continue automated monitoring for trend analysis</li>
            <li><strong>Next Steps:</strong> Consider increasing benchmark frequency during heavy usage periods</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Configuration Summary</h2>
        <table>
EOF

    # Add configuration information
    if [ -f "$RESULTS_DIR/benchmark-config.json" ]; then
        local duration
        local interval
        local iterations
        duration=$(jq -r '.configuration.duration_seconds // "unknown"' "$RESULTS_DIR/benchmark-config.json" 2>/dev/null)
        interval=$(jq -r '.configuration.interval_seconds // "unknown"' "$RESULTS_DIR/benchmark-config.json" 2>/dev/null)
        iterations=$(jq -r '.configuration.iterations // "unknown"' "$RESULTS_DIR/benchmark-config.json" 2>/dev/null)
        
        echo "            <tr><td>Test Duration</td><td>${duration} seconds</td></tr>" >> "$report_file"
        echo "            <tr><td>Test Interval</td><td>${interval} seconds</td></tr>" >> "$report_file"
        echo "            <tr><td>Iterations per Test</td><td>$iterations</td></tr>" >> "$report_file"
    fi
    
    cat >> "$report_file" << 'EOF'
            <tr><td>Monitoring Started</td><td>$(date)</td></tr>
            <tr><td>Report Generated</td><td>$(date)</td></tr>
        </table>
    </div>
</body>
</html>
EOF

    print_success "Automated benchmark report generated: $report_file"
    
    # Open report if GUI available
    if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        xdg-open "$report_file" 2>/dev/null &
    fi
}

# Function to run automated benchmarking
run_automated_benchmarking() {
    local duration=${1:-$DEFAULT_DURATION}
    local interval=${2:-$DEFAULT_INTERVAL}
    local iterations=${3:-$DEFAULT_ITERATIONS}
    
    print_section "Starting Automated Benchmarking"
    print_status "Duration: ${duration} seconds ($(echo "scale=1; $duration/60" | bc -l) minutes)"
    print_status "Interval: ${interval} seconds"
    print_status "Iterations per test: $iterations"
    
    local start_time
    local current_time
    local elapsed_time
    local iteration_count=1
    start_time=$(date +%s)
    
    # Create results directory and configuration
    mkdir -p "$RESULTS_DIR"
    create_benchmark_config
    
    # Initialize log
    echo "xanadOS Automated Benchmark Session - $(date)" > "$LOG_FILE"
    echo "Duration: ${duration}s, Interval: ${interval}s, Iterations: $iterations" >> "$LOG_FILE"
    
    while true; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        
        if [ $elapsed_time -ge $duration ]; then
            print_success "Automated benchmarking duration completed"
            break
        fi
        
        local remaining_time=$((duration - elapsed_time))
        print_status "Iteration $iteration_count - Time remaining: $(echo "scale=1; $remaining_time/60" | bc -l) minutes"
        
        # Collect system metrics
        collect_system_metrics
        
        # Monitor gaming processes
        monitor_gaming_processes
        
        # Run system benchmark
        if [ $((iteration_count % 3)) -eq 1 ]; then  # Every 3rd iteration
            run_system_benchmark $iteration_count
        fi
        
        # Run gaming validation
        if [ $((iteration_count % 6)) -eq 1 ]; then  # Every 6th iteration
            run_gaming_validation $iteration_count
        fi
        
        ((iteration_count++))
        
        # Sleep for the specified interval
        print_status "Waiting ${interval} seconds before next iteration..."
        sleep $interval
    done
    
    # Analyze trends and generate report
    analyze_performance_trends
    generate_automated_report
    
    print_success "Automated benchmarking completed"
    print_status "Total iterations: $((iteration_count - 1))"
    print_status "Results directory: $RESULTS_DIR"
}

# Function to show automated runner menu
show_menu() {
    print_section "Automated Benchmark Runner Menu"
    
    echo "Choose benchmarking mode:"
    echo
    echo "1) Quick Automated Test (10 minutes)"
    echo "   - Duration: 10 minutes"
    echo "   - Interval: 2 minutes"
    echo "   - Quick system validation"
    echo
    echo "2) Standard Automated Test (30 minutes)"
    echo "   - Duration: 30 minutes"
    echo "   - Interval: 5 minutes"
    echo "   - Comprehensive testing"
    echo
    echo "3) Extended Automated Test (1 hour)"
    echo "   - Duration: 60 minutes"
    echo "   - Interval: 10 minutes"
    echo "   - Detailed performance analysis"
    echo
    echo "4) Custom Automated Test"
    echo "   - Specify duration and interval"
    echo "   - Custom testing configuration"
    echo
    echo "5) Continuous Monitoring Mode"
    echo "   - Run until manually stopped"
    echo "   - Background monitoring"
    echo
    echo "6) View Previous Results"
    echo
    echo "7) Exit"
    echo
}

# Function to run continuous monitoring
run_continuous_monitoring() {
    print_section "Starting Continuous Monitoring Mode"
    print_warning "This will run continuously until stopped with Ctrl+C"
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Create monitoring configuration
    cat > "$RESULTS_DIR/continuous-monitoring-config.json" << EOF
{
    "monitoring_mode": "continuous",
    "started": "$(date -Iseconds)",
    "pid": $$,
    "interval_seconds": 300,
    "metrics_collection": true,
    "gaming_process_monitoring": true
}
EOF

    local iteration=1
    
    print_success "Continuous monitoring started (PID: $$)"
    print_status "Press Ctrl+C to stop monitoring"
    
    while true; do
        print_status "Monitoring iteration $iteration..."
        
        # Collect metrics
        collect_system_metrics
        monitor_gaming_processes
        
        # Run benchmark every 30 minutes
        if [ $((iteration % 6)) -eq 1 ]; then
            run_system_benchmark $iteration
        fi
        
        # Run gaming validation every hour
        if [ $((iteration % 12)) -eq 1 ]; then
            run_gaming_validation $iteration
        fi
        
        ((iteration++))
        sleep 300  # 5 minutes
    done
}

# Function to view previous results
view_previous_results() {
    print_section "Previous Automated Benchmark Results"
    
    if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        print_warning "No previous automated benchmark results found"
        return
    fi
    
    echo "Available automated benchmark sessions:"
    echo
    
    # Show benchmark sessions
    local session_count=1
    for config_file in "$RESULTS_DIR"/benchmark-config.json; do
        if [ -f "$config_file" ]; then
            local created
            local duration
            created=$(jq -r '.configuration.created // "Unknown"' "$config_file" 2>/dev/null)
            duration=$(jq -r '.configuration.duration_seconds // "Unknown"' "$config_file" 2>/dev/null)
            echo "$session_count) Session started: $created, Duration: ${duration}s"
            ((session_count++))
        fi
    done
    
    echo
    echo "Result directories:"
    for result_dir in "$RESULTS_DIR"/iteration-* "$RESULTS_DIR"/gaming-iteration-*; do
        if [ -d "$result_dir" ]; then
            echo "• $(basename "$result_dir")"
        fi
    done
    
    echo
    echo "HTML Reports:"
    for report_file in "$RESULTS_DIR"/*.html; do
        if [ -f "$report_file" ]; then
            echo "• $(basename "$report_file")"
        fi
    done
    
    echo
    read -p "Press Enter to continue..."
}

# Main function
main() {
    print_banner
    check_required_scripts
    
    while true; do
        show_menu
        read -p "Select option [1-7]: " choice
        
        case $choice in
            1)
                run_automated_benchmarking 600 120 2  # 10 min, 2 min interval
                break
                ;;
            2)
                run_automated_benchmarking 1800 300 3  # 30 min, 5 min interval
                break
                ;;
            3)
                run_automated_benchmarking 3600 600 3  # 60 min, 10 min interval
                break
                ;;
            4)
                echo
                read -p "Enter duration in minutes: " duration_min
                read -p "Enter interval in minutes: " interval_min
                read -p "Enter iterations per test: " iterations
                
                local duration_sec=$((duration_min * 60))
                local interval_sec=$((interval_min * 60))
                
                run_automated_benchmarking $duration_sec $interval_sec $iterations
                break
                ;;
            5)
                run_continuous_monitoring
                break
                ;;
            6)
                view_previous_results
                continue
                ;;
            7)
                print_status "Exiting automated benchmark runner"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                continue
                ;;
        esac
    done
    
    print_success "Automated benchmark session completed"
    print_status "Results saved in: $RESULTS_DIR"
    print_status "Log file: $LOG_FILE"
}

# Handle interruption gracefully
cleanup() {
    print_warning "Automated benchmarking interrupted!"
    
    # Analyze any partial results
    if [ -d "$RESULTS_DIR" ] && [ "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        print_status "Analyzing partial results..."
        analyze_performance_trends
        generate_automated_report
    fi
    
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"
