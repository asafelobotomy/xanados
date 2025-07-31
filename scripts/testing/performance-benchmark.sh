#!/bin/bash
# xanadOS Performance Benchmarking Suite
# Comprehensive gaming and system performance validation

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

# Function to check dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    local missing_deps=()
    local required_tools=(
        "stress-ng"
        "sysbench"
        "iperf3"
        "glxgears"
        "7z"
        "dd"
        "hdparm"
        "lscpu"
        "free"
        "nvidia-smi||radeon-profile||radeontop"
    )
    
    for tool in "${required_tools[@]}"; do
        if [[ "$tool" == *"||"* ]]; then
            # Handle alternative tools
            IFS='||' read -ra ALTERNATIVES <<< "$tool"
            local found=false
            for alt in "${ALTERNATIVES[@]}"; do
                if command -v "$alt" >/dev/null 2>&1; then
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                missing_deps+=("${ALTERNATIVES[0]} (or alternatives)")
            fi
        else
            if ! command -v "$tool" >/dev/null 2>&1; then
                missing_deps+=("$tool")
            fi
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        print_status "Installing missing dependencies..."
        
        # Install missing dependencies
        local install_cmd=""
        if command -v pacman >/dev/null 2>&1; then
            install_cmd="sudo pacman -S --noconfirm"
        elif command -v apt >/dev/null 2>&1; then
            install_cmd="sudo apt install -y"
        elif command -v dnf >/dev/null 2>&1; then
            install_cmd="sudo dnf install -y"
        else
            print_error "Unable to determine package manager"
            return 1
        fi
        
        # Map tools to packages
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "stress-ng") $install_cmd stress ;;
                "sysbench") $install_cmd sysbench ;;
                "iperf3") $install_cmd iperf3 ;;
                "glxgears") $install_cmd mesa-demos ;;
                "7z") $install_cmd p7zip ;;
                "hdparm") $install_cmd hdparm ;;
            esac
        done
    fi
    
    print_success "All dependencies available"
}

# Function to collect system information
collect_system_info() {
    print_section "Collecting System Information"
    
    mkdir -p "$RESULTS_DIR"
    
    # Create comprehensive system info JSON
    cat > "$SYSTEM_INFO_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "distribution": "$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")",
    "cpu": {
        "model": "$(lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//')",
        "cores": $(nproc),
        "threads": $(lscpu | grep "Thread(s) per core" | awk '{print $4}'),
        "architecture": "$(uname -m)",
        "frequency": "$(lscpu | grep "CPU MHz" | awk '{print $3}' || echo "Unknown")"
    },
    "memory": {
        "total": "$(free -h | grep Mem | awk '{print $2}')",
        "available": "$(free -h | grep Mem | awk '{print $7}')",
        "swap": "$(free -h | grep Swap | awk '{print $2}')"
    },
    "graphics": {
        "driver": "$(glxinfo 2>/dev/null | grep "OpenGL vendor string" | cut -d: -f2 | xargs || echo "Unknown")",
        "renderer": "$(glxinfo 2>/dev/null | grep "OpenGL renderer string" | cut -d: -f2 | xargs || echo "Unknown")",
        "version": "$(glxinfo 2>/dev/null | grep "OpenGL version string" | cut -d: -f2 | xargs || echo "Unknown")"
    },
    "storage": [
EOF

    # Add storage information
    local first_disk=true
    while IFS= read -r line; do
        if [[ $line == /dev/sd* ]] || [[ $line == /dev/nvme* ]]; then
            if [ "$first_disk" = false ]; then
                echo "," >> "$SYSTEM_INFO_FILE"
            fi
            local device=$(echo "$line" | awk '{print $1}')
            local size=$(lsblk -b "$device" 2>/dev/null | grep -v MOUNTPOINT | awk '{print $4}' | head -1)
            echo "        {" >> "$SYSTEM_INFO_FILE"
            echo "            \"device\": \"$device\"," >> "$SYSTEM_INFO_FILE"
            echo "            \"size\": \"$(numfmt --to=iec $size 2>/dev/null || echo "Unknown")\"," >> "$SYSTEM_INFO_FILE"
            echo "            \"type\": \"$(lsblk -d -o NAME,ROTA "$device" 2>/dev/null | tail -1 | awk '{print ($2 == "0") ? "SSD" : "HDD"}')\"" >> "$SYSTEM_INFO_FILE"
            echo -n "        }" >> "$SYSTEM_INFO_FILE"
            first_disk=false
        fi
    done < <(lsblk -p -o NAME,SIZE,TYPE | grep disk)

    cat >> "$SYSTEM_INFO_FILE" << EOF

    ],
    "gaming_optimizations": {
        "gamemode_available": $(command -v gamemoderun >/dev/null 2>&1 && echo "true" || echo "false"),
        "mangohud_available": $(command -v mangohud >/dev/null 2>&1 && echo "true" || echo "false"),
        "steam_installed": $(command -v steam >/dev/null 2>&1 && echo "true" || echo "false"),
        "lutris_installed": $(command -v lutris >/dev/null 2>&1 && echo "true" || echo "false"),
        "cpu_governor": "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Unknown")"
    }
}
EOF

    print_success "System information collected"
}

