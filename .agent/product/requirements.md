<!-- TEMPLATE: Adjust these requirements to match your infrastructure needs. -->
<!-- Remove this comment block when your requirements are finalized.       -->

# Requirements

## Functional Requirements

### FR-1: Agent Coordination
- The Governor must be able to assign tasks to agents via SSH
- Agents must report status through structured file-based state
- The orchestrator agent must delegate work to specialist agents based on task type
- Escalation must flow upward through the agent hierarchy

### FR-2: Spec-First Workflow
- Every non-trivial change must have a spec before implementation begins
- Specs must include: goal, approach, acceptance criteria, rollback plan
- The Governor must track spec status (draft, approved, implementing, complete)

### FR-3: Approval-Gated Changes
- System changes (package installs, config modifications, service restarts) require explicit user approval
- The Governor operates in read-only mode by default
- Emergency changes must be logged and reviewed post-incident

### FR-4: Self-Correcting Memory
- Every user correction must be captured as a rule in CLAUDE.md
- The Governor must review lessons at the start of each session
- Incident logs must be maintained in `.agent/memory/failures.md`

### FR-5: Monitoring and Verification
- The Governor must verify task completion through log inspection and output validation
- No task is marked complete without end-to-end verification
- Agents must expose health status that the Governor can query

## Non-Functional Requirements

### NFR-1: Security
- SSH keys for authentication (no passwords)
- Least-privilege agent permissions
- Audit trail for all system modifications

### NFR-2: Reliability
- Agent failures must not cascade
- The Governor must detect and report unresponsive agents
- Recovery workflows must be documented and executable

### NFR-3: Simplicity
- Prefer markdown files over databases
- Prefer SSH over custom protocols
- Prefer small, focused agents over monolithic ones

### NFR-4: Extensibility
- New agent roles can be added without modifying existing agents
- New workflows can be added as markdown runbooks
- The hierarchy supports arbitrary depth (Tier 1, 2, 3, ... N)
