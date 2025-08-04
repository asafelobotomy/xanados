#!/bin/bash
# xanadOS Advanced CPU Optimization
# Modern CPU features and gaming-specific optimizations

set -euo pipefail

# Prevent multiple sourcing
[[ "${XANADOS_CPU_OPT_LOADED:-}" == "true" ]] && return 0
readonly XANADOS_CPU_OPT_LOADED="true"

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# CPU optimization configuration
readonly CPU_INFO_FILE="/proc/cpuinfo"
readonly CPU_FREQ_DIR="/sys/devices/system/cpu/cpufreq"
readonly CPU_GOVERNOR_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

# ============================================================================
# Advanced CPU Detection and Optimization
# ============================================================================

# Detect CPU architecture level (x86-64-v2, v3, v4)
detect_cpu_arch_level() {
    log_info "Detecting CPU architecture optimization level"

    local cpu_flags
    cpu_flags=$(grep -m1 "^flags" "$CPU_INFO_FILE" | cut -d: -f2)

    # x86-64-v4 requirements (2020+)
    local v4_flags=("avx512f" "avx512bw" "avx512cd" "avx512dq" "avx512vl")
    local v4_supported=true

    for flag in "${v4_flags[@]}"; do
        if ! echo "$cpu_flags" | grep -q "$flag"; then
            v4_supported=false
            break
        fi
    done

    if [[ "$v4_supported" == "true" ]]; then
        echo "x86-64-v4"
        return 0
    fi

    # x86-64-v3 requirements (2017+)
    local v3_flags=("avx2" "bmi1" "bmi2" "f16c" "fma" "movbe" "osxsave")
    local v3_supported=true

    for flag in "${v3_flags[@]}"; do
        if ! echo "$cpu_flags" | grep -q "$flag"; then
            v3_supported=false
            break
        fi
    done

    if [[ "$v3_supported" == "true" ]]; then
        echo "x86-64-v3"
        return 0
    fi

    # x86-64-v2 requirements (2009+)
    local v2_flags=("cx16" "lahf_lm" "popcnt" "sse4_1" "sse4_2" "ssse3")
    local v2_supported=true

    for flag in "${v2_flags[@]}"; do
        if ! echo "$cpu_flags" | grep -q "$flag"; then
            v2_supported=false
            break
        fi
    done

    if [[ "$v2_supported" == "true" ]]; then
        echo "x86-64-v2"
        return 0
    fi

    # Fallback to baseline
    echo "x86-64-v1"
}

# Detect CPU vendor and model
detect_cpu_vendor() {
    local vendor_id
    vendor_id=$(grep -m1 "^vendor_id" "$CPU_INFO_FILE" | cut -d: -f2 | tr -d ' ')

    case "$vendor_id" in
        "GenuineIntel")
            echo "intel"
            ;;
        "AuthenticAMD")
            echo "amd"
            ;;
        *)
            echo "generic"
            ;;
    esac
}

# Apply vendor-specific optimizations
apply_vendor_optimizations() {
    local vendor="$1"
    local arch_level="$2"

    log_info "Applying $vendor CPU optimizations for $arch_level"

    case "$vendor" in
        "intel")
            apply_intel_optimizations "$arch_level"
            ;;
        "amd")
            apply_amd_optimizations "$arch_level"
            ;;
        *)
            apply_generic_optimizations "$arch_level"
            ;;
    esac
}

# Intel-specific optimizations
apply_intel_optimizations() {
    local arch_level="$1"

    log_info "Applying Intel-specific optimizations"

    # Intel P-State driver optimizations
    if [[ -f "/sys/devices/system/cpu/intel_pstate/status" ]]; then
        local pstate_status
        pstate_status=$(cat /sys/devices/system/cpu/intel_pstate/status)

        if [[ "$pstate_status" == "active" ]]; then
            # Use performance governor with P-State
            echo "performance" | sudo tee "$CPU_GOVERNOR_FILE" >/dev/null

            # Enable turbo boost if available
            if [[ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
                echo "0" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
                log_success "Intel Turbo Boost enabled"
            fi
        fi
    fi

    # Apply microarchitecture-specific optimizations
    case "$arch_level" in
        "x86-64-v4")
            # Modern Intel with AVX-512 support
            apply_modern_intel_optimizations
            ;;
        "x86-64-v3")
            # Haswell+ optimizations
            apply_haswell_plus_optimizations
            ;;
    esac
}

# AMD-specific optimizations
apply_amd_optimizations() {
    local arch_level="$1"

    log_info "Applying AMD-specific optimizations"

    # AMD P-State driver optimizations
    if [[ -f "/sys/devices/system/cpu/amd_pstate/status" ]]; then
        local pstate_status
        pstate_status=$(cat /sys/devices/system/cpu/amd_pstate/status 2>/dev/null || echo "passive")

        if [[ "$pstate_status" == "active" ]]; then
            echo "performance" | sudo tee "$CPU_GOVERNOR_FILE" >/dev/null
        fi
    fi

    # AMD Boost optimization
    if [[ -f "/sys/devices/system/cpu/cpufreq/boost" ]]; then
        echo "1" | sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null
        log_success "AMD Boost enabled"
    fi

    # Apply Zen architecture optimizations
    apply_zen_optimizations "$arch_level"
}

