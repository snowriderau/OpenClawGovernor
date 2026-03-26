# Failure Log

Record of issues encountered, their root causes, and resolutions. Governor and agents populate this file automatically. The owner reviews it — never fills it in directly.

## Format

Governor writes entries in this format:

### Failure #N: [Title]
- **Date:** YYYY-MM-DD
- **Severity:** [Critical / High / Medium / Low]
- **Description:** What happened?
- **Impact:** What did it affect?
- **Root Cause:** Why did it happen?
- **Resolution:** How was it fixed?
- **Prevention:** How do we prevent this in the future?

---

## Log

<!-- Governor appends entries here automatically. No manual editing needed. -->

### Failure #1: [Example] Service crash after package update
- **Date:** YYYY-MM-DD
- **Severity:** Medium
- **Description:** Service X stopped responding after routine apt upgrade. Exit code 1 in systemd journal, no further context.
- **Impact:** Service X unavailable for N hours until Governor detected and remediated.
- **Root Cause:** Package Y updated to a version with a breaking config change. Old config file format was no longer accepted.
- **Resolution:** Governor updated config file to new format per upstream changelog. Service restarted automatically.
- **Prevention:** Before applying updates to critical services, Governor now checks upstream changelogs for breaking changes. Post-patch verification step added to patch management workflow.

---

## Notes for Investigators

When Governor investigates a failure it follows these principles:
1. **Preserve evidence** — Don't delete logs or configs
2. **Document findings** — Record what was learned here automatically
3. **Test fixes** — Verify solution before marking resolved
4. **Update processes** — Prevent recurrence via workflow updates
5. **Review impact** — Did it affect other systems or agents?

## Common Failure Categories

- **Configuration Errors** — Misapplied settings, typos
- **Automation Failures** — Scripts or agents failing unexpectedly
- **Patch Issues** — Updates breaking functionality
- **Permission Problems** — Access control errors
- **Incomplete Changes** — Partial application of updates
- **Timing Issues** — Race conditions, timing-dependent bugs
- **Agent Errors** — Unexpected agent behavior or self-modification
