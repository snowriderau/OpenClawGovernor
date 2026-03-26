# System Architecture

## Components

### Core Scanning & Monitoring
- **Vulnerability Scanner:** Checks for CVEs, outdated packages
- **Log Monitor:** Analyzes system logs for anomalies
- **Config Auditor:** Reviews security configurations
- **Access Auditor:** Monitors user accounts and permissions

### Decision & Response
- **Policy Engine:** Matches findings against security policies
- **Recommendation Engine:** Suggests remediation actions
- **Approval Workflow:** Routes high-impact decisions to system owner; everything else executes autonomously
- **Incident Response:** Executes playbooks for security events

### Execution & Maintenance
- **Patch Manager:** Applies updates and security patches
- **Config Manager:** Manages system configurations — Governor writes all config
- **Backup Manager:** Ensures rollback capability
- **Audit Logger:** Records all changes and decisions

## Data Flow

```
Scanning      →  Analysis  →  Decision  →  Approval*  →  Execution
Logs                Policy        Engine      Owner*       Changes
Configs       Findings      Recommendations  Review*      Logging
Packages

* Only for high-impact or irreversible changes. All other decisions execute autonomously.
```

## Security Boundaries

### Agent Domain Isolation
Domain isolation between agents is the security model. Each agent is locked to its scope:
- Each agent receives only the tools its domain requires
- No agent accumulates cross-domain capabilities or context
- Atlas coordinates; it never executes domain work directly
- Bolt (local model) handles sensitive data — cloud models never touch credentials or configs

### Governor Responsibilities
- Writes and maintains all config files, specs, and workspace documents
- Deploys new agents as workload grows
- Audits agent behavior and improves configs
- Applies fixes autonomously; escalates only when human judgment is required

### Owner Responsibilities
- Authorize high-impact changes (irreversible, high-risk, policy-setting)
- Review summary reports
- Set priorities

### Protected Data
- User credentials never stored or transmitted
- Sensitive configs handled by local agents (Bolt) — never sent to cloud providers
- Audit logs retained for compliance
- Backups encrypted and tested

## Integration Points

### OS Level
- Package managers (apt, dnf, pacman, brew, etc.) — Governor adapts to the host distro
- System logs (/var/log or journald)
- Configuration files (/etc or platform equivalent)
- systemctl and service management (systemd-based systems)

### Hardware
- GPU: NVIDIA, AMD, Apple Silicon, or CPU-only — Governor detects and configures appropriately
- Local inference adapts to available compute

### External (As Needed)
- Security advisories (CVE databases)
- Package repositories
- NTP for time sync
- DNS for resolution

## Tech Stack

- **Language:** Bash, Python (for advanced parsing)
- **Tools:** Built-in OS utilities (grep, awk, etc.)
- **Storage:** Flat files in .agent/data/
- **Tracking:** Markdown files for state and decisions
- **Agent Runtime:** Openclaw (Governor-configured)
- **Local Inference:** LM Studio, Ollama, or vLLM (platform-adaptive)
