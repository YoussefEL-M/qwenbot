# Multi-stage Dockerfile for Qwen Chat System
# Optimized for both CPU and GPU usage with Podman compatibility

# Stage 1: Base Python environment
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: PyTorch with CUDA support
FROM base as torch-cuda

# Install PyTorch with CUDA support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Stage 3: CPU-only PyTorch
FROM base as torch-cpu

# Install PyTorch CPU-only version
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Stage 4: Main application
FROM torch-cpu as main

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY backend/requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install additional dependencies for model handling
RUN pip install --no-cache-dir \
    huggingface-hub \
    datasets \
    accelerate

# Create necessary directories
RUN mkdir -p /app/model_cache /app/offload_cache /app/logs

# Copy application files
COPY backend/app.py /app/
COPY simple-server.py /app/
COPY simple-frontend.html /app/
COPY model_config.json /app/
COPY *.js /app/
COPY *.css /app/

# Create non-root user for security
RUN useradd -m -u 1000 qwen

# Copy entrypoint script
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh && \
    chown qwen:qwen /app/docker-entrypoint.sh

# Change ownership of all files
RUN chown -R qwen:qwen /app
USER qwen

# Expose ports
EXPOSE 8000 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command - start both services
CMD ["/bin/bash", "-c", "cd /app && python app.py & python simple-server.py & wait"]