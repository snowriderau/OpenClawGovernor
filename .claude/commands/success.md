---
description: Finalize changes — commit, update docs, update feature map
---

# Success Workflow

Finalize the feature implementation or update.

## Step 1: Verify Acceptance Criteria

Check the spec (`specs/FEAT-XXX_*.md`):
- [ ] All acceptance criteria met?
- [ ] All blockers resolved?
- [ ] Tested on the machine?

## Step 2: Commit Changes

```bash
git add -A
git commit -m "feat: implement FEAT-XXX_<name>

- What was done (2-3 bullet points)
- Acceptance criteria met

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Step 3: Update Docs

1. **Feature map** (`feature_map.md`):
   - Mark feature as `[x]` (complete)
   - Update status line

2. **Active state** (`.agent/memory/active_state.md`):
   - Move completed task to "Done" section
   - Update "Next Up" section
   - Add to learnings if noteworthy

## Step 4: Sync with OpenClaw Agents

If changes affect OpenClaw agents, restart relevant services:
- Update workspace files (USER.md, IDENTITY.md, TOOLS.md, TASKS.md) if agent behavior changed
- Restart gateway: `systemctl --user restart openclaw-gateway.service`
- Verify with `openclaw health` or `openclaw status`

## Step 5: Archive & Close

- Move any related issues/tickets to "Done"
- Document learnings in memory
- Note any follow-up tasks in task_queue.md

---

Feature to finalize: $ARGUMENTS
