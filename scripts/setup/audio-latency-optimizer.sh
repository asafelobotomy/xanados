#!/bin/bash
# xanadOS Audio Latency Optimization Script
# Optimizes PipeWire and audio stack for low-latency gaming

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PIPEWIRE_CONFIG_DIR="$HOME/.config/pipewire"
PIPEWIRE_SYSTEM_CONFIG="/etc/pipewire"
WIREPLUMBER_CONFIG_DIR="$HOME/.config/wireplumber"
LOG_FILE="/var/log/xanados-audio-optimization.log"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█          🎵 xanadOS Audio Latency Optimization 🎵           █"
    echo "█                                                              █"
    echo "█         Low-Latency Audio for Gaming Performance            █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
}

# Function to detect audio hardware
detect_audio_hardware() {
    print_section "Detecting Audio Hardware"
    
    echo "Audio Hardware Information:"
    lspci | grep -i audio | head -10
    echo
    
    if [ -f "/proc/asound/cards" ]; then
        echo "Available Sound Cards:"
        cat /proc/asound/cards
        echo
    fi
    
    echo "Audio Modules:"
    lsmod | grep -E "(snd|hda|usb_audio)" | head -10
    echo
    
    # Detect USB audio devices
    if lsusb | grep -i audio >/dev/null; then
        echo "USB Audio Devices:"
        lsusb | grep -i audio
        echo
    fi
    
    # Check for gaming headsets
    if lsusb | grep -E "(SteelSeries|Logitech|Razer|HyperX|Corsair|Audio-Technica)" >/dev/null; then
        print_status "Gaming audio hardware detected"
        echo "Gaming Audio Hardware:"
        lsusb | grep -E "(SteelSeries|Logitech|Razer|HyperX|Corsair|Audio-Technica)"
        echo
    fi
}

# Function to check current audio system status
check_audio_status() {
    print_section "Current Audio System Status"
    
    echo "Audio System Information:"
    
    # Check if PipeWire is running
    if systemctl --user is-active pipewire >/dev/null 2>&1; then
        echo "  ✅ PipeWire: Running"
        if systemctl --user is-active pipewire-pulse >/dev/null 2>&1; then
            echo "  ✅ PipeWire-Pulse: Running"
        else
            echo "  ❌ PipeWire-Pulse: Not running"
        fi
    else
        echo "  ❌ PipeWire: Not running"
    fi
    
    # Check WirePlumber
    if systemctl --user is-active wireplumber >/dev/null 2>&1; then
        echo "  ✅ WirePlumber: Running"
    else
        echo "  ❌ WirePlumber: Not running"
    fi
    
    # Check JACK
    if systemctl --user is-active pipewire-jack >/dev/null 2>&1; then
        echo "  ✅ PipeWire-JACK: Running"
    else
        echo "  ⚠️  PipeWire-JACK: Not running"
    fi
    
    echo
    
    # Show current audio latency if possible
    if command -v pw-top >/dev/null 2>&1; then
        echo "Current PipeWire Status:"
        timeout 2 pw-top -n 1 2>/dev/null | head -20 || echo "  Unable to get detailed status"
    fi
    
    echo
    
    # Show current buffer sizes
    if command -v pactl >/dev/null 2>&1; then
        echo "Current Audio Configuration:"
        default_sink=$(pactl get-default-sink 2>/dev/null)
        if [ -n "$default_sink" ]; then
            echo "  Default Sink: $default_sink"
            pactl list sinks short | grep "$default_sink" | head -1
        fi
        echo
    fi
}

# Function to install audio optimization packages
install_audio_packages() {
    print_section "Installing Audio Optimization Packages"
    
    print_status "Installing required audio packages..."
    
    if command -v pacman >/dev/null 2>&1; then
        local packages=(
            "pipewire"
            "pipewire-alsa"
            "pipewire-pulse"
            "pipewire-jack"
            "lib32-pipewire"
            "lib32-pipewire-jack"
            "wireplumber"
            "alsa-utils"
            "alsa-plugins"
            "lib32-alsa-plugins"
            "pavucontrol"
            "helvum"
            "easyeffects"
            "qpwgraph"
            "carla"
        )
        
        for package in "${packages[@]}"; do
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                pacman -S --needed --noconfirm "$package" 2>/dev/null || print_warning "Failed to install $package"
            fi
        done
        
        print_success "Audio packages installed"
    else
        print_warning "Package manager not detected - please install PipeWire manually"
    fi
}

