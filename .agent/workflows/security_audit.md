# Security Audit Workflow

## Purpose
Regular security assessment to identify vulnerabilities, configuration issues, and compliance gaps.

## Frequency
- **Baseline:** Once at start (ASAP)
- **Regular:** Weekly
- **On-Demand:** When suspected compromise or major changes

## Workflow Steps

### Phase 1: System Inventory (0.5 hours)
Gather basic system information to understand the scope.

```bash
# What we're checking
- OS name, version, kernel version
- System uptime
- CPU, memory, disk usage
- Installed packages count
- Running services count
- Network interfaces and connectivity
```

**Inputs:** System commands (uname, lsb_release, etc.)
**Output:** System baseline info

### Phase 2: Package & Vulnerability Scanning (1 hour)
Identify outdated packages and known CVEs.

```bash
# Tools used
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

### Phase 3: Service & Port Audit (0.5 hours)
Find listening services and verify they're necessary.

```bash
# Checks
- systemctl list-units --type=service (running services)
- netstat -tulpn (listening ports)
- Comparison against expected services
- Identification of unexpected services
```

**Inputs:** Service and network state
**Output:** Service audit report

### Phase 4: Access Control Review (1 hour)
Audit users, groups, permissions, and sudo access.

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

### Phase 5: Configuration Review (1 hour)
Scan for common security misconfigurations.

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

### Phase 6: Log Review (0.5 hours)
Check for suspicious activity in recent logs.

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

### Phase 7: Report Generation (0.5 hours)
Compile findings into actionable report.

**Output:** Security audit report with:
- Findings organized by severity
- Recommendations for each issue
- Comparison to baseline (if exists)
- Timestamp and auditor info

## Decision Points

At the end of each audit:
- **Critical issues found?** -> Escalate to system owner immediately
- **Blockers for other tasks?** -> Document in active_state.md
- **New patterns identified?** -> Update monitoring rules

## Success Criteria

Audit is successful when:
- [ ] All system components inventoried
- [ ] All running services identified and justified
- [ ] Vulnerability list generated with severities
- [ ] Report delivered to system owner
- [ ] Findings recorded in backlog
- [ ] Next audit scheduled

## Rollback / Remediation

This is read-only. No changes are made during audit.

If findings suggest immediate action needed:
- Flag as critical in report
- Do not auto-execute fixes
- Await system owner approval
- Document decision

## Notes

- Run with caution in production
- Minimize resource usage during scans
- Run during low-activity windows if possible
- Preserve logs of audit execution
