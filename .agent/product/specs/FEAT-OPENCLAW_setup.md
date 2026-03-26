# OpenClaw Governor — Agent System Setup

## Overview
**Title:** OpenClaw Agent System
**Author:** Claude / System Owner
**Status:** Template
**Last Updated:** 2026-03-26

## What Is OpenClaw Governor

OpenClaw Governor is an autonomous AI agent system that manages a Linux server. It is the primary operator, running tasks, using tools, and orchestrating workflows. It interfaces with a local inference server for on-device AI and various cloud providers as fallback.

## Environment

### Install
- **Config dir:** `~/.openclaw/`
- **Main config:** `~/.openclaw/openclaw.json`
- **Memory:** `~/.openclaw/memory/` (SQLite)
- **Sessions:** `~/.openclaw/agents/*/sessions/`
- **Workspace:** `~/.openclaw/workspace/`
- **Completion scripts:** `~/.openclaw/completions/`

### Agents Configuration

OpenClaw supports multiple agents with different roles and models. Configure agents in `openclaw.json`.

**Primary agent ({{AGENT_MAIN}}):**
- Primary model: `{{PRIMARY_MODEL}}`
- Fallbacks: `{{LOCAL_MODEL}}`, additional cloud models as needed
- Tools: coding profile + browser, canvas, message, gateway, nodes, agents_list, tts
- Workspace: `~/.openclaw/workspace/workspaces/{{AGENT_MAIN}}`

**Worker agent ({{AGENT_WORKER}}):**
- Model: `{{LOCAL_MODEL}}` (local inference server)
- Workspace: `~/.openclaw/workspace/workspaces/{{AGENT_WORKER}}`

**Researcher agent ({{AGENT_RESEARCHER}}):**
- Model: cloud model with web access
- Tools: browser, web search
- Workspace: `~/.openclaw/workspace/workspaces/{{AGENT_RESEARCHER}}`

### Example Agent Definitions

| Agent Name | Role | Model | Notes |
|---|---|---|---|
| ops-commander | Primary orchestrator | {{PRIMARY_MODEL}} | Delegates to other agents |
| gpu-runner | Local inference worker | {{LOCAL_MODEL}} | Uses local GPU |
| web-scout | Research & web tasks | Cloud model | Browser + search tools |
| sec-sentinel | Security auditor | Cloud model | Security scanning workflows |
| deploy-chief | Deployment manager | {{PRIMARY_MODEL}} | Docker + service management |
| alert-relay | Notification handler | Lightweight model | Telegram/Discord/Slack integration |
| log-parser | Log analysis agent | {{LOCAL_MODEL}} | Parses and summarizes logs |

### Infrastructure
- **Gateway port:** `{{GATEWAY_PORT}}` (loopback)
- **Gateway auth:** token-based (`{{GATEWAY_AUTH_TOKEN}}`)
- **Remote access:** configured via VPN/Tailscale as needed
- **Notification bot:** configured ({{TELEGRAM_BOT}} or equivalent)
- **Web heartbeat:** 1 second
- **Memory backend:** QMD paths at `{{MODEL_DIR}}/memory`

### Providers
- **Local inference:** `http://127.0.0.1:{{INFERENCE_PORT}}/v1` (OpenAI-compatible)
- **Cloud provider:** OAuth or API key, model `{{PRIMARY_MODEL}}`
- **Web search:** Brave API or equivalent

### Plugins
- `telegram` — enabled (or your notification channel)
- `acpx` — enabled

## Problem

OpenClaw needs to run as a persistent daemon that:
- Auto-starts when the machine boots
- Restarts if it crashes
- Has appropriate system permissions to manage its own environment
- Can be monitored and restarted remotely

## Goals

1. OpenClaw runs as a persistent systemd service
2. Auto-restarts on crash
3. Has passwordless sudo for safe system operations
4. Health check monitors OpenClaw gateway (`:{{GATEWAY_PORT}}`)
5. Local inference server starts before OpenClaw

## Permissions Required

The `{{USERNAME}}` user (OpenClaw runs as this user) needs passwordless sudo for:

```bash
# /etc/sudoers.d/openclaw-agent
{{USERNAME}} ALL=(ALL) NOPASSWD: /bin/systemctl start *
{{USERNAME}} ALL=(ALL) NOPASSWD: /bin/systemctl stop *
{{USERNAME}} ALL=(ALL) NOPASSWD: /bin/systemctl restart *
{{USERNAME}} ALL=(ALL) NOPASSWD: /bin/systemctl status *
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/apt update
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/apt upgrade -y
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/apt install -y *
{{USERNAME}} ALL=(ALL) NOPASSWD: /sbin/reboot
{{USERNAME}} ALL=(ALL) NOPASSWD: /sbin/shutdown
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/journalctl *
```

## Design: systemd Service

```ini
[Unit]
Description=OpenClaw Autonomous AI Agent
After=network-online.target local-inference.service
Wants=local-inference.service
Requires=network-online.target

[Service]
Type=simple
User={{USERNAME}}
Group={{USERNAME}}
Environment=HOME=/home/{{USERNAME}}
WorkingDirectory=/home/{{USERNAME}}/.openclaw/workspace
ExecStart=<OPENCLAW_BINARY> --agent {{AGENT_MAIN}}
Restart=always
RestartSec=15
StartLimitIntervalSec=180
StartLimitBurst=5
StandardOutput=append:/var/log/openclaw/agent.log
StandardError=append:/var/log/openclaw/agent-error.log
TimeoutStopSec=30
KillMode=process

[Install]
WantedBy=multi-user.target
```

## Health Check

Check gateway port:
```bash
curl -sf http://127.0.0.1:{{GATEWAY_PORT}}/health > /dev/null && echo "UP" || echo "DOWN"
```

Or check process:
```bash
pgrep -f 'openclaw' > /dev/null && echo "UP" || echo "DOWN"
```

## Implementation Tasks

- [ ] Confirm OpenClaw binary path and launch command
- [ ] Create `/etc/systemd/system/openclaw.service`
- [ ] Create `/etc/sudoers.d/openclaw-agent` with passwordless rules
- [ ] `sudo systemctl enable openclaw`
- [ ] `sudo systemctl start openclaw`
- [ ] Verify gateway responds on `:{{GATEWAY_PORT}}`
- [ ] Add to health check script

## Acceptance Criteria

- [ ] `systemctl status openclaw` shows active
- [ ] Gateway accessible at `http://127.0.0.1:{{GATEWAY_PORT}}`
- [ ] Survives kill + auto-restarts
- [ ] Starts after local inference server on boot
- [ ] Logs written to `/var/log/openclaw/agent.log`
- [ ] Sudoers rules in place and working

## Remote Access

Configure VPN or Tailscale for remote management. OpenClaw can be reached or managed via:
- SSH: `ssh {{USERNAME}}@{{TAILSCALE_IP}}`
- Gateway: `http://{{TAILSCALE_IP}}:{{GATEWAY_PORT}}` (if bind changed from loopback)
