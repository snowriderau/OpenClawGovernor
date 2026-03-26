# Docker Host Setup

## Overview
**Title:** Docker Container Host
**Author:** Claude
**Status:** Template
**Last Updated:** 2026-03-26

## Problem
Need a container runtime to host and manage projects built on the server. Docker must be configured so that the service user can access it and storage is directed to a drive with sufficient capacity.

## Goals
1. `{{USERNAME}}` user can run docker commands without sudo
2. Docker data root moved to `{{MODEL_DIR}}/docker-data`
3. Docker Compose works for multi-container projects
4. OpenClaw agents can manage containers

## Implementation Plan

### 1. Add user to docker group
```bash
sudo usermod -aG docker {{USERNAME}}
```
User needs to re-login or `newgrp docker` for it to take effect.

### 2. Configure daemon.json

Create `/etc/docker/daemon.json`:
```json
{
  "data-root": "{{MODEL_DIR}}/docker-data",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {"base": "172.17.0.0/16", "size": 24}
  ]
}
```

### 3. Apply configuration — stop Docker, set new root, restart
```bash
sudo systemctl stop docker
sudo systemctl start docker
# Docker creates fresh state at new data-root automatically
```
No migration needed for a clean slate setup.

### 4. Verify
```bash
# Confirm user can run docker without sudo
docker run hello-world

# Confirm data root is on the correct drive
docker info | grep "Docker Root Dir"
# Expected output: Docker Root Dir: {{MODEL_DIR}}/docker-data

# Confirm Compose is available
docker compose version
```

### 5. Add Docker tools to OpenClaw agents
- Add docker/compose to agent tool awareness (deploy-chief, ops-commander)
- Update sudoers if needed for container management

## Acceptance Criteria
- [ ] `{{USERNAME}}` in docker group, can run docker without sudo
- [ ] Docker data root at `{{MODEL_DIR}}/docker-data`
- [ ] `docker run hello-world` works
- [ ] `docker compose version` works
- [ ] Log rotation configured (10MB, 3 files)
- [ ] OpenClaw agents aware of Docker capability

## Rollback Plan
- Revert daemon.json (delete it, Docker uses defaults)
- Move data back: `rsync -aP {{MODEL_DIR}}/docker-data/ /var/lib/docker/`
- Restart Docker: `sudo systemctl restart docker`
