# Machine Recovery Workflow

## When To Use
Governor detects SSH to {{HOSTNAME}} is failing (Tailscale or LAN). This runbook covers automated diagnosis, recovery, and prevention. All steps are executed by Governor unless physical intervention is required.

## Step 1: Verify Network Connectivity (Automated, 30 sec)

Governor checks:

```bash
# Does Governor's host have internet?
ping -c 1 8.8.8.8

# Is Tailscale connected on Governor's host?
tailscale status
```

## Step 2: Try All SSH Paths (Automated, 1 min)

```bash
# Tailscale
ssh -o ConnectTimeout=5 {{HOSTNAME}} echo "tailscale ok"

# LAN primary (enp7s0)
ssh -o ConnectTimeout=5 {{HOSTNAME}}-lan echo "lan1 ok"

# LAN secondary (enp4s0)
ssh -o ConnectTimeout=5 -i ~/.ssh/{{SSH_KEY}} {{SYSTEM_USER}}@{{LAN_IP_NIC2}} echo "lan2 ok"
```

## Step 3: Network Reachability (Automated, 30 sec)

```bash
ping -c 2 -W 2 {{TAILSCALE_IP}}    # Tailscale
ping -c 2 -W 2 {{LAN_IP_NIC1}}     # LAN NIC1
ping -c 2 -W 2 {{LAN_IP_NIC2}}     # LAN NIC2

# Service ports (if ping works but SSH doesn't)
nc -z -w 3 {{LAN_IP_NIC1}} {{LM_STUDIO_PORT}}      # LM Studio
nc -z -w 3 {{LAN_IP_NIC1}} {{OPENCLAW_PORT}}        # Openclaw gateway
nc -z -w 3 {{LAN_IP_NIC1}} {{HEALTH_PORT}}          # Health endpoint
```

## Step 4: Diagnosis Matrix

| Tailscale SSH | LAN SSH | Ping LAN | Diagnosis | Automated Action |
|---|---|---|---|---|
| Fail | OK | OK | Tailscale down on {{HOSTNAME}} | SSH via LAN, `sudo systemctl restart tailscaled` |
| Fail | Fail | OK | sshd crashed or firewall | Openclaw Telegram (Step 5), NAS jump (Step 6) |
| Fail | Fail | Fail (slow) | High load / OOM | Wait 5 min, retry with `-o ServerAliveInterval=5` |
| Fail | Fail | Fail | Machine off/frozen | WoL (Step 7), then escalate to owner for physical access |

## Step 5: Openclaw Telegram Recovery (Automated)

If the machine is running but SSH is broken, Governor messages `{{TELEGRAM_BOT}}` on Telegram:
- "check system status"
- "restart sshd" → `sudo systemctl restart ssh`
- "restart tailscaled" → `sudo systemctl restart tailscaled`
- "check disk space" → `df -h`

**Requires:** Openclaw gateway running + outbound internet working.

## Step 6: NAS Jump Host (Automated)

```bash
# Governor SSHes to NAS (always-on NAS on same LAN)
ssh {{NAS_HOST}}    # {{NAS_IP}}:{{NAS_SSH_PORT}}

# From NAS, try the machine
ssh {{SYSTEM_USER}}@{{LAN_IP_NIC1}}
ping {{LAN_IP_NIC1}}

# If ping works but SSH doesn't, attempt WoL from NAS
# wakeonlan <MAC_ADDRESS>
```

**Prerequisite:** SSH key from NAS → {{HOSTNAME}} must be set up (see Setup section).

## Step 7: Wake-on-LAN (Automated)

```bash
# Governor sends WoL from its host (brew install wakeonlan)
wakeonlan -i {{LAN_BROADCAST}} {{MAC_ADDRESS}}

# Alternatively, Governor triggers WoL via NAS
ssh {{NAS_HOST}} 'wakeonlan {{MAC_ADDRESS}}'
```

