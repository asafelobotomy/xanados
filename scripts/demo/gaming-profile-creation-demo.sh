#!/bin/bash

# Gaming Profile Creation Demo
# Demonstrates the new Phase 4.1.3 Gaming Profile Creation system

# Source required libraries
# Source shared libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh" || {
    echo "Error: Could not source common.sh" >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/hardware-detection.sh"
source "$SCRIPT_DIR/../lib/gaming-profiles.sh"

demo_profile_creation() {
    print_header "${GAMING} Gaming Profile Creation Demo ${GAMING}"

    echo -e "${BOLD}Welcome to the Gaming Profile Creation Demo!${NC}"
    echo -e "This demonstrates the new Phase 4.1.3 functionality for creating personalized gaming profiles.\n"

    # Show current system context
    print_section "System Detection"
    detect_hardware

    local gpu_vendor="${DETECTED_GPU_VENDOR:-unknown}"
    local memory_gb="${DETECTED_MEMORY_GB:-0}"
    local cpu_cores="${DETECTED_CPU_CORES:-unknown}"

    echo -e "🖥️  Detected Hardware:"
    echo -e "   GPU: ${BOLD}$gpu_vendor${NC}"
    echo -e "   RAM: ${BOLD}${memory_gb}GB${NC}"
    echo -e "   CPU Cores: ${BOLD}$cpu_cores${NC}"
    echo

    # Show existing profiles if any
    print_section "Existing Gaming Profiles"
    if ! list_gaming_profiles 2>/dev/null | grep -q "No gaming profiles found"; then
        list_gaming_profiles
    else
        echo -e "${YELLOW}No existing gaming profiles found.${NC}"
    fi
    echo

    # Demo profile creation options
    print_section "Profile Creation Options"
    echo -e "Choose a demo action:"
    echo -e "  ${BOLD}1.${NC} ${GREEN}Interactive Profile Creation${NC} - Create a profile step-by-step"
    echo -e "  ${BOLD}2.${NC} ${BLUE}Quick Competitive Profile${NC} - Create a pre-configured competitive gaming profile"
    echo -e "  ${BOLD}3.${NC} ${PURPLE}Show Profile Schema${NC} - Display the gaming profile JSON structure"
    echo -e "  ${BOLD}4.${NC} ${CYAN}Hardware-Aware Recommendations${NC} - Show personalized recommendations"
    echo -e "  ${BOLD}0.${NC} Exit demo"
    echo

    while true; do
        read -p "Please enter your choice [1-4, 0 to exit]: " -n 1 -r
        echo

        case "$REPLY" in
            1)
                echo -e "\n${GREEN}Starting interactive profile creation...${NC}"
                create_gaming_profile
                break
                ;;
            2)
                echo -e "\n${BLUE}Creating quick competitive profile...${NC}"
                create_demo_competitive_profile
                break
                ;;
            3)
                echo -e "\n${PURPLE}Gaming Profile Schema:${NC}"
                show_profile_schema
                echo -e "\nPress any key to continue..."
                read -n 1 -s -r
                ;;
            4)
                echo -e "\n${CYAN}Hardware-Aware Recommendations:${NC}"
                show_hardware_recommendations
                echo -e "\nPress any key to continue..."
                read -n 1 -s -r
                ;;
            0)
                echo -e "\n${YELLOW}Demo completed. Thank you!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
    done
}

create_demo_competitive_profile() {
    local profile_name="demo-competitive-$(date +%s)"

    # Create a sample competitive profile
    cat > "/tmp/${profile_name}.json" << EOF
{
    "name": "$profile_name",
    "gaming_type": "competitive",
    "performance_priority": "maximum_fps",
    "hardware_context": {
        "gpu_vendor": "$DETECTED_GPU_VENDOR",
        "memory_gb": $DETECTED_MEMORY_GB,
        "cpu_cores": $DETECTED_CPU_CORES
    },
    "gaming_preferences": {
        "target_fps": 144,
        "resolution": "1920x1080",
        "graphics_quality": "low",
        "vsync": false,
        "fullscreen": true
    },
    "software_configuration": {
        "steam_launch_options": "-novid -high -threads $DETECTED_CPU_CORES +fps_max 0",
        "discord_optimizations": true,
        "background_apps": "minimal"
    },
    "system_optimizations": {
        "cpu_governor": "performance",
        "gpu_performance": "maximum",
        "memory_tweaks": true,
        "network_optimizations": true
    },
    "created_date": "$(date -Iseconds)",
    "description": "Demo competitive gaming profile optimized for maximum FPS"
}
EOF

    # Import the profile
    import_gaming_profile "/tmp/${profile_name}.json"
    rm -f "/tmp/${profile_name}.json"

    echo -e "\n${GREEN}✅ Demo competitive profile '${profile_name}' created successfully!${NC}"
    echo -e "\nProfile features:"
    echo -e "  • Optimized for competitive gaming with maximum FPS"
    echo -e "  • Target: 144 FPS at 1920x1080"
    echo -e "  • Low graphics quality for performance"
    echo -e "  • CPU performance governor"
    echo -e "  • Network optimizations enabled"
    echo -e "  • Minimal background applications"
}