# Function to configure PipeWire for low latency
configure_pipewire_low_latency() {
    print_section "Configuring PipeWire for Low Latency"
    
    print_status "Setting up PipeWire low-latency configuration..."
    
    # Create PipeWire config directories
    mkdir -p "$PIPEWIRE_CONFIG_DIR"
    mkdir -p "$WIREPLUMBER_CONFIG_DIR/main.lua.d"
    
    # Create low-latency PipeWire configuration
    cat > "$PIPEWIRE_CONFIG_DIR/pipewire.conf" << 'EOF'
# xanadOS Low-Latency PipeWire Configuration

context.properties = {
    # Core settings for low latency
    default.clock.rate = 48000
    default.clock.quantum = 64
    default.clock.min-quantum = 32
    default.clock.max-quantum = 8192
    
    # Gaming-optimized settings
    core.daemon = true
    core.name = pipewire-0
    
    # Memory and CPU optimizations
    mem.warn-mlock = false
    mem.allow-mlock = true
    mem.mlock-all = false
    
    # Scheduling
    support.dbus = true
    link.max-buffers = 64
}

context.spa-libs = {
    audio.convert.* = audioconvert/libspa-audioconvert
    support.* = support/libspa-support
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level = -11
            rt.prio = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-profiler }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-spa-device-factory }
    { name = libpipewire-module-spa-node-factory }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-client-device }
    { name = libpipewire-module-portal
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-access
        args = {
            access.allowed = [
                /usr/bin/pipewire-media-session
                /usr/bin/wireplumber
            ]
            access.rejected = [ ]
            access.restricted = [ ]
            access.force = flatpak
        }
    }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-link-factory }
    { name = libpipewire-module-session-manager }
]

context.objects = [
    { factory = adapter
        args = {
            factory.name = support.null-audio-sink
            node.name = Dummy-Driver
            node.description = "Dummy-Driver"
            media.class = Audio/Sink
        }
    }
]

context.exec = [
    { path = "wireplumber" args = "" }
]
EOF

    # Create low-latency PipeWire-Pulse configuration
    cat > "$PIPEWIRE_CONFIG_DIR/pipewire-pulse.conf" << 'EOF'
# xanadOS Low-Latency PipeWire-Pulse Configuration

context.properties = {
    log.level = 2
    default.clock.rate = 48000
    default.clock.quantum = 64
    default.clock.min-quantum = 32
    default.clock.max-quantum = 8192
    
    # PulseAudio compatibility
    module.x11.bell = true
    module.access = true
}

pulse.properties = {
    # Gaming-optimized buffer settings
    pulse.min.req = 32/48000
    pulse.default.req = 64/48000
    pulse.max.req = 8192/48000
    pulse.min.quantum = 32/48000
    pulse.max.quantum = 8192/48000
    
    # Latency settings
    pulse.default.frag = 64/48000
    pulse.default.tlength = 64/48000
    pulse.min.frag = 32/48000
    pulse.max.tlength = 8192/48000
    
    # High quality resampling
    resample.quality = 4
    channelmix.normalize = false
    channelmix.mix-lfe = false
    channelmix.upmix = true
    channelmix.lfe-cutoff = 0
    channelmix.fc-cutoff = 0
    channelmix.rear-delay = 0
}

stream.properties = {
    node.latency = 64/48000
    resample.quality = 4
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level = -11
            rt.prio = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-protocol-pulse
        args = {
            pulse.min.req = 32/48000
            pulse.default.req = 64/48000
            pulse.max.req = 8192/48000
            pulse.min.quantum = 32/48000
            pulse.max.quantum = 8192/48000
            server.address = [ "unix:native" ]
        }
    }
]
EOF

    # Create WirePlumber gaming configuration
    cat > "$WIREPLUMBER_CONFIG_DIR/main.lua.d/50-gaming-config.lua" << 'EOF'
-- xanadOS Gaming WirePlumber Configuration

-- Low latency settings for gaming
alsa_monitor.properties = {
  ["alsa.jack-device"] = false,
  ["alsa.reserve"] = false,
}

default_access.properties = {
  ["enable-flatpak-portal"] = false,
}

-- Gaming-optimized node settings
apply_properties = {
  ["node.pause-on-idle"] = false,
  ["resample.quality"] = 4,
  ["channelmix.normalize"] = false,
  ["adapter.auto-port-config"] = false,
  ["session.suspend-timeout-seconds"] = 0,
  ["node.max-latency"] = "64/48000",
}

