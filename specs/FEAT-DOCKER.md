# FEAT-DOCKER: Docker Container Host

## Overview
**Feature ID:** FEAT-DOCKER
**Title:** Docker Container Host
**Author:** Governor (Claude Code)
**Status:** Draft — configure for your environment
**Last Updated:** YYYY-MM-DD

## Problem
Need a container runtime to host and manage projects built on the server. Docker may be installed but not configured correctly — the user may lack group membership and storage may be on the wrong disk (OS disk instead of data disk).

## Current State (pre-setup)
- Docker may or may not be installed
- `{{USERNAME}}` user may not be in docker group (permission denied)
- Default data root: `/var/lib/docker` (OS disk — typically wrong location)
- No `daemon.json` configured
- Data disk (e.g. `{{DATA_DISK_MOUNT}}`) likely has more free space — target for Docker storage

## Goals
1. `{{USERNAME}}` can run docker commands without sudo
2. Docker data root moved to data disk (`{{DOCKER_DATA_DIR}}`)
3. Docker Compose works for multi-container projects
4. Openclaw agents can manage containers (Atlas/Bolt)

---

## Implementation Plan

### 1. Install Docker (if not installed)
```bash
# Official install script (Ubuntu/Debian/Pop!_OS)
curl -fsSL https://get.docker.com | sh

# Or manual:
# https://docs.docker.com/engine/install/ubuntu/
```

### 2. Add user to docker group
```bash
sudo usermod -aG docker {{USERNAME}}
```
User needs to re-login or run `newgrp docker` for group membership to take effect.

### 3. Configure daemon.json
Create `/etc/docker/daemon.json`:
```json
{
  "data-root": "{{DOCKER_DATA_DIR}}",
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

### 4. Fresh start — stop Docker, set new root, restart
```bash
sudo systemctl stop docker
# Optionally move existing data (if any containers exist):
# sudo rsync -aP /var/lib/docker/ {{DOCKER_DATA_DIR}}/
# Or clean slate (recommended for fresh installs):
sudo systemctl start docker
# Docker creates fresh state at new data-root automatically
```

### 5. Verify
```bash
# Test basic functionality (as {{USERNAME}}, no sudo)
docker run --rm hello-world

# Verify data root location
docker info | grep "Docker Root Dir"

# Verify Compose
docker compose version
```

### 6. Add Docker awareness to Openclaw agents
- Update Atlas and Bolt's TOOLS.md with Docker capability reference
- Add docker/compose to sudoers if agents need elevated container ops:
  ```bash
  # /etc/sudoers.d/openclaw-agent (append if needed)
  {{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/docker *
  ```

---

## Acceptance Criteria
- [ ] `{{USERNAME}}` in docker group, can run docker without sudo
- [ ] Docker data root at `{{DOCKER_DATA_DIR}}`
- [ ] `docker run --rm hello-world` works
- [ ] `docker compose version` works
- [ ] Log rotation configured (10MB, 3 files)
- [ ] Openclaw agents aware of Docker capability

---

## Rollback Plan
```bash
# Revert daemon.json
sudo rm /etc/docker/daemon.json

# Move data back (if you moved it)
sudo rsync -aP {{DOCKER_DATA_DIR}}/ /var/lib/docker/

# Restart Docker
sudo systemctl restart docker
```

---

## Notes

- Docker data can grow large quickly. Monitor `{{DOCKER_DATA_DIR}}` disk usage.
- Use `docker system prune` periodically to remove unused images/containers/volumes.
- For agents managing containers: scope their permissions carefully. Bolt (local compute) can manage containers it spawns. Courier (files) should not have docker exec access.
- Compose files for agent-managed projects should live in `{{PROJECT_DIR}}/` alongside project specs.
