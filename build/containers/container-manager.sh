#!/bin/bash
# Container Management Script for xanadOS Build System
# Provides easy commands for Docker-based builds

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly CONTAINER_DIR="$PROJECT_ROOT/build/containers"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Utility functions
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══ $1 ═══${NC}\n"
}

# Check dependencies
check_dependencies() {
    local deps=("docker" "docker-compose")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Please install Docker and Docker Compose"
        exit 1
    fi
}

# Build the container image
build_image() {
    print_header "Building xanadOS Build Container"

    cd "$CONTAINER_DIR"

    # Create required directories
    mkdir -p output dev-output cache logs dev-cache dev-logs

    print_info "Building container image..."
    docker-compose build xanados-build

    print_status "Container image built successfully"
}

# Start the build container
start_container() {
    print_header "Starting xanadOS Build Container"

    cd "$CONTAINER_DIR"

    print_info "Starting container..."
    docker-compose up -d xanados-build

    print_status "Container started"
    print_info "Use 'exec' command to access the container"
}

# Stop the build container
stop_container() {
    print_header "Stopping xanadOS Build Container"

    cd "$CONTAINER_DIR"

    print_info "Stopping container..."
    docker-compose down

    print_status "Container stopped"
}

# Execute command in container
exec_container() {
    local service="${1:-xanados-build}"
    shift || true

    cd "$CONTAINER_DIR"

    if [[ $# -eq 0 ]]; then
        print_info "Opening interactive shell in $service..."
        docker-compose exec "$service" bash
    else
        print_info "Executing command in $service: $*"
        docker-compose exec "$service" "$@"
    fi
}

# Build all targets using container
build_all() {
    print_header "Building All Targets in Container"

    cd "$CONTAINER_DIR"

    # Ensure container is running
    if ! docker-compose ps xanados-build | grep -q "Up"; then
        print_info "Starting container..."
        docker-compose up -d xanados-build
    fi

    print_info "Building all targets..."
    docker-compose exec xanados-build container-build.sh --all "$@"

    print_status "All builds completed"
}

# Build specific target using container
build_target() {
    local target="$1"
    shift

    print_header "Building Target: $target"

    cd "$CONTAINER_DIR"

    # Ensure container is running
    if ! docker-compose ps xanados-build | grep -q "Up"; then
        print_info "Starting container..."
        docker-compose up -d xanados-build
    fi

    print_info "Building target: $target"
    docker-compose exec xanados-build container-build.sh --target "$target" "$@"

    print_status "Target $target build completed"
}

# Clean container environment
clean() {
    print_header "Cleaning Container Environment"

    cd "$CONTAINER_DIR"

    print_info "Stopping containers..."
    docker-compose down -v

    print_info "Removing images..."
    docker rmi xanados-build:latest 2>/dev/null || true

    print_info "Cleaning build artifacts..."
    rm -rf output/* dev-output/* cache/* logs/* dev-cache/* dev-logs/*

    print_status "Environment cleaned"
}

# Show container status
status() {
    print_header "Container Status"

    cd "$CONTAINER_DIR"

    print_info "Container status:"
    docker-compose ps

    echo
    print_info "Image information:"
    docker images | grep -E "(xanados-build|REPOSITORY)" || echo "No xanadOS images found"

    echo
    print_info "Volume usage:"
    docker system df
}

# Show logs
logs() {
    local service="${1:-xanados-build}"
    local tail_lines="${2:-100}"

    print_header "Container Logs: $service"

    cd "$CONTAINER_DIR"

    docker-compose logs --tail="$tail_lines" -f "$service"
}

# Test the build system
test_build() {
    print_header "Testing Build System"

    cd "$CONTAINER_DIR"

    # Start container if not running
    if ! docker-compose ps xanados-build | grep -q "Up"; then
        print_info "Starting container..."
        docker-compose up -d xanados-build
    fi

    print_info "Running build system test..."
    docker-compose exec xanados-build setup

    print_status "Build system test completed"
}

# Show help
show_help() {
    cat << 'EOF'
xanadOS Container Management Script

USAGE:
    container-manager.sh <command> [options]

COMMANDS:
    build           Build the container image
    start           Start the build container
    stop            Stop the build container
    exec [service]  Execute interactive shell in container
    shell           Alias for 'exec'

    build-all       Build all ISO targets in container
    build-target    Build specific target (x86-64-v3, x86-64-v4, compatibility)

    test            Test the build system
    status          Show container and image status
    logs [service]  Show container logs
    clean           Clean up containers, images, and build artifacts

    help            Show this help message

EXAMPLES:
    # Basic container management
    ./container-manager.sh build                    # Build container image
    ./container-manager.sh start                    # Start container
    ./container-manager.sh exec                     # Open shell in container
    ./container-manager.sh stop                     # Stop container

    # Build operations
    ./container-manager.sh build-all                # Build all targets
    ./container-manager.sh build-target x86-64-v3   # Build specific target
    ./container-manager.sh test                     # Test build system

    # Monitoring and maintenance
    ./container-manager.sh status                   # Check status
    ./container-manager.sh logs                     # View logs
    ./container-manager.sh clean                    # Clean everything

    # Development workflow
    ./container-manager.sh build && \
    ./container-manager.sh start && \
    ./container-manager.sh build-all

SERVICES:
    xanados-build   Production build container
    xanados-dev     Development container with debug tools

DIRECTORIES:
    build/containers/output/        Production build outputs
    build/containers/dev-output/    Development build outputs
    build/containers/cache/         Build cache (persistent)
    build/containers/logs/          Build logs (persistent)

NOTES:
    - Container requires privileged mode for ISO building
    - Source code is mounted from project root
    - Build cache persists between container restarts
    - Use 'clean' command to reset environment completely
EOF
}

# Main function
main() {
    # Check if running from correct directory
    if [[ ! -f "$PROJECT_ROOT/README.md" ]] || [[ ! -d "$PROJECT_ROOT/build" ]]; then
        print_error "Script must be run from xanadOS project directory"
        exit 1
    fi

    # Check dependencies
    check_dependencies

    # Parse command
    case "${1:-help}" in
        "build")
            build_image
            ;;
        "start")
            start_container
            ;;
        "stop")
            stop_container
            ;;
        "exec"|"shell")
            exec_container "${@:2}"
            ;;
        "build-all")
            build_all "${@:2}"
            ;;
        "build-target")
            if [[ $# -lt 2 ]]; then
                print_error "Target name required"
                print_info "Available targets: x86-64-v3, x86-64-v4, compatibility"
                exit 1
            fi
            build_target "${@:2}"
            ;;
        "test")
            test_build
            ;;
        "status")
            status
            ;;
        "logs")
            logs "${@:2}"
            ;;
        "clean")
            clean
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
