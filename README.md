# xanadOS

> A specialized Arch Linux-based gaming distribution optimized for performance and security.

[![Project Status](https://img.shields.io/badge/Status-In%20Development-yellow.svg)](https://github.com/asafelobotomy/xanadOS)
[![Development Phase](https://img.shields.io/badge/Phase-1%20Complete-brightgreen.svg)](#project-status)
[![License](https://img.shields.io/badge/License-Personal%20Use-blue.svg)](#license)

## Table of Contents

- [About](#about)
- [Project Status](#project-status)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Development](#development)
- [Contributing](#contributing)
- [Support](#support)
- [Roadmap](#roadmap)
- [Acknowledgments](#acknowledgments)
- [License](#license)

## About

xanadOS is a personal Linux gaming distribution project built on Arch Linux with AI assistance. It focuses on delivering exceptional gaming performance while maintaining system security for personal use.

### What xanadOS Does

- **Gaming Performance Optimization**: Automatically configures Steam, Lutris, GameMode, and other gaming platforms for optimal performance
- **Hardware-Specific Tuning**: Detects and optimizes graphics drivers, audio latency, and gaming peripherals
- **Comprehensive Monitoring**: Provides detailed performance reports and system analysis tools
- **Automated Setup**: Streamlines the complex process of setting up a gaming-focused Linux environment

### Why xanadOS is Useful

- Eliminates the complexity of manually configuring a Linux gaming setup
- Provides gaming-specific optimizations often missed in general Linux distributions
- Offers comprehensive testing and validation tools for gaming performance
- Maintains detailed documentation and reports for troubleshooting

### Who This Project is For

- Linux gaming enthusiasts seeking optimal performance
- Users wanting to transition from Windows gaming to Linux
- Developers interested in gaming environment automation
- Anyone looking for a well-documented, modular gaming setup system

## Project Status

🚧 **In Development** - Phase 1: Foundation & Tooling Complete

Current development focuses on gaming environment setup, hardware optimization, and development tooling.

## Quick Start

### Prerequisites

- Arch Linux or Arch-based distribution
- Bash 4.0 or later
- `sudo` privileges for system modifications
- Internet connection for package installation

### Basic Setup

```bash
# Clone the repository
git clone https://github.com/asafelobotomy/xanadOS.git
cd xanadOS

# Set up development environment
./scripts/setup/dev-environment.sh

# Install gaming platforms
./scripts/setup/install-steam.sh
./scripts/setup/install-lutris.sh
./scripts/setup/install-gamemode.sh

# Run gaming setup wizard
./scripts/setup/gaming-setup-wizard.sh
```

### Generate Reports

```bash
# Generate comprehensive system reports
./testing/automated/testing-suite.sh

# Run performance benchmarks
./testing/automated/performance-benchmark.sh

# Validate gaming environment
./testing/automated/gaming-validator.sh
```

## Installation

### System Requirements

- **OS**: Arch Linux or Arch-based distribution (Manjaro, EndeavourOS, etc.)
- **RAM**: Minimum 8GB (16GB recommended for gaming)
- **Storage**: 20GB free space for base installation
- **GPU**: NVIDIA, AMD, or Intel graphics (dedicated GPU recommended)
- **Network**: Internet connection required for initial setup

### Detailed Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/asafelobotomy/xanadOS.git
   cd xanadOS
   ```

2. **Run Initial Setup**
   ```bash
   # This will set up the base development environment
   ./scripts/setup/dev-environment.sh
   ```

3. **Install Gaming Components**
   ```bash
   # Use the wizard for guided setup
   ./scripts/setup/gaming-setup-wizard.sh
   
   # Or install components individually
   ./scripts/setup/install-steam.sh
   ./scripts/setup/install-lutris.sh
   ./scripts/setup/unified-gaming-setup.sh
   ```

4. **Optimize Hardware**
   ```bash
   # Hardware-specific optimizations
   ./scripts/setup/priority3-hardware-optimization.sh
   
   # Audio optimization for gaming
   ./scripts/setup/audio-latency-optimizer.sh
   ```

5. **Validate Installation**
   ```bash
   # Comprehensive system validation
   ./testing/automated/testing-suite.sh
   ```

## Usage

### Core Commands

- **Gaming Setup Wizard**: `./scripts/setup/gaming-setup-wizard.sh` - Interactive gaming environment setup
- **Hardware Optimization**: `./scripts/setup/priority3-hardware-optimization.sh` - Optimize graphics and hardware
- **System Testing**: `./testing/automated/testing-suite.sh` - Comprehensive system validation
- **Performance Benchmarking**: `./testing/automated/performance-benchmark.sh` - Gaming performance testing

### Configuration

Most configuration is automated, but you can customize:

- **Gaming profiles**: Edit files in `configs/` directory
- **Hardware settings**: Modify scripts in `scripts/setup/`
- **Testing parameters**: Adjust settings in `testing/` directory

### Monitoring and Reports

xanadOS generates comprehensive reports in multiple formats:

- **HTML Reports**: Visual dashboards with charts and graphs
- **JSON Data**: Machine-readable performance metrics
- **Markdown Summaries**: Human-readable status reports

Reports are saved to `docs/reports/generated/` with timestamps.

## Features

- **Gaming Optimization**: Steam, Lutris, GameMode integration
- **Performance Monitoring**: Comprehensive system and gaming performance reports  
- **Hardware Optimization**: Graphics drivers, audio latency, device optimization
- **Development Tools**: Automated testing, validation, and reporting frameworks
- **Modular Architecture**: Library-based script system with proper dependency management

## Project Structure

```text
xanadOS/
├── archive/                    # Historical and backup files
│   ├── backups/               # System and configuration backups
│   └── deprecated/            # Deprecated features and old versions
├── build/                     # ISO building and distribution files
│   ├── bootloader/           # Boot configuration
│   ├── filesystem/           # Root filesystem structure
│   └── packages/             # Package management
├── configs/                   # Configuration files and templates
│   ├── desktop/              # Desktop environment configs
│   ├── network/              # Network optimization settings
│   ├── security/             # Security configurations
│   ├── services/             # System service definitions
│   └── system/               # System-level configurations
├── docs/                      # Documentation
│   ├── user/                 # End-user guides and references
│   ├── development/          # Technical documentation and reports
│   ├── api/                  # API documentation
│   └── reports/              # Generated reports and data
├── packages/                  # Package lists and definitions
│   ├── core/                 # Essential system packages
│   ├── desktop/              # Desktop environment packages
│   └── development/          # Development tools packages
├── scripts/                   # All executable scripts
│   ├── lib/                  # Shared libraries and functions
│   ├── setup/                # Installation and configuration scripts
│   ├── demo/                 # Demonstration and example scripts
│   ├── dev-tools/            # Development utilities
│   └── utilities/            # System utility scripts
├── testing/                   # Testing and validation
│   ├── automated/            # Automated test suites
│   ├── unit/                 # Unit tests for components
│   ├── integration/          # Integration testing
│   ├── performance/          # Performance benchmarks
│   └── compatibility/        # Hardware compatibility tests
└── workflows/                 # CI/CD and automation workflows
```

### Key Directories

- **`scripts/lib/`**: Core library functions used across all scripts
- **`scripts/setup/`**: Primary installation and configuration scripts  
- **`testing/automated/`**: Main testing suite and validation tools
- **`docs/user/`**: User-facing documentation and guides
- **`configs/`**: Configuration templates and system settings

See [Project Structure](docs/development/project_structure.md) for detailed directory structure.

## Documentation

### User Guides
- [Gaming Quick Reference](docs/user/gaming-quick-reference.md) - Essential gaming commands and tips
- [Gaming Stack](docs/user/gaming-stack.md) - Gaming environment documentation
- [Hardware Optimization Guide](docs/user/priority3-hardware-optimization-guide.md) - Hardware tuning guide
- [User Experience Guide](docs/user/priority4-user-experience-guide.md) - Complete user setup guide

### Development Documentation
- [Project Plan](docs/development/xanadOS_plan.md) - Overall project roadmap and goals
- [Project Structure](docs/development/project_structure.md) - Detailed directory organization
- [Performance Testing Suite](docs/development/performance-testing-suite.md) - Testing framework guide
- [Library Review](docs/development/library-review-2025-08-02.md) - Code architecture analysis

### API Documentation
- [Library Functions](scripts/lib/) - Core library documentation
- [Setup Scripts](scripts/setup/) - Installation script documentation

## Development

### Development Philosophy

This project is developed with AI assistance using modern development practices:

- **Modular Design**: Library-based architecture with clean dependencies
- **Comprehensive Testing**: Automated validation and performance testing  
- **Detailed Reporting**: Multi-format reports (HTML, JSON, Markdown)
- **Documentation-Driven**: Comprehensive guides and technical documentation
- **AI-Assisted Development**: Leveraging AI for code optimization and testing

### Architecture

xanadOS uses a modular architecture built around several core libraries:

- **`common.sh`**: Basic utilities and print functions
- **`validation.sh`**: Command detection and system validation
- **`gaming-env.sh`**: Gaming environment detection and configuration
- **`setup-common.sh`**: Shared setup and installation functions
- **`logging.sh`**: Advanced logging and reporting
- **`directories.sh`**: Directory management and organization
- **`reports.sh`**: Multi-format report generation

### Development Setup

```bash
# Clone and setup development environment
git clone https://github.com/asafelobotomy/xanadOS.git
cd xanadOS
./scripts/setup/dev-environment.sh

# Run development tests
./testing/unit/test-library-functionality.sh
./testing/automated/testing-suite.sh

# Generate development reports
./scripts/demo/gaming-matrix-integration-demo.sh
```

## Contributing

While this is primarily a personal project, contributions are welcome! Here's how you can help:

### Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include system information (distro, kernel version, hardware)
- Provide relevant log files from `docs/reports/generated/`

### Code Contributions

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style and structure
- Add tests for new functionality
- Update documentation for any changes
- Use the shared libraries in `scripts/lib/`
- Generate reports to validate changes

## Support

### Getting Help

- **Documentation**: Check the [docs/user/](docs/user/) directory for guides
- **Issues**: Create a GitHub issue for bugs or questions
- **Gaming Problems**: See [Gaming Quick Reference](docs/user/gaming-quick-reference.md)

### Common Issues

- **Permission Errors**: Ensure scripts have execute permissions (`chmod +x script.sh`)
- **Missing Dependencies**: Run `./scripts/setup/dev-environment.sh` to install requirements
- **Hardware Detection**: Check `./testing/automated/gaming-validator.sh` output

### Debug Information

When reporting issues, include:

```bash
# Generate comprehensive system report
./testing/automated/testing-suite.sh

# Check library functionality
./testing/unit/test-library-functionality.sh

# Validate gaming environment
./testing/automated/gaming-validator.sh
```

## Roadmap

### Phase 1: Foundation & Tooling ✅ Complete
- [x] Core library system
- [x] Setup and installation scripts
- [x] Testing and validation framework
- [x] Documentation system

### Phase 2: Gaming Optimization 🚧 In Progress
- [x] Steam and Lutris integration
- [x] Hardware detection and optimization
- [x] Audio latency optimization
- [ ] Advanced graphics driver management
- [ ] Controller and peripheral optimization

### Phase 3: Distribution Building 📋 Planned
- [ ] ISO building system
- [ ] Package management integration
- [ ] Automated installation process
- [ ] Live environment configuration

### Phase 4: Advanced Features 📋 Future
- [ ] Web-based configuration interface
- [ ] Remote monitoring and management
- [ ] Cloud sync for configurations
- [ ] Community package repository

## Acknowledgments

### Technologies Used

- **Arch Linux**: Base distribution
- **Bash**: Primary scripting language
- **GitHub Copilot**: AI development assistance
- **Steam Proton**: Windows gaming compatibility
- **GameMode**: Gaming performance optimization

### Inspiration

This project was inspired by the need for a comprehensive, automated gaming setup for Arch Linux that maintains the distribution's philosophy while providing gaming-specific optimizations.

### AI Development

This project extensively uses AI assistance for:
- Code optimization and review
- Testing automation
- Documentation generation
- Architecture planning

## License

This project is for personal use. While the code is publicly available for educational purposes, please respect the personal nature of this project.

### Usage Rights

- ✅ View and study the code
- ✅ Use concepts and techniques in your own projects
- ✅ Report issues and suggest improvements
- ❌ Commercial use or redistribution
- ❌ Creating competing distributions without permission

For questions about usage rights, please open an issue or contact the maintainer.

---

**Built with ❤️ and AI assistance for the Linux gaming community**
