#!/bin/bash
# xanadOS ISO Testing and Validation Script
# Automated testing for built ISOs with quality assurance

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly TEST_RESULTS_DIR="$BUILD_ROOT/test-results"
readonly LOG_DIR="$BUILD_ROOT/logs"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test configuration
readonly QEMU_MEMORY="2048"
readonly QEMU_TIMEOUT="300"  # 5 minutes boot timeout

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_section() {
    echo -e "${BLUE}▓▓▓ $1 ▓▓▓${NC}"
}

# Initialize test environment
init_test_environment() {
    print_section "Initializing Test Environment"

    mkdir -p "$TEST_RESULTS_DIR" "$LOG_DIR"

    # Check for required tools
    local required_tools=("qemu-system-x86_64" "7z" "isoinfo")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Install with: sudo pacman -S qemu-desktop p7zip cdrtools"
        return 1
    fi

    print_status "Test environment initialized"
    return 0
}

# Test ISO file integrity
test_iso_integrity() {
    local iso_file="$1"
    local test_name="ISO Integrity"

    print_section "$test_name"

    # Test 1: File exists and is readable
    if [[ ! -f "$iso_file" ]]; then
        print_error "ISO file not found: $iso_file"
        return 1
    fi

    if [[ ! -r "$iso_file" ]]; then
        print_error "ISO file not readable: $iso_file"
        return 1
    fi

    print_status "ISO file exists and is readable"

    # Test 2: Valid ISO 9660 format
    if file "$iso_file" | grep -q "ISO 9660"; then
        print_status "Valid ISO 9660 format detected"
    else
        print_error "Invalid ISO format"
        return 1
    fi

    # Test 3: ISO size validation
    local iso_size=$(stat -c%s "$iso_file" 2>/dev/null)
    local min_size=$((300 * 1024 * 1024))  # 300MB minimum
    local max_size=$((5 * 1024 * 1024 * 1024))  # 5GB maximum

    if [[ $iso_size -gt $min_size && $iso_size -lt $max_size ]]; then
        print_status "ISO size valid: $(( iso_size / 1024 / 1024 ))MB"
    else
        print_error "ISO size invalid: $(( iso_size / 1024 / 1024 ))MB"
        return 1
    fi

    # Test 4: Checksum validation
    local iso_dir=$(dirname "$iso_file")
    local iso_name=$(basename "$iso_file")

    if [[ -f "$iso_dir/$iso_name.sha256" ]]; then
        cd "$iso_dir"
        if sha256sum -c "$iso_name.sha256" &>/dev/null; then
            print_status "SHA256 checksum validation passed"
        else
            print_error "SHA256 checksum validation failed"
            return 1
        fi
    else
        print_warning "SHA256 checksum file not found"
    fi

    return 0
}

# Test ISO structure and contents
test_iso_structure() {
    local iso_file="$1"
    local test_name="ISO Structure"

    print_section "$test_name"

    # Test bootloader presence
    if isoinfo -i "$iso_file" -l | grep -q "boot/"; then
        print_status "Boot directory found"
    else
        print_error "Boot directory missing"
        return 1
    fi

    # Test for essential directories
    local required_dirs=("arch/" "boot/" "EFI/")
    local missing_dirs=()

    for dir in "${required_dirs[@]}"; do
        if ! isoinfo -i "$iso_file" -l | grep -q "$dir"; then
            missing_dirs+=("$dir")
        fi
    done

    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        print_status "All required directories present"
    else
        print_error "Missing directories: ${missing_dirs[*]}"
        return 1
    fi

    # Test for kernel and initramfs
    if isoinfo -i "$iso_file" -l | grep -q "vmlinuz"; then
        print_status "Kernel (vmlinuz) found"
    else
        print_error "Kernel (vmlinuz) missing"
        return 1
    fi

    if isoinfo -i "$iso_file" -l | grep -q "initramfs"; then
        print_status "Initial ramdisk (initramfs) found"
    else
        print_error "Initial ramdisk (initramfs) missing"
        return 1
    fi

    return 0
}

