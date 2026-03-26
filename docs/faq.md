# OpenClaw Governor -- Frequently Asked Questions

---

### What is OpenClaw?

OpenClaw is a framework for running AI agents on Linux machines. It provides a gateway server that manages agent lifecycle, inter-agent communication, tool access, and task dispatch. Think of it as an operating system layer for AI agents -- it handles the plumbing so each agent can focus on its job. The gateway exposes an API (default port `{{GATEWAY_PORT}}`) that agents and external tools (like Claude Code) use to interact with the system.

---

### What is the Governor pattern?

The Governor pattern separates oversight from execution by running the management layer on a different machine than the agents themselves. Claude Code runs on your Mac or laptop as the "Governor." It connects to your Linux server via SSH and monitors, verifies, and unblocks the OpenClaw agents running there. The Governor never writes application code -- it writes specs, reviews output, and ensures agents are doing the right thing. This separation provides isolation, auditability, and a clean context window for oversight tasks.

---

### Do I need a separate machine for the Governor?

Strongly recommended, but not strictly required. You could run everything on a single machine, but you lose the key benefits: isolation (a misbehaving agent can't affect your workstation), clean separation of concerns (the Governor repo stays focused on oversight), and the natural audit boundary that SSH provides. In practice, the Governor runs on whatever machine you use Claude Code on -- typically a Mac or laptop -- while the agents run on a Linux server, home lab, or cloud VM.

---

### What Linux distros are supported?

Any modern Linux distribution works. The template is tested primarily on Ubuntu 22.04/24.04 and Debian 12, but there is nothing distribution-specific in the setup. You need SSH access, a shell (bash or zsh), and the ability to install packages. If you use a different distribution (Fedora, Arch, NixOS), you may need to adjust package manager commands in the setup scripts, but the agent architecture and Governor workflow are identical.

---

### Can I use Ollama instead of LM Studio?

Yes. The template uses `{{INFERENCE_PORT}}` as a placeholder for whatever inference server you run. Both LM Studio and Ollama expose OpenAI-compatible APIs, so agents interact with them the same way. During `scripts/init.sh` setup, you'll be asked which inference server you use. The only difference is the startup commands and model management (LM Studio uses a GUI, Ollama uses CLI). vLLM and LocalAI are also supported -- anything that serves an OpenAI-compatible endpoint works.

---

### How many agents do I need?

Start with two: `ops-commander` (Tier 1 orchestrator) and one worker. Add agents only when you identify a concrete, recurring need that existing agents cannot cover efficiently. For a typical home lab or small server, three to four agents (orchestrator + security auditor + one or two workers) covers most use cases. The full seven-agent hierarchy in the template is a reference architecture, not a minimum requirement. Every additional agent adds coordination overhead, so only add them when the benefit clearly outweighs the complexity.

---

### How do agents communicate?

Agents communicate through the OpenClaw Gateway. The gateway manages message routing, task dispatch, and result collection. When `ops-commander` needs to assign work to `gpu-runner`, it sends a dispatch message through the gateway API. Results flow back the same way. Agents do not communicate directly with each other -- all communication is mediated by the gateway, which enforces the tier hierarchy (Tier 1 can dispatch to Tier 2 and 3, Tier 2 can dispatch to Tier 3, Tier 3 cannot dispatch). This prevents circular dependencies and makes the communication flow auditable.

---

### What happens if an agent fails?

Each agent is configured with heartbeat monitoring. When `ops-commander` misses two consecutive heartbeats from an agent, it investigates: checks the agent's process status, reviews recent logs, and attempts a restart. If the restart succeeds, normal operation resumes and the event is logged. If the restart fails, `ops-commander` escalates to the human operator via `alert-relay` (Telegram/Slack/email notification). The system is designed for graceful degradation -- if a Tier 3 worker goes down, the rest of the system continues operating. If `ops-commander` itself fails, the OpenClaw gateway has its own watchdog process that attempts recovery.

---

### How do I add a new agent?

1. Decide which tier the agent belongs to (Tier 2 director or Tier 3 worker).
2. Write a spec in `specs/` describing the agent's purpose, tool access, model, and responsibilities.
3. Create the agent configuration on the target machine through `ops-commander`.
4. Define which tools the agent can access (principle of least privilege).
5. Configure heartbeat monitoring.
6. Update the dispatch rules so `ops-commander` (and Tier 2 directors, if applicable) knows how to assign work to the new agent.
7. Test by dispatching a simple task and verifying the result.

The architecture diagram in `docs/architecture-diagram.svg` shows the extensibility points marked with "+ Add your agents."

---

### How does the security audit work?

The security audit is performed by `sec-sentinel` (Tier 2 Security Auditor). On initial setup, it runs a comprehensive baseline scan covering: open ports, running services, firewall configuration, SSH hardening, user permissions, installed packages with known CVEs, file permissions, and cron jobs. The results are stored in `audit_logs/`. Ongoing audits run on a weekly rotation: Week 1 checks packages/CVEs, Week 2 reviews access controls, Week 3 scans network exposure, Week 4 reviews logs for anomalies. Each audit produces a report that the Governor reviews. Critical findings trigger immediate notification via `alert-relay`.

---

### What's a spec and why do I need one?

A spec is a structured document that describes what you want to change, why, how, and what success looks like. The template includes `specs/_TEMPLATE_spec.md` as a starting point. Specs matter because AI agents execute exactly what you ask for -- and vague requests produce vague results. A spec that says "set up monitoring" will get you something generic. A spec that defines specific endpoints, intervals, thresholds, and alert channels will get you exactly what you need. Specs also create an audit trail: months later, you can trace any configuration back to the spec that requested it and understand the reasoning behind it.

---

### Can I use this without Claude Code?

The Governor pattern is designed around Claude Code as the oversight tool, but the underlying concepts apply to any setup where you remotely manage AI agents via SSH. You could adapt the pattern to use Cursor, Aider, or another AI coding tool as the Governor. However, the template's workflows, slash commands, and CLAUDE.md configuration are specifically written for Claude Code. If you use a different tool, you'll need to adapt the workflow layer while keeping the architectural principles (separation of concerns, spec-first development, self-correcting memory).

---

### How do I connect to my server?

The Governor connects to the target machine via SSH. During setup (`scripts/init.sh`), you provide the server's hostname or IP address and your SSH username. The template supports three connection methods: direct LAN connection (using `{{LAN_IP}}`), Tailscale mesh VPN (using `{{TAILSCALE_IP}}`), and jump host / NAS relay (using `{{NAS_IP}}`). SSH key-based authentication is strongly recommended -- password auth should be disabled as part of the initial security hardening. Once connected, the Governor interacts with the OpenClaw gateway API on port `{{GATEWAY_PORT}}`.

---

### What permissions do agents need?

Follow the principle of least privilege. Each agent should have access to only the tools and directories it needs for its specific role. `gpu-runner` needs read/write access to `{{MODEL_DIR}}` and the inference server, but not SSH keys or firewall rules. `sec-sentinel` needs read access to system configuration files and audit logs, but should not deploy containers. `deploy-chief` needs access to the container runtime and deployment scripts, but not model files. No agent should have unrestricted sudo access. When an agent needs elevated privileges for a specific operation, it should escalate to `ops-commander`, which requests human approval before proceeding.

---

### How do I customize this template?

Run `scripts/init.sh` and answer the interactive questionnaire. The script replaces all `{{PLACEHOLDER}}` values across the template files with your actual configuration (hostnames, IPs, model names, ports, etc.). After initialization, customize further by editing CLAUDE.md to add project-specific rules and lessons, modifying the agent hierarchy to match your needs (remove agents you don't need, add ones you do), adjusting the security audit schedule and scope, and writing specs for your specific infrastructure goals. The template is a starting point, not a rigid framework -- adapt it to your workflow, not the other way around.
