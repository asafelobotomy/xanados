# xanadOS

A specialized Arch Linux-based gaming distribution optimized for performance and security.

## Project Status

🚧 **In Development** - Phase 1: Foundation & Tooling Complete

Current development focuses on gaming environment setup, hardware optimization, and development tooling.

## Quick Start

```bash
# Set up development environment
./scripts/setup/dev-environment.sh

# Install gaming platforms
./scripts/setup/install-steam.sh
./scripts/setup/install-lutris.sh
./scripts/setup/install-gamemode.sh

# Run gaming setup wizard
./scripts/setup/gaming-setup-wizard.sh

# Generate reports (performance, gaming, system)
./scripts/testing/reports.sh
```

## Features

- **Gaming Optimization**: Steam, Lutris, GameMode integration
- **Performance Monitoring**: Comprehensive system and gaming performance reports  
- **Hardware Optimization**: Graphics drivers, audio latency, device optimization
- **Development Tools**: Automated testing, validation, and reporting frameworks
- **Modular Architecture**: Library-based script system with proper dependency management

## Project Structure

```
scripts/
├── lib/           # Core libraries (common, logging, reports, validation)
├── setup/         # Installation and configuration scripts
├── testing/       # Performance testing and validation
├── dev-tools/     # Development utilities and analysis
└── build/         # ISO building (in development)

docs/
├── user/          # User guides and documentation
└── development/   # Development reports and technical documentation
```

See [Project Structure](docs/user/project_structure.md) for detailed directory structure.

## Documentation

- [Project Plan](docs/user/xanadOS_plan.md) - Overall project roadmap and goals
- [Project Structure](docs/user/project_structure.md) - Detailed directory organization
- [Gaming Stack](docs/user/gaming-stack.md) - Gaming environment documentation
- [Performance Testing](docs/user/performance-testing-suite.md) - Testing framework guide

## Development

This project is developed with AI assistance using modern development practices:

- **Modular Design**: Library-based architecture with clean dependencies
- **Comprehensive Testing**: Automated validation and performance testing
- **Detailed Reporting**: Multi-format reports (HTML, JSON, Markdown)
- **Documentation-Driven**: Comprehensive guides and technical documentation

## License

Personal use project - see LICENSE file for details.
