# xanadOS Gaming Profiles Guide

> Comprehensive guide to xanadOS gaming profiles and optimization strategies

## Table of Contents

- [Overview](#overview)
- [Gaming Profile Types](#gaming-profile-types)
- [Performance Priorities](#performance-priorities)
- [System Optimizations](#system-optimizations)
- [Profile Management](#profile-management)
- [Hardware Recommendations](#hardware-recommendations)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)

## Overview

xanadOS gaming profiles provide intelligent, hardware-aware optimization for different gaming scenarios. Each profile automatically configures system settings, software configurations, and performance parameters to deliver the best experience for specific types of gaming.

### Key Features

- **7 Specialized Gaming Types**: Each optimized for different gaming scenarios
- **5 Performance Priority Levels**: Fine-tune the balance between performance and quality
- **Hardware-Aware Recommendations**: Automatic detection and optimization for your specific hardware
- **Automatic Software Configuration**: Steam, MangoHud, and system settings configured automatically
- **Import/Export Support**: Share profiles and backup configurations

### Quick Start

```bash
# Access gaming profiles through the setup wizard
./scripts/setup/gaming-setup-wizard.sh

# Or manage profiles directly
source scripts/lib/gaming-profiles.sh
create_gaming_profile
list_gaming_profiles
apply_gaming_profile "profile_name"
```

## Gaming Profile Types

### 🏆 Competitive Gaming Profile

**Best for**: Esports, competitive FPS games, online multiplayer

**Optimization Focus**: Maximum frame rate, minimal input latency, consistent performance

#### System Optimizations
- **CPU Governor**: `performance` - Maximum clock speeds at all times
- **Memory Management**: Aggressive low-latency settings
  - Swappiness: 10 (minimal swap usage)
  - Cache pressure: 50 (optimized for gaming workloads)
- **I/O Scheduler**: `mq-deadline` - Predictable, low-latency disk access
- **GPU**: Maximum performance mode, reduced power management

#### Software Configuration
- **Steam Launch Options**:
  - `-novid` - Skip startup videos
  - `-nojoy` - Disable joystick support (reduces input lag)
  - `-nobreakpad` - Disable crash reporting
  - `-noshaderapi` - Faster startup
- **Steam Overlay**: **Disabled** - Eliminates overlay input lag
- **Shader Cache**: Enabled for consistency
- **Proton**: Latest stable version with Proton-GE

#### MangoHud Display
- **Position**: Top-right (minimal interference)
- **Metrics**: FPS only (minimal overlay)
- **Style**: Small, transparent

#### Ideal Hardware
- High refresh rate monitors (120Hz, 144Hz, 240Hz+)
- Gaming keyboards with low input lag
- Gaming mice with high polling rates
- Fast NVMe SSDs

#### Target Games
- Counter-Strike 2, Valorant, Apex Legends
- League of Legends, Dota 2
- Rocket League, Overwatch 2

---

### 🎮 Casual Gaming Profile

**Best for**: General gaming, single-player adventures, indie games

**Optimization Focus**: Balanced performance and quality, stable experience

#### System Optimizations
- **CPU Governor**: `schedutil` - Intelligent frequency scaling
- **Memory Management**: Balanced settings
  - Swappiness: 60 (standard setting)
  - Cache pressure: 100 (balanced)
- **I/O Scheduler**: Optimized but not aggressive
- **GPU**: Balanced performance/efficiency mode

#### Software Configuration
- **Steam Launch Options**: Standard (no aggressive optimizations)
- **Steam Overlay**: **Enabled** - Full functionality
- **Shader Cache**: Enabled
- **Proton**: Latest version with Proton-GE for compatibility

#### MangoHud Display
- **Position**: Top-left
- **Metrics**: FPS, GPU stats, CPU stats, memory, temperature
- **Style**: Full monitoring for optimization insights

#### Ideal Hardware
- 1080p or 1440p monitors at 60Hz
- Standard gaming peripherals
- SATA or NVMe SSDs

#### Target Games
- The Witcher 3, Cyberpunk 2077 (moderate settings)
- Indie games, platformers
- Strategy games, RPGs

---

### 🎬 Cinematic Gaming Profile

**Best for**: Story-driven games, AAA titles, screenshot/video capture

**Optimization Focus**: Maximum visual quality, cinematic experience

#### System Optimizations
- **CPU Governor**: `performance` when needed, `schedutil` for efficiency
- **Memory Management**: Optimized for large textures and assets
  - Swappiness: 30 (less aggressive swapping)
  - Enhanced buffer cache for large files
- **I/O Scheduler**: Optimized for large sequential reads
- **GPU**: Maximum quality settings prioritized

#### Software Configuration
- **Steam Launch Options**: Quality-focused (no performance sacrifices)
- **Steam Overlay**: Enabled with enhanced features
- **Shader Cache**: **Prioritized** - Precompiled for visual consistency
- **Proton**: Latest version with all compatibility layers

#### MangoHud Display
- **Position**: Top-left or configurable
- **Metrics**: Full monitoring including detailed temperature data
- **Style**: Comprehensive for quality assurance

#### Ideal Hardware
- 4K monitors or high-resolution displays
- High-end GPUs (RTX 3070+, RX 6700 XT+)
- 32GB+ RAM for large games
- Fast NVMe SSDs for texture streaming

#### Target Games
- Red Dead Redemption 2, Horizon Zero Dawn
- Microsoft Flight Simulator
- AAA single-player titles with raytracing

---

### 🕹️ Retro Gaming Profile

**Best for**: Emulation, classic games, DOSBox titles

**Optimization Focus**: Compatibility, stable frame pacing, power efficiency

#### System Optimizations
- **CPU Governor**: `schedutil` or `conservative` - Efficient for older games
- **Memory Management**: Conservative settings
  - Standard swappiness (60)
  - Optimized for smaller memory footprints
- **I/O Scheduler**: Standard settings
- **GPU**: Power-efficient mode

#### Software Configuration
- **Steam Launch Options**: Compatibility-focused
- **Steam Overlay**: Enabled but lightweight
- **Proton**: **Disabled** for many titles (native Linux or specific emulators)
- **Emulator Integration**: DOSBox, ScummVM, RetroArch optimizations

#### MangoHud Display
- **Position**: Bottom-right (non-intrusive)
- **Metrics**: Basic monitoring (FPS, temperature)
- **Style**: Minimal, retro-friendly

#### Ideal Hardware
- Any modern hardware (retro games are not demanding)
- Focus on controller compatibility
- Good speakers/headphones for audio

#### Target Games
- Classic arcade games, NES/SNES/Genesis emulation
- DOSBox games (Commander Keen, Doom)
- Early 3D games (Quake, Half-Life)

---

### 🥽 VR Gaming Profile

**Best for**: Virtual Reality gaming, VR development

**Optimization Focus**: Ultra-low latency, consistent frame times, motion-to-photon optimization

#### System Optimizations
- **CPU Governor**: `performance` - VR requires absolute consistency
- **Memory Management**: Ultra-low latency settings
  - Swappiness: 1 (virtually no swapping)
  - Real-time priority adjustments
- **I/O Scheduler**: `mq-deadline` - Minimal latency
- **GPU**: Maximum performance, no power saving
- **USB**: Enhanced polling rates for VR headsets

#### Software Configuration
- **Steam Launch Options**: VR-specific optimizations
- **Steam Overlay**: VR-compatible mode
- **SteamVR**: Enhanced integration and optimization
- **VR Runtime**: Optimized for specific headsets

#### MangoHud Display
- **Position**: VR-safe positioning
- **Metrics**: Minimal (FPS, frame time)
- **Style**: VR-compatible minimal overlay

#### Ideal Hardware
- VR-ready GPUs (RTX 3060+, RX 6600 XT+)
- High-end CPUs for consistent frame times
- Fast RAM (3200MHz+)
- USB 3.0+ ports for headset connectivity

#### Target Games
- Half-Life: Alyx, Beat Saber
- VRChat, Rec Room
- VR development environments

#### Critical Settings
- **Target Frame Rate**: 90Hz minimum (120Hz preferred)
- **Motion-to-Photon Latency**: <20ms target
- **Frame Time Consistency**: <1ms variance

---

### 📺 Streaming Gaming Profile

**Best for**: Gaming while streaming, content creation, live broadcasting

**Optimization Focus**: Stable performance while encoding, balanced resource allocation

#### System Optimizations
- **CPU Governor**: `performance` - CPU-intensive encoding
- **Memory Management**: Enhanced for video encoding buffers
  - Swappiness: 20 (minimal to preserve encoding memory)
  - Large buffer allocations for streaming
- **I/O Scheduler**: Optimized for simultaneous gaming and encoding
- **GPU**: Dual workload optimization (gaming + encoding)

#### Software Configuration
- **Steam Launch Options**: Streaming-compatible settings
- **Steam Overlay**: Stream-safe positioning
- **Hardware Acceleration**: NVENC, AMF, or QuickSync enabled
- **OBS Integration**: Optimized game capture settings

#### MangoHud Display
- **Position**: Stream-safe area (typically bottom-left)
- **Metrics**: Stream-relevant data (FPS, encoding stats)
- **Style**: Clean, readable on stream

#### Ideal Hardware
- Multi-core CPUs (8+ cores) or dedicated streaming PCs
- GPUs with hardware encoding (RTX series, RX 6000+)
- 32GB+ RAM for simultaneous workloads
- Fast upload internet connection

#### Target Use Cases
- Twitch/YouTube streaming
- Content creation and tutorials
- Multiplayer gaming with audience interaction

---

### 🛠️ Development Gaming Profile

**Best for**: Game development, testing, debugging

**Optimization Focus**: Detailed monitoring, debugging support, consistent testing environment

#### System Optimizations
- **CPU Governor**: `schedutil` - Balanced for development tools
- **Memory Management**: Debug-friendly settings
  - Standard swappiness with debug allocations
  - Enhanced crash dump support
- **I/O Scheduler**: Standard with logging enhancements
- **GPU**: Debugging-enabled mode

#### Software Configuration
- **Steam Launch Options**: Developer mode features
- **Steam Overlay**: Development tools integration
- **Debug Symbols**: Enhanced debugging support
- **Profiling Tools**: Performance analysis integration

#### MangoHud Display
- **Position**: Configurable for testing
- **Metrics**: Comprehensive development metrics
- **Style**: Detailed performance data

#### Ideal Hardware
- Development workstations
- Multiple monitors for code + game
- Fast SSDs for project compilation
- Ample RAM for development tools

#### Target Use Cases
- Unity/Unreal Engine development
- Indie game testing
- Performance profiling and optimization

## Performance Priorities

Each gaming profile can be fine-tuned with these performance priority levels:

### 🚀 Maximum FPS Priority
- **Focus**: Highest possible frame rate
- **Trade-offs**: Reduced visual quality, minimal effects
- **CPU**: Maximum performance mode
- **GPU**: Performance mode, reduced quality settings
- **Memory**: Optimized for speed over capacity
- **Best for**: Competitive gaming, high refresh rate monitors

### ⚖️ Balanced Priority
- **Focus**: Optimal balance of performance and quality
- **Trade-offs**: Moderate settings across all areas
- **CPU**: Intelligent scaling based on load
- **GPU**: Balanced performance/quality
- **Memory**: Standard optimizations
- **Best for**: General gaming, most users

### 🎨 Visual Quality Priority
- **Focus**: Maximum visual fidelity
- **Trade-offs**: Lower frame rates for better graphics
- **CPU**: Quality-focused optimizations
- **GPU**: Maximum quality settings
- **Memory**: Optimized for large textures
- **Best for**: Single-player games, screenshot enthusiasts

### 🔋 Power Efficiency Priority
- **Focus**: Minimize power consumption and heat
- **Trade-offs**: Reduced performance for efficiency
- **CPU**: Conservative frequency scaling
- **GPU**: Efficient mode, lower clocks
- **Memory**: Power-saving configurations
- **Best for**: Laptops, quiet systems, low power consumption

### 🛡️ Stability Priority
- **Focus**: Consistent, reliable performance
- **Trade-offs**: Conservative settings for stability
- **CPU**: Stable frequencies, no overclocking
- **GPU**: Conservative clocks, thermal limits
- **Memory**: Error-checking enabled where possible
- **Best for**: Long gaming sessions, system stability

## System Optimizations

### CPU Governor Settings

Gaming profiles automatically configure CPU frequency scaling:

- **performance**: Maximum frequency at all times
- **schedutil**: Intelligent scaling based on system load
- **conservative**: Gradual frequency changes for stability
- **powersave**: Minimum frequency for efficiency

### Memory Management

Optimizations include:

- **Swappiness**: Controls swap usage (1-100 scale)
- **Cache Pressure**: Balances memory cache vs application memory
- **Dirty Ratio**: Controls when data is written to disk
- **OOM Killer**: Out-of-memory handling for gaming workloads

### I/O Scheduler Optimization

Different schedulers for different workloads:

- **mq-deadline**: Low latency, predictable access (competitive gaming)
- **bfq**: Balanced fairness for mixed workloads
- **noop**: Minimal overhead for SSDs
- **kyber**: Modern multiqueue scheduler

### Graphics Optimization

Automatic configuration of:

- **GPU power management**: Performance vs efficiency modes
- **Driver-specific settings**: NVIDIA/AMD optimizations
- **Vulkan/OpenGL**: API-specific optimizations
- **Shader compilation**: Precompiled vs runtime compilation

## Profile Management

### Creating Profiles

```bash
# Interactive profile creation
source scripts/lib/gaming-profiles.sh
create_gaming_profile

# The wizard will guide you through:
# 1. Profile name and description
# 2. Hardware detection and recommendations
# 3. Gaming type selection
# 4. Performance priority configuration
# 5. Custom settings (optional)
```

### Listing Profiles

```bash
# Table format (default)
list_gaming_profiles

# JSON format for scripting
list_gaming_profiles json

# Names only
list_gaming_profiles names
```

### Applying Profiles

```bash
# Apply a profile
apply_gaming_profile "competitive_fps"

# Dry run (preview changes)
apply_gaming_profile "competitive_fps" true
```

### Exporting and Importing

```bash
# Export profile for sharing
export_gaming_profile "my_profile" "/path/to/export/"

# Import profile from file
import_gaming_profile "/path/to/profile.json"
```

### Profile Backup and Restore

Profiles are automatically backed up before:
- Profile deletion
- System changes
- Profile modifications

Backups are stored in: `~/.config/xanados/gaming-profiles/backups/`

## Hardware Recommendations

### System Requirements by Profile Type

#### Competitive Gaming
- **CPU**: High single-core performance (Intel i5-12400+, AMD Ryzen 5 5600+)
- **GPU**: High frame rate capable (RTX 3060+, RX 6600+)
- **RAM**: 16GB+ with low latency (3200MHz+)
- **Storage**: NVMe SSD for fast game loading
- **Monitor**: High refresh rate (144Hz+, low input lag)

#### Cinematic Gaming
- **CPU**: Multi-core performance (Intel i7-12700+, AMD Ryzen 7 5700X+)
- **GPU**: High-end graphics (RTX 3070+, RX 6700 XT+)
- **RAM**: 32GB+ for large games
- **Storage**: Fast NVMe SSD (PCIe 4.0 preferred)
- **Monitor**: 4K or high-resolution displays

#### VR Gaming
- **CPU**: Consistent performance (Intel i5-12400+, AMD Ryzen 5 5600+)
- **GPU**: VR-ready (RTX 3060+, RX 6600 XT+)
- **RAM**: 16GB+ with fast memory
- **Storage**: Fast SSD for quick loading
- **USB**: Multiple USB 3.0+ ports

#### Streaming Gaming
- **CPU**: High core count (Intel i7-12700+, AMD Ryzen 7 5700X+)
- **GPU**: Hardware encoding support (RTX series, RX 6000+)
- **RAM**: 32GB+ for dual workloads
- **Storage**: Fast SSDs for recording
- **Network**: High upload bandwidth

### Hardware Detection

xanadOS automatically detects and optimizes for:

```bash
# Hardware detection includes:
- CPU model and core count
- GPU vendor and model
- Available RAM and speed
- Storage type (HDD/SSD/NVMe)
- Monitor resolution and refresh rate
- Audio hardware
- Input devices
```

## Advanced Configuration

### Custom Launch Options

Add game-specific optimizations:

```bash
# Steam launch options by profile type:
# Competitive: -novid -nojoy -nobreakpad
# Cinematic: -vulkan -borderless
# VR: -vr -room_setup
```

### MangoHud Customization

Configure performance overlay:

```bash
# Edit MangoHud configuration per profile
~/.config/xanados/gaming-profiles/mangohud/
├── competitive.conf
├── casual.conf
├── cinematic.conf
└── custom.conf
```

### System Service Integration

Gaming profiles integrate with:

- **GameMode**: Automatic activation for gaming sessions
- **Steam**: Launch option management
- **GPU drivers**: Performance profile switching
- **Audio**: Low-latency audio configuration

### Environment Variables

Gaming-specific environment variables:

```bash
# Automatically set by gaming profiles:
export MANGOHUD=1
export RADV_PERFTEST=aco
export __GL_THREADED_OPTIMIZATIONS=1
export WINE_CPU_TOPOLOGY=4:2
```

## Troubleshooting

### Common Issues

#### Profile Not Applying
```bash
# Check profile validity
source scripts/lib/gaming-profiles.sh
load_gaming_profile "profile_name"

# Verify system permissions
sudo journalctl -u xanados-gaming-optimization

# Reset to default profile
apply_gaming_profile "default"
```

#### Performance Issues
```bash
# Check current optimizations
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /proc/sys/vm/swappiness

# Validate hardware detection
./scripts/demo/gaming-hardware-demo.sh

# Run performance tests
./testing/automated/performance-benchmark.sh
```

#### Software Configuration Problems
```bash
# Verify Steam integration
steam -console +quit

# Check MangoHud installation
mangohud --version

# Validate Proton setup
ls ~/.steam/steam/steamapps/common/Proton*/
```

### Logging and Debugging

Enable detailed logging:

```bash
# Set debug logging
export XANADOS_DEBUG=1
export GAMING_PROFILE_DEBUG=1

# Check logs
tail -f ~/.config/xanados/logs/gaming-profiles.log

# Profile application logs
journalctl -f -u xanados-gaming-optimization
```

### Performance Monitoring

Monitor profile effectiveness:

```bash
# Real-time performance monitoring
watch -n 1 'cat /proc/loadavg; cat /sys/class/thermal/thermal_zone*/temp'

# Gaming session analysis
./testing/automated/gaming-session-analysis.sh

# Compare profile performance
./testing/automated/profile-comparison-test.sh
```

### Reset and Recovery

#### Reset Individual Profile
```bash
# Reset specific profile to defaults
delete_gaming_profile "profile_name" false
create_gaming_profile  # Recreate with detected settings
```

#### Reset All Profiles
```bash
# Backup existing profiles
cp -r ~/.config/xanados/gaming-profiles/ ~/gaming-profiles-backup/

# Reset to system defaults
rm -rf ~/.config/xanados/gaming-profiles/
create_default_gaming_profile
```

#### System Recovery
```bash
# Restore system to non-gaming state
./scripts/utilities/restore-system-defaults.sh

# Reapply conservative settings
apply_gaming_profile "default"
```

---

## Additional Resources

- **Gaming Setup Wizard**: Interactive profile creation and management
- **Performance Testing Suite**: Validate profile effectiveness
- **Hardware Optimization Guide**: Detailed hardware tuning
- **Gaming Quick Reference**: Essential commands and shortcuts

For technical support and advanced configuration, see the [xanadOS Development Documentation](../development/README.md).

---

**Last Updated**: August 3, 2025
**xanadOS Version**: Phase 4.1.3+
**Gaming Profiles Library Version**: 1.0.0
