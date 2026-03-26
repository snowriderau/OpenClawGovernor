# Features Map

This template ships with a set of reference features demonstrating the OpenClaw Governor architecture. All checkboxes start unchecked — Governor configures everything for your installation.

## Core Components

### Local Inference Server ([spec](./specs/FEAT-LOCAL_INFERENCE.md))
- [ ] Running on port 1234 (OpenAI-compatible API)
- [ ] GPU inference configured (see spec for GPU options)
- [ ] Models downloaded to {{MODEL_DIR}}
- [ ] systemd user service (`local-inference.service`) — active + enabled
- [ ] Headless / CLI mode configured (no display required)
- [ ] CLI installed and available on PATH

### Openclaw Agent ([spec](./specs/FEAT-OPENCLAW_setup.md))
- [ ] Installed at `~/.openclaw/`, binary available on PATH
- [ ] Config validated (valid JSON, no syntax errors)
- [ ] Eight agents configured per AGENT_REGISTRY: Atlas, Conductor, Forge, Hermes, Bolt, Scout, Courier, Sentinel
- [ ] Notification channel configured (groupPolicy: allowlist, only Atlas has message tool)
- [ ] Web search provider connected
- [ ] Local inference connected ({{LOCAL_MODEL}})
- [ ] systemd user service (`openclaw-gateway.service`) — active + enabled
- [ ] loginctl linger enabled (starts at boot without login)
- [ ] Sudoers rules installed (`/etc/sudoers.d/openclaw-agent`)
- [ ] `tools.elevated.allowFrom` consolidated at global level
- [ ] Workspace files populated: USER.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, TASKS.md, OPS.md
- [ ] Memory backend installed and seeded
- [ ] Heartbeat: Atlas 30m → notification channel (delegation-first), Conductor 60m → internal
- [ ] Security audit: denyCommands configured, exec approvals set appropriately
- [ ] Inter-agent dispatch routing configured (see AGENT_REGISTRY.md)
- [ ] Browser: headless mode enabled
- [ ] Skills enabled: coding-agent, github, gh-issues, session-logs, healthcheck
- [ ] GitHub CLI installed and authenticated
- [ ] Dead model fallbacks cleaned (remove any unauthenticated provider references)

### NemoClaw Enterprise Security ([spec](./specs/FEAT-NEMOCLAW_setup.md)) — Optional
- [ ] NemoClaw installed (OpenClaw + NVIDIA OpenShell + Privacy Router)
- [ ] OpenShell runtime installed
- [ ] First sandbox created and verified
- [ ] Network policy applied (default-deny + required egress whitelisted)
- [ ] Privacy Router configured (PII/code/financial → local Nemotron, non-sensitive → cloud)
- [ ] Inference credentials stored in gateway (not visible to agents)
- [ ] Audit logging verified
- [ ] Governor can create/destroy/manage sandboxes via SSH
- [ ] Per-agent sandbox policies written (domain-locked egress per agent role)

### Remote Access
- [ ] Tailscale active on server ({{TAILSCALE_IP}})
- [ ] Client machine connected to Tailscale
- [ ] SSH config entries: `ssh {{HOSTNAME}}` (Tailscale) / `ssh {{HOSTNAME}}-lan` (LAN)
- [ ] SSH key auth configured for any secondary machines (e.g. NAS)

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
- [ ] HTTP status endpoint

### Backup ([spec](./specs/backup_setup.md))
- [ ] NAS or external storage destination configured
- [ ] rsync jobs scheduled: `~/.openclaw/`, inference server configs, `/etc/`
- [ ] At least one successful test backup completed
- [ ] Restore procedure tested

---

## Agent Fleet Management

### Agent Improvement & Optimization
- **Owner:** Governor
- **Command:** `/agent-improvement`
- **Status:** Active — continuous improvement cycle

The Governor's most frequent operational task. Covers the full lifecycle of keeping agents effective:

- [ ] Tool gap analysis — agents missing tools they need, or using tools that don't exist in their runtime
- [ ] Permission and spawn rule verification — can each agent reach who it needs to?
- [ ] Workspace file quality — IDENTITY.md, TOOLS.md, SOUL.md populated with real environment data (not templates)
- [ ] Model optimization — right model for the workload (local for simple/sensitive, cloud for reasoning)
- [ ] Heartbeat configuration — producing useful output, not just HEARTBEAT_OK
- [ ] Escalation chain verification — end-to-end message path works (agent → Atlas → notification channel)
- [ ] Context rot detection — agents accumulating cross-domain knowledge they shouldn't have
- [ ] New agent recommendations — "you're doing X manually, an agent could handle this"
- [ ] Weekly audit schedule established
- [ ] Lessons captured in CLAUDE.md self-correction table after each cycle

The self-correction loop is the key: every time an agent fails or underperforms, the Governor fixes it AND writes a rule so it doesn't happen again. The system gets smarter with every failure.

See `docs/workspace-examples/` for battle-tested workspace file templates based on a real production deployment.

---

## Security & Maintenance

### Priority 1: Core Security Hygiene
- [ ] Initial system audit baseline
- [ ] Automated vulnerability scanning
- [ ] Regular patch assessment
- [ ] Critical CVE alerting
- [ ] Basic access control audit

## Priority 2: Maintenance Automation
- [ ] Weekly security check workflow (cron: weekly)
- [ ] Patch staging and testing
- [ ] Configuration compliance checking
- [ ] Log analysis and reporting
- [ ] Incident playbook execution

## Priority 3: Hardening & Best Practices
- [ ] CIS Benchmark alignment
- [ ] Firewall rule management
- [ ] SSH hardening
- [ ] Service auditing
- [ ] Permission auditing

## Priority 4: Monitoring & Response
- [ ] Real-time log monitoring
- [ ] Anomaly detection
- [ ] Alert aggregation
- [ ] Incident tracking
- [ ] Evidence preservation

## Priority 5: Compliance & Documentation
- [ ] Audit trail maintenance
- [ ] Policy documentation
- [ ] Remediation tracking
- [ ] Compliance reports
- [ ] Decision logging

---

## Feature Specifications

### Vulnerability Scanning
**Status:** Spec TBD
**Owner:** Governor (Claude Code) or designated security agent
**Triggers:** Weekly, or on-demand
**Inputs:** Installed packages, OS version
**Outputs:** Vulnerability report with severity

### Patch Management
**Status:** Spec TBD
**Owner:** Governor (with agent execution)
**Triggers:** Weekly check, on-demand
**Inputs:** Available updates
**Outputs:** Patch recommendations, approval workflow

### Access Control Audit
**Status:** Spec TBD
**Owner:** Governor
**Triggers:** Weekly
**Inputs:** /etc/passwd, /etc/sudoers
**Outputs:** Access audit report

### Log Monitoring
**Status:** Spec TBD
**Owner:** Governor
**Triggers:** Continuous/daily
**Inputs:** System logs
**Outputs:** Alerts, anomaly reports

### Incident Response
**Status:** Spec TBD
**Owner:** Governor (with user notification for decisions requiring human judgment)
**Triggers:** Automated alert or user-initiated
**Inputs:** Security event details
**Outputs:** Incident log, remediation steps
