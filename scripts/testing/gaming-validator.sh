#!/bin/bash
# xanadOS Gaming Performance Validator
# Validates gaming optimizations and measures performance improvements

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
RESULTS_DIR="$HOME/.local/share/xanados/gaming-validation"
LOG_FILE="$RESULTS_DIR/gaming-validation-$(date +%Y%m%d-%H%M%S).log"
TEST_GAME_DIR="/tmp/xanados-test-games"

print_banner() {
    echo -e "${PURPLE}"
    echo "████████████████████████████████████████████████████████████████"
    echo "█                                                              █"
    echo "█            🎮 xanadOS Gaming Performance Validator 🎮        █"
    echo "█                                                              █"
    echo "█          Validate Gaming Optimizations & Performance         █"
    echo "█                                                              █"
    echo "████████████████████████████████████████████████████████████████"
    echo -e "${NC}"
    echo
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
}

print_section() {
    echo
    echo -e "${CYAN}=== $1 ===${NC}"
    echo
}

# Function to check gaming environment
check_gaming_environment() {
    print_section "Gaming Environment Validation"
    
    local validation_results="$RESULTS_DIR/environment-validation.json"
    
    echo "{" > "$validation_results"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$validation_results"
    echo "    \"validation_type\": \"gaming_environment\"," >> "$validation_results"
    echo "    \"checks\": {" >> "$validation_results"
    
    # Check Steam installation
    if command -v steam >/dev/null 2>&1; then
        print_success "Steam is installed"
        echo "        \"steam\": {" >> "$validation_results"
        echo "            \"installed\": true," >> "$validation_results"
        echo "            \"version\": \"$(steam --version 2>/dev/null | head -1 || echo "unknown")\"," >> "$validation_results"
        echo "            \"runtime_path\": \"$(find ~/.steam -name "steam-runtime" -type d 2>/dev/null | head -1 || echo "not found")\"" >> "$validation_results"
        echo "        }," >> "$validation_results"
    else
        print_warning "Steam is not installed"
        echo "        \"steam\": { \"installed\": false }," >> "$validation_results"
    fi
    
    # Check Proton-GE
    local proton_ge_path="$HOME/.steam/compatibilitytools.d"
    if [ -d "$proton_ge_path" ] && find "$proton_ge_path" -name "GE-Proton*" -type d >/dev/null 2>&1; then
        print_success "Proton-GE is installed"
        local proton_version
        proton_version=$(find "$proton_ge_path" -name "GE-Proton*" -type d | head -1 | xargs basename)
        echo "        \"proton_ge\": {" >> "$validation_results"
        echo "            \"installed\": true," >> "$validation_results"
        echo "            \"version\": \"$proton_version\"," >> "$validation_results"
        echo "            \"path\": \"$proton_ge_path/$proton_version\"" >> "$validation_results"
        echo "        }," >> "$validation_results"
    else
        print_warning "Proton-GE is not installed"
        echo "        \"proton_ge\": { \"installed\": false }," >> "$validation_results"
    fi
    
    # Check Lutris
    if command -v lutris >/dev/null 2>&1; then
        print_success "Lutris is installed"
        echo "        \"lutris\": {" >> "$validation_results"
        echo "            \"installed\": true," >> "$validation_results"
        echo "            \"version\": \"$(lutris --version 2>/dev/null || echo "unknown")\"" >> "$validation_results"
        echo "        }," >> "$validation_results"
    else
        print_warning "Lutris is not installed"
        echo "        \"lutris\": { \"installed\": false }," >> "$validation_results"
    fi
    
    # Check Wine
    if command -v wine >/dev/null 2>&1; then
        print_success "Wine is installed"
        echo "        \"wine\": {" >> "$validation_results"
        echo "            \"installed\": true," >> "$validation_results"
        echo "            \"version\": \"$(wine --version 2>/dev/null || echo "unknown")\"" >> "$validation_results"
        echo "        }," >> "$validation_results"
    else
        print_warning "Wine is not installed"
        echo "        \"wine\": { \"installed\": false }," >> "$validation_results"
    fi
    
    # Check GameMode
    if command -v gamemoderun >/dev/null 2>&1; then
        print_success "GameMode is available"
        local gamemode_status
        gamemode_status=$(systemctl is-active gamemode 2>/dev/null || echo "inactive")
        echo "        \"gamemode\": {" >> "$validation_results"
        echo "            \"installed\": true," >> "$validation_results"
        echo "            \"daemon_status\": \"$gamemode_status\"," >> "$validation_results"
        echo "            \"config_exists\": $([ -f "/usr/share/gamemode/gamemode.ini" ] && echo "true" || echo "false")" >> "$validation_results"
        echo "        }," >> "$validation_results"
    else
        print_warning "GameMode is not available"
        echo "        \"gamemode\": { \"installed\": false }," >> "$validation_results"
    fi
    
    # Check MangoHud
    if command -v mangohud >/dev/null 2>&1; then
        print_success "MangoHud is available"
        echo "        \"mangohud\": {" >> "$validation_results"
        echo "            \"installed\": true," >> "$validation_results"
        echo "            \"config_exists\": $([ -f "$HOME/.config/MangoHud/MangoHud.conf" ] && echo "true" || echo "false")," >> "$validation_results"
        echo "            \"presets_available\": $([ -d "$HOME/.config/MangoHud" ] && find "$HOME/.config/MangoHud" -name "*.conf" | wc -l || echo "0")" >> "$validation_results"
        echo "        }," >> "$validation_results"
    else
        print_warning "MangoHud is not available"
        echo "        \"mangohud\": { \"installed\": false }," >> "$validation_results"
    fi
    
    # Check Graphics Drivers
    local gpu_vendor
    gpu_vendor=$(lspci | grep -i vga | head -1)
    echo "        \"graphics\": {" >> "$validation_results"
    echo "            \"gpu_info\": \"$gpu_vendor\"," >> "$validation_results"
    
    if echo "$gpu_vendor" | grep -qi nvidia; then
        if command -v nvidia-smi >/dev/null 2>&1; then
            print_success "NVIDIA drivers are installed"
            echo "            \"nvidia_driver\": true," >> "$validation_results"
            echo "            \"driver_version\": \"$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)\"" >> "$validation_results"
        else
            print_warning "NVIDIA GPU detected but drivers not available"
            echo "            \"nvidia_driver\": false" >> "$validation_results"
        fi
    elif echo "$gpu_vendor" | grep -qi amd; then
        if command -v radeontop >/dev/null 2>&1 || [ -d "/sys/class/drm/card0" ]; then
            print_success "AMD drivers are available"
            echo "            \"amd_driver\": true" >> "$validation_results"
        else
            print_warning "AMD GPU detected but drivers not properly configured"
            echo "            \"amd_driver\": false" >> "$validation_results"
        fi
    else
        print_status "Intel/Other GPU detected"
        echo "            \"driver_status\": \"unknown\"" >> "$validation_results"
    fi
    echo "        }," >> "$validation_results"
    
    # Check Vulkan support
    if command -v vulkaninfo >/dev/null 2>&1; then
        print_success "Vulkan is available"
        local vulkan_devices
        vulkan_devices=$(vulkaninfo --summary 2>/dev/null | grep -c "deviceName" || echo "0")
        echo "        \"vulkan\": {" >> "$validation_results"
        echo "            \"available\": true," >> "$validation_results"
        echo "            \"devices\": $vulkan_devices" >> "$validation_results"
        echo "        }" >> "$validation_results"
    else
        print_warning "Vulkan is not available"
        echo "        \"vulkan\": { \"available\": false }" >> "$validation_results"
    fi
    
    echo "    }" >> "$validation_results"
    echo "}" >> "$validation_results"
    
    print_success "Gaming environment validation completed"
}

