# Feature Map

> This document tracks all features, their status, and links to specs.
> Use it as the single source of truth for what is built, in progress, and planned.

## How to Document Features

Each feature entry should follow this format:

```markdown
### Feature Name ([spec](./specs/spec_file.md))
- [x] Completed item — brief description
- [ ] Pending item — what still needs to be done
```

Use `[x]` for completed items and `[ ]` for pending. Group features into sections by domain.

---

## Infrastructure

### Local Inference Server ([spec](./specs/EXAMPLE_local_inference.md))
- [ ] Inference server installed (LM Studio / Ollama / vLLM)
- [ ] GPU driver verified (`nvidia-smi` shows {{GPU_MODEL}})
- [ ] Server running on port {{INFERENCE_PORT}} (OpenAI-compatible API)
- [ ] systemd service enabled and auto-starts on boot
- [ ] At least one model loaded: {{LOCAL_MODEL}}
- [ ] Health check integrated with watchdog

### Docker Host ([spec](./specs/docker_setup.md))
- [ ] Docker + Compose installed
- [ ] {{USERNAME}} in docker group (no sudo needed)
- [ ] Data root configured at {{MODEL_DIR}}/docker-data
- [ ] Log rotation configured (10MB, 3 files)
- [ ] Projects directory created at {{MODEL_DIR}}/projects/

### Backup ([spec](./specs/backup_setup.md))
- [ ] Backup script created and tested
- [ ] Daily rsync to external drive or NAS ({{NAS_IP}})
- [ ] systemd timer enabled for automated daily backups
- [ ] Restore procedure documented and tested
- [ ] Quick config snapshot script available for pre-change captures

---

## Agents

### OpenClaw Governor ([spec](./specs/FEAT-OPENCLAW_setup.md))
- [ ] Installed and configured at `~/.openclaw/`
- [ ] Agent gateway running on port {{GATEWAY_PORT}}
- [ ] systemd service enabled (auto-start on boot)
- [ ] Sudoers rules installed (`/etc/sudoers.d/openclaw-agent`)
- [ ] Local inference provider connected
- [ ] Cloud provider fallback configured
- [ ] Workspace files populated (USER.md, IDENTITY.md, TOOLS.md)

### Agent Registry

Define your agents here. Use professional role-based names.

| Agent | Role | Model | Status |
|---|---|---|---|
| ops-commander | Primary orchestrator, delegates tasks | {{PRIMARY_MODEL}} | [ ] Configured |
| gpu-runner | Local inference worker | {{LOCAL_MODEL}} | [ ] Configured |
| web-scout | Web research and browsing | Cloud model | [ ] Configured |
| sec-sentinel | Security auditing and scanning | Cloud model | [ ] Configured |
| deploy-chief | Docker and deployment management | {{PRIMARY_MODEL}} | [ ] Configured |
| alert-relay | Notification routing | Lightweight model | [ ] Configured |
| log-parser | Log analysis and summarization | {{LOCAL_MODEL}} | [ ] Configured |

### Notification Channel ([spec](./specs/EXAMPLE_notification_channel.md))
- [ ] Notification channel selected (Telegram / Discord / Slack)
- [ ] Bot or webhook created and tested
- [ ] Notification script deployed at `/opt/openclaw/scripts/notify.sh`
- [ ] Health alerts routed to notification channel
- [ ] Agent can send messages programmatically
- [ ] Daily digest delivery configured

---

## Security & Maintenance

### Priority 1: Core Security Hygiene
- [ ] Initial system audit baseline completed
- [ ] Automated vulnerability scanning
- [ ] Regular patch assessment
- [ ] Critical CVE alerting
- [ ] Basic access control audit

### Priority 2: Maintenance Automation
- [ ] Weekly security check workflow (cron or systemd timer)
- [ ] Patch staging and testing
- [ ] Configuration compliance checking
- [ ] Log analysis and reporting
- [ ] Incident playbook execution

### Priority 3: Hardening & Best Practices
- [ ] CIS Benchmark alignment
- [ ] Firewall rule management
- [ ] SSH hardening
- [ ] Service auditing
- [ ] Permission auditing

---

## Monitoring

### Watchdog & Fault Tolerance ([spec](./specs/watchdog_setup.md))
- [ ] All services have `Restart=always` in systemd units
- [ ] Health check script deployed at `/opt/openclaw/scripts/healthcheck.sh`
- [ ] systemd timer running (5-min health checks)
- [ ] HTTP status endpoint available on port 8888
- [ ] Self-heal script deployed and tested
- [ ] Log rotation configured (`/etc/logrotate.d/openclaw`)
- [ ] Alerts file written on failures (`/opt/openclaw/alerts.txt`)

### Remote Access
- [ ] VPN or Tailscale configured for remote management
- [ ] SSH access verified from remote machine
- [ ] Health endpoint accessible remotely

---

## Feature Specifications (Planned)

### Vulnerability Scanning
**Status:** Spec TBD
**Owner:** sec-sentinel agent
**Triggers:** Weekly, or on-demand
**Inputs:** Installed packages, OS version
**Outputs:** Vulnerability report with severity ratings

### Patch Management
**Status:** Spec TBD
**Owner:** System Owner (with agent execution)
**Triggers:** Weekly check, manual request
**Inputs:** Available updates
**Outputs:** Patch recommendations, approval workflow

### Access Control Audit
**Status:** Spec TBD
**Owner:** sec-sentinel agent
**Triggers:** Weekly
**Inputs:** /etc/passwd, /etc/sudoers, SSH authorized_keys
**Outputs:** Access audit report

### Log Monitoring
**Status:** Spec TBD
**Owner:** log-parser agent
**Triggers:** Continuous / daily
**Inputs:** System logs, application logs
**Outputs:** Alerts, anomaly reports

### Incident Response
**Status:** Spec TBD
**Owner:** System Owner (with agent support)
**Triggers:** Manual or alert-based
**Inputs:** Security event details
**Outputs:** Incident log, remediation steps
