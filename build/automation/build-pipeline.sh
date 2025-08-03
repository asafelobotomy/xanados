#!/bin/bash
# xanadOS Automated Build Pipeline
# Multi-target ISO build system with quality assurance

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly XANADOS_ROOT="$(cd "$BUILD_ROOT/.." && pwd)"
readonly LOG_DIR="$BUILD_ROOT/logs"
readonly OUTPUT_DIR="$BUILD_ROOT/iso"
readonly WORK_DIR="$BUILD_ROOT/work"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Build targets
declare -A BUILD_TARGETS=(
    ["x86-64-v3"]="Modern CPU optimization (2017+)"
    ["x86-64-v4"]="Latest CPU optimization (2020+)"
    ["compatibility"]="Maximum compatibility (2010+)"
)

# Logging
mkdir -p "$LOG_DIR"
readonly BUILD_LOG="$LOG_DIR/build-$(date '+%Y%m%d-%H%M%S').log"
exec > >(tee -a "$BUILD_LOG") 2>&1

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    xanadOS Automated Build Pipeline                  ║${NC}"
    echo -e "${BLUE}║                     Multi-Target ISO Builder                         ║${NC}"
    echo -e "${BLUE}║                        $(date '+%Y-%m-%d %H:%M:%S')                        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}▓▓▓ $1 ▓▓▓${NC}"
}

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

# Validate build environment
validate_environment() {
    print_section "Build Environment Validation"

    local errors=0

    # Check for required tools
    local required_tools=(
        "mkarchiso"
        "pacman"
        "makepkg"
        "git"
        "docker"
        "pigz"
        "xz"
    )

    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            print_status "$tool found"
        else
            print_error "$tool not found"
            ((errors++))
        fi
    done

    # Check disk space (need at least 10GB)
    local available_space=$(df "$BUILD_ROOT" | awk 'NR==2 {print $4}')
    local required_space=$((10 * 1024 * 1024))  # 10GB in KB

    if [[ $available_space -gt $required_space ]]; then
        print_status "Sufficient disk space available ($(( available_space / 1024 / 1024 ))GB)"
    else
        print_error "Insufficient disk space. Need 10GB, have $(( available_space / 1024 / 1024 ))GB"
        ((errors++))
    fi

    # Check for archiso
    if [[ -d /usr/share/archiso/configs/releng ]]; then
        print_status "archiso configuration found"
    else
        print_error "archiso not properly installed"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        print_error "Environment validation failed with $errors errors"
        exit 1
    fi

    print_status "Build environment validation passed"
    echo ""
}

# CPU feature detection and target validation
detect_build_capabilities() {
    print_section "Build Capability Detection"

    local cpu_features=""
    if [[ -f /proc/cpuinfo ]]; then
        cpu_features=$(grep '^flags' /proc/cpuinfo | head -1 | cut -d: -f2)
    fi

    echo "🔍 Analyzing CPU capabilities for optimal build target selection..."

    # Check x86-64-v4 support
    if echo "$cpu_features" | grep -q "avx512f\|avx512bw\|avx512cd\|avx512dq\|avx512vl"; then
        print_status "x86-64-v4 capable CPU detected (AVX-512 support)"
        echo "   Recommended: x86-64-v4 target for maximum performance"
    # Check x86-64-v3 support
    elif echo "$cpu_features" | grep -q "avx2\|bmi2\|f16c\|fma"; then
        print_status "x86-64-v3 capable CPU detected (AVX2 support)"
        echo "   Recommended: x86-64-v3 target for modern performance"
    else
        print_status "Standard x86-64 CPU detected"
        echo "   Recommended: compatibility target for broad support"
    fi

    echo ""
}

