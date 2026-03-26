# FEAT-OPENCLAW: Openclaw — Autonomous AI Agent

## Overview
**Feature ID:** FEAT-OPENCLAW
**Title:** Openclaw Agent System
**Status:** Draft — configure for your environment
**Last Updated:** YYYY-MM-DD

## What Is Openclaw

Openclaw is the autonomous AI agent runtime that manages your machine. It is the primary operator — running tasks, using tools, and orchestrating workflows across the agent fleet. It interfaces with a local inference server for air-gapped data operations and cloud providers for general reasoning.

The Governor (Claude Code) sits above Openclaw — it monitors, verifies, and improves the agents themselves. Openclaw runs the fleet. The Governor oversees the fleet.

## Environment

### Install
- **Config dir:** `~/.openclaw/`
- **Main config:** `~/.openclaw/openclaw.json`
- **Memory:** `~/.openclaw/memory/` (SQLite)
- **Sessions:** `~/.openclaw/agents/*/sessions/`
- **Workspace:** `~/.openclaw/workspace/`
- **Completion scripts:** `~/.openclaw/completions/`

### Agents Configuration

Reference AGENT_REGISTRY.md for the full fleet definition. Minimum viable setup:

**Atlas (main agent):**
- Primary model: `{{PRIMARY_MODEL}}`
- Fallbacks: `{{LOCAL_MODEL}}`, `{{SECONDARY_MODEL}}`
- Tools: coding profile + browser, canvas, message, gateway, nodes, agents_list, tts
- Workspace: `~/.openclaw/workspace/workspaces/main`

**Bolt (local compute worker):**
- Model: `{{LOCAL_MODEL}}` (local via inference server)
- Workspace: `~/.openclaw/workspace/workspaces/worker`
- Tools: coding profile + process (NO network, NO message, NO spawn)

### Infrastructure
- **Gateway port:** `18789` (loopback by default)
- **Gateway auth:** token-based (generate a secure token)
- **Tailscale:** configure `allowTailscale: true` for remote access
- **Notification bot:** configure channel integration (Telegram, Discord, Slack)
- **Web heartbeat:** 1 second
- **Memory backend:** configure path to persistent storage

### Providers
- **Local inference:** `http://127.0.0.1:{{LOCAL_INFERENCE_PORT}}/v1` (OpenAI-compatible)
- **Cloud primary:** {{CLOUD_PROVIDER}} — configure OAuth/API key
- **Web search:** configure Brave API or alternative search provider

### Plugins
- `telegram` (or notification plugin of choice) — enable for notification channel
- `acpx` — enable for extended tool access

---

## Problem

Openclaw needs to run as a persistent daemon that:
- Auto-starts when the machine boots
- Restarts if it crashes
- Has appropriate system permissions to manage its own environment
- Can be monitored and restarted remotely via Tailscale

---

## Goals

1. Openclaw runs as a persistent systemd service
2. Auto-restarts on crash with backoff limits
3. Dedicated user account with passwordless sudo for autonomous system operations
4. Health check monitors Openclaw gateway (`:18789`)
5. Local inference server starts before Openclaw

---

## Permissions Required

The `{{USERNAME}}` user (Openclaw runs as this user) needs passwordless sudo for autonomous operation:

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

> Note: Adjust package manager commands for your distro (e.g. `dnf`, `pacman`, `zypper`). Governor writes this file — adapt to the target machine's package manager.

---

## Design: systemd Service

```ini
[Unit]
Description=Openclaw Autonomous AI Agent
After=network-online.target local-inference.service
Wants=local-inference.service
Requires=network-online.target

[Service]
Type=simple
User={{USERNAME}}
Group={{USERNAME}}
Environment=HOME=/home/{{USERNAME}}
WorkingDirectory=/home/{{USERNAME}}/.openclaw/workspace
ExecStart=<OPENCLAW_BINARY> --agent main
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

**Note:** Replace `<OPENCLAW_BINARY>` with the actual binary path. Common locations:
- `~/.npm-global/bin/openclaw` (npm global install)
- `/usr/local/bin/openclaw` (system install)

Confirm path with: `which openclaw`

---

## Health Check

Check gateway port:
```bash
curl -sf http://127.0.0.1:18789/health > /dev/null && echo "UP" || echo "DOWN"
```

Or check process:
```bash
pgrep -f 'openclaw' > /dev/null && echo "UP" || echo "DOWN"
```

---

## Known Issues

### Config JSON Corruption
Openclaw will fail to start if `openclaw.json` has invalid JSON. Symptoms: service fails immediately, logs show parse error.

Diagnosis:
```bash
python3 -m json.tool ~/.openclaw/openclaw.json > /dev/null && echo "Valid" || echo "Invalid"
```

Fix: Repair the JSON. Always keep a backup: `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup`

---

## Implementation Tasks

- [ ] Confirm openclaw binary path: `which openclaw`
- [ ] Create `/etc/systemd/system/openclaw.service` (or user service)
- [ ] Create `/etc/sudoers.d/openclaw-agent` with passwordless rules
- [ ] Validate `openclaw.json` (JSON lint before starting service)
- [ ] `sudo systemctl enable openclaw`
- [ ] `sudo systemctl start openclaw`
- [ ] Verify gateway responds on `:18789`
- [ ] Enable loginctl linger: `loginctl enable-linger {{USERNAME}}`
- [ ] Add to health check script

---

## Acceptance Criteria

- [ ] `systemctl status openclaw` shows active
- [ ] Gateway accessible at `http://127.0.0.1:18789`
- [ ] Survives kill + auto-restarts within 30 seconds
- [ ] Starts after local inference server on boot
- [ ] Logs written to `/var/log/openclaw/agent.log`
- [ ] Sudoers rules in place and working
- [ ] loginctl linger enabled (starts at boot without login session)

---

## Remote Access

With Tailscale running on this machine (`{{TAILSCALE_IP}}`), Openclaw can be reached or managed via:
- SSH: `ssh {{USERNAME}}@{{TAILSCALE_IP}}`
- Gateway: `http://{{TAILSCALE_IP}}:18789` (only if gateway bind changed from loopback)

**Security note:** Keep the gateway on loopback (`127.0.0.1`) by default. Use Tailscale for remote access — don't expose the gateway port to the internet.