# Function to run CPU benchmarks
benchmark_cpu() {
    print_section "CPU Performance Benchmarks"
    
    local results_file="$RESULTS_DIR/cpu-benchmark-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$results_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "    \"test_type\": \"cpu\"," >> "$results_file"
    echo "    \"tests\": {" >> "$results_file"
    
    # CPU stress test
    print_status "Running CPU stress test..."
    local cpu_start_time=$(date +%s.%N)
    stress-ng --cpu $(nproc) --timeout ${WARMUP_TIME}s --metrics-brief > /tmp/cpu_stress.out 2>&1
    local cpu_end_time=$(date +%s.%N)
    local cpu_duration=$(echo "$cpu_end_time - $cpu_start_time" | bc -l 2>/dev/null || echo "0")
    
    echo "        \"stress_test\": {" >> "$results_file"
    echo "            \"duration\": \"${cpu_duration}s\"," >> "$results_file"
    echo "            \"cores_used\": $(nproc)," >> "$results_file"
    echo "            \"operations_per_second\": \"$(grep "operations per second" /tmp/cpu_stress.out | awk '{print $1}' || echo "0")\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # Sysbench CPU test
    if command -v sysbench >/dev/null 2>&1; then
        print_status "Running Sysbench CPU test..."
        sysbench cpu --threads=$(nproc) --time=60 run > /tmp/sysbench_cpu.out 2>&1
        
        echo "        \"sysbench_cpu\": {" >> "$results_file"
        echo "            \"events_per_second\": \"$(grep "events per second" /tmp/sysbench_cpu.out | awk '{print $1}' || echo "0")\"," >> "$results_file"
        echo "            \"latency_avg\": \"$(grep "avg:" /tmp/sysbench_cpu.out | awk '{print $2}' || echo "0")\"," >> "$results_file"
        echo "            \"latency_95th\": \"$(grep "95th percentile:" /tmp/sysbench_cpu.out | awk '{print $3}' || echo "0")\"" >> "$results_file"
        echo "        }," >> "$results_file"
    fi
    
    # 7zip benchmark
    if command -v 7z >/dev/null 2>&1; then
        print_status "Running 7zip benchmark..."
        7z b > /tmp/7zip_bench.out 2>&1
        
        local comp_rating=$(grep "Avr:" /tmp/7zip_bench.out | tail -1 | awk '{print $3}' || echo "0")
        local decomp_rating=$(grep "Avr:" /tmp/7zip_bench.out | tail -1 | awk '{print $4}' || echo "0")
        
        echo "        \"7zip_benchmark\": {" >> "$results_file"
        echo "            \"compression_rating\": \"$comp_rating\"," >> "$results_file"
        echo "            \"decompression_rating\": \"$decomp_rating\"" >> "$results_file"
        echo "        }" >> "$results_file"
    else
        # Remove trailing comma if 7zip not available
        sed -i '$ s/,$//' "$results_file"
    fi
    
    echo "    }" >> "$results_file"
    echo "}" >> "$results_file"
    
    print_success "CPU benchmarks completed"
    return 0
}

