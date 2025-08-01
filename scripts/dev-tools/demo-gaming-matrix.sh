#!/bin/bash
# Gaming Tool Availability Matrix Demo
# Demonstrates the new gaming environment matrix functionality

# Change to the correct directory and source our libraries
cd "$(dirname "$0")" || exit 1
source "../lib/common.sh"
source "../lib/validation.sh"
source "../lib/gaming-env.sh"

print_header "🎮 Gaming Tool Availability Matrix Demo"
echo ""

print_status "Initializing command cache..."
cache_gaming_tools
cache_dev_tools
cache_system_tools
echo ""

print_section "Demo 1: Table Format (Basic)"
generate_gaming_matrix "table" "false"

print_section "Demo 2: Table Format (With Versions)"
generate_gaming_matrix "table" "true"

print_section "Demo 3: Detailed Analysis"
generate_gaming_matrix "detailed" "true"

print_section "Demo 4: JSON Format (With Versions)"
generate_gaming_matrix "json" "true"

print_section "Demo 5: Gaming Readiness Score"
readiness_score=$(get_gaming_readiness_score)
print_success "Your Gaming Readiness Score: ${readiness_score}%"

echo ""
print_success "Gaming Matrix Demo completed!"
print_info "Use these functions in other scripts:"
echo "  - generate_gaming_matrix [table|json|detailed] [true|false]"
echo "  - get_gaming_readiness_score"
echo "  - provide_gaming_recommendations"
