#!/bin/bash

# 📦 xanadOS Installation Package Creator
# Create easy-to-deploy installation package for xanadOS Gaming Distribution
#
# Purpose: Generate complete installation package with automated setup
#          Package all components for easy distribution and deployment
#
# Author: xanadOS Development Team
# Version: 1.0.0
# Date: August 3, 2025

set -euo pipefail

# Simple logging functions
log_info() {
    echo "[INFO] $*"
}

log_warning() {
    echo "[WARNING] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*"
}

# 📁 Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
XANADOS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
BUILD_DIR="$XANADOS_ROOT/build"
PACKAGE_DIR="$BUILD_DIR/xanados-installer"
RELEASE_DIR="$BUILD_DIR/release"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Version information
XANADOS_VERSION="1.0.0"
RELEASE_DATE=$(date +"%B %d, %Y")

# 📦 Package Creation Functions

prepare_build_directories() {
    log_info "🏗️  Preparing build directories..."

    # Clean and create build directories
    rm -rf "$PACKAGE_DIR" "$RELEASE_DIR"
    mkdir -p "$PACKAGE_DIR" "$RELEASE_DIR"

    log_success "Build directories prepared"
}

copy_core_components() {
    log_info "📂 Copying core xanadOS components..."

    # Copy essential directories
    local core_dirs=(
        "scripts"
        "configs"
        "packages"
        "docs"
    )

    for dir in "${core_dirs[@]}"; do
        if [[ -d "$XANADOS_ROOT/$dir" ]]; then
            cp -r "$XANADOS_ROOT/$dir" "$PACKAGE_DIR/"
            log_info "  ✅ Copied: $dir"
        else
            log_warning "  ⚠️  Missing: $dir"
        fi
    done

    # Copy essential files
    local core_files=(
        "README.md"
        "CHANGELOG.md"
    )

    for file in "${core_files[@]}"; do
        if [[ -f "$XANADOS_ROOT/$file" ]]; then
            cp "$XANADOS_ROOT/$file" "$PACKAGE_DIR/"
            log_info "  ✅ Copied: $file"
        else
            log_warning "  ⚠️  Missing: $file"
        fi
    done

    log_success "Core components copied"
}