# Modern Intel optimizations (Skylake+)
apply_modern_intel_optimizations() {
    log_info "Applying modern Intel optimizations"

    # Enable Intel Speed Shift if available
    if cpupower frequency-info | grep -q "hardware limits"; then
        cpupower frequency-set -g performance >/dev/null 2>&1 || true
    fi

    # Optimize for AVX-512 workloads
    if [[ -f "/proc/sys/kernel/sched_min_granularity_ns" ]]; then
        echo "1000000" | sudo tee /proc/sys/kernel/sched_min_granularity_ns >/dev/null
    fi
}

# Haswell+ optimizations
apply_haswell_plus_optimizations() {
    log_info "Applying Haswell+ optimizations"

    # Optimize scheduler for AVX2
    if [[ -f "/proc/sys/kernel/sched_migration_cost_ns" ]]; then
        echo "500000" | sudo tee /proc/sys/kernel/sched_migration_cost_ns >/dev/null
    fi
}

# AMD Zen optimizations
apply_zen_optimizations() {
    local arch_level="$1"

    log_info "Applying AMD Zen optimizations"

    # Zen-specific scheduler optimizations
    if [[ -f "/proc/sys/kernel/sched_autogroup_enabled" ]]; then
        echo "0" | sudo tee /proc/sys/kernel/sched_autogroup_enabled >/dev/null
    fi

    # CCX-aware optimizations for multi-CCD systems
    apply_ccx_optimizations
}

# CCX (Core Complex) optimization for AMD
apply_ccx_optimizations() {
    local cpu_count
    cpu_count=$(nproc)

    # Only apply on systems with multiple CCX (>8 cores typically)
    if [[ $cpu_count -gt 8 ]]; then
        log_info "Applying CCX-aware optimizations for $cpu_count cores"

        # Optimize for NUMA-like behavior within CPU
        if [[ -f "/proc/sys/kernel/numa_balancing" ]]; then
            echo "1" | sudo tee /proc/sys/kernel/numa_balancing >/dev/null
        fi
    fi
}

# Gaming-specific CPU optimizations
apply_gaming_cpu_optimizations() {
    log_info "Applying gaming-specific CPU optimizations"

    # Reduce timer frequency for better gaming performance
    if [[ -f "/proc/sys/kernel/timer_migration" ]]; then
        echo "0" | sudo tee /proc/sys/kernel/timer_migration >/dev/null
    fi

    # Optimize scheduler for interactive workloads
    if [[ -f "/proc/sys/kernel/sched_latency_ns" ]]; then
        echo "6000000" | sudo tee /proc/sys/kernel/sched_latency_ns >/dev/null
    fi

    # Real-time process priority optimization
    if [[ -f "/proc/sys/kernel/sched_rt_runtime_us" ]]; then
        echo "950000" | sudo tee /proc/sys/kernel/sched_rt_runtime_us >/dev/null
    fi
}

# Main optimization function
optimize_cpu_for_gaming() {
    log_info "Starting advanced CPU optimization for gaming"

    # Detect hardware capabilities
    local vendor
    local arch_level
    vendor=$(detect_cpu_vendor)
    arch_level=$(detect_cpu_arch_level)

    log_info "Detected: $vendor CPU with $arch_level architecture level"

    # Apply optimizations
    apply_vendor_optimizations "$vendor" "$arch_level"
    apply_gaming_cpu_optimizations

    # Store optimization state
    local state_file="/tmp/xanados-cpu-optimization.state"
    cat > "$state_file" << EOF
vendor=$vendor
arch_level=$arch_level
optimization_time=$(date -Iseconds)
EOF

    log_success "Advanced CPU optimization completed for $vendor $arch_level"
}

# Restore default CPU settings
restore_cpu_defaults() {
    log_info "Restoring default CPU settings"

    # Restore default governor
    if [[ -f "$CPU_GOVERNOR_FILE" ]]; then
        echo "schedutil" | sudo tee "$CPU_GOVERNOR_FILE" >/dev/null 2>&1 ||
        echo "ondemand" | sudo tee "$CPU_GOVERNOR_FILE" >/dev/null 2>&1 || true
    fi

    # Restore default scheduler settings
    if [[ -f "/proc/sys/kernel/sched_autogroup_enabled" ]]; then
        echo "1" | sudo tee /proc/sys/kernel/sched_autogroup_enabled >/dev/null
    fi

    log_success "CPU settings restored to defaults"
}

# Export functions
export -f detect_cpu_arch_level
export -f detect_cpu_vendor
export -f optimize_cpu_for_gaming
export -f restore_cpu_defaults

log_debug "Advanced CPU optimization library loaded"