# Test ISO boot capability with QEMU
test_iso_boot() {
    local iso_file="$1"
    local test_name="ISO Boot Test"
    local target_name="$(basename "$(dirname "$iso_file")")"

    print_section "$test_name for $target_name"

    # Create test log
    local test_log="$TEST_RESULTS_DIR/boot-test-$target_name-$(date '+%Y%m%d-%H%M%S').log"

    print_info "Starting QEMU boot test (timeout: ${QEMU_TIMEOUT}s)..."
    print_info "Test log: $test_log"

    # QEMU command for boot testing
    local qemu_cmd=(
        "qemu-system-x86_64"
        "-M" "q35"
        "-m" "$QEMU_MEMORY"
        "-cdrom" "$iso_file"
        "-boot" "d"
        "-nographic"
        "-serial" "stdio"
        "-display" "none"
        "-no-reboot"
    )

    # Run QEMU with timeout
    local boot_success=false
    local qemu_pid=""

    # Start QEMU in background
    "${qemu_cmd[@]}" > "$test_log" 2>&1 &
    qemu_pid=$!

    # Monitor boot process
    local elapsed=0
    local check_interval=5

    while [[ $elapsed -lt $QEMU_TIMEOUT ]]; do
        # Check if QEMU is still running
        if ! kill -0 "$qemu_pid" 2>/dev/null; then
            print_warning "QEMU process ended unexpectedly"
            break
        fi

        # Check for successful boot indicators
        if grep -q "Welcome to.*xanadOS\|login:\|# " "$test_log" 2>/dev/null; then
            print_status "Boot successful - login prompt reached"
            boot_success=true
            break
        fi

        # Check for boot errors
        if grep -q "Kernel panic\|FATAL\|Boot failed" "$test_log" 2>/dev/null; then
            print_error "Boot failed - kernel panic or fatal error detected"
            break
        fi

        sleep $check_interval
        elapsed=$((elapsed + check_interval))

        if [[ $((elapsed % 30)) -eq 0 ]]; then
            print_info "Boot test progress: ${elapsed}/${QEMU_TIMEOUT}s"
        fi
    done

    # Cleanup QEMU process
    if kill -0 "$qemu_pid" 2>/dev/null; then
        print_info "Terminating QEMU process..."
        kill "$qemu_pid" 2>/dev/null || true
        sleep 2
        kill -9 "$qemu_pid" 2>/dev/null || true
    fi

    # Analyze results
    if [[ $boot_success == true ]]; then
        print_status "Boot test passed for $target_name"
        return 0
    else
        print_error "Boot test failed for $target_name"
        print_info "Check log for details: $test_log"
        return 1
    fi
}

# Test gaming-specific features
test_gaming_features() {
    local iso_file="$1"
    local test_name="Gaming Features"

    print_section "$test_name"

    # Extract some files for analysis (if possible)
    local temp_dir="/tmp/xanados-iso-test-$$"
    mkdir -p "$temp_dir"

    # Try to extract specific files for verification
    local test_results=0

    # Test for gaming kernel
    if isoinfo -i "$iso_file" -l | grep -q "linux-zen\|linux-cachyos"; then
        print_status "Gaming-optimized kernel detected"
    else
        print_warning "Standard kernel detected (gaming kernel not found)"
        ((test_results++))
    fi

    # Test for gaming packages in the package list
    if 7z l "$iso_file" 2>/dev/null | grep -q "packages.x86_64"; then
        # Extract and check package list
        if 7z e "$iso_file" -o"$temp_dir" "*/packages.x86_64" &>/dev/null; then
            local pkg_file=$(find "$temp_dir" -name "packages.x86_64" | head -1)
            if [[ -f "$pkg_file" ]]; then
                # Check for gaming packages
                local gaming_packages=("steam" "gamemode" "lutris" "wine" "vulkan-tools")
                local found_packages=0

                for pkg in "${gaming_packages[@]}"; do
                    if grep -q "^$pkg$" "$pkg_file"; then
                        ((found_packages++))
                    fi
                done

                if [[ $found_packages -gt 2 ]]; then
                    print_status "Gaming packages detected ($found_packages/5)"
                else
                    print_warning "Limited gaming packages found ($found_packages/5)"
                    ((test_results++))
                fi
            fi
        fi
    fi

    # Cleanup
    rm -rf "$temp_dir"

    if [[ $test_results -eq 0 ]]; then
        print_status "Gaming features test passed"
        return 0
    else
        print_warning "Gaming features test completed with warnings"
        return 0  # Non-critical for boot functionality
    fi
}

