# Qwen 2.5 Chat System

A comprehensive AI chat system powered by Qwen 2.5 language models, featuring a modern web interface, real-time streaming, and flexible deployment options.

## 🌟 Features

### Core Functionality
- **AI Chat Interface**: Interactive chat with Qwen 2.5 language models
- **Real-time Streaming**: WebSocket-based streaming responses for natural conversation flow
- **Model Switching**: Dynamic model loading and switching without restart
- **Multiple Model Support**: Compatible with various Qwen model sizes (0.5B, 3B, 7B, etc.)
- **CPU/GPU Support**: Optimized for both CPU and GPU inference
- **Memory Management**: Efficient memory usage with model offloading capabilities

### Web Interface
- **Modern UI**: Clean, responsive chat interface with syntax highlighting
- **Real-time Updates**: Live message streaming and typing indicators
- **Model Selection**: Easy model switching through the web interface
- **Mobile Responsive**: Works seamlessly on desktop and mobile devices
- **Dark/Light Themes**: Customizable interface themes

### API Features
- **RESTful API**: Complete REST API for integration
- **WebSocket Support**: Real-time bidirectional communication
- **Health Monitoring**: Built-in health checks and status endpoints
- **CORS Support**: Cross-origin resource sharing for web applications
- **Error Handling**: Comprehensive error handling and logging

### Deployment Options
- **Docker Support**: Containerized deployment with Docker Compose
- **Podman Ready**: Configuration files prepared for Podman migration
- **Nginx Integration**: Production-ready reverse proxy configuration
- **Environment Configuration**: Flexible environment-based configuration

## 🏗️ Architecture

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │   Nginx Proxy   │    │  Docker Container│
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │Frontend   │  │◄───┤  │Port 3001  │  │◄───┤  │Port 3000  │  │
│  │(React)    │  │    │  │Frontend   │  │    │  │Frontend   │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │WebSocket  │  │◄───┤  │Port 8004  │  │◄───┤  │Port 8000  │  │
│  │Connection │  │    │  │Backend    │  │    │  │Backend    │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack

- **Backend**: FastAPI (Python 3.11)
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **AI Model**: Qwen 2.5 (Hugging Face Transformers)
- **WebSocket**: FastAPI WebSocket support
- **Containerization**: Docker with multi-stage builds
- **Reverse Proxy**: Nginx
- **Database**: In-memory (stateless design)

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- 8GB+ RAM (for 0.5B model)
- 16GB+ RAM (for 3B model)
- Optional: NVIDIA GPU with CUDA support

### 1. Clone and Setup

```bash
git clone <repository-url>
cd newqwen-chat
```

### 2. Configure Environment

Edit `docker-compose.override.yml` to customize your setup:

```yaml
services:
  qwen-chat:
    environment:
      - MODEL_NAME=Qwen/Qwen2.5-0.5B-Instruct  # Default model
      - MAX_MEMORY_GB=8                        # Memory limit
      - DEVICE=cpu                             # cpu or cuda
```

### 3. Start the System

```bash
./start-docker.sh
```

### 4. Access the Interface

- **Web Interface**: https://rosetta.semaphor.dk/qwen/
- **API Health**: https://rosetta.semaphor.dk/qwen/health
- **API Documentation**: https://rosetta.semaphor.dk/qwen-api/docs

## 📖 Detailed Usage

### Web Interface

1. **Starting a Chat**:
   - Open the web interface
   - Type your message in the input field
   - Press Enter or click Send
   - Watch the AI response stream in real-time

2. **Switching Models**:
   - Click the model selector dropdown
   - Choose from available models
   - Wait for the model to load (indicated by status)

3. **Chat Features**:
   - **Streaming Responses**: See responses appear word-by-word
   - **Syntax Highlighting**: Code blocks are automatically highlighted
   - **Message History**: Previous messages are preserved in the session
   - **Copy Responses**: Click to copy AI responses

### API Usage

#### Chat Endpoint

```bash
curl -X POST "https://rosetta.semaphor.dk/qwen-api/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ],
    "stream": false,
    "max_tokens": 2048,
    "temperature": 0.7
  }'
```

#### WebSocket Connection

```javascript
const ws = new WebSocket('wss://rosetta.semaphor.dk/qwen/ws/');

ws.onopen = function(event) {
    console.log('Connected to chat');
};

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('AI Response:', data.content);
};

// Send a message
ws.send(JSON.stringify({
    messages: [{"role": "user", "content": "Hello!"}],
    stream: true
}));
```

#### Model Management

```bash
# Get current model status
curl "https://rosetta.semaphor.dk/qwen-api/status"

# Switch model
curl -X POST "https://rosetta.semaphor.dk/qwen-api/config/model" \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen/Qwen2.5-3B-Instruct"}'
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_NAME` | `Qwen/Qwen2.5-0.5B-Instruct` | Default model to load |
| `MAX_MEMORY_GB` | `8` | Maximum memory usage in GB |
| `DEVICE` | `cpu` | Device type: `cpu` or `cuda` |
| `HOST` | `0.0.0.0` | Server host |
| `PORT` | `8000` | Backend port |

### Model Configuration

Models are configured in `model_config.json`:

```json
{
  "model": "Qwen/Qwen2.5-0.5B-Instruct"
}
```

### Nginx Configuration

The system includes production-ready Nginx configuration:

