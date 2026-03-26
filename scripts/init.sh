#!/usr/bin/env bash
# =============================================================================
# OpenClaw Governor Template -- Interactive Setup
# =============================================================================
# Collects configuration values, writes .env, and replaces {{PLACEHOLDER}}
# tokens across all template files. Idempotent: safe to re-run.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors & helpers
# ---------------------------------------------------------------------------
if command -v tput &>/dev/null && [ -t 1 ]; then
  BOLD=$(tput bold)
  DIM=$(tput dim)
  RESET=$(tput sgr0)
  BLUE=$(tput setaf 4)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6)
  RED=$(tput setaf 1)
else
  BOLD="" DIM="" RESET="" BLUE="" GREEN="" YELLOW="" CYAN="" RED=""
fi

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$REPO_DIR/.env"

banner() {
  echo ""
  echo "${BLUE}${BOLD}=====================================================================${RESET}"
  echo "${BLUE}${BOLD}  $1${RESET}"
  echo "${BLUE}${BOLD}=====================================================================${RESET}"
  echo ""
}

section() {
  echo ""
  echo "${CYAN}${BOLD}--- $1 ---${RESET}"
  echo ""
}

# prompt VAR_NAME "Prompt text" "default_value"
prompt() {
  local var_name="$1" prompt_text="$2" default="$3" value
  if [ -n "$default" ]; then
    printf "  ${GREEN}%s${RESET} [${DIM}%s${RESET}]: " "$prompt_text" "$default"
  else
    printf "  ${GREEN}%s${RESET}: " "$prompt_text"
  fi
  read -r value
  value="${value:-$default}"
  eval "$var_name=\"\$value\""
}

# prompt_yn VAR_NAME "Prompt text" "y/n default"
prompt_yn() {
  local var_name="$1" prompt_text="$2" default="$3" value
  printf "  ${GREEN}%s${RESET} [${DIM}%s${RESET}]: " "$prompt_text" "$default"
  read -r value
  value="${value:-$default}"
  value="$(echo "$value" | tr '[:upper:]' '[:lower:]')"
  eval "$var_name=\"\$value\""
}

validate_ip() {
  local ip="$1"
  if [ -z "$ip" ]; then return 0; fi
  if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0
  elif [[ "$ip" =~ ^100\. ]]; then
    # Tailscale IPs
    return 0
  fi
  echo "  ${RED}Warning: '$ip' doesn't look like a valid IPv4 address.${RESET}"
  return 0  # warn but don't block
}

# ---------------------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------------------
banner "OpenClaw Governor Template -- Setup"

echo "  This script will configure your Governor template by collecting"
echo "  information about your target machine, agents, and preferences."
echo ""
echo "  ${DIM}Press Enter to accept defaults shown in [brackets].${RESET}"
echo "  ${DIM}Re-run this script anytime to update your configuration.${RESET}"
echo ""

if [ -f "$ENV_FILE" ]; then
  echo "  ${YELLOW}Existing .env found. Values will be used as defaults.${RESET}"
  echo ""
  # shellcheck disable=SC1090
  source "$ENV_FILE" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Section 1: Target Machine
# ---------------------------------------------------------------------------
section "1/6  Target Machine"

prompt HOSTNAME    "Hostname"                "${HOSTNAME:-my-server}"
prompt DISTRO      "Linux distribution"      "${DISTRO:-Ubuntu 24.04}"
prompt USERNAME    "SSH username"             "${USERNAME:-$(whoami)}"
prompt LAN_IP      "LAN IP address"           "${LAN_IP:-192.168.1.100}"
validate_ip "$LAN_IP"

echo ""
echo "  ${DIM}Hardware (used for agent config & documentation):${RESET}"
prompt GPU_MODEL   "GPU model"               "${GPU_MODEL:-RTX 4090}"
prompt GPU_VRAM    "GPU VRAM"                "${GPU_VRAM:-24GB}"
prompt CPU_MODEL   "CPU model"               "${CPU_MODEL:-AMD Ryzen 9 7950X}"
prompt RAM_SIZE    "Total RAM"               "${RAM_SIZE:-64GB}"