# Generate test report
generate_test_report() {
    local iso_file="$1"
    local test_results="$2"
    local target_name="$(basename "$(dirname "$iso_file")")"

    local report_file="$TEST_RESULTS_DIR/test-report-$target_name-$(date '+%Y%m%d-%H%M%S').md"

    cat > "$report_file" << EOF
# xanadOS ISO Test Report
**Target:** $target_name
**ISO File:** $(basename "$iso_file")
**Test Date:** $(date '+%Y-%m-%d %H:%M:%S')

## Test Results Summary
EOF

    # Parse test results
    if [[ $test_results -eq 0 ]]; then
        echo "**Overall Status:** ✅ **PASSED**" >> "$report_file"
    else
        echo "**Overall Status:** ❌ **FAILED**" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

## Test Details

### ISO Integrity
- File format validation
- Size validation
- Checksum verification

### ISO Structure
- Boot directory presence
- Essential directories verification
- Kernel and initramfs detection

### Boot Capability
- QEMU boot test
- Login prompt verification
- Error detection

### Gaming Features
- Gaming kernel detection
- Gaming packages verification
- Gaming-specific configurations

## Technical Details
- **ISO Size:** $(du -h "$iso_file" | cut -f1)
- **Test Duration:** $(date '+%Y-%m-%d %H:%M:%S')
- **Test Environment:** $(uname -a)

## Files Generated
- Test logs: $TEST_RESULTS_DIR/
- Boot test log: Available for analysis

---
Generated by xanadOS ISO Testing System
EOF

    print_status "Test report generated: $report_file"
}

# Main test function
test_iso() {
    local iso_file="$1"
    local target_name="$(basename "$(dirname "$iso_file")")"

    print_section "Testing ISO: $target_name"
    print_info "ISO File: $iso_file"

    local test_results=0

    # Run all tests
    if ! test_iso_integrity "$iso_file"; then
        ((test_results++))
    fi

    if ! test_iso_structure "$iso_file"; then
        ((test_results++))
    fi

    if ! test_iso_boot "$iso_file"; then
        ((test_results++))
    fi

    if ! test_gaming_features "$iso_file"; then
        # Gaming features are not critical for basic functionality
        print_info "Gaming features test completed with warnings (non-critical)"
    fi

    # Generate report
    generate_test_report "$iso_file" $test_results

    return $test_results
}

# Main execution
main() {
    local iso_files=()
    local test_all=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --iso)
                iso_files+=("$2")
                shift 2
                ;;
            --all)
                test_all=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --iso FILE    Test specific ISO file"
                echo "  --all         Test all ISOs in build output directory"
                echo "  --help        Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Initialize test environment
    if ! init_test_environment; then
        exit 1
    fi

    # Find ISOs to test
    if [[ $test_all == true ]]; then
        readarray -t iso_files < <(find "$BUILD_ROOT/iso" -name "*.iso" -type f 2>/dev/null)
    fi

    if [[ ${#iso_files[@]} -eq 0 ]]; then
        print_error "No ISO files specified or found"
        print_info "Use --iso FILE or --all to specify ISOs to test"
        exit 1
    fi

    # Test each ISO
    local total_tests=${#iso_files[@]}
    local passed_tests=0
    local failed_tests=0

    print_section "xanadOS ISO Testing Suite"
    print_info "Testing $total_tests ISO(s)..."

    for iso_file in "${iso_files[@]}"; do
        if test_iso "$iso_file"; then
            ((passed_tests++))
            print_status "$(basename "$iso_file") - PASSED"
        else
            ((failed_tests++))
            print_error "$(basename "$iso_file") - FAILED"
        fi
        echo ""
    done

    # Final summary
    print_section "Test Suite Summary"
    print_status "Total tests: $total_tests"
    print_status "Passed: $passed_tests"

    if [[ $failed_tests -gt 0 ]]; then
        print_error "Failed: $failed_tests"
        exit 1
    else
        print_status "All tests passed!"
        exit 0
    fi
}

# Execute main function
main "$@"
