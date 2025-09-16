# Available Models for 12GB VRAM

This chat system supports multiple models optimized for 12GB VRAM systems.

## Supported Models

### 🤖 Qwen 2.5 3B (Default)
- **Model**: `Qwen/Qwen2.5-3B-Instruct`
- **VRAM**: ~3-4GB
- **Speed**: Very Fast
- **Quality**: Good for general chat
- **Best for**: Quick responses, general conversation

### 🦙 Llama 3 8B
- **Model**: `meta-llama/Llama-3-8B-Instruct`
- **VRAM**: ~8-10GB
- **Speed**: Fast
- **Quality**: Excellent
- **Best for**: High-quality responses, complex reasoning

### 💎 Gemma 2 9B
- **Model**: `google/gemma-2-9b-it`
- **VRAM**: ~9-11GB
- **Speed**: Good
- **Quality**: Very Good
- **Best for**: Balanced performance and quality

### 🇸🇪 GPT-SW3 6.7B
- **Model**: `AI-Sweden-Models/gpt-sw3-6.7b-v2-instruct`
- **VRAM**: ~7-9GB
- **Speed**: Good
- **Quality**: Good
- **Best for**: Multilingual support, Swedish language

## How to Switch Models

### Method 1: Using the Web Interface (Recommended)
1. Click the **New Chat** button (➕) in the top-right corner
2. A model selection modal will appear
3. Choose your desired model from the dropdown
4. Click "Start New Chat"
5. Wait 30-60 seconds for automatic model switching
6. The current model will be displayed in the header

### Method 2: Using the Command Line
```bash
# Switch to Llama 3 8B
./switch-model.sh llama8b

# Switch to Gemma 2 9B
./switch-model.sh gemma9b

# Switch to GPT-SW3
./switch-model.sh gptsw3

# Switch back to Qwen 3B
./switch-model.sh qwen3b
```

### Method 3: Manual Configuration
Edit `model_config.json`:
```json
{
    "model": "meta-llama/Llama-3-8B-Instruct"
}
```
Then restart with `./complete-restart.sh`

## Dynamic Model Switching

The system supports **dynamic model switching** when starting new chats:

- ✅ **Modal Selection**: Choose model when starting new chat
- ✅ **Automatic**: Models load/unload automatically
- ✅ **Memory Efficient**: Previous model is unloaded before loading new one
- ✅ **Real-time**: Switch happens in 30-60 seconds
- ✅ **Status Updates**: Current model displayed in header
- ✅ **Error Handling**: Fallback to restart if dynamic switch fails

## Performance Tips

- **Qwen 3B**: Best for development and testing
- **Llama 3 8B**: Best overall quality for production
- **Gemma 2 9B**: Good balance of speed and quality
- **GPT-SW3**: Best for Swedish/multilingual content

## Troubleshooting

If a model fails to load:
1. Check available VRAM: `nvidia-smi`
2. Try a smaller model first
3. Check logs: `tail -f logs/backend.log`
4. Ensure you have enough disk space for model cache

## Model Cache

Models are cached in `backend/model_cache/` to avoid re-downloading. Each model can take 5-15GB of disk space.