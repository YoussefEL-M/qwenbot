#!/bin/bash

# Model switching script for newqwen-chat
# Usage: ./switch-model.sh <model_name>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <model_name>"
    echo "Available models:"
    echo "  qwen05b    - Qwen/Qwen2.5-0.5B-Instruct"
    echo "  qwen3b     - Qwen/Qwen2.5-3B-Instruct"
    echo "  qwen7b     - Qwen/Qwen2.5-7B-Instruct"
    echo "  gptsw3     - AI-Sweden-Models/gpt-sw3-6.7b-v2-instruct"
    exit 1
fi

MODEL_NAME=$1

# Map model aliases to full names
case $MODEL_NAME in
    "qwen05b")
        FULL_MODEL_NAME="Qwen/Qwen2.5-0.5B-Instruct"
        ;;
    "qwen3b")
        FULL_MODEL_NAME="Qwen/Qwen2.5-3B-Instruct"
        ;;
    "qwen7b")
        FULL_MODEL_NAME="Qwen/Qwen2.5-7B-Instruct"
        ;;
    "gptsw3")
        FULL_MODEL_NAME="AI-Sweden-Models/gpt-sw3-6.7b-v2-instruct"
        ;;
    *)
        echo "Unknown model: $MODEL_NAME"
        echo "Available models: qwen05b, qwen3b, qwen7b, gptsw3"
        exit 1
        ;;
esac

echo "🔄 Switching to model: $FULL_MODEL_NAME"

# Update model configuration
echo "{\"model\": \"$FULL_MODEL_NAME\"}" > model_config.json

echo "✅ Model configuration updated"

# Try to switch model dynamically via API
echo "🔄 Attempting dynamic model switch..."

if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    # Server is running, try dynamic switch
    RESPONSE=$(curl -s -X POST http://localhost:8000/config/model \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$FULL_MODEL_NAME\"}")
    
    if echo "$RESPONSE" | grep -q '"status":"success"'; then
        echo "✅ Model switched dynamically!"
        echo "🚀 New model: $FULL_MODEL_NAME"
        echo "💡 Use the web interface to start a new chat with this model"
    else
        echo "⚠️  Dynamic switch failed, restarting server..."
        # Fallback to restart
        pkill -f "python.*app.py" 2>/dev/null || true
        sleep 2
        cd backend
        nohup python app.py > ../logs/backend.log 2>&1 &
        BACKEND_PID=$!
        echo "🚀 Backend restarted with PID: $BACKEND_PID"
    fi
else
    echo "🔄 Server not running, starting with new model..."
    cd backend
    nohup python app.py > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    echo "🚀 Backend started with PID: $BACKEND_PID"
fi

echo "📝 Check logs: tail -f logs/backend.log"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Health check: http://localhost:8000/health"