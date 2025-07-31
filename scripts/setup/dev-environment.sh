#!/bin/bash
# xanadOS Development Environment Setup Script
# This script sets up the development environment for building xanadOS

set -e  # Exit on any error

echo "=== xanadOS Development Environment Setup ==="
echo "Setting up development environment for xanadOS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Arch Linux
check_arch_linux() {
    print_status "Checking if running on Arch Linux..."
    if [ -f /etc/arch-release ]; then
        print_success "Running on Arch Linux"
    else
        print_warning "Not running on Arch Linux. Some packages may not be available."
        read -r -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    if command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm
        print_success "System packages updated"
    else
        print_warning "Pacman not found. Skipping system update."
    fi
}

# Install development dependencies
install_dependencies() {
    print_status "Installing development dependencies..."
    
    # Core development packages
    local packages=(
        "archiso"           # For building Arch Linux ISOs
        "git"               # Version control
        "base-devel"        # Development tools
        "devtools"          # Arch development tools
        "pacman-contrib"    # Additional pacman tools
        "squashfs-tools"    # For filesystem creation
        "libisoburn"        # ISO burning tools
        "dosfstools"        # FAT filesystem tools
        "tree"              # Directory tree display
        "curl"              # HTTP client
        "wget"              # File downloader
        "rsync"             # File synchronization
        "jq"                # JSON processor
        "vim"               # Text editor
        "nano"              # Alternative text editor
    )
    
    if command -v pacman &> /dev/null; then
        for package in "${packages[@]}"; do
            print_status "Installing $package..."
            if pacman -Qi "$package" &> /dev/null; then
                print_success "$package is already installed"
            else
                sudo pacman -S --noconfirm "$package"
                print_success "$package installed"
            fi
        done
    else
        print_error "Pacman not available. Please install packages manually:"
        printf '%s\n' "${packages[@]}"
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    local base_dir="/home/vm/Documents/xanadOS"
    local work_dirs=(
        "$base_dir/build/work"
        "$base_dir/build/out"
        "$base_dir/build/cache"
        "$base_dir/archive/backups"
        "$base_dir/testing/results"
    )
    
    for dir in "${work_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        else
            print_success "Directory already exists: $dir"
        fi
    done
}

# Set up git configuration (if not already configured)
setup_git() {
    print_status "Setting up Git configuration..."
    
    if [ -z "$(git config --global user.name)" ]; then
        read -r -p "Enter your Git username: " git_username
        git config --global user.name "$git_username"
        print_success "Git username set to: $git_username"
    else
        print_success "Git username already configured: $(git config --global user.name)"
    fi
    
    if [ -z "$(git config --global user.email)" ]; then
        read -r -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
        print_success "Git email set to: $git_email"
    else
        print_success "Git email already configured: $(git config --global user.email)"
    fi
}

# Initialize Git repository (if not already initialized)
init_git_repo() {
    print_status "Initializing Git repository..."
    
    cd /home/vm/Documents/xanadOS
    
    if [ ! -d ".git" ]; then
        git init
        git add .
        git commit -m "Initial xanadOS project structure"
        print_success "Git repository initialized"
    else
        print_success "Git repository already exists"
    fi
}

# Create initial configuration files
create_initial_configs() {
    print_status "Creating initial configuration files..."
    
    # Create .gitignore
    cat > /home/vm/Documents/xanadOS/.gitignore << 'EOF'
# Build artifacts
build/work/*
build/out/*
build/cache/*
*.iso
*.img

# Temporary files
*.tmp
*.log
*~
.DS_Store
Thumbs.db

# IDE/Editor files
.vscode/
.idea/
*.swp
*.swo

# Archive and backup files
archive/backups/*
testing/results/*

# System files
.directory
desktop.ini
EOF
    print_success "Created .gitignore"
    
    # Create README.md
    cat > /home/vm/Documents/xanadOS/README.md << 'EOF'
# xanadOS

A specialized Arch Linux-based gaming distribution optimized for performance and security.

## Project Status
🚧 **In Development** - Phase 1: Foundation

## Quick Start
```bash
# Set up development environment
./scripts/setup/dev-environment.sh

# Build ISO (coming soon)
./scripts/build/create-iso.sh
```

## Project Structure
See `docs/user/project_structure.md` for detailed directory structure.

## Documentation
- [Project Plan](docs/user/xanadOS_plan.md)
- [Development Setup](docs/development/setup.md)

## Development
This project is developed with AI assistance using modern development practices.

## License
Personal use project - see LICENSE file for details.
EOF
    print_success "Created README.md"
}

# Main execution
main() {
    echo "Starting xanadOS development environment setup..."
    echo
    
    check_arch_linux
    update_system
    install_dependencies
    create_directories
    setup_git
    init_git_repo
    create_initial_configs
    
    echo
    print_success "=== Development Environment Setup Complete! ==="
    echo
    print_status "Next steps:"
    echo "1. Review the project structure in docs/user/project_structure.md"
    echo "2. Check the project plan in docs/user/xanadOS_plan.md"
    echo "3. Start with Phase 1 development tasks"
    echo "4. Run './scripts/build/create-iso.sh' when ready to build"
    echo
    print_status "Happy coding! 🚀"
}

# Run main function
main "$@"