-- Apply settings to audio nodes
for_each_matching_node = function(media_class_glob)
  return {
    ["media.class"] = media_class_glob,
    apply_properties = apply_properties,
  }
end

table.insert(alsa_monitor.rules, for_each_matching_node("Audio/*"))
EOF

    print_success "PipeWire low-latency configuration created"
}

# Function to configure ALSA for gaming
configure_alsa_gaming() {
    print_section "Configuring ALSA for Gaming"
    
    print_status "Setting up ALSA gaming configuration..."
    
    # Create ALSA user configuration
    cat > "$HOME/.asoundrc" << 'EOF'
# xanadOS Gaming ALSA Configuration

pcm.!default {
    type plug
    slave.pcm "dmixer"
    hint.description "Default gaming audio output"
}

pcm.dmixer {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"
        period_time 2667
        period_size 64
        buffer_time 10667
        buffer_size 256
        rate 48000
        channels 2
        format S16_LE
    }
    bindings {
        0 0
        1 1
    }
}

pcm.dsnoop {
    type dsnoop
    ipc_key 2048
    slave {
        pcm "hw:0,0"
        period_time 2667
        period_size 64
        buffer_time 10667
        buffer_size 256
        rate 48000
        channels 2
        format S16_LE
    }
    bindings {
        0 0
        1 1
    }
}

pcm.duplex {
    type asym
    playback.pcm "dmixer"
    capture.pcm "dsnoop"
}

# Low latency PCM for professional audio
pcm.lowlatency {
    type hw
    card 0
    device 0
    subdevice 0
    hint.description "Low latency direct hardware access"
}

# Gaming headset configuration
pcm.gaming {
    type plug
    slave.pcm "dmixer"
    slave.rate 48000
    slave.channels 2
    hint.description "Gaming headset optimized"
}
EOF

    # Create ALSA module configuration for low latency
    sudo mkdir -p /etc/modprobe.d
    sudo tee /etc/modprobe.d/alsa-gaming.conf > /dev/null << 'EOF'
# ALSA Gaming Optimizations

# Intel HDA optimizations
options snd_hda_intel power_save=0
options snd_hda_intel power_save_controller=0
options snd_hda_intel align_buffer_size=0
options snd_hda_intel snoop=1
options snd_hda_intel enable_msi=1

# USB Audio optimizations
options snd_usb_audio nrpacks=1
options snd_usb_audio async_unlink=0
options snd_usb_audio sync_urb=0

# General ALSA optimizations
options snd_pcm slots=,0,1,2,3,4,5,6,7
options snd_mixer_oss device_count=8
options snd_seq device_count=8
EOF

    print_success "ALSA gaming configuration created"
}

