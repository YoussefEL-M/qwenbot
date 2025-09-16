#!/bin/bash

echo "🔄 Complete Chat System Restart"
echo "==================================="

# Check if we're in nix-shell
if [ -z "$IN_NIX_SHELL" ]; then
    echo "❌ Not in nix-shell. Please run:"
    echo "nix-shell ../qwen-shell.nix"
    echo "cd qwen-chat"
    echo "./complete-restart.sh"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Kill all processes
echo -e "${YELLOW}🛑 Stopping all services...${NC}"
pkill -f "python.*app.py" 2>/dev/null || true
pkill -f "python.*simple-react-server.py" 2>/dev/null || true
pkill -f "npm.*start" 2>/dev/null || true

# Kill processes using specific ports
echo -e "${YELLOW}🛑 Freeing ports 8000 and 3000...${NC}"
lsof -ti :8000 | xargs kill -9 2>/dev/null || true
lsof -ti :3000 | xargs kill -9 2>/dev/null || true

sleep 5

# Create directories
mkdir -p logs model_cache offload_cache

# Start backend first
echo -e "${BLUE}🤖 Starting Chat backend...${NC}"

# Check if Python is available
if ! command -v python &> /dev/null; then
    echo -e "${RED}❌ Python not found! Make sure you're in nix-shell${NC}"
    exit 1
fi

# Load model configuration
if [ -f "model_config.json" ]; then
    MODEL_NAME=$(python3 -c "import json; print(json.load(open('model_config.json'))['model'])")
    echo -e "${GREEN}📋 Using model: $MODEL_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  No model config found, using default${NC}"
fi

echo "Python version: $(python --version)"
cd backend
nohup python app.py > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
cd ..
sleep 3

# Wait for backend with better checking
echo -e "${YELLOW}⏳ Waiting for backend to start...${NC}"
for i in {1..30}; do
    if curl -s --max-time 2 http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend health check OK${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Backend failed to start${NC}"
        echo "Backend logs:"
        tail -10 logs/backend.log
        exit 1
    fi
    sleep 2
    echo -n "."
done

# Test WebSocket endpoint specifically
echo -e "${YELLOW}🔌 Testing WebSocket endpoint...${NC}"
python3 -c "
import requests
try:
    response = requests.get('http://localhost:8000/ws', timeout=5)
    print(f'WebSocket endpoint status: {response.status_code}')
except Exception as e:
    print(f'WebSocket test error: {e}')
"

# Start secure frontend server
echo -e "${BLUE}🌐 Starting Secure Frontend Server...${NC}"
echo -e "${YELLOW}🚀 Serving chat interface only...${NC}"
nohup python3 simple-server.py > logs/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
sleep 3

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down services...${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    exit
}
trap cleanup SIGINT SIGTERM

echo ""
echo -e "${GREEN}🎉 Services starting up!${NC}"
echo "=================================="
echo -e "${BLUE}Backend:${NC}   http://localhost:8000"
echo -e "${BLUE}Frontend:${NC}  http://localhost:3000"
echo -e "${BLUE}External:${NC}  https://rosetta.semaphor.dk/qwen/"
echo -e "${BLUE}Health:${NC}    http://localhost:8000/health"
echo -e "${BLUE}WebSocket:${NC} wss://rosetta.semaphor.dk/qwen/ws/"
echo ""

# Wait for frontend
echo -e "${YELLOW}⏳ Waiting for frontend...${NC}"
for i in {1..20}; do
    if curl -s --max-time 1 http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend ready${NC}"
        break
    fi
    
    # Check if frontend process died
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${RED}❌ Frontend process died during startup!${NC}"
        echo "Frontend logs:"
        cat logs/frontend.log | tail -10
        exit 1
    fi
    
    sleep 1
done

echo ""
echo -e "${GREEN}🎉🎉 ALL SERVICES RUNNING! 🎉🎉${NC}"
echo -e "${GREEN}🌐 https://rosetta.semaphor.dk/qwen/${NC}"
echo -e "${YELLOW}🛑 Press Ctrl+C to stop${NC}"

# Monitor services
while true; do
    sleep 5
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${RED}❌ Backend died!${NC}"
        exit 1
    fi
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${RED}❌ Frontend died!${NC}"
        exit 1
    fi
done