# Load target configuration
load_target_config() {
    local target="$1"
    local config_file="$BUILD_ROOT/targets/${target}.conf"

    if [[ ! -f "$config_file" ]]; then
        print_error "Target configuration not found: $config_file"
        return 1
    fi

    print_info "Loading target configuration: $target"
    source "$config_file"

    # Validate required CPU features if specified
    if [[ -n "${VALIDATION_CMD:-}" ]]; then
        if eval "$VALIDATION_CMD"; then
            print_status "CPU validation passed for $target"
        else
            print_warning "CPU may not support all optimizations for $target"
            if [[ "${FORCE_BUILD:-false}" != "true" ]]; then
                read -p "Continue anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

# Prepare build environment for target
prepare_build_environment() {
    local target="$1"

    print_section "Preparing Build Environment for $target"

    # Create target-specific work directory
    local target_work_dir="$WORK_DIR/$target"
    mkdir -p "$target_work_dir"

    # Copy archiso base configuration
    cp -r /usr/share/archiso/configs/releng/* "$target_work_dir/"

    # Apply xanadOS customizations
    local xanados_config_dir="$XANADOS_ROOT/build"

    # Copy packages list
    if [[ -f "$xanados_config_dir/packages.x86_64" ]]; then
        cp "$xanados_config_dir/packages.x86_64" "$target_work_dir/"
        print_status "xanadOS package list applied"
    fi

    # Apply target-specific package list if it exists
    local target_packages="$xanados_config_dir/packages.${target}.x86_64"
    if [[ -f "$target_packages" ]]; then
        cat "$target_packages" >> "$target_work_dir/packages.x86_64"
        print_status "Target-specific packages applied for $target"
    fi

    # Copy configurations
    if [[ -d "$XANADOS_ROOT/configs" ]]; then
        mkdir -p "$target_work_dir/airootfs/etc/xanados"
        cp -r "$XANADOS_ROOT/configs"/* "$target_work_dir/airootfs/etc/xanados/"
        print_status "xanadOS configurations applied"
    fi

    # Apply makepkg configuration for target
    local makepkg_conf="$target_work_dir/airootfs/etc/makepkg.conf"
    cat > "$makepkg_conf" << EOF
# xanadOS Target: $target
# Generated by automated build pipeline

$(cat "$BUILD_ROOT/targets/${target}.conf" | grep -E '^(CARCH|CHOST|CFLAGS|CXXFLAGS|LDFLAGS|MAKEFLAGS|PKGEXT)=')

# Build target identification
XANADOS_BUILD_TARGET="$target"
XANADOS_BUILD_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
EOF

    print_status "Makepkg configuration applied for $target"

    # Create build identification
    cat > "$target_work_dir/airootfs/etc/xanados-build-info" << EOF
# xanadOS Build Information
BUILD_TARGET="$target"
BUILD_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
BUILD_DESCRIPTION="${BUILD_DESCRIPTION:-}"
PERFORMANCE_GAIN="${PERFORMANCE_GAIN:-}"
BUILD_PIPELINE_VERSION="1.0.0"
COMPILER_FLAGS="$CFLAGS"
EOF

    print_status "Build environment prepared for $target"
    echo ""
}

# Build ISO for specific target
build_iso() {
    local target="$1"
    local target_work_dir="$WORK_DIR/$target"
    local target_output_dir="$OUTPUT_DIR/$target"

    print_section "Building ISO for $target"

    # Create output directory
    mkdir -p "$target_output_dir"

    # Build the ISO
    print_info "Starting mkarchiso for $target..."
    local build_start=$(date +%s)

    if mkarchiso -v -w "$target_work_dir" -o "$target_output_dir" "$target_work_dir"; then
        local build_end=$(date +%s)
        local build_time=$((build_end - build_start))

        print_status "ISO build completed for $target in ${build_time}s"

        # Find the generated ISO
        local iso_file=$(find "$target_output_dir" -name "*.iso" -type f | head -1)
        if [[ -f "$iso_file" ]]; then
            local iso_size=$(du -h "$iso_file" | cut -f1)
            print_status "Generated ISO: $(basename "$iso_file") (${iso_size})"

            # Create checksums
            cd "$target_output_dir"
            sha256sum "$(basename "$iso_file")" > "$(basename "$iso_file").sha256"
            md5sum "$(basename "$iso_file")" > "$(basename "$iso_file").md5"
            print_status "Checksums generated"

            # Create build report
            cat > "$target_output_dir/build-report.txt" << EOF
xanadOS Build Report
===================
Target: $target
Description: ${BUILD_DESCRIPTION:-}
Build Date: $(date '+%Y-%m-%d %H:%M:%S')
Build Time: ${build_time} seconds
ISO Size: $iso_size
Compiler Flags: $CFLAGS
Performance Gain: ${PERFORMANCE_GAIN:-}

ISO File: $(basename "$iso_file")
SHA256: $(cat "$(basename "$iso_file").sha256")
MD5: $(cat "$(basename "$iso_file").md5")
EOF
            print_status "Build report generated"

        else
            print_error "ISO file not found after build"
            return 1
        fi
    else
        print_error "ISO build failed for $target"
        return 1
    fi

    echo ""
    return 0
}

# Run basic ISO validation
validate_iso() {
    local target="$1"
    local target_output_dir="$OUTPUT_DIR/$target"

    print_section "Validating ISO for $target"

    local iso_file=$(find "$target_output_dir" -name "*.iso" -type f | head -1)

    if [[ ! -f "$iso_file" ]]; then
        print_error "ISO file not found for validation"
        return 1
    fi

    # Check ISO integrity
    if file "$iso_file" | grep -q "ISO 9660"; then
        print_status "ISO format validation passed"
    else
        print_error "ISO format validation failed"
        return 1
    fi

    # Check ISO size (should be reasonable)
    local iso_size=$(stat -f%z "$iso_file" 2>/dev/null || stat -c%s "$iso_file")
    local min_size=$((500 * 1024 * 1024))  # 500MB minimum
    local max_size=$((4 * 1024 * 1024 * 1024))  # 4GB maximum

    if [[ $iso_size -gt $min_size && $iso_size -lt $max_size ]]; then
        print_status "ISO size validation passed ($(( iso_size / 1024 / 1024 ))MB)"
    else
        print_error "ISO size validation failed ($(( iso_size / 1024 / 1024 ))MB)"
        return 1
    fi

    # Verify checksums
    cd "$target_output_dir"
    if sha256sum -c "$(basename "$iso_file").sha256" &>/dev/null; then
        print_status "SHA256 checksum validation passed"
    else
        print_error "SHA256 checksum validation failed"
        return 1
    fi

    print_status "ISO validation completed for $target"
    echo ""
    return 0
}

# Generate comprehensive build report
generate_build_report() {
    print_section "Generating Comprehensive Build Report"

    local report_file="$BUILD_ROOT/build-summary-$(date '+%Y%m%d-%H%M%S').md"

    cat > "$report_file" << EOF
# xanadOS Multi-Target Build Report
**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Pipeline Version:** 1.0.0

## Build Summary

### Targets Built
EOF

    for target in "${!BUILD_TARGETS[@]}"; do
        local target_output_dir="$OUTPUT_DIR/$target"
        local iso_file=$(find "$target_output_dir" -name "*.iso" -type f 2>/dev/null | head -1)

        echo "#### $target - ${BUILD_TARGETS[$target]}" >> "$report_file"

        if [[ -f "$iso_file" ]]; then
            local iso_size=$(du -h "$iso_file" | cut -f1)
            echo "- **Status:** ✅ Success" >> "$report_file"
            echo "- **ISO File:** $(basename "$iso_file")" >> "$report_file"
            echo "- **Size:** $iso_size" >> "$report_file"

            if [[ -f "$target_output_dir/build-report.txt" ]]; then
                echo "- **Build Time:** $(grep "Build Time:" "$target_output_dir/build-report.txt" | cut -d: -f2)"  >> "$report_file"
            fi
        else
            echo "- **Status:** ❌ Failed" >> "$report_file"
        fi
        echo "" >> "$report_file"
    done

    cat >> "$report_file" << EOF

## Build Environment
- **Build Host:** $(hostname)
- **Kernel:** $(uname -r)
- **Architecture:** $(uname -m)
- **Build Pipeline:** xanadOS Automated Build System v1.0.0

## Output Location
All ISOs and checksums are available in: \`$OUTPUT_DIR\`

## Usage Instructions
1. Verify checksums before use
2. Select appropriate target based on your CPU
3. Boot from USB/DVD for installation

---
Generated by xanadOS Automated Build Pipeline
EOF

    print_status "Build report generated: $report_file"
    echo ""
}

# Cleanup function
cleanup() {
    print_section "Cleanup"

    if [[ "${KEEP_WORK_DIR:-false}" != "true" ]]; then
        print_info "Cleaning up work directories..."
        rm -rf "$WORK_DIR"
        print_status "Work directories cleaned"
    else
        print_info "Work directories preserved for debugging"
    fi
}

# Main execution function
main() {
    print_header

    local targets_to_build=()
    local build_all=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                targets_to_build+=("$2")
                shift 2
                ;;
            --all)
                build_all=true
                shift
                ;;
            --force)
                export FORCE_BUILD=true
                shift
                ;;
            --keep-work)
                export KEEP_WORK_DIR=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --target TARGET    Build specific target (x86-64-v3, x86-64-v4, compatibility)"
                echo "  --all              Build all targets"
                echo "  --force            Force build even if CPU validation fails"
                echo "  --keep-work        Keep work directories for debugging"
                echo "  --help             Show this help"
                echo ""
                echo "Available targets:"
                for target in "${!BUILD_TARGETS[@]}"; do
                    echo "  $target: ${BUILD_TARGETS[$target]}"
                done
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Set targets to build
    if [[ $build_all == true ]]; then
        targets_to_build=($(printf "%s\n" "${!BUILD_TARGETS[@]}" | sort))
    elif [[ ${#targets_to_build[@]} -eq 0 ]]; then
        print_warning "No targets specified. Use --all or --target TARGET"
        print_info "Available targets: ${!BUILD_TARGETS[*]}"
        exit 1
    fi

    # Validate environment
    validate_environment
    detect_build_capabilities

    # Build each target
    local successful_builds=0
    local failed_builds=0

    for target in "${targets_to_build[@]}"; do
        if [[ -n "${BUILD_TARGETS[$target]:-}" ]]; then
            print_section "Building Target: $target"

            if load_target_config "$target" && \
               prepare_build_environment "$target" && \
               build_iso "$target" && \
               validate_iso "$target"; then
                print_status "Target $target completed successfully"
                ((successful_builds++))
            else
                print_error "Target $target failed"
                ((failed_builds++))
            fi
        else
            print_error "Unknown target: $target"
            ((failed_builds++))
        fi
    done

    # Generate final report
    generate_build_report

    # Summary
    print_section "Build Pipeline Summary"
    print_status "Successful builds: $successful_builds"
    if [[ $failed_builds -gt 0 ]]; then
        print_error "Failed builds: $failed_builds"
    fi

    # Cleanup
    cleanup

    print_section "Build Pipeline Complete"
    echo "🎯 Results available in: $OUTPUT_DIR"
    echo "📋 Build log: $BUILD_LOG"

    # Exit with appropriate code
    if [[ $failed_builds -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