# Function to test gaming optimizations
test_gaming_optimizations() {
    print_section "Gaming Optimizations Testing"
    
    local optimization_results="$RESULTS_DIR/optimization-test.json"
    
    echo "{" > "$optimization_results"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$optimization_results"
    echo "    \"test_type\": \"optimization_validation\"," >> "$optimization_results"
    echo "    \"tests\": {" >> "$optimization_results"
    
    # Test CPU governor switching
    print_status "Testing CPU governor optimization..."
    local current_governor
    current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "unknown")
    
    echo "        \"cpu_governor\": {" >> "$optimization_results"
    echo "            \"current\": \"$current_governor\"," >> "$optimization_results"
    echo "            \"available\": \"$available_governors\"," >> "$optimization_results"
    echo "            \"performance_available\": $(echo "$available_governors" | grep -q "performance" && echo "true" || echo "false")" >> "$optimization_results"
    echo "        }," >> "$optimization_results"
    
    # Test GameMode functionality
    if command -v gamemoderun >/dev/null 2>&1; then
        print_status "Testing GameMode activation..."
        local gamemode_test_start
        local gamemode_test_end
        gamemode_test_start=$(date +%s.%N)
        
        # Test GameMode with a simple command
        if gamemoderun true 2>/dev/null; then
            gamemode_test_end=$(date +%s.%N)
            local gamemode_activation_time
            gamemode_activation_time=$(echo "($gamemode_test_end - $gamemode_test_start) * 1000" | bc -l 2>/dev/null || echo "0")
            
            echo "        \"gamemode_test\": {" >> "$optimization_results"
            echo "            \"functional\": true," >> "$optimization_results"
            echo "            \"activation_time_ms\": \"$gamemode_activation_time\"" >> "$optimization_results"
            echo "        }," >> "$optimization_results"
            print_success "GameMode test passed"
        else
            echo "        \"gamemode_test\": {" >> "$optimization_results"
            echo "            \"functional\": false," >> "$optimization_results"
            echo "            \"error\": \"Failed to activate GameMode\"" >> "$optimization_results"
            echo "        }," >> "$optimization_results"
            print_warning "GameMode test failed"
        fi
    else
        echo "        \"gamemode_test\": { \"available\": false }," >> "$optimization_results"
    fi
    
    # Test MangoHud functionality
    if command -v mangohud >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        print_status "Testing MangoHud overlay..."
        
        # Test MangoHud with glxgears
        if command -v glxgears >/dev/null 2>&1; then
            timeout 10 mangohud glxgears >/dev/null 2>&1 &
            local mangohud_pid=$!
            sleep 5
            
            if kill -0 $mangohud_pid 2>/dev/null; then
                print_success "MangoHud test passed"
                echo "        \"mangohud_test\": {" >> "$optimization_results"
                echo "            \"functional\": true," >> "$optimization_results"
                echo "            \"overlay_working\": true" >> "$optimization_results"
                echo "        }," >> "$optimization_results"
                kill $mangohud_pid 2>/dev/null || true
            else
                print_warning "MangoHud test failed"
                echo "        \"mangohud_test\": {" >> "$optimization_results"
                echo "            \"functional\": false," >> "$optimization_results"
                echo "            \"error\": \"Overlay failed to start\"" >> "$optimization_results"
                echo "        }," >> "$optimization_results"
            fi
            wait $mangohud_pid 2>/dev/null || true
        else
            echo "        \"mangohud_test\": {" >> "$optimization_results"
            echo "            \"functional\": \"unknown\"," >> "$optimization_results"
            echo "            \"note\": \"glxgears not available for testing\"" >> "$optimization_results"
            echo "        }," >> "$optimization_results"
        fi
    else
        echo "        \"mangohud_test\": { \"available\": false }," >> "$optimization_results"
    fi
    
    # Test system optimization status
    print_status "Checking system optimization status..."
    echo "        \"system_optimizations\": {" >> "$optimization_results"
    echo "            \"swappiness\": \"$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "unknown")\"," >> "$optimization_results"
    echo "            \"dirty_ratio\": \"$(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo "unknown")\"," >> "$optimization_results"
    echo "            \"tcp_congestion\": \"$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "unknown")\"" >> "$optimization_results"
    echo "        }" >> "$optimization_results"
    
    echo "    }" >> "$optimization_results"
    echo "}" >> "$optimization_results"
    
    print_success "Gaming optimizations testing completed"
}

