#!/bin/bash
# xanadOS Hardware Detection and Optimization Script - 2025 Security Update
# Automatically applies CPU and GPU specific optimizations
# Personal Use License - see LICENSE file

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging with rotation
LOGFILE="/var/log/xanados-hardware-optimization.log"
LOGSIZE_MAX=10485760  # 10MB

# Rotate log if too large
if [[ -f "$LOGFILE" ]] && [[ $(stat -f%z "$LOGFILE" 2>/dev/null || stat -c%s "$LOGFILE") -gt $LOGSIZE_MAX ]]; then
    mv "$LOGFILE" "${LOGFILE}.old"
fi

exec 1> >(tee -a "$LOGFILE")
exec 2> >(tee -a "$LOGFILE" >&2)

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date): $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date): $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date): $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $(date): $1"
}

# Hardware Detection Functions
detect_cpu() {
    local cpu_info
    cpu_info=$(lscpu)

    if echo "$cpu_info" | grep -qi "intel"; then
        echo "intel"
    elif echo "$cpu_info" | grep -qi "amd"; then
        echo "amd"
    else
        echo "unknown"
    fi
}

detect_gpu() {
    local gpu_info
    gpu_info=$(lspci | grep -i "vga\|3d\|display")

    # Check for multiple GPUs and return primary gaming GPU priority
    if echo "$gpu_info" | grep -qi "nvidia"; then
        echo "nvidia"
    elif echo "$gpu_info" | grep -qi "amd\|radeon"; then
        echo "amd"
    elif echo "$gpu_info" | grep -qi "intel"; then
        echo "intel"
    else
        echo "unknown"
    fi
}

get_cpu_cores() {
    nproc
}

get_memory_gb() {
    local mem_kb
    mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((mem_kb / 1024 / 1024))
}

# CPU-Specific Optimizations
apply_intel_optimizations() {
    log_info "Applying Intel CPU optimizations..."

    # Intel-specific kernel parameters
    local intel_params="intel_pstate=passive intel_idle.max_cstate=0"

    # Intel performance optimizations
    sysctl -w kernel.sched_rt_runtime_us=950000
    sysctl -w kernel.sched_rt_period_us=1000000

    # Intel turbo boost management
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
        log_info "Intel Turbo Boost enabled"
    fi

    # Intel-specific governor settings
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" > "$cpu" 2>/dev/null || true
    done

    # Intel energy performance preference
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [[ -w "$cpu" ]]; then
            echo "performance" > "$cpu" 2>/dev/null || true
        fi
    done

    echo "$intel_params" >> /etc/xanados/hardware-params.conf
    log_info "Intel optimizations applied successfully"
}

apply_amd_optimizations() {
    log_info "Applying AMD CPU optimizations..."

    # AMD-specific kernel parameters
    local amd_params="amd_pstate=passive processor.max_cstate=1"

    # AMD performance optimizations
    sysctl -w kernel.sched_rt_runtime_us=950000

    # AMD boost management
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo 1 > /sys/devices/system/cpu/cpufreq/boost
        log_info "AMD Boost enabled"
    fi

    # AMD-specific governor settings
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" > "$cpu" 2>/dev/null || true
    done

    # AMD SMT management for gaming
    local cores
    cores=$(get_cpu_cores)
    if [[ $cores -gt 8 ]]; then
        log_info "High core count detected ($cores), optimizing for gaming workload"
        # Consider SMT optimization for high core count AMD CPUs
    fi

    echo "$amd_params" >> /etc/xanados/hardware-params.conf
    log_info "AMD optimizations applied successfully"
}

# GPU-Specific Optimizations
apply_nvidia_optimizations() {
    log_info "Applying NVIDIA GPU optimizations..."

    # NVIDIA-specific kernel parameters
    local nvidia_params="nvidia-drm.modeset=1 nvidia.NVreg_UsePageAttributeTable=1"

    # NVIDIA power management
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi -pm 1 2>/dev/null || log_warn "Could not enable NVIDIA persistence mode"
        nvidia-smi -ac 3004,1911 2>/dev/null || log_warn "Could not set NVIDIA application clocks"
    fi

    # NVIDIA GameMode integration
    cat > /etc/gamemode.d/nvidia.conf << 'EOF'
[gpu]
apply_gpu_optimisations=1
gpu_device=0
amd_performance_level=high
[custom]
start=nvidia-smi -pm 1; nvidia-smi -ac 3004,1911
end=nvidia-smi -rac
EOF

    echo "$nvidia_params" >> /etc/xanados/hardware-params.conf
    log_info "NVIDIA optimizations applied successfully"
}

apply_amd_gpu_optimizations() {
    log_info "Applying AMD GPU optimizations..."

    # AMD GPU kernel parameters
    local amd_gpu_params="amdgpu.dc=1 amdgpu.dpm=1 amdgpu.gpu_recovery=1"

    # AMD GPU power management
    if [[ -d /sys/class/drm/card0/device/power_dpm_force_performance_level ]]; then
        echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
        log_info "AMD GPU performance level set to high"
    fi

    # AMD GameMode integration
    cat > /etc/gamemode.d/amd.conf << 'EOF'
[gpu]
apply_gpu_optimisations=1
gpu_device=0
amd_performance_level=high
[custom]
start=echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level
end=echo auto > /sys/class/drm/card0/device/power_dpm_force_performance_level
EOF

    echo "$amd_gpu_params" >> /etc/xanados/hardware-params.conf
    log_info "AMD GPU optimizations applied successfully"
}

