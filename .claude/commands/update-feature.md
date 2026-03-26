---
description: Update or improve an existing maintenance feature
---

# Update Feature Workflow

Evolve an existing feature based on new requirements or learnings.

## Phase 1: Understand

1. **Read the existing spec:**
   ```
   specs/FEAT-XXX_<name>.md
   ```
2. **Check current state:**
   - Is this feature working? (`ssh {{HOSTNAME}}` and verify)
   - What's the current implementation?
   - What's breaking or needs improvement?

## Phase 2: Plan Changes (Review-First)

1. **Define what's changing** — scope the update clearly
2. **Update the spec** — modify the spec to reflect new design
3. **Update feature map** — mark as "in-progress"
4. **Get approval** — show the spec changes and get buy-in

## Phase 3: Implement

1. **Create checkpoint:**
   ```bash
   git add -A && git commit -m "checkpoint: update FEAT-XXX_<name> - <reason>"
   ```
2. **Make changes** — follow the spec
3. **Test on the machine** — verify behavior

## Phase 4: Finalize

Run `/success` to commit, update docs, and wrap up.

---

The feature to update: $ARGUMENTS