# Function to run memory benchmarks
benchmark_memory() {
    print_section "Memory Performance Benchmarks"
    
    local results_file="$RESULTS_DIR/memory-benchmark-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$results_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "    \"test_type\": \"memory\"," >> "$results_file"
    echo "    \"tests\": {" >> "$results_file"
    
    # Memory stress test
    print_status "Running memory stress test..."
    local total_mem=$(free -b | grep Mem | awk '{print $2}')
    local test_mem=$((total_mem * 80 / 100))  # Use 80% of total memory
    
    stress-ng --vm 2 --vm-bytes $test_mem --timeout 60s --metrics-brief > /tmp/mem_stress.out 2>&1
    
    echo "        \"stress_test\": {" >> "$results_file"
    echo "            \"test_size\": \"$(numfmt --to=iec $test_mem)\"," >> "$results_file"
    echo "            \"operations_per_second\": \"$(grep "operations per second" /tmp/mem_stress.out | awk '{print $1}' || echo "0")\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # Sysbench memory test
    if command -v sysbench >/dev/null 2>&1; then
        print_status "Running Sysbench memory test..."
        sysbench memory --memory-total-size=10G run > /tmp/sysbench_mem.out 2>&1
        
        echo "        \"sysbench_memory\": {" >> "$results_file"
        echo "            \"operations_per_second\": \"$(grep "operations per second" /tmp/sysbench_mem.out | awk '{print $1}' || echo "0")\"," >> "$results_file"
        echo "            \"transferred_per_second\": \"$(grep "transferred per second" /tmp/sysbench_mem.out | awk '{print $1}' || echo "0")\"" >> "$results_file"
        echo "        }," >> "$results_file"
    fi
    
    # dd memory test
    print_status "Running dd memory throughput test..."
    local dd_result=$(dd if=/dev/zero of=/dev/null bs=1M count=1024 2>&1 | grep "copied" | awk '{print $(NF-1), $NF}')
    
    echo "        \"dd_throughput\": {" >> "$results_file"
    echo "            \"result\": \"$dd_result\"" >> "$results_file"
    echo "        }" >> "$results_file"
    
    echo "    }" >> "$results_file"
    echo "}" >> "$results_file"
    
    print_success "Memory benchmarks completed"
}

# Function to run storage benchmarks
benchmark_storage() {
    print_section "Storage Performance Benchmarks"
    
    local results_file="$RESULTS_DIR/storage-benchmark-$(date +%Y%m%d-%H%M%S).json"
    local test_file="/tmp/xanados_storage_test"
    
    echo "{" > "$results_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "    \"test_type\": \"storage\"," >> "$results_file"
    echo "    \"tests\": {" >> "$results_file"
    
    # Sequential write test
    print_status "Running sequential write test..."
    local write_result=$(dd if=/dev/zero of="$test_file" bs=1M count=1024 conv=fdatasync 2>&1 | grep "copied" | awk '{print $(NF-1), $NF}')
    
    echo "        \"sequential_write\": {" >> "$results_file"
    echo "            \"size\": \"1GB\"," >> "$results_file"
    echo "            \"result\": \"$write_result\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # Sequential read test
    print_status "Running sequential read test..."
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1  # Clear cache
    local read_result=$(dd if="$test_file" of=/dev/null bs=1M 2>&1 | grep "copied" | awk '{print $(NF-1), $NF}')
    
    echo "        \"sequential_read\": {" >> "$results_file"
    echo "            \"size\": \"1GB\"," >> "$results_file"
    echo "            \"result\": \"$read_result\"" >> "$results_file"
    echo "        }," >> "$results_file"
    
    # Random I/O test with sysbench
    if command -v sysbench >/dev/null 2>&1; then
        print_status "Running random I/O test..."
        sysbench fileio --file-total-size=2G prepare >/dev/null 2>&1
        sysbench fileio --file-total-size=2G --file-test-mode=rndrw --time=60 run > /tmp/sysbench_io.out 2>&1
        sysbench fileio cleanup >/dev/null 2>&1
        
        echo "        \"random_io\": {" >> "$results_file"
        echo "            \"reads_per_second\": \"$(grep "reads/s:" /tmp/sysbench_io.out | awk '{print $2}' || echo "0")\"," >> "$results_file"
        echo "            \"writes_per_second\": \"$(grep "writes/s:" /tmp/sysbench_io.out | awk '{print $2}' || echo "0")\"," >> "$results_file"
        echo "            \"avg_latency\": \"$(grep "avg:" /tmp/sysbench_io.out | awk '{print $2}' || echo "0")\"" >> "$results_file"
        echo "        }," >> "$results_file"
    fi
    
    # hdparm test (if available and running as root or with sudo)
    if command -v hdparm >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        print_status "Running hdparm disk test..."
        local root_device=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
        local hdparm_result=$(sudo hdparm -t "$root_device" 2>/dev/null | grep "Timing" | awk '{print $11, $12}' || echo "N/A")
        
        echo "        \"hdparm_test\": {" >> "$results_file"
        echo "            \"device\": \"$root_device\"," >> "$results_file"
        echo "            \"result\": \"$hdparm_result\"" >> "$results_file"
        echo "        }" >> "$results_file"
    else
        # Remove trailing comma if hdparm not available
        sed -i '$ s/,$//' "$results_file"
    fi
    
    echo "    }" >> "$results_file"
    echo "}" >> "$results_file"
    
    # Cleanup
    rm -f "$test_file"
    
    print_success "Storage benchmarks completed"
}

