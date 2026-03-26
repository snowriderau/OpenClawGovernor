---
name: nemoclaw-config
description: Reference guide for configuring NemoClaw enterprise security layer on top of OpenClaw. Auto-loads when tasks involve NemoClaw setup, sandbox policies, Privacy Router, or enterprise agent security.
user-invocable: false
---

# NemoClaw Configuration Guide

**The Governor loads this when working with NemoClaw — the enterprise security layer for OpenClaw.** NemoClaw does NOT replace OpenClaw. It adds NVIDIA OpenShell sandboxing, Privacy Router, and audit logging on top.

**NemoClaw = OpenClaw + OpenShell (sandbox) + Nemotron (local models) + Privacy Router**

## What NemoClaw Adds

| Capability | Plain OpenClaw | With NemoClaw |
|------------|---------------|---------------|
| Filesystem access | Full system | `/sandbox` and `/tmp` only |
| Network access | Open | Default-deny, policy-gated egress |
| Inference credentials | Agent-visible | Hidden behind Inference Gateway |
| PII handling | Manual routing | Auto-routed to local models via Privacy Router |
| Audit logging | None built-in | Full decision traces and access logs |
| Operator review | None | Blocked requests surface in OpenShell TUI |

## Key Paths

| What | Where |
|------|-------|
| Config | `~/.nemoclaw/config.yaml` |
| Credentials | `~/.nemoclaw/credentials.json` |
| Policy presets | `nemoclaw-blueprint/policies/presets/` |
| OpenShell binary | `~/.openshell/bin/openshell` |
| NemoClaw repo | `{{NEMOCLAW_REPO}}` |

## CLI Commands

### Sandbox Lifecycle

```bash
# Create a new sandbox for an agent
nemoclaw <name> create

# Connect to a running sandbox
nemoclaw <name> connect

# Check sandbox status
nemoclaw <name> status

# View sandbox logs (audit trail)
nemoclaw <name> logs

# Remove a sandbox
nemoclaw <name> destroy
```

### Policy Management

```bash
# Hot-reload network policy (no sandbox restart needed)
openshell policy set <policy-file>

# Show current active policy
openshell policy show
```

### Inside a Sandbox — OpenClaw Works Normally

```bash
openclaw agent --agent main -m "hello"
openclaw agents list --json
openclaw config validate
```

## Installation

```bash
# Standard install (any machine with internet)
curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash

# Manual install (for air-gapped or custom setups)
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh
git clone https://github.com/NVIDIA/NemoClaw.git
cd NemoClaw && ./install.sh

# Add local inference (optional — enables Privacy Router local routing)
ollama pull nemotron-3-super:120b
```

## Privacy Router

The Privacy Router automatically classifies query sensitivity and routes accordingly:

| Data Type | Route | Why |
|-----------|-------|-----|
| PII, credentials, private keys | Local Nemotron | Data never leaves the machine |
| Code with proprietary logic | Local Nemotron | IP protection |
| Financial data | Local Nemotron | Compliance |
| General reasoning, research | Cloud (Claude, GPT, etc.) | Better capability |
| Non-sensitive tool use | Cloud | Cost/speed tradeoff |

Configure in `~/.nemoclaw/config.yaml`:

```yaml
privacy_router:
  local_provider: ollama
  local_model: nemotron-3-super:120b
  cloud_providers:
    - anthropic
    - openai
  routing_rules:
    - pattern: "pii|credential|password|key|token"
      route: local
    - pattern: "code|source|proprietary"
      route: local
    - default: cloud
```

## Policy Presets (27+ available)

NemoClaw ships with pre-built network policies for common services:

**Development:** PyPI, npm, Docker Hub, GitHub, GitLab, Homebrew
**Communication:** Slack, Discord, Telegram, Microsoft Teams
**Cloud:** AWS, GCP, Azure, Vercel, Netlify, Cloudflare
**Business:** Jira, HubSpot, Salesforce, Notion, Linear
**AI:** OpenAI, Anthropic, NVIDIA Endpoints, Ollama (local)

