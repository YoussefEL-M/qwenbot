#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to wait for a service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 2 "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Function to start backend
start_backend() {
    print_status "Starting Qwen Chat Backend..."
    
    # Check if port 8000 is available
    if ! check_port 8000; then
        print_warning "Port 8000 is already in use, attempting to free it..."
        lsof -ti :8000 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # Start backend
    cd /app/backend
    nohup python app.py > /app/logs/backend.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > /app/logs/backend.pid
    
    print_status "Backend started with PID: $BACKEND_PID"
    
    # Wait for backend to be ready
    if wait_for_service "http://localhost:8000/health" "Backend"; then
        print_success "Backend is ready!"
    else
        print_error "Backend failed to start. Check logs: tail -f /app/logs/backend.log"
        exit 1
    fi
}

# Function to start frontend
start_frontend() {
    print_status "Starting Frontend Server..."
    
    # Check if port 3000 is available
    if ! check_port 3000; then
        print_warning "Port 3000 is already in use, attempting to free it..."
        lsof -ti :3000 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # Start frontend
    cd /app
    nohup python simple-server.py > /app/logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > /app/logs/frontend.pid
    
    print_status "Frontend started with PID: $FRONTEND_PID"
    
    # Wait for frontend to be ready
    if wait_for_service "http://localhost:3000" "Frontend"; then
        print_success "Frontend is ready!"
    else
        print_error "Frontend failed to start. Check logs: tail -f /app/logs/frontend.log"
        exit 1
    fi
}

# Function to start all services
start_all() {
    print_status "🚀 Starting Qwen Chat System..."
    
    # Create necessary directories
    mkdir -p /app/logs /app/model_cache /app/offload_cache
    
    # Start backend first
    start_backend
    
    # Start frontend
    start_frontend
    
    print_success "🎉 All services are running!"
    print_status "Backend: http://localhost:8000"
    print_status "Frontend: http://localhost:3000"
    print_status "Health Check: http://localhost:8000/health"
    
    # Monitor services
    monitor_services
}

# Function to monitor services
monitor_services() {
    print_status "Monitoring services..."
    
    while true; do
        sleep 10
        
        # Check backend
        if [ -f /app/logs/backend.pid ]; then
            BACKEND_PID=$(cat /app/logs/backend.pid)
            if ! kill -0 $BACKEND_PID 2>/dev/null; then
                print_error "Backend process died! Restarting..."
                start_backend
            fi
        fi
        
        # Check frontend
        if [ -f /app/logs/frontend.pid ]; then
            FRONTEND_PID=$(cat /app/logs/frontend.pid)
            if ! kill -0 $FRONTEND_PID 2>/dev/null; then
                print_error "Frontend process died! Restarting..."
                start_frontend
            fi
        fi
    done
}

# Function to stop services
stop_services() {
    print_status "Stopping services..."
    
    # Stop backend
    if [ -f /app/logs/backend.pid ]; then
        BACKEND_PID=$(cat /app/logs/backend.pid)
        kill $BACKEND_PID 2>/dev/null || true
        rm -f /app/logs/backend.pid
    fi
    
    # Stop frontend
    if [ -f /app/logs/frontend.pid ]; then
        FRONTEND_PID=$(cat /app/logs/frontend.pid)
        kill $FRONTEND_PID 2>/dev/null || true
        rm -f /app/logs/frontend.pid
    fi
    
    # Kill any remaining processes
    pkill -f "python.*app.py" 2>/dev/null || true
    pkill -f "python.*simple-server.py" 2>/dev/null || true
    
    print_success "Services stopped"
}

# Function to show logs
show_logs() {
    local service=${1:-"all"}
    
    case $service in
        "backend")
            tail -f /app/logs/backend.log
            ;;
        "frontend")
            tail -f /app/logs/frontend.log
            ;;
        "all")
            tail -f /app/logs/*.log
            ;;
        *)
            echo "Usage: $0 logs [backend|frontend|all]"
            exit 1
            ;;
    esac
}

# Function to show status
show_status() {
    print_status "Qwen Chat System Status:"
    echo "================================"
    
    # Check backend
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        print_success "Backend: Running (http://localhost:8000)"
    else
        print_error "Backend: Not running"
    fi
    
    # Check frontend
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "Frontend: Running (http://localhost:3000)"
    else
        print_error "Frontend: Not running"
    fi
    
    # Show model info
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo ""
        print_status "Model Information:"
        curl -s http://localhost:8000/health | python -m json.tool 2>/dev/null || echo "Unable to fetch model info"
    fi
}

# Main script logic
case "${1:-start}" in
    "start")
        start_all
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        sleep 2
        start_all
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "backend")
        start_backend
        monitor_services
        ;;
    "frontend")
        start_frontend
        monitor_services
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|backend|frontend}"
        echo ""
        echo "Commands:"
        echo "  start     - Start all services (default)"
        echo "  stop      - Stop all services"
        echo "  restart   - Restart all services"
        echo "  status    - Show service status"
        echo "  logs      - Show logs (backend|frontend|all)"
        echo "  backend   - Start only backend"
        echo "  frontend  - Start only frontend"
        exit 1
        ;;
esac