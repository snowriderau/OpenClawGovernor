# Users & Roles

## Governor (Primary Operator)

**Profile:** Claude Code — builds, configures, monitors, and improves everything

**Goals:**
- Deploy and configure the full agent fleet
- Write all openclaw.json config, specs, and workspace files
- Continuously audit and improve agents
- Detect and fix problems autonomously
- Escalate only when a decision requires human judgment

**Behaviors:**
- Writes all config — user never touches files
- Deploys new agents on demand as workload grows
- Audits agents regularly and recommends improvements
- Monitors system health and responds to alerts
- Updates security policies as the environment evolves

**Knowledge Level:** Full access to codebase, configs, SSH, and system state

## System Owner (Approver)

**Profile:** You — sets direction, approves high-impact changes, receives status reports

**Goals:**
- Maintain secure, up-to-date system
- Stay informed without being in the weeds
- Authorize changes that require human judgment (irreversible, high-risk, or policy-setting)

**Behaviors:**
- Reviews summary reports via notification channel
- Approves high-impact changes when prompted
- Sets priorities and adjusts policies
- Does not write config or specs — Governor handles all of that

**Knowledge Level:** Advanced — familiar with the system, security concepts, and command line — but does not need to operate it directly

## Agent Fleet (Execution Layer)

**Profile:** Openclaw agents (Atlas, Conductor, Forge, Hermes, Bolt, Scout, Courier, Sentinel) — execute all tasks autonomously within their domains

**Goals:**
- Execute tasks assigned by Governor or Atlas
- Report findings clearly through the escalation chain
- Operate within domain boundaries
- Maintain audit trail

**Capabilities:**
- Full autonomous execution within their assigned domain
- Escalate to Atlas for user-facing notifications
- Dispatch sub-agents as needed per spawn permissions

**Boundaries:**
- Each agent locked to its security domain
- No cross-domain tool access
- Atlas is the only agent that sends to the notification channel

## Stakeholders

**System Users (Secondary):**
- Should not be disrupted by maintenance
- Trust system is secure and available

**Compliance/Security Standards (if applicable):**
- CIS Benchmarks, NIST frameworks
- Regular audits for compliance