- **Frontend**: `https://rosetta.semaphor.dk/qwen/` → `http://localhost:3001`
- **API**: `https://rosetta.semaphor.dk/qwen-api/` → `http://localhost:8004`
- **WebSocket**: `wss://rosetta.semaphor.dk/qwen/ws/` → `ws://localhost:8004/ws`
- **Health**: `https://rosetta.semaphor.dk/qwen/health` → `http://localhost:8004/health`

## 🔧 Development

### Local Development

1. **Backend Development**:
   ```bash
   cd backend
   pip install -r requirements.txt
   python app.py
   ```

2. **Frontend Development**:
   ```bash
   python simple-server.py
   # Access at http://localhost:3000
   ```

3. **Full Stack Development**:
   ```bash
   docker-compose up --build
   ```

### Code Structure

```
newqwen-chat/
├── backend/
│   ├── app.py              # FastAPI backend
│   └── requirements.txt    # Python dependencies
├── docker-compose.yml      # Docker Compose configuration
├── docker-compose.override.yml  # Local overrides
├── Dockerfile             # Multi-stage Docker build
├── simple-server.py       # Frontend server
├── simple-frontend.html   # Web interface
├── model_config.json      # Model configuration
├── start-docker.sh        # Startup script
└── README.md             # This file
```

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/status` | System status |
| `POST` | `/chat` | Send chat message |
| `POST` | `/config/model` | Switch model |
| `GET` | `/docs` | API documentation |
| `WebSocket` | `/ws` | Real-time chat |

## 🐳 Docker Deployment

### Multi-Stage Build

The Dockerfile uses a multi-stage build for optimization:

1. **Base Stage**: Python 3.11 slim with system dependencies
2. **Torch CUDA Stage**: PyTorch with CUDA support
3. **Torch CPU Stage**: PyTorch CPU-only version
4. **Main Stage**: Application with CPU-optimized PyTorch

### Container Features

- **Non-root User**: Runs as `qwen` user for security
- **Health Checks**: Built-in health monitoring
- **Volume Mounts**: Persistent model cache and logs
- **Resource Limits**: Configurable memory and CPU limits

### Volume Mounts

```yaml
volumes:
  - qwen_model_cache:/app/model_cache      # Model cache
  - qwen_offload_cache:/app/offload_cache  # Model offload cache
  - qwen_logs:/app/logs                    # Application logs
  - ./model_config.json:/app/model_config.json  # Model config
```

## 🔍 Monitoring and Logs

### Health Monitoring

- **Health Endpoint**: `/health` - Basic health check
- **Status Endpoint**: `/status` - Detailed system status
- **Docker Health**: Built-in Docker health checks

### Logging

Logs are available in multiple locations:

- **Container Logs**: `docker-compose logs qwen-chat`
- **Application Logs**: `/app/logs/` (mounted volume)
- **Nginx Logs**: `/var/log/nginx/`

### Performance Monitoring

The system provides detailed performance metrics:

- Model loading time
- Memory usage
- Response generation time
- WebSocket connection status

## 🚨 Troubleshooting

### Common Issues

1. **Model Loading Fails**:
   - Check available memory (8GB+ for 0.5B model)
   - Verify model name in `model_config.json`
   - Check device configuration (`DEVICE=cpu` or `DEVICE=cuda`)

2. **Permission Denied**:
   - Ensure `model_config.json` is writable
   - Check file permissions: `chmod 666 model_config.json`

3. **WebSocket Connection Issues**:
   - Verify Nginx WebSocket configuration
   - Check firewall settings
   - Ensure proper SSL/TLS configuration

4. **Memory Issues**:
   - Reduce model size (use 0.5B instead of 3B)
   - Increase container memory limits
   - Enable model offloading

### Debug Commands

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs qwen-chat

# Check resource usage
docker stats

# Test API endpoints
curl http://localhost:8004/health
curl http://localhost:8004/status

# Check Nginx configuration
nginx -t
systemctl reload nginx
```

## 🔒 Security Considerations

### Production Security

- **HTTPS Only**: All traffic encrypted with SSL/TLS
- **CORS Configuration**: Properly configured cross-origin policies
- **Input Validation**: All inputs validated and sanitized
- **Rate Limiting**: Consider implementing rate limiting for production
- **Authentication**: Add authentication for production use

### Container Security

- **Non-root User**: Container runs as non-root user
- **Minimal Base Image**: Uses slim Python image
- **No Secrets in Code**: Environment variables for sensitive data
- **Regular Updates**: Keep base images updated

## 📈 Performance Optimization

### Memory Optimization

- **Model Quantization**: Use quantized models for lower memory usage
- **Model Offloading**: Offload unused models to disk
- **Batch Processing**: Process multiple requests efficiently
- **Memory Monitoring**: Track memory usage and optimize accordingly

### Speed Optimization

- **Model Caching**: Keep frequently used models in memory
- **Response Streaming**: Stream responses for better user experience
- **Connection Pooling**: Reuse database connections
- **CDN Integration**: Use CDN for static assets

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style

- Follow PEP 8 for Python code
- Use meaningful variable names
- Add docstrings to functions
- Include type hints where appropriate

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Alibaba Cloud**: For the Qwen language models
- **Hugging Face**: For the Transformers library
- **FastAPI**: For the excellent web framework
- **Docker**: For containerization support

## 📞 Support

For support and questions:

- **Issues**: Create an issue in the repository
- **Documentation**: Check this README and inline code comments
- **Logs**: Check container and application logs for error details

---

**Happy Chatting! 🤖💬**