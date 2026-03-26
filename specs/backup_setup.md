# Spec: Backup Strategy

## Overview
**Feature ID:** FEAT-BACKUP
**Title:** Basic Backup for Home AI Server
**Status:** Draft — configure for your environment
**Last Updated:** YYYY-MM-DD

## Problem
The server has NO backups by default. Running autonomous AI agent workloads with no fallback is high risk — a bad package install, config corruption, or disk issue could wipe everything.

## Goals
- Automated daily backups of critical data
- Ability to restore key configs in under 1 hour
- Minimal storage overhead
- Simple enough for an autonomous agent (Courier) to verify backup health

---

## What to Back Up

### Critical (daily backup)
```
/etc/                    # All system configs
~/.openclaw/             # Openclaw data, configs, scripts
/etc/systemd/system/     # Custom service definitions
/opt/openclaw/           # Scripts and runtime data (if using /opt layout)
```

### Nice to Have (weekly)
```
/home/{{USERNAME}}/      # Owner home directory
Openclaw conversation history / model configs
Inference server settings
```

### Do NOT Back Up
```
/tmp/                    # Temporary files
/var/cache/              # Package cache (easily rebuilt)
AI model weights         # Too large; re-download if needed
swap                     # Not needed
```

---

## Simple Solution: rsync to NAS or External Drive

### Backup Script (`/opt/openclaw/scripts/backup.sh`)
```bash
#!/bin/bash
# Backup critical configs and data
# Designed to run daily via systemd timer
# Managed by the Courier agent (file/storage domain)

BACKUP_DEST="{{NAS_BACKUP_PATH}}"   # NAS or external drive mount point
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
    /home/{{USERNAME}}/.openclaw/ \
    /opt/openclaw/ \
    "$BACKUP_DIR/"

if [ $? -eq 0 ]; then
    log "Backup complete: $BACKUP_DIR"
    # Keep last 7 daily backups
    ls -dt "$BACKUP_DEST/backups/"*/ | tail -n +8 | xargs rm -rf
    log "Cleanup: kept last 7 backups"
else
    log "ERROR: Backup failed!"
    exit 1
fi
```

### systemd Timer for Daily Backups

**`/etc/systemd/system/openclaw-backup.service`**
```ini
[Unit]
Description=Openclaw Daily Backup

[Service]
Type=oneshot
User={{USERNAME}}
ExecStart=/opt/openclaw/scripts/backup.sh
StandardOutput=append:/var/log/openclaw/backup.log
StandardError=append:/var/log/openclaw/backup.log
```

**`/etc/systemd/system/openclaw-backup.timer`**
```ini
[Unit]
Description=Openclaw Daily Backup Timer

[Timer]
OnCalendar=daily
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw-backup.timer
sudo systemctl start openclaw-backup.timer
```

---

## Alternative: NAS rsync over SSH

```bash
# Rsync over SSH to NAS
rsync -az -e "ssh -p {{NAS_SSH_PORT}}" \
    /etc/ \
    /home/{{USERNAME}}/.openclaw/ \
    {{USERNAME}}@{{NAS_IP}}:/volume1/backups/openclaw-server/

# BorgBackup (deduplication + encryption — recommended for sensitive configs)
sudo apt install borgbackup
borg init --encryption=repokey {{USERNAME}}@{{NAS_IP}}:/volume1/backups/borg-repo
borg create {{USERNAME}}@{{NAS_IP}}:/volume1/backups/borg-repo::backup-{now} \
    /etc /home/{{USERNAME}}/.openclaw
```

---

## Quick Config Snapshot (Lightweight)

Run before ANY system change — takes seconds:

```bash
#!/bin/bash
# Quick config snapshot - run before any system change
SNAP_DIR="/opt/openclaw/snapshots/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$SNAP_DIR"
cp -r /etc/systemd/system/ "$SNAP_DIR/"
cp /etc/sudoers.d/openclaw-agent "$SNAP_DIR/" 2>/dev/null
dpkg --get-selections > "$SNAP_DIR/installed_packages.txt"
echo "Snapshot saved to $SNAP_DIR"
```

---

## Courier Agent Integration

Backup operations belong to the **Courier** agent (file/storage security domain). Courier:
- Runs the backup script on schedule
- Verifies backup size and integrity
- Escalates to Atlas if backup fails (disk full, NAS unreachable, etc.)
- Never makes decisions about what to delete — only reports status

Courier does NOT:
- Fix code or configs that caused a backup failure
- Delete source files to free space
- Make decisions about backup retention policy changes

Any backup failure that requires a decision escalates to Atlas → user.

---

## Acceptance Criteria

- [ ] Backup script created and executable at `/opt/openclaw/scripts/backup.sh`
- [ ] Backup runs daily (systemd timer or cron)
- [ ] At least one successful backup completed
- [ ] Backup includes `/etc` and `~/.openclaw/`
- [ ] Restore procedure tested at least once
- [ ] Log shows last backup status at `/var/log/openclaw/backup.log`
- [ ] Courier agent configured to verify backup health on heartbeat

---

## Priority Note

Until backups are in place:
- **Do NOT** do major system changes (large package upgrades, kernel changes)
- **Do NOT** modify `/etc/sudoers` significantly
- **Do** run a config snapshot before any maintenance

**Minimum viable backup:** `cp -r /etc /tmp/etc-backup-$(date +%Y%m%d)` before making changes is better than nothing.
