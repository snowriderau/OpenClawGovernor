# Spec: Openclaw Agent System Access

## Overview
**Feature ID:** FEAT-001
**Title:** Openclaw Autonomous Agent Permissions & Access
**Status:** Active
**Last Updated:** YYYY-MM-DD

## Problem
The Openclaw autonomous agent needs to manage the system (services, packages, configs, AI workloads) but lacks appropriate system access by default. Standard user permissions are too restrictive for autonomous operation, but root access is too broad.

## Goals
- Give Openclaw the permissions it needs to manage its own environment
- Apply least-privilege (only what it actually needs)
- Make changes auditable and reversible
- Keep clear separation between Openclaw actions and owner actions

---

## Design: Openclaw User Account

Openclaw runs as a **dedicated system user** (`{{USERNAME}}`) with elevated permissions via sudo — not as root directly.

**Benefits:**
- All Openclaw actions logged under its own user
- Easy to revoke or limit permissions later
- Audit trail shows exactly what the agent did
- Safer than running the inference server + agent as root

---

## Permissions Scope

### Allowed WITHOUT password (sudoers)
```
# Service management
systemctl start/stop/restart/status <service>
systemctl enable/disable <service>

# Package management (for self-updates)
apt update
apt upgrade --yes
apt install --yes <package>

# Process management
kill, pkill (for stuck processes)

# File ops in designated directories
Read/Write to /opt/openclaw/
Read/Write to /var/log/openclaw/
Read to /etc/ (configs)

# Network status
ufw status
ufw allow/deny

# Log reading
journalctl
cat /var/log/*
```

### Requires owner password (interactive sudo)
```
# Destructive or dangerous operations
rm -rf anything
Modify /etc/passwd, /etc/sudoers
Disk formatting/partitioning
Firewall disable
SSH configuration changes
cron modifications outside Openclaw scope
```

### NEVER without explicit owner command
```
Access to owner's personal files
Modify ownership of / or /home
Disable security services
Remove system packages
Access to SSH private keys
```

---

## Implementation Plan

### Step 1: Create Openclaw User
```bash
# Create system user for Openclaw (if not using your own user account)
sudo useradd -r -m -s /bin/bash openclaw
sudo usermod -aG sudo openclaw

# Set up runtime directory
sudo mkdir -p /opt/openclaw/{data,logs,config,scripts}
sudo chown -R openclaw:openclaw /opt/openclaw
```

> **Note:** Many setups run Openclaw as the owner's regular user account (`{{USERNAME}}`). A dedicated `openclaw` user is more secure but requires more setup. Choose based on your risk tolerance.

### Step 2: Configure Sudoers (Targeted Rules)
```bash
# Edit sudoers safely (always use visudo, never edit directly)
sudo visudo -f /etc/sudoers.d/openclaw-agent

# Contents:
# Allow agent user to manage services without password
{{USERNAME}} ALL=(ALL) NOPASSWD: /bin/systemctl start *, \
                               /bin/systemctl stop *, \
                               /bin/systemctl restart *, \
                               /bin/systemctl status *, \
                               /bin/systemctl enable *, \
                               /bin/systemctl disable *

# Allow package management without password
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/apt update, \
                               /usr/bin/apt upgrade -y, \
                               /usr/bin/apt install -y *

# Allow log reading
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/bin/journalctl *, \
                               /bin/cat /var/log/*

# Allow process management
{{USERNAME}} ALL=(ALL) NOPASSWD: /bin/kill, /usr/bin/pkill

# Allow network status (read-only)
{{USERNAME}} ALL=(ALL) NOPASSWD: /usr/sbin/ufw status
```

### Step 3: Log Directory Setup
```bash
# Dedicated log directory for Openclaw activity
sudo mkdir -p /var/log/openclaw
sudo chown {{USERNAME}}:{{USERNAME}} /var/log/openclaw
sudo chmod 750 /var/log/openclaw
```

### Step 4: Configure Audit Logging
```bash
# Track all agent actions via auditd
sudo apt install auditd
# Replace <agent_uid> with the actual UID of the running user
sudo auditctl -a always,exit -F uid=<agent_uid> -k openclaw_actions
```

### Step 5: Enable loginctl Linger
Required for user systemd services to run at boot without an active login session:
```bash
loginctl enable-linger {{USERNAME}}
```

---

## Security Notes

1. **Audit everything** — auditd logs all agent system calls. Review weekly.
2. **Rotate logs** — set up logrotate for `/var/log/openclaw/`
3. **Limit scope** — only add permissions when needed, not in advance
4. **Review regularly** — weekly check of what the agent has been doing (Governor's job)
5. **No SSH key access** — the agent doesn't need to SSH out by default
6. **No cron writes** — the agent schedules tasks via its own queue, not crontab
7. **Remove unused permissions** — if a permission hasn't been used in 30 days, remove it

---

## Acceptance Criteria

- [ ] Agent user exists and has dedicated runtime directory
- [ ] Sudoers configured with targeted rules (use `sudo -l -U {{USERNAME}}` to verify)
- [ ] Agent can start/stop services without password prompt
- [ ] Agent can install packages without password prompt
- [ ] Audit logging active for all agent actions
- [ ] loginctl linger enabled
- [ ] Owner can review audit log of agent activity
- [ ] Owner can revoke individual permissions without breaking the system

---

## Rollback

```bash
# Remove sudoers rules
sudo rm /etc/sudoers.d/openclaw-agent

# Disable linger
loginctl disable-linger {{USERNAME}}

# If using a dedicated openclaw user — lock but don't delete (preserve audit trail)
sudo usermod -L openclaw

# Disable services
sudo systemctl disable openclaw
sudo systemctl disable local-inference
```
