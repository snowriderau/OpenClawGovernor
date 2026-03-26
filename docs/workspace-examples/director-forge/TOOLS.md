# TOOLS.md — Forge (Senior Engineer)

## Core Tools

### Code & Files
- **read** — Read source files, configs, logs
- **write** — Create new files
- **edit** — Edit files in place (prefer this over full rewrites)
- **exec** — Run shell commands (bash)
- **glob** — Find files by pattern
- **grep** — Search file contents

### Version Control
- **git** — Standard git operations (commit, push, diff, log, branch)
- Commit frequently — small, meaningful commits
- Always commit before major refactors

### Process Management
- **process** — List, inspect, kill processes
- **exec** with systemd commands for service management

### Agent Dispatch

> **Always use `sessions_spawn` for inter-agent dispatch — never the `message` tool.**

```
sessions_spawn(agent: "bolt", message: "Check GPU utilization and confirm inference server is responding at {{INFERENCE_API}}")
```

```
sessions_spawn(agent: "scout", message: "Research the latest stable release of Caddy v2 and summarize the key config changes since v2.6")
```

**Bolt** — Use for: system health, log access, disk checks, anything needing machine exec
**Scout** — Use for: library docs, API references, tool comparisons, any web research

---

## System Knowledge

### Machine
- **OS:** {{DISTRO}} — kernel {{KERNEL_VERSION}}
- **CPU:** {{CPU}}
- **GPU:** {{GPU}} — {{VRAM}} VRAM — driver {{GPU_DRIVER}}
- **RAM:** {{RAM}}
- **Storage:** {{STORAGE_LAYOUT}}

### Key Paths
- Projects: `{{PROJECTS_DIR}}/`
- Openclaw workspace: `~/.openclaw/workspace/`
- Openclaw config: `~/.openclaw/`
- System logs: `/var/log/` (use `journalctl` for systemd)
- User services: `~/.config/systemd/user/`

### Network
- LAN: `{{MACHINE_IP}}` (primary interface)
- Tailscale: `{{TAILSCALE_IP}}` (remote access)
- NAS: `{{NAS_HOST}}` (SSH port {{NAS_PORT}})

### Services Atlas Manages
- Openclaw gateway: `http://127.0.0.1:{{GATEWAY_PORT}}`
- Inference server: `{{INFERENCE_API}}`
- Telegram bot: `{{NOTIFICATION_BOT}}`

---

## Useful Commands

### Service Management
```bash
systemctl --user status <service>                    # Check service
systemctl --user restart <service>                   # Restart
systemctl --user enable <service>                    # Enable at boot
journalctl --user -u <service> -f                    # Follow logs
journalctl --user -u <service> --since '1h ago'      # Recent logs
```

### Docker
```bash
docker ps                                            # Running containers
docker compose up -d                                 # Start stack
docker compose logs -f                               # Follow logs
docker compose down && docker compose up -d          # Restart stack
docker system prune -f                               # Clean up
```

### Process & Port Debugging
```bash
ss -tlnp                                             # Listening ports
ps aux | grep <name>                                 # Find process
lsof -i :{{PORT}}                                    # What's on a port
```

### Git Workflow
```bash
git status && git diff                               # Check state
git add -p                                           # Stage hunks selectively
git commit -m "fix: description of what changed"    # Commit
git log --oneline -10                                # Recent history
```

### Python / FastAPI Projects
```bash
pip install -r requirements.txt                      # Install deps
uvicorn app.main:app --reload --port {{PORT}}        # Dev server
python -m pytest                                     # Run tests
```

---

## Project Conventions

When you build a new project or take over an existing one, follow this structure:

```
project-name/
├── .agent/
│   ├── product/
│   │   ├── specs/FEAT-001_name.md
│   │   └── feature_map.md
│   └── memory/
│       └── active_state.md
├── app/           (or src/)
├── scripts/
├── requirements.txt (or package.json)
├── Dockerfile (if containerized)
└── README.md
```

Every project gets:
1. A spec before code starts
2. A systemd user service (not root)
3. Health check in Sentinel's watchlist
4. Entry in Atlas's TOOLS.md "Apps & Projects" section

---

## Deployment Checklist

When deploying a new service:

```
[ ] Service runs cleanly via command line
[ ] systemd unit file created at ~/.config/systemd/user/<name>.service
[ ] systemctl --user enable <name>.service
[ ] systemctl --user start <name>.service
[ ] Service responds at expected port
[ ] linger enabled (loginctl enable-linger $USER) — survives reboot without login
[ ] Atlas TOOLS.md updated with URL, port, repo path
[ ] Sentinel watchlist updated
```
