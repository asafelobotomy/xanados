#!/bin/bash
# ============================================================================
# Parallel Operations Integration Examples
# Real-world examples of parallel execution in xanadOS scripts
# ============================================================================

set -euo pipefail

# Source xanadOS shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/directories.sh"

# ============================================================================
# Configuration
# ============================================================================

readonly DEMO_NAME="Parallel Operations Integration Examples"
readonly RESULTS_DIR="$(get_results_dir "parallel-demo" false)"

# ============================================================================
# Gaming Setup Parallel Installation Example
# ============================================================================

demo_parallel_gaming_installation() {
    print_header "🎮 Parallel Gaming Installation Demo"
    echo "Demonstrating parallel installation of gaming components..."
    echo
    
    print_status "Simulating parallel gaming package installation..."
    
    # Essential gaming packages that can be installed in parallel
    local essential_packages=(
        "steam"
        "gamemode"
        "mangohud"
        "lib32-mesa"
        "lib32-vulkan-icd-loader"
    )
    
    # Additional gaming packages
    local additional_packages=(
        "lutris"
        "wine"
        "winetricks"
        "discord"
        "obs-studio"
    )
    
    # Performance tools
    local performance_packages=(
        "htop"
        "iotop"
        "stress"
        "sysbench"
        "mesa-demos"
    )
    
    echo "Installing packages in parallel groups:"
    echo "  Essential: ${essential_packages[*]}"
    echo "  Additional: ${additional_packages[*]}"
    echo "  Performance: ${performance_packages[*]}"
    echo
    
    # Initialize progress tracking for 3 groups
    print_status "Starting parallel installation groups..."
    
    # Install in parallel groups
    (
        install_packages_parallel "${essential_packages[@]}" --simulate
    ) &
    
    # Group 2: Additional gaming packages  
    (
        sleep 1  # Slight delay to simulate different completion times
        install_packages_parallel "${additional_packages[@]}" --simulate
    ) &
    
    # Group 3: Performance tools
    (
        sleep 0.5
        install_packages_parallel "${performance_packages[@]}" --simulate
    ) &
    
    # Wait for all groups to complete
    wait
    
    print_success "Parallel gaming installation demo completed"
    echo
}

# ============================================================================
# Parallel Benchmark Execution Example
# ============================================================================

demo_parallel_benchmarks() {
    print_header "🔬 Parallel Benchmark Execution Demo"
    echo "Demonstrating parallel execution of multiple benchmarks..."
    echo
    
    # Define benchmark simulations
    local benchmarks=(
        "echo 'CPU Benchmark: Running stress test...' && sleep 2 && echo 'CPU: 95% performance rating'"
        "echo 'Memory Benchmark: Testing RAM throughput...' && sleep 1.5 && echo 'Memory: 8.2 GB/s throughput'"
        "echo 'Disk Benchmark: Testing I/O performance...' && sleep 2.5 && echo 'Disk: 450 MB/s sequential read'"
        "echo 'Graphics Benchmark: Testing GPU performance...' && sleep 3 && echo 'GPU: 120 FPS average'"
        "echo 'Network Benchmark: Testing connectivity...' && sleep 1 && echo 'Network: 50ms latency'"
    )
    
    print_status "Running ${#benchmarks[@]} benchmarks in parallel..."
    
    if run_benchmark_parallel "${benchmarks[@]}"; then
        print_success "All benchmarks completed successfully"
    else
        print_error "Some benchmarks failed"
    fi
    
    echo
}

# ============================================================================
# Parallel File Processing Example
# ============================================================================

