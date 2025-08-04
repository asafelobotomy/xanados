#!/bin/bash
# xanadOS AUR Package Builder
# Build and manage custom AUR packages for xanadOS

# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh" || {
    echo "Error: Could not source common.sh" >&2
    exit 1
}

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly BUILD_DIR="$HOME/.cache/xanados-aur/builds"
readonly PKG_DIR="$HOME/.cache/xanados-aur/packages"
readonly LOG_FILE="$HOME/.cache/xanados-aur/builder.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Create directories
mkdir -p "$BUILD_DIR" "$PKG_DIR"

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Build AUR package
build_aur_package() {
    local package_name="$1"
    local build_path="$BUILD_DIR/$package_name"
    local install_flag="${2:-false}"

    if [[ ! -d "$build_path" ]]; then
        print_error "Package directory not found: $build_path"
        print_info "Run: $0 clone $package_name"
        return 1
    fi

    print_header "Building AUR Package: $package_name"

    cd "$build_path"

    # Show PKGBUILD info
    if [[ -f "PKGBUILD" ]]; then
        print_info "Package information:"
        grep -E "^(pkgname|pkgver|pkgrel|pkgdesc)" PKGBUILD || true
    fi

    # Build package
    print_info "Building package..."
    if makepkg -s --noconfirm; then
        print_status "Package built successfully"

        # Move built packages to package directory
        find . -name "*.pkg.tar.*" -exec mv {} "$PKG_DIR/" \;

        # Install if requested
        if [[ "$install_flag" == "true" ]]; then
            print_info "Installing package..."
            if makepkg -si --noconfirm; then
                print_status "Package installed successfully"
            else
                print_error "Failed to install package"
                return 1
            fi
        fi

        return 0
    else
        print_error "Failed to build package"
        return 1
    fi
}

# Build multiple packages
build_package_list() {
    local list_file="$1"
    local install_flag="${2:-false}"

    if [[ ! -f "$list_file" ]]; then
        print_error "Package list not found: $list_file"
        return 1
    fi

    print_header "Building Packages from List: $(basename "$list_file")"

    local packages=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Extract package name (first word)
        local package=$(echo "$line" | awk '{print $1}')
        [[ -n "$package" ]] && packages+=("$package")
    done < "$list_file"

    print_info "Found ${#packages[@]} packages to build"

    local success_count=0
    local fail_count=0

    for package in "${packages[@]}"; do
        print_info "Processing package: $package"

        if clone_aur_package "$package" && build_aur_package "$package" "$install_flag"; then
            ((success_count++))
            print_status "Successfully processed $package"
        else
            ((fail_count++))
            print_error "Failed to process $package"
        fi

        echo
    done

    print_header "Build Summary"
    print_info "Total packages: ${#packages[@]}"
    print_status "Successful builds: $success_count"
    [[ $fail_count -gt 0 ]] && print_error "Failed builds: $fail_count"

    return $fail_count
}

