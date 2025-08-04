#!/bin/bash
# xanadOS System Monitoring Library
# Modern system monitoring and health checks with 2024/2025 best practices
# Version: 1.0.0

# Bash strict mode - 2024 best practice
set -euo pipefail
IFS=$'\n\t'

# Prevent multiple sourcing
[[ "${XANADOS_MONITORING_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_MONITORING_LOADED="true"

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# Configuration
readonly MONITORING_INTERVAL="${XANADOS_MONITORING_INTERVAL:-60}"
readonly MONITORING_HISTORY_SIZE="${XANADOS_MONITORING_HISTORY:-100}"
readonly MONITORING_ALERT_THRESHOLD_CPU="${XANADOS_CPU_THRESHOLD:-80}"
readonly MONITORING_ALERT_THRESHOLD_MEMORY="${XANADOS_MEMORY_THRESHOLD:-90}"
readonly MONITORING_ALERT_THRESHOLD_DISK="${XANADOS_DISK_THRESHOLD:-85}"

# Global monitoring state
declare -A SYSTEM_METRICS=()
declare -a METRIC_HISTORY=()

# System health check with comprehensive metrics
check_system_health() {
    local detailed="${1:-false}"

    log_debug "Performing system health check"

    # CPU usage
    local cpu_usage
    cpu_usage=$(get_cpu_usage)
    SYSTEM_METRICS["cpu_usage"]="$cpu_usage"

    # Memory usage
    local memory_usage
    memory_usage=$(get_memory_usage)
    SYSTEM_METRICS["memory_usage"]="$memory_usage"

    # Disk usage
    local disk_usage
    disk_usage=$(get_disk_usage "/")
    SYSTEM_METRICS["disk_usage"]="$disk_usage"

    # Load average
    local load_avg
    load_avg=$(get_load_average)
    SYSTEM_METRICS["load_average"]="$load_avg"

    # Network connectivity
    local network_status
    network_status=$(check_network_connectivity)
    SYSTEM_METRICS["network_status"]="$network_status"

    # Process count
    local process_count
    process_count=$(get_process_count)
    SYSTEM_METRICS["process_count"]="$process_count"

    # Check for critical issues
    local health_status="healthy"
    local issues=()

    if (( $(echo "$cpu_usage > $MONITORING_ALERT_THRESHOLD_CPU" | bc -l) )); then
        health_status="warning"
        issues+=("High CPU usage: ${cpu_usage}%")
    fi

    if (( $(echo "$memory_usage > $MONITORING_ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        health_status="critical"
        issues+=("High memory usage: ${memory_usage}%")
    fi

    if (( $(echo "$disk_usage > $MONITORING_ALERT_THRESHOLD_DISK" | bc -l) )); then
        health_status="warning"
        issues+=("High disk usage: ${disk_usage}%")
    fi

    if [[ "$network_status" != "online" ]]; then
        health_status="critical"
        issues+=("Network connectivity issues")
    fi

    SYSTEM_METRICS["health_status"]="$health_status"
    SYSTEM_METRICS["issues"]="${issues[*]}"

    # Log results
    case "$health_status" in
        "healthy")
            log_info "System health: OK"
            ;;
        "warning")
            log_warn "System health: WARNING - ${issues[*]}"
            ;;
        "critical")
            log_error "System health: CRITICAL - ${issues[*]}"
            ;;
    esac

    if [[ "$detailed" == "true" ]]; then
        display_system_metrics
    fi

    return 0
}

# Get CPU usage percentage
get_cpu_usage() {
    local cpu_usage
    # Use top to get CPU usage (more reliable than /proc/stat parsing)
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    echo "${cpu_usage:-0}"
}

# Get memory usage percentage
get_memory_usage() {
    local memory_info
    memory_info=$(free | grep Mem)
    local total used
    total=$(echo "$memory_info" | awk '{print $2}')
    used=$(echo "$memory_info" | awk '{print $3}')

    if [[ $total -gt 0 ]]; then
        echo "scale=1; $used * 100 / $total" | bc
    else
        echo "0"
    fi
}

# Get disk usage percentage for a given path
get_disk_usage() {
    local path="${1:-/}"
    local usage
    usage=$(df "$path" | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "${usage:-0}"
}

# Get system load average
get_load_average() {
    local load
    load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    echo "${load:-0}"
}

# Check network connectivity
check_network_connectivity() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")

    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
            echo "online"
            return 0
        fi
    done

    echo "offline"
    return 1
}

# Get total process count
get_process_count() {
    ps aux | wc -l
}

# Display system metrics in a formatted way
display_system_metrics() {
    echo ""
    print_header "System Metrics"

    printf "%-20s: %s%%\n" "CPU Usage" "${SYSTEM_METRICS[cpu_usage]}"
    printf "%-20s: %s%%\n" "Memory Usage" "${SYSTEM_METRICS[memory_usage]}"
    printf "%-20s: %s%%\n" "Disk Usage" "${SYSTEM_METRICS[disk_usage]}"
    printf "%-20s: %s\n" "Load Average" "${SYSTEM_METRICS[load_average]}"
    printf "%-20s: %s\n" "Network Status" "${SYSTEM_METRICS[network_status]}"
    printf "%-20s: %s\n" "Process Count" "${SYSTEM_METRICS[process_count]}"
    printf "%-20s: %s\n" "Health Status" "${SYSTEM_METRICS[health_status]}"

    if [[ -n "${SYSTEM_METRICS[issues]}" ]]; then
        echo ""
        print_warning "Issues detected:"
        echo "${SYSTEM_METRICS[issues]}"
    fi

    echo ""
}

# Monitor specific service health
monitor_service() {
    local service_name="$1"
    local expected_status="${2:-active}"

    validate_string "$service_name" '^[a-zA-Z0-9._-]+$' "service name"

    local service_status
    if command_exists systemctl; then
        service_status=$(systemctl is-active "$service_name" 2>/dev/null || echo "unknown")
    else
        # Fallback for systems without systemd
        if pgrep -f "$service_name" >/dev/null; then
            service_status="active"
        else
            service_status="inactive"
        fi
    fi

    if [[ "$service_status" == "$expected_status" ]]; then
        log_info "Service '$service_name' is $service_status"
        return 0
    else
        log_warn "Service '$service_name' is $service_status (expected: $expected_status)"
        return 1
    fi
}

# Monitor file system space
monitor_filesystem() {
    local path="${1:-/}"
    local threshold="${2:-$MONITORING_ALERT_THRESHOLD_DISK}"

    validate_directory "$path" true

    local usage
    usage=$(get_disk_usage "$path")

    if (( $(echo "$usage > $threshold" | bc -l) )); then
        log_warn "Filesystem usage at $path: ${usage}% (threshold: ${threshold}%)"
        return 1
    else
        log_debug "Filesystem usage at $path: ${usage}%"
        return 0
    fi
}

# Monitor log file growth
monitor_log_file() {
    local log_file="$1"
    local max_size_mb="${2:-100}"

    validate_file "$log_file" true

    local file_size_mb
    file_size_mb=$(du -m "$log_file" | cut -f1)

    if [[ $file_size_mb -gt $max_size_mb ]]; then
        log_warn "Log file '$log_file' is ${file_size_mb}MB (max: ${max_size_mb}MB)"
        return 1
    else
        log_debug "Log file '$log_file' size: ${file_size_mb}MB"
        return 0
    fi
}

# Monitor process memory usage
monitor_process_memory() {
    local process_name="$1"
    local threshold_mb="${2:-1000}"

    validate_string "$process_name" '^[a-zA-Z0-9._-]+$' "process name"

    local memory_usage
    memory_usage=$(ps -C "$process_name" -o rss= 2>/dev/null | awk '{sum+=$1} END {print sum/1024}' || echo "0")

    if (( $(echo "$memory_usage > $threshold_mb" | bc -l) )); then
        log_warn "Process '$process_name' memory usage: ${memory_usage}MB (threshold: ${threshold_mb}MB)"
        return 1
    else
        log_debug "Process '$process_name' memory usage: ${memory_usage}MB"
        return 0
    fi
}

# Continuous monitoring loop
start_monitoring() {
    local duration="${1:-0}"  # 0 = infinite
    local interval="${2:-$MONITORING_INTERVAL}"

    log_info "Starting system monitoring (interval: ${interval}s)"

    local start_time
    start_time=$(date +%s)

    while true; do
        check_system_health

        # Check if we should stop (duration-based)
        if [[ $duration -gt 0 ]]; then
            local current_time
            current_time=$(date +%s)
            local elapsed=$((current_time - start_time))

            if [[ $elapsed -ge $duration ]]; then
                log_info "Monitoring duration completed (${duration}s)"
                break
            fi
        fi

        sleep "$interval"
    done
}

# Generate monitoring report
generate_monitoring_report() {
    local output_file="${1:-/tmp/system-monitoring-report.txt}"

    {
        echo "xanadOS System Monitoring Report"
        echo "Generated: $(date)"
        echo "======================================="
        echo ""

        check_system_health true

        echo ""
        echo "Additional Checks:"
        echo "=================="

        # Check critical services
        local critical_services=("sshd" "NetworkManager" "systemd-resolved")
        for service in "${critical_services[@]}"; do
            if monitor_service "$service" >/dev/null 2>&1; then
                echo "✓ Service $service: OK"
            else
                echo "✗ Service $service: ISSUE"
            fi
        done

        # Check filesystem usage
        local filesystems=("/" "/tmp" "/var")
        for fs in "${filesystems[@]}"; do
            if [[ -d "$fs" ]]; then
                local usage
                usage=$(get_disk_usage "$fs")
                echo "  Filesystem $fs: ${usage}%"
            fi
        done

        echo ""
        echo "Report completed at: $(date)"

    } > "$output_file"

    log_info "Monitoring report saved to: $output_file"
    return 0
}

# Cleanup monitoring resources
cleanup_monitoring() {
    log_debug "Cleaning up monitoring resources"

    # Clear metrics
    unset SYSTEM_METRICS
    declare -A SYSTEM_METRICS=()

    # Clear history
    METRIC_HISTORY=()

    log_debug "Monitoring cleanup completed"
}

# Library initialization
log_debug "xanadOS Monitoring Library v1.0.0 loaded"