# Function to run graphics benchmarks
benchmark_graphics() {
    print_section "Graphics Performance Benchmarks"
    
    local results_file="$RESULTS_DIR/graphics-benchmark-$(date +%Y%m%d-%H%M%S).json"
    
    echo "{" > "$results_file"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$results_file"
    echo "    \"test_type\": \"graphics\"," >> "$results_file"
    echo "    \"tests\": {" >> "$results_file"
    
    # Check if we have a display
    if [ -z "$DISPLAY" ]; then
        print_warning "No display available, skipping graphics benchmarks"
        echo "        \"error\": \"No display available\"" >> "$results_file"
        echo "    }" >> "$results_file"
        echo "}" >> "$results_file"
        return 0
    fi
    
    # GLX gears test
    if command -v glxgears >/dev/null 2>&1; then
        print_status "Running GLX gears test..."
        timeout 30 glxgears > /tmp/glxgears.out 2>&1 &
        local glx_pid=$!
        sleep 30
        kill $glx_pid 2>/dev/null || true
        wait $glx_pid 2>/dev/null || true
        
        local fps=$(grep "frames in" /tmp/glxgears.out | tail -1 | awk '{print $1/5}' || echo "0")
        
        echo "        \"glxgears\": {" >> "$results_file"
        echo "            \"fps\": \"$fps\"" >> "$results_file"
        echo "        }," >> "$results_file"
    fi
    
    # GPU information
    echo "        \"gpu_info\": {" >> "$results_file"
    
    # NVIDIA GPU info
    if command -v nvidia-smi >/dev/null 2>&1; then
        local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)
        local gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
        local gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1)
        
        echo "            \"vendor\": \"NVIDIA\"," >> "$results_file"
        echo "            \"model\": \"$gpu_name\"," >> "$results_file"
        echo "            \"memory\": \"${gpu_memory}MB\"," >> "$results_file"
        echo "            \"temperature\": \"${gpu_temp}C\"" >> "$results_file"
    
    # AMD GPU info
    elif command -v radeontop >/dev/null 2>&1; then
        echo "            \"vendor\": \"AMD\"," >> "$results_file"
        echo "            \"model\": \"$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "Unknown")\"" >> "$results_file"
        echo "            \"driver\": \"$(glxinfo 2>/dev/null | grep "OpenGL vendor" | cut -d: -f2 | xargs || echo "Unknown")\"" >> "$results_file"
    
    # Intel GPU info
    else
        echo "            \"vendor\": \"$(glxinfo 2>/dev/null | grep "OpenGL vendor" | cut -d: -f2 | xargs || echo "Unknown")\"," >> "$results_file"
        echo "            \"model\": \"$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "Unknown")\"" >> "$results_file"
        echo "            \"driver\": \"$(glxinfo 2>/dev/null | grep "OpenGL version" | cut -d: -f2 | xargs || echo "Unknown")\"" >> "$results_file"
    fi
    
    echo "        }" >> "$results_file"
    
    echo "    }" >> "$results_file"
    echo "}" >> "$results_file"
    
    print_success "Graphics benchmarks completed"
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
    read -p "Press Enter to continue..."
}

# Main function
main() {
    print_banner
    check_dependencies
    
    while true; do
        show_menu
        read -p "Select option [1-9]: " choice
        
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
