# CLAUDE.md — Spec-First Starter

A spec-driven development framework that prevents the common AI-assisted development problem: building without design, then reworking. Copy `.agent/` into any project to get structured product thinking and autonomous task execution.

## Quick Start

1. Copy `.agent/` into your project root
2. Run the `/discovery` workflow to initialize product definition
3. Fill in product docs (problem, users, requirements, architecture, feature_map)
4. Queue initial tasks in `task_queue.md`
5. Use `/new_feature` for new specs, `/loop` for autonomous execution

## Structure

```
.agent/
├── product/
│   ├── problem.md          # Vision, audience, constraints
│   ├── users.md            # Target personas
│   ├── requirements.md     # Functional & non-functional
│   ├── architecture.md     # Technical blueprint
│   ├── feature_map.md      # Feature inventory with status
│   └── specs/              # Per-feature specifications
├── memory/
│   ├── active_state.md     # Current context & decisions
│   ├── task_queue.md       # Claimable work items
│   ├── backlog.md          # Future work
│   └── failures.md         # Failure log for learning
├── workflows/
│   ├── discovery.md        # /discovery — init project
│   ├── new_feature.md      # /new_feature — spec-first dev
│   ├── update_feature.md   # /update_feature — evolve specs
│   ├── loop.md             # /loop — autonomous execution
│   └── success.md          # /success — finalize & commit
└── skills/                 # Reusable agent knowledge
```

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Write detailed specs upfront to `.agent/product/specs/` to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep the main context window clean
- Offload research, exploration, and parallel analysis to subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update the Lessons table below
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for relevant context

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Run the system, check logs, read actual output — not just status fields
- Ask: "Would a staff engineer approve this?"

### 5. Demand Elegance
- For non-trivial changes, pause and ask "is there a more elegant way?"
- If a fix feels hacky: implement the elegant solution instead
- Skip this for simple, obvious fixes — don't over-engineer

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it, no hand-holding needed
- Go fix failing systems without being told how
- Escalate only when blocked (needs sudo, missing dependency, user decision)

---

## Self-Correction

Every mistake becomes a rule. This file is a self-correcting system — it gets smarter every time something goes wrong.

| Date | What went wrong | Rule |
|------|----------------|------|

---

## Core Principles

- **Spec first** — Never code without a spec. Design first, build second.
- **Living docs** — Specs describe what is currently built, not stale plans.
- **Multi-agent safe** — Task claiming prevents conflicts in parallel execution.
- **Failures are learning** — Every mistake becomes a documented prevention rule.

## Workflows

| Command | File | Purpose |
|---------|------|---------|
| `/discovery` | `workflows/discovery.md` | Initialize vision, personas, requirements |
| `/new_feature` | `workflows/new_feature.md` | Spec → approval → implementation |
| `/update_feature` | `workflows/update_feature.md` | Evolve existing features |
| `/loop` | `workflows/loop.md` | Autonomous task queue execution |
| `/success` | `workflows/success.md` | Finalize, commit, update living docs |