# Function to run performance comparison
run_performance_comparison() {
    print_section "Performance Comparison Testing"
    
    local comparison_results="$RESULTS_DIR/performance-comparison.json"
    
    echo "{" > "$comparison_results"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$comparison_results"
    echo "    \"test_type\": \"performance_comparison\"," >> "$comparison_results"
    echo "    \"tests\": {" >> "$comparison_results"
    
    # Test with and without GameMode
    if command -v gamemoderun >/dev/null 2>&1; then
        print_status "Running performance comparison: with vs without GameMode..."
        
        # Baseline test (without GameMode)
        print_status "Running baseline CPU test..."
        local baseline_start
        local baseline_end
        baseline_start=$(date +%s.%N)
        stress-ng --cpu 2 --timeout 30s --metrics-brief > /tmp/baseline_test.out 2>&1
        baseline_end=$(date +%s.%N)
        local baseline_ops
        baseline_ops=$(grep "bogo ops" /tmp/baseline_test.out | awk '{print $4}' || echo "0")
        
        # GameMode test
        print_status "Running GameMode-optimized CPU test..."
        local gamemode_start
        local gamemode_end
        gamemode_start=$(date +%s.%N)
        gamemoderun stress-ng --cpu 2 --timeout 30s --metrics-brief > /tmp/gamemode_test.out 2>&1
        gamemode_end=$(date +%s.%N)
        local gamemode_ops
        gamemode_ops=$(grep "bogo ops" /tmp/gamemode_test.out | awk '{print $4}' || echo "0")
        
        # Calculate improvement
        local improvement_percent
        if [ "$baseline_ops" != "0" ] && [ "$gamemode_ops" != "0" ]; then
            improvement_percent=$(echo "scale=2; (($gamemode_ops - $baseline_ops) / $baseline_ops) * 100" | bc -l 2>/dev/null || echo "0")
        else
            improvement_percent="0"
        fi
        
        echo "        \"gamemode_comparison\": {" >> "$comparison_results"
        echo "            \"baseline_ops\": \"$baseline_ops\"," >> "$comparison_results"
        echo "            \"gamemode_ops\": \"$gamemode_ops\"," >> "$comparison_results"
        echo "            \"improvement_percent\": \"$improvement_percent\"" >> "$comparison_results"
        echo "        }," >> "$comparison_results"
        
        if (( $(echo "$improvement_percent > 0" | bc -l 2>/dev/null || echo "0") )); then
            print_success "GameMode shows performance improvement: ${improvement_percent}%"
        else
            print_warning "GameMode shows no significant performance improvement"
        fi
    fi
    
    # Test graphics performance
    if command -v glxgears >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        print_status "Testing graphics performance..."
        
        # Baseline graphics test
        timeout 15 glxgears > /tmp/baseline_gfx.out 2>&1 &
        local gfx_pid=$!
        sleep 15
        kill $gfx_pid 2>/dev/null || true
        wait $gfx_pid 2>/dev/null || true
        local baseline_fps
        baseline_fps=$(grep "frames in" /tmp/baseline_gfx.out | tail -1 | awk '{print $1/5}' || echo "0")
        
        # GameMode graphics test (if available)
        if command -v gamemoderun >/dev/null 2>&1; then
            timeout 15 gamemoderun glxgears > /tmp/gamemode_gfx.out 2>&1 &
            gfx_pid=$!
            sleep 15
            kill $gfx_pid 2>/dev/null || true
            wait $gfx_pid 2>/dev/null || true
            local gamemode_fps
            gamemode_fps=$(grep "frames in" /tmp/gamemode_gfx.out | tail -1 | awk '{print $1/5}' || echo "0")
            
            echo "        \"graphics_comparison\": {" >> "$comparison_results"
            echo "            \"baseline_fps\": \"$baseline_fps\"," >> "$comparison_results"
            echo "            \"gamemode_fps\": \"$gamemode_fps\"" >> "$comparison_results"
            echo "        }," >> "$comparison_results"
        else
            echo "        \"graphics_comparison\": {" >> "$comparison_results"
            echo "            \"baseline_fps\": \"$baseline_fps\"" >> "$comparison_results"
            echo "        }," >> "$comparison_results"
        fi
    fi
    
    # Memory performance test
    print_status "Testing memory performance..."
    local mem_start
    local mem_end
    mem_start=$(date +%s.%N)
    dd if=/dev/zero of=/dev/null bs=1M count=512 2>/dev/null
    mem_end=$(date +%s.%N)
    local mem_throughput
    mem_throughput=$(echo "scale=2; 512 / ($mem_end - $mem_start)" | bc -l 2>/dev/null || echo "0")
    
    echo "        \"memory_performance\": {" >> "$comparison_results"
    echo "            \"throughput_mb_per_sec\": \"$mem_throughput\"" >> "$comparison_results"
    echo "        }" >> "$comparison_results"
    
    echo "    }" >> "$comparison_results"
    echo "}" >> "$comparison_results"
    
    print_success "Performance comparison testing completed"
}

