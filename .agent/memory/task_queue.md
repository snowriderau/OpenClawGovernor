# Task Queue (Prioritized)

Governor maintains this queue. Agents execute tasks. The owner reviews progress — Governor handles population, prioritization, and updates automatically.

## Now / This Week

<!-- Governor populates current tasks here. Owner reviews via Governor. -->

### EXAMPLE-1: [Example] Baseline System Assessment
- **Status:** Ready to Start
- **Owner:** Governor
- **Effort:** 2 hours (estimated)
- **Description:** Complete initial security audit of the target machine
- **Tasks:**
  - [ ] Identify OS and version
  - [ ] List installed packages and versions
  - [ ] Check for available security updates
  - [ ] Audit running services and listening ports
  - [ ] Review user accounts and sudo access
  - [ ] Scan for obvious misconfigurations
- **Output:** security_audit_baseline_YYYY_MM_DD.md
- **Spec:** [security_audit.md](../workflows/security_audit.md)

---

## Next Week

<!-- Governor queues upcoming tasks here. -->

### EXAMPLE-2: [Example] Set Up Automated Security Checks
- **Status:** Queued
- **Owner:** Governor
- **Effort:** 2-3 hours
- **Description:** Configure weekly security scanning workflow
- **Tasks:**
  - [ ] Design scan automation
  - [ ] Create monitoring dashboard
  - [ ] Set up alerting for critical findings

---

## Future

<!-- Governor adds backlog items here as they get scheduled. -->

### EXAMPLE-3: [Example] CIS Benchmark Hardening
- **Status:** Backlog
- **Owner:** Governor (with owner approval for each change)
- **Effort:** 4-6 hours
- **Description:** Apply CIS hardening recommendations

---

## Task Template

Governor uses this format when creating new tasks:

**TASK-XXX: [Title]**
- **Status:** [Ready to Start / In Progress / Blocked / Complete]
- **Owner:** [Governor / Agent name]
- **Effort:** [Estimated hours/time]
- **Description:** [What and why]
- **Tasks:**
  - [ ] Subtask 1
  - [ ] Subtask 2
- **Output:** [What gets delivered]
- **Spec:** [Link to spec if exists]
- **Blocker:** [If blocked, what's blocking and whether owner escalation is needed]
