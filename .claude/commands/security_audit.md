# Security Audit Workflow

## Purpose
Governor performs regular security assessment to identify vulnerabilities, configuration issues, compliance gaps, and agent behavior anomalies. All phases are automated. Governor also audits OpenClaw agents directly and surfaces improvement recommendations.

## Frequency
- **Baseline:** Once at start (ASAP, Governor-initiated)
- **Regular:** Weekly (scheduled automatically)
- **On-Demand:** When suspected compromise or major changes

## Workflow Steps

### Phase 1: System Inventory (Automated, ~0.5 hours)
Governor gathers basic system information to understand the scope.

```bash
# What Governor checks
- OS name, version, kernel version
- System uptime
- CPU, memory, disk usage
- Installed packages count
- Running services count
- Network interfaces and connectivity
```

**Inputs:** System commands (uname, lsb_release, etc.) run via SSH
**Output:** System baseline info

### Phase 2: Package & Vulnerability Scanning (Automated, ~1 hour)
Governor identifies outdated packages and known CVEs.

```bash
# Tools Governor uses
- apt/yum list --upgradable (for updates available)
- ubuntu-security-notices (if Ubuntu)
- CVE databases lookup
- Version comparison against known vulnerabilities
```

**Inputs:** Installed package list
**Output:** Vulnerability report with:
- Total packages
- Available updates
- Security updates available
- Known CVEs in current versions

### Phase 3: Service & Port Audit (Automated, ~0.5 hours)
Governor finds listening services and verifies they're necessary.

```bash
# Checks
- systemctl list-units --type=service (running services)
- netstat -tulpn (listening ports)
- Comparison against expected services
- Identification of unexpected services
```

**Inputs:** Service and network state
**Output:** Service audit report

### Phase 4: Access Control Review (Automated, ~1 hour)
Governor audits users, groups, permissions, and sudo access.

```bash
# Checks
- cat /etc/passwd (user list)
- cat /etc/sudoers (sudo privileges)
- lastlog (login history)
- check for empty password fields
- verify UID=0 accounts
- find files with SUID/SGID set
```

**Inputs:** /etc files and file permissions
**Output:** Access control report

### Phase 5: Configuration Review (Automated, ~1 hour)
Governor scans for common security misconfigurations.

```bash
# Checks
- SSH configuration (/etc/ssh/sshd_config)
- File permissions on sensitive files
- Firewall status and rules
- Selinux/Apparmor status
- Password policy settings
```

**Inputs:** Configuration files
**Output:** Configuration compliance report

### Phase 6: Log Review (Automated, ~0.5 hours)
Governor checks for suspicious activity in recent logs.

```bash
# Logs checked
- /var/log/auth.log (authentication attempts)
- /var/log/syslog (system events)
- Check for failed login attempts
- Look for unusual sudo usage
- Identify service errors
```

**Inputs:** System log files
**Output:** Log analysis summary

### Phase 7: Agent Audit (Automated, ~0.5 hours)
Governor audits OpenClaw agent behavior and configuration.

**What Governor checks:**
- Agent task completion rates and failure patterns
- Anomalous tool usage or unexpected commands issued
- Agent config drift from last known-good state
- Resource consumption per agent (CPU, memory, tokens)
- Agent-to-agent communication patterns
- Stale or abandoned tasks in agent queues
- Agent self-modifications (Governor reviews, not blocks)

**Output:** Agent audit report with improvement recommendations added to `backlog.md`

### Phase 8: Report Generation (~0.5 hours)
Governor compiles findings into an actionable report.

**Output:** Security audit report with:
- Findings organized by severity
- Recommendations for each issue
- Agent improvement suggestions
- Comparison to baseline (if exists)
- Timestamp and audit metadata

## Decision Points

At the end of each audit:
- **Critical issues found?** → Governor escalates to owner immediately via Telegram
- **Blockers for other tasks?** → Governor documents in `active_state.md`
- **New patterns identified?** → Governor updates monitoring rules automatically
- **Agent improvements identified?** → Governor adds recommendations to `backlog.md`

## Success Criteria

Audit is successful when:
- [ ] All system components inventoried
- [ ] All running services identified and justified
- [ ] Vulnerability list generated with severities
- [ ] Report delivered to owner
- [ ] Findings recorded in `backlog.md`
- [ ] Agent audit complete with recommendations recorded
- [ ] Next audit scheduled automatically

## Audit Scope

This is read-only for system state. No changes are made during audit.

If findings suggest immediate action is needed:
- Flag as critical in report
- Governor does not auto-execute fixes during audit phase
- Owner is notified; Governor awaits approval before remediating
- Decision is documented in `failures.md`

## Notes

- Governor runs audits during low-activity windows when possible
- Governor minimizes resource usage during scans
- All audit execution logs are preserved
- Governor's own behavior is auditable — audit logs are committed to this repo
