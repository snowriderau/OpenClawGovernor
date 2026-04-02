#!/bin/bash
# =============================================================================
# OpenClaw Governor — Interactive Setup Script
# =============================================================================
# Asks for your environment values, writes .env, and replaces all {{PLACEHOLDER}}
# tokens across template files.
#
# IDEMPOTENT: Re-running sources your existing .env as defaults.
# Run again whenever you add new agents or change your network config.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colour helpers (graceful fallback if tput is unavailable)
# ---------------------------------------------------------------------------
if command -v tput &>/dev/null && tput colors &>/dev/null; then
  BOLD=$(tput bold)
  DIM=$(tput dim)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6)
  BLUE=$(tput setaf 4)
  RESET=$(tput sgr0)
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" CYAN="" BLUE="" RESET=""
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
header() { echo; echo "${BOLD}${CYAN}── $1 ${RESET}"; }
info()   { echo "  ${DIM}$1${RESET}"; }
ok()     { echo "  ${GREEN}✓${RESET} $1"; }
warn()   { echo "  ${YELLOW}!${RESET} $1"; }
err()    { echo "  ${RED}✗${RESET} $1"; }

ask() {
  # ask <var_name> <prompt> <default>
  local var="$1" prompt="$2" default="${3:-}"
  local current
  current="${!var:-${default}}"
  local display_default="${current:+${DIM}[${current}]${RESET}}"
  printf "  %s %s: " "${prompt}" "${display_default}"
  read -r input
  if [[ -n "$input" ]]; then
    printf -v "$var" '%s' "$input"
  elif [[ -n "$current" ]]; then
    printf -v "$var" '%s' "$current"
  else
    printf -v "$var" '%s' ""
  fi
}

ask_yn() {
  # ask_yn <prompt> — returns 0 for yes, 1 for no
  local prompt="$1"
  printf "  %s [y/N]: " "${prompt}"
  read -r input
  [[ "${input,,}" == "y" || "${input,,}" == "yes" ]]
}

