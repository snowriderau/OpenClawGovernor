---
description: Discover current system state — services, hardware, network, and health
---

# Discovery Workflow

Survey the managed machine to understand its current state, running services, and health.

## Step 1: System Baseline

SSH to the machine and gather basic info:

```bash
ssh {{HOSTNAME}} '
# System info
uname -a && cat /etc/os-release
uptime
df -h
free -h

# Hardware
lscpu | head -20
lspci | grep -i "vga\|3d\|display" 2>/dev/null
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader 2>/dev/null || echo "No NVIDIA GPU detected"
'
```

## Step 2: Service Health

Check configured services are running:

```bash
ssh {{HOSTNAME}} '
# Enabled services
systemctl list-unit-files --type=service --state=enabled | grep -v "^UNIT"

# User services (OpenClaw gateway, etc.)
systemctl --user list-units --type=service --state=running 2>/dev/null

# Open ports
sudo ss -tlnp 2>/dev/null || netstat -tlnp

# Check inference server
curl -s http://127.0.0.1:{{INFERENCE_PORT}}/v1/models 2>/dev/null | head -20 || echo "Inference server not responding on port {{INFERENCE_PORT}}"

# Check OpenClaw gateway
curl -s http://127.0.0.1:{{GATEWAY_PORT}}/health 2>/dev/null || echo "OpenClaw gateway not responding on port {{GATEWAY_PORT}}"
'
```

## Step 3: Network & Connectivity

```bash
ssh {{HOSTNAME}} '
# Network interfaces
ip -br addr

# Tailscale status (if configured)
tailscale status 2>/dev/null || echo "Tailscale not active"

# DNS resolution
host google.com 2>/dev/null | head -1
'
```

## Step 4: Backup & Storage Check

```bash
ssh {{HOSTNAME}} '
# Check NAS/backup mount points
mount | grep -i "nfs\|cifs\|smb\|backup" || echo "No network mounts found"

# Check rsync/backup cron jobs
crontab -l 2>/dev/null | grep -i "rsync\|backup" || echo "No backup cron jobs found"

# Disk usage on key paths
du -sh /home/{{USERNAME}}/ 2>/dev/null
du -sh {{MODEL_DIR}} 2>/dev/null || echo "Model directory not found at {{MODEL_DIR}}"
'
```

## Step 5: Document Findings

1. Write results to `.agent/memory/active_state.md`
2. Update `feature_map.md` if discovery reveals new capabilities or issues
3. Add any urgent items to `.agent/memory/task_queue.md`

---

Target system: $ARGUMENTS
