#!/bin/bash
# Command Detection Performance Demo
# Tests the performance difference between cached and uncached command detection

# Change to the correct directory and source our libraries
cd "$(dirname "$0")" || exit 1
source "../lib/common.sh"
source "../lib/validation.sh"

print_status "Command Detection Performance Demo"
echo ""

# Test commands (common gaming and system tools)
test_commands=(
    "steam" "lutris" "wine" "gamemoderun" "mangohud" 
    "git" "gcc" "make" "python3" "docker"
    "pacman" "systemctl" "nvidia-smi" "vulkaninfo"
)

print_status "Testing ${#test_commands[@]} commands for performance comparison"
echo ""

# Test 1: Traditional method (no caching)
print_warning "Test 1: Traditional command detection (no caching)"
start_time=$(date +%s%N)

for _ in {1..5}; do  # Run 5 iterations
    for cmd in "${test_commands[@]}"; do
        command -v "$cmd" >/dev/null 2>&1
    done
done

end_time=$(date +%s%N)
traditional_time=$((($end_time - $start_time) / 1000000))  # Convert to milliseconds
print_info "Traditional method: ${traditional_time}ms for $((5 * ${#test_commands[@]})) checks"
echo ""

# Test 2: First run with caching (cache population)
print_warning "Test 2: First run with caching (cache population)"
clear_command_cache
start_time=$(date +%s%N)

for cmd in "${test_commands[@]}"; do
    command_exists "$cmd"
done

end_time=$(date +%s%N)
first_cached_time=$((($end_time - $start_time) / 1000000))
print_info "First cached run: ${first_cached_time}ms for ${#test_commands[@]} checks"
echo ""

# Test 3: Subsequent runs with caching (cache hits)
print_warning "Test 3: Cached command detection (cache hits)"
start_time=$(date +%s%N)

for _ in {1..5}; do  # Run 5 iterations
    for cmd in "${test_commands[@]}"; do
        get_cached_command "$cmd" >/dev/null
    done
done

end_time=$(date +%s%N)
cached_time=$((($end_time - $start_time) / 1000000))
print_info "Cached method: ${cached_time}ms for $((5 * ${#test_commands[@]})) checks"
echo ""

# Calculate performance improvement
if [[ $cached_time -gt 0 ]]; then
    improvement=$((($traditional_time - $cached_time) * 100 / $traditional_time))
    speedup=$(($traditional_time / $cached_time))
else
    improvement=99
    speedup=999
fi

print_success "Performance Results:"
echo "  Traditional: ${traditional_time}ms"
echo "  Cached: ${cached_time}ms"
echo "  Improvement: ${improvement}% faster"
echo "  Speedup: ${speedup}x faster"
echo ""

# Show cache statistics
print_status "Cache Statistics:"
show_cache_stats
echo ""

# Test bulk caching
print_status "Testing bulk caching performance"
clear_command_cache

print_info "Caching all gaming tools..."
cache_gaming_tools

print_info "Caching all development tools..."  
cache_dev_tools

print_info "Caching all system tools..."
cache_system_tools

echo ""
print_success "Demo completed! Cache is now populated with all known tools."
show_cache_stats
