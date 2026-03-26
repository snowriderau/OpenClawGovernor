# FEAT: NemoClaw Enterprise Security Setup

## Summary

Enterprise security layer for OpenClaw agents using NVIDIA NemoClaw. Adds OpenShell sandboxing, Privacy Router, default-deny networking, and audit logging. Each agent runs in an isolated container with policy-gated egress — the architectural domain isolation model enforced at the infrastructure level.

## Status: Optional

NemoClaw is currently in alpha preview (March 2026). APIs and interfaces may change. Plain OpenClaw is production-ready and sufficient for most deployments. NemoClaw adds enterprise compliance features.

## Problem

Agents with external API access or sensitive data handling need stronger isolation than OpenClaw's built-in domain separation provides. Enterprise environments require audit trails, credential isolation, and policy-enforced network boundaries.

## Solution

NemoClaw layers NVIDIA's OpenShell sandbox runtime on top of OpenClaw:

1. **OpenShell containers** — each agent runs in filesystem-isolated sandbox (`/sandbox` + `/tmp` only)
2. **Default-deny networking** — every outbound request must be whitelisted by policy or approved by operator
3. **Privacy Router** — automatically routes PII/credentials/code to local Nemotron models, non-sensitive queries to cloud
4. **Inference Gateway** — hides API keys from agents entirely
5. **Audit logging** — full decision traces for compliance

## Architecture

```
Governor (Claude Code / any coding agent)
    │
    │ SSH
    ▼
┌─────────────────────────────────────────────┐
│  Target Machine                              │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │  NemoClaw Plugin (TypeScript CLI)     │   │
│  │  nemoclaw <name> create/connect/...   │   │
│  └──────────┬───────────────────────────┘   │
│             │                                │
│  ┌──────────▼───────────────────────────┐   │
│  │  NemoClaw Blueprint (Python)          │   │
│  │  Creates sandboxes, applies policies  │   │
│  └──────────┬───────────────────────────┘   │
│             │                                │
│  ┌──────────▼───────────────────────────┐   │
│  │  OpenShell Sandbox (per agent)        │   │
│  │  ┌─────────────────────────────────┐ │   │
│  │  │  OpenClaw Agent                  │ │   │
│  │  │  (same config, workspace files)  │ │   │
│  │  └─────────────────────────────────┘ │   │
│  │  Network: default-deny + policy      │   │
│  │  Filesystem: /sandbox + /tmp only    │   │
│  └──────────────────────────────────────┘   │
│             │                                │
│  ┌──────────▼───────────────────────────┐   │
│  │  Inference Gateway / Privacy Router   │   │
│  │  PII → Local Nemotron                 │   │
│  │  Non-sensitive → Cloud (Claude/GPT)   │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Acceptance Criteria

- [ ] NemoClaw installed on target machine
- [ ] OpenShell runtime installed and verified
- [ ] First sandbox created and agent responds inside it
- [ ] Network policy applied (default-deny + required egress whitelisted per agent domain)
- [ ] Privacy Router configured (local model for PII, cloud for non-sensitive)
- [ ] Inference credentials stored in gateway (not visible to agents inside sandbox)
- [ ] Audit logging producing decision traces
- [ ] Governor can create/destroy/manage sandboxes via SSH
- [ ] Per-agent sandbox policies match domain isolation rules from AGENT_REGISTRY.md:
  - Forge → GitHub + npm + Docker egress
  - Hermes → email provider egress only
  - Scout → web read-only egress
  - Bolt → no egress (already air-gapped)
  - Courier → NAS/storage egress only

## Rollback

```bash
# Destroy all sandboxes
nemoclaw <name> destroy  # for each sandbox

# Uninstall NemoClaw (leaves OpenClaw intact)
# OpenClaw agents continue running outside sandboxes
```

NemoClaw uninstall does not affect: Docker, Node.js, npm, Ollama, or your base OpenClaw installation.

## Dependencies

- OpenClaw (base) — must be installed and working first
- Docker — required for OpenShell containers
- Ollama (optional) — required only if using Privacy Router with local models

## References

- NemoClaw: github.com/NVIDIA/NemoClaw
- OpenShell: github.com/NVIDIA/OpenShell
- Policy presets: github.com/VoltAgent/awesome-nemoclaw
- OpenClaw: github.com/openclaw/openclaw
