# Requirements

## Functional Requirements

### FR1: Vulnerability Assessment
- Scan system for known CVEs
- Check package versions against security databases
- Generate vulnerability report with severity levels
- Prioritize by exploitability and impact

### FR2: Patch Management
- Check available updates weekly
- Assess patches before applying
- Apply security updates autonomously where safe; escalate high-impact changes
- Maintain rollback capability

### FR3: Access Control
- Audit user accounts and permissions
- Detect and flag unusual access patterns
- Domain isolation between agents is the access control model — not restrictive permissions
- Review sudo access regularly

### FR4: Log Monitoring
- Collect and analyze system logs
- Alert on suspicious activities
- Track authentication attempts
- Monitor service restarts and failures

### FR5: Configuration Hardening
- Enforce security best practices
- Disable unnecessary services
- Configure firewall rules
- Set secure defaults

### FR6: Incident Response
- Quickly identify security events
- Isolate affected systems if needed
- Preserve evidence for investigation
- Execute incident playbooks autonomously; escalate decisions requiring human judgment

## Non-Functional Requirements

### NF1: Reliability
- Maintain system stability during maintenance (uptime >99%)
- All changes must be reversible
- Verify before applying to production

### NF2: Security
- All credentials encrypted at rest
- Audit trail for all changes
- Minimal exposure of sensitive data
- Domain isolation between agents — each agent locked to its scope

### NF3: Usability
- Clear, actionable reports
- Easy to understand recommendations
- Approval process only for high-impact or irreversible changes
- Transparent about what agents are doing

### NF4: Maintainability
- Governor documents all security policies
- Track decisions and rationale
- Easy to update procedures
- Version control for configurations

### NF5: Platform Agnosticism
- Works on any systemd-capable system
- Package manager commands adapt to distro (apt, dnf, pacman, brew, etc.)
- GPU support: NVIDIA, AMD, Apple Silicon, or CPU-only
- Governor detects environment and adapts — no hardcoded Linux/NVIDIA assumptions

## Compliance & Standards

- Follow CIS Benchmarks where applicable
- Align with NIST Cybersecurity Framework
- Regular audit reviews
- Governor documents remediation efforts
