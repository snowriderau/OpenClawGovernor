---
description: Run a comprehensive security audit of the system
---

# Security Audit Workflow

Scan for misconfigurations, missing patches, permission issues, and compliance gaps.

## Phase 1: Baseline Scan

SSH to machine and gather baseline data:

```bash
ssh {{HOSTNAME}} '
# System info
uname -a && cat /etc/os-release
df -h

# Packages with available updates
sudo apt list --upgradable 2>/dev/null || apt list --upgradable

# Security patches available
apt-cache policy 2>/dev/null | head -5

# User accounts
cat /etc/passwd | grep -E "^(root|{{USERNAME}})" | cut -d: -f1,3,6

# Sudoers rules
sudo cat /etc/sudoers.d/ 2>/dev/null || echo "No custom sudoers rules found"
ls -la /etc/sudoers.d/ 2>/dev/null

# Services
systemctl list-unit-files --type=service --state=enabled | grep -v "^UNIT"

# Open ports
sudo ss -tlnp 2>/dev/null || netstat -tlnp
'
```

## Phase 2: Check Against Specs

Review each configured service against its spec:

1. **Inference Server** — Running on :{{INFERENCE_PORT}}? Headless? systemd service active?
2. **OpenClaw Gateway** — Running on :{{GATEWAY_PORT}}? Sudoers correct? Config valid?
3. **Backup** — NAS/backup destination reachable? Rsync jobs scheduled?
4. **Watchdog** — Health check script and timer running?

Cross-reference `feature_map.md` and `specs/` for expected configuration.

## Phase 3: Vulnerability Check

```bash
ssh {{HOSTNAME}} '
# Check for known security issues in installed packages
sudo apt list --upgradable 2>/dev/null | grep -i security

# Check for world-writable files in sensitive dirs
find /etc -perm -002 -type f 2>/dev/null | head -20

# Check SSH config
grep -E "^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config

# Check firewall status
sudo ufw status 2>/dev/null || sudo iptables -L -n 2>/dev/null | head -20
'
```

## Phase 4: Report Findings

Generate report in `.agent/memory/`:
```
audit_YYYY-MM-DD.md

- System baseline (OS version, kernel, uptime)
- Security patches available
- Permission review (sudoers, file modes, ownership)
- Configuration audit (against specs)
- Recommendations
```

## Phase 5: Document Decisions

1. Update active_state.md with findings
2. Add urgent issues to task_queue.md
3. Note patterns in learnings

---

System to audit: $ARGUMENTS
