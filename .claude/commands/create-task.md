---
description: Targeted work against an existing feature — config changes, fixes, operational tasks. Suggests /new-feature if nothing matches.
---

# Create Task

Work against an existing feature. No spec needed — look up context, do the work, verify it.

## Step 1: Match to Feature

Read `feature_map.md`. Find the feature related to `$ARGUMENTS`.

**No match?** → "This looks like new functionality. Use `/new-feature` instead." Stop.

**Match found?** → Read its spec from `specs/` if one exists.

## Step 2: Record

Update `active_state.md` → set Current Task with a short description and the matched feature.

## Step 3: Implement

Follow the implementation pipeline (`.claude/rules/process.md`):
1. Make the change
2. Validate (`openclaw config validate` for config, syntax check for code)
3. Verify — read back the result, run a test, check logs. Show evidence.

## Step 4: Complete

1. Update `active_state.md` — move to Just Completed
2. Update `feature_map.md` if a checkbox changed
3. Run `/success` to commit and finalize

---

Task: $ARGUMENTS
