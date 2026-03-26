# Machine Recovery Workflow

## When To Use
SSH to {{HOSTNAME}} fails (Tailscale or LAN). This runbook covers diagnosis, recovery, and prevention.

## Step 1: Verify Your Own Connectivity (30 sec)

```bash
# Control machine has internet?
ping -c 1 8.8.8.8

# Tailscale connected on control machine?
tailscale status
```

## Step 2: Try All SSH Paths (1 min)

```bash
# Tailscale
ssh -o ConnectTimeout=5 {{HOSTNAME}} echo "tailscale ok"

# LAN primary (NIC1)
ssh -o ConnectTimeout=5 {{HOSTNAME}}-lan echo "lan1 ok"

# LAN secondary (NIC2)
ssh -o ConnectTimeout=5 -i ~/.ssh/id_rsa {{USERNAME}}@{{LAN_IP}} echo "lan2 ok"
```

## Step 3: Network Reachability (30 sec)

```bash
ping -c 2 -W 2 {{TAILSCALE_IP}}    # Tailscale
ping -c 2 -W 2 {{LAN_IP}}          # LAN NIC1
ping -c 2 -W 2 {{LAN_IP_NIC2}}     # LAN NIC2

# Service ports (if ping works but SSH doesn't)
nc -z -w 3 {{LAN_IP}} {{GATEWAY_PORT}}      # Agent gateway
nc -z -w 3 {{LAN_IP}} {{INFERENCE_PORT}}     # Inference engine
nc -z -w 3 {{LAN_IP}} 8888                   # Health endpoint
```

## Step 4: Diagnosis Matrix

| Tailscale SSH | LAN SSH | Ping LAN | Diagnosis | Action |
|---|---|---|---|---|
| Fail | OK | OK | Tailscale down on {{HOSTNAME}} | SSH via LAN, `sudo systemctl restart tailscaled` |
| Fail | Fail | OK | sshd crashed or firewall | Agent Telegram (Step 5), NAS/jump host (Step 6) |
| Fail | Fail | Fail (slow) | High load / OOM | Wait 5 min, retry with `-o ServerAliveInterval=5` |
| Fail | Fail | Fail | Machine off/frozen | WoL (Step 7), then physical access |

## Step 5: Agent Telegram Recovery

If machine is running but SSH broken, message {{TELEGRAM_BOT}} on Telegram:
- "check system status"
- "restart sshd" -> `sudo systemctl restart ssh`
- "restart tailscaled" -> `sudo systemctl restart tailscaled`
- "check disk space" -> `df -h`

**Requires:** Agent gateway running + outbound internet working.

## Step 6: NAS/Jump Host

```bash
# SSH to NAS/jump host (always-on device on same LAN)
ssh nas-jump    # {{NAS_IP}}:{{NAS_SSH_PORT}}

# From NAS/jump host, try target machine
ssh {{USERNAME}}@{{LAN_IP}}
ping {{LAN_IP}}

# If ping works but SSH doesn't, try WoL from NAS/jump host
# wakeonlan {{MAC_ADDRESS}}
```

**Prerequisite:** SSH key from NAS/jump host to target machine must be set up (see Setup section).

## Step 7: Wake-on-LAN

```bash
# From control machine (brew install wakeonlan on macOS)
wakeonlan -i {{LAN_BROADCAST}} {{MAC_ADDRESS}}

# From NAS/jump host
ssh nas-jump 'wakeonlan {{MAC_ADDRESS}}'
```

**Prerequisites:**
- MAC address recorded (run `ip link show <NIC>` when machine is up)
- WoL enabled in BIOS/UEFI
- WoL enabled in OS: `sudo ethtool -s <NIC> wol g`

## Step 8: Physical Access Required

If all above fails:
1. Power cycle the machine (hold power button 10 sec, then press again)
2. Once booted, SSH in and check `journalctl -b -1` for previous boot crash logs
3. Record the failure in `.agent/memory/failures.md`

---

## Prevention: Four-Layer Monitoring

### Layer 1: Target Machine Outbound Heartbeat (catches everything)
- `/home/{{USERNAME}}/scripts/heartbeat.sh` pings Healthchecks.io every 2 min
- Healthchecks.io alerts via Telegram after 5 min of silence
- Also checks service health and sends Telegram alerts on status changes
- **Works even when:** SSH is broken, Tailscale is down, control machine is off

### Layer 2: NAS/Jump Host LAN Monitor (catches LAN failures)
- NAS/jump host script pings target machine every 5 min
- Auto-attempts WoL if ping fails
- Alerts via Telegram if WoL doesn't recover it
- **Works even when:** Control machine is off, Tailscale is down, operator is remote

### Layer 3: Control Machine SSH Probe (fastest feedback when at desk)
- Control machine script checks SSH every 5 min via cron
- Desktop notification + Telegram alert on failure
- **Works when:** Control machine is on and on network

### Layer 4: Tailscale Auto-Reconnect (prevents common failure)
- `/home/{{USERNAME}}/scripts/tailscale-watchdog.sh` checks Tailscale every 5 min
- Auto-runs `sudo tailscale up` if disconnected
- Prevents the most common remote-access failure mode

---

## Setup Checklist (One-Time)

### On Target Machine (when SSH is restored)
- [ ] Record MAC address: `ip link show <NIC> | grep ether`
- [ ] Verify WoL: `sudo ethtool <NIC> | grep Wake-on` (need `g`)
- [ ] Enable WoL if needed: `sudo ethtool -s <NIC> wol g` + persist via networkd
- [ ] Create Healthchecks.io account, get ping URL
- [ ] Deploy heartbeat.sh + systemd timer
- [ ] Deploy healthcheck.sh + systemd timer
- [ ] Deploy tailscale-watchdog.sh + systemd timer
- [ ] Deploy HTTP health endpoint on :8888
- [ ] Set up SSH key FROM NAS/jump host to target machine

### On Control Machine
- [ ] `brew install wakeonlan` (macOS) or equivalent
- [ ] Deploy monitor script + cron job
- [ ] Record MAC address in this file

### On NAS/Jump Host
- [ ] Deploy LAN check script
- [ ] Add scheduled task entry (5 min interval)
- [ ] Install/verify wakeonlan available
- [ ] Generate SSH key and add to target machine authorized_keys

---

## System Identifiers

| Item | Value |
|------|-------|
| Tailscale IP | {{TAILSCALE_IP}} |
| LAN IP (NIC1) | {{LAN_IP}} |
| LAN IP (NIC2) | {{LAN_IP_NIC2}} |
| MAC (NIC1) | {{MAC_ADDRESS}} |
| MAC (NIC2) | {{MAC_ADDRESS}} |
| WoL enabled | **TODO: verify when machine is up** |
| NAS/Jump Host IP | {{NAS_IP}} (SSH port {{NAS_SSH_PORT}}) |
| Telegram bot | {{TELEGRAM_BOT}} |
| Telegram user ID | {{TELEGRAM_USER_ID}} |
| Healthchecks.io URL | **TODO: create account** |