# ---------------------------------------------------------------------------
# Section 2: Remote Access
# ---------------------------------------------------------------------------
section "2/6  Remote Access"

prompt_yn USE_TAILSCALE "Use Tailscale VPN?" "${USE_TAILSCALE:-y}"
if [[ "$USE_TAILSCALE" == "y" ]]; then
  prompt TAILSCALE_IP "Tailscale IP" "${TAILSCALE_IP:-100.x.x.x}"
  validate_ip "$TAILSCALE_IP"
else
  TAILSCALE_IP=""
fi

prompt_yn USE_NAS "Use NAS / jump host?" "${USE_NAS:-n}"
if [[ "$USE_NAS" == "y" ]]; then
  prompt NAS_IP       "NAS / jump host IP"     "${NAS_IP:-192.168.1.200}"
  validate_ip "$NAS_IP"
  prompt NAS_SSH_PORT "NAS SSH port"           "${NAS_SSH_PORT:-22}"
else
  NAS_IP=""
  NAS_SSH_PORT="22"
fi

# ---------------------------------------------------------------------------
# Section 3: Services
# ---------------------------------------------------------------------------
section "3/6  Services"

echo "  ${DIM}Inference server (LM Studio, Ollama, vLLM, LocalAI, etc.):${RESET}"
prompt INFERENCE_TYPE "Inference server type" "${INFERENCE_TYPE:-lmstudio}"
prompt INFERENCE_PORT "Inference server port" "${INFERENCE_PORT:-1234}"
prompt GATEWAY_PORT   "OpenClaw Gateway port" "${GATEWAY_PORT:-18789}"
prompt MODEL_DIR      "Model directory"       "${MODEL_DIR:-/opt/models}"

prompt_yn USE_CONTAINERS "Use containers (Docker/Podman)?" "${USE_CONTAINERS:-y}"
if [[ "$USE_CONTAINERS" == "y" ]]; then
  prompt CONTAINER_RUNTIME "Container runtime" "${CONTAINER_RUNTIME:-docker}"
else
  CONTAINER_RUNTIME=""
fi

# ---------------------------------------------------------------------------
# Section 4: Agent Hierarchy
# ---------------------------------------------------------------------------
section "4/6  Agent Hierarchy"

echo "  ${DIM}Configure your primary cloud model and local model:${RESET}"
prompt PRIMARY_MODEL    "Primary cloud model"  "${PRIMARY_MODEL:-claude-sonnet-4}"
prompt LOCAL_MODEL      "Local model"          "${LOCAL_MODEL:-llama3-70b}"

echo ""
echo "  ${DIM}Agent names (used in configs and dispatch rules):${RESET}"
prompt AGENT_MAIN       "Orchestrator name (Tier 1)" "${AGENT_MAIN:-ops-commander}"
prompt AGENT_WORKER     "GPU worker name (Tier 3)"   "${AGENT_WORKER:-gpu-runner}"
prompt AGENT_RESEARCHER "Research agent name (Tier 3)" "${AGENT_RESEARCHER:-web-scout}"

# ---------------------------------------------------------------------------
# Section 5: Notifications
# ---------------------------------------------------------------------------
section "5/6  Notifications"

echo "  ${DIM}Choose how you want to receive alerts from agents:${RESET}"
echo "  ${DIM}Options: telegram, slack, email, none${RESET}"
prompt NOTIFY_CHANNEL "Notification channel" "${NOTIFY_CHANNEL:-telegram}"

case "$NOTIFY_CHANNEL" in
  telegram)
    prompt TELEGRAM_BOT     "Telegram bot token/handle" "${TELEGRAM_BOT:-@MyBot}"
    prompt TELEGRAM_USER_ID "Telegram user/chat ID"     "${TELEGRAM_USER_ID:-123456789}"
    ;;
  slack)
    prompt SLACK_WEBHOOK "Slack webhook URL" "${SLACK_WEBHOOK:-https://hooks.slack.com/...}"
    TELEGRAM_BOT="" TELEGRAM_USER_ID=""
    ;;
  email)
    prompt ALERT_EMAIL "Alert email address" "${ALERT_EMAIL:-alerts@example.com}"
    TELEGRAM_BOT="" TELEGRAM_USER_ID=""
    ;;
  *)
    TELEGRAM_BOT="" TELEGRAM_USER_ID=""
    ;;
