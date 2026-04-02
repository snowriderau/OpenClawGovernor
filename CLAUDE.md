# OpenClaw Governor — Template Development Mode

You are working on the OpenClaw Governor **template repository**. This is NOT a deployed instance. There is no live machine, no running agents, no active fleet.

Your job: improve the template — specs, docs, scripts, commands, rules, skills, and architecture.

---

## What This Repo Is

A template that anyone can clone and deploy to run an autonomous agent fleet with a Governor oversight layer. When someone runs `scripts/init.sh`, placeholders get replaced with real values and `CLAUDE_template.md` becomes the active `CLAUDE.md` — activating the Governor persona.

## Template vs Deployed

| | Template (you are here) | Deployed (after init.sh) |
|---|---|---|
| `CLAUDE.md` | This file — template dev instructions | Governor persona from `CLAUDE_template.md` |
| `{{PLACEHOLDERS}}` | Present in files | Replaced with real values |
| `.env` | Does not exist | Generated with machine config |
| Agents | Don't exist | Running on target machine |

---

## Workflow

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- Write specs to `specs/` before building features

### 2. Subagent Strategy
- Use subagents to keep the main context clean
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction: write or update a rule in `.claude/rules/`
- Do NOT maintain a self-correction table — rules prevent mistakes, tables record them

### 4. Verification Before Done
- For scripts: test they parse and run
- For specs: verify they reference correct file paths and placeholders
- For docs: ensure accuracy against current repo state

### 5. Placeholder Discipline
- Use `{{UPPER_SNAKE_CASE}}` for all environment-specific values
- Every placeholder must have a matching prompt in `scripts/init.sh`
- Check `scripts/init.sh` when adding new placeholders

---

## Local Reference (optional)

If `.env.governor` exists, it contains local paths to a prod OpenClaw setup you can reference for ideas and patterns. This file is gitignored. SSH to the machine and read directly.

---

## What Lives Where

| What | Where |
|------|-------|
| Governor persona template | `CLAUDE_template.md` |
| Feature specs & status | `specs/` and `feature_map.md` |
| Agent fleet template | `fleet.md` |
| Active state template | `active_state.md` |
| Governance ledger template | `governance-ledger.md` |
| Guard plugins (source) | `plugins/` (heartbeat-guard, announce-guard, role-guard) |
| Setup wizard | `scripts/init.sh` |
| OpenClaw config rules | `.claude/rules/openclaw.md` |
| Process rules | `.claude/rules/process.md` |
| Boundary rules | `.claude/rules/governor-boundary.md` |
| Auth philosophy | `.claude/rules/auth-by-role.md` |
| Copy policy | `.claude/rules/local-copy-policy.md` |
| Service management | `.claude/rules/systemd-only.md` |
| Governor commands | `.claude/commands/` |
| Governor skills | `.claude/skills/` |
| Local reference paths | `.env.governor` (gitignored) |