demo_parallel_file_processing() {
    print_header "📁 Parallel File Processing Demo"
    echo "Demonstrating parallel file operations..."
    echo
    
    # Create test files
    local test_dir="$RESULTS_DIR/file-processing-demo"
    mkdir -p "$test_dir"
    
    print_status "Creating test files for parallel processing..."
    
    # Create some test files
    for i in {1..6}; do
        echo "Test file $i content - $(date)" > "$test_dir/testfile$i.txt"
        echo "Additional data for file $i" >> "$test_dir/testfile$i.txt"
        echo "More content to make the file larger" >> "$test_dir/testfile$i.txt"
    done
    
    print_success "Created 6 test files"
    
    # Test parallel checksum calculation
    print_status "Calculating checksums in parallel..."
    
    local test_files=("$test_dir"/testfile*.txt)
    
    if process_files_parallel "checksum" "${test_files[@]}"; then
        print_success "Parallel checksum calculation completed"
        
        # Show results
        echo "Checksum files created:"
        for checksum_file in "$test_dir"/*.sha256; do
            if [[ -f "$checksum_file" ]]; then
                echo "  - $(basename "$checksum_file")"
            fi
        done
    else
        print_error "Parallel file processing failed"
    fi
    
    echo
}

# ============================================================================
# Gaming Setup Wizard Parallel Optimization Example
# ============================================================================

demo_parallel_gaming_optimization() {
    print_header "⚡ Parallel Gaming Optimization Demo"
    echo "Demonstrating parallel application of gaming optimizations..."
    echo
    
    # Define optimization tasks that can run in parallel
    local optimization_tasks=(
        "echo 'CPU Governor: Setting performance mode...' && sleep 1 && echo 'CPU: Performance mode enabled'"
        "echo 'Graphics Driver: Applying optimizations...' && sleep 1.5 && echo 'Graphics: Optimizations applied'"
        "echo 'Network Stack: Tuning for gaming...' && sleep 0.8 && echo 'Network: Gaming optimizations active'"
        "echo 'Memory Manager: Optimizing settings...' && sleep 1.2 && echo 'Memory: Gaming profile applied'"
        "echo 'I/O Scheduler: Configuring for performance...' && sleep 0.9 && echo 'I/O: Performance scheduler active'"
    )
    
    print_status "Applying ${#optimization_tasks[@]} gaming optimizations in parallel..."
    
    # Initialize progress for optimization tasks
    init_multi_progress ${#optimization_tasks[@]}
    
    # Execute optimizations in parallel with progress monitoring
    if run_parallel_jobs "${optimization_tasks[@]}"; then
        print_success "All gaming optimizations applied successfully"
    else
        print_error "Some optimizations failed"
    fi
    
    echo
}

# ============================================================================
# Parallel Download Example
# ============================================================================

demo_parallel_downloads() {
    print_header "⬇️ Parallel Download Demo"
    echo "Demonstrating parallel download functionality..."
    echo
    
    # Example URLs (using httpbin.org for testing)
    local test_urls=(
        "https://httpbin.org/json"
        "https://httpbin.org/uuid"
        "https://httpbin.org/headers"
        "https://httpbin.org/ip"
    )
    
    print_status "Downloading ${#test_urls[@]} files in parallel..."
    
    if command -v curl >/dev/null 2>&1; then
        if download_parallel "${test_urls[@]}"; then
            print_success "Parallel downloads completed"
            
            # Show downloaded files
            local download_dir="${XANADOS_DOWNLOADS_DIR:-/tmp/downloads}"
            if [[ -d "$download_dir" ]]; then
                echo "Downloaded files:"
                for file in "$download_dir"/*; do
                    if [[ -f "$file" ]]; then
                        echo "  - $(basename "$file") ($(wc -c < "$file") bytes)"
                    fi
                done
            fi
        else
            print_error "Parallel downloads failed"
        fi
    else
        print_warning "curl not available, skipping download demo"
    fi
    
    echo
}

# ============================================================================
# System Integration Example
# ============================================================================

demo_system_integration() {
    print_header "🔧 System Integration Demo"
    echo "Demonstrating how parallel operations integrate with xanadOS setup scripts..."
    echo
    
    print_status "Simulating full system setup with parallel operations..."
    
    # Simulate a complete system setup workflow
    local setup_phases=(
        "echo 'Phase 1: Base system configuration...' && sleep 1 && echo 'Base system: Configured'"
        "echo 'Phase 2: Gaming environment setup...' && sleep 1.5 && echo 'Gaming: Environment ready'"
        "echo 'Phase 3: Desktop customization...' && sleep 1.2 && echo 'Desktop: Gaming theme applied'"
        "echo 'Phase 4: Performance optimization...' && sleep 0.8 && echo 'Performance: Optimizations active'"
    )
    
    # Initialize progress for all phases
    init_multi_progress ${#setup_phases[@]}
    
    print_status "Running setup phases in parallel..."
    
    if run_parallel_jobs "${setup_phases[@]}"; then
        print_success "Full system setup completed successfully"
        
        # Summary
        echo
        echo "Setup Summary:"
        echo "  ✅ Base system configured"
        echo "  ✅ Gaming environment ready"
        echo "  ✅ Desktop customized for gaming"
        echo "  ✅ Performance optimizations active"
        echo
        echo "System is ready for gaming! 🎮"
    else
        print_error "System setup encountered issues"
    fi
    
    echo
}

# ============================================================================
# Performance Comparison Demo
# ============================================================================

demo_performance_comparison() {
    print_header "📊 Performance Comparison Demo"
    echo "Comparing sequential vs parallel execution times..."
    echo
    
    # Create test tasks
    local test_tasks=(
        "sleep 0.5"
        "sleep 0.3" 
        "sleep 0.4"
        "sleep 0.2"
    )
    
    # Sequential execution
    print_status "Running tasks sequentially..."
    local start_time
    start_time=$(date +%s)
    
    for task in "${test_tasks[@]}"; do
        eval "$task"
    done
    
    local end_time
    end_time=$(date +%s)
    local sequential_time=$((end_time - start_time))
    
    print_success "Sequential execution completed in ${sequential_time}s"
    
    # Parallel execution
    print_status "Running tasks in parallel..."
    start_time=$(date +%s)
    
    run_parallel "${test_tasks[@]}"
    
    end_time=$(date +%s)
    local parallel_time=$((end_time - start_time))
    
    print_success "Parallel execution completed in ${parallel_time}s"
    
    # Calculate improvement
    local improvement=$((sequential_time - parallel_time))
    
    echo
    echo "Sequential time: ${sequential_time}s"
    echo "Parallel time: ${parallel_time}s"
    echo "Time saved: ${improvement}s"
    echo
}

# ============================================================================
# Main Demo Runner
# ============================================================================

main() {
    local demo_mode="all"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --gaming)
                demo_mode="gaming"
                shift
                ;;
            --benchmark)
                demo_mode="benchmark"
                shift
                ;;
            --files)
                demo_mode="files"
                shift
                ;;
            --downloads)
                demo_mode="downloads"
                shift
                ;;
            --performance)
                demo_mode="performance"
                shift
                ;;
            --help)
                echo "Usage: $0 [--gaming|--benchmark|--files|--downloads|--performance] [--help]"
                echo "  --gaming      Show gaming installation demo"
                echo "  --benchmark   Show benchmark execution demo"
                echo "  --files       Show file processing demo"
                echo "  --downloads   Show download demo"
                echo "  --performance Show performance comparison"
                echo "  --help        Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Setup
    ensure_directory "$RESULTS_DIR"
    
    print_header "🔄 xanadOS Parallel Operations Integration Examples"
    echo "Demonstrating real-world usage of parallel execution in xanadOS setup scripts"
    echo
    
    case "$demo_mode" in
        "gaming")
            demo_parallel_gaming_installation
            demo_parallel_gaming_optimization
            ;;
        "benchmark")
            demo_parallel_benchmarks
            ;;
        "files")
            demo_parallel_file_processing
            ;;
        "downloads")
            demo_parallel_downloads
            ;;
        "performance")
            demo_performance_comparison
            ;;
        "all")
            demo_parallel_gaming_installation
            demo_parallel_benchmarks
            demo_parallel_file_processing
            demo_parallel_gaming_optimization
            demo_parallel_downloads
            demo_system_integration
            demo_performance_comparison
            ;;
    esac
    
    print_header "✅ Parallel Operations Integration Complete"
    echo "All parallel operations examples completed successfully!"
    echo
    echo "Key Benefits Demonstrated:"
    echo "  🚀 Faster package installations through parallel batching"
    echo "  📊 Concurrent benchmark execution for comprehensive testing"
    echo "  📁 Parallel file processing for bulk operations"
    echo "  ⚡ Gaming optimization tasks running simultaneously"
    echo "  ⬇️ Multiple downloads with progress monitoring"
    echo "  🔧 Complete system setup with coordinated parallel phases"
    echo
    echo "Task 3.3.2: Parallel Operations - COMPLETE! 🎉"
}

# Run main function with all arguments
main "$@"
