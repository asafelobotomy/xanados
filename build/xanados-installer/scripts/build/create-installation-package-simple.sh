#!/bin/bash

# 📦 xanadOS Installation Package Creator (Simplified)
# Create easy-to-deploy installation package for xanadOS Gaming Distribution

set -euo pipefail

log_info() { echo "[INFO] $*"; }
log_success() { echo "[SUCCESS] $*"; }

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
XANADOS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
BUILD_DIR="$XANADOS_ROOT/build"
PACKAGE_DIR="$BUILD_DIR/xanados-installer"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
XANADOS_VERSION="1.0.0"

main() {
    log_info "📦 Creating xanadOS installation package..."
    
    # Prepare directories
    rm -rf "$PACKAGE_DIR"
    mkdir -p "$PACKAGE_DIR"
    
    # Copy core components
    log_info "📂 Copying core components..."
    cp -r "$XANADOS_ROOT/scripts" "$PACKAGE_DIR/"
    cp -r "$XANADOS_ROOT/configs" "$PACKAGE_DIR/"
    cp -r "$XANADOS_ROOT/packages" "$PACKAGE_DIR/"
    cp -r "$XANADOS_ROOT/docs" "$PACKAGE_DIR/"
    cp "$XANADOS_ROOT/README.md" "$PACKAGE_DIR/" 2>/dev/null || true
    cp "$XANADOS_ROOT/CHANGELOG.md" "$PACKAGE_DIR/" 2>/dev/null || true
    
    # Create simple installer
    log_info "🚀 Creating installer script..."
    cat > "$PACKAGE_DIR/install-xanados.sh" << 'EOF'
#!/bin/bash

echo "🎮 xanadOS Gaming Distribution Installer v1.0.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

INSTALL_DIR="/opt/xanados"

echo "Installing xanadOS to $INSTALL_DIR..."

# Create installation directory
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER:$USER" "$INSTALL_DIR"

# Copy files
cp -r scripts configs packages docs "$INSTALL_DIR/"

# Set permissions
find "$INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \;

# Add to PATH
echo "export PATH=\"$INSTALL_DIR/scripts/setup:\$PATH\"" | sudo tee -a /etc/profile.d/xanados.sh
echo "export XANADOS_ROOT=\"$INSTALL_DIR\"" | sudo tee -a /etc/profile.d/xanados.sh

# Initialize gaming mode
"$INSTALL_DIR/scripts/setup/gaming-desktop-mode.sh" init 2>/dev/null || true

echo ""
echo "✅ xanadOS installation completed!"
echo ""
echo "Quick start commands:"
echo "  xanados-gaming-setup.sh     - Complete gaming setup"
echo "  gaming-desktop-mode.sh      - Gaming desktop mode"
echo ""
echo "🎮 Enjoy gaming with xanadOS!"
EOF

    chmod +x "$PACKAGE_DIR/install-xanados.sh"
    
    # Create documentation
    log_info "📄 Creating documentation..."
    cat > "$PACKAGE_DIR/INSTALL.md" << EOF
# 🎮 xanadOS Gaming Distribution - Installation

## Quick Installation
\`\`\`bash
chmod +x install-xanados.sh
./install-xanados.sh
\`\`\`

## What's Included
- Complete gaming optimization suite
- Gaming desktop mode and workflows
- Automated setup wizards
- Hardware detection and optimization
- Gaming profile management
- KDE desktop integration

## Post-Installation
\`\`\`bash
# Complete gaming setup
xanados-gaming-setup.sh

# Toggle gaming mode
gaming-desktop-mode.sh toggle

# Performance stats
gaming-desktop-mode.sh stats
\`\`\`

## Requirements
- Arch Linux (recommended)
- 8GB RAM minimum
- KDE Plasma desktop
- Sudo access

---
**xanadOS Gaming Distribution v$XANADOS_VERSION**  
The ultimate gaming experience on Linux! 🎮
EOF

    # Create archive
    log_info "📦 Creating release archive..."
    cd "$BUILD_DIR"
    tar -czf "xanados-gaming-distribution-v${XANADOS_VERSION}-${TIMESTAMP}.tar.gz" "$(basename "$PACKAGE_DIR")"
    
    echo ""
    echo "📦 xanadOS Installation Package Created!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Package Details:"
    echo "  📦 Version: $XANADOS_VERSION"
    echo "  📁 Package Directory: $PACKAGE_DIR"
    echo "  📦 Archive: xanados-gaming-distribution-v${XANADOS_VERSION}-${TIMESTAMP}.tar.gz"
    echo "  📊 Total Files: $(find "$PACKAGE_DIR" -type f | wc -l)"
    echo "  💾 Package Size: $(du -sh "$PACKAGE_DIR" | cut -f1)"
    echo ""
    echo "🚀 Installation:"
    echo "  1. Extract: tar -xzf xanados-gaming-distribution-*.tar.gz"
    echo "  2. Install: cd xanados-installer && ./install-xanados.sh"
    echo ""
    echo "✅ Ready for distribution!"
}

main "$@"
