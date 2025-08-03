#!/bin/bash

# 🎮 xanadOS Unified Gaming Setup Launcher
# Single entry point for all gaming setup and configuration
# Phase 4 Integration - Complete User Experience

set -euo pipefail

# Simple logging
log_info() { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
XANADOS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

show_main_menu() {
    clear
    echo "🎮 xanadOS Gaming Distribution Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Select an option:"
    echo ""
    echo "  1️⃣  Complete Gaming Setup (Recommended)"
    echo "  2️⃣  Gaming Hardware Detection & Optimization"
    echo "  3️⃣  Gaming Software Installation"
    echo "  4️⃣  Gaming Profile Creation & Management"
    echo "  5️⃣  Desktop Gaming Customization"
    echo "  6️⃣  Gaming Workflow Optimization"
    echo "  7️⃣  Gaming Desktop Mode"
    echo "  8️⃣  First-Boot Experience Setup"
    echo ""
    echo "  🔧 Advanced Options:"
    echo "  9️⃣  System Integration Test"
    echo "  🔄 Component Validation"
    echo ""
    echo "  ❌ Exit"
    echo ""
    echo -n "Enter your choice: "
}

run_complete_setup() {
    log_info "🎮 Starting complete gaming setup..."
    
    echo "🚀 xanadOS Complete Gaming Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This will run all gaming setup components:"
    echo "  • Hardware detection and optimization"
    echo "  • Gaming software installation"
    echo "  • Gaming profile creation"
    echo "  • Desktop customization"
    echo "  • First-boot experience setup"
    echo ""
    echo -n "Continue? (y/N): "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Run setup wizard
        "$SCRIPT_DIR/gaming-setup-wizard.sh" || log_error "Gaming setup wizard failed"
        
        # Configure desktop
        if [[ -f "$SCRIPT_DIR/kde-gaming-customization.sh" ]]; then
            "$SCRIPT_DIR/kde-gaming-customization.sh" --auto || log_error "Desktop customization failed"
        fi
        
        # Setup workflows
        "$SCRIPT_DIR/gaming-workflow-optimization.sh" setup || log_error "Workflow optimization failed"
        
        # Initialize gaming mode
        "$SCRIPT_DIR/gaming-desktop-mode.sh" init || log_error "Gaming desktop mode initialization failed"
        
        # Setup first-boot experience
        "$SCRIPT_DIR/first-boot-experience.sh" setup || log_error "First-boot experience setup failed"
        
        echo ""
        echo "✅ Complete gaming setup finished!"
        echo "🎮 Your xanadOS gaming environment is ready!"
    fi
}

main() {
    while true; do
        show_main_menu
        read -r choice
        
        case "$choice" in
            1)
                run_complete_setup
                ;;
            2)
                "$SCRIPT_DIR/gaming-setup-wizard.sh" hardware-detect
                ;;
            3)
                "$SCRIPT_DIR/gaming-setup-wizard.sh" software-install
                ;;
            4)
                "$SCRIPT_DIR/../lib/gaming-profiles.sh" interactive
                ;;
            5)
                if [[ -f "$SCRIPT_DIR/kde-gaming-customization.sh" ]]; then
                    "$SCRIPT_DIR/kde-gaming-customization.sh"
                else
                    log_error "KDE gaming customization not available"
                fi
                ;;
            6)
                "$SCRIPT_DIR/gaming-workflow-optimization.sh"
                ;;
            7)
                "$SCRIPT_DIR/gaming-desktop-mode.sh"
                ;;
            8)
                "$SCRIPT_DIR/first-boot-experience.sh"
                ;;
            9)
                "$SCRIPT_DIR/phase4-integration-polish.sh" test
                ;;
            "validation"|"validate")
                "$SCRIPT_DIR/phase4-integration-polish.sh" validate
                ;;
            "exit"|"quit"|"q"|"")
                echo "👋 Thanks for using xanadOS!"
                exit 0
                ;;
            *)
                echo "❌ Invalid choice. Please try again."
                sleep 2
                ;;
        esac
        
        echo ""
        echo "Press Enter to continue..."
        read -r
    done
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
