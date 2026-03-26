#!/usr/bin/env bash
# backup.sh
#
# Rsync-based backup of agent state, inference configs, and selected system
# configs to a NAS. Designed to be run as a systemd service or cron job.
#
# Governor must customize:
#   - {{NAS_HOST}}    — hostname or IP of the backup NAS
#   - {{BACKUP_PATH}} — root path on the NAS where backups land
#   - {{USERNAME}}    — Linux user on this machine
#   - {{AGENT_MAIN}}  — agent name used for log directory
#
# Exit codes:
#   0  — all syncs succeeded
#   1  — one or more syncs failed (check log for details)
#
# Prerequisites:
#   - SSH key-based auth to {{NAS_HOST}} (no password prompt)
#   - rsync installed on both source and destination
#   - NAS path {{BACKUP_PATH}} exists and is writable

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# Governor: these values come from the deployment .env or active_state config.
# ---------------------------------------------------------------------------
NAS_HOST="{{NAS_HOST}}"
BACKUP_ROOT="{{BACKUP_PATH}}"
USERNAME="{{USERNAME}}"
AGENT_MAIN="{{AGENT_MAIN}}"

LOG_DIR="$HOME/.local/state/backup"
LOG_FILE="$LOG_DIR/backup.log"
ERRORS=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() {
  local level="$1"
  shift
  echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] [$level] $*" | tee -a "$LOG_FILE"
}

rsync_job() {
  local label="$1"
  local src="$2"
  local dst="$3"
  shift 3
  local extra_args=("$@")

  log "INFO" "Starting: $label  ($src -> $NAS_HOST:$dst)"

  if rsync -avz --delete \
      "${extra_args[@]}" \
      -e "ssh -o BatchMode=yes -o ConnectTimeout=10" \
      "$src" \
      "$NAS_HOST:$dst" \
      >> "$LOG_FILE" 2>&1; then
    log "OK" "Done: $label"
  else
    log "ERROR" "Failed: $label (rsync exit $?)"
    (( ERRORS++ )) || true
  fi
}

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
mkdir -p "$LOG_DIR"
log "INFO" "=== Backup started ==="

# ---------------------------------------------------------------------------
# 1. OpenClaw agent state and config
#    ~/.openclaw/ contains gateway config, channel config, agent workspaces.
#    Exclude large model caches or tmp dirs if they live here.
# ---------------------------------------------------------------------------
rsync_job "openclaw-config" \
  "$HOME/.openclaw/" \
  "$BACKUP_ROOT/openclaw/" \
  --exclude="*.tmp" \
  --exclude="cache/"

# ---------------------------------------------------------------------------
# 2. Inference server configs
#    LM Studio stores user settings in ~/.cache/lm-studio/ and ~/.lmstudio/
#    Ollama model manifests live in ~/.ollama/manifests/ (not the weights)
#    Governor: uncomment the backend(s) in use; skip large model weights.
# ---------------------------------------------------------------------------

# LM Studio settings (skip model weights — those are in {{MODEL_DIR}})
rsync_job "lmstudio-settings" \
  "$HOME/.lmstudio/" \
  "$BACKUP_ROOT/inference/lmstudio/" \
  --exclude="models/"

# Uncomment for Ollama (manifests only, not the actual weights):
# rsync_job "ollama-manifests" \
#   "$HOME/.ollama/manifests/" \
#   "$BACKUP_ROOT/inference/ollama/manifests/"

# ---------------------------------------------------------------------------
# 3. Systemd user units
#    Backs up all user-level unit files so services can be restored quickly.
# ---------------------------------------------------------------------------
rsync_job "systemd-user-units" \
  "$HOME/.config/systemd/user/" \
  "$BACKUP_ROOT/systemd/user/" \
  --include="*.service" \
  --include="*.timer" \
  --include="*.socket" \
  --exclude="*"

# ---------------------------------------------------------------------------
# 4. Selected /etc configs
#    Only files likely to be customized; skip large or auto-generated files.
#    Governor: adjust include/exclude list to match what was changed on this box.
# ---------------------------------------------------------------------------
rsync_job "etc-configs" \
  "/etc/" \
  "$BACKUP_ROOT/etc/" \
  --include="hostname" \
  --include="hosts" \
  --include="fstab" \
  --include="ssh/***" \
  --include="cron.d/***" \
  --include="cron.daily/***" \
  --include="environment" \
  --include="locale.gen" \
  --include="timezone" \
  --exclude="*"

# ---------------------------------------------------------------------------
# 5. This Governor repo (belt-and-suspenders alongside git remote)
# ---------------------------------------------------------------------------
rsync_job "governor-repo" \
  "$HOME/code/OpenClawGovernor/" \
  "$BACKUP_ROOT/governor/" \
  --exclude=".git/"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "INFO" "=== Backup complete — errors: $ERRORS ==="

if (( ERRORS > 0 )); then
  log "ERROR" "One or more backup jobs failed. Review $LOG_FILE"
  exit 1
fi

exit 0
