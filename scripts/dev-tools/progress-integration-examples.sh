#!/bin/bash
# Task 3.3.1: Progress Indicators - Integration Examples
# Demonstrate real-world usage of progress indicators in xanadOS scripts

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# Auto-initialize advanced logging
auto_init_logging "$(basename "$0")" "INFO" "integration"

print_header "Progress Indicators Integration Examples"

# Example 1: Gaming Setup with Progress
gaming_setup_with_progress() {
    print_section "Gaming Setup Simulation"
    
    local steps=(
        "System Updates"
        "Graphics Drivers"
        "Steam Installation"
        "Gaming Tools"
        "Audio Setup"
        "Performance Tuning"
        "Validation"
    )
    
    local total_steps=${#steps[@]}
    
    for i in "${!steps[@]}"; do
        local step_num=$((i + 1))
        local step_name="${steps[i]}"
        
        show_step_progress "$step_name" "$step_num" "$total_steps" "Configuring ${step_name,,}..."
        
        # Simulate work with progress bar
        for j in {1..10}; do
            show_progress_advanced "Installing $step_name" "$j" 10 false 25
            sleep 0.1
        done
        echo
        sleep 0.2
    done
    
    print_success "Gaming setup completed successfully!"
}

# Example 2: ISO Creation with Progress
iso_creation_simulation() {
    print_section "ISO Creation Simulation"
    
    log_info "Starting xanadOS gaming ISO creation..." "iso-builder"
    
    local phases=(
        "Preparing build environment"
        "Installing base packages"
        "Adding gaming software"
        "Configuring system"
        "Creating filesystem"
        "Building ISO image"
        "Validating ISO"
    )
    
    # Multi-step progress
    for i in "${!phases[@]}"; do
        local phase="${phases[i]}"
        local step_num=$((i + 1))
        
        show_step_progress "$phase" "$step_num" "${#phases[@]}"
        
        # Simulate varying work loads
        case $step_num in
            1|7) # Quick steps
                run_with_progress "$phase" sleep 1
                ;;
            2|3|5) # Medium steps  
                for k in {1..20}; do
                    show_progress_advanced "$phase" "$k" 20 true 35
                    sleep 0.05
                done
                ;;
            4|6) # Slow steps
                for k in {1..30}; do
                    show_progress_advanced "$phase" "$k" 30 true 40
                    sleep 0.03
                done
                ;;
        esac
        echo
    done
    
    print_success "xanadOS gaming ISO created successfully!"
}

# Example 3: Benchmark Suite with Multi-Progress
benchmark_suite_simulation() {
    print_section "Gaming Benchmark Suite"
    
    log_info "Running comprehensive gaming benchmarks..." "benchmark"
    
    # Initialize multiple progress trackers
    init_multi_progress "cpu_bench" 25 "CPU Performance Tests"
    init_multi_progress "gpu_bench" 30 "GPU Performance Tests"
    init_multi_progress "disk_bench" 15 "Disk I/O Tests"
    init_multi_progress "network_bench" 10 "Network Performance Tests"
    
    # Simulate parallel benchmark execution
    local benchmarks=("cpu_bench" "gpu_bench" "disk_bench" "network_bench")
    
    for round in {1..35}; do
        # Randomly update different benchmarks
        for bench in "${benchmarks[@]}"; do
            local current="${XANADOS_MULTI_PROGRESS["${bench}_current"]}"
            local total="${XANADOS_MULTI_PROGRESS["${bench}_total"]}"
            
            if [[ "$current" -lt "$total" ]] && (( RANDOM % 3 == 0 )); then
                update_multi_progress "$bench" 1
                echo
            fi
        done
        sleep 0.1
    done
    
    # Ensure all benchmarks complete
    for bench in "${benchmarks[@]}"; do
        local current="${XANADOS_MULTI_PROGRESS["${bench}_current"]}"
        local total="${XANADOS_MULTI_PROGRESS["${bench}_total"]}"
        
        while [[ "$current" -lt "$total" ]]; do
            update_multi_progress "$bench" 1
            current="${XANADOS_MULTI_PROGRESS["${bench}_current"]}"
            echo
            sleep 0.05
        done
    done
    
    print_success "Gaming benchmark suite completed!"
}

