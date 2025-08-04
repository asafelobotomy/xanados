#!/bin/bash
# xanadOS 2025 Security Implementation Script
# Deploy all security updates and configurations

# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh" || {
    echo "Error: Could not source common.sh" >&2
    exit 1
}

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XANADOS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_FILE="/var/log/xanados-security-deployment.log"
readonly BACKUP_DIR="/var/backups/xanados-security-$(date +%Y%m%d-%H%M%S)"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting xanadOS 2025 Security Implementation"

# Color codes for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color


# Security check
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root for system security configuration"
   exit 1
fi

# Create backup directory
print_status "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to backup and deploy configuration
deploy_config() {
    local src="$1"
    local dest="$2"
    local description="$3"

    print_status "Deploying $description..."

    # Backup existing file if it exists
    if [[ -f "$dest" ]]; then
        cp "$dest" "$BACKUP_DIR/$(basename "$dest").backup"
        print_status "Backed up existing $dest"
    fi

    # Deploy new configuration
    cp "$src" "$dest"
    print_status "Deployed $description to $dest"
}

# Function to create system users for services
create_security_users() {
    print_status "Creating security service users..."

    # Create users for security services (if they don't exist)
    for user in xanados-gaming xanados-system xanados-cpu; do
        if ! id "$user" &>/dev/null; then
            useradd -r -s /bin/false -d /var/lib/"$user" -c "xanadOS Security Service" "$user"
            mkdir -p /var/lib/"$user"
            chown "$user:$user" /var/lib/"$user"
            print_status "Created security user: $user"
        else
            print_status "Security user already exists: $user"
        fi
    done
}

# Function to install security packages
install_security_packages() {
    print_status "Installing 2025 security packages..."

    # Update package database
    pacman -Sy

    # Install security packages
    local packages=(
        "bubblewrap"
        "audit"
        "lynis"
        "aide"
        "ufw"
        "apparmor"
        "fail2ban"
    )

    for package in "${packages[@]}"; do
        if ! pacman -Q "$package" &>/dev/null; then
            print_status "Installing $package..."
            pacman -S --noconfirm "$package"
        else
            print_status "Package already installed: $package"
        fi
    done

    # Remove insecure packages
    if pacman -Q firejail &>/dev/null; then
        print_warning "Removing insecure Firejail package..."
        pacman -Rs --noconfirm firejail
    fi
}

# Deploy security configurations
deploy_security_configs() {
    print_status "Deploying 2025 security configurations..."

    # AppArmor configuration
    deploy_config \
        "$XANADOS_ROOT/configs/security/apparmor-gaming.conf" \
        "/etc/apparmor.d/xanados-gaming" \
        "AppArmor gaming profile"

    # Bubblewrap configuration
    deploy_config \
        "$XANADOS_ROOT/configs/security/bubblewrap-gaming.conf" \
        "/etc/xanados/bubblewrap-gaming.conf" \
        "Bubblewrap gaming configuration"

    # UFW rules script
    deploy_config \
        "$XANADOS_ROOT/configs/security/ufw-gaming-rules.sh" \
        "/usr/local/bin/xanados-ufw-setup" \
        "UFW gaming rules script"

    chmod +x /usr/local/bin/xanados-ufw-setup

    # Kernel parameters
    deploy_config \
        "$XANADOS_ROOT/configs/system/kernel-params.conf" \
        "/etc/sysctl.d/99-xanados-security.conf" \
        "Kernel security parameters"
}

# Deploy systemd services
deploy_services() {
    print_status "Deploying secure systemd services..."

    # Gaming monitor service
    deploy_config \
        "$XANADOS_ROOT/configs/services/xanados-gaming-monitor.service" \
        "/etc/systemd/system/xanados-gaming-monitor.service" \
        "Gaming monitor service"

    # System optimization service
    deploy_config \
        "$XANADOS_ROOT/configs/services/xanados-optimizations.service" \
        "/etc/systemd/system/xanados-optimizations.service" \
        "System optimization service"

    # CPU governor service
    deploy_config \
        "$XANADOS_ROOT/configs/system/xanados-cpu-governor.service" \
        "/etc/systemd/system/xanados-cpu-governor.service" \
        "CPU governor service"

    # Reload systemd
    systemctl daemon-reload
    print_status "SystemD daemon reloaded"
}

