# Qwen Chat System - Docker/Podman Setup

This document explains how to run the Qwen Chat System using Docker or Podman containers.

## Prerequisites

- Docker or Podman installed
- At least 8GB RAM (16GB recommended)
- 20GB+ free disk space for model cache
- NVIDIA GPU with CUDA support (optional, for GPU acceleration)

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo>
cd newqwen-chat
cp .env.example .env
# Edit .env file if needed
```

### 2. Build and Run

```bash
# Using Docker Compose (recommended)
docker-compose up -d

# Or using Podman Compose
podman-compose up -d
```

### 3. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Health Check**: http://localhost:8000/health

## Configuration

### Environment Variables

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Key variables:
- `MODEL_NAME`: Hugging Face model name (default: Qwen/Qwen2.5-0.5B-Instruct)
- `MAX_MEMORY_GB`: Maximum GPU memory to use (default: 12)
- `DEVICE`: Device to use (auto/cpu/cuda)

### Model Configuration

The system supports multiple models. Change the model by:

1. **Via Web Interface**: Use the model selection in the chat interface
2. **Via Environment**: Set `MODEL_NAME` in `.env` file
3. **Via API**: POST to `/config/model` endpoint

Supported models:
- `Qwen/Qwen2.5-0.5B-Instruct` (fastest, lowest quality)
- `Qwen/Qwen2.5-3B-Instruct` (balanced)
- `Qwen/Qwen2.5-7B-Instruct` (higher quality)
- `AI-Sweden-Models/gpt-sw3-6.7b-v2-instruct` (multilingual)

## GPU Support

### Docker with NVIDIA GPU

1. Install NVIDIA Container Toolkit:
```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

2. Uncomment GPU configuration in `docker-compose.yml`:
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

### Podman with NVIDIA GPU

1. Install NVIDIA Container Toolkit for Podman
2. Uncomment GPU configuration in `docker-compose.yml`:
```yaml
devices:
  - /dev/nvidia0:/dev/nvidia0
  - /dev/nvidiactl:/dev/nvidiactl
  - /dev/nvidia-uvm:/dev/nvidia-uvm
```

## Management Commands

### Container Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f qwen-chat

# Check status
docker-compose ps
```

### Inside Container

```bash
# Access container shell
docker-compose exec qwen-chat bash

# Check service status
docker-compose exec qwen-chat /app/docker-entrypoint.sh status

# View logs
docker-compose exec qwen-chat /app/docker-entrypoint.sh logs

# Restart services inside container
docker-compose exec qwen-chat /app/docker-entrypoint.sh restart
```

## Volumes and Data Persistence

The system uses named volumes for data persistence:

- `qwen_model_cache`: Downloaded models (20GB+)
- `qwen_offload_cache`: Model offloading cache
- `qwen_logs`: Application logs

### Backup Model Cache

```bash
# Backup model cache
docker run --rm -v qwen_model_cache:/data -v $(pwd):/backup alpine tar czf /backup/model_cache_backup.tar.gz -C /data .

# Restore model cache
docker run --rm -v qwen_model_cache:/data -v $(pwd):/backup alpine tar xzf /backup/model_cache_backup.tar.gz -C /data
```

## Troubleshooting

### Common Issues

1. **Out of Memory Error**
   - Reduce `MAX_MEMORY_GB` in `.env`
   - Use a smaller model
   - Increase system RAM

2. **Model Download Fails**
   - Check internet connection
   - Verify Hugging Face access
   - Check disk space

3. **GPU Not Detected**
   - Verify NVIDIA drivers are installed
   - Check Docker/Podman GPU support
   - Use CPU-only version: `DEVICE=cpu`

4. **Port Already in Use**
   - Change ports in `docker-compose.yml`
   - Kill existing processes: `lsof -ti :8000 | xargs kill -9`

### Debugging

```bash
# Check container logs
docker-compose logs qwen-chat

# Check container status
docker-compose ps

# Access container shell
docker-compose exec qwen-chat bash

# Check health endpoint
curl http://localhost:8000/health

# Monitor resource usage
docker stats qwen-chat
```

### Performance Tuning

1. **For CPU-only systems**:
   - Use `DEVICE=cpu` in `.env`
   - Use smaller models
   - Increase `MAX_MEMORY_GB` for better performance

2. **For GPU systems**:
   - Use `DEVICE=auto` or `DEVICE=cuda`
   - Use larger models for better quality
   - Monitor GPU memory usage

## Development

### Building from Source

```bash
# Build image
docker-compose build

# Build with no cache
docker-compose build --no-cache

# Build specific target (CPU-only)
docker-compose build --target torch-cpu
```

### Custom Configuration

1. **Custom Model**: Edit `model_config.json`
2. **Custom Frontend**: Modify `simple-frontend.html`
3. **Custom Backend**: Modify `backend/app.py`

## Security Considerations

1. **Network Security**: The application binds to all interfaces (0.0.0.0)
2. **File Permissions**: Container runs as non-root user
3. **Resource Limits**: Set appropriate memory limits
4. **API Security**: Consider adding authentication for production use

## Production Deployment

For production deployment:

1. Use a reverse proxy (nginx/traefik)
2. Enable HTTPS/TLS
3. Set up monitoring and logging
4. Configure backup strategies
5. Use secrets management for sensitive data
6. Set up health checks and auto-restart

## Support

- Check logs: `docker-compose logs -f`
- Health check: `curl http://localhost:8000/health`
- Model info: `curl http://localhost:8000/health | jq`
- GitHub Issues: [Your repository issues]