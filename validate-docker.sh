#!/bin/bash

# Docker/Podman Configuration Validation Script
# This script validates the Docker setup for the Qwen Chat System

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED=$((FAILED + 1))
}

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        print_success "$description exists: $file"
        return 0
    else
        print_error "$description missing: $file"
        return 1
    fi
}

# Function to check if file is executable
check_executable() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ] && [ -x "$file" ]; then
        print_success "$description is executable: $file"
        return 0
    elif [ -f "$file" ]; then
        print_warning "$description exists but is not executable: $file"
        return 1
    else
        print_error "$description missing: $file"
        return 1
    fi
}

# Function to check Docker/Podman availability
check_container_runtime() {
    print_status "Checking container runtime availability..."
    
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            print_success "Docker is available and running"
            return 0
        else
            print_warning "Docker is installed but not running"
        fi
    fi
    
    if command -v podman >/dev/null 2>&1; then
        if podman info >/dev/null 2>&1; then
            print_success "Podman is available and running"
            return 0
        else
            print_warning "Podman is installed but not running"
        fi
    fi
    
    print_error "No container runtime is available or running"
    return 1
}

# Function to check compose availability
check_compose() {
    print_status "Checking compose availability..."
    
    local has_compose=false
    
    if command -v docker-compose >/dev/null 2>&1; then
        print_success "docker-compose is available"
        has_compose=true
    fi
    
    if docker compose version >/dev/null 2>&1 2>/dev/null; then
        print_success "docker compose (plugin) is available"
        has_compose=true
    fi
    
    if command -v podman-compose >/dev/null 2>&1; then
        print_success "podman-compose is available"
        has_compose=true
    fi
    
    if podman compose version >/dev/null 2>&1 2>/dev/null; then
        print_success "podman compose (plugin) is available"
        has_compose=true
    fi
    
    if [ "$has_compose" = false ]; then
        print_error "No compose tool is available"
        return 1
    fi
    
    return 0
}

# Function to validate Dockerfile
validate_dockerfile() {
    print_status "Validating Dockerfile..."
    
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found"
        return 1
    fi
    
    # Check for required stages
    if grep -q "FROM.*as base" Dockerfile; then
        print_success "Base stage found in Dockerfile"
    else
        print_error "Base stage not found in Dockerfile"
    fi
    
    if grep -q "FROM.*as torch-cuda" Dockerfile; then
        print_success "CUDA stage found in Dockerfile"
    else
        print_error "CUDA stage not found in Dockerfile"
    fi
    
    if grep -q "FROM.*as torch-cpu" Dockerfile; then
        print_success "CPU stage found in Dockerfile"
    else
        print_error "CPU stage not found in Dockerfile"
    fi
    
    if grep -q "EXPOSE 8000 3000" Dockerfile; then
        print_success "Ports exposed in Dockerfile"
    else
        print_error "Ports not exposed in Dockerfile"
    fi
    
    if grep -q "HEALTHCHECK" Dockerfile; then
        print_success "Health check configured in Dockerfile"
    else
        print_warning "Health check not configured in Dockerfile"
    fi
}

# Function to validate docker-compose.yml
validate_compose() {
    print_status "Validating docker-compose.yml..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found"
        return 1
    fi
    
    # Check for required services
    if grep -q "qwen-chat:" docker-compose.yml; then
        print_success "qwen-chat service found in docker-compose.yml"
    else
        print_error "qwen-chat service not found in docker-compose.yml"
    fi
    
    # Check for required volumes
    if grep -q "qwen_model_cache:" docker-compose.yml; then
        print_success "Model cache volume configured"
    else
        print_error "Model cache volume not configured"
    fi
    
    # Check for environment variables
    if grep -q "MODEL_NAME" docker-compose.yml; then
        print_success "Model name environment variable configured"
    else
        print_warning "Model name environment variable not configured"
    fi
    
    # Check for port mappings
    if grep -q "8000:8000" docker-compose.yml; then
        print_success "Backend port mapping configured"
    else
        print_error "Backend port mapping not configured"
    fi
    
    if grep -q "3000:3000" docker-compose.yml; then
        print_success "Frontend port mapping configured"
    else
        print_error "Frontend port mapping not configured"
    fi
}