esac

# ---------------------------------------------------------------------------
# Section 6: Identity
# ---------------------------------------------------------------------------
section "6/6  Identity"

prompt GITHUB_USER "GitHub username" "${GITHUB_USER:-myuser}"
prompt EMAIL       "Email address"   "${EMAIL:-user@example.com}"

# ---------------------------------------------------------------------------
# Write .env
# ---------------------------------------------------------------------------
banner "Writing Configuration"

cat > "$ENV_FILE" <<ENVEOF
# =============================================================================
# OpenClaw Governor Template -- Environment Configuration
# =============================================================================
# Generated by scripts/init.sh on $(date '+%Y-%m-%d %H:%M:%S')
# Re-run scripts/init.sh to update.
# =============================================================================

# --- Target Machine ---
HOSTNAME=$HOSTNAME
DISTRO="$DISTRO"
USERNAME=$USERNAME
LAN_IP=$LAN_IP
TAILSCALE_IP=$TAILSCALE_IP
NAS_IP=$NAS_IP
NAS_SSH_PORT=$NAS_SSH_PORT

# --- Hardware ---
GPU_MODEL="$GPU_MODEL"
GPU_VRAM=$GPU_VRAM
CPU_MODEL="$CPU_MODEL"
RAM_SIZE=$RAM_SIZE

# --- Agent Configuration ---
AGENT_MAIN=$AGENT_MAIN
AGENT_WORKER=$AGENT_WORKER
AGENT_RESEARCHER=$AGENT_RESEARCHER
PRIMARY_MODEL=$PRIMARY_MODEL
LOCAL_MODEL=$LOCAL_MODEL

# --- Ports ---
GATEWAY_PORT=$GATEWAY_PORT
INFERENCE_PORT=$INFERENCE_PORT

# --- Services ---
INFERENCE_TYPE=$INFERENCE_TYPE
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-}
MODEL_DIR=$MODEL_DIR

# --- Notifications ---
NOTIFY_CHANNEL=$NOTIFY_CHANNEL
TELEGRAM_BOT=$TELEGRAM_BOT
TELEGRAM_USER_ID=$TELEGRAM_USER_ID
SLACK_WEBHOOK=${SLACK_WEBHOOK:-}
ALERT_EMAIL=${ALERT_EMAIL:-}

# --- Identity ---
EMAIL=$EMAIL
GITHUB_USER=$GITHUB_USER
ENVEOF

echo "  ${GREEN}Wrote${RESET} $ENV_FILE"

# ---------------------------------------------------------------------------
# Replace placeholders across all template files
# ---------------------------------------------------------------------------
echo ""
echo "  ${CYAN}Replacing {{PLACEHOLDER}} values across template files...${RESET}"
echo ""

# Build replacement map: PLACEHOLDER -> VALUE
declare -A REPLACEMENTS=(
  [HOSTNAME]="$HOSTNAME"
  [DISTRO]="$DISTRO"
  [USERNAME]="$USERNAME"
  [LAN_IP]="$LAN_IP"
  [TAILSCALE_IP]="${TAILSCALE_IP:-100.x.x.x}"
  [NAS_IP]="${NAS_IP:-192.168.1.200}"
  [GPU_MODEL]="$GPU_MODEL"
  [GPU_VRAM]="$GPU_VRAM"
  [CPU_MODEL]="$CPU_MODEL"
  [RAM_SIZE]="$RAM_SIZE"
  [EMAIL]="$EMAIL"
  [TELEGRAM_BOT]="${TELEGRAM_BOT:-@MyBot}"
  [TELEGRAM_USER_ID]="${TELEGRAM_USER_ID:-123456789}"
  [GITHUB_USER]="$GITHUB_USER"
  [MODEL_DIR]="$MODEL_DIR"
  [GATEWAY_PORT]="$GATEWAY_PORT"
  [INFERENCE_PORT]="$INFERENCE_PORT"
  [AGENT_MAIN]="$AGENT_MAIN"
  [AGENT_WORKER]="$AGENT_WORKER"
  [AGENT_RESEARCHER]="$AGENT_RESEARCHER"
  [PRIMARY_MODEL]="$PRIMARY_MODEL"
  [LOCAL_MODEL]="$LOCAL_MODEL"
)

