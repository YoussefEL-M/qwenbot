#!/bin/bash

# Qwen Chat System - Docker/Podman Startup Script
# This script provides an easy way to start the Qwen Chat System with Docker or Podman

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect container runtime
detect_runtime() {
    if command_exists docker && docker info >/dev/null 2>&1; then
        echo "docker"
    elif command_exists podman && podman info >/dev/null 2>&1; then
        echo "podman"
    else
        echo "none"
    fi
}

# Function to check if compose is available
check_compose() {
    local runtime=$1
    
    if [ "$runtime" = "docker" ]; then
        if command_exists docker-compose; then
            echo "docker-compose"
        elif docker compose version >/dev/null 2>&1; then
            echo "docker compose"
        else
            echo "none"
        fi
    elif [ "$runtime" = "podman" ]; then
        if command_exists podman-compose; then
            echo "podman-compose"
        elif podman compose version >/dev/null 2>&1; then
            echo "podman compose"
        else
            echo "none"
        fi
    else
        echo "none"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        print_warning ".env file not found, creating from example..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env file from .env.example"
        else
            print_error ".env.example file not found!"
            exit 1
        fi
    fi
    
    # Check if model_config.json exists
    if [ ! -f "model_config.json" ]; then
        print_warning "model_config.json not found, creating default..."
        echo '{"model": "Qwen/Qwen2.5-0.5B-Instruct"}' > model_config.json
        print_success "Created default model_config.json"
    fi
    
    # Check if required files exist
    local required_files=("simple-frontend.html" "simple-server.py" "backend/app.py")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done
    
    print_success "Prerequisites check passed"
}

# Function to start services
start_services() {
    local runtime=$1
    local compose_cmd=$2
    
    print_status "Starting Qwen Chat System with $runtime..."
    
    # Create necessary directories
    mkdir -p logs model_cache offload_cache
    
    # Start services
    print_status "Building and starting containers..."
    $compose_cmd up -d --build
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8000/health >/dev/null 2>&1; then
            print_success "Backend is ready!"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Backend failed to start after $max_attempts attempts"
            print_status "Check logs with: $compose_cmd logs"
            exit 1
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for backend..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    # Check frontend
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend is ready!"
    else
        print_warning "Frontend may not be ready yet, check logs with: $compose_cmd logs"
    fi
}

# Function to show status
show_status() {
    local runtime=$1
    local compose_cmd=$2
    
    print_status "Qwen Chat System Status:"
    echo "================================"
    
    # Show container status
    $compose_cmd ps
    
    echo ""
    print_status "Service URLs:"
    echo "  Frontend:  http://localhost:3000"
    echo "  Backend:   http://localhost:8000"
    echo "  Health:    http://localhost:8000/health"
    
    echo ""
    print_status "Management Commands:"
    echo "  View logs:     $compose_cmd logs -f"
    echo "  Stop:          $compose_cmd down"
    echo "  Restart:       $compose_cmd restart"
    echo "  Shell access:  $compose_cmd exec qwen-chat bash"
}

# Function to show help
show_help() {
    echo "Qwen Chat System - Docker/Podman Startup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --status   Show service status"
    echo "  -l, --logs     Show service logs"
    echo "  -d, --down     Stop services"
    echo "  -r, --restart  Restart services"
    echo "  --cpu-only     Use CPU-only version (no GPU)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Start services"
    echo "  $0 --status           # Show status"
    echo "  $0 --logs             # Show logs"
    echo "  $0 --down             # Stop services"
    echo "  $0 --cpu-only         # Start with CPU-only version"
}

# Main script
main() {
    local action="start"
    local cpu_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--status)
                action="status"
                shift
                ;;
            -l|--logs)
                action="logs"
                shift
                ;;
            -d|--down)
                action="down"
                shift
                ;;
            -r|--restart)
                action="restart"
                shift
                ;;
            --cpu-only)
                cpu_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Detect container runtime
    local runtime=$(detect_runtime)
    if [ "$runtime" = "none" ]; then
        print_error "Neither Docker nor Podman is available or running"
        print_status "Please install and start Docker or Podman"
        exit 1
    fi
    
    print_success "Detected container runtime: $runtime"
    
    # Check compose availability
    local compose_cmd=$(check_compose "$runtime")
    if [ "$compose_cmd" = "none" ]; then
        print_error "Docker Compose or Podman Compose not available"
        print_status "Please install docker-compose or podman-compose"
        exit 1
    fi
    
    print_success "Using compose command: $compose_cmd"
    
    # Handle CPU-only mode
    if [ "$cpu_only" = true ]; then
        print_status "Using CPU-only mode"
        export COMPOSE_FILE="docker-compose.yml:docker-compose.override.yml"
    fi
    
    # Execute action
    case $action in
        "start")
            check_prerequisites
            start_services "$runtime" "$compose_cmd"
            show_status "$runtime" "$compose_cmd"
            ;;
        "status")
            show_status "$runtime" "$compose_cmd"
            ;;
        "logs")
            $compose_cmd logs -f
            ;;
        "down")
            print_status "Stopping services..."
            $compose_cmd down
            print_success "Services stopped"
            ;;
        "restart")
            print_status "Restarting services..."
            $compose_cmd restart
            print_success "Services restarted"
            ;;
    esac
}

# Run main function
main "$@"