<!-- TEMPLATE: Define the user personas relevant to your deployment. -->
<!-- Remove this comment block when your personas are finalized.     -->

# User Personas

## Primary: Infrastructure Owner

The person who owns and operates the Linux machine(s). They use Claude Code on their development machine to manage infrastructure through the Governor pattern.

**Characteristics:**
- Comfortable with Linux command line and SSH
- Wants to automate routine sysadmin tasks
- Needs to maintain control over system changes
- May or may not have deep expertise in every subsystem (networking, GPU, security)

**Goals:**
- Reduce time spent on routine maintenance
- Catch security issues before they become incidents
- Deploy and manage services reliably
- Have a clear audit trail of all changes

**Pain Points:**
- Context switching between multiple systems and tools
- Forgetting to patch or audit regularly
- Debugging agent behavior when something goes wrong
- Losing track of what changed and when

---

## Secondary: Agent Developer

A developer who creates or modifies OpenClaw agent configurations. They define agent roles, tool bindings, and escalation rules.

**Characteristics:**
- Understands the OpenClaw runtime and configuration format
- Designs agent hierarchies and delegation patterns
- Tests agent behavior in development before deploying to production

**Goals:**
- Create agents that are focused and reliable
- Define clear boundaries between agent responsibilities
- Build escalation paths that prevent agents from acting outside their scope

---

## Tertiary: Team Member

Someone who receives notifications from agents (via Telegram, Slack, etc.) or occasionally reviews the Governor's logs, but does not directly operate the system.

**Characteristics:**
- Needs to be informed about incidents and status changes
- May respond to approval requests forwarded by agents
- Does not SSH into the target machine directly

**Goals:**
- Stay informed without being overwhelmed by alerts
- Quickly understand incident severity and required action
- Trust that the system is being managed competently
