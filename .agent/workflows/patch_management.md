# Patch Management Workflow

## Purpose
Regular assessment and application of security patches and updates to keep system secure and stable.

## Frequency
- **Security patches:** Apply within 1 week of release
- **Regular updates:** Apply weekly, tested
- **Critical CVE:** Apply immediately upon identification

## Workflow Steps

### Phase 1: Update Assessment (0.5 hours)
Determine what updates are available and their importance.

```bash
# Commands
- apt update (refresh package lists)
- apt list --upgradable (show available updates)
- apt-cache policy <package> (check specific versions)
```

**Output:** Available updates report with:
- Total updates available
- Security updates count
- Regular update count
- Critical CVE updates

### Phase 2: Security Review (1 hour)
Evaluate patches for risk and necessity.

For each security update:
- [ ] What vulnerability does it fix?
- [ ] How critical is the vulnerability?
- [ ] Are we affected by this CVE?
- [ ] Known issues with this patch?
- [ ] Compatibility with our setup?

**Tools:**
- Ubuntu Security Advisories
- CVE databases
- Package changelogs
- Community reports

**Output:** Patch evaluation report

### Phase 3: Staging Environment (2-4 hours)
Test patches before applying to production.

```bash
# Option 1: Test in VM or container
- Snapshot current system
- Apply updates
- Test critical functionality
- Verify no breakage
- Document results

# Option 2: Test key applications
- Run service health checks
- Test application functionality
- Monitor logs for errors
- Verify no regressions
```

**Inputs:** Patches to test
**Output:** Test results and approval/rejection

### Phase 4: Approval & Scheduling (0.5 hours)
Get system owner approval before production application.

**Approval needed for:**
- All security updates
- Kernel updates
- Major version updates
- Packages with breaking changes

**Approval template:**
```
Please review and approve patch application:
- Patches: [list]
- CVEs Fixed: [list]
- Risk Level: [Low / Medium / High]
- Estimated downtime: [none / X minutes]
- Rollback plan: [How to revert if needed]
- Scheduled for: [Date/Time]
```

### Phase 5: Backup & Snapshot (1 hour)
Create restore point before applying patches.

```bash
# Backup strategy
- Snapshot filesystem if possible
- Backup critical configs
- Backup application data
- Verify backup integrity
- Document backup location
```

**Output:** Backup verified and ready

### Phase 6: Patch Application (0.5-2 hours)
Apply patches with monitoring.

```bash
# Process
1. Schedule at maintenance window
2. Notify system users
3. Create backup checkpoint
4. Run apt upgrade --yes
5. Monitor for errors
6. Reboot if kernel updates applied
7. Verify all services running
8. Test critical functionality
```

**Monitoring during:**
- Watch for errors in output
- Check service status
- Monitor system logs
- Check disk space

**Output:** Patch application log

### Phase 7: Verification (1 hour)
Confirm patches applied correctly and system stable.

```bash
# Checks
- All updates applied? (apt list --upgradable should be empty)
- System bootable? (If reboot done)
- All services running?
- No new errors in logs?
- Application functionality working?
- Network connectivity stable?
```

**Output:** Post-patch verification report

### Phase 8: Documentation (0.5 hours)
Record what was done for audit and future reference.

**Document:**
- Date and time of patching
- Patches applied (list)
- CVEs fixed
- Any issues encountered
- Test results
- System status post-patch

## Decision Points

### Should we apply this patch?
- Is it a security update? -> **YES**
- Is system affected by CVE? -> **YES**
- Are there known issues? -> Get owner approval
- Would it cause downtime? -> Schedule and notify

### What if patch causes issues?
- Log the error in failures.md
- Rollback to backup snapshot
- Document issue and investigation
- Wait for patch fix or workaround
- Notify system owner

## Success Criteria

Patching is successful when:
- [ ] All approved updates applied
- [ ] System stable and responsive
- [ ] Services running normally
- [ ] No errors in logs
- [ ] Verification tests passed
- [ ] Documentation updated

## Rollback Procedure

If patch causes problems:

```bash
# Step 1: Identify issue
# Check logs, test services, gather evidence

# Step 2: Prepare for rollback
# Notify users of issue
# Begin service shutdown if needed

# Step 3: Restore from backup
# Restore filesystem snapshot, or
# Downgrade affected packages

# Step 4: Verify recovery
# Test services
# Verify data integrity
# Check logs

# Step 5: Document
# Record what went wrong
# Update patch evaluation
# Plan alternative approach
```

## Notes

- Never patch unbackup'd system
- Always test in staging first
- Keep rollback plan documented
- Schedule during maintenance window
- Monitor heavily during and after
- Allow time for system to stabilize
