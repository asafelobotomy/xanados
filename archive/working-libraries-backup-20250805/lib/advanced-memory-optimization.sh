#!/bin/bash
# xanadOS Advanced Memory Management
# Gaming-optimized memory allocation and management

set -euo pipefail

# Prevent multiple sourcing
[[ "${XANADOS_MEMORY_OPT_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_MEMORY_OPT_LOADED="true"

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Memory configuration
readonly MEMINFO_FILE="/proc/meminfo"
readonly VM_DIR="/proc/sys/vm"

# ============================================================================
# Advanced Memory Detection and Optimization
# ============================================================================

# Detect total system memory
get_total_memory_gb() {
    local mem_kb
    mem_kb=$(grep "^MemTotal:" "$MEMINFO_FILE" | awk '{print $2}')
    echo $((mem_kb / 1024 / 1024))
}

# Detect memory type and speed
detect_memory_profile() {
    local total_gb
    total_gb=$(get_total_memory_gb)

    log_info "Detected ${total_gb}GB system memory"

    if [[ $total_gb -ge 32 ]]; then
        echo "high_memory"
    elif [[ $total_gb -ge 16 ]]; then
        echo "gaming_optimized"
    elif [[ $total_gb -ge 8 ]]; then
        echo "balanced"
    else
        echo "conservative"
    fi
}

# Apply memory profile optimizations
apply_memory_optimizations() {
    local profile="$1"

    log_info "Applying memory optimizations for profile: $profile"

    case "$profile" in
        "high_memory")
            apply_high_memory_optimizations
            ;;
        "gaming_optimized")
            apply_gaming_memory_optimizations
            ;;
        "balanced")
            apply_balanced_memory_optimizations
            ;;
        "conservative")
            apply_conservative_memory_optimizations
            ;;
    esac
}

# High memory system optimizations (32GB+)
apply_high_memory_optimizations() {
    log_info "Applying high memory system optimizations"

    # Aggressive caching for better performance
    echo "1" | sudo tee "$VM_DIR/swappiness" >/dev/null
    echo "200" | sudo tee "$VM_DIR/vfs_cache_pressure" >/dev/null
    echo "30" | sudo tee "$VM_DIR/dirty_ratio" >/dev/null
    echo "10" | sudo tee "$VM_DIR/dirty_background_ratio" >/dev/null

    # Optimize for large memory systems
    echo "10" | sudo tee "$VM_DIR/min_free_kbytes" >/dev/null
    echo "1" | sudo tee "$VM_DIR/zone_reclaim_mode" >/dev/null

    # Configure huge pages for gaming
    configure_huge_pages "aggressive"

    log_success "High memory optimizations applied"
}

# Gaming-optimized memory (16-31GB)
apply_gaming_memory_optimizations() {
    log_info "Applying gaming memory optimizations"

    # Balanced approach for gaming workloads
    echo "10" | sudo tee "$VM_DIR/swappiness" >/dev/null
    echo "50" | sudo tee "$VM_DIR/vfs_cache_pressure" >/dev/null
    echo "15" | sudo tee "$VM_DIR/dirty_ratio" >/dev/null
    echo "5" | sudo tee "$VM_DIR/dirty_background_ratio" >/dev/null

    # Gaming-specific VM settings
    echo "65536" | sudo tee "$VM_DIR/min_free_kbytes" >/dev/null
    echo "0" | sudo tee "$VM_DIR/zone_reclaim_mode" >/dev/null

    # Configure moderate huge pages
    configure_huge_pages "moderate"

    # Optimize memory compaction for gaming
    echo "1" | sudo tee "$VM_DIR/compact_memory" >/dev/null 2>&1 || true

    log_success "Gaming memory optimizations applied"
}

# Balanced memory settings (8-15GB)
apply_balanced_memory_optimizations() {
    log_info "Applying balanced memory optimizations"

    # Conservative but performance-focused
    echo "20" | sudo tee "$VM_DIR/swappiness" >/dev/null
    echo "100" | sudo tee "$VM_DIR/vfs_cache_pressure" >/dev/null
    echo "10" | sudo tee "$VM_DIR/dirty_ratio" >/dev/null
    echo "3" | sudo tee "$VM_DIR/dirty_background_ratio" >/dev/null

    # Standard settings with gaming bias
    echo "32768" | sudo tee "$VM_DIR/min_free_kbytes" >/dev/null

    # Minimal huge pages to preserve memory
    configure_huge_pages "minimal"

    log_success "Balanced memory optimizations applied"
}

# Conservative memory settings (<8GB)
apply_conservative_memory_optimizations() {
    log_info "Applying conservative memory optimizations"

    # Preserve memory aggressively
    echo "60" | sudo tee "$VM_DIR/swappiness" >/dev/null
    echo "150" | sudo tee "$VM_DIR/vfs_cache_pressure" >/dev/null
    echo "5" | sudo tee "$VM_DIR/dirty_ratio" >/dev/null
    echo "2" | sudo tee "$VM_DIR/dirty_background_ratio" >/dev/null

    # Minimal memory reservation
    echo "16384" | sudo tee "$VM_DIR/min_free_kbytes" >/dev/null

    # No huge pages to preserve memory
    configure_huge_pages "disabled"

    log_success "Conservative memory optimizations applied"
}