**Prerequisites:**
- MAC address recorded (run `ip link show enp7s0` when machine is up)
- WoL enabled in BIOS/UEFI
- WoL enabled in OS: `sudo ethtool -s enp7s0 wol g`

## Step 8: Physical Access Required (Owner Escalation)

If all automated recovery fails, Governor escalates to the owner via Telegram/notification:
1. Owner power-cycles the machine (hold power button 10 sec, then press again)
2. Once booted, Governor SSHes in and checks `journalctl -b -1` for previous boot crash logs
3. Governor records the failure in `.agent/memory/failures.md` automatically

---

## Prevention: Four-Layer Monitoring (Fully Automated)

### Layer 1: Outbound Heartbeat (catches everything)
- `/home/{{SYSTEM_USER}}/scripts/heartbeat.sh` pings Healthchecks.io every 2 min
- Healthchecks.io alerts via Telegram after 5 min of silence
- Also checks service health and sends Telegram alerts on status changes
- **Works even when:** SSH is broken, Tailscale is down, Governor host is off

### Layer 2: NAS LAN Monitor (catches LAN failures)
- `/volume1/scripts/check-machine.sh` pings {{HOSTNAME}} every 5 min
- Auto-attempts WoL if ping fails
- Alerts via Telegram if WoL doesn't recover it
- **Works even when:** Governor host is off, Tailscale is down, operator is remote

### Layer 3: Governor SSH Probe (fastest feedback when Governor is active)
- Governor checks SSH every 5 min via scheduled task
- Sends Telegram alert on failure and initiates recovery sequence automatically
- **Works when:** Governor host is on and on network

### Layer 4: Tailscale Auto-Reconnect (prevents common failure)
- `/home/{{SYSTEM_USER}}/scripts/tailscale-watchdog.sh` checks Tailscale every 5 min
- Auto-runs `sudo tailscale up` if disconnected
- Prevents the most common remote-access failure mode

---

## Setup Checklist (One-Time, Governor-Executed)

### On the Target Machine (when SSH is restored)
- [ ] Record MAC address: `ip link show enp7s0 | grep ether`
- [ ] Verify WoL: `sudo ethtool enp7s0 | grep Wake-on` (need `g`)
- [ ] Enable WoL if needed: `sudo ethtool -s enp7s0 wol g` + persist via networkd
- [ ] Create Healthchecks.io account, get ping URL
- [ ] Deploy heartbeat.sh + systemd timer
- [ ] Deploy healthcheck.sh + systemd timer
- [ ] Deploy tailscale-watchdog.sh + systemd timer
- [ ] Deploy HTTP health endpoint on :{{HEALTH_PORT}}
- [ ] Set up SSH key FROM NAS → machine

### On Governor Host
- [ ] `brew install wakeonlan`
- [ ] Deploy SSH probe + scheduled task
- [ ] Record MAC address in this file

### On NAS
- [ ] Deploy check-machine.sh
- [ ] Add Task Scheduler entry (5 min interval)
- [ ] Install/verify wakeonlan available
- [ ] Generate SSH key and add to machine authorized_keys

---

## System Identifiers

Governor populates this table during initial setup. Store sensitive values (keys, tokens) in your secrets manager — not here.

| Item | Value |
|------|-------|
| Tailscale IP | {{TAILSCALE_IP}} |
| LAN IP (NIC1) | {{LAN_IP_NIC1}} |
| LAN IP (NIC2) | {{LAN_IP_NIC2}} |
| MAC (NIC1) | {{MAC_ADDRESS}} |
| MAC (NIC2) | {{MAC_ADDRESS}} |
| WoL enabled | TODO: verify when machine is up |
| NAS IP | {{NAS_IP}} (SSH port {{NAS_SSH_PORT}}) |
| Telegram bot | {{TELEGRAM_BOT}} |
| Telegram user ID | {{TELEGRAM_USER_ID}} |
| Healthchecks.io URL | TODO: create account |