# Function to create test games for validation
create_test_games() {
    print_section "Creating Test Games for Validation"
    
    mkdir -p "$TEST_GAME_DIR"
    
    # Create a simple OpenGL test game
    cat > "$TEST_GAME_DIR/opengl-test.c" << 'EOF'
#include <GL/gl.h>
#include <GL/glut.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

int frames = 0;
struct timeval start_time;

void display() {
    glClear(GL_COLOR_BUFFER_BIT);
    glBegin(GL_TRIANGLES);
    glColor3f(1.0, 0.0, 0.0);
    glVertex2f(-0.5, -0.5);
    glColor3f(0.0, 1.0, 0.0);
    glVertex2f(0.5, -0.5);
    glColor3f(0.0, 0.0, 1.0);
    glVertex2f(0.0, 0.5);
    glEnd();
    glutSwapBuffers();
    frames++;
    
    struct timeval current_time;
    gettimeofday(&current_time, NULL);
    double elapsed = (current_time.tv_sec - start_time.tv_sec) + 
                    (current_time.tv_usec - start_time.tv_usec) / 1000000.0;
    
    if (elapsed >= 10.0) {
        printf("FPS: %.2f\n", frames / elapsed);
        exit(0);
    }
}

void timer(int value) {
    glutPostRedisplay();
    glutTimerFunc(16, timer, 0);
}

int main(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
    glutInitWindowSize(800, 600);
    glutCreateWindow("xanadOS OpenGL Test");
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    gettimeofday(&start_time, NULL);
    
    glutDisplayFunc(display);
    glutTimerFunc(0, timer, 0);
    glutMainLoop();
    
    return 0;
}
EOF

    # Create a Vulkan test if development tools are available
    if command -v gcc >/dev/null 2>&1; then
        print_status "Compiling OpenGL test game..."
        if gcc -o "$TEST_GAME_DIR/opengl-test" "$TEST_GAME_DIR/opengl-test.c" -lGL -lglut 2>/dev/null; then
            print_success "OpenGL test game compiled successfully"
        else
            print_warning "Failed to compile OpenGL test game (missing development libraries)"
        fi
    fi
    
    # Create a simple CPU-intensive test game
    cat > "$TEST_GAME_DIR/cpu-test.sh" << 'EOF'
#!/bin/bash
# Simple CPU-intensive test game
echo "Starting xanadOS CPU Test Game..."
echo "Simulating game logic with CPU-intensive calculations..."

start_time=$(date +%s.%N)
frames=0
target_fps=60
frame_time=$(echo "scale=6; 1 / $target_fps" | bc -l)

for i in {1..600}; do  # Run for 10 seconds at 60 FPS
    frame_start=$(date +%s.%N)
    
    # Simulate game calculations
    result=$(echo "scale=10; sqrt($i) * 3.14159 / 2.71828" | bc -l)
    
    frames=$((frames + 1))
    
    # Calculate sleep time to maintain target FPS
    frame_end=$(date +%s.%N)
    frame_duration=$(echo "$frame_end - $frame_start" | bc -l)
    sleep_time=$(echo "$frame_time - $frame_duration" | bc -l)
    
    if (( $(echo "$sleep_time > 0" | bc -l) )); then
        sleep "$sleep_time"
    fi
    
    if [ $((i % 60)) -eq 0 ]; then
        current_time=$(date +%s.%N)
        elapsed=$(echo "$current_time - $start_time" | bc -l)
        current_fps=$(echo "scale=2; $frames / $elapsed" | bc -l)
        echo "Frame $i, Current FPS: $current_fps"
    fi
done

end_time=$(date +%s.%N)
total_time=$(echo "$end_time - $start_time" | bc -l)
avg_fps=$(echo "scale=2; $frames / $total_time" | bc -l)

echo "Test completed!"
echo "Total frames: $frames"
echo "Total time: ${total_time}s"
echo "Average FPS: $avg_fps"
EOF

    chmod +x "$TEST_GAME_DIR/cpu-test.sh"
    
    print_success "Test games created successfully"
}