# Configure transparent huge pages
configure_huge_pages() {
    local mode="$1"
    local thp_path="/sys/kernel/mm/transparent_hugepage"

    if [[ ! -d "$thp_path" ]]; then
        log_warn "Transparent huge pages not supported"
        return 0
    fi

    log_info "Configuring transparent huge pages: $mode"

    case "$mode" in
        "aggressive")
            echo "always" | sudo tee "$thp_path/enabled" >/dev/null
            echo "always" | sudo tee "$thp_path/defrag" >/dev/null
            ;;
        "moderate")
            echo "madvise" | sudo tee "$thp_path/enabled" >/dev/null
            echo "defer" | sudo tee "$thp_path/defrag" >/dev/null
            ;;
        "minimal")
            echo "madvise" | sudo tee "$thp_path/enabled" >/dev/null
            echo "never" | sudo tee "$thp_path/defrag" >/dev/null
            ;;
        "disabled")
            echo "never" | sudo tee "$thp_path/enabled" >/dev/null
            echo "never" | sudo tee "$thp_path/defrag" >/dev/null
            ;;
    esac

    log_success "Transparent huge pages configured: $mode"
}

# Configure zram for gaming systems
configure_gaming_zram() {
    local memory_profile="$1"
    local total_gb
    total_gb=$(get_total_memory_gb)

    log_info "Configuring zram for gaming systems"

    # Check if zram is available
    if ! lsmod | grep -q zram; then
        if ! sudo modprobe zram 2>/dev/null; then
            log_warn "zram module not available"
            return 0
        fi
    fi

    # Calculate zram size based on memory profile
    local zram_size
    case "$memory_profile" in
        "high_memory")
            # Minimal zram for high memory systems
            zram_size="2G"
            ;;
        "gaming_optimized")
            # Moderate zram for gaming
            zram_size="4G"
            ;;
        "balanced")
            # Standard zram
            zram_size="8G"
            ;;
        "conservative")
            # Aggressive zram for low memory
            zram_size="16G"
            ;;
    esac

    # Configure zram device
    if [[ -b "/dev/zram0" ]]; then
        # Reset existing zram
        sudo swapoff /dev/zram0 2>/dev/null || true
        echo "1" | sudo tee /sys/block/zram0/reset >/dev/null
    fi

    # Set compression algorithm (lz4 for gaming performance)
    echo "lz4" | sudo tee /sys/block/zram0/comp_algorithm >/dev/null 2>&1 || true

    # Set size and enable
    echo "$zram_size" | sudo tee /sys/block/zram0/disksize >/dev/null
    sudo mkswap /dev/zram0
    sudo swapon /dev/zram0 -p 10  # High priority

    log_success "Gaming zram configured: $zram_size"
}

# Monitor memory pressure and optimize
monitor_memory_pressure() {
    local threshold="${1:-80}"  # Default 80% threshold

    while true; do
        local mem_usage
        mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')

        if [[ $mem_usage -gt $threshold ]]; then
            log_warn "High memory usage detected: ${mem_usage}%"

            # Trigger memory cleanup
            trigger_memory_cleanup
        fi

        sleep 30
    done
}

# Trigger memory cleanup when under pressure
trigger_memory_cleanup() {
    log_info "Triggering memory cleanup"

    # Drop caches if safe to do so
    if [[ $(cat /proc/loadavg | cut -d' ' -f1 | cut -d'.' -f1) -lt 2 ]]; then
        sync
        echo "1" | sudo tee /proc/sys/vm/drop_caches >/dev/null
        log_info "Dropped page cache"
    fi

    # Trigger memory compaction
    echo "1" | sudo tee /proc/sys/vm/compact_memory >/dev/null 2>&1 || true
}

# Main memory optimization function
optimize_memory_for_gaming() {
    log_info "Starting advanced memory optimization for gaming"

    # Detect memory profile
    local profile
    profile=$(detect_memory_profile)

    log_info "Using memory profile: $profile"

    # Apply optimizations
    apply_memory_optimizations "$profile"
    configure_gaming_zram "$profile"

    # Store optimization state
    local state_file="/tmp/xanados-memory-optimization.state"
    cat > "$state_file" << EOF
profile=$profile
total_memory_gb=$(get_total_memory_gb)
optimization_time=$(date -Iseconds)
EOF

    log_success "Advanced memory optimization completed for profile: $profile"
}

# Restore default memory settings
restore_memory_defaults() {
    log_info "Restoring default memory settings"

    # Restore default VM settings
    echo "60" | sudo tee "$VM_DIR/swappiness" >/dev/null
    echo "100" | sudo tee "$VM_DIR/vfs_cache_pressure" >/dev/null
    echo "20" | sudo tee "$VM_DIR/dirty_ratio" >/dev/null
    echo "10" | sudo tee "$VM_DIR/dirty_background_ratio" >/dev/null

    # Disable custom zram if configured
    sudo swapoff /dev/zram0 2>/dev/null || true

    log_success "Memory settings restored to defaults"
}

# Export functions
export -f get_total_memory_gb
export -f detect_memory_profile
export -f optimize_memory_for_gaming
export -f restore_memory_defaults
export -f monitor_memory_pressure

log_debug "Advanced memory optimization library loaded"