# Update existing packages
update_packages() {
    print_header "Updating AUR Packages"

    if [[ ! -d "$BUILD_DIR" ]] || [[ -z "$(ls -A "$BUILD_DIR" 2>/dev/null)" ]]; then
        print_warning "No packages found to update"
        return 0
    fi

    for package_dir in "$BUILD_DIR"/*; do
        if [[ -d "$package_dir" ]]; then
            local package_name=$(basename "$package_dir")
            print_info "Updating $package_name..."

            cd "$package_dir"

            # Pull latest changes
            if git pull; then
                # Check if PKGBUILD changed
                if git diff --name-only HEAD~1 HEAD | grep -q PKGBUILD; then
                    print_info "PKGBUILD updated, rebuilding..."
                    if build_aur_package "$package_name"; then
                        print_status "Updated $package_name"
                    else
                        print_error "Failed to update $package_name"
                    fi
                else
                    print_info "No changes for $package_name"
                fi
            else
                print_error "Failed to update $package_name"
            fi
        fi
    done
}

# Clean build environment
clean_builds() {
    print_header "Cleaning Build Environment"

    print_info "Removing build directories..."
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "${BUILD_DIR:?}"/*
        print_status "Build directories cleaned"
    fi

    print_info "Removing old package files..."
    if [[ -d "$PKG_DIR" ]]; then
        find "$PKG_DIR" -name "*.pkg.tar.*" -mtime +7 -delete
        print_status "Old package files cleaned"
    fi
}

# List built packages
list_built_packages() {
    print_header "Built Packages"

    if [[ ! -d "$PKG_DIR" ]] || [[ -z "$(ls -A "$PKG_DIR" 2>/dev/null)" ]]; then
        print_info "No built packages found"
        return 0
    fi

    print_info "Available package files:"
    ls -lh "$PKG_DIR"/*.pkg.tar.* 2>/dev/null | while read -r line; do
        echo "  $line"
    done
}

# Install built package
install_built_package() {
    local package_pattern="$1"

    local package_files=()
    while IFS= read -r -d '' file; do
        package_files+=("$file")
    done < <(find "$PKG_DIR" -name "*$package_pattern*.pkg.tar.*" -print0 2>/dev/null)

    if [[ ${#package_files[@]} -eq 0 ]]; then
        print_error "No built packages found matching: $package_pattern"
        print_info "Available packages:"
        list_built_packages
        return 1
    fi

    if [[ ${#package_files[@]} -gt 1 ]]; then
        print_warning "Multiple packages found:"
        for pkg in "${package_files[@]}"; do
            echo "  $(basename "$pkg")"
        done
        read -p "Enter exact filename to install: " selected_pkg

        local full_path="$PKG_DIR/$selected_pkg"
        if [[ ! -f "$full_path" ]]; then
            print_error "File not found: $selected_pkg"
            return 1
        fi
        package_files=("$full_path")
    fi

    local package_file="${package_files[0]}"
    print_info "Installing: $(basename "$package_file")"

    if sudo pacman -U --noconfirm "$package_file"; then
        print_status "Package installed successfully"
    else
        print_error "Failed to install package"
        return 1
    fi
}

# Create custom PKGBUILD
create_custom_pkgbuild() {
    local package_name="$1"
    local package_dir="$BUILD_DIR/$package_name"

    print_header "Creating Custom PKGBUILD: $package_name"

    mkdir -p "$package_dir"
    cd "$package_dir"

    # Interactive PKGBUILD creation
    read -p "Package version: " pkgver
    read -p "Package description: " pkgdesc
    read -p "Source URL: " source_url
    read -p "License: " license
    read -p "Dependencies (space-separated): " depends

    cat > PKGBUILD << EOF
# Maintainer: xanadOS Team
pkgname=$package_name
pkgver=$pkgver
pkgrel=1
pkgdesc="$pkgdesc"
arch=('x86_64')
url="$source_url"
license=('$license')
depends=(${depends})
source=("\$pkgname-\$pkgver.tar.gz::$source_url")
sha256sums=('SKIP')

build() {
    cd "\$pkgname-\$pkgver"
    # Add build commands here
    echo "Building \$pkgname..."
}

package() {
    cd "\$pkgname-\$pkgver"
    # Add package commands here
    echo "Packaging \$pkgname..."
}
EOF

    print_status "PKGBUILD created at: $package_dir/PKGBUILD"
    print_info "Edit the PKGBUILD file to customize the build process"

    # Open in editor if available
    if command -v nano &>/dev/null; then
        read -p "Open in editor? (y/N): " edit_choice
        if [[ "$edit_choice" =~ ^[Yy] ]]; then
            nano PKGBUILD
        fi
    fi
}

# Batch build from xanadOS package lists
batch_build_xanados() {
    print_header "Batch Building xanadOS Packages"

    local categories=("gaming" "development" "optional")

    for category in "${categories[@]}"; do
        local list_file="$PROJECT_ROOT/packages/aur/$category.list"
        if [[ -f "$list_file" ]]; then
            print_info "Building $category packages..."
            build_package_list "$list_file" false
        else
            print_warning "Package list not found: $list_file"
        fi
    done
}

# Show build statistics
show_statistics() {
    print_header "Build Statistics"

    # Count built packages
    local built_count=0
    if [[ -d "$PKG_DIR" ]]; then
        built_count=$(find "$PKG_DIR" -name "*.pkg.tar.*" 2>/dev/null | wc -l)
    fi

    # Count cloned packages
    local cloned_count=0
    if [[ -d "$BUILD_DIR" ]]; then
        cloned_count=$(find "$BUILD_DIR" -maxdepth 1 -type d | tail -n +2 | wc -l)
    fi

    echo "Build environment statistics:"
    echo "  Cloned packages: $cloned_count"
    echo "  Built packages: $built_count"
    echo "  Build directory: $BUILD_DIR"
    echo "  Package directory: $PKG_DIR"

    # Disk usage
    if [[ -d "$BUILD_DIR" ]]; then
        local build_size=$(du -sh "$BUILD_DIR" 2>/dev/null | cut -f1)
        echo "  Build directory size: $build_size"
    fi

    if [[ -d "$PKG_DIR" ]]; then
        local pkg_size=$(du -sh "$PKG_DIR" 2>/dev/null | cut -f1)
        echo "  Package directory size: $pkg_size"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
xanadOS AUR Package Builder

USAGE:
    aur-builder.sh <command> [options]

COMMANDS:
    clone <package>         Clone AUR package source
    build <package>         Build AUR package
    install <package>       Build and install AUR package

    build-list <file>       Build all packages from list file
    install-list <file>     Build and install all packages from list

    update                  Update all cloned packages
    clean                   Clean build environment

    list                    List built packages
    install-built <pattern> Install previously built package

    create <name>           Create custom PKGBUILD
    batch-xanados           Build all xanadOS AUR packages

    stats                   Show build statistics
    help                    Show this help message

EXAMPLES:
    # Clone and build a package
    ./aur-builder.sh clone discord
    ./aur-builder.sh build discord

    # Build and install in one step
    ./aur-builder.sh install discord

    # Build all gaming packages
    ./aur-builder.sh build-list ../packages/aur/gaming.list

    # Install previously built package
    ./aur-builder.sh install-built discord

    # Update all cloned packages
    ./aur-builder.sh update

    # Clean build environment
    ./aur-builder.sh clean

    # Build all xanadOS packages
    ./aur-builder.sh batch-xanados

DIRECTORIES:
    Build cache: ~/.cache/xanados-aur/builds/
    Built packages: ~/.cache/xanados-aur/packages/
    Logs: ~/.cache/xanados-aur/builder.log

NOTES:
    - Requires makepkg and git
    - Built packages are cached for later installation
    - Use 'build-list' for batch building from package lists
    - 'batch-xanados' builds all packages from xanadOS lists
EOF
}

# Main function
main() {
    case "${1:-help}" in
        "clone")
            if [[ $# -lt 2 ]]; then
                print_error "Package name required"
                exit 1
            fi
            clone_aur_package "$2"
            ;;
        "build")
            if [[ $# -lt 2 ]]; then
                print_error "Package name required"
                exit 1
            fi
            build_aur_package "$2"
            ;;
        "install")
            if [[ $# -lt 2 ]]; then
                print_error "Package name required"
                exit 1
            fi
            clone_aur_package "$2" && build_aur_package "$2" true
            ;;
        "build-list")
            if [[ $# -lt 2 ]]; then
                print_error "List file required"
                exit 1
            fi
            build_package_list "$2"
            ;;
        "install-list")
            if [[ $# -lt 2 ]]; then
                print_error "List file required"
                exit 1
            fi
            build_package_list "$2" true
            ;;
        "update")
            update_packages
            ;;
        "clean")
            clean_builds
            ;;
        "list")
            list_built_packages
            ;;
        "install-built")
            if [[ $# -lt 2 ]]; then
                print_error "Package pattern required"
                exit 1
            fi
            install_built_package "$2"
            ;;
        "create")
            if [[ $# -lt 2 ]]; then
                print_error "Package name required"
                exit 1
            fi
            create_custom_pkgbuild "$2"
            ;;
        "batch-xanados")
            batch_build_xanados
            ;;
        "stats")
            show_statistics
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
