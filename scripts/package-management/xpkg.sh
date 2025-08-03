#!/bin/bash
# xanadOS Unified Package Manager
# Single interface using paru for all package operations (official repos + AUR)

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly PACKAGES_DIR="$PROJECT_ROOT/packages"
readonly CACHE_DIR="$HOME/.cache/xanados-packages"
readonly CONFIG_DIR="$HOME/.config/xanados"
readonly LOG_FILE="$CACHE_DIR/package-manager.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Create required directories
mkdir -p "$CACHE_DIR" "$CONFIG_DIR"

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
    log "STATUS: $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
    log "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
    log "INFO: $1"
}

print_header() {
    echo -e "\n${PURPLE}═══ $1 ═══${NC}\n"
    log "HEADER: $1"
}

print_subheader() {
    echo -e "\n${CYAN}── $1 ──${NC}\n"
    log "SUBHEADER: $1"
}

# Unified package command using paru
pkg() {
    local cmd="$1"
    shift

    case "$cmd" in
        "install"|"i")
            paru -S --needed --noconfirm "$@"
            ;;
        "update"|"u")
            paru -Syu --noconfirm "$@"
            ;;
        "remove"|"r")
            paru -Rs --noconfirm "$@"
            ;;
        "search"|"s")
            paru -Ss "$@"
            ;;
        "info")
            paru -Si "$@"
            ;;
        "list"|"l")
            paru -Q "$@"
            ;;
        "clean"|"c")
            paru -Sc --noconfirm "$@"
            ;;
        "refresh")
            paru -Sy "$@"
            ;;
        *)
            print_error "Unknown package command: $cmd"
            print_info "Available commands: install, update, remove, search, info, list, clean, refresh"
            return 1
            ;;
    esac
}

# Check and install paru if needed
ensure_paru() {
    if command -v paru &>/dev/null; then
        print_info "Paru already installed"
        return 0
    fi

    print_header "Installing Paru AUR Helper"

    # Check for pacman as fallback
    if ! command -v pacman &>/dev/null; then
        print_error "Neither paru nor pacman found. Cannot proceed."
        exit 1
    fi

    # Install dependencies
    print_info "Installing paru dependencies..."
    sudo pacman -S --needed --noconfirm git base-devel rust

    # Clone and build paru
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    print_info "Cloning paru repository..."
    git clone https://aur.archlinux.org/paru.git
    cd paru

    print_info "Building paru..."
    makepkg -si --noconfirm

    cd "$PROJECT_ROOT"
    rm -rf "$temp_dir"

    print_status "Paru installed successfully"

    # Configure paru for optimal gaming performance
    configure_paru
}

# Configure paru for gaming optimization
configure_paru() {
    print_info "Configuring paru for gaming optimization..."

    local paru_config="$HOME/.config/paru/paru.conf"
    mkdir -p "$(dirname "$paru_config")"

    cat > "$paru_config" << 'EOF'
# xanadOS Paru Configuration
# Optimized for gaming distribution

[options]
# Performance optimizations
BottomUp
Devel
Provides
DevelSuffixes = -git -cvs -svn -bzr -darcs -always

# Gaming-specific settings
BatchInstall
CombinedUpgrade
UpgradeMenu
NewsOnUpgrade

# Build optimizations
UseAsk
SaveChanges
FailFast
Sudo

# Parallel builds for faster compilation
[bin]
# Use all available cores for compilation
MFlags = -j$(nproc)

# Optimized compiler flags for gaming
CFlags = -march=native -O2 -pipe -fno-plt
CxxFlags = -march=native -O2 -pipe -fno-plt
LdFlags = -Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now

# Gaming-focused makepkg configuration
Packager = xanadOS Gaming Distribution
CompressXZ = --threads=0
CompressZST = --threads=0
EOF

    print_status "Paru configured for gaming optimization"
}

