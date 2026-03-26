# Best Practices — OpenClaw Governor Template

This document synthesizes operational knowledge across all components of the OpenClaw Governor pattern. It is not a tutorial — it is a reference for teams who want to run this architecture correctly and safely from day one.

---

## 1. The Governor Pattern

**Why run Claude Code separately from your OpenClaw agents?**

The Governor (Claude Code, or any AI coding agent, running on a separate machine — local, remote, wherever you can SSH from) and your OpenClaw agents are deliberately different layers with different roles. Claude Code is the primary recommendation, but Codex, Antigravity, and others work too. Conflating the Governor with the agents it governs is the most common architectural mistake.

OpenClaw agents live on the target machine and execute work continuously — they spawn sessions, process tasks, run code, manage files. The Governor sits above and outside this — it monitors, verifies, improves, and can also directly build on the OpenClaw system when needed. As the highest-capability model with the least context rot, the Governor can do project work too. The key is maintaining separation: the Governor knows it's working on OpenClaw (remote) vs its own local repo, and keeps those contexts distinct.

This separation provides:
- **Independent oversight.** A Governor agent cannot be co-opted by a confused sub-agent to approve its own work.
- **Meta-level control.** When something systemic breaks (wrong model configured, agent tool permissions malformed), only an outside observer can see the pattern.
- **Upgrade path.** You can swap, retrain, or reset individual agents without taking down the oversight layer.

In practice: the Governor writes rules into `CLAUDE.md`, updates workspace files, and can SSH into the machine to check logs or restart services. It never touches application code or data directly. Every correction the Governor makes becomes a permanent rule — the system gets smarter each time it fails.

---

## 2. Spec-First Development

**The Governor writes the spec. You describe what you want.**

The most reliable agents don't improvise — they follow a well-specified brief. But you never write that brief yourself. Tell the Governor what you want — "I need email triage" or "set up a weather alert agent" — and it creates the spec, dispatches the right agents, and tracks progress. The spec lands in `specs/` and covers: problem statement, goals, design, acceptance criteria, and rollback.

This eliminates the largest class of rework: agents that implement the wrong thing correctly. The Governor is precise so compute isn't wasted. You do the thinking; the robots do the documentation and the work.

Key rules from operational experience:
- **Acceptance criteria must be verifiable.** Not "it works" but "the test passes" or "the endpoint returns 200 with this JSON structure."
- **Include rollback steps.** Every spec that touches infrastructure or configuration needs a clear undo path. Agents make mistakes — having a rollback documented before starting means recovery is a 30-second command, not a debugging session.
- **Mark spec status.** `draft → approved → active → done`. Agents shouldn't start work on a draft spec. The PM agent's heartbeat scans `active` specs for progress.

Use the `_TEMPLATE_spec.md` as a starting point. Resist the temptation to fill it out partially — an incomplete spec is worse than no spec because it creates false confidence.

---

## 3. Agent Hierarchy Design

**The shape of your agent fleet is a security decision, not an efficiency one.**

The three-tier hierarchy (Governor → Orchestrator → Directors → Workers) is not cosmetic. Each boundary prevents a specific failure mode:

- **Orchestrator can't execute.** Atlas sees everything and talks to the user, but has no code execution, no email access, no file write to production. A compromised or confused orchestrator cannot cause real damage.
- **Directors own one domain.** Forge owns code. Hermes owns email. Conductor owns project state. None of them can accidentally (or deliberately) cross boundaries because the tools aren't there.
- **Workers don't know why.** Bolt and Courier receive tasks, execute, return results. No context about the broader goal means no drift, no assumptions, no intent leakage. The agent that processes your credentials doesn't know it's processing credentials.

**Escalation chain:**
```
Workers → escalate to → Directors
Directors → escalate to → Atlas (Orchestrator)
Atlas → notifies → User (via Notification Channel)
```

`sessions_spawn` is the mechanism. Workers cannot spawn — they can only return results within their session. Directors can spawn workers. Only Atlas can send to the notification channel (Telegram, Slack, Discord, etc.).

The Governor builds and deploys agents on demand. Tell it what you need — "I need an agent for weather alerts" — and it creates the agent with appropriate tools, workspace files, and domain isolation. Scale up freely. More agents with narrow domains is better than fewer agents with broad scope. There is no reason to be conservative — the architecture handles the safety, not the headcount.

---

## 4. Self-Correcting Memory

**Every mistake becomes a rule. The system gets smarter each time it fails.**

