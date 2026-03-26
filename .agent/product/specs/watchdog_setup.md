# Watchdog & Heartbeat System

## Overview
**Title:** Fault-Tolerant Watchdog & Remote Heartbeat
**Author:** Claude
**Status:** Template
**Last Updated:** 2026-03-26

## Problem
A server running autonomous AI workloads (local inference, agent gateway) needs:
- Auto-recovery when services crash or hang
- Remote visibility into health status
- Ability to restart from outside if completely stuck

## Goals
- Services restart automatically on failure
- Owner can see machine status remotely
- Owner can remotely restart services or machine if needed
- Agents can monitor and self-heal their own processes

## Architecture

```
[Inference Server]  [Agent Gateway]  [Other Services]
        |                  |                |
        v                  v                v
   [systemd watchdog (auto-restart)]
        |
        v
   [Health Check Script] --> [Status log / endpoint]
        |
        v
   [Remote Heartbeat] --> [External ping / alert]
```

## Component 1: systemd Auto-Restart

All services use systemd's built-in restart capability.

```ini
[Service]
Restart=always
RestartSec=10
StartLimitIntervalSec=60
StartLimitBurst=5
WatchdogSec=30
```

**Restart policies:**
- `Restart=always` -- restart on any exit (crash, kill, etc.)
- `RestartSec=10` -- wait 10 seconds before restart
- `StartLimitBurst=5` -- max 5 restarts per `StartLimitIntervalSec`
- `WatchdogSec=30` -- notify systemd every 30 sec or be killed

### Local Inference Service (`/etc/systemd/system/local-inference.service`)
```ini
[Unit]
Description=Local Inference Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{USERNAME}}
WorkingDirectory=/opt/openclaw
ExecStart=/usr/bin/inference-server start --port {{INFERENCE_PORT}}
ExecStop=/usr/bin/inference-server stop
Restart=always
RestartSec=10
StartLimitIntervalSec=120
StartLimitBurst=3
StandardOutput=append:/var/log/openclaw/inference.log
StandardError=append:/var/log/openclaw/inference-error.log
TimeoutStartSec=60
KillMode=process

[Install]
WantedBy=multi-user.target
```

### Agent Gateway Service (`/etc/systemd/system/openclaw.service`)
```ini
[Unit]
Description=OpenClaw Autonomous Agent
After=network-online.target local-inference.service
Wants=local-inference.service

[Service]
Type=simple
User={{USERNAME}}
WorkingDirectory=/opt/openclaw
ExecStart=/opt/openclaw/run.sh
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

## Component 2: Health Check Script

Local script that checks all service health and logs status.

### `/opt/openclaw/scripts/healthcheck.sh`
```bash
#!/bin/bash
# Health Check Script for OpenClaw system
# Runs every 5 minutes via systemd timer

LOGFILE="/var/log/openclaw/health.log"
SERVICES=("local-inference" "openclaw")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
STATUS_FILE="/opt/openclaw/health_status.json"

check_service() {
    local name=$1
    if systemctl is-active --quiet "$name"; then
        echo "OK"
    else
        echo "DOWN"
    fi
}

check_port() {
    local port=$1
    if ss -tlnp | grep -q ":$port "; then
        echo "LISTENING"
    else
        echo "NOT_LISTENING"
    fi
}

# Run checks
INFERENCE_STATUS=$(check_service local-inference)
AGENT_STATUS=$(check_service openclaw)
INFERENCE_PORT_STATUS=$(check_port {{INFERENCE_PORT}})
GATEWAY_PORT_STATUS=$(check_port {{GATEWAY_PORT}})
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')
MEM_USAGE=$(free | awk '/^Mem:/{printf "%.0f%%", $3/$2*100}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')

# Write JSON status
cat > "$STATUS_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "services": {
    "inference": "$INFERENCE_STATUS",
    "agent": "$AGENT_STATUS"
  },
  "ports": {
    "inference_{{INFERENCE_PORT}}": "$INFERENCE_PORT_STATUS",
    "gateway_{{GATEWAY_PORT}}": "$GATEWAY_PORT_STATUS"
  },
  "system": {
    "disk": "$DISK_USAGE",
    "memory": "$MEM_USAGE",
    "load": "$LOAD"
  }
}
EOF

# Log summary
echo "[$TIMESTAMP] inference=$INFERENCE_STATUS agent=$AGENT_STATUS disk=$DISK_USAGE mem=$MEM_USAGE load=$LOAD" >> "$LOGFILE"

# Alert if something is down
if [ "$INFERENCE_STATUS" = "DOWN" ] || [ "$AGENT_STATUS" = "DOWN" ]; then
    echo "[$TIMESTAMP] ALERT: Service down - attempting restart" >> "$LOGFILE"
    if [ "$INFERENCE_STATUS" = "DOWN" ]; then
        systemctl restart local-inference
        sleep 5
        NEW_STATUS=$(check_service local-inference)
        echo "[$TIMESTAMP] Inference server restart result: $NEW_STATUS" >> "$LOGFILE"
    fi