# Hardware detection
detect_hardware() {
    print_subheader "Hardware Detection"

    local gpu_vendor=""
    local cpu_vendor=""
    local detected_hardware=()

    # Detect GPU
    if lspci | grep -i "vga\|3d\|2d" | grep -qi nvidia; then
        gpu_vendor="nvidia"
        detected_hardware+=("nvidia")
        print_info "NVIDIA GPU detected"
    elif lspci | grep -i "vga\|3d\|2d" | grep -qi "amd\|ati"; then
        gpu_vendor="amd"
        detected_hardware+=("amd")
        print_info "AMD GPU detected"
    elif lspci | grep -i "vga\|3d\|2d" | grep -qi intel; then
        gpu_vendor="intel"
        detected_hardware+=("intel")
        print_info "Intel GPU detected"
    fi

    # Detect CPU
    if grep -qi "intel" /proc/cpuinfo; then
        cpu_vendor="intel"
        if [[ ! " ${detected_hardware[*]} " =~ " intel " ]]; then
            detected_hardware+=("intel")
        fi
        print_info "Intel CPU detected"
    elif grep -qi "amd" /proc/cpuinfo; then
        cpu_vendor="amd"
        if [[ ! " ${detected_hardware[*]} " =~ " amd " ]]; then
            detected_hardware+=("amd")
        fi
        print_info "AMD CPU detected"
    fi

    # Save hardware configuration
    cat > "$CONFIG_DIR/hardware.conf" << EOF
GPU_VENDOR="$gpu_vendor"
CPU_VENDOR="$cpu_vendor"
DETECTED_HARDWARE=(${detected_hardware[*]})
DETECTION_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
EOF

    print_status "Hardware detection complete"
    echo "Detected hardware: ${detected_hardware[*]}"
}

# Load package list from file
load_package_list() {
    local list_file="$1"

    if [[ ! -f "$list_file" ]]; then
        print_error "Package list not found: $list_file"
        return 1
    fi

    # Parse package list (ignore comments and empty lines)
    grep -v '^#' "$list_file" | grep -v '^$' | awk '{print $1}' | sort -u
}