# Example 4: Package Download with File Progress
package_download_simulation() {
    print_section "Gaming Package Downloads"
    
    local packages=(
        "steam:156MB"
        "lutris:89MB"
        "gamemode:12MB"
        "mangohud:34MB"
        "wine-staging:234MB"
        "proton-ge:567MB"
    )
    
    for package_info in "${packages[@]}"; do
        local package_name="${package_info%%:*}"
        local package_size="${package_info##*:}"
        local size_mb="${package_size%MB}"
        local size_bytes=$((size_mb * 1024 * 1024))
        
        log_info "Downloading $package_name ($package_size)..." "downloader"
        
        local chunk_size=$((size_bytes / 50))
        for ((current=0; current<=size_bytes; current+=chunk_size)); do
            if [[ $current -gt $size_bytes ]]; then
                current=$size_bytes
            fi
            show_file_progress "DOWNLOAD" "$package_name.pkg" "$current" "$size_bytes"
            sleep 0.02
        done
        echo
        
        log_success "Downloaded $package_name successfully" "downloader"
        sleep 0.3
    done
}

# Example 5: System Optimization with Timer Progress
system_optimization_simulation() {
    print_section "System Optimization"
    
    local optimizations=(
        "CPU governor tuning:5"
        "Memory optimization:8"
        "GPU driver optimization:12"
        "Disk I/O tuning:6"
        "Network optimization:4"
    )
    
    for opt_info in "${optimizations[@]}"; do
        local opt_name="${opt_info%%:*}"
        local duration="${opt_info##*:}"
        
        log_info "Running $opt_name..." "optimizer"
        show_timer_progress "$opt_name" "$duration" 1
        echo
        log_success "$opt_name completed" "optimizer"
    done
    
    print_success "System optimization completed!"
}

# Example 6: Real-world Integration - Enhanced script template
create_enhanced_script_template() {
    print_section "Enhanced Script Template Example"
    
    cat > "$XANADOS_ROOT/scripts/examples/progress-enhanced-template.sh" << 'EOF'
#!/bin/bash
# Enhanced xanadOS Script Template with Progress Indicators
# This template shows how to integrate progress indicators into scripts

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/logging.sh"

# Auto-initialize advanced logging
auto_init_logging "$(basename "$0")" "INFO" "template"

# Example function with progress indicators
enhanced_operation() {
    local operation_name="$1"
    local item_count="$2"
    
    print_header "$operation_name"
    
    # Step-based progress for major phases
    show_step_progress "Initialization" 1 4 "Setting up environment"
    sleep 1
    
    show_step_progress "Processing" 2 4 "Processing $item_count items"
    
    # Item-by-item progress with ETA
    for ((i=1; i<=item_count; i++)); do
        show_progress_advanced "Processing items" "$i" "$item_count" true 30
        # Simulate variable processing time
        sleep $(echo "scale=2; $RANDOM / 32767 * 0.2" | bc -l 2>/dev/null || echo "0.1")
    done
    echo
    
    show_step_progress "Validation" 3 4 "Validating results"
    
    # Timer-based progress for validation
    show_timer_progress "Running validation checks" 3 1
    echo
    
    show_step_progress "Completion" 4 4 "Finalizing operation"
    sleep 1
    
    print_success "$operation_name completed successfully!"
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    enhanced_operation "Example Enhanced Operation" 20
fi
EOF
    
    chmod +x "$XANADOS_ROOT/scripts/examples/progress-enhanced-template.sh"
    log_success "Enhanced script template created: scripts/examples/progress-enhanced-template.sh" "integration"
}

# Main demonstration
main() {
    log_info "Demonstrating progress indicators in real-world scenarios..." "demo"
    
    # Create examples directory if it doesn't exist
    ensure_directory "$XANADOS_ROOT/scripts/examples"
    
    # Run all examples
    gaming_setup_with_progress
    echo
    
    iso_creation_simulation
    echo
    
    benchmark_suite_simulation
    echo
    
    package_download_simulation
    echo
    
    system_optimization_simulation
    echo
    
    create_enhanced_script_template
    echo
    
    print_success "🎉 All integration examples completed successfully!"
    echo
    print_info "Integration Features Demonstrated:"
    print_info "✅ Gaming setup wizard with multi-step progress"
    print_info "✅ ISO creation with phase-based progress tracking"
    print_info "✅ Benchmark suite with multi-progress coordination"
    print_info "✅ Package downloads with file size progress"
    print_info "✅ System optimization with timer-based progress"
    print_info "✅ Enhanced script template for easy integration"
    echo
    print_info "Ready for production deployment across xanadOS!"
}

# Run demonstration
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