apply_intel_gpu_optimizations() {
    log_info "Applying Intel GPU optimizations..."

    # Intel GPU kernel parameters
    local intel_gpu_params="i915.enable_guc=2 i915.enable_fbc=1 i915.fastboot=1"

    # Intel GPU GameMode integration
    cat > /etc/gamemode.d/intel.conf << 'EOF'
[gpu]
apply_gpu_optimisations=0
[custom]
start=echo 1 > /sys/kernel/debug/dri/0/i915_wedged
end=echo 0 > /sys/kernel/debug/dri/0/i915_wedged
EOF

    echo "$intel_gpu_params" >> /etc/xanados/hardware-params.conf
    log_info "Intel GPU optimizations applied successfully"
}

# Memory-based optimizations
apply_memory_optimizations() {
    local memory_gb
    memory_gb=$(get_memory_gb)

    log_info "Detected ${memory_gb}GB RAM, applying memory optimizations..."

    if [[ $memory_gb -ge 32 ]]; then
        # High memory systems
        sysctl -w vm.swappiness=1
        sysctl -w vm.vfs_cache_pressure=50
        sysctl -w vm.dirty_ratio=20
        sysctl -w vm.dirty_background_ratio=5
        log_info "High memory optimizations applied (32GB+)"
    elif [[ $memory_gb -ge 16 ]]; then
        # Standard gaming systems
        sysctl -w vm.swappiness=1
        sysctl -w vm.vfs_cache_pressure=50
        sysctl -w vm.dirty_ratio=15
        sysctl -w vm.dirty_background_ratio=5
        log_info "Standard memory optimizations applied (16-31GB)"
    else
        # Lower memory systems
        sysctl -w vm.swappiness=5
        sysctl -w vm.vfs_cache_pressure=75
        sysctl -w vm.dirty_ratio=10
        sysctl -w vm.dirty_background_ratio=3
        log_info "Conservative memory optimizations applied (<16GB)"
    fi
}

# Setup optimized zram
setup_zram_optimization() {
    local memory_gb
    memory_gb=$(get_memory_gb)

    # Remove existing zram if present
    if swapon --show | grep -q zram; then
        swapoff /dev/zram0 2>/dev/null || true
        rmmod zram 2>/dev/null || true
    fi

    # Calculate optimal zram size (2025 update with zstd)
    local zram_size
    if [[ $memory_gb -ge 32 ]]; then
        zram_size="8G"
    elif [[ $memory_gb -ge 16 ]]; then
        zram_size="4G"
    elif [[ $memory_gb -ge 8 ]]; then
        zram_size="2G"
    else
        zram_size="1G"
    fi

    log_info "Setting up zram with ${zram_size} using zstd compression for ${memory_gb}GB system"

    # Setup optimized zram with zstd (2025 best practice)
    modprobe zram num_devices=1
    echo zstd > /sys/block/zram0/comp_algorithm
    echo "$zram_size" > /sys/block/zram0/disksize
    mkswap /dev/zram0
    swapon -p 10 /dev/zram0

    log_info "zram optimization completed with zstd compression"
}# Main execution
main() {
    log_info "Starting xanadOS hardware optimization..."

    # Create config directory
    mkdir -p /etc/xanados

    # Initialize hardware params file
    echo "# xanadOS Hardware-Specific Kernel Parameters" > /etc/xanados/hardware-params.conf
    echo "# Generated on $(date)" >> /etc/xanados/hardware-params.conf

    # Detect hardware
    local cpu_vendor gpu_vendor
    cpu_vendor=$(detect_cpu)
    gpu_vendor=$(detect_gpu)

    log_info "Detected CPU: $cpu_vendor"
    log_info "Detected GPU: $gpu_vendor"
    log_info "CPU Cores: $(get_cpu_cores)"
    log_info "Memory: $(get_memory_gb)GB"

    # Apply CPU optimizations
    case "$cpu_vendor" in
        "intel")
            apply_intel_optimizations
            ;;
        "amd")
            apply_amd_optimizations
            ;;
        *)
            log_warn "Unknown CPU vendor: $cpu_vendor, applying generic optimizations"
            ;;
    esac

    # Apply GPU optimizations
    case "$gpu_vendor" in
        "nvidia")
            apply_nvidia_optimizations
            ;;
        "amd")
            apply_amd_gpu_optimizations
            ;;
        "intel")
            apply_intel_gpu_optimizations
            ;;
        *)
            log_warn "Unknown GPU vendor: $gpu_vendor, skipping GPU optimizations"
            ;;
    esac

    # Apply memory optimizations
    apply_memory_optimizations

    # Setup zram
    setup_zram_optimization

    # Apply gaming-specific optimizations
    sysctl -w vm.max_map_count=2147483642
    sysctl -w fs.file-max=2147483647
    sysctl -w net.core.netdev_max_backlog=5000

    # I/O scheduler optimization
    for disk in /sys/block/sd*; do
        if [[ -w "$disk/queue/scheduler" ]]; then
            echo "mq-deadline" > "$disk/queue/scheduler"
            log_debug "Set mq-deadline scheduler for $(basename "$disk")"
        fi
    done

    for disk in /sys/block/nvme*; do
        if [[ -w "$disk/queue/scheduler" ]]; then
            echo "none" > "$disk/queue/scheduler"
            log_debug "Set none scheduler for $(basename "$disk")"
        fi
    done

    # IRQ optimization
    if command -v irqbalance >/dev/null 2>&1; then
        systemctl enable --now irqbalance
        log_info "IRQ balancing enabled"
    fi

    log_info "Hardware optimization completed successfully!"
    log_info "Hardware parameters saved to /etc/xanados/hardware-params.conf"
    log_info "Reboot recommended to apply all kernel parameter changes"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Run main function
main "$@"
