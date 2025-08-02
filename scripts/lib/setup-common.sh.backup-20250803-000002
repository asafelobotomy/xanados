#!/bin/bash
# ============================================================================
# xanadOS Shared Setup Library
# Common functions and utilities for all setup scripts
# ============================================================================

# Prevent multiple sourcing
[[ -n "${XANADOS_SETUP_COMMON_LOADED:-}" ]] && return 0
readonly XANADOS_SETUP_COMMON_LOADED=1

# Source existing common utilities for colors and base functions
SCRIPT_DIR_COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_COMMON/common.sh" 2>/dev/null || {
    # Fallback color definitions if common.sh not available
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[0;37m'
    readonly GRAY='\033[0;90m'
    readonly NC='\033[0m'
}

# ============================================================================
# Standardized Logging Setup
# ============================================================================
setup_standard_logging() {
    local script_name="$1"
    local log_dir="/var/log/xanados"
    
    # Try system log directory first
    if sudo mkdir -p "$log_dir" 2>/dev/null && sudo chown "$USER:$USER" "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/${script_name}.log"
    else
        # Fallback to user directory
        log_dir="$HOME/.local/share/xanados/logs"
        mkdir -p "$log_dir"
        LOG_FILE="$log_dir/${script_name}.log"
    fi
    
    # Initialize log file
    {
        echo "========================================================"
        echo "xanadOS ${script_name^} Started: $(date)"
        echo "========================================================"
    } >> "$LOG_FILE"
    
    export LOG_FILE
    readonly LOG_FILE
    
    print_info "Logging to: $LOG_FILE"
}

# ============================================================================
# Logging Functions - Use common.sh print functions to avoid conflicts
# ============================================================================
# Note: Using print functions from common.sh instead of creating duplicates
# If advanced logging is needed, use logging.sh library separately

setup_log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "${LOG_FILE:-/dev/stdout}"
}

# ============================================================================
# Common Argument Parsing
# ============================================================================
parse_common_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-checks)
                SKIP_CHECKS=true
                shift
                ;;
            --config-only)
                CONFIG_ONLY=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_warn "Unknown option: $1"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Export common variables
    export SHOW_HELP VERBOSE QUIET FORCE DRY_RUN SKIP_CHECKS CONFIG_ONLY
}

# ============================================================================
# Standardized Banner Function
# ============================================================================
print_standard_banner() {
    local title="$1"
    local subtitle="$2"
    local icon="${3:-🎮}"
    
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    printf "█         %s %-44s %s         █\n" "$icon" "$title" "$icon"
    echo "█                                                              █"
    printf "█        %-52s        █\n" "$subtitle"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

# ============================================================================
# Standardized Package Installation
# ============================================================================
install_packages_with_fallback() {
    local packages=("$@")
    
    print_info "Installing packages: ${packages[*]}"
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt update -qq || print_warn "Failed to update package lists"
        sudo apt install -y "${packages[@]}" || return 1
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${packages[@]}" || return 1
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm "${packages[@]}" || return 1
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "${packages[@]}" || return 1
    else
        print_error "Unsupported package manager"
        return 1
    fi
    
    print_success "Packages installed successfully"
}

# ============================================================================
# Hardware Detection Cache
# ============================================================================
readonly HARDWARE_CACHE_FILE="/tmp/xanados-hardware-cache-$$"

get_cached_hardware_info() {
    local key="$1"
    
    if [[ ! -f "$HARDWARE_CACHE_FILE" ]]; then
        detect_all_hardware > "$HARDWARE_CACHE_FILE"
    fi
    
    grep "^${key}=" "$HARDWARE_CACHE_FILE" 2>/dev/null | cut -d= -f2- | head -1
}

detect_all_hardware() {
    print_info "Detecting hardware configuration..."
    
    # CPU Information
    echo "cpu_model=$(lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^[ \t]+/, "", $2); print $2}' | head -1)"
    echo "cpu_cores=$(nproc 2>/dev/null || echo 1)"
    echo "cpu_threads=$(lscpu 2>/dev/null | awk -F: '/Thread/ {print $2}' | xargs || echo 1)"
    
    # Memory Information
    echo "memory_gb=$(free -g 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 0)"
    echo "memory_mb=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 0)"
    
    # GPU Information
    echo "gpu_vendor=$(detect_gpu_vendor)"
    echo "gpu_model=$(detect_gpu_model)"
    
    # Storage Information
    echo "has_ssd=$(lsblk -d -o ROTA 2>/dev/null | grep -q 0 && echo true || echo false)"
    
    # Audio System
    echo "audio_system=$(detect_audio_system)"
    
    # Gaming Hardware
    echo "controller_count=$(find /dev/input -name "js*" 2>/dev/null | wc -l)"
    echo "has_controllers=$([ "$(find /dev/input -name "js*" 2>/dev/null | wc -l)" -gt 0 ] && echo true || echo false)"
    
    # Desktop Environment
    echo "desktop_environment=${XDG_CURRENT_DESKTOP:-unknown}"
    echo "kde_session=${KDE_FULL_SESSION:-false}"
    
    # Distribution Information
    echo "distro=$(detect_distribution)"
    echo "distro_version=$(detect_distribution_version)"
}

detect_gpu_vendor() {
    if command -v nvidia-smi &>/dev/null; then
        echo "nvidia"
    elif lspci 2>/dev/null | grep -qi "amd\|ati"; then
        echo "amd"
    elif lspci 2>/dev/null | grep -qi intel; then
        echo "intel"
    else
        echo "unknown"
    fi
}

detect_gpu_model() {
    local gpu_line
    gpu_line=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -1)
    if [[ -n "$gpu_line" ]]; then
        echo "$gpu_line" | sed 's/.*: //'
    else
        echo "Unknown"
    fi
}