# Function to validate entrypoint script
validate_entrypoint() {
    print_status "Validating docker-entrypoint.sh..."
    
    if [ ! -f "docker-entrypoint.sh" ]; then
        print_error "docker-entrypoint.sh not found"
        return 1
    fi
    
    if [ -x "docker-entrypoint.sh" ]; then
        print_success "docker-entrypoint.sh is executable"
    else
        print_warning "docker-entrypoint.sh is not executable"
    fi
    
    # Check for required functions
    if grep -q "start_all()" docker-entrypoint.sh; then
        print_success "start_all function found in entrypoint"
    else
        print_error "start_all function not found in entrypoint"
    fi
    
    if grep -q "start_backend()" docker-entrypoint.sh; then
        print_success "start_backend function found in entrypoint"
    else
        print_error "start_backend function not found in entrypoint"
    fi
    
    if grep -q "start_frontend()" docker-entrypoint.sh; then
        print_success "start_frontend function found in entrypoint"
    else
        print_error "start_frontend function not found in entrypoint"
    fi
}

# Function to validate required files
validate_required_files() {
    print_status "Validating required application files..."
    
    local required_files=(
        "backend/app.py:Backend application"
        "backend/requirements.txt:Python requirements"
        "simple-server.py:Frontend server"
        "simple-frontend.html:Frontend interface"
        "model_config.json:Model configuration"
    )
    
    for file_desc in "${required_files[@]}"; do
        local file=$(echo "$file_desc" | cut -d: -f1)
        local description=$(echo "$file_desc" | cut -d: -f2)
        check_file "$file" "$description"
    done
}

# Function to validate environment files
validate_environment() {
    print_status "Validating environment configuration..."
    
    if [ -f ".env.example" ]; then
        print_success ".env.example file exists"
    else
        print_warning ".env.example file not found"
    fi
    
    if [ -f ".env" ]; then
        print_success ".env file exists"
    else
        print_warning ".env file not found (will be created from .env.example)"
    fi
}

# Function to validate startup script
validate_startup_script() {
    print_status "Validating startup script..."
    
    if [ -f "start-docker.sh" ]; then
        print_success "start-docker.sh exists"
        
        if [ -x "start-docker.sh" ]; then
            print_success "start-docker.sh is executable"
        else
            print_warning "start-docker.sh is not executable"
        fi
        
        # Check for required functions
        if grep -q "detect_runtime()" start-docker.sh; then
            print_success "Runtime detection function found"
        else
            print_error "Runtime detection function not found"
        fi
        
        if grep -q "check_prerequisites()" start-docker.sh; then
            print_success "Prerequisites check function found"
        else
            print_error "Prerequisites check function not found"
        fi
    else
        print_error "start-docker.sh not found"
    fi
}

# Function to test Docker build (if possible)
test_docker_build() {
    print_status "Testing Docker build (this may take a while)..."
    
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        if docker build --target torch-cpu -t qwen-chat-test . >/dev/null 2>&1; then
            print_success "Docker build test passed (CPU-only)"
            docker rmi qwen-chat-test >/dev/null 2>&1 || true
        else
            print_error "Docker build test failed"
        fi
    else
        print_warning "Docker not available, skipping build test"
    fi
}

# Function to show summary
show_summary() {
    echo ""
    echo "=========================================="
    echo "Validation Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        print_success "All critical checks passed! Docker setup is ready."
        echo ""
        echo "Next steps:"
        echo "1. Run: ./start-docker.sh"
        echo "2. Access: http://localhost:3000"
        echo "3. Check logs: ./start-docker.sh --logs"
    else
        print_error "Some critical checks failed. Please fix the issues above."
        exit 1
    fi
}

# Main validation function
main() {
    echo "Qwen Chat System - Docker Configuration Validation"
    echo "=================================================="
    echo ""
    
    # Run all validations
    validate_required_files
    echo ""
    
    validate_environment
    echo ""
    
    validate_dockerfile
    echo ""
    
    validate_compose
    echo ""
    
    validate_entrypoint
    echo ""
    
    validate_startup_script
    echo ""
    
    check_container_runtime
    echo ""
    
    check_compose
    echo ""
    
    test_docker_build
    echo ""
    
    show_summary
}

# Run main function
main "$@"