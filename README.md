# Qwen Chat System

A high-performance, containerized chat system powered by Qwen 2.5 and other large language models, optimized for 12GB VRAM systems with dynamic model switching capabilities.

## 🚀 Features

### Core Features
- **Dynamic Model Switching**: Switch between different LLM models without restarting the system
- **Memory Optimized**: Designed for 12GB VRAM systems with intelligent memory management
- **Real-time Streaming**: WebSocket-based streaming responses for smooth chat experience
- **Multi-Model Support**: Qwen 2.5, Llama 3, Gemma 2, and GPT-SW3 models
- **Modern Web Interface**: Beautiful, responsive chat interface with syntax highlighting
- **Containerized**: Full Docker/Podman support with health checks and logging

### Technical Features
- **GPU Acceleration**: CUDA support with automatic GPU detection
- **Memory Management**: Automatic model unloading and memory optimization
- **Caching**: Persistent model cache to avoid re-downloading
- **Health Monitoring**: Built-in health checks and status endpoints
- **Logging**: Comprehensive logging with rotation
- **Security**: Non-root container execution and secure file serving

### Supported Models
- **Qwen 2.5 3B** (Default) - Fast, efficient for general chat
- **Llama 3 8B** - High-quality responses and complex reasoning
- **Gemma 2 9B** - Balanced performance and quality
- **GPT-SW3 6.7B** - Multilingual support, especially Swedish

## 🏗️ Architecture

The system consists of three main components:

1. **Backend API** (`backend/app.py`)
   - FastAPI-based REST API
   - WebSocket support for streaming
   - Dynamic model loading/unloading
   - Memory optimization and GPU management

2. **Frontend Interface** (`simple-frontend.html`)
   - Modern, responsive web interface
   - Real-time chat with streaming
   - Syntax highlighting for code
   - Model switching interface

3. **Static Server** (`simple-server.py`)
   - Lightweight HTTP server
   - Serves frontend and static assets
   - Security-focused file serving

## 🚀 Quick Start

### Prerequisites
- Docker or Podman installed and running
- 12GB+ VRAM (for GPU acceleration)
- 20GB+ free disk space (for model cache)

### Using Docker (Current)
```bash
# Clone and navigate to the project
git clone <repository-url>
cd newqwen-chat

# Start the system
./start-docker.sh

# Access the chat interface
open http://localhost:3000
```

### Using Podman (Coming Soon)
```bash
# Start with Podman (when implemented)
./start-podman.sh

# Access the chat interface
open http://localhost:3000
```

## 📋 Management Commands

### Docker Commands
```bash
# Start services
./start-docker.sh

# Check status
./start-docker.sh --status

# View logs
./start-docker.sh --logs

# Stop services
./start-docker.sh --down

# Restart services
./start-docker.sh --restart

# CPU-only mode (no GPU)
./start-docker.sh --cpu-only
```

### Model Management
```bash
# Switch models via script
./switch-model.sh qwen3b      # Qwen 2.5 3B
./switch-model.sh llama8b     # Llama 3 8B
./switch-model.sh gemma9b     # Gemma 2 9B
./switch-model.sh gptsw3      # GPT-SW3 6.7B

# Complete restart (if needed)
./complete-restart.sh
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file to customize settings:
```bash
# Model configuration
MODEL_NAME=Qwen/Qwen2.5-3B-Instruct
MAX_MEMORY_GB=12
DEVICE=auto

# Optional: Custom model
# MODEL_NAME=meta-llama/Llama-3-8B-Instruct
```

### Model Configuration
Edit `model_config.json` to set the default model:
```json
{
    "model": "Qwen/Qwen2.5-3B-Instruct"
}
```

## 🌐 API Endpoints

### REST API
- `GET /` - Basic health check
- `GET /health` - Detailed system status
- `POST /chat` - Chat completion (non-streaming)
- `POST /config/model` - Switch model dynamically

### WebSocket
- `WS /ws` - Streaming chat interface

### Example API Usage
```bash
# Health check
curl http://localhost:8000/health

# Chat completion
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 100
  }'

# Switch model
curl -X POST http://localhost:8000/config/model \
  -H "Content-Type: application/json" \
  -d '{"model": "meta-llama/Llama-3-8B-Instruct"}'