The lessons table in `CLAUDE.md` (and each agent's workspace `IDENTITY.md`) is not a changelog — it's a living rulebook. The discipline: after any correction from a user, the Governor writes a new row into the lessons table before the session ends.

Format:
```
| Date | What went wrong | Rule |
```

The rule must be concrete and actionable. "Be more careful" is not a rule. "Before any destructive file operation, verify the replacement exists and matches expected size — exit code 0 is not sufficient confirmation" is a rule.

At session start, the Governor reviews lessons relevant to the current context. Agents doing file operations see the file safety rules. Agents doing config changes see the config verification rules. This is how institutional knowledge accumulates without requiring a human to remember it.

Keep the table trimmed. Rules that have been stable for 6+ months without incident can be promoted to formal policy in the relevant spec or workflow document and removed from the active table.

---

## 5. Workspace Files

**Every agent has a workspace directory with standardised files. Do not skip this.**

Each agent's `agentDir` contains files that define who the agent is, what tools it has, what it's currently doing, and what it has learned. These are not optional decoration — they are the agent's persistent identity and memory.

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Who the agent is, its domain, its security rules. Loaded at session start. |
| `TOOLS.md` | What tools are available and how to use them. Prevents tool hallucination. |
| `TASKS.md` | Current task queue. Checked by Conductor on heartbeat. |
| `HEARTBEAT.md` | Instructions for what to do on each heartbeat cycle. |
| `OPS.md` | Operational reference — paths, commands, known issues for this agent's domain. |
| `KNOWN_ISSUES.md` | (Optional) Domain-specific problems and workarounds. |

`IDENTITY.md` is the most important. It must state clearly: what this agent does, what it does NOT do, and its security domain. An agent without a clear IDENTITY.md will drift — responding to whatever prompt arrives instead of staying within its role.

`TOOLS.md` prevents a common failure: agents attempting to use tools that don't exist in their runtime. Document every tool with its actual syntax, not what you hope the syntax is. Test once and write down the working invocation.

---

## 6. Security Approach

**Architecture is the guardrail, not permissions.**

The security model here is not about locking agents down or requiring approval gates. Agents have wide-open access within their tier — that's what makes them useful. The safety comes from the structure itself: even with full sudo, no single agent has both the full picture and the full toolkit. That combination is what makes an agent dangerous, and the tiered architecture structurally prevents it.

**Four architectural properties that provide security without friction:**

1. **Forge builds, Sentinel verifies.** The agent that writes the code is never the agent that approves it. This catches both bugs and scope creep — structurally, not by policy.
2. **Local models for data touchpoints.** Any agent that handles credentials, personal data, security configs, or sensitive files runs on a local model (Bolt, Courier). Cloud APIs never see that data. This is both a security property and a cost optimisation — cheap local inference for execution tasks, expensive cloud reasoning only when it's needed.
3. **Workers have no outbound channel.** Bolt and Courier cannot send messages, spawn sessions, or make network calls beyond their narrow tool set. They execute within their session and return results. Containment is structural, not policy.
4. **Push sensitive access down to lower tiers.** Workers on local models handle credentials and sensitive data. Cloud-facing agents never see it. The architecture enforces this structurally — there are no approval gates to configure or bypass.

The architecture is deliberately light on deny lists. Deny lists need maintenance. Structure-based isolation doesn't.

---

## 7. Monitoring and Recovery

**A four-layer system that catches failures before users notice them.**

**Layer 1 — Heartbeats.** Each agent with a heartbeat runs its `HEARTBEAT.md` routine on a schedule. Conductor scans project states every 60 minutes. Atlas synthesises and notifies the user when something needs attention. Heartbeats are not just "I'm alive" pings — they are active work cycles that check for drift, stalled tasks, and blocked agents.

**Layer 2 — Watchdog.** A systemd timer (every 5 minutes) hits the Openclaw gateway health endpoint. If the gateway is not responding, it attempts a restart and notifies the user via the notification channel. The Openclaw service itself runs with `Restart=always` — transient crashes self-recover within seconds.

**Layer 3 — Governor.** The Governor (Claude Code) does periodic SSH checks — reading agent `TASKS.md` files, checking gateway logs, reviewing recent escalations. This is the architectural-level sanity check that catches systemic problems the watchdog misses — pattern recognition across the whole fleet, not just individual service health.

**Layer 4 — Audit logs.** Every agent action that touches the system goes through auditd logging under the agent's user account. Weekly security checks (cron or Governor-initiated) review these logs for anomalies — unexpected sudo use, unusual file access patterns, out-of-hours activity.

**Recovery procedure for a stuck agent:**

The Governor handles this automatically. When an agent gets stuck, the Governor SSHes in, reads the agent's `TASKS.md` and recent session logs, identifies whether it's blocked, errored, or drifted, and fixes it. You get a notification when it's resolved. If the Governor itself needs a decision from you — a missing credential, an architectural choice — it escalates via the notification channel. Otherwise it handles recovery end-to-end without involving you.

---

## 8. Operational Tips

**Hard-won lessons from running this architecture in production.**

**Restart the gateway after every config change.** This cannot be overstated. Openclaw's `openclaw.json` changes take effect only after a gateway restart. A common failure pattern: change the config, see the change looks correct in the file, assume it's live. It's not. `systemctl --user restart openclaw-gateway.service`, then verify the change is active by checking agent behaviour.

**Validate your config before restart.** Openclaw will fail to start with invalid JSON. Run a JSON lint pass on `openclaw.json` before every restart. Keep a known-good backup of the config before making any changes.

**Known invalid tools.** Some tools appear valid in Openclaw documentation but are not available in the agent runtime (`glob`, `grep`). If an agent logs tool warnings on startup, remove those tools from its config. Don't ignore the warnings — they indicate the agent will attempt and fail to use those tools.

**Test escalations end-to-end.** After the Governor deploys a new agent, it runs a test escalation: trigger the agent, verify it completes its task, verify it reports back through the correct chain, verify the notification reaches you. The Governor doesn't declare an agent operational until the full message path has been verified in practice.

**Use SSH aliases.** Your Tailscale and LAN IPs go in `~/.ssh/config` with meaningful aliases (`ssh {{HOSTNAME}}`, `ssh {{HOSTNAME}}-lan`). Agents that need to SSH to other machines (Courier moving files to NAS, Governor checking agent state) should use these aliases, not raw IPs. IP-based configs break when network topology changes; alias-based configs don't.

**One notification channel.** Only Atlas sends to the user's notification channel. If you find yourself configuring a second agent to send directly, stop. Create an escalation path to Atlas instead. Multiple agents with direct notification access creates noise and breaks the coherent user experience the orchestrator pattern is designed to provide.

---

## 9. Local Model Recommendations

Local models handle secure data touchpoints — credentials, configs, sensitive files, air-gapped compute — AND save cloud API costs on simple execution tasks that don't need expensive reasoning models. Cloud APIs never see sensitive data, and you're not paying cloud rates for work a local model handles fine. The right local model depends on your hardware.

**Recommended Model Families:**

- **Qwen 3.5** — Best size-to-capability ratio for general agentic work. MoE variants (35B-A3B) activate only 3B parameters per token — fast enough for interactive use on modest VRAM. Strong tool use and function calling.
- **MiniMax M1** — 456B total / 46B active MoE, 1M context window. Excellent for agentic tasks that require holding large codebases or document sets in context. Cloud-class reasoning locally.
- **Nemotron Super 120B** — 120B total / 12B active hybrid Mamba-MoE. 1M context. Built specifically for agent pipelines by NVIDIA. Excellent instruction following and tool use discipline.

**VRAM Guide:**

| VRAM | Hardware | Recommended | Quantization |
|------|----------|-------------|-------------|
| 8–16 GB | Mac Mini, RTX 4060/4080 | Qwen 3.5 9B | Q4–Q8 |
| 24 GB | RTX 4090 | Qwen 3.5 35B-A3B (3B active) | Q4_K_M |
| 32 GB | RTX 5090, Mac M4 Max | Qwen 3.5 35B-A3B | Q6–Q8 |
| 48–64 GB | Mac M4 Ultra, 2x GPU | Nemotron Super 120B-A12B | Q4_K_M |
| 96 GB+ | DGX Spark, multi-GPU | Nemotron Super 120B (Q6+), MiniMax M1 (Q3–Q4) | High quality |

All three families support tool use and function calling. MoE models (A3B, A12B) only activate a fraction of parameters per token — they are much faster than their total parameter count suggests. A 35B-A3B model with 3B active parameters runs at 3B inference speed while retaining 35B knowledge capacity.

**Quantization quick reference:**
- **Q4** — 4-bit, smallest file, slight quality loss. Good for VRAM-constrained setups.
- **Q6** — 6-bit, good balance of size and quality. Default recommendation.
- **Q8** — 8-bit, near full quality, larger file. Use when you have headroom.
- **FP16** — Full precision. Only if VRAM is abundant.

Use LM Studio or Ollama as your local inference server. Both expose an OpenAI-compatible API. The Governor configures your local model provider automatically — you never touch `openclaw.json` directly.
