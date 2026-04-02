import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { appendFileSync } from "node:fs";

const ALERT_PATH = "/tmp/openclaw-governor-alerts.jsonl";

const DEFAULT_BLOCKED_TOOLS = ["write", "edit", "apply_patch"];

const EXEC_WRITE_PATTERNS = [
  /[^|]\s*>\s/,          // redirect (not pipe | >)
  />>/,                   // append redirect
  /\btee\s/,              // tee command
  /\bsed\s+-i/,           // in-place sed
  /\bpython3?\s.*open\(.*['"]w/, // python file write
  /\bmkdir\s/,            // create directory
  /\btouch\s/,            // create file
  /\bcp\s/,               // copy files
  /\bmv\s/,               // move files
  /\brm\s/,               // delete files
];

/**
 * Build the role guidance message from config.
 * Users configure which agents handle ops vs project work for their fleet.
 */
function buildRoleGuidance(cfg) {
  const opsAgent = cfg.opsAgent || "your ops/worker agent";
  const projectAgent = cfg.projectAgent || "your project manager agent";

  return [
    "ROLE CONSTRAINT: You are a coordinator. You NEVER create or edit files.",
    "If blocked from a command, delegate to the RIGHT agent:",
    `  - Quick ops task (run a script, system command, file write) → spawn ${opsAgent}`,
    `  - Project/feature/code work → spawn ${projectAgent}`,
    "You may run read-only commands (systemctl, ls, df, cat, grep, etc) yourself.",
  ].join("\n");
}

export default definePluginEntry({
  id: "role-guard",
  name: "Role Guard",
  description: "Deterministic role enforcement — blocks file writes for coordinator agents, escalates violations to Governor",

  register(api) {
    const cfg = api.pluginConfig ?? {};
    const guardedAgents = new Set(cfg.agents ?? ["main"]);
    const blockedTools = new Set(cfg.blockedTools ?? DEFAULT_BLOCKED_TOOLS);
    const roleGuidance = buildRoleGuidance(cfg);

    if (cfg.enabled === false) {
      api.logger.info("[role-guard] disabled by config");
      return;
    }

    const opsAgent = cfg.opsAgent || "ops/worker agent";
    const projectAgent = cfg.projectAgent || "project manager";

    function isWriteCommand(command) {
      if (typeof command !== "string") return false;
      return EXEC_WRITE_PATTERNS.some((p) => p.test(command));
    }

    function alertGovernor(agent, tool, command) {
      try {
        const entry = JSON.stringify({
          ts: new Date().toISOString(),
          agent,
          tool,
          command: typeof command === "string" ? command.slice(0, 200) : undefined,
          action: "blocked",
        });
        appendFileSync(ALERT_PATH, entry + "\n");
      } catch {
        // Alert file is best-effort — don't crash the plugin
      }
    }

    function blockReason(tool, agentId, command) {
      const base = command
        ? `[role-guard] exec write blocked for ${agentId}: ${command.slice(0, 100)}.`
        : `[role-guard] ${tool} blocked for ${agentId}.`;
      return `${base} Delegate to ${opsAgent} (quick ops) or ${projectAgent} (project work) via sessions_spawn.`;
    }

    // --- Hook 1: The Cage — block file writes ---
    api.on("before_tool_call", (event, ctx) => {
      if (!guardedAgents.has(ctx.agentId)) return;

      const tool = event.toolName;

      // Block named write tools
      if (blockedTools.has(tool)) {
        const reason = blockReason(tool, ctx.agentId);
        api.logger.warn(reason);
        alertGovernor(ctx.agentId, tool, null);
        return { block: true, blockReason: reason };
      }

      // Inspect exec commands for file-write patterns
      if (tool === "exec") {
        const command = event.params?.command ?? event.params?.args?.join?.(" ") ?? "";
        if (isWriteCommand(command)) {
          const reason = blockReason("exec", ctx.agentId, command);
          api.logger.warn(reason);
          alertGovernor(ctx.agentId, "exec", command);
          return { block: true, blockReason: reason };
        }
      }
    });

    // --- Hook 2: Reinforcement — inject role guidance into system prompt ---
    api.on("before_prompt_build", (_event, ctx) => {
      if (!guardedAgents.has(ctx.agentId)) return;
      return { prependSystemContext: roleGuidance };
    });

    api.logger.info(`[role-guard] guarding agents: ${[...guardedAgents].join(", ")}`);
  },
});