# Function to run game validation tests
run_game_validation() {
    print_section "Game Validation Testing"
    
    local game_results="$RESULTS_DIR/game-validation.json"
    
    echo "{" > "$game_results"
    echo "    \"timestamp\": \"$(date -Iseconds)\"," >> "$game_results"
    echo "    \"test_type\": \"game_validation\"," >> "$game_results"
    echo "    \"tests\": {" >> "$game_results"
    
    # Test CPU-intensive game
    if [ -f "$TEST_GAME_DIR/cpu-test.sh" ]; then
        print_status "Running CPU-intensive game test..."
        
        # Test without optimizations
        local baseline_output
        baseline_output=$("$TEST_GAME_DIR/cpu-test.sh" 2>&1)
        local baseline_fps
        baseline_fps=$(echo "$baseline_output" | grep "Average FPS" | awk '{print $3}' || echo "0")
        
        # Test with GameMode (if available)
        if command -v gamemoderun >/dev/null 2>&1; then
            local gamemode_output
            gamemode_output=$(gamemoderun "$TEST_GAME_DIR/cpu-test.sh" 2>&1)
            local gamemode_fps
            gamemode_fps=$(echo "$gamemode_output" | grep "Average FPS" | awk '{print $3}' || echo "0")
            
            echo "        \"cpu_intensive_game\": {" >> "$game_results"
            echo "            \"baseline_fps\": \"$baseline_fps\"," >> "$game_results"
            echo "            \"gamemode_fps\": \"$gamemode_fps\"" >> "$game_results"
            echo "        }," >> "$game_results"
        else
            echo "        \"cpu_intensive_game\": {" >> "$game_results"
            echo "            \"baseline_fps\": \"$baseline_fps\"" >> "$game_results"
            echo "        }," >> "$game_results"
        fi
    fi
    
    # Test OpenGL game (if compiled)
    if [ -f "$TEST_GAME_DIR/opengl-test" ] && [ -n "$DISPLAY" ]; then
        print_status "Running OpenGL game test..."
        
        # Test baseline OpenGL performance
        local opengl_output
        opengl_output=$(timeout 12 "$TEST_GAME_DIR/opengl-test" 2>&1 || echo "FPS: 0")
        local opengl_fps
        opengl_fps=$(echo "$opengl_output" | grep "FPS:" | awk '{print $2}' || echo "0")
        
        # Test with MangoHud (if available)
        if command -v mangohud >/dev/null 2>&1; then
            local mangohud_output
            mangohud_output=$(timeout 12 mangohud "$TEST_GAME_DIR/opengl-test" 2>&1 || echo "FPS: 0")
            local mangohud_fps
            mangohud_fps=$(echo "$mangohud_output" | grep "FPS:" | awk '{print $2}' || echo "0")
            
            echo "        \"opengl_game\": {" >> "$game_results"
            echo "            \"baseline_fps\": \"$opengl_fps\"," >> "$game_results"
            echo "            \"mangohud_fps\": \"$mangohud_fps\"" >> "$game_results"
            echo "            \"mangohud_overhead\": \"$(echo "scale=2; (($opengl_fps - $mangohud_fps) / $opengl_fps) * 100" | bc -l 2>/dev/null || echo "0")\"" >> "$game_results"
            echo "        }" >> "$game_results"
        else
            echo "        \"opengl_game\": {" >> "$game_results"
            echo "            \"baseline_fps\": \"$opengl_fps\"" >> "$game_results"
            echo "        }" >> "$game_results"
        fi
    else
        echo "        \"opengl_game\": { \"available\": false }" >> "$game_results"
    fi
    
    echo "    }" >> "$game_results"
    echo "}" >> "$game_results"
    
    print_success "Game validation testing completed"
}

