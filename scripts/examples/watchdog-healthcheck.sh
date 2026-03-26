#!/usr/bin/env bash
# watchdog-healthcheck.sh
#
# Checks critical services and disk usage, logs results, and exits non-zero
# to trigger systemd failure handling / alerting if anything is unhealthy.
#
# Governor must customize:
#   - check_service calls: add/remove services to match this deployment
#   - check_disk calls: update mount points for this machine's storage layout
#   - LOG_DIR: uses {{AGENT_MAIN}} as the state namespace — replace with agent name
#   - {{MODEL_DIR}}: mount point where model files live (may be an external drive)
#
# Exit codes:
#   0  — all checks passed
#   2  — one or more checks failed (service down or disk over threshold)

set -euo pipefail

ALERT=0
REPORT=()

# ---------------------------------------------------------------------------
# check_service <unit-name>
# Marks ALERT if the user-level systemd unit is not active.
# ---------------------------------------------------------------------------
check_service() {
  local svc="$1"
  local st
  st=$(systemctl --user is-active "$svc" 2>/dev/null || true)
  if [[ "$st" != "active" ]]; then
    ALERT=1
    REPORT+=("service:$svc=$st")
  else
    REPORT+=("service:$svc=active")
  fi
}

# ---------------------------------------------------------------------------
# check_disk <path>
# Marks ALERT if disk usage at <path> is >= 85%.
# Also alerts if the path is missing (unmounted drive, etc.).
# ---------------------------------------------------------------------------
check_disk() {
  local path="$1"
  local used
  used=$(df -P "$path" 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')
  if [[ -z "${used:-}" ]]; then
    ALERT=1
    REPORT+=("disk:$path=missing")
    return
  fi
  if (( used >= 85 )); then
    ALERT=1
  fi
  REPORT+=("disk:$path=${used}%")
}

# ---------------------------------------------------------------------------
# Services to monitor
# Governor: add or remove lines to match this deployment's services.
# ---------------------------------------------------------------------------
check_service openclaw-gateway.service
check_service local-inference.service   # Governor: change if using a different inference unit name

# ---------------------------------------------------------------------------
# Disks to monitor
# Governor: update paths to match this machine's mount points.
# {{MODEL_DIR}} is typically an external drive or large partition for model files.
# ---------------------------------------------------------------------------
check_disk /
check_disk {{MODEL_DIR}}

# ---------------------------------------------------------------------------
# Build log entry and append to state log
# Log dir uses {{AGENT_MAIN}} as namespace — Governor replaces this.
# ---------------------------------------------------------------------------
STAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
LINE="[$STAMP] ${REPORT[*]}"

LOG_DIR="$HOME/.local/state/{{AGENT_MAIN}}"
mkdir -p "$LOG_DIR"
echo "$LINE" >> "$LOG_DIR/watchdog.log"

# ---------------------------------------------------------------------------
# Output and exit
# ---------------------------------------------------------------------------
if (( ALERT == 1 )); then
  echo "ALERT $LINE"
  exit 2
fi

echo "OK $LINE"