# Install packages from list using paru
install_package_list() {
    local list_file="$1"
    local packages

    print_info "Loading packages from: $(basename "$list_file")"

    if ! packages=$(load_package_list "$list_file"); then
        return 1
    fi

    local package_array=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && package_array+=("$package")
    done <<< "$packages"

    if [[ ${#package_array[@]} -eq 0 ]]; then
        print_warning "No packages found in list"
        return 0
    fi

    print_info "Found ${#package_array[@]} packages to install"

    # Install packages with paru (handles both official repos and AUR)
    if pkg install "${package_array[@]}"; then
        print_status "Successfully installed packages from $(basename "$list_file")"

        # Log successful installation
        echo "INSTALLED_$(date +%s): $(basename "$list_file"): ${#package_array[@]} packages" >> "$CONFIG_DIR/install_history.log"
    else
        print_error "Failed to install some packages from $(basename "$list_file")"
        return 1
    fi
}

# Install all packages from category
install_all_packages() {
    local category="$1"

    print_header "Installing All $category Packages"

    case "$category" in
        "core")
            for list in "$PACKAGES_DIR/core"/*.list; do
                [[ -f "$list" ]] && install_package_list "$list"
            done
            ;;
        "aur")
            for list in "$PACKAGES_DIR/aur"/*.list; do
                [[ -f "$list" ]] && install_package_list "$list"
            done
            ;;
        "hardware")
            install_hardware_packages
            ;;
        "profiles")
            print_info "Available profiles:"
            list_available_profiles
            read -p "Select profile to install: " selected_profile
            install_profile_packages "$selected_profile"
            ;;
        "everything")
            install_all_packages "core"
            install_all_packages "aur"
            install_hardware_packages
            ;;
        *)
            print_error "Unknown category: $category"
            print_info "Available categories: core, aur, hardware, profiles, everything"
            return 1
            ;;
    esac
}

# Install hardware-specific packages
install_hardware_packages() {
    print_header "Installing Hardware-Specific Packages"

    # Load hardware configuration
    if [[ -f "$CONFIG_DIR/hardware.conf" ]]; then
        source "$CONFIG_DIR/hardware.conf"
    else
        print_warning "No hardware configuration found, running detection..."
        detect_hardware
        source "$CONFIG_DIR/hardware.conf"
    fi

    # Install packages for detected hardware
    for hw in "${DETECTED_HARDWARE[@]}"; do
        local hw_list="$PACKAGES_DIR/hardware/$hw.list"
        if [[ -f "$hw_list" ]]; then
            print_info "Installing $hw hardware packages..."
            install_package_list "$hw_list" || print_warning "Some $hw packages failed to install"
        else
            print_warning "No package list found for $hw hardware"
        fi
    done
}

# Install profile packages
install_profile_packages() {
    local profile="$1"

    print_header "Installing Profile Packages: $profile"

    local profile_list="$PACKAGES_DIR/profiles/$profile.list"
    if [[ -f "$profile_list" ]]; then
        install_package_list "$profile_list"
    else
        print_error "Profile not found: $profile"
        list_available_profiles
        return 1
    fi
}

# List available profiles
list_available_profiles() {
    print_info "Available profiles:"
    if [[ -d "$PACKAGES_DIR/profiles" ]]; then
        for profile in "$PACKAGES_DIR/profiles"/*.list; do
            if [[ -f "$profile" ]]; then
                local name=$(basename "$profile" .list)
                local count=$(load_package_list "$profile" | wc -l)
                echo "  - $name ($count packages)"
            fi
        done
    else
        print_warning "No profiles directory found"
    fi
}

# Interactive gaming setup
gaming_setup_wizard() {
    print_header "xanadOS Gaming Setup Wizard"

    echo "🎮 Welcome to xanadOS Gaming Setup!"
    echo
    echo "This wizard will set up your complete gaming environment."
    echo "All packages will be installed using paru for optimal performance."
    echo

    # Hardware detection
    detect_hardware
    echo

    # Gaming setup options
    echo "Select your gaming setup type:"
    echo "1) 🏆 Competitive Esports (CS2, Valorant, League of Legends)"
    echo "2) 🎥 Content Creator & Streaming (OBS, editing tools)"
    echo "3) 🛠️  Game Developer (engines, IDEs, dev tools)"
    echo "4) 🎮 Casual Gaming (Steam, Lutris, general gaming)"
    echo "5) 🚀 Everything (complete gaming distribution)"
    echo "6) 📋 Custom selection"
    echo "0) Exit"

    read -p "Enter your choice (0-6): " setup_choice

    case "$setup_choice" in
        1)
            print_info "Setting up competitive esports environment..."
            install_package_list "$PACKAGES_DIR/core/gaming.list"
            install_package_list "$PACKAGES_DIR/aur/gaming.list"
            install_profile_packages "esports"
            install_hardware_packages
            ;;
        2)
            print_info "Setting up content creation environment..."
            install_package_list "$PACKAGES_DIR/core/gaming.list"
            install_package_list "$PACKAGES_DIR/aur/gaming.list"
            install_profile_packages "streaming"
            install_hardware_packages
            ;;
        3)
            print_info "Setting up game development environment..."
            install_package_list "$PACKAGES_DIR/aur/development.list"
            install_profile_packages "development"
            install_hardware_packages
            ;;
        4)
            print_info "Setting up casual gaming environment..."
            install_package_list "$PACKAGES_DIR/core/gaming.list"
            install_package_list "$PACKAGES_DIR/aur/gaming.list"
            install_hardware_packages
            ;;
        5)
            print_info "Setting up complete gaming distribution..."
            install_all_packages "everything"
            ;;
        6)
            custom_package_selection
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            gaming_setup_wizard
            ;;
    esac

    print_header "🎉 Gaming Setup Complete!"
    print_status "Your xanadOS gaming environment is ready!"
    print_info "Reboot your system to ensure all drivers and optimizations are active."
}

# Custom package selection
custom_package_selection() {
    print_header "Custom Package Selection"

    echo "Available package categories:"
    echo
    echo "Core packages:"
    for list in "$PACKAGES_DIR/core"/*.list; do
        if [[ -f "$list" ]]; then
            local name=$(basename "$list" .list)
            local count=$(load_package_list "$list" | wc -l)
            echo "  core/$name ($count packages)"
        fi
    done

    echo
    echo "AUR packages:"
    for list in "$PACKAGES_DIR/aur"/*.list; do
        if [[ -f "$list" ]]; then
            local name=$(basename "$list" .list)
            local count=$(load_package_list "$list" | wc -l)
            echo "  aur/$name ($count packages)"
        fi
    done

    echo
    echo "Profiles:"
    list_available_profiles

    echo
    echo "Hardware: (auto-detected based on your system)"
    echo

    read -p "Enter package categories (space-separated, e.g., 'core/gaming aur/gaming esports'): " -a selections

    for selection in "${selections[@]}"; do
        case "$selection" in
            core/*)
                local core_name="${selection#core/}"
                install_package_list "$PACKAGES_DIR/core/$core_name.list"
                ;;
            aur/*)
                local aur_name="${selection#aur/}"
                install_package_list "$PACKAGES_DIR/aur/$aur_name.list"
                ;;
            hardware)
                install_hardware_packages
                ;;
            *)
                # Try as profile
                if [[ -f "$PACKAGES_DIR/profiles/$selection.list" ]]; then
                    install_profile_packages "$selection"
                else
                    print_error "Unknown selection: $selection"
                fi
                ;;
        esac
    done
}

# System update using paru
system_update() {
    print_header "System Update"

    print_info "Updating package databases..."
    pkg refresh

    print_info "Upgrading all packages (official repos + AUR)..."
    pkg update

    print_status "System update complete"
}

# Clean system
system_clean() {
    print_header "System Cleanup"

    print_info "Cleaning package cache..."
    pkg clean

    print_info "Removing orphaned packages..."
    if paru -Qtdq &>/dev/null; then
        paru -Rs "$(paru -Qtdq)" --noconfirm
        print_status "Orphaned packages removed"
    else
        print_info "No orphaned packages found"
    fi

    # Clean local cache
    print_info "Cleaning local cache..."
    rm -rf "${CACHE_DIR:?}"/*

    print_status "System cleanup complete"
}

# Show package statistics
show_statistics() {
    print_header "Package Statistics"

    # Count packages by category
    echo "📦 Package counts by category:"
    echo

    for category in "$PACKAGES_DIR"/*; do
        if [[ -d "$category" ]]; then
            local cat_name=$(basename "$category")
            echo "  $cat_name packages:"
            for list in "$category"/*.list; do
                if [[ -f "$list" ]]; then
                    local name=$(basename "$list" .list)
                    local count=$(load_package_list "$list" | wc -l)
                    printf "    %-20s %d packages\n" "$name" "$count"
                fi
            done
            echo
        fi
    done

    # Show installed packages
    local total_installed=$(paru -Q | wc -l)
    local aur_installed=$(paru -Qm | wc -l)
    local official_installed=$((total_installed - aur_installed))

    echo "📊 System statistics:"
    echo "  Total installed packages: $total_installed"
    echo "  Official repository packages: $official_installed"
    echo "  AUR packages: $aur_installed"
    echo

    # Show hardware info
    if [[ -f "$CONFIG_DIR/hardware.conf" ]]; then
        source "$CONFIG_DIR/hardware.conf"
        echo "🖥️  Detected hardware: ${DETECTED_HARDWARE[*]}"
        echo "   GPU vendor: $GPU_VENDOR"
        echo "   CPU vendor: $CPU_VENDOR"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
xanadOS Unified Package Manager

DESCRIPTION:
    Single interface using paru for all package operations.
    Handles official repositories and AUR seamlessly with gaming optimizations.

USAGE:
    xpkg <command> [options]

COMMANDS:
    setup                   Launch gaming setup wizard (recommended)
    install <category>      Install packages from category
    profile <name>          Install gaming profile
    hardware               Install hardware-specific packages

    update                 Update all packages (repos + AUR)
    clean                  Clean system and remove orphans
    stats                  Show package statistics

    pkg <cmd> [args]       Direct paru commands:
                          pkg install <packages>
                          pkg search <term>
                          pkg remove <packages>

    detect                 Detect and save hardware configuration
    help                   Show this help

GAMING SETUP:
    setup                  🎮 Interactive gaming environment setup

CATEGORIES:
    core                   Essential system packages
    aur                    AUR gaming and development packages
    hardware               GPU/CPU specific optimizations
    profiles               Complete environment setups
    everything             Install all packages

PROFILES:
    esports                Competitive gaming (CS2, Valorant, etc.)
    streaming              Content creation and streaming
    development            Game development environment

EXAMPLES:
    # Launch gaming setup wizard (recommended for new users)
    xpkg setup

    # Install esports gaming profile
    xpkg profile esports

    # Install hardware optimizations
    xpkg hardware

    # Update entire system
    xpkg update

    # Install specific packages
    xpkg pkg install steam lutris discord

    # Search for packages
    xpkg pkg search gaming

FEATURES:
    ✅ Unified package management (repos + AUR)
    ✅ Gaming-optimized paru configuration
    ✅ Hardware auto-detection
    ✅ One-command environment setup
    ✅ Comprehensive logging
    ✅ Parallel compilation for speed

NOTES:
    - Uses paru as the unified package manager
    - Automatically detects hardware for optimizations
    - Optimized for gaming performance and compilation speed
    - All operations are logged for troubleshooting
EOF
}

# Main function
main() {
    # Ensure paru is installed and configured
    ensure_paru

    # Parse command
    case "${1:-help}" in
        "setup")
            gaming_setup_wizard
            ;;
        "install")
            if [[ $# -lt 2 ]]; then
                print_error "Category name required"
                print_info "Available categories: core, aur, hardware, profiles, everything"
                exit 1
            fi
            install_all_packages "$2"
            ;;
        "profile")
            if [[ $# -lt 2 ]]; then
                print_error "Profile name required"
                list_available_profiles
                exit 1
            fi
            install_profile_packages "$2"
            ;;
        "hardware")
            install_hardware_packages
            ;;
        "update")
            system_update
            ;;
        "clean")
            system_clean
            ;;
        "stats")
            show_statistics
            ;;
        "pkg")
            if [[ $# -lt 2 ]]; then
                print_error "Package command required"
                print_info "Examples: pkg install steam, pkg search discord, pkg remove firefox"
                exit 1
            fi
            shift
            pkg "$@"
            ;;
        "detect")
            detect_hardware
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

# Run main function with all arguments
main "$@"
