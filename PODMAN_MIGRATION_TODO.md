# 🐳 Podman Migration Todo List

This document outlines the tasks needed to migrate the Qwen Chat System from Docker to Podman for better security, rootless operation, and systemd integration.

## 📋 Migration Tasks

### 🔧 **1. Podman Installation & Setup**
- [ ] Install Podman on the target system
  ```bash
  # Ubuntu/Debian
  sudo apt update && sudo apt install podman
  
  # CentOS/RHEL/Fedora
  sudo dnf install podman
  
  # Or use the official installation script
  curl -s https://raw.githubusercontent.com/containers/podman/main/install.sh | bash
  ```
- [ ] Install Podman Compose
  ```bash
  # Install podman-compose
  pip install podman-compose
  
  # Or use the standalone binary
  curl -L https://github.com/containers/podman-compose/releases/latest/download/podman-compose-linux-amd64 -o /usr/local/bin/podman-compose
  chmod +x /usr/local/bin/podman-compose
  ```
- [ ] Configure Podman for rootless operation
  ```bash
  # Enable user namespaces
  echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf
  
  # Configure subuid/subgid
  sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER
  ```
- [ ] Test Podman installation
  ```bash
  podman --version
  podman-compose --version
  podman info
  ```

### 🐳 **2. Container Configuration Updates**
- [ ] Update `docker-compose.yml` for Podman compatibility
  - [ ] Remove Docker-specific features
  - [ ] Update volume mounting syntax
  - [ ] Adjust resource limits for Podman
  - [ ] Update health check commands
- [ ] Create `podman-compose.yml` (alternative to modifying existing file)
  - [ ] Copy from `docker-compose.yml`
  - [ ] Update for Podman-specific features
  - [ ] Add Podman-specific configurations
- [ ] Update `Dockerfile` for Podman compatibility
  - [ ] Ensure all commands work with Podman
  - [ ] Test multi-stage builds
  - [ ] Verify user creation and permissions

### 🔄 **3. Script Updates**
- [ ] Update `start-docker.sh` to detect and use Podman
  - [ ] Add Podman detection logic
  - [ ] Update compose command selection
  - [ ] Add Podman-specific error handling
  - [ ] Test all script options with Podman
- [ ] Create `start-podman.sh` (dedicated Podman script)
  - [ ] Optimized for Podman features
  - [ ] Include Podman-specific commands
  - [ ] Add rootless operation support
- [ ] Update `switch-model.sh` for Podman
  - [ ] Test model switching with Podman containers
  - [ ] Update container management commands
- [ ] Update `complete-restart.sh` for Podman
  - [ ] Replace Docker commands with Podman equivalents
  - [ ] Test restart functionality

### 🔐 **4. Security & Permissions**
- [ ] Configure rootless operation
  - [ ] Test running containers as non-root user
  - [ ] Verify file permissions work correctly
  - [ ] Test volume mounting in rootless mode
- [ ] Update volume permissions
  - [ ] Ensure model cache is accessible
  - [ ] Fix log file permissions
  - [ ] Test persistent storage
- [ ] Configure SELinux/AppArmor (if applicable)
  - [ ] Test with security policies enabled
  - [ ] Update policies if needed

### 🚀 **5. GPU Support**
- [ ] Test NVIDIA GPU support with Podman
  - [ ] Install `nvidia-container-toolkit` for Podman
  - [ ] Configure GPU access in rootless mode
  - [ ] Test CUDA functionality
- [ ] Update GPU configuration in compose files
  - [ ] Use Podman-compatible GPU syntax
  - [ ] Test with different GPU configurations
- [ ] Create GPU-specific Podman compose file
  - [ ] Separate configuration for GPU-enabled systems
  - [ ] Include necessary device mappings

### 📊 **6. Monitoring & Logging**
- [ ] Update logging configuration for Podman
  - [ ] Test log collection and rotation
  - [ ] Verify log file permissions
- [ ] Update health check endpoints
  - [ ] Test health checks with Podman
  - [ ] Update monitoring scripts