fi
```

### Health Check Timer (`/etc/systemd/system/openclaw-health.timer`)
```ini
[Unit]
Description=OpenClaw Health Check Timer

[Timer]
OnBootSec=60
OnUnitActiveSec=5min
AccuracySec=30

[Install]
WantedBy=timers.target
```

### Health Check Service (`/etc/systemd/system/openclaw-health.service`)
```ini
[Unit]
Description=OpenClaw Health Check

[Service]
Type=oneshot
User={{USERNAME}}
ExecStart=/opt/openclaw/scripts/healthcheck.sh
```

## Component 3: Remote Heartbeat

Options for remote visibility (pick one based on available infrastructure):

### Option A: Simple HTTP endpoint (recommended)
Expose the health_status.json via a lightweight HTTP server on a non-standard port.

```python
# /opt/openclaw/scripts/status_server.py
import http.server
import json
import os

class StatusHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            status_file = '/opt/openclaw/health_status.json'
            if os.path.exists(status_file):
                with open(status_file) as f:
                    data = f.read()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(data.encode())
            else:
                self.send_response(503)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress access logs

if __name__ == '__main__':
    server = http.server.HTTPServer(('0.0.0.0', 8888), StatusHandler)
    server.serve_forever()
```

Access from anywhere on local network: `curl http://{{LAN_IP}}:8888/health`

### Option B: SSH-based remote check
```bash
# From remote machine, check status:
ssh {{USERNAME}}@{{LAN_IP}} 'cat /opt/openclaw/health_status.json'

# From remote machine, restart service:
ssh {{USERNAME}}@{{LAN_IP}} 'sudo systemctl restart openclaw'
```

### Option C: VPN/Tailscale (recommended for remote access)
```bash
sudo apt install tailscale
sudo tailscale up
# Then access via Tailscale IP from any device
curl http://{{TAILSCALE_IP}}:8888/health
```

## Component 4: Self-Healing Script

The agent system can run this to detect and fix its own environment:

### `/opt/openclaw/scripts/self_heal.sh`
```bash
#!/bin/bash
# Self-healing script agents can trigger
# Checks state and auto-restarts components

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a /var/log/openclaw/self_heal.log; }

log "Self-heal check started"

# Check inference server
if ! systemctl is-active --quiet local-inference; then
    log "Inference server is down - restarting"
    sudo systemctl restart local-inference
    sleep 10
    if systemctl is-active --quiet local-inference; then
        log "Inference server restarted successfully"
    else
        log "Inference server restart FAILED - escalating"
        echo "ALERT: Inference server failed to restart at $(date)" >> /opt/openclaw/alerts.txt
    fi
fi

# Check disk space (warn if >85%)
DISK=$(df / | awk 'NR==2{print $5}' | tr -d '%')
if [ "$DISK" -gt 85 ]; then
    log "WARNING: Disk usage is ${DISK}% - cleanup needed"
    echo "WARN: Disk at ${DISK}% at $(date)" >> /opt/openclaw/alerts.txt
fi

# Check memory (restart if OOM risk)
MEM=$(free | awk '/^Mem:/{printf "%.0f", $3/$2*100}')
if [ "$MEM" -gt 90 ]; then
    log "WARNING: Memory usage at ${MEM}%"
    echo "WARN: Memory at ${MEM}% at $(date)" >> /opt/openclaw/alerts.txt
fi

log "Self-heal check complete"
```

## Setup Commands (Run Once)

```bash
# 1. Create directories
sudo mkdir -p /opt/openclaw/scripts
sudo mkdir -p /var/log/openclaw
sudo chown -R {{USERNAME}}:{{USERNAME}} /opt/openclaw
sudo chown -R {{USERNAME}}:{{USERNAME}} /var/log/openclaw

# 2. Copy scripts
sudo cp healthcheck.sh /opt/openclaw/scripts/
sudo cp self_heal.sh /opt/openclaw/scripts/
sudo cp status_server.py /opt/openclaw/scripts/
sudo chmod +x /opt/openclaw/scripts/*.sh

# 3. Enable systemd services
sudo systemctl daemon-reload
sudo systemctl enable local-inference
sudo systemctl enable openclaw
sudo systemctl enable openclaw-health.timer
sudo systemctl start openclaw-health.timer

# 4. Verify
systemctl status local-inference
systemctl status openclaw
systemctl status openclaw-health.timer
cat /opt/openclaw/health_status.json
```

## Acceptance Criteria

- [ ] Inference server auto-restarts on crash
- [ ] Agent gateway auto-restarts on crash
- [ ] Health check runs every 5 minutes
- [ ] Health status viewable via HTTP endpoint
- [ ] Self-heal script can restart services
- [ ] Alerts written to file when things fail
- [ ] Logs rotated to prevent disk fill

## Log Rotation (`/etc/logrotate.d/openclaw`)
```
/var/log/openclaw/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 {{USERNAME}} {{USERNAME}}
}
```
