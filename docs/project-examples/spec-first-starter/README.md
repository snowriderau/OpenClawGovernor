# spec-first-starter

A **spec-driven development framework** for AI-assisted projects. Drop the `.agent/` folder into any repo and get structured product thinking, autonomous task execution, and living documentation — out of the box.

> Build the right thing, then build it right.

## Why

Most AI coding sessions start with "just build it" and end with rework. This framework enforces a **spec-first workflow** where you define the problem, design the UX, get approval, *then* implement. Every feature gets a spec. Every spec becomes living documentation.

## Quick Start

1. **Copy** `.agent/` and `CLAUDE.md` into your project root
2. Run `/discovery` to initialize vision, personas, requirements
3. Run `/new_feature` to start your first spec-driven feature
4. Run `/loop` for autonomous task queue execution
5. Run `/success` to finalize completed work

## Five Core Workflows

| Command | What It Does |
|---------|-------------|
| `/discovery` | Vision → Personas → Requirements. Interactive init for new projects. |
| `/new_feature` | Understand → Design → Approve → Implement → Verify. Spec-first. |
| `/update_feature` | Read existing spec → append update plan → approve → implement. |
| `/loop` | Autonomous task execution. Claims from queue, executes, repeats. |
| `/success` | Commit, update feature map, rewrite spec as living reference. |

## Key Principles

- **Never code without a spec** — design first, build second
- **Specs are living documents** — `/success` keeps each spec current, not stale
- **Task claiming is multi-agent safe** — multiple agents can work the queue simultaneously
- **Failures are learning** — logged for pattern recognition, not blame

## Works With

Tool-agnostic — works with any AI coding assistant that can read markdown:
- Claude Code
- Codex
- Antigravity
- Cursor
- Windsurf