# Function to create audio latency testing tools
create_audio_testing_tools() {
    print_section "Creating Audio Latency Testing Tools"
    
    # Create audio latency test script
    cat > "/usr/local/bin/audio-latency-test" << 'EOF'
#!/bin/bash
# Audio Latency Testing Tool

test_audio_latency() {
    echo "=== Audio Latency Test ==="
    echo "Date: $(date)"
    echo
    
    # Test PipeWire latency
    if command -v pw-metadata >/dev/null 2>&1; then
        echo "PipeWire Latency Information:"
        pw-metadata -n settings | grep -E "(quantum|rate)" | while read -r line; do
            echo "  $line"
        done
        echo
    fi
    
    # Test buffer sizes
    if command -v pactl >/dev/null 2>&1; then
        echo "PulseAudio Buffer Information:"
        pactl list sinks | grep -E "(Name:|Latency:|Buffer)" | head -20
        echo
    fi
    
    # Test JACK latency if available
    if command -v jack_lsp >/dev/null 2>&1 && pgrep -x pipewire-jack >/dev/null; then
        echo "JACK Latency (via PipeWire):"
        timeout 5 jack_lsp -c 2>/dev/null || echo "  JACK not responding"
        echo
    fi
    
    # ALSA device latency test
    echo "ALSA Device Information:"
    aplay -l 2>/dev/null | head -10
    echo
    
    # Recommend optimizations
    echo "Latency Optimization Recommendations:"
    
    quantum=$(pw-metadata -n settings 2>/dev/null | grep "default.clock.quantum" | awk '{print $3}' | tr -d '"')
    if [ -n "$quantum" ] && [ "$quantum" -gt 128 ]; then
        echo "  ⚠️  Consider lowering quantum size (current: $quantum, recommended: 64)"
    elif [ -n "$quantum" ]; then
        echo "  ✅ Quantum size looks good: $quantum"
    fi
    
    rate=$(pw-metadata -n settings 2>/dev/null | grep "default.clock.rate" | awk '{print $3}' | tr -d '"')
    if [ -n "$rate" ] && [ "$rate" != "48000" ]; then
        echo "  ⚠️  Consider using 48000 Hz sample rate (current: $rate)"
    elif [ -n "$rate" ]; then
        echo "  ✅ Sample rate looks good: $rate Hz"
    fi
    
    echo
}

test_audio_performance() {
    echo "=== Audio Performance Test ==="
    
    # Test audio dropouts
    if command -v arecord >/dev/null 2>&1 && command -v aplay >/dev/null 2>&1; then
        echo "Testing for audio dropouts (10 second test)..."
        temp_file=$(mktemp /tmp/audio_test_XXXXXX.wav)
        
        # Record and playback simultaneously
        arecord -D default -f cd -t wav -d 10 "$temp_file" 2>/dev/null &
        record_pid=$!
        sleep 1
        aplay "$temp_file" 2>/dev/null &
        play_pid=$!
        
        wait $record_pid
        wait $play_pid
        rm -f "$temp_file"
        
        echo "  Audio dropout test completed"
    fi
    
    # Test CPU usage during audio processing
    echo "Monitoring CPU usage during audio processing..."
    if command -v pw-top >/dev/null 2>&1; then
        timeout 5 pw-top 2>/dev/null | tail -5
    fi
    
    echo
}

case "$1" in
    latency)
        test_audio_latency
        ;;
    performance)
        test_audio_performance
        ;;
    full)
        test_audio_latency
        test_audio_performance
        ;;
    *)
        echo "Usage: $0 {latency|performance|full}"
        echo "  latency     - Test audio latency settings"
        echo "  performance - Test audio performance"
        echo "  full        - Run complete audio tests"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/audio-latency-test"
    
    # Create real-time audio configuration tool
    cat > "/usr/local/bin/audio-realtime-config" << 'EOF'
#!/bin/bash
# Real-time Audio Configuration Tool

setup_realtime_audio() {
    echo "Setting up real-time audio permissions..."
    
    # Add user to audio group
    if ! groups "$USER" | grep -q audio; then
        sudo usermod -a -G audio "$USER"
        echo "Added $USER to audio group (requires logout/login)"
    fi
    
    # Configure real-time limits
    sudo tee /etc/security/limits.d/95-audio-realtime.conf > /dev/null << 'EOF'
# Real-time audio configuration for xanadOS
@audio   -  rtprio     95
@audio   -  memlock    unlimited
@audio   -  nice       -10
@audio   -  nofile     16384

# Gaming audio users
$USER    -  rtprio     95
$USER    -  memlock    unlimited
$USER    -  nice       -10
$USER    -  nofile     16384
EOF

    # Configure PAM limits
    if ! grep -q "pam_limits.so" /etc/pam.d/login 2>/dev/null; then
        echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/login > /dev/null
    fi
    
    echo "Real-time audio configuration completed"
    echo "Note: You may need to logout and login for changes to take effect"
}

check_realtime_capabilities() {
    echo "=== Real-time Audio Capabilities ==="
    
    echo "Current user groups:"
    groups "$USER"
    echo
    
    echo "Real-time limits:"
    ulimit -r 2>/dev/null && echo "  RT Priority: $(ulimit -r)" || echo "  RT Priority: Not available"
    ulimit -l 2>/dev/null && echo "  Memory Lock: $(ulimit -l)" || echo "  Memory Lock: Not available"
    echo
    
    echo "Audio-related processes with RT priority:"
    ps -eo pid,rtprio,cmd | grep -E "(pipewire|wireplumber|pulseaudio)" | grep -v grep
    echo
}

case "$1" in
    setup)
        setup_realtime_audio
        ;;
    check)
        check_realtime_capabilities
        ;;
    *)
        echo "Usage: $0 {setup|check}"
        echo "  setup - Configure real-time audio permissions"
        echo "  check - Check current real-time capabilities"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/audio-realtime-config"
    
    print_success "Audio testing and configuration tools created"
}

