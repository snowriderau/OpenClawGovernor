# Backup Strategy

## Overview
**Title:** Basic Backup for AI Server
**Author:** Claude
**Status:** Template
**Last Updated:** 2026-03-26

## Problem
The server has NO backups. Running autonomous AI agent workloads with no fallback is high risk -- a bad package install, config corruption, or disk issue could wipe everything.

## Goals
- Automated daily backups of critical data
- Ability to restore key configs in <1 hour
- Minimal storage overhead
- Simple enough for autonomous agent to verify backup health

## What to Back Up

### Critical (daily backup)
```
/etc/                          # All system configs
/home/{{USERNAME}}/            # User home directory
/etc/systemd/system/           # Custom service definitions
{{MODEL_DIR}}/config/          # Agent and model configurations
```

### Nice to Have (weekly)
```
Agent conversation history / model configs
Local inference server settings
Project directories
```

### Do NOT Back Up
```
/tmp/                    # Temporary files
/var/cache/              # Package cache (easily rebuilt)
AI model weights         # Too large; re-download if needed
swap                     # Not needed
Docker image layers      # Rebuilt from Dockerfiles
```

## Simple Solution: rsync to External Drive

### Local Backup Script (`/opt/openclaw/scripts/backup.sh`)
```bash
#!/bin/bash
# Backup critical configs and data
# Designed to run daily via systemd timer

BACKUP_DEST="/media/backup"  # External drive mount point
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_DEST/backups/$TIMESTAMP"
LOG="/var/log/openclaw/backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"; }

# Check if backup destination is available
if [ ! -d "$BACKUP_DEST" ]; then
    log "ERROR: Backup destination $BACKUP_DEST not available"
    exit 1
fi

log "Starting backup to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup critical directories
rsync -az --delete \
    /etc/ \
    /home/{{USERNAME}}/ \
    {{MODEL_DIR}}/config/ \
    "$BACKUP_DIR/"

if [ $? -eq 0 ]; then
    log "Backup complete: $BACKUP_DIR"
    # Keep last 7 daily backups
    ls -dt "$BACKUP_DEST/backups/"*/ | tail -n +8 | xargs rm -rf
    log "Cleanup: kept last 7 backups"
else
    log "ERROR: Backup failed!"
fi
```

### systemd Timer for Daily Backups

**Timer** (`/etc/systemd/system/openclaw-backup.timer`):
```ini
[Unit]
Description=Daily Backup Timer

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

**Service** (`/etc/systemd/system/openclaw-backup.service`):
```ini
[Unit]
Description=Daily Backup Service

[Service]
Type=oneshot
User=root
ExecStart=/opt/openclaw/scripts/backup.sh
```

Enable with:
```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw-backup.timer
sudo systemctl start openclaw-backup.timer
```

## Alternative: Network Backup (No External Drive)

```bash
# Option A: rsync to another machine on local network
rsync -az -e "ssh -p {{NAS_SSH_PORT}}" \
    /etc/ /home/{{USERNAME}}/ \
    {{USERNAME}}@{{NAS_IP}}:/backups/server/

# Option B: BorgBackup (deduplication, encryption)
sudo apt install borgbackup
borg init --encryption=repokey /path/to/backup/repo
borg create /path/to/backup/repo::backup-{now} /etc /home/{{USERNAME}}

# Option C: rsync to NAS via SSH
rsync -az /etc/ {{USERNAME}}@{{NAS_IP}}:/volume1/backups/server-etc/
```

## Quick Config Snapshot (Lightweight)

Even without a full backup, capture configs quickly before making changes:

```bash
#!/bin/bash
# Quick config snapshot - can run before any system change
SNAP_DIR="/opt/openclaw/snapshots/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$SNAP_DIR"
cp -r /etc/systemd/system/ "$SNAP_DIR/"
cp /etc/sudoers.d/openclaw-agent "$SNAP_DIR/" 2>/dev/null
dpkg --get-selections > "$SNAP_DIR/installed_packages.txt"
echo "Snapshot saved to $SNAP_DIR"
```

## Acceptance Criteria

- [ ] Backup script created and executable
- [ ] Backup runs daily (systemd timer or cron)
- [ ] At least one successful backup completed
- [ ] Backup includes /etc and user home
- [ ] Restore procedure tested at least once
- [ ] Log shows last backup status

## Priority Note

Until backups are in place:
- **Do NOT** do major system changes (large package upgrades, kernel changes)
- **Do NOT** modify /etc/sudoers significantly
- **Do** get at least a config snapshot before any maintenance

**Minimum viable backup:** Even just `cp -r /etc /tmp/etc-backup-$(date +%Y%m%d)` before making changes is better than nothing.
