#!/bin/bash
# xanadOS AUR Package Manager
# Advanced AUR package management with hardware detection and user profiles

# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh" || {
    echo "Error: Could not source common.sh" >&2
    exit 1
}

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly PACKAGES_DIR="$PROJECT_ROOT/packages"
readonly CACHE_DIR="$HOME/.cache/xanados-aur"
readonly CONFIG_DIR="$HOME/.config/xanados"
readonly LOG_FILE="$CACHE_DIR/aur-manager.log"

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

print_subheader() {
    echo -e "\n${CYAN}── $1 ──${NC}\n"
    log "SUBHEADER: $1"
}

# Check dependencies
check_dependencies() {
    local deps=("paru" "git" "curl" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Installing missing dependencies..."

        # Install paru if missing
        if [[ " ${missing[*]} " =~ " paru " ]]; then
            install_paru
        fi

        # Install other dependencies using paru
        for dep in "${missing[@]}"; do
            if [[ "$dep" != "paru" ]]; then
                paru -S --noconfirm "$dep" || {
                    print_error "Failed to install $dep"
                    exit 1
                }
            fi
        done
    fi
}

# Install paru AUR helper
install_paru() {
    print_info "Installing paru AUR helper..."

    # Check for pacman as fallback for initial installation
    if ! command -v pacman &>/dev/null; then
        print_error "Neither paru nor pacman found. Cannot proceed."
        exit 1
    fi

    # Install dependencies
    print_info "Installing paru dependencies..."
    sudo pacman -S --needed --noconfirm git base-devel rust

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    print_info "Cloning paru repository..."
    git clone https://aur.archlinux.org/paru.git
    cd paru

    print_info "Building paru..."
    makepkg -si --noconfirm

    cd "$PROJECT_ROOT"
    rm -rf "$temp_dir"

    print_status "paru installed successfully"

    # Configure paru for gaming optimization
    configure_paru_for_gaming
}

# Configure paru for gaming optimization
configure_paru_for_gaming() {
    print_info "Configuring paru for gaming optimization..."

    local paru_config="$HOME/.config/paru/paru.conf"
    mkdir -p "$(dirname "$paru_config")"

    cat > "$paru_config" << 'PARU_EOF'
# xanadOS Paru Configuration - Gaming Optimized
[options]
BottomUp
Devel
Provides
DevelSuffixes = -git -cvs -svn -bzr -darcs -always
BatchInstall
CombinedUpgrade
UpgradeMenu
NewsOnUpgrade
UseAsk
SaveChanges
FailFast
Sudo

[bin]
# Use all available cores for compilation
MFlags = -j$(nproc)
# Gaming-optimized compiler flags
CFlags = -march=native -O2 -pipe -fno-plt
CxxFlags = -march=native -O2 -pipe -fno-plt
LdFlags = -Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now
PARU_EOF

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

# Install packages from list
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

    # Install packages with paru
    if paru -S --noconfirm --needed "${package_array[@]}"; then
        print_status "Successfully installed packages from $(basename "$list_file")"

        # Log successful installation
        echo "INSTALLED_$(date +%s): $(basename "$list_file"): ${#package_array[@]} packages" >> "$CONFIG_DIR/install_history.log"
    else
        print_error "Failed to install some packages from $(basename "$list_file")"
        return 1
    fi
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

# Install AUR category packages
install_aur_packages() {
    local category="$1"

    print_header "Installing AUR Packages: $category"

    local aur_list="$PACKAGES_DIR/aur/$category.list"
    if [[ -f "$aur_list" ]]; then
        install_package_list "$aur_list"
    else
        print_error "AUR category not found: $category"
        list_available_aur_categories
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

# List available AUR categories
list_available_aur_categories() {
    print_info "Available AUR categories:"
    if [[ -d "$PACKAGES_DIR/aur" ]]; then
        for category in "$PACKAGES_DIR/aur"/*.list; do
            if [[ -f "$category" ]]; then
                local name=$(basename "$category" .list)
                local count=$(load_package_list "$category" | wc -l)
                echo "  - $name ($count packages)"
            fi
        done
    else
        print_warning "No AUR directory found"
    fi
}

# List available hardware packages
list_available_hardware() {
    print_info "Available hardware packages:"
    if [[ -d "$PACKAGES_DIR/hardware" ]]; then
        for hw in "$PACKAGES_DIR/hardware"/*.list; do
            if [[ -f "$hw" ]]; then
                local name=$(basename "$hw" .list)
                local count=$(load_package_list "$hw" | wc -l)
                echo "  - $name ($count packages)"
            fi
        done
    else
        print_warning "No hardware directory found"
    fi
}

# Interactive package selection
interactive_install() {
    print_header "Interactive Package Installation"

    echo "Select installation type:"
    echo "1) Hardware-specific packages (auto-detected)"
    echo "2) Gaming profile"
    echo "3) Development profile"
    echo "4) Streaming profile"
    echo "5) Esports profile"
    echo "6) AUR gaming packages"
    echo "7) AUR development packages"
    echo "8) AUR optional packages"
    echo "9) Custom selection"
    echo "0) Exit"

    read -p "Enter your choice (0-9): " choice

    case "$choice" in
        1) install_hardware_packages ;;
        2) install_profile_packages "gaming" ;;
        3) install_profile_packages "development" ;;
        4) install_profile_packages "streaming" ;;
        5) install_profile_packages "esports" ;;
        6) install_aur_packages "gaming" ;;
        7) install_aur_packages "development" ;;
        8) install_aur_packages "optional" ;;
        9) custom_selection ;;
        0) exit 0 ;;
        *) print_error "Invalid choice"; interactive_install ;;
    esac
}

# Custom package selection
custom_selection() {
    print_header "Custom Package Selection"

    print_info "Available package categories:"
    echo

    echo "Profiles:"
    list_available_profiles
    echo

    echo "AUR Categories:"
    list_available_aur_categories
    echo

    echo "Hardware Packages:"
    list_available_hardware
    echo

    read -p "Enter package list names (space-separated): " -a selections

    for selection in "${selections[@]}"; do
        # Try profiles first
        if [[ -f "$PACKAGES_DIR/profiles/$selection.list" ]]; then
            install_profile_packages "$selection"
        # Try AUR categories
        elif [[ -f "$PACKAGES_DIR/aur/$selection.list" ]]; then
            install_aur_packages "$selection"
        # Try hardware packages
        elif [[ -f "$PACKAGES_DIR/hardware/$selection.list" ]]; then
            print_info "Installing $selection hardware packages..."
            install_package_list "$PACKAGES_DIR/hardware/$selection.list"
        else
            print_error "Package list not found: $selection"
        fi
    done
}

# Update AUR packages
update_aur_packages() {
    print_header "Updating AUR Packages"

    print_info "Updating package database..."
    paru -Sy

    print_info "Upgrading all packages (official repos + AUR)..."
    paru -Syu --noconfirm

    print_status "All packages updated"
}

# Clean package cache
clean_cache() {
    print_header "Cleaning Package Cache"

    # Clean paru cache (handles both official repos and AUR)
    print_info "Cleaning paru cache..."
    paru -Sc --noconfirm

    # Clean local cache
    print_info "Cleaning local cache..."
    rm -rf "${CACHE_DIR:?}"/*

    print_status "Cache cleaned"
}

# Show package statistics
show_statistics() {
    print_header "Package Statistics"

    # Count packages by category
    echo "Package counts by category:"
    echo

    for category in "$PACKAGES_DIR"/*/*.list; do
        if [[ -f "$category" ]]; then
            local name=$(basename "$category" .list)
            local dir=$(basename "$(dirname "$category")")
            local count=$(load_package_list "$category" | wc -l)
            printf "  %-20s %-15s %d packages\n" "$dir/$name" "" "$count"
        fi
    done

    echo

    # Show installed AUR packages
    local aur_count=$(paru -Qm | wc -l)
    echo "Currently installed AUR packages: $aur_count"

    # Show system information
    echo
    echo "System information:"
    echo "  Total packages: $(paru -Q | wc -l)"
    echo "  AUR packages: $aur_count"
    echo "  Official packages: $(($(paru -Q | wc -l) - aur_count))"
}

# Backup installed packages
backup_packages() {
    local backup_file="$1"

    print_header "Backing Up Package Lists"

    local backup_dir=$(dirname "$backup_file")
    mkdir -p "$backup_dir"

    # Create backup
    {
        echo "# xanadOS Package Backup - $(date)"
        echo "# Generated by xanadOS AUR Manager"
        echo
        echo "# Official packages:"
        pacman -Qqe | grep -v "$(pacman -Qqm)"
        echo
        echo "# AUR packages:"
        pacman -Qqm
    } > "$backup_file"

    print_status "Package list backed up to: $backup_file"
}

# Restore packages from backup
restore_packages() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi

    print_header "Restoring Packages from Backup"

    # Extract package lists
    local official_packages=$(grep -v '^#' "$backup_file" | grep -v '^$' | head -n -1)
    local aur_packages=$(grep -v '^#' "$backup_file" | grep -v '^$' | tail -n +2)

    # Install official packages
    if [[ -n "$official_packages" ]]; then
        print_info "Installing official packages..."
        echo "$official_packages" | sudo pacman -S --needed -
    fi

    # Install AUR packages
    if [[ -n "$aur_packages" ]]; then
        print_info "Installing AUR packages..."
        echo "$aur_packages" | paru -S --needed -
    fi

    print_status "Package restoration complete"
}

# Show help
show_help() {
    cat << 'EOF'
xanadOS AUR Package Manager

USAGE:
    aur-manager.sh <command> [options]

COMMANDS:
    install <category>      Install packages from specific category
    profile <name>          Install packages for specific profile
    hardware               Install hardware-specific packages (auto-detected)
    interactive            Interactive package installation
    update                 Update all AUR packages
    clean                  Clean package cache
    stats                  Show package statistics
    backup <file>          Backup installed packages to file
    restore <file>         Restore packages from backup file
    list                   List available package categories
    detect                 Detect and configure hardware
    help                   Show this help message

CATEGORIES:
    AUR Categories:
      gaming               Gaming packages from AUR
      development          Development tools from AUR
      optional             Optional enhancement packages

    Profiles:
      esports              Competitive gaming setup
      streaming            Content creation and streaming
      development          Game development environment

    Hardware:
      nvidia               NVIDIA GPU optimizations
      amd                  AMD GPU/CPU optimizations
      intel                Intel CPU/GPU optimizations

EXAMPLES:
    # Interactive installation
    ./aur-manager.sh interactive

    # Install gaming packages
    ./aur-manager.sh install gaming

    # Install esports profile
    ./aur-manager.sh profile esports

    # Install hardware-specific packages
    ./aur-manager.sh hardware

    # Update all AUR packages
    ./aur-manager.sh update

    # Show statistics
    ./aur-manager.sh stats

    # Backup packages
    ./aur-manager.sh backup ~/.config/xanados/package-backup.txt

    # Clean cache
    ./aur-manager.sh clean

CONFIGURATION:
    Configuration files are stored in: ~/.config/xanados/
    Cache files are stored in: ~/.cache/xanados-aur/
    Logs are written to: ~/.cache/xanados-aur/aur-manager.log

NOTES:
    - Requires paru AUR helper (will be installed automatically)
    - Hardware detection runs automatically on first use
    - All installations are logged for tracking
    - Use 'interactive' mode for guided installation
EOF
}

# Main function
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root"
        exit 1
    fi

    # Check dependencies
    check_dependencies

    # Parse command
    case "${1:-help}" in
        "install")
            if [[ $# -lt 2 ]]; then
                print_error "Category name required"
                print_info "Available categories:"
                list_available_aur_categories
                exit 1
            fi
            install_aur_packages "$2"
            ;;
        "profile")
            if [[ $# -lt 2 ]]; then
                print_error "Profile name required"
                print_info "Available profiles:"
                list_available_profiles
                exit 1
            fi
            install_profile_packages "$2"
            ;;
        "hardware")
            install_hardware_packages
            ;;
        "interactive")
            interactive_install
            ;;
        "update")
            update_aur_packages
            ;;
        "clean")
            clean_cache
            ;;
        "stats")
            show_statistics
            ;;
        "backup")
            if [[ $# -lt 2 ]]; then
                print_error "Backup file path required"
                exit 1
            fi
            backup_packages "$2"
            ;;
        "restore")
            if [[ $# -lt 2 ]]; then
                print_error "Backup file path required"
                exit 1
            fi
            restore_packages "$2"
            ;;
        "list")
            echo "Available package categories:"
            echo
            echo "AUR Categories:"
            list_available_aur_categories
            echo
            echo "Profiles:"
            list_available_profiles
            echo
            echo "Hardware:"
            list_available_hardware
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
