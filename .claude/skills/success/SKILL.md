---
description: Finalize changes - commit, update docs, update feature map
---

# Success Workflow

Finalize the feature implementation or update.

## Step 1: Verify

- [ ] All acceptance criteria met?
- [ ] Tested / verified on the machine?
- [ ] Evidence shown (config readback, log entry, test output)?

## Step 2: Update Docs

1. **Feature map** (`feature_map.md`) — mark items `[x]`, update status
2. **Active state** (`active_state.md`) — move task to Just Completed
3. **Fleet** (`fleet.md`) — update if agent config changed

## Step 3: Commit

Stage specific files (not `git add -A`). Commit with descriptive message.

## Step 4: Sync with Openclaw (if applicable)

If changes affect agent config:
- Update workspace files on the machine
- Validate: `openclaw config validate`
- Restart gateway if config changed
- Verify the change took effect

---

Feature to finalize: $ARGUMENTS