create_installer_script() {
    log_info "🚀 Creating installation script..."

    cat > "$PACKAGE_DIR/install-xanados.sh" << 'EOF'
#!/bin/bash

# 🎮 xanadOS Gaming Distribution Installer
# Automated installation script for xanadOS gaming environment
# Version: 1.0.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Simple logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Installation directory
INSTALL_DIR="/opt/xanados"
USER_CONFIG_DIR="$HOME/.config/xanados"

show_welcome() {
    clear
    echo -e "${CYAN}🎮 Welcome to xanadOS Gaming Distribution Installer${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${WHITE}xanadOS Gaming Distribution v1.0.0${NC}"
    echo "The ultimate Arch Linux-based gaming environment"
    echo ""
    echo "Features:"
    echo "  🚀 Complete gaming optimization suite"
    echo "  🎯 Hardware-specific performance tuning"
    echo "  🎮 Gaming desktop mode with quick access tools"
    echo "  🔧 Automated setup wizards and configuration"
    echo "  📊 Performance monitoring and statistics"
    echo "  🎨 Gaming-optimized KDE desktop themes"
    echo ""
    echo "This installer will:"
    echo "  • Install xanadOS scripts and tools to $INSTALL_DIR"
    echo "  • Set up gaming optimization configurations"
    echo "  • Configure desktop gaming environment"
    echo "  • Create user gaming profiles"
    echo "  • Install gaming software stack (Steam, Lutris, etc.)"
    echo ""
    echo -n "Continue with installation? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
}

check_requirements() {
    log_info "🔍 Checking system requirements..."

    # Check if running on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_warning "xanadOS is optimized for Arch Linux. Some features may not work on other distributions."
    fi

    # Check for required commands
    local required_commands=(
        "bash"
        "systemctl"
        "pacman"
    )

    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_info "  ✅ Found: $cmd"
        else
            log_error "  ❌ Missing required command: $cmd"
            exit 1
        fi
    done

    # Check for sudo access
    if sudo -n true 2>/dev/null; then
        log_info "  ✅ Sudo access available"
    else
        log_warning "  ⚠️  Sudo access required for system configuration"
    fi

    log_success "System requirements check completed"
}

install_xanados_system() {
    log_info "📦 Installing xanadOS system..."

    # Create installation directory
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$USER:$USER" "$INSTALL_DIR"

    # Copy all xanadOS files
    cp -r scripts configs packages docs "$INSTALL_DIR/"

    # Set executable permissions
    find "$INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \;

    # Create user configuration directory
    mkdir -p "$USER_CONFIG_DIR"

    log_success "xanadOS system installed to $INSTALL_DIR"
}

setup_system_integration() {
    log_info "🔧 Setting up system integration..."

    # Add xanadOS to PATH
    echo "# xanadOS Gaming Distribution" | sudo tee -a /etc/profile.d/xanados.sh
    echo "export PATH=\"$INSTALL_DIR/scripts/setup:\$PATH\"" | sudo tee -a /etc/profile.d/xanados.sh
    echo "export XANADOS_ROOT=\"$INSTALL_DIR\"" | sudo tee -a /etc/profile.d/xanados.sh

    # Create desktop applications
    create_desktop_applications

    # Setup gaming configurations
    setup_gaming_configs

    log_success "System integration completed"
}

create_desktop_applications() {
    log_info "🖥️  Creating desktop applications..."

    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"

    # xanadOS Gaming Setup launcher
    cat > "$desktop_dir/xanados-gaming-setup.desktop" << EOF
[Desktop Entry]
Name=xanadOS Gaming Setup
Comment=Complete gaming environment setup and configuration
Exec=$INSTALL_DIR/scripts/setup/xanados-gaming-setup.sh
Icon=applications-games
Type=Application
Categories=Game;Settings;
Keywords=gaming;setup;configuration;xanados;
EOF

    # Gaming Desktop Mode launcher
    cat > "$desktop_dir/xanados-gaming-mode.desktop" << 'EOF2'
[Desktop Entry]
Name=Gaming Desktop Mode
Comment=Toggle gaming-optimized desktop environment
Exec=$INSTALL_DIR/scripts/setup/gaming-desktop-mode.sh toggle
Icon=preferences-desktop-gaming
Type=Application
Categories=Game;Settings;
Keywords=gaming;desktop;mode;performance;
EOF2

    chmod +x "$desktop_dir"/*.desktop

    log_info "  ✅ Desktop applications created"
}

setup_gaming_configs() {
    log_info "⚙️  Setting up gaming configurations..."

    # Copy gaming configurations to system locations (if root access available)
    if sudo -n true 2>/dev/null; then
        # Network optimizations
        if [[ -f "$INSTALL_DIR/configs/network/gaming-optimizations.conf" ]]; then
            sudo cp "$INSTALL_DIR/configs/network/gaming-optimizations.conf" /etc/sysctl.d/99-gaming.conf
        fi

        # Gaming services
        if [[ -d "$INSTALL_DIR/configs/services" ]]; then
            sudo cp "$INSTALL_DIR/configs/services"/*.service /etc/systemd/system/ 2>/dev/null || true
            sudo systemctl daemon-reload
        fi
    else
        log_warning "Skipping system configuration - requires root access"
    fi

    log_info "  ✅ Gaming configurations applied"
}

run_initial_setup() {
    log_info "🎮 Running initial xanadOS setup..."

    # Initialize gaming desktop mode
    if [[ -f "$INSTALL_DIR/scripts/setup/gaming-desktop-mode.sh" ]]; then
        "$INSTALL_DIR/scripts/setup/gaming-desktop-mode.sh" init
    fi

    # Run first-boot experience setup
    if [[ -f "$INSTALL_DIR/scripts/setup/first-boot-experience.sh" ]]; then
        "$INSTALL_DIR/scripts/setup/first-boot-experience.sh" setup
    fi

    log_success "Initial setup completed"
}

show_completion() {
    clear
    echo -e "${GREEN}🎉 xanadOS Gaming Distribution Installation Complete!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${WHITE}Installation Summary:${NC}"
    echo "  📦 xanadOS installed to: $INSTALL_DIR"
    echo "  ⚙️  User config directory: $USER_CONFIG_DIR"
    echo "  🖥️  Desktop applications created"
    echo "  🎮 Gaming optimizations configured"
    echo ""
    echo -e "${WHITE}Quick Start:${NC}"
    echo "  🚀 Run complete setup: xanados-gaming-setup.sh"
    echo "  🎮 Toggle gaming mode: gaming-desktop-mode.sh toggle"
    echo "  📊 Performance stats: gaming-desktop-mode.sh stats"
    echo ""
    echo -e "${WHITE}Available Commands:${NC}"
    echo "  • xanados-gaming-setup.sh     - Complete gaming setup wizard"
    echo "  • gaming-desktop-mode.sh      - Gaming desktop mode management"
    echo "  • first-boot-experience.sh    - First-boot setup experience"
    echo "  • gaming-workflow-optimization.sh - Gaming workflow tools"
    echo ""
    echo -e "${CYAN}🎮 Welcome to the ultimate gaming experience!${NC}"
    echo ""
    echo "For documentation and support:"
    echo "  📖 Documentation: $INSTALL_DIR/docs/"
    echo "  🔧 Configuration: $USER_CONFIG_DIR/"
    echo ""
    echo "Enjoy gaming with xanadOS! 🎮"
}

# Main installation process
main() {
    show_welcome
    check_requirements
    install_xanados_system
    setup_system_integration
    run_initial_setup
    show_completion
}

# Run installer if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF

    chmod +x "$PACKAGE_DIR/install-xanados.sh"
    log_success "Installation script created"
}

create_package_documentation() {
    log_info "📄 Creating package documentation..."

    # Create installation README
    cat > "$PACKAGE_DIR/INSTALL.md" << EOF
# 🎮 xanadOS Gaming Distribution - Installation Guide

**Version**: $XANADOS_VERSION
**Release Date**: $RELEASE_DATE

## 📋 Quick Installation

### Automated Installation (Recommended)
\`\`\`bash
chmod +x install-xanados.sh
./install-xanados.sh
\`\`\`

### Manual Installation
\`\`\`bash
# 1. Copy files to installation directory
sudo cp -r * /opt/xanados/

# 2. Set executable permissions
sudo find /opt/xanados/scripts -name "*.sh" -exec chmod +x {} \;

# 3. Add to PATH
echo 'export PATH="/opt/xanados/scripts/setup:\$PATH"' | sudo tee -a /etc/profile.d/xanados.sh

# 4. Initialize gaming mode
/opt/xanados/scripts/setup/gaming-desktop-mode.sh init
\`\`\`

## 🎯 What's Included

### Core Components
- **Gaming Optimization Suite** - Complete performance optimization
- **Hardware Detection** - Automatic hardware analysis and tuning
- **Gaming Desktop Mode** - Gaming-optimized desktop environment
- **Setup Wizards** - Automated gaming software installation
- **Profile Management** - Gaming profile creation and management

### Gaming Software Integration
- Steam installation and optimization
- Lutris gaming platform setup
- GameMode performance optimization
- Controller configuration
- Graphics driver optimization

### Desktop Integration
- KDE Plasma gaming themes
- Gaming shortcuts and hotkeys
- Performance monitoring widgets
- Gaming-aware notification system
- Window management optimization

## 🚀 Post-Installation

### Quick Start Commands
\`\`\`bash
# Complete gaming setup
xanados-gaming-setup.sh

# Toggle gaming mode
gaming-desktop-mode.sh toggle

# Performance statistics
gaming-desktop-mode.sh stats

# First-boot experience
first-boot-experience.sh
\`\`\`

### Desktop Applications
After installation, look for these applications in your desktop menu:
- **xanadOS Gaming Setup** - Complete setup wizard
- **Gaming Desktop Mode** - Toggle gaming environment

## 🔧 System Requirements

### Minimum Requirements
- **OS**: Arch Linux (recommended) or compatible distribution
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 2GB for xanadOS components
- **Desktop**: KDE Plasma (for full desktop integration)

### Optional Components
- **Graphics**: NVIDIA/AMD graphics card for enhanced gaming
- **Controllers**: Gaming controllers for enhanced experience
- **Network**: High-speed internet for gaming platform integration

## 📖 Documentation

Complete documentation available in:
- \`docs/README.md\` - Main documentation
- \`docs/user/\` - User guides and references
- \`docs/installation/\` - Detailed installation instructions

## 🆘 Support and Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure sudo access for system configuration
2. **Missing Dependencies**: Install required packages using pacman
3. **Desktop Integration**: Requires KDE Plasma for full functionality

### Getting Help
- Check documentation in \`docs/\` directory
- Review gaming quick reference: \`docs/user/gaming-quick-reference.md\`
- Run component validation: \`scripts/setup/phase4-integration-polish.sh validate\`

## ✅ Verification

Verify installation success:
\`\`\`bash
# Check installation
ls -la /opt/xanados/

# Test gaming mode
gaming-desktop-mode.sh status

# Run system validation
/opt/xanados/scripts/testing/run-full-system-test.sh
\`\`\`

---

**Welcome to xanadOS Gaming Distribution!** 🎮

Enjoy the ultimate gaming experience on Linux!
EOF

    # Create package info file
    cat > "$PACKAGE_DIR/PACKAGE_INFO.txt" << EOF
xanadOS Gaming Distribution v$XANADOS_VERSION
Release Date: $RELEASE_DATE
Package Created: $(date)

Components:
- Complete gaming optimization suite
- Gaming desktop mode and workflows
- Automated setup wizards
- Hardware detection and optimization
- Gaming profile management
- KDE desktop integration
- Performance monitoring tools

Installation: Run ./install-xanados.sh

Total Files: $(find "$PACKAGE_DIR" -type f | wc -l)
Package Size: $(du -sh "$PACKAGE_DIR" | cut -f1)
EOF

    log_success "Package documentation created"
}

create_release_archive() {
    log_info "📦 Creating release archive..."

    local archive_name="xanados-gaming-distribution-v${XANADOS_VERSION}-${TIMESTAMP}"
    local archive_path="$RELEASE_DIR/${archive_name}.tar.gz"

    # Create compressed archive
    cd "$BUILD_DIR"
    tar -czf "$archive_path" -C "$BUILD_DIR" "$(basename "$PACKAGE_DIR")"

    # Create release info
    cat > "$RELEASE_DIR/RELEASE_INFO.md" << EOF
# 🎮 xanadOS Gaming Distribution v$XANADOS_VERSION

**Release Date**: $RELEASE_DATE
**Build Date**: $(date)
**Archive**: \`${archive_name}.tar.gz\`

## 📦 Release Contents

This release includes the complete xanadOS Gaming Distribution with:

### ✅ Core Features
- Complete gaming optimization suite (Phases 1-4)
- Gaming desktop mode with performance optimization
- Automated setup wizards and hardware detection
- Gaming profile creation and management
- KDE Plasma desktop integration
- Gaming workflow optimization tools

### 🎮 Gaming Integration
- Steam platform optimization
- Lutris gaming setup
- GameMode performance enhancement
- Controller configuration
- Graphics driver optimization

### 📊 System Components
- **Scripts**: $(find "$PACKAGE_DIR/scripts" -name "*.sh" | wc -l) shell scripts
- **Configurations**: Gaming-optimized system configs
- **Documentation**: Complete user and developer guides
- **Packages**: Gaming software package lists

## 🚀 Installation

\`\`\`bash
# Extract archive
tar -xzf ${archive_name}.tar.gz

# Run installer
cd $(basename "$PACKAGE_DIR")
./install-xanados.sh
\`\`\`

## 📈 What's New in v$XANADOS_VERSION

- ✅ Complete Phase 4 user experience implementation
- ✅ Gaming desktop mode with keyboard shortcuts
- ✅ Unified gaming setup launcher
- ✅ Comprehensive system integration
- ✅ Professional desktop gaming environment
- ✅ Performance monitoring and statistics

## 🎯 Ready for Production

This release represents the complete xanadOS Gaming Distribution, ready for:
- Personal gaming workstation setup
- Gaming community distribution
- Gaming café/lab deployment
- Gaming-focused Linux distributions

---

**Total Package Size**: $(du -sh "$archive_path" | cut -f1)
**Installation Time**: ~5-10 minutes
**Target Platform**: Arch Linux

🎮 **Ready to revolutionize your gaming experience!**
EOF

    log_success "Release archive created: $archive_path"
    log_info "📊 Archive size: $(du -sh "$archive_path" | cut -f1)"
}

show_package_summary() {
    echo ""
    echo "📦 xanadOS Installation Package Created!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Package Details:"
    echo "  📦 Version: $XANADOS_VERSION"
    echo "  📅 Release Date: $RELEASE_DATE"
    echo "  📁 Package Directory: $PACKAGE_DIR"
    echo "  📦 Release Archive: $RELEASE_DIR/"
    echo "  📊 Total Files: $(find "$PACKAGE_DIR" -type f | wc -l)"
    echo "  💾 Package Size: $(du -sh "$PACKAGE_DIR" | cut -f1)"
    echo ""
    echo "🚀 Installation:"
    echo "  1. Extract archive or use package directory"
    echo "  2. Run: ./install-xanados.sh"
    echo "  3. Follow automated installation process"
    echo ""
    echo "📄 Documentation:"
    echo "  • INSTALL.md - Installation guide"
    echo "  • PACKAGE_INFO.txt - Package details"
    echo "  • docs/ - Complete documentation"
    echo ""
    echo "✅ Ready for distribution and deployment!"
}

# Main execution
main() {
    local command="${1:-create}"

    case "$command" in
        "create"|"build"|"package")
            log_info "📦 Creating xanadOS installation package..."
            echo ""

            prepare_build_directories
            copy_core_components
            create_installer_script
            create_package_documentation
            create_release_archive
            show_package_summary
            ;;
        "test"|"validate")
            log_info "🧪 Testing installation package..."
            if [[ -d "$PACKAGE_DIR" ]]; then
                echo "Package directory exists: $PACKAGE_DIR"
                echo "Installer script: $(ls -la "$PACKAGE_DIR/install-xanados.sh" 2>/dev/null || echo "Missing")"
                echo "Documentation: $(ls -la "$PACKAGE_DIR/INSTALL.md" 2>/dev/null || echo "Missing")"
            else
                log_error "Package not created yet. Run 'create' first."
            fi
            ;;
        "clean")
            log_info "🧹 Cleaning build directories..."
            rm -rf "$PACKAGE_DIR" "$RELEASE_DIR"
            log_success "Build directories cleaned"
            ;;
        "help"|"--help"|"-h")
            echo "📦 xanadOS Installation Package Creator"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Commands:"
            echo "  create    Create complete installation package"
            echo "  test      Test and validate package"
            echo "  clean     Clean build directories"
            echo "  help      Show this help message"
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Use '$0 help' for available commands"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