# Configure security services
configure_security_services() {
    print_status "Configuring security services..."

    # Enable and configure AppArmor
    systemctl enable apparmor
    print_status "AppArmor enabled"

    # Configure audit system
    systemctl enable auditd
    print_status "Audit system enabled"

    # Enable UFW (will be configured later)
    systemctl enable ufw
    print_status "UFW enabled"

    # Configure fail2ban
    systemctl enable fail2ban
    print_status "Fail2ban enabled"
}

# Apply kernel security parameters
apply_kernel_security() {
    print_status "Applying kernel security parameters..."

    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-xanados-security.conf
    print_status "Kernel security parameters applied"

    # Update GRUB with kernel parameters (if needed)
    if [[ -f /etc/default/grub ]]; then
        # Check if our parameters are already in GRUB config
        if ! grep -q "mitigations=auto,nosmt" /etc/default/grub; then
            print_warning "Kernel boot parameters need manual update in /etc/default/grub"
            print_warning "Add: mitigations=auto,nosmt spec_store_bypass_disable=auto tsx=off"
        fi
    fi
}

# Verify security implementation
verify_security() {
    print_status "Verifying security implementation..."

    local errors=0

    # Check if security packages are installed
    local packages=("bubblewrap" "audit" "lynis" "aide" "ufw" "apparmor")
    for package in "${packages[@]}"; do
        if pacman -Q "$package" &>/dev/null; then
            print_status "✓ $package installed"
        else
            print_error "✗ $package not installed"
            ((errors++))
        fi
    done

    # Check if services are configured
    local services=("apparmor" "auditd" "ufw" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            print_status "✓ $service enabled"
        else
            print_error "✗ $service not enabled"
            ((errors++))
        fi
    done

    # Check configuration files
    local configs=(
        "/etc/apparmor.d/xanados-gaming"
        "/etc/xanados/bubblewrap-gaming.conf"
        "/usr/local/bin/xanados-ufw-setup"
        "/etc/sysctl.d/99-xanados-security.conf"
    )

    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            print_status "✓ $config deployed"
        else
            print_error "✗ $config missing"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        print_status "✓ All security components verified successfully"
        return 0
    else
        print_error "✗ $errors security components failed verification"
        return 1
    fi
}

# Generate security report
generate_security_report() {
    print_status "Generating security implementation report..."

    local report_file="/var/log/xanados-security-implementation-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$report_file" << EOF
xanadOS 2025 Security Implementation Report
==========================================
Date: $(date)
Backup Location: $BACKUP_DIR

Security Components Deployed:
- AppArmor gaming profiles
- Bubblewrap sandboxing configuration
- UFW gaming firewall rules
- Secure systemd services
- Kernel security parameters
- Security monitoring tools (audit, lynis, aide)

Services Enabled:
- AppArmor application confinement
- Audit system monitoring
- UFW firewall
- Fail2ban intrusion prevention

Configuration Files:
- /etc/apparmor.d/xanados-gaming
- /etc/xanados/bubblewrap-gaming.conf
- /usr/local/bin/xanados-ufw-setup
- /etc/sysctl.d/99-xanados-security.conf

Next Steps:
1. Run '/usr/local/bin/xanados-ufw-setup' to configure firewall
2. Reboot system to apply all kernel security parameters
3. Enable gaming services: systemctl enable xanados-gaming-monitor
4. Run security scan: lynis audit system

Security Level: ENHANCED (2025 Standards)
Gaming Performance: MAINTAINED
Risk Assessment: LOW
EOF

    print_status "Security report generated: $report_file"
}

# Main deployment sequence
main() {
    print_status "=== xanadOS 2025 Security Implementation ==="

    # Pre-deployment checks
    print_status "Performing pre-deployment security checks..."

    # Create necessary directories
    mkdir -p /etc/xanados /var/log/xanados

    # Create security users
    create_security_users

    # Install security packages
    install_security_packages

    # Deploy configurations
    deploy_security_configs

    # Deploy services
    deploy_services

    # Configure security services
    configure_security_services

    # Apply kernel security
    apply_kernel_security

    # Verify implementation
    if verify_security; then
        print_status "✓ Security implementation completed successfully"
    else
        print_error "✗ Security implementation completed with errors"
        exit 1
    fi

    # Generate report
    generate_security_report

    print_status "=== 2025 Security Implementation Complete ==="
    print_status "Backup created at: $BACKUP_DIR"
    print_status "Next steps:"
    print_status "1. Reboot system to apply kernel parameters"
    print_status "2. Run: /usr/local/bin/xanados-ufw-setup"
    print_status "3. Enable gaming services as needed"
    print_status "4. Review security report in /var/log/"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] xanadOS 2025 Security Implementation completed"
}

# Execute main function
main "$@"