Apply a preset:
```bash
openshell policy set policies/presets/slack.yaml
```

Combine presets for an agent that needs multiple services:
```bash
# Merge GitHub + Slack + AWS for a DevOps agent
openshell policy merge policies/presets/github.yaml policies/presets/slack.yaml policies/presets/aws.yaml > policies/devops-agent.yaml
openshell policy set policies/devops-agent.yaml
```

## When to Use NemoClaw vs Plain OpenClaw

| Scenario | Recommendation |
|----------|---------------|
| Development / prototyping | Plain OpenClaw — less friction |
| Internal agents, trusted network | Plain OpenClaw |
| Agents with external API access | NemoClaw — policy-gated egress |
| Agents handling sensitive data | NemoClaw — Privacy Router + audit |
| Enterprise / compliance requirements | NemoClaw — audit trails, isolation |
| Mixed fleet | Both — sandbox sensitive agents, leave internal ones plain |

## Hardware Requirements

| Setup | CPU | RAM | VRAM | Disk |
|-------|-----|-----|------|------|
| Cloud routing only | 4+ vCPU | 8 GB | None | 20 GB |
| Nemotron Nano (local) | 4+ vCPU | 16 GB | 8 GB+ | 30 GB |
| Nemotron Super (full local) | 8+ vCPU | 32 GB | 48 GB+ | 100 GB |
| macOS Apple Silicon | Any M-series | 16 GB | Unified | 30 GB |

macOS requires Xcode Command Line Tools.

## Integration with Governor Template

The Governor manages NemoClaw alongside OpenClaw. When NemoClaw is enabled:

1. **Governor creates sandboxes** for agents that need enterprise security
2. **Governor writes policy files** based on each agent's domain (e.g., Hermes gets email-only egress, Forge gets GitHub + npm + Docker)
3. **Governor audits sandbox logs** alongside regular `/agent-improvement` cycles
4. **Plain OpenClaw agents** (dev/internal) continue running outside sandboxes
5. **Per-agent sandbox policies** map to the domain isolation model — each sandbox enforces what IDENTITY.md declares

### Example: Mixed Fleet

```
Atlas (orchestrator)    → Plain OpenClaw (internal coordination only)
Forge (engineer)        → NemoClaw sandbox (GitHub + npm + Docker egress)
Hermes (email)          → NemoClaw sandbox (email provider egress only)
Bolt (local compute)    → Plain OpenClaw (already air-gapped by design)
Scout (researcher)      → NemoClaw sandbox (web read-only egress)
```

## Learnings & Gotchas

1. **NemoClaw is alpha (March 2026)** — APIs may change. Don't build hard dependencies on internal interfaces.
2. **Filesystem policies lock at sandbox creation** — plan your mounts before creating. You can't add new mounts to a running sandbox.
3. **Network policies CAN be hot-reloaded** — `openshell policy set <file>` works without restart.
4. **One sandbox per agent** — each agent in the fleet should get its own sandbox for proper isolation.
5. **Governor manages sandboxes** — users never touch policy files directly. The Governor writes them based on the agent's declared domain.
6. **Uninstalling NemoClaw is clean** — removes only NemoClaw artifacts. Docker, Node.js, npm, Ollama, and your base OpenClaw install are untouched.
7. **Privacy Router needs a local model** — if you enable PII routing, you need Ollama (or LM Studio) running with a Nemotron model loaded.
8. **Audit logs are the killer feature** — for enterprise compliance, the full decision trace is what auditors want to see.

## Repos

| Repo | URL |
|------|-----|
| NemoClaw | github.com/NVIDIA/NemoClaw |
| OpenShell (sandbox runtime) | github.com/NVIDIA/OpenShell |
| OpenClaw (base) | github.com/openclaw/openclaw |
| Community presets | github.com/VoltAgent/awesome-nemoclaw |