detect_audio_system() {
    if systemctl --user is-active pipewire &>/dev/null; then
        echo "pipewire"
    elif systemctl --user is-active pulseaudio &>/dev/null; then
        echo "pulseaudio"
    elif command -v jackd &>/dev/null; then
        echo "jack"
    else
        echo "unknown"
    fi
}

detect_distribution() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

detect_distribution_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Configuration Management
# ============================================================================
create_backup() {
    local source="$1"
    local backup_base="${2:-$HOME/.config/xanados/backups}"
    
    [[ -e "$source" ]] || return 0
    
    local backup_dir
    backup_dir="$backup_base/$(basename "$source")-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -d "$source" ]]; then
        cp -r "$source" "$backup_dir/"
    else
        cp "$source" "$backup_dir/"
    fi
    
    echo "$backup_dir"
    print_info "Backup created: $backup_dir"
}

# ============================================================================
# Service Management
# ============================================================================
manage_service() {
    local action="$1"
    local service="$2"
    local scope="${3:-user}"
    
    systemctl "--$scope" "$action" "$service" &>/dev/null
}

# ============================================================================
# Launcher Creation
# ============================================================================
create_launcher() {
    local name="$1"
    local command="$2"
    local wrapper="${3:-}"
    local description="${4:-xanadOS Gaming Launcher}"
    
    # Create command-line launcher
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/$name" << EOF
#!/bin/bash
# xanadOS Gaming Launcher: $description
exec ${wrapper:+$wrapper } $command "\$@"
EOF
    chmod +x "$HOME/.local/bin/$name"
    
    # Create desktop launcher if in graphical environment
    if [[ -n "${DISPLAY:-}" ]]; then
        mkdir -p "$HOME/.local/share/applications"
        cat > "$HOME/.local/share/applications/$name.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$description
Comment=xanadOS Gaming Launcher
Exec=$HOME/.local/bin/$name
Icon=applications-games
Terminal=false
Categories=Game;
EOF
    fi
    
    print_success "Launcher created: $name"
}

# ============================================================================
# Configuration Generation
# ============================================================================
generate_config() {
    local template_content="$1"
    local output="$2"
    shift 2
    
    # Use associative array for variable substitution
    local -A vars=()
    while [[ $# -gt 1 ]]; do
        vars["$1"]="$2"
        shift 2
    done
    
    local content="$template_content"
    
    # Simple variable substitution
    for key in "${!vars[@]}"; do
        content="${content//\{\{$key\}\}/${vars[$key]}}"
    done
    
    mkdir -p "$(dirname "$output")"
    echo "$content" > "$output"
    print_info "Configuration generated: $output"
}

# ============================================================================
# Status Checking
# ============================================================================
check_installation_status() {
    local -A components=()
    
    # Parse component definitions from arguments
    while [[ $# -gt 1 ]]; do
        components["$1"]="$2"
        shift 2
    done
    
    print_info "Checking installation status..."
    
    local all_installed=true
    for component in "${!components[@]}"; do
        if eval "${components[$component]}" &>/dev/null; then
            print_success "$component: Installed"
        else
            print_warning "$component: Not installed"
            all_installed=false
        fi
    done
    
    if [[ "$all_installed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Interactive Menus
# ============================================================================
show_component_menu() {
    local title="$1"
    shift
    
    echo -e "${CYAN}$title${NC}"
    echo "============================================"
    
    local i=1
    for component in "$@"; do
        local name="${component%%:*}"
        local desc="${component#*:}"
        echo "  $i. $desc"
        ((i++))
    done
    echo "  0. Exit"
    echo
}

process_menu_choice() {
    local choice="$1"
    shift
    local component_count=$#
    
    if [[ "$choice" == "0" ]]; then
        print_info "Exiting..."
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -le $component_count ]] && [[ $choice -gt 0 ]]; then
        local component_array=("$@")
        local component="${component_array[$((choice-1))]}"
        local name="${component%%:*}"
        echo "$name"
        return 0
    else
        print_error "Invalid choice: $choice"
        return 1
    fi
}

# ============================================================================
# Validation Functions
# ============================================================================
validate_root_check() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

validate_sudo_access() {
    if ! sudo -n true 2>/dev/null; then
        print_info "This script requires sudo access for system modifications"
        sudo -v || {
            print_error "Could not obtain sudo access"
            exit 1
        }
    fi
}

# ============================================================================
# Script Template Functions
# ============================================================================
standard_script_init() {
    local script_name="$1"
    local title="$2"
    local subtitle="$3"
    local icon="${4:-🎮}"
    
    validate_root_check
    setup_standard_logging "$script_name"
    print_standard_banner "$title" "$subtitle" "$icon"
    
    # Cache system tools for performance (if validation.sh is available)
    if declare -f cache_system_tools >/dev/null 2>&1; then
        cache_system_tools &>/dev/null || true
    fi
}

standard_script_cleanup() {
    # Cleanup temporary files
    [[ -f "$HARDWARE_CACHE_FILE" ]] && rm -f "$HARDWARE_CACHE_FILE"
}

# Set cleanup trap
trap standard_script_cleanup EXIT

# ============================================================================
# Export key functions for use in other scripts
# ============================================================================
export -f setup_standard_logging
export -f print_standard_banner
export -f install_packages_with_fallback
export -f get_cached_hardware_info
export -f create_backup
export -f manage_service
export -f create_launcher
export -f generate_config
export -f check_installation_status
export -f validate_root_check
export -f validate_sudo_access
export -f standard_script_init
export -f standard_script_cleanup
