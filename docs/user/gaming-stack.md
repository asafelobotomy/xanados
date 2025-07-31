# xanadOS Gaming Stack Documentation

## Overview

The xanadOS Gaming Stack provides a comprehensive, automated gaming environment built on Arch Linux with performance optimizations, compatibility layers, and modern gaming tools.

## Gaming Software Components

### Core Gaming Platforms

#### Steam with Proton-GE

- **Native Steam Client**: Latest Steam installation with multilib support
- **Proton-GE**: Enhanced Proton with additional codec support and performance improvements
- **Automatic Updates**: Proton-GE auto-updater for latest compatibility fixes
- **Gaming Optimizations**: CPU governor switching, memory management, network tuning
- **Integration**: GameMode and MangoHud integration for optimal performance

#### Lutris Gaming Platform

- **Multi-Platform Gaming**: Support for Epic Games, GOG, Origin, Battle.net, and more
- **Wine Optimization**: Latest Wine-staging with performance patches
- **DXVK/VKD3D**: DirectX to Vulkan translation for Windows games
- **Prefix Management**: Automatic Wine prefix creation and management
- **Runner Support**: Multiple Wine versions and other game engines

#### GameMode & Performance Tools

- **GameMode Daemon**: Automatic CPU and system optimizations during gaming
- **MangoHud Overlay**: Real-time performance monitoring with customizable display
- **GOverlay**: GUI configuration tool for MangoHud settings
- **System Monitoring**: GPU, CPU, memory, and thermal monitoring
- **Performance Profiles**: Different optimization profiles for various game types

### Supporting Tools

#### Additional Gaming Platforms

- **Heroic Games Launcher**: Epic Games Store and GOG integration
- **Bottles**: Modern Wine prefix manager with gaming focus
- **RetroArch**: Comprehensive retro gaming emulation
- **PCSX2/RPCS3**: PlayStation emulation support

#### Graphics and Audio

- **Mesa Drivers**: Latest open-source graphics drivers with gaming optimizations
- **Vulkan Support**: Complete Vulkan ecosystem for modern games
- **PulseAudio/PipeWire**: Low-latency audio configuration
- **Graphics Driver Support**: NVIDIA proprietary and AMD open-source optimizations

## Installation Scripts

### Master Gaming Setup (`gaming-setup.sh`)

The unified installation script that orchestrates the complete gaming environment setup.

**Features:**

- Interactive menu-driven installation
- Complete or component-specific installation options
- Prerequisites checking and validation
- Post-installation configuration
- Unified gaming launcher creation
- Comprehensive logging and error handling

**Usage:**

```bash
cd /home/vm/Documents/xanadOS/scripts/setup
./gaming-setup.sh
```bash

**Installation Options:**

1. **Complete Gaming Setup** (Recommended)
   - All gaming platforms and tools
   - Full optimization suite
   - Unified gaming hub

2. **Component-Specific Installation**
   - Steam Only
   - Lutris & Wine Only
   - GameMode & Performance Tools Only

3. **Custom Installation**
   - Choose specific components
   - Tailored to user preferences

### Individual Installation Scripts

#### Steam Setup (`install-steam.sh`)

Automated Steam installation with Proton-GE integration.

**Key Features:**

- Multilib repository configuration
- Steam package installation with dependencies
- Proton-GE automatic installation and updates
- Steam launch optimizations
- Gaming-specific system configurations

**Commands:**

```bash
./install-steam.sh install    # Full installation
./install-steam.sh update     # Update Proton-GE
./install-steam.sh status     # Check installation status
./install-steam.sh remove     # Uninstall components
```bash

#### Lutris Setup (`install-lutris.sh`)

Comprehensive Lutris and Wine gaming environment.

**Key Features:**

- Wine-staging installation with performance optimizations
- DXVK and VKD3D configuration
- Lutris platform with all runners
- Wine prefix management automation
- Gaming library integration

**Commands:**

```bash
./install-lutris.sh install   # Full installation
./install-lutris.sh configure # Configure Wine settings
./install-lutris.sh status    # Check installation status
./install-lutris.sh remove    # Uninstall components
```bash

#### GameMode Setup (`install-gamemode.sh`)

Performance optimization tools and monitoring.

**Key Features:**

- GameMode daemon installation and configuration
- MangoHud overlay with custom presets
- GOverlay GUI management tool
- Performance monitoring utilities
- System optimization scripts

**Commands:**