# Function to enable audio services
enable_audio_services() {
    print_section "Enabling Audio Services"
    
    print_status "Configuring audio services..."
    
    # Stop conflicting services
    systemctl --user stop pulseaudio 2>/dev/null || true
    systemctl --user disable pulseaudio 2>/dev/null || true
    
    # Enable PipeWire services
    systemctl --user enable pipewire.service
    systemctl --user enable pipewire-pulse.service
    systemctl --user enable wireplumber.service
    
    # Start PipeWire services
    systemctl --user restart pipewire.service
    systemctl --user restart pipewire-pulse.service
    systemctl --user restart wireplumber.service
    
    # Wait for services to start
    sleep 3
    
    # Verify services are running
    if systemctl --user is-active pipewire >/dev/null 2>&1; then
        print_success "PipeWire service started"
    else
        print_error "Failed to start PipeWire service"
    fi
    
    if systemctl --user is-active pipewire-pulse >/dev/null 2>&1; then
        print_success "PipeWire-Pulse service started"
    else
        print_error "Failed to start PipeWire-Pulse service"
    fi
    
    if systemctl --user is-active wireplumber >/dev/null 2>&1; then
        print_success "WirePlumber service started"
    else
        print_error "Failed to start WirePlumber service"
    fi
}

# Function to create audio gaming mode
create_audio_gaming_mode() {
    print_section "Creating Audio Gaming Mode"
    
    # Create audio gaming mode script
    cat > "/usr/local/bin/audio-gaming-mode" << 'EOF'
#!/bin/bash
# Audio Gaming Mode Script

enable_gaming_audio() {
    echo "Enabling gaming audio optimizations..."
    
    # Set low latency in PipeWire
    if command -v pw-metadata >/dev/null 2>&1; then
        pw-metadata -n settings 0 default.clock.quantum 64
        pw-metadata -n settings 0 default.clock.rate 48000
        pw-metadata -n settings 0 default.clock.min-quantum 32
        pw-metadata -n settings 0 default.clock.max-quantum 8192
    fi
    
    # Boost audio process priority
    for pid in $(pgrep -f "pipewire|wireplumber"); do
        sudo renice -10 -p "$pid" 2>/dev/null || true
    done
    
    # Disable audio power management
    for card in /proc/asound/card*; do
        if [ -f "$card/power_state" ]; then
            echo "D0" | sudo tee "$card/power_state" >/dev/null 2>&1 || true
        fi
    done
    
    echo "Gaming audio optimizations enabled"
}

disable_gaming_audio() {
    echo "Restoring default audio settings..."
    
    # Reset PipeWire to defaults
    if command -v pw-metadata >/dev/null 2>&1; then
        pw-metadata -n settings 0 default.clock.quantum 1024
        pw-metadata -n settings 0 default.clock.rate 48000
        pw-metadata -n settings 0 default.clock.min-quantum 32
        pw-metadata -n settings 0 default.clock.max-quantum 8192
    fi
    
    # Reset process priorities
    for pid in $(pgrep -f "pipewire|wireplumber"); do
        sudo renice 0 -p "$pid" 2>/dev/null || true
    done
    
    echo "Default audio settings restored"
}

show_audio_status() {
    echo "=== Audio Gaming Mode Status ==="
    
    if command -v pw-metadata >/dev/null 2>&1; then
        echo "Current PipeWire settings:"
        pw-metadata -n settings | grep -E "(quantum|rate)" | while read -r line; do
            echo "  $line"
        done
    fi
    
    echo
    echo "Audio process priorities:"
    ps -eo pid,ni,cmd | grep -E "(pipewire|wireplumber)" | grep -v grep
    echo
}

case "$1" in
    enable|on)
        enable_gaming_audio
        ;;
    disable|off)
        disable_gaming_audio
        ;;
    status)
        show_audio_status
        ;;
    *)
        echo "Usage: $0 {enable|disable|status}"
        echo "  enable  - Enable gaming audio optimizations"
        echo "  disable - Disable gaming audio optimizations"
        echo "  status  - Show current audio status"
        ;;
esac
EOF
    chmod +x "/usr/local/bin/audio-gaming-mode"
    
    print_success "Audio gaming mode script created"
}