- [ ] Create Podman-specific monitoring tools
  - [ ] Container status monitoring
  - [ ] Resource usage tracking

### 🧪 **7. Testing & Validation**
- [ ] Test all models with Podman
  - [ ] Qwen 2.5 0.5B, 3B, 7B
  - [ ] Llama 3 8B
  - [ ] Gemma 2 9B
  - [ ] GPT-SW3 6.7B
- [ ] Test model switching functionality
  - [ ] Dynamic model loading
  - [ ] Memory management
  - [ ] Error handling
- [ ] Test WebSocket functionality
  - [ ] Real-time streaming
  - [ ] Connection management
  - [ ] Error recovery
- [ ] Performance testing
  - [ ] Compare performance with Docker
  - [ ] Memory usage analysis
  - [ ] Startup time comparison

### 📚 **8. Documentation Updates**
- [ ] Update README.md with Podman instructions
  - [ ] Add Podman installation guide
  - [ ] Update usage examples
  - [ ] Add troubleshooting section
- [ ] Create Podman-specific documentation
  - [ ] Podman setup guide
  - [ ] Rootless operation guide
  - [ ] GPU configuration guide
- [ ] Update API documentation
  - [ ] Add Podman-specific endpoints
  - [ ] Update management commands

### 🔧 **9. Advanced Features**
- [ ] Systemd integration
  - [ ] Create systemd service files
  - [ ] Enable auto-start on boot
  - [ ] Configure service dependencies
- [ ] Podman pods support
  - [ ] Group related containers
  - [ ] Shared networking
  - [ ] Resource sharing
- [ ] Image management
  - [ ] Build and push images
  - [ ] Image registry integration
  - [ ] Image signing and verification

### 🚨 **10. Error Handling & Recovery**
- [ ] Update error messages for Podman
  - [ ] Podman-specific error detection
  - [ ] Better error reporting
  - [ ] Recovery suggestions
- [ ] Create fallback mechanisms
  - [ ] Docker fallback if Podman fails
  - [ ] Graceful degradation
  - [ ] Automatic recovery
- [ ] Update troubleshooting guide
  - [ ] Common Podman issues
  - [ ] Rootless operation problems
  - [ ] GPU access issues

## 🎯 **Priority Levels**

### **High Priority** (Must Complete)
1. Podman installation and basic setup
2. Container configuration updates
3. Script updates for Podman detection
4. Basic functionality testing

### **Medium Priority** (Should Complete)
1. Security and permissions configuration
2. GPU support testing
3. Model switching functionality
4. Documentation updates

### **Low Priority** (Nice to Have)
1. Advanced features (systemd, pods)
2. Performance optimizations
3. Advanced monitoring
4. Image management

## 🧪 **Testing Checklist**

### **Basic Functionality**
- [ ] Podman installation works
- [ ] Containers start successfully
- [ ] Frontend is accessible
- [ ] Backend API responds
- [ ] Health checks pass

### **Model Operations**
- [ ] Models load correctly
- [ ] Model switching works
- [ ] Memory management functions
- [ ] GPU acceleration works (if available)

### **Advanced Features**
- [ ] WebSocket streaming works
- [ ] File serving works
- [ ] Logging functions correctly
- [ ] Volume persistence works

### **Error Scenarios**
- [ ] Out of memory handling
- [ ] Network connectivity issues
- [ ] Container restart scenarios
- [ ] Model loading failures

## 📝 **Notes**

- **Rootless Operation**: Podman's main advantage is rootless operation, which improves security
- **Compatibility**: Most Docker commands have Podman equivalents
- **Performance**: Podman may have slightly different performance characteristics
- **GPU Support**: Requires additional setup for NVIDIA GPU support
- **Volumes**: Podman handles volumes differently, especially in rootless mode

## 🔗 **Useful Resources**

- [Podman Documentation](https://docs.podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)
- [Rootless Podman Guide](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

---

**Estimated Completion Time**: 2-3 days for basic functionality, 1-2 weeks for full feature parity with Docker.