```bash
./install-gamemode.sh install    # Full installation
./install-gamemode.sh configure  # Configure settings
./install-gamemode.sh status     # Check installation status
./install-gamemode.sh remove     # Uninstall components
```bash

## Gaming Launchers

### Unified Gaming Hub (`xanados-gaming`)

Central hub for launching all gaming platforms with optimizations.

**Features:**

- Single interface for all gaming platforms
- Automatic performance optimization activation
- MangoHud and GameMode integration
- Custom game launcher support
- Performance monitoring tools access

**Usage:**

```bash
xanados-gaming
```bash

### Optimized Platform Launchers

#### Steam with Optimizations

```bash
steam-gamemode          # Steam with GameMode
steam-mangohud          # Steam with MangoHud
steam-optimized         # Steam with full optimizations
```bash

#### Lutris with Optimizations

```bash
lutris-gamemode         # Lutris with GameMode
lutris-mangohud         # Lutris with MangoHud
lutris-optimized        # Lutris with full optimizations
```bash

#### Universal Game Launcher

```bash
gamemode-launch <game>  # Launch any game with optimizations
```bash

## Configuration Files

### Steam Configuration

**Location**: `~/.steam/steam/config/`

- Custom launch options for Proton-GE
- Per-game optimization settings
- Steam Input controller configurations

### Wine Configuration

**Location**: `~/.wine/` and `~/Games/wine-prefixes/`

- Optimized Wine prefixes for different games
- DXVK/VKD3D configurations
- Registry tweaks for gaming performance

### MangoHud Configuration

**Location**: `~/.config/MangoHud/`

- Custom overlay presets
- Performance monitoring settings
- Game-specific configurations

**Key Settings:**

```ini

# Main configuration (~/.config/MangoHud/MangoHud.conf)

fps_limit=0
toggle_fps_limit=F1
legacy_layout=false
horizontal
gpu_stats
cpu_stats
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
```bash

### GameMode Configuration

**Location**: `/usr/share/gamemode/` and `~/.config/gamemode/`

- CPU governor profiles
- Process priority adjustments
- I/O scheduler optimizations
- Custom game-specific settings

## Performance Optimizations

### System-Level Optimizations

#### CPU Optimizations

- Automatic CPU governor switching (powersave → performance)
- CPU frequency scaling optimization
- Process priority management
- Core pinning for critical gaming processes

#### Memory Management

- Gaming-optimized memory allocation
- Swap configuration for gaming workloads
- Memory overcommit adjustments
- Transparent hugepages optimization

#### I/O Optimizations

- SSD-optimized I/O schedulers
- Gaming-specific mount options
- Filesystem optimizations for game storage
- Reduced disk access during gaming

#### Network Optimizations

- Gaming-focused network stack tuning
- Reduced network latency configurations
- Quality of Service (QoS) prioritization
- DNS optimization for gaming services

### Graphics Optimizations

#### Driver Configurations

- Mesa driver optimizations for AMD GPUs
- NVIDIA driver settings for gaming
- Vulkan environment variables
- OpenGL performance tuning

#### Display Settings

- Variable refresh rate (VRR) support
- Low-latency display configurations
- HDR gaming support preparation
- Multi-monitor gaming optimizations

## Troubleshooting

### Common Issues

#### Steam Issues

**Problem**: Proton-GE not available in Steam
**Solution**:

```bash
./install-steam.sh update

# Restart Steam and check compatibility tools

```bash

**Problem**: Steam games not launching
**Solution**:

```bash

# Check Steam runtime

steam --reset

# Verify Proton-GE installation

ls ~/.steam/compatibilitytools.d/
```bash

#### Lutris Issues

**Problem**: Wine games not starting
**Solution**:

```bash

# Reinstall Wine dependencies

./install-lutris.sh configure

# Check Wine prefix

winecfg
```bash

**Problem**: DXVK/VKD3D not working
**Solution**:

```bash

# Verify Vulkan support

vulkaninfo | head -20

# Reinstall DXVK

lutris --install-runner dxvk
```bash

#### Performance Issues

**Problem**: GameMode not activating
**Solution**:

```bash

# Check GameMode status

gamemoded -s

# Restart GameMode daemon

sudo systemctl restart gamemode
```bash

**Problem**: MangoHud not displaying
**Solution**:

```bash

# Test MangoHud

MANGOHUD=1 glxgears

# Check configuration

cat ~/.config/MangoHud/MangoHud.conf
```bash

### Debug Commands

#### System Information

```bash

# Check gaming environment

./scripts/utilities/xanados-gaming-optimizer --status

# Graphics information

glxinfo | grep -E "(OpenGL|vendor|renderer)"
vulkaninfo | head -30

# Audio information

pactl info
aplay -l
```bash

#### Gaming Process Monitoring

```bash

# Monitor gaming processes

ps aux | grep -E "(steam|lutris|wine|proton)"

# Check GameMode status

gamemoded -s

# Monitor system resources

htop -u $USER
```bash

## Advanced Configuration

### Custom Game Profiles

Create custom optimization profiles for specific games:

**Location**: `~/.config/xanados/game-profiles/`

**Example Profile** (`~/.config/xanados/game-profiles/cyberpunk2077.conf`):

```ini
[Game]
name=Cyberpunk 2077
executable=Cyberpunk2077.exe

[Optimizations]
cpu_governor=performance
io_scheduler=mq-deadline
cpu_affinity=0-7
nice_level=-10

[Environment]
DXVK_HUD=fps,memory
MANGOHUD=1
RADV_PERFTEST=aco

[Limits]
fps_limit=60
cpu_limit=90
```bash

### Integration with System Optimization

The gaming stack integrates with the broader xanadOS optimization framework:

- **CPU Governor Integration**: Automatic switching during gaming sessions
- **System Monitoring**: Integration with system-wide performance monitoring
- **Security Profiles**: Gaming-specific AppArmor and firewall configurations
- **Automation**: Integration with xanadOS automation scripts

### Future Enhancements

#### Planned Features

- **Cloud Gaming Integration**: GeForce Now, Xbox Cloud Gaming support
- **VR Gaming Support**: SteamVR and OpenXR optimization
- **Streaming Optimization**: OBS Studio integration for game streaming
- **AI-Powered Optimization**: Machine learning-based performance tuning
- **Hardware Detection**: Automatic optimization based on detected hardware

#### Community Contributions

- Game-specific optimization profiles
- Hardware compatibility testing
- Performance benchmarking database
- User-contributed gaming configurations

## Maintenance

### Regular Maintenance Tasks

#### Weekly

```bash

# Update Proton-GE

./install-steam.sh update

# Update Wine runners in Lutris

lutris --update-runners

# Clean gaming caches

./scripts/utilities/cleanup-gaming-cache.sh
```bash

#### Monthly

```bash

# Full gaming stack update

./gaming-setup.sh

# Verify system optimizations

./scripts/utilities/xanados-gaming-optimizer --verify

# Clean old Wine prefixes

./scripts/utilities/cleanup-wine-prefixes.sh
```bash

### Backup and Recovery

#### Important Directories to Backup

- `~/.steam/` - Steam configuration and games
- `~/Games/wine-prefixes/` - Wine game installations
- `~/.local/share/lutris/` - Lutris configuration
- `~/.config/MangoHud/` - Performance monitoring settings

#### Backup Script

```bash
#!/bin/bash

# Gaming backup script

BACKUP_DIR="$HOME/Backups/gaming-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/steam-config.tar.gz" ~/.steam/config/
tar -czf "$BACKUP_DIR/lutris-config.tar.gz" ~/.local/share/lutris/
tar -czf "$BACKUP_DIR/mangohud-config.tar.gz" ~/.config/MangoHud/
cp -r ~/Games/wine-prefixes/ "$BACKUP_DIR/"
```bash

## Performance Metrics

### Benchmarking Tools

- **Built-in Benchmarks**: Steam games with built-in benchmark modes
- **Unigine Benchmarks**: Heaven, Valley, Superposition for graphics testing
- **Gaming Performance Tests**: 3DMark via Wine/Proton
- **Custom Benchmarks**: Game-specific performance testing scripts

### Performance Monitoring

- **MangoHud Logging**: Automatic performance data collection
- **System Metrics**: CPU, GPU, memory usage during gaming
- **Thermal Monitoring**: Temperature tracking during gaming sessions
- **Power Consumption**: Battery/power usage monitoring for laptops

## Integration with xanadOS

The gaming stack is fully integrated with the broader xanadOS ecosystem:

- **Build System**: Gaming packages included in ISO builds
- **Security Framework**: Gaming-specific security profiles
- **Automation**: Gaming optimization triggers and automation
- **System Monitoring**: Integration with system-wide monitoring tools
- **Package Management**: Gaming package tracking and updates

This documentation provides comprehensive coverage of the xanadOS gaming stack, from installation to advanced configuration and maintenance.