validate_ip() {
  local ip="$1"
  [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

validate_nonempty() {
  [[ -n "${1:-}" ]]
}

# ---------------------------------------------------------------------------
# Load existing .env as defaults (idempotency)
# ---------------------------------------------------------------------------
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  set -a; source "$ENV_FILE"; set +a
  warn "Loaded existing .env — existing values shown as defaults."
fi

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
clear
echo
echo "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════╗${RESET}"
echo "${BOLD}${BLUE}║         OpenClaw Governor — Setup Wizard              ║${RESET}"
echo "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════╝${RESET}"
echo
echo "  This script configures your template by replacing all"
echo "  ${CYAN}{{PLACEHOLDER}}${RESET} tokens across docs, configs, and scripts."
echo
echo "  Press ${BOLD}Enter${RESET} to accept a default value shown in brackets."
echo

# ---------------------------------------------------------------------------
# Section 1: Machine identity
# ---------------------------------------------------------------------------
header "1. Machine Identity"

ask HOSTNAME    "Hostname of your machine (e.g. myserver)"  "${HOSTNAME:-my-linux-box}"
ask USERNAME    "Username on the machine"                    "${USERNAME:-$(whoami)}"

while true; do
  ask LAN_IP "LAN IP address of the machine" "${LAN_IP:-192.168.1.x}"
  if validate_ip "$LAN_IP"; then break
  else err "Invalid IP format. Try again."; fi
done

ask DISTRO      "OS distribution (e.g. Ubuntu 24.04, Pop!_OS)" "${DISTRO:-Ubuntu 24.04}"
ask OWNER_NAME  "Your name"                                     "${OWNER_NAME:-$(whoami)}"
ask TIMEZONE    "Timezone (e.g. America/New_York)"              "${TIMEZONE:-$(cat /etc/timezone 2>/dev/null || echo 'UTC')}"

# ---------------------------------------------------------------------------
# Section 2: Tailscale (optional)
# ---------------------------------------------------------------------------
header "2. Tailscale VPN (optional — skip with Enter)"
echo
info "Tailscale lets you reach your machine securely from anywhere."
echo
USE_TAILSCALE=false
if ask_yn "Are you using Tailscale?"; then
  USE_TAILSCALE=true
  while true; do
    ask TAILSCALE_IP "Tailscale IP" "${TAILSCALE_IP:-100.x.x.x}"
    if validate_ip "$TAILSCALE_IP"; then break
    else err "Invalid IP format. Try again."; fi
  done
fi

# ---------------------------------------------------------------------------
# Section 3: NAS / Network Storage (optional)
# ---------------------------------------------------------------------------
header "3. NAS / Network Storage (optional — skip with Enter)"
echo
USE_NAS=false
if ask_yn "Do you have a NAS or secondary storage machine?"; then
  USE_NAS=true
  while true; do
    ask NAS_IP "NAS IP address" "${NAS_IP:-192.168.1.x}"
    if validate_ip "$NAS_IP"; then break
    else err "Invalid IP format. Try again."; fi
  done
  ask NAS_SSH_PORT "NAS SSH port" "${NAS_SSH_PORT:-22}"
fi

# ---------------------------------------------------------------------------
# Section 4: SSH
# ---------------------------------------------------------------------------
header "4. SSH Key"

ask SSH_KEY_PATH "Path to SSH private key" "${SSH_KEY_PATH:-~/.ssh/id_ed25519}"

# ---------------------------------------------------------------------------
# Section 5: Hardware / Inference
# ---------------------------------------------------------------------------
header "5. Hardware and Inference"

ask GPU           "GPU model (e.g. RTX 4090)"             "${GPU:-RTX 4090}"
ask INFERENCE_PORT "Local inference port (LM Studio / Ollama)" "${INFERENCE_PORT:-1234}"
ask GATEWAY_PORT  "Openclaw gateway port"                  "${GATEWAY_PORT:-18789}"
ask MODEL_DIR     "Model storage directory"                "${MODEL_DIR:-/opt/models}"
ask PROJECTS_DIR  "Projects directory on target machine"   "${PROJECTS_DIR:-/home/${USERNAME}/projects}"

# ---------------------------------------------------------------------------
# Section 6: Models
# ---------------------------------------------------------------------------
header "6. Model Configuration"
echo
info "PRIMARY_MODEL: used by Atlas, Conductor, Forge, Hermes (cloud)"
info "LOCAL_MODEL:   used by Bolt, Courier (local inference — data stays on machine)"
info "SECONDARY_MODEL: used by Scout, Sentinel (lighter cloud model)"
echo

ask PRIMARY_MODEL   "Primary cloud model"   "${PRIMARY_MODEL:-claude-opus-4-5}"
ask LOCAL_MODEL     "Local model ID"        "${LOCAL_MODEL:-qwen3.5-35b-a3b}"
ask SECONDARY_MODEL "Secondary cloud model" "${SECONDARY_MODEL:-claude-haiku-4-5}"

# ---------------------------------------------------------------------------
# Section 7: Agent names
# ---------------------------------------------------------------------------
header "7. Agent Configuration"
echo
info "AGENT_MAIN is the name of your orchestrator agent (Atlas by default)."
echo

ask AGENT_MAIN "Orchestrator agent name" "${AGENT_MAIN:-Atlas}"

# ---------------------------------------------------------------------------
# Section 8: Notification channel (Telegram optional)
# ---------------------------------------------------------------------------
header "8. Notification Channel — Telegram (optional)"
echo
info "Only Atlas sends to the notification channel. All other agents escalate."
echo
USE_TELEGRAM=false
if ask_yn "Are you using Telegram for notifications?"; then
  USE_TELEGRAM=true
  ask TELEGRAM_BOT_TOKEN "Telegram bot token (from @BotFather)" "${TELEGRAM_BOT_TOKEN:-}"
  ask TELEGRAM_USER_ID   "Your Telegram user ID (integer)"       "${TELEGRAM_USER_ID:-}"
  ask TELEGRAM_BOT       "Bot username (e.g. @MyAgentBot)"       "${TELEGRAM_BOT:-@MyAgentBot}"
fi

# ---------------------------------------------------------------------------
# Section 9: GitHub
# ---------------------------------------------------------------------------
header "9. GitHub"

ask GITHUB_USER "GitHub username" "${GITHUB_USER:-your-github-username}"

# ---------------------------------------------------------------------------
# Section 10: Email (optional)
# ---------------------------------------------------------------------------
header "10. Email — for Hermes agent (optional)"
echo
USE_EMAIL=false
if ask_yn "Will you be using the Hermes email agent?"; then
  USE_EMAIL=true
  ask EMAIL "Agent email address (OAuth account)" "${EMAIL:-agent@example.com}"
fi

# ---------------------------------------------------------------------------
# Section 11: NemoClaw Enterprise Security (optional)
# ---------------------------------------------------------------------------
header "11. NemoClaw Enterprise Security (optional)"
echo
info "NemoClaw adds NVIDIA OpenShell sandboxing, Privacy Router, and audit"
info "logging on top of OpenClaw. Agents run in isolated containers with"
info "policy-gated network access. Currently in alpha preview."
echo
USE_NEMOCLAW=false
if ask_yn "Will you be using NemoClaw for enterprise agent security?"; then
  USE_NEMOCLAW=true
  ask NEMOCLAW_REPO "NemoClaw repo path" "${NEMOCLAW_REPO:-\$HOME/NemoClaw}"
  info "NemoClaw repos: github.com/NVIDIA/NemoClaw + github.com/NVIDIA/OpenShell"
fi

# ---------------------------------------------------------------------------
# Section 12: OpenClaw Repository Locations
# ---------------------------------------------------------------------------
header "12. OpenClaw Repository Locations"
echo
info "Where OpenClaw code lives — used by the Governor for reference."
echo
ask OPENCLAW_REPO "OpenClaw repo path (local clone)" "${OPENCLAW_REPO:-}"
if [[ -z "${OPENCLAW_REPO:-}" ]]; then
  info "Skipped — Governor will use docs.openclaw.ai for reference."
fi

ask OPENCLAW_PLUGIN_PATH "OpenClaw plugins directory" "${OPENCLAW_PLUGIN_PATH:-/home/${USERNAME}/.openclaw/plugin}"

# ---------------------------------------------------------------------------
# Section 13: Governor Agent
# ---------------------------------------------------------------------------
header "13. Governor Agent"
echo
info "Which coding agent will you use as the Governor?"
info "  1) Claude Code       — reads CLAUDE.md automatically"
info "  2) Codex             — reads CLAUDE.md automatically"
info "  3) Antigravity       — load folder as workspace"
info "  4) Cursor            — add CLAUDE.md to Rules for AI"
info "  5) Windsurf          — reads CLAUDE.md automatically"
info "  6) Other"
echo
ask GOVERNOR_AGENT "Governor agent" "${GOVERNOR_AGENT:-Claude Code}"

# ---------------------------------------------------------------------------
# Write .env file
# ---------------------------------------------------------------------------
header "Writing .env"

cat > "$ENV_FILE" <<EOF
# =============================================================================
# OpenClaw Governor — Environment Configuration
# Generated by scripts/init.sh — $(date +"%Y-%m-%d %H:%M:%S")
# =============================================================================
# DO NOT commit this file. It is listed in .gitignore.
# Re-run scripts/init.sh to update values.

# Machine identity
HOSTNAME="${HOSTNAME}"
USERNAME="${USERNAME}"
LAN_IP="${LAN_IP}"
DISTRO="${DISTRO}"
OWNER_NAME="${OWNER_NAME}"
TIMEZONE="${TIMEZONE}"

# Tailscale VPN
TAILSCALE_IP="${TAILSCALE_IP:-}"

# NAS / Network storage
NAS_IP="${NAS_IP:-}"
NAS_SSH_PORT="${NAS_SSH_PORT:-22}"

# SSH
SSH_KEY_PATH="${SSH_KEY_PATH}"

# Hardware
GPU="${GPU}"

# Inference ports
INFERENCE_PORT="${INFERENCE_PORT}"
GATEWAY_PORT="${GATEWAY_PORT}"

# Directories
MODEL_DIR="${MODEL_DIR}"
PROJECTS_DIR="${PROJECTS_DIR}"

# Models
PRIMARY_MODEL="${PRIMARY_MODEL}"
LOCAL_MODEL="${LOCAL_MODEL}"
SECONDARY_MODEL="${SECONDARY_MODEL}"

# Agent names
AGENT_MAIN="${AGENT_MAIN}"

# Telegram
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_USER_ID="${TELEGRAM_USER_ID:-}"
TELEGRAM_BOT="${TELEGRAM_BOT:-}"

# GitHub
GITHUB_USER="${GITHUB_USER}"

# Email
EMAIL="${EMAIL:-}"

# NemoClaw (enterprise security layer)
USE_NEMOCLAW="${USE_NEMOCLAW}"
NEMOCLAW_REPO="${NEMOCLAW_REPO:-}"

# OpenClaw repo location
OPENCLAW_REPO="${OPENCLAW_REPO:-}"
OPENCLAW_PLUGIN_PATH="${OPENCLAW_PLUGIN_PATH:-}"

# Governor agent
GOVERNOR_AGENT="${GOVERNOR_AGENT}"
EOF

ok ".env written to ${ENV_FILE}"

# ---------------------------------------------------------------------------
# Template replacement — sed across all template files
# ---------------------------------------------------------------------------
header "Applying placeholder replacements"
echo
info "Replacing {{PLACEHOLDER}} tokens in: *.md, *.svg, *.json, *.sh"
echo

REPLACEMENT_COUNT=0

do_replace() {
  local placeholder="$1"
  local value="$2"
  local file_patterns=("${REPO_ROOT}"/**/*.md "${REPO_ROOT}"/**/*.svg "${REPO_ROOT}"/**/*.json "${REPO_ROOT}"/**/*.sh)

  # Use find for safety (handles spaces, avoids _source/ contamination)
  while IFS= read -r -d '' file; do
    # Skip _source/ directory — source reference files should not be modified
    [[ "$file" == *"/_source/"* ]] && continue
    # Skip this script itself
    [[ "$file" == "${BASH_SOURCE[0]}" ]] && continue
    # Skip .env and .env.example
    [[ "$(basename "$file")" == ".env" ]] && continue

    if grep -qF "{{${placeholder}}}" "$file" 2>/dev/null; then
      # Escape forward slashes in the value for sed
      local escaped_value
      escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
      sed -i.bak "s|{{${placeholder}}}|${escaped_value}|g" "$file"
      rm -f "${file}.bak"
      ((REPLACEMENT_COUNT++))
    fi
  done < <(find "$REPO_ROOT" \( -name "*.md" -o -name "*.svg" -o -name "*.json" -o -name "*.sh" \) -not -path "*/_source/*" -print0 2>/dev/null)
}

# NOTE: Not all {{PLACEHOLDER}} tokens are replaced by this script.
# Tokens like {{CPU}}, {{RAM}}, {{COMPANY}}, {{NAS_HOST}} etc. are
# context-specific — the Governor populates them as it discovers
# your environment during its first SSH session.

# Core identity replacements
do_replace "HOSTNAME"          "$HOSTNAME"
do_replace "USERNAME"          "$USERNAME"
do_replace "LAN_IP"            "$LAN_IP"
do_replace "DISTRO"            "$DISTRO"
do_replace "OWNER_NAME"        "$OWNER_NAME"
do_replace "TIMEZONE"          "$TIMEZONE"
do_replace "GPU"               "$GPU"
do_replace "INFERENCE_PORT"    "$INFERENCE_PORT"
do_replace "GATEWAY_PORT"      "$GATEWAY_PORT"
do_replace "MODEL_DIR"         "$MODEL_DIR"
do_replace "PROJECTS_DIR"      "$PROJECTS_DIR"
do_replace "PRIMARY_MODEL"     "$PRIMARY_MODEL"
do_replace "LOCAL_MODEL"       "$LOCAL_MODEL"
do_replace "SECONDARY_MODEL"   "$SECONDARY_MODEL"
do_replace "AGENT_MAIN"        "$AGENT_MAIN"
do_replace "GITHUB_USER"       "$GITHUB_USER"

# Optional replacements (only if provided)
if [[ "$USE_TAILSCALE" == true && -n "${TAILSCALE_IP:-}" ]]; then
  do_replace "TAILSCALE_IP" "$TAILSCALE_IP"
fi

if [[ "$USE_NAS" == true ]]; then
  [[ -n "${NAS_IP:-}" ]]       && do_replace "NAS_IP"       "$NAS_IP"
  [[ -n "${NAS_SSH_PORT:-}" ]] && do_replace "NAS_SSH_PORT" "$NAS_SSH_PORT"
fi

if [[ "$USE_TELEGRAM" == true ]]; then
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] && do_replace "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
  [[ -n "${TELEGRAM_USER_ID:-}" ]]   && do_replace "TELEGRAM_USER_ID"   "$TELEGRAM_USER_ID"
  [[ -n "${TELEGRAM_BOT:-}" ]]       && do_replace "TELEGRAM_BOT"        "$TELEGRAM_BOT"
fi

if [[ "$USE_EMAIL" == true && -n "${EMAIL:-}" ]]; then
  do_replace "EMAIL" "$EMAIL"
fi

# SSH key path
do_replace "SSH_KEY_PATH" "$SSH_KEY_PATH"

ok "Replaced tokens in ${REPLACEMENT_COUNT} file(s)."

# ---------------------------------------------------------------------------
# Activate Governor persona
# ---------------------------------------------------------------------------
header "Activating Governor mode"

if [[ -f "${REPO_ROOT}/CLAUDE_template.md" ]]; then
  # Preserve the template-editing CLAUDE.md so it's still accessible
  cp "${REPO_ROOT}/CLAUDE.md" "${REPO_ROOT}/CLAUDE_dev.md"
  # Activate Governor persona (token replacement already applied to CLAUDE_template.md)
  cp "${REPO_ROOT}/CLAUDE_template.md" "${REPO_ROOT}/CLAUDE.md"
  ok "CLAUDE.md now contains Governor instructions"
  info "Template-editing instructions saved as CLAUDE_dev.md"
else
  warn "CLAUDE_template.md not found — CLAUDE.md unchanged"
fi

# ---------------------------------------------------------------------------
# Deploy spec-first-starter and PM workspace to target machine
# ---------------------------------------------------------------------------
header "Deploying project templates to target machine"

SSH_TARGET="${USERNAME}@${HOSTNAME}"
if [[ -n "${TAILSCALE_IP:-}" ]]; then
  SSH_TARGET="${USERNAME}@${TAILSCALE_IP}"
elif [[ -n "${LAN_IP:-}" ]]; then
  SSH_TARGET="${USERNAME}@${LAN_IP}"
fi

SSH_CMD="ssh"
if [[ -n "${SSH_KEY_PATH:-}" ]]; then
  SSH_CMD="ssh -i ${SSH_KEY_PATH}"
fi

# Test SSH connectivity
if $SSH_CMD "$SSH_TARGET" "echo ok" &>/dev/null; then
  ok "SSH connection to ${SSH_TARGET} verified"

  # Create projects directory if it doesn't exist
  $SSH_CMD "$SSH_TARGET" "mkdir -p '${PROJECTS_DIR}'" 2>/dev/null
  ok "Projects directory: ${PROJECTS_DIR}"

  # Deploy spec-first-starter template
  if [[ -d "${REPO_ROOT}/docs/project-examples/spec-first-starter" ]]; then
    if $SSH_CMD "$SSH_TARGET" "test -d '${PROJECTS_DIR}/spec-first-starter'" 2>/dev/null; then
      info "spec-first-starter already exists on target — skipping (delete to re-deploy)"
    else
      rsync -az --exclude='.git' \
        "${REPO_ROOT}/docs/project-examples/spec-first-starter/" \
        "${SSH_TARGET}:${PROJECTS_DIR}/spec-first-starter/"
      ok "Deployed spec-first-starter template to ${PROJECTS_DIR}/spec-first-starter/"
    fi
  fi

  # Deploy PM workspace scaffold
  if $SSH_CMD "$SSH_TARGET" "test -d '${PROJECTS_DIR}/_pm'" 2>/dev/null; then
    info "PM workspace already exists on target — skipping"
  else
    $SSH_CMD "$SSH_TARGET" "mkdir -p '${PROJECTS_DIR}/_pm/.agent/memory'"
    # Copy PM workspace files from examples
    if [[ -d "${REPO_ROOT}/docs/workspace-examples/director-pm" ]]; then
      rsync -az \
        "${REPO_ROOT}/docs/workspace-examples/director-pm/" \
        "${SSH_TARGET}:${PROJECTS_DIR}/_pm/"
      ok "Deployed PM workspace to ${PROJECTS_DIR}/_pm/"
    fi
  fi

  # Deploy guard plugins to ~/.openclaw/plugins/
  if [[ -d "${REPO_ROOT}/plugins" ]]; then
    header "Deploying guard plugins"
    $SSH_CMD "$SSH_TARGET" "mkdir -p ~/.openclaw/plugins" 2>/dev/null

    for plugin_dir in "${REPO_ROOT}"/plugins/*/; do
      plugin_name="$(basename "$plugin_dir")"
      # Skip README.md (not a plugin directory)
      [[ ! -f "${plugin_dir}/package.json" ]] && continue

      if $SSH_CMD "$SSH_TARGET" "test -f ~/.openclaw/plugins/${plugin_name}/package.json" 2>/dev/null; then
        info "${plugin_name} already deployed — skipping (delete to re-deploy)"
      else
        rsync -az --exclude='test' \
          "${plugin_dir}" \
          "${SSH_TARGET}:~/.openclaw/plugins/${plugin_name}/"
        ok "Deployed ${plugin_name} to ~/.openclaw/plugins/${plugin_name}/"
      fi
    done

    info "Plugins deployed. Register them in openclaw.json plugins.entries."
    info "See plugins/README.md for config examples."
  fi
else
  warn "Could not SSH to ${SSH_TARGET} — skipping remote deployment"
  info "You can deploy templates manually later. See INSTALL.md Step 6."
fi

# ---------------------------------------------------------------------------
# Post-setup checks
# ---------------------------------------------------------------------------
header "Post-setup checks"

# Check for any remaining unreplaced placeholders (informational only)
REMAINING=$(grep -r --include="*.md" --include="*.svg" --include="*.json" \
  -o '{{[A-Z_]*}}' "$REPO_ROOT" \
  --exclude-dir=_source \
  --exclude-dir=".git" 2>/dev/null | sort -u || true)

if [[ -n "$REMAINING" ]]; then
  warn "The following placeholders were not replaced (optional sections skipped):"
  echo "$REMAINING" | while read -r p; do echo "    ${DIM}${p}${RESET}"; done
  echo
  info "This is expected for optional features you chose not to configure."
  info "Re-run this script to fill them in later."
fi

# Check if .env is gitignored
if grep -q "^\.env$" "${REPO_ROOT}/.gitignore" 2>/dev/null; then
  ok ".env is listed in .gitignore"
else
  warn ".env is NOT in .gitignore — add it before committing!"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
header "Setup complete"
echo
echo "  ${BOLD}Machine:${RESET}   ${USERNAME}@${HOSTNAME}  (LAN: ${LAN_IP})"
if [[ "$USE_TAILSCALE" == true ]]; then
  echo "  ${BOLD}Tailscale:${RESET} ${TAILSCALE_IP}"
fi
if [[ "$USE_NAS" == true ]]; then
  echo "  ${BOLD}NAS:${RESET}       ${NAS_IP}:${NAS_SSH_PORT}"
fi
echo "  ${BOLD}GPU:${RESET}       ${GPU}"
echo "  ${BOLD}Models:${RESET}    ${PRIMARY_MODEL} (cloud) | ${LOCAL_MODEL} (local)"
echo "  ${BOLD}Ports:${RESET}     inference :${INFERENCE_PORT}  gateway :${GATEWAY_PORT}"
echo "  ${BOLD}Governor:${RESET}  ${GOVERNOR_AGENT}"
echo "  ${BOLD}Projects:${RESET}  ${PROJECTS_DIR}"
if [[ "$USE_TELEGRAM" == true ]]; then
  echo "  ${BOLD}Telegram:${RESET}  ${TELEGRAM_BOT} → ${TELEGRAM_USER_ID}"
fi
echo

echo "  ${BOLD}Next steps:${RESET}"
echo "  1. Review .env and verify all values are correct"
echo "  2. Read ${CYAN}INSTALL.md${RESET} for the full setup walkthrough"
echo

# Tailored Governor launch instructions
case "${GOVERNOR_AGENT}" in
  "Claude Code"|"claude code"|"claude")
    echo "  3. Launch your Governor:"
    echo "     ${CYAN}cd $(basename "$REPO_ROOT") && claude${RESET}"
    ;;
  "Codex"|"codex")
    echo "  3. Launch your Governor:"
    echo "     ${CYAN}cd $(basename "$REPO_ROOT") && codex${RESET}"
    ;;
  "Antigravity"|"antigravity")
    echo "  3. Open Antigravity and load this folder as your workspace"
    ;;
  "Cursor"|"cursor")
    echo "  3. Open this folder in Cursor"
    echo "     Add CLAUDE.md to Settings > Rules for AI"
    ;;
  "Windsurf"|"windsurf")
    echo "  3. Open this folder in Windsurf"
    ;;
  *)
    echo "  3. Point your coding agent at this repo and ensure it reads CLAUDE.md"
    ;;
esac

echo
echo "  4. Tell it: ${CYAN}Read INSTALL.md and set up my agent fleet${RESET}"
echo
echo "  ${BOLD}Core workflow commands:${RESET}"
echo "  /new-feature <name>  — Write spec, get approval, implement, finalize"
echo "  /create-task <task>  — Execute a task against an existing feature"
echo "  /update-feature      — Modify an existing feature"
echo "  /agent-improvement   — Audit and fix the agent fleet"
echo
echo "  ${BOLD}Maintenance commands:${RESET}"
echo "  /security-audit      — Full security review"
echo