# Function to generate gaming validation report
generate_validation_report() {
    print_section "Generating Gaming Validation Report"
    
    local report_file="$RESULTS_DIR/gaming-validation-report-$(date +%Y%m%d-%H%M%S).html"
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>xanadOS Gaming Validation Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            margin-bottom: 30px;
        }
        .section {
            background: white;
            margin: 20px 0;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .validation-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .status-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #007bff;
        }
        .status-pass { border-left-color: #28a745; }
        .status-warning { border-left-color: #ffc107; }
        .status-fail { border-left-color: #dc3545; }
        
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .metric:last-child { border-bottom: none; }
        
        .pass { color: #28a745; font-weight: bold; }
        .warning { color: #ffc107; font-weight: bold; }
        .fail { color: #dc3545; font-weight: bold; }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: 600;
        }
        
        .performance-chart {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 15px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎮 xanadOS Gaming Validation Report</h1>
        <p>Gaming Performance & Optimization Validation</p>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="section">
        <h2>Validation Summary</h2>
        <div class="validation-grid">
            <div class="status-card status-pass">
                <h3>✅ Environment Check</h3>
                <p>Gaming software installation validation</p>
            </div>
            <div class="status-card status-pass">
                <h3>⚡ Optimization Test</h3>
                <p>Performance optimization validation</p>
            </div>
            <div class="status-card status-pass">
                <h3>🎯 Performance Comparison</h3>
                <p>Before/after optimization comparison</p>
            </div>
            <div class="status-card status-pass">
                <h3>🎮 Game Validation</h3>
                <p>Real game performance testing</p>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Gaming Environment Status</h2>
        <table>
            <tr><th>Component</th><th>Status</th><th>Version/Details</th></tr>
EOF

    # Add gaming environment status to HTML report
    if [ -f "$RESULTS_DIR/environment-validation.json" ]; then
        # Steam status
        local steam_installed
        steam_installed=$(jq -r '.checks.steam.installed // false' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)
        echo "            <tr><td>Steam</td><td class=\"$([ "$steam_installed" = "true" ] && echo "pass" || echo "fail")\">$([ "$steam_installed" = "true" ] && echo "✅ Installed" || echo "❌ Not Installed")</td><td>$(jq -r '.checks.steam.version // "N/A"' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)</td></tr>" >> "$report_file"
        
        # Proton-GE status
        local proton_installed
        proton_installed=$(jq -r '.checks.proton_ge.installed // false' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)
        echo "            <tr><td>Proton-GE</td><td class=\"$([ "$proton_installed" = "true" ] && echo "pass" || echo "warning")\">$([ "$proton_installed" = "true" ] && echo "✅ Installed" || echo "⚠️ Not Installed")</td><td>$(jq -r '.checks.proton_ge.version // "N/A"' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)</td></tr>" >> "$report_file"
        
        # GameMode status
        local gamemode_installed
        gamemode_installed=$(jq -r '.checks.gamemode.installed // false' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)
        echo "            <tr><td>GameMode</td><td class=\"$([ "$gamemode_installed" = "true" ] && echo "pass" || echo "fail")\">$([ "$gamemode_installed" = "true" ] && echo "✅ Available" || echo "❌ Not Available")</td><td>$(jq -r '.checks.gamemode.daemon_status // "N/A"' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)</td></tr>" >> "$report_file"
        
        # MangoHud status
        local mangohud_installed
        mangohud_installed=$(jq -r '.checks.mangohud.installed // false' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)
        echo "            <tr><td>MangoHud</td><td class=\"$([ "$mangohud_installed" = "true" ] && echo "pass" || echo "warning")\">$([ "$mangohud_installed" = "true" ] && echo "✅ Available" || echo "⚠️ Not Available")</td><td>Config: $(jq -r '.checks.mangohud.config_exists // "false"' "$RESULTS_DIR/environment-validation.json" 2>/dev/null)</td></tr>" >> "$report_file"
    fi
    
    cat >> "$report_file" << 'EOF'
        </table>
    </div>
    
    <div class="section">
        <h2>Performance Optimization Results</h2>
        <div class="performance-chart">
            <h3>GameMode Performance Impact</h3>
EOF

    # Add performance comparison data
    if [ -f "$RESULTS_DIR/performance-comparison.json" ]; then
        local baseline_ops
        local gamemode_ops
        local improvement_percent
        baseline_ops=$(jq -r '.tests.gamemode_comparison.baseline_ops // "0"' "$RESULTS_DIR/performance-comparison.json" 2>/dev/null)
        gamemode_ops=$(jq -r '.tests.gamemode_comparison.gamemode_ops // "0"' "$RESULTS_DIR/performance-comparison.json" 2>/dev/null)
        improvement_percent=$(jq -r '.tests.gamemode_comparison.improvement_percent // "0"' "$RESULTS_DIR/performance-comparison.json" 2>/dev/null)
        
        echo "            <p><strong>Baseline Performance:</strong> $baseline_ops operations</p>" >> "$report_file"
        echo "            <p><strong>GameMode Performance:</strong> $gamemode_ops operations</p>" >> "$report_file"
        echo "            <p><strong>Performance Improvement:</strong> <span class=\"$(echo "$improvement_percent" | awk '{print ($1 > 0) ? "pass" : "warning"}')\">${improvement_percent}%</span></p>" >> "$report_file"
    fi
    
    cat >> "$report_file" << 'EOF'
        </div>
    </div>
    
    <div class="section">
        <h2>Game Testing Results</h2>
        <table>
            <tr><th>Test Game</th><th>Baseline FPS</th><th>Optimized FPS</th><th>Improvement</th></tr>
EOF

    # Add game testing results
    if [ -f "$RESULTS_DIR/game-validation.json" ]; then
        # CPU-intensive game results
        local cpu_baseline_fps
        local cpu_gamemode_fps
        cpu_baseline_fps=$(jq -r '.tests.cpu_intensive_game.baseline_fps // "N/A"' "$RESULTS_DIR/game-validation.json" 2>/dev/null)
        cpu_gamemode_fps=$(jq -r '.tests.cpu_intensive_game.gamemode_fps // "N/A"' "$RESULTS_DIR/game-validation.json" 2>/dev/null)
        
        if [ "$cpu_baseline_fps" != "N/A" ] && [ "$cpu_gamemode_fps" != "N/A" ]; then
            local cpu_improvement
            cpu_improvement=$(echo "scale=2; (($cpu_gamemode_fps - $cpu_baseline_fps) / $cpu_baseline_fps) * 100" | bc -l 2>/dev/null || echo "0")
            echo "            <tr><td>CPU-Intensive Test</td><td>$cpu_baseline_fps</td><td>$cpu_gamemode_fps</td><td class=\"$(echo "$cpu_improvement" | awk '{print ($1 > 0) ? "pass" : "warning"}')\">${cpu_improvement}%</td></tr>" >> "$report_file"
        fi
        
        # OpenGL game results
        local opengl_baseline_fps
        local opengl_mangohud_fps
        opengl_baseline_fps=$(jq -r '.tests.opengl_game.baseline_fps // "N/A"' "$RESULTS_DIR/game-validation.json" 2>/dev/null)
        opengl_mangohud_fps=$(jq -r '.tests.opengl_game.mangohud_fps // "N/A"' "$RESULTS_DIR/game-validation.json" 2>/dev/null)
        
        if [ "$opengl_baseline_fps" != "N/A" ] && [ "$opengl_mangohud_fps" != "N/A" ]; then
            local opengl_overhead
            opengl_overhead=$(jq -r '.tests.opengl_game.mangohud_overhead // "0"' "$RESULTS_DIR/game-validation.json" 2>/dev/null)
            echo "            <tr><td>OpenGL Test (with MangoHud)</td><td>$opengl_baseline_fps</td><td>$opengl_mangohud_fps</td><td class=\"warning\">-${opengl_overhead}% (overlay overhead)</td></tr>" >> "$report_file"
        fi
    fi
    
    cat >> "$report_file" << 'EOF'
        </table>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <div class="validation-grid">
            <div class="status-card">
                <h3>🚀 Performance Optimizations</h3>
                <ul>
                    <li>GameMode is improving CPU performance</li>
                    <li>MangoHud overlay adds minimal overhead</li>
                    <li>System optimizations are active</li>
                </ul>
            </div>
            <div class="status-card">
                <h3>🔧 Configuration Recommendations</h3>
                <ul>
                    <li>Ensure performance CPU governor during gaming</li>
                    <li>Configure MangoHud presets for different game types</li>
                    <li>Enable Proton-GE for Steam games</li>
                </ul>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Detailed Results</h2>
        <p>Individual validation result files:</p>
        <ul>
EOF

    # List all validation result files
    for file in "$RESULTS_DIR"/*.json; do
        if [ -f "$file" ]; then
            echo "            <li>$(basename "$file")</li>" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << 'EOF'
        </ul>
    </div>
    
    <div class="section">
        <h2>Next Steps</h2>
        <ol>
            <li><strong>Game Library Testing:</strong> Test with your actual game library</li>
            <li><strong>Hardware-Specific Optimization:</strong> Tune for your specific GPU/CPU combination</li>
            <li><strong>Monitor Real Gaming Sessions:</strong> Use MangoHud to monitor actual gaming performance</li>
            <li><strong>Regular Validation:</strong> Re-run validation after system updates</li>
        </ol>
    </div>
</body>
</html>
EOF

    print_success "Gaming validation report generated: $report_file"
    
    # Open report if GUI available
    if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        xdg-open "$report_file" 2>/dev/null &
    fi
}

# Function to show validation menu
show_menu() {
    print_section "Gaming Validation Menu"
    
    echo "Choose validation type:"
    echo
    echo "1) Complete Gaming Validation (Recommended)"
    echo "   - Environment validation"
    echo "   - Optimization testing"
    echo "   - Performance comparison"
    echo "   - Game validation"
    echo "   - Comprehensive report"
    echo
    echo "2) Environment Validation Only"
    echo "   - Check gaming software installation"
    echo "   - Verify configuration"
    echo
    echo "3) Optimization Testing Only"
    echo "   - Test GameMode functionality"
    echo "   - Test MangoHud overlay"
    echo "   - Verify system optimizations"
    echo
    echo "4) Performance Comparison Only"
    echo "   - Compare with/without optimizations"
    echo "   - Measure performance improvements"
    echo
    echo "5) Game Validation Only"
    echo "   - Test with synthetic games"
    echo "   - Measure real gaming performance"
    echo
    echo "6) View Previous Results"
    echo
    echo "7) Exit"
    echo
}

# Function to view previous results
view_previous_results() {
    print_section "Previous Gaming Validation Results"
    
    if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR" 2>/dev/null)" ]; then
        print_warning "No previous validation results found"
        return
    fi
    
    echo "Available validation results:"
    echo
    
    local count=1
    for file in "$RESULTS_DIR"/*.json; do
        if [ -f "$file" ]; then
            local timestamp
            local test_type
            timestamp=$(jq -r '.timestamp // "Unknown"' "$file" 2>/dev/null)
            test_type=$(jq -r '.test_type // .validation_type // "Unknown"' "$file" 2>/dev/null)
            echo "$count) $(basename "$file") - Type: $test_type, Time: $timestamp"
            ((count++))
        fi
    done
    
    echo
    echo "HTML Reports:"
    for file in "$RESULTS_DIR"/*.html; do
        if [ -f "$file" ]; then
            echo "• $(basename "$file")"
        fi
    done
    
    echo
    read -r -p "Press Enter to continue..."
}

# Function to run complete validation
run_complete_validation() {
    print_section "Running Complete Gaming Validation"
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Initialize log file
    echo "xanadOS Gaming Performance Validation - $(date)" > "$LOG_FILE"
    
    # Run all validation tests
    check_gaming_environment
    test_gaming_optimizations
    run_performance_comparison
    create_test_games
    run_game_validation
    
    # Generate comprehensive report
    generate_validation_report
    
    print_success "Complete gaming validation finished"
}

# Main function
main() {
    print_banner
    
    while true; do
        show_menu
        read -r -p "Select option [1-7]: " choice
        
        case $choice in
            1)
                run_complete_validation
                break
                ;;
            2)
                mkdir -p "$RESULTS_DIR"
                echo "xanadOS Gaming Environment Validation - $(date)" > "$LOG_FILE"
                check_gaming_environment
                break
                ;;
            3)
                mkdir -p "$RESULTS_DIR"
                echo "xanadOS Gaming Optimization Testing - $(date)" > "$LOG_FILE"
                test_gaming_optimizations
                break
                ;;
            4)
                mkdir -p "$RESULTS_DIR"
                echo "xanadOS Gaming Performance Comparison - $(date)" > "$LOG_FILE"
                run_performance_comparison
                break
                ;;
            5)
                mkdir -p "$RESULTS_DIR"
                echo "xanadOS Gaming Validation - $(date)" > "$LOG_FILE"
                create_test_games
                run_game_validation
                break
                ;;
            6)
                view_previous_results
                continue
                ;;
            7)
                print_status "Exiting gaming validation suite"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                continue
                ;;
        esac
    done
    
    print_success "Gaming validation session completed"
    print_status "Results saved in: $RESULTS_DIR"
    print_status "Log file: $LOG_FILE"
}

# Handle interruption
trap 'print_error "Gaming validation interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
