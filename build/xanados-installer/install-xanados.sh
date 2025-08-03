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