show_profile_schema() {
    echo -e "\n${BOLD}Gaming Profile JSON Schema:${NC}"
    cat << 'EOF'
{
    "name": "profile_name",
    "gaming_type": "competitive|casual|cinematic|retro|vr|streaming|development",
    "performance_priority": "maximum_fps|balanced|visual_quality|power_efficiency|stability",
    "hardware_context": {
        "gpu_vendor": "nvidia|amd|intel",
        "memory_gb": 16,
        "cpu_cores": 8
    },
    "gaming_preferences": {
        "target_fps": 60,
        "resolution": "1920x1080",
        "graphics_quality": "high",
        "vsync": true,
        "fullscreen": true
    },
    "software_configuration": {
        "steam_launch_options": "",
        "discord_optimizations": true,
        "background_apps": "standard"
    },
    "system_optimizations": {
        "cpu_governor": "performance|powersave|schedutil",
        "gpu_performance": "maximum|balanced|power_save",
        "memory_tweaks": true,
        "network_optimizations": true
    },
    "created_date": "2025-01-16T10:30:00Z",
    "description": "Profile description"
}
EOF
}

show_hardware_recommendations() {
    echo -e "\n${BOLD}Hardware-Aware Recommendations for Your System:${NC}"
    echo

    # GPU-specific recommendations
    case "${DETECTED_GPU_VENDOR}" in
        "nvidia")
            echo -e "🎮 ${GREEN}NVIDIA GPU Detected${NC}"
            echo -e "   • Use maximum performance mode for competitive gaming"
            echo -e "   • Enable NVIDIA Reflex for reduced input lag"
            echo -e "   • Consider DLSS for demanding games"
            ;;
        "amd")
            echo -e "🎮 ${RED}AMD GPU Detected${NC}"
            echo -e "   • Use Radeon Anti-Lag for reduced input latency"
            echo -e "   • Enable FreeSync if supported by monitor"
            echo -e "   • Consider FSR for performance boost"
            ;;
        *)
            echo -e "🎮 ${YELLOW}Generic GPU Configuration${NC}"
            echo -e "   • Focus on CPU-based optimizations"
            echo -e "   • Lower graphics settings for better performance"
            ;;
    esac

    echo

    # Memory-based recommendations
    if [[ ${DETECTED_MEMORY_GB} -lt 8 ]]; then
        echo -e "💾 ${RED}Low Memory Detected (${DETECTED_MEMORY_GB}GB)${NC}"
        echo -e "   • Enable aggressive memory management"
        echo -e "   • Close unnecessary background applications"
        echo -e "   • Use lower texture quality settings"
    elif [[ ${DETECTED_MEMORY_GB} -lt 16 ]]; then
        echo -e "💾 ${YELLOW}Moderate Memory (${DETECTED_MEMORY_GB}GB)${NC}"
        echo -e "   • Standard memory optimizations"
        echo -e "   • Monitor memory usage during gaming"
    else
        echo -e "💾 ${GREEN}High Memory (${DETECTED_MEMORY_GB}GB)${NC}"
        echo -e "   • Can handle high texture quality"
        echo -e "   • Multiple applications can run simultaneously"
    fi

    echo

    # CPU-based recommendations
    if [[ ${DETECTED_CPU_CORES} -lt 4 ]]; then
        echo -e "🔧 ${RED}Low Core Count (${DETECTED_CPU_CORES} cores)${NC}"
        echo -e "   • Use performance CPU governor"
        echo -e "   • Limit background processes"
        echo -e "   • Focus on single-threaded optimizations"
    else
        echo -e "🔧 ${GREEN}Multi-Core CPU (${DETECTED_CPU_CORES} cores)${NC}"
        echo -e "   • Can handle multitasking while gaming"
        echo -e "   • Enable multi-threaded game optimizations"
    fi
}

# Run the demo
demo_profile_creation
