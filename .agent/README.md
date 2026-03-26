# .agent/ Directory

Navigation index for the Governor's working memory and product documentation.

---

## Directory Structure

```
.agent/
├── README.md              ← You are here
├── memory/                # Runtime state (changes frequently)
│   ├── active_state.md    # Current tasks and progress
│   └── failures.md        # Incident log with lessons learned
│
├── product/               # Product definition (changes rarely)
│   ├── architecture.md    # System architecture and decisions
│   ├── problem.md         # Problem statement and scope
│   ├── requirements.md    # Functional and non-functional requirements
│   ├── users.md           # User personas and use cases
│   ├── agent_escalation_protocol.md  # Agent hierarchy and escalation rules
│   └── specs/             # Individual feature specifications
│
└── workflows/             # Operational runbooks
    ├── incident_response.md
    ├── machine_recovery.md
    ├── patch_management.md
    └── security_audit.md
```

---

## How It Works

### memory/
Volatile state that changes with every session. The Governor writes its current plan to `active_state.md` and logs incidents to `failures.md`. These files are the Governor's short-term and long-term memory.

### product/
Stable product documentation. Defines what the system is, who it serves, and how it should be built. Edit these when the project scope changes, not during routine operations.

### workflows/
Step-by-step runbooks for common operational procedures. Referenced by the Governor when handling incidents, patches, audits, or recovery scenarios.

---

## Conventions

- Files in `memory/` are append-friendly — add to them, don't rewrite them
- Files in `product/` should be reviewed and updated deliberately
- Specs in `product/specs/` follow the template: goal, approach, acceptance criteria, rollback plan
- Workflow files are executable checklists — each step should be actionable
