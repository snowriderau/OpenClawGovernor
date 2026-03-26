# Patch Management Workflow

## Purpose
Governor performs regular assessment and application of security patches and updates to keep target machines secure and stable. All phases are automated. Owner approval is required before production patch application.

## Frequency
- **Security patches:** Apply within 1 week of release
- **Regular updates:** Apply weekly, tested
- **Critical CVE:** Apply immediately upon identification

## Workflow Steps

### Phase 1: Update Assessment (Automated, ~0.5 hours)
Governor determines what updates are available and their importance.

```bash
# Governor runs on the target machine via SSH
- apt update (refresh package lists)
- apt list --upgradable (show available updates)
- apt-cache policy <package> (check specific versions)
```

**Output:** Available updates report with:
- Total updates available
- Security updates count
- Regular update count
- Critical CVE updates

### Phase 2: Security Review (Automated, ~1 hour)
Governor evaluates patches for risk and necessity.

For each security update:
- [ ] What vulnerability does it fix?
- [ ] How critical is the vulnerability?
- [ ] Is the target machine affected by this CVE?
- [ ] Known issues with this patch?
- [ ] Compatibility with the current setup?

**Tools (Governor-executed):**
- Ubuntu Security Advisories
- CVE databases
- Package changelogs
- Community reports

**Output:** Patch evaluation report

### Phase 3: Staging Environment (Automated, 2-4 hours)
Governor tests patches before applying to production.

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
**Output:** Test results and approval/rejection recommendation

### Phase 4: Approval & Scheduling (~0.5 hours)
Governor requests owner approval before production application.

**Approval needed for:**
- All security updates
- Kernel updates
- Major version updates
- Packages with breaking changes

**Governor sends this approval request to owner:**
```
Please review and approve patch application:
- Patches: [list]
- CVEs Fixed: [list]
- Risk Level: [Low / Medium / High]
- Estimated downtime: [none / X minutes]
- Rollback plan: [How to revert if needed]
- Scheduled for: [Date/Time]
```

### Phase 5: Backup & Snapshot (Automated, ~1 hour)
Governor creates a restore point before applying patches.

```bash
# Governor runs backup strategy
- Snapshot filesystem if possible
- Backup critical configs
- Backup application data
- Verify backup integrity
- Document backup location
```

**Output:** Backup verified and ready

### Phase 6: Patch Application (Automated, 0.5-2 hours)
Governor applies patches with continuous monitoring.

```bash
# Process
1. Schedule at maintenance window
2. Create backup checkpoint
3. Run apt upgrade --yes
4. Monitor for errors
5. Reboot if kernel updates applied
6. Verify all services running
7. Test critical functionality
```

**Monitoring during:**
- Watch for errors in output
- Check service status
- Monitor system logs
- Check disk space

**Output:** Patch application log written to `failures.md` if any issues occur

### Phase 7: Verification (Automated, ~1 hour)
Governor confirms patches applied correctly and system is stable.

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

### Phase 8: Documentation (Automated, ~0.5 hours)
Governor records what was done for audit and future reference.

**Governor documents:**
- Date and time of patching
- Patches applied (list)
- CVEs fixed
- Any issues encountered
- Test results
- System status post-patch

## Decision Points

### Should this patch be applied?
- Is it a security update? → **YES**
- Is the machine affected by the CVE? → **YES**
- Are there known issues? → Get owner approval
- Would it cause downtime? → Schedule and notify owner

### What if a patch causes issues?
- Governor logs the error in `failures.md`
- Governor rolls back to backup snapshot
- Governor documents issue and investigation
- Governor waits for patch fix or workaround
- Governor notifies owner with full report

## Success Criteria

Patching is successful when:
- [ ] All approved updates applied
- [ ] System stable and responsive
- [ ] Services running normally
- [ ] No errors in logs
- [ ] Verification tests passed
- [ ] Documentation updated by Governor

## Rollback Procedure

If a patch causes problems, Governor executes automatically:

```bash
# Step 1: Identify issue
# Governor checks logs, tests services, gathers evidence

# Step 2: Prepare for rollback
# Governor notifies owner of issue
# Governor begins service shutdown if needed

# Step 3: Restore from backup
# Restore filesystem snapshot, or
# Downgrade affected packages

# Step 4: Verify recovery
# Test services
# Verify data integrity
# Check logs

# Step 5: Document
# Record what went wrong in failures.md
# Update patch evaluation
# Plan alternative approach
```

## Notes

- Never patch an unbacked-up system — Governor verifies backup first
- Governor always tests in staging before production
- Rollback plan is documented before every patch run
- Patches are scheduled during maintenance windows
- Governor monitors heavily during and after patching
- Allow time for system to stabilize; Governor checks post-stabilization
