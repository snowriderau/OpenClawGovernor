# TOOLS.md — Bolt (Compute Worker)

## My Tools

### File Operations
- **read** — Read files on disk
- **write** — Create or overwrite files
- **edit** — Edit files in place
- **glob** — Find files by pattern
- **grep** — Search file contents

### Execution
- **exec** — Run shell commands (bash)
- **process** — List, inspect, manage running processes

> **Workers do NOT have `sessions_spawn` or `message` tools.**
> Bolt cannot dispatch sub-agents and cannot send notifications.
> Results are returned to the caller — complete the task and return a clear response.

---

## System Knowledge

### Machine
- **OS:** {{DISTRO}} — kernel {{KERNEL_VERSION}}
- **CPU:** {{CPU}}
- **GPU:** {{GPU}} — {{VRAM}} VRAM — driver {{GPU_DRIVER}}
- **RAM:** {{RAM}}

### Key Paths
- **Data / projects:** `{{PROJECTS_DIR}}/`
- **Openclaw workspace:** `~/.openclaw/workspace/`
- **Openclaw config:** `~/.openclaw/`
- **System logs:** `/var/log/`
- **User services:** `~/.config/systemd/user/`
- **NAS SSH key:** `~/.ssh/{{NAS_SSH_KEY}}`

### Network
- **LAN IP:** `{{MACHINE_IP}}`
- **Tailscale IP:** `{{TAILSCALE_IP}}`
- **NAS:** `{{NAS_HOST}}` — SSH port {{NAS_PORT}}, user `{{NAS_USER}}`

### Services
- **Inference server:** `{{INFERENCE_API}}`
- **Openclaw gateway:** `http://127.0.0.1:{{GATEWAY_PORT}}`

---

## Useful Commands

### GPU & Hardware
```bash
nvidia-smi                                              # GPU status, VRAM, temp
nvidia-smi dmon -s u -d 1 -c 5                         # GPU utilization over 5s
nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader
```

### Disk
```bash
df -h                                                   # Disk usage by mount
du -sh {{PROJECTS_DIR}}/*                               # Size of each project
du -sh ~/.openclaw/                                     # Workspace size
ncdu {{PROJECTS_DIR}}                                   # Interactive disk explorer (if installed)
```

### Memory & CPU
```bash
free -h                                                 # RAM usage
uptime                                                  # Load averages
top -bn1 | head -25                                     # Process snapshot
ps aux --sort=-%mem | head -15                          # Top memory consumers
```

### Services
```bash
systemctl --user status <service>                       # Check service
systemctl --user list-units --state=failed              # Failed services
journalctl --user -u <service> --since '1h ago'        # Recent logs
journalctl --user -u <service> -n 50 --no-pager        # Last 50 lines
```

### Inference Server Health
```bash
curl -sf {{INFERENCE_API}}/models | python3 -m json.tool    # List loaded models
curl -sf {{INFERENCE_API}}/health                           # Health endpoint (if available)
```

### NAS / Storage
```bash
ssh -p {{NAS_PORT}} {{NAS_USER}}@{{NAS_HOST}}              # SSH to NAS
ssh {{NAS_HOST}} df -h                                          # Disk usage on NAS
ssh {{NAS_HOST}} ls -la /{{NAS_VOLUME}}/                        # List NAS volume
ping -c1 {{NAS_HOST}}                                       # Connectivity check
```

### Log Analysis
```bash
journalctl --user --since '2h ago' --no-pager | grep -i error   # Recent errors
tail -f /var/log/syslog                                          # System log
journalctl -k --since '1h ago'                                   # Kernel messages
```

### Network
```bash
ss -tlnp                                                # Listening ports
curl -sf http://127.0.0.1:{{GATEWAY_PORT}}/            # Gateway health
tailscale status                                        # Tailscale peers
```

### File Discovery
```bash
find {{PROJECTS_DIR}} -name '*.log' -newer /tmp -type f    # Recent log files
find ~/.openclaw -name 'config.json' -type f               # Config files
ls -lht {{PROJECTS_DIR}} | head -10                        # Most recently modified
```

---

## Health Check Script (Standard)

When asked for a "system health check", run these in order and summarize:

```bash
# 1. GPU
nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits

# 2. Disk
df -h | grep -E '(Filesystem|/dev/)'

# 3. Memory
free -h | head -3

# 4. Services (adjust list to match your deployment)
for svc in openclaw-gateway lmstudio home-dashboard; do
  systemctl --user is-active $svc 2>/dev/null && echo "$svc: active" || echo "$svc: INACTIVE"
done

# 5. Inference server
curl -sf {{INFERENCE_API}}/models > /dev/null && echo "inference: OK" || echo "inference: UNREACHABLE"
```

Return: GPU temp/VRAM, disk % used per mount, RAM free, service statuses, inference status. Flag anything that looks wrong.