```

## 🎯 Model Switching

### Via Web Interface (Recommended)
1. Click the **New Chat** button (➕) in the header
2. Select your desired model from the dropdown
3. Click "Start New Chat"
4. Wait 30-60 seconds for automatic model switching
5. Current model is displayed in the header

### Via API
```bash
# Switch to Llama 3 8B
curl -X POST http://localhost:8000/config/model \
  -H "Content-Type: application/json" \
  -d '{"model": "meta-llama/Llama-3-8B-Instruct"}'
```

### Via Configuration File
```bash
# Edit model_config.json
echo '{"model": "meta-llama/Llama-3-8B-Instruct"}' > model_config.json

# Restart services
./complete-restart.sh
```

## 🔍 Monitoring and Debugging

### Health Checks
```bash
# Check system status
curl http://localhost:8000/health

# Check container status
docker-compose ps
# or
podman-compose ps
```

### Logs
```bash
# View all logs
./start-docker.sh --logs

# View specific service logs
docker-compose logs -f qwen-chat
# or
podman-compose logs -f qwen-chat

# View backend logs
tail -f logs/backend.log
```

### GPU Monitoring
```bash
# Check GPU usage
nvidia-smi

# Check GPU memory
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

## 🐛 Troubleshooting

### Common Issues

#### Build Context Too Large (60GB+)
The large build context is caused by model cache being included. This is being addressed in the Podman migration.

**Temporary fix:**
```bash
# Move model cache out of build context
mv model_cache ../model_cache_backup
./start-docker.sh
mv ../model_cache_backup model_cache
```

#### Model Loading Fails
```bash
# Check available VRAM
nvidia-smi

# Try a smaller model first
curl -X POST http://localhost:8000/config/model \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen2.5-0.5B-Instruct"}'

# Check logs
tail -f logs/backend.log
```

#### Out of Memory
```bash
# Use CPU-only mode
./start-docker.sh --cpu-only

# Or switch to a smaller model
./switch-model.sh qwen3b
```

#### Container Won't Start
```bash
# Check prerequisites
./validate-docker.sh

# Check logs
docker-compose logs

# Complete restart
./complete-restart.sh
```

### Performance Optimization

#### For 12GB VRAM Systems
- Use Qwen 2.5 3B for development
- Use Llama 3 8B for production quality
- Monitor GPU memory with `nvidia-smi`
- Enable memory optimization in the backend

#### For CPU-Only Systems
- Use `--cpu-only` flag
- Expect slower response times
- Consider smaller models

## 📁 Project Structure

```
newqwen-chat/
├── backend/                 # Backend API code
│   ├── app.py              # Main FastAPI application
│   ├── requirements.txt    # Python dependencies
│   └── model_cache/        # Cached models (created at runtime)
├── logs/                   # Application logs
├── model_cache/            # Model cache (created at runtime)
├── offload_cache/          # Model offload cache (created at runtime)
├── docker-compose.yml      # Docker Compose configuration
├── docker-compose.override.yml  # Override for CPU-only mode
├── Dockerfile              # Multi-stage Docker build
├── start-docker.sh         # Docker startup script
├── start-podman.sh         # Podman startup script (coming soon)
├── switch-model.sh         # Model switching script
├── complete-restart.sh     # Complete system restart
├── validate-docker.sh      # Docker validation script
├── simple-frontend.html    # Web interface
├── simple-server.py        # Static file server
├── model_config.json       # Model configuration
├── .env.example           # Environment variables template
└── README.md              # This file
```

## 🔮 Roadmap

### Podman Migration (In Progress)
- [ ] Podman-specific docker-compose configuration
- [ ] Podman startup script
- [ ] GPU support with Podman
- [ ] Optimized build context
- [ ] Podman documentation

### Planned Features
- [ ] Model quantization support
- [ ] Batch inference capabilities
- [ ] API authentication
- [ ] Multi-user support
- [ ] Model fine-tuning interface
- [ ] Advanced monitoring dashboard

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both Docker and Podman
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Qwen Team](https://github.com/QwenLM/Qwen) for the excellent Qwen models
- [Hugging Face](https://huggingface.co/) for the transformers library
- [FastAPI](https://fastapi.tiangolo.com/) for the web framework
- [Docker](https://www.docker.com/) and [Podman](https://podman.io/) for containerization

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs
3. Open an issue on GitHub
4. Check the model-specific documentation in `MODELS.md`

---

**Note**: This system is optimized for 12GB VRAM systems. For different hardware configurations, adjust the memory settings in the configuration files.