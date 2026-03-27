---
description: Start autonomous loop - pick a task from the queue and work continuously until done
---

# Autonomous Loop

---

## Loop Instructions

### Step 0: Generate Agent ID
Generate a unique agent ID for this session. Use format: `agent-HH:MM` (current time).

### Step 1: Read Queue
```bash
cat .agent/memory/task_queue.md
```

### Step 2: Find & Claim Task
1. Find the **first task** with status `QUEUED` (not `CLAIMED`)
2. Edit `task_queue.md`: change status from `QUEUED` → `CLAIMED`, add your agent ID
3. If ALL tasks are `CLAIMED` by other agents, wait and check again next iteration

### Step 3: Execute Task

#### 3a. Check for Spec
```bash
cat .agent/product/specs/<TASK_ID>_*.md 2>/dev/null || echo "No spec found"
```

**If NO spec exists:**
1. **STOP** — do not start coding
2. Create spec using `/new_feature` Phase 2 (Design)
3. Get user approval if significant feature
4. Then proceed to implementation

#### 3b. Implementation
1. Read the spec's verification criteria
2. Follow `/new_feature` Phase 3 (Implementation)
3. Run tests/verification as specified in spec

### Step 4: On Completion

**Success:**
1. Run `/success` workflow to commit
2. Move task to `## Completed` section with date and commit

**Failure:**
1. Log error to `.agent/memory/failures.md`
2. Try to fix (max 3 attempts)
3. If still failing: change status to `BLOCKED`, add reason, clear "Claimed By"

### Step 5: Continue Loop
After completing/blocking a task, go back to Step 1. Repeat until no more `QUEUED` tasks.

---

## Multi-Agent Coordination

Multiple agents can run `/loop` simultaneously. First agent to write the claim wins. If you see a task already claimed, skip it.

**Stale Claims:** If a task is CLAIMED but untouched for 1+ hour, you may reclaim it.

---

## Emergency Stop

Send any message to interrupt, or say "stop" or "cancel".