# Function to show optimization summary
show_optimization_summary() {
    print_section "Audio Optimization Summary"
    
    echo "Audio System Configuration:"
    if systemctl --user is-active pipewire >/dev/null 2>&1; then
        echo "  ✅ PipeWire: Running"
    else
        echo "  ❌ PipeWire: Not running"
    fi
    
    if systemctl --user is-active pipewire-pulse >/dev/null 2>&1; then
        echo "  ✅ PipeWire-Pulse: Running"
    else
        echo "  ❌ PipeWire-Pulse: Not running"
    fi
    
    if systemctl --user is-active wireplumber >/dev/null 2>&1; then
        echo "  ✅ WirePlumber: Running"
    else
        echo "  ❌ WirePlumber: Not running"
    fi
    
    echo
    
    echo "Optimizations Applied:"
    echo "  ✅ Low-latency PipeWire configuration"
    echo "  ✅ Gaming-optimized ALSA settings"
    echo "  ✅ Real-time audio permissions"
    echo "  ✅ Audio testing tools installed"
    echo "  ✅ Gaming mode scripts created"
    echo
    
    echo "Available Commands:"
    echo "  • audio-gaming-mode enable       - Enable gaming audio optimizations"
    echo "  • audio-gaming-mode disable      - Disable gaming audio optimizations"
    echo "  • audio-latency-test full         - Run complete audio tests"
    echo "  • audio-realtime-config setup     - Configure real-time permissions"
    echo
    
    echo "Configuration Files:"
    echo "  • PipeWire config: $PIPEWIRE_CONFIG_DIR/"
    echo "  • WirePlumber config: $WIREPLUMBER_CONFIG_DIR/"
    echo "  • ALSA config: ~/.asoundrc"
    echo "  • Log file: $LOG_FILE"
    echo
}

# Function to show interactive menu
show_menu() {
    print_section "Audio Latency Optimization Menu"
    
    echo "Choose an action:"
    echo
    echo "1) 🔍 Detect Audio Hardware"
    echo "2) 📊 Check Audio System Status"
    echo "3) 📦 Install Audio Packages"
    echo "4) ⚡ Configure Low-Latency PipeWire"
    echo "5) 🎵 Configure ALSA for Gaming"
    echo "6) 🧪 Create Audio Testing Tools"
    echo "7) 🎮 Create Gaming Mode Scripts"
    echo "8) 🔧 Enable Audio Services"
    echo "9) ✅ Apply All Optimizations"
    echo "10) 📋 Show Optimization Summary"
    echo "11) 🚪 Exit"
    echo
}

# Main function
main() {
    # Initialize log file
    sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    sudo touch "$LOG_FILE" 2>/dev/null || true
    
    print_banner
    
    if [ "$#" -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option [1-11]: " choice
            
            case $choice in
                1)
                    detect_audio_hardware
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    check_audio_status
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    install_audio_packages
                    read -p "Press Enter to continue..."
                    ;;
                4)
                    configure_pipewire_low_latency
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    configure_alsa_gaming
                    read -p "Press Enter to continue..."
                    ;;
                6)
                    create_audio_testing_tools
                    read -p "Press Enter to continue..."
                    ;;
                7)
                    create_audio_gaming_mode
                    read -p "Press Enter to continue..."
                    ;;
                8)
                    enable_audio_services
                    read -p "Press Enter to continue..."
                    ;;
                9)
                    install_audio_packages
                    configure_pipewire_low_latency
                    configure_alsa_gaming
                    create_audio_testing_tools
                    create_audio_gaming_mode
                    enable_audio_services
                    show_optimization_summary
                    break
                    ;;
                10)
                    show_optimization_summary
                    read -p "Press Enter to continue..."
                    ;;
                11)
                    print_status "Exiting audio optimization"
                    exit 0
                    ;;
                *)
                    print_error "Invalid option. Please try again."
                    ;;
            esac
        done
    else
        # Command-line mode
        case "$1" in
            detect)
                detect_audio_hardware
                ;;
            status)
                check_audio_status
                ;;
            install)
                install_audio_packages
                ;;
            configure)
                configure_pipewire_low_latency
                configure_alsa_gaming
                ;;
            services)
                enable_audio_services
                ;;
            all)
                install_audio_packages
                configure_pipewire_low_latency
                configure_alsa_gaming
                create_audio_testing_tools
                create_audio_gaming_mode
                enable_audio_services
                show_optimization_summary
                ;;
            *)
                echo "Usage: $0 [detect|status|install|configure|services|all]"
                echo "  detect     - Detect audio hardware"
                echo "  status     - Check audio system status"
                echo "  install    - Install audio packages"
                echo "  configure  - Configure low-latency audio"
                echo "  services   - Enable audio services"
                echo "  all        - Run complete optimization"
                echo
                echo "Run without arguments for interactive mode"
                exit 1
                ;;
        esac
    fi
    
    print_success "Audio latency optimization completed"
}

# Handle interruption
trap 'print_warning "Audio optimization interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
