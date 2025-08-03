#!/bin/bash
# xanadOS Gaming Optimization Service
# Applies performance optimizations at boot
# Now integrates with hardware detection

# Personal Use License - see LICENSE file

# Run hardware-specific optimizations first
if [[ -x /usr/local/bin/xanados-hardware-optimization.sh ]]; then
    echo "Running hardware-specific optimizations..."
    /usr/local/bin/xanados-hardware-optimization.sh
else
    echo "Hardware optimization script not found, applying generic optimizations..."

    # Fallback generic optimizations
    # CPU Performance
    echo "performance" > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

    # I/O Scheduler optimization
    for disk in /sys/block/sd*; do
        echo "mq-deadline" > "$disk/queue/scheduler" 2>/dev/null
    done

    for disk in /sys/block/nvme*; do
        echo "none" > "$disk/queue/scheduler" 2>/dev/null
    done

    # Memory optimizations
    echo 1 > /proc/sys/vm/oom_kill_allocating_task
    echo 0 > /proc/sys/vm/oom_dump_tasks

    # Network optimizations for gaming
    echo 1 > /proc/sys/net/core/netdev_max_backlog

    # Gaming-specific sysctl settings
    sysctl -w vm.max_map_count=2147483642
    sysctl -w fs.file-max=2147483647

    # IRQ balance for gaming
    systemctl start irqbalance

    # Generic zram setup for gaming systems
    if ! swapon --show | grep -q zram; then
        modprobe zram num_devices=1
        echo lz4 > /sys/block/zram0/comp_algorithm
        echo 4G > /sys/block/zram0/disksize
        mkswap /dev/zram0
        swapon -p 10 /dev/zram0
    fi
fi

echo "xanadOS gaming optimizations applied successfully"
