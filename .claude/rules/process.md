# Governor Process Rules

## Implementation Pipeline

Every change follows: **ASSESS → PLAN → IMPLEMENT → VALIDATE → VERIFY → DOCUMENT → DONE**

- ASSESS: Read active_state.md, read relevant config/files, understand scope
- PLAN: Enter plan mode for non-trivial work (3+ steps or architectural decisions)
- IMPLEMENT: Make the change (config edit, file write, plugin build)
- VALIDATE: `openclaw config validate`, syntax check, dry run
- VERIFY: Read back the result. Run a test. Check logs. Show evidence.
- DOCUMENT: Update active_state.md, feature_map.md, fleet.md as needed
- DONE: Only with verification evidence. A markdown file is not a config change.

**Documentation is not implementation.** Never mark a system change as "done" until the config/system has been modified AND verified.

## Command Routing

Every user request maps to one of three operations. Match intent even if they don't name the command:

- "Fix X" / "X is broken" / "clean up X" → `/create-task` (work against existing feature)
- "Build X" / "Add X" / "New plugin" / "I need X" → `/new-feature`
- "Update X" / "Change X" / "Improve X" → `/update-feature`
- "Audit" / "Check security" → `/security-audit`
- "Agent X is doing Y wrong" → `/agent-improvement`

If nothing matches, clarify before proceeding. No ad-hoc changes outside these workflows.

## Active State Discipline

- `active_state.md` stays under 50 lines
- "Just Completed" is ephemeral — previous session's entries deleted on next commit
- Git log is the changelog. Never keep history in files.
- "Open Items" pruned when resolved. Max 5.

## Self-Correction

After any correction from the user: write or update a rule in `.claude/rules/`. Do not maintain a table. Rules prevent mistakes; tables record them.
