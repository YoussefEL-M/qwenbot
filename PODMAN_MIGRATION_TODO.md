# Podman Migration Todo List

## Overview
Migration from Docker to Podman for the Qwen Chat System, addressing build context issues and ensuring full compatibility.

## Tasks

### 1. Create Podman-specific docker-compose.yml
- [ ] Create `docker-compose.podman.yml` with proper device mapping
- [ ] Configure volume mounts for Podman compatibility
- [ ] Update GPU device mapping for Podman (`/dev/nvidia0` etc.)
- [ ] Test volume persistence with Podman

### 2. Update Dockerfile for Podman compatibility
- [ ] Remove Docker-specific optimizations
- [ ] Ensure multi-stage builds work with Podman
- [ ] Test build process with Podman
- [ ] Verify security context and user permissions

### 3. Create start-podman.sh script
- [ ] Create Podman-specific startup script
- [ ] Implement Podman compose detection (`podman-compose` vs `podman compose`)
- [ ] Add Podman-specific error handling
- [ ] Include GPU support detection for Podman

### 4. Test GPU support with Podman
- [ ] Install and configure nvidia-container-toolkit for Podman
- [ ] Test GPU device mapping in containers
- [ ] Verify CUDA functionality with Podman
- [ ] Test memory allocation and GPU monitoring

### 5. Update health checks and logging
- [ ] Modify health check commands for Podman
- [ ] Update logging configuration for Podman
- [ ] Test log rotation with Podman
- [ ] Ensure proper log file permissions

### 6. Create Podman-specific documentation
- [ ] Write Podman installation guide
- [ ] Create troubleshooting section for Podman
- [ ] Document Podman-specific commands
- [ ] Add Podman vs Docker comparison

### 7. Test model switching functionality
- [ ] Verify dynamic model loading with Podman
- [ ] Test model unloading and memory cleanup
- [ ] Ensure model cache persistence
- [ ] Test model switching via API and web interface

### 8. Optimize build context size
- [ ] **CRITICAL**: Address 60GB+ build context issue
- [ ] Create `.dockerignore` to exclude model cache
- [ ] Implement model download in container startup
- [ ] Test build time improvements
- [ ] Verify model cache mounting works correctly

## Priority Order
1. **Task 8** (Build context optimization) - Most critical for usability
2. **Task 1** (Podman compose config) - Core functionality
3. **Task 3** (Startup script) - User experience
4. **Task 4** (GPU support) - Performance
5. **Tasks 2, 5, 6, 7** - Polish and testing

## Notes
- Current build context is 60GB+ due to model cache inclusion
- Podman has different device mapping requirements than Docker
- Need to test both `podman-compose` and `podman compose` commands
- GPU support requires nvidia-container-toolkit installation
- Model switching is critical feature that must work with Podman

## Success Criteria
- [ ] Build context under 1GB
- [ ] All Docker functionality works with Podman
- [ ] GPU acceleration works with Podman
- [ ] Model switching works seamlessly
- [ ] Complete documentation for Podman usage