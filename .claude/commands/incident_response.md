# Incident Response Workflow

## Purpose
Rapid identification, containment, and remediation of security incidents while preserving evidence and maintaining system availability. All phases are Governor-driven. The owner is notified and consulted on high-stakes decisions, but does not execute steps directly.

## Incident Classification

### Severity Levels

**CRITICAL** (Respond in minutes)
- Active compromise/breach
- Unauthorized access attempt
- Malware detection
- Data exfiltration detected
- Service hijacking

**HIGH** (Respond in hours)
- Multiple failed login attempts from unknown source
- Unusual sudo usage patterns
- Configuration tampering detected
- Suspicious new user accounts
- Unexpected outbound connections

**MEDIUM** (Respond within 1 day)
- Unusual process execution
- File permission anomalies
- Configuration drift from baseline
- Unexpected service restart patterns
- Log manipulation detected

**LOW** (Log and monitor)
- Informational findings
- Expected security events
- Automated security tool alerts
- Non-security operational issues

## Incident Response Phases

### Phase 1: Detection & Validation (Minutes)
Governor confirms the incident is real and understands its scope.

**Automated Actions:**
1. Receive alert from monitoring layer or agent report
2. Verify finding is not a false positive
3. Determine incident severity
4. Identify affected systems/services
5. Record exact time of discovery in `failures.md`

**Decision:** Proceed to Phase 2 or escalate to owner if critical

### Phase 2: Containment (Minutes to Hours)
Governor limits damage and prevents spread without destroying evidence.

**Possible Actions (CRITICAL requires owner approval, lower severities are autonomous):**
- Disable compromised user account
- Kill malicious process
- Revoke suspicious SSH keys
- Block suspicious IP addresses
- Isolate service from network (if severe)
- Preserve logs and evidence

**Do NOT:**
- Delete suspicious files
- Clear logs
- Restart services prematurely
- Overwrite memory/running processes

**Output:** Containment action log written to `failures.md`

### Phase 3: Investigation (Hours to Days)
Governor investigates what happened and how.

**Investigate:**
- Timeline of events leading up to incident
- Attack vector or vulnerability used
- Scope of compromise (what was accessed)
- Proof of unauthorized access
- Methods used by attacker
- Any tools or malware involved

**Evidence Collection:**
- Preserve suspicious files (hash/copy)
- Capture network connections
- Export relevant logs
- Document system state

**Output:** Incident investigation report delivered to owner

### Phase 4: Remediation (Hours to Days)
Governor applies fixes and restores normal operation. Owner approves before execution.

**Tasks:**
1. Apply security patch if CVE exploited
2. Remove malware or backdoors
3. Reset credentials if compromised
4. Restore from clean backup if needed
5. Update firewall/access control rules
6. Implement additional monitoring
7. Harden configuration against recurrence

**Approval:** Owner approves the remediation plan; Governor executes it

**Output:** Remediation action log

### Phase 5: Recovery & Validation (Hours)
Governor restores normal operations and verifies the system is secure.

**Actions:**
1. Restore services to normal operation
2. Re-enable user accounts (if applicable)
3. Clear quarantine/containment measures
4. Verify all services functioning
5. Run security audit post-incident
6. Confirm no residual compromise

**Validation:**
- [ ] All services responding normally
- [ ] No suspicious processes
- [ ] Logs show normal activity
- [ ] Performance baseline restored
- [ ] Agents can access resources

**Output:** Recovery verification report

### Phase 6: Post-Incident Review (1-2 Days)
Governor learns from the incident to prevent future occurrences.

**Review:**
1. Root cause analysis
   - How did vulnerability exist?
   - Why wasn't it caught?
   - How was it exploited?

2. Timeline review
   - When should detection have fired?
   - How fast was response?
   - What could be faster?

3. Preventive measures
   - Patch or update required?
   - Configuration hardening needed?
   - New monitoring needed?
   - Process improvements?

4. Detection improvements
   - Should Governor have caught this earlier?
   - What log patterns indicate this attack?
   - Add to automated detection rules?

**Output:** Post-incident report with recommendations; Governor self-improves detection rules

## Decision Tree

```
Incident Detected (by monitoring layer or agent)
    ↓
Is this confirmed? (Not false positive)
    ├─ NO → Governor logs as false positive, updates detection rules
    └─ YES → Determine severity
        ↓
Is this CRITICAL?
    ├─ YES → Governor immediately notifies owner
    │       → Containment initiated; owner approval for invasive actions
    │       → Investigation and remediation begin
    └─ NO → Governor handles autonomously up to HIGH severity
        → Owner receives daily report
        → Governor proceeds with investigation
```

## Response Time Targets

- **CRITICAL:** Detection within 5 min, Containment within 15 min
- **HIGH:** Detection within 30 min, Containment within 2 hours
- **MEDIUM:** Detection within 4 hours, Contained same day
- **LOW:** Logged, addressed in routine maintenance

## Incident Report Template

Governor populates this automatically:

```
INCIDENT #XXX
Date/Time: YYYY-MM-DD HH:MM:SS
Severity: [CRITICAL / HIGH / MEDIUM / LOW]
Detected By: [Governor monitoring layer / agent report]

DESCRIPTION
What happened?

IMPACT
- Affected systems:
- Affected data:
- Agent impact:
- Downtime: (if any)

TIMELINE
- HH:MM - Event 1
- HH:MM - Event 2
- HH:MM - Detection
- HH:MM - Containment started

INVESTIGATION
- Root cause:
- Attack vector:
- Scope of compromise:

REMEDIATION
- Actions taken:
- Time to recovery:
- Preventive measures:

LESSONS LEARNED
- What went well:
- What could be better:
- Process improvements:
```

## Escalation Matrix

**Immediate Owner Notification:**
- CRITICAL incidents
- Potential data exposure
- Successful breach attempts
- Service outages

**Daily Report:**
- HIGH severity incidents
- Pattern of unusual activity
- Configuration tampering
- Failed attack attempts

**Weekly Review:**
- Summary of all incidents
- Trends and patterns
- Improvement recommendations
- Compliance implications

## Communication

### Internal Logging
- All incidents recorded automatically in `.agent/memory/failures.md`
- Evidence preserved for audit trail
- Decision log maintained

### To System Owner
- CRITICAL: Immediate Telegram notification + brief status
- Updates every 30 minutes during active incident
- Final report within 24 hours of resolution

### Do NOT
- Share incident details publicly
- Disclose to unauthorized parties
- Communicate with external entities
- Send through unsecured channels

## Tools & Resources

**Investigation Tools (Governor-executed):**
- System logs (auth.log, syslog)
- Process monitoring (ps, top, systemd-journal)
- Network analysis (netstat, ss, tcpdump)
- File integrity checking (find, stat, md5sum)
- String searching (grep, strings)

**Remediation Tools (Governor-executed, owner-approved):**
- Package managers (apt, yum)
- User management (useradd, passwd, sudoers)
- Firewall (ufw, iptables)
- SSH key management
- Configuration backup/restore

## Incident Prevention

Best practices Governor enforces continuously:
1. Keep system patches current via patch_management workflow
2. Monitor logs automatically via scheduled audits
3. Maintain strong access controls, audited regularly
4. Regular security audits via security_audit workflow
5. Backup critical data automatically
6. Host-based IDS (Auditd) monitored by Governor
7. Governor audits agent behavior for anomalous patterns
8. Incident procedures are tested and improved automatically after each incident
