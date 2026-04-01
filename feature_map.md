# Features Map

All features and their status. Governor updates this file after every change.

## Core Components

### Local Inference Server ([spec](./specs/FEAT-LOCAL_INFERENCE.md))
- [ ] Running on port {{INFERENCE_PORT}} (OpenAI-compatible API)
- [ ] GPU inference configured (see spec for GPU options)
- [ ] Models downloaded to {{MODEL_DIR}}
- [ ] systemd user service (`local-inference.service`) — active + enabled
- [ ] Headless / CLI mode configured (no display required)
- [ ] CLI installed and available on PATH

### Openclaw Agent ([spec](./specs/FEAT-OPENCLAW_setup.md))
- [ ] Installed at `~/.openclaw/`, binary available on PATH
- [ ] Config validated (valid JSON, no syntax errors)
- [ ] Agent fleet configured — see `fleet.md` for hierarchy and roster
- [ ] Notification channel configured (groupPolicy: allowlist, only {{AGENT_MAIN}} has message tool)
- [ ] Web search provider connected
- [ ] Local inference connected ({{LOCAL_MODEL}})
- [ ] systemd user service (`openclaw-gateway.service`) — active + enabled
- [ ] loginctl linger enabled (starts at boot without login)
- [ ] Sudoers rules installed (`/etc/sudoers.d/openclaw-agent`)
- [ ] `tools.elevated.allowFrom` consolidated at global level
- [ ] Workspace files populated: USER.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, TASKS.md
- [ ] Heartbeat: {{AGENT_MAIN}} 30m → notification channel, PM 60m → internal
- [ ] Fleet-wide heartbeat isolation: `isolatedSession: true` + `lightContext: true`
- [ ] Security: denyCommands configured, exec approvals set appropriately
- [ ] Inter-agent dispatch routing configured — see `fleet.md` spawn permissions
- [ ] Browser: headless mode enabled
- [ ] GitHub CLI installed and authenticated

### heartbeat-guard Plugin ([spec](./specs/FEAT-020_heartbeat_guard/SPEC.md))
- [ ] Plugin installed at `~/.openclaw/plugins/heartbeat-guard/`
- [ ] Registered in openclaw.json plugins.entries
- [ ] Heartbeat tool calls capped at 10 per run
- [ ] Cron tool calls capped at 30 per run
- [ ] User-triggered sessions unlimited (-1)
- [ ] Blocked events logged to `~/.openclaw/logs/heartbeat-guard.log`
- [ ] Gateway restarted and plugin active (`openclaw plugins list`)

### Remote Access
- [ ] Tailscale active on server ({{TAILSCALE_IP}})
- [ ] Client machine connected to Tailscale
- [ ] SSH config entries: `ssh {{HOSTNAME}}` (Tailscale) / `ssh {{HOSTNAME}}-lan` (LAN)

### Docker Host ([spec](./specs/FEAT-DOCKER.md))
- [ ] Docker latest stable + Compose plugin installed
- [ ] {{USERNAME}} in docker group (no sudo needed)
- [ ] Data root configured to storage disk (not OS disk)
- [ ] Log rotation: 10MB, 3 files
- [ ] tmux installed (enables Openclaw tmux skill)

### Watchdog & Fault Tolerance ([spec](./specs/watchdog_setup.md))
- [ ] Openclaw has built-in `Restart=always` in its service
- [ ] Health check script installed
- [ ] systemd timer (5-min checks)

### Backup ([spec](./specs/backup_setup.md))
- [ ] NAS or external storage destination configured
- [ ] rsync jobs scheduled: `~/.openclaw/`, inference server configs, `/etc/`
- [ ] At least one successful test backup completed
- [ ] Restore procedure tested

### Project Management & Spec-Driven Development
- [ ] Projects directory created on target machine (`{{PROJECTS_DIR}}`)
- [ ] Spec-first-starter template deployed to `{{PROJECTS_DIR}}/spec-first-starter/`
- [ ] PM agent configured in openclaw.json with heartbeat (scans projects every 60m)
- [ ] PM agent workspace files personalized: IDENTITY.md, SOUL.md, TOOLS.md, HEARTBEAT.md
- [ ] At least one project initialized with spec-first structure
- [ ] PM agent successfully scans project task queues and dispatches agents

---

## Agent Fleet Management

### Agent Improvement & Optimization
- **Owner:** Governor
- **Command:** `/agent-improvement`
- **Status:** Active — continuous improvement cycle

Key areas:
- [ ] Tool gap analysis — agents missing tools or using tools that don't exist
- [ ] Spawn rule verification — agents reach who they need to
- [ ] Workspace file quality — populated with real environment data (not templates)
- [ ] Model optimization — right model for the workload
- [ ] Heartbeat configuration — producing useful output, not just HEARTBEAT_OK
- [ ] Escalation chain verification — end-to-end message path works
- [ ] Governance audit cron active on PM (every 6h)

See `fleet.md` for hierarchy, spawn rules, and model assignments.
See `docs/workspace-examples/` for battle-tested workspace file templates.