# Find all text files (excluding .git, .env, and this script)
file_count=0
replaced_count=0

while IFS= read -r -d '' file; do
  # Skip binary files
  if file "$file" | grep -q "text"; then
    changed=false
    for placeholder in "${!REPLACEMENTS[@]}"; do
      value="${REPLACEMENTS[$placeholder]}"
      # Use | as sed delimiter to handle / in paths
      if grep -q "{{${placeholder}}}" "$file" 2>/dev/null; then
        # Escape special chars for sed
        escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
        sed -i.bak "s|{{${placeholder}}}|${escaped_value}|g" "$file"
        rm -f "${file}.bak"
        changed=true
        ((replaced_count++))
      fi
    done
    if $changed; then
      ((file_count++))
      echo "  ${GREEN}Updated${RESET}  ${file#$REPO_DIR/}"
    fi
  fi
done < <(find "$REPO_DIR" -type f \
  -not -path '*/.git/*' \
  -not -path '*/.env' \
  -not -name 'init.sh' \
  -not -name '*.svg' \
  -print0 2>/dev/null)

# Handle SVG files separately (they use {{PLACEHOLDER}} too)
while IFS= read -r -d '' file; do
  changed=false
  for placeholder in "${!REPLACEMENTS[@]}"; do
    value="${REPLACEMENTS[$placeholder]}"
    if grep -q "{{${placeholder}}}" "$file" 2>/dev/null; then
      escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
      sed -i.bak "s|{{${placeholder}}}|${escaped_value}|g" "$file"
      rm -f "${file}.bak"
      changed=true
      ((replaced_count++))
    fi
  done
  if $changed; then
    ((file_count++))
    echo "  ${GREEN}Updated${RESET}  ${file#$REPO_DIR/}"
  fi
done < <(find "$REPO_DIR" -name '*.svg' -print0 2>/dev/null)

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
banner "Setup Complete"

echo "  ${BOLD}Configuration Summary${RESET}"
echo ""
echo "  ${CYAN}Target:${RESET}        $USERNAME@$HOSTNAME ($LAN_IP)"
echo "  ${CYAN}Distro:${RESET}        $DISTRO"
echo "  ${CYAN}Hardware:${RESET}      $GPU_MODEL ($GPU_VRAM) | $CPU_MODEL | $RAM_SIZE RAM"
echo "  ${CYAN}Gateway:${RESET}       port $GATEWAY_PORT"
echo "  ${CYAN}Inference:${RESET}     $INFERENCE_TYPE on port $INFERENCE_PORT"
echo "  ${CYAN}Models:${RESET}        Cloud: $PRIMARY_MODEL | Local: $LOCAL_MODEL"
echo "  ${CYAN}Agents:${RESET}        $AGENT_MAIN (T1) | $AGENT_WORKER (T3) | $AGENT_RESEARCHER (T3)"
echo "  ${CYAN}Notifications:${RESET} $NOTIFY_CHANNEL"
echo "  ${CYAN}Identity:${RESET}      $GITHUB_USER <$EMAIL>"
if [ -n "$TAILSCALE_IP" ] && [ "$TAILSCALE_IP" != "100.x.x.x" ]; then
  echo "  ${CYAN}Tailscale:${RESET}     $TAILSCALE_IP"
fi
if [ -n "$NAS_IP" ]; then
  echo "  ${CYAN}NAS/Jump:${RESET}      $NAS_IP:$NAS_SSH_PORT"
fi
echo ""
echo "  ${GREEN}$file_count files updated${RESET} with ${GREEN}$replaced_count placeholder replacements${RESET}"
echo ""
echo "  ${DIM}Next steps:${RESET}"
echo "    1. Review .env and adjust if needed"
echo "    2. SSH into your target machine: ssh $USERNAME@$LAN_IP"
echo "    3. Install OpenClaw on the target machine"
echo "    4. Start your first agent: $AGENT_MAIN"
echo ""
echo "  ${DIM}Run this script again anytime to update your configuration.${RESET}"
echo ""
