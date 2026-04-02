import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

/**
 * announce-guard — Structural filter for subagent announce spam.
 *
 * Problem: The Openclaw runtime injects a hardcoded instruction telling
 * coordinators to forward every subagent completion as a user-facing
 * Telegram message. This creates noise for background orchestration work.
 *
 * Fix: Hook before_prompt_build. When subagent_announce messages are
 * detected in the session, inject a system-prompt-level override that
 * forces ::silent:: replies. System prompt outranks user-message
 * instructions — this is structural, not advisory.
 *
 * Scope: Only fires for agents listed in config (default: coordinators).
 */

const SILENT_TOKEN = "::silent::";

const OVERRIDE_INSTRUCTION = [
  "CRITICAL SYSTEM OVERRIDE — subagent announce handling:",
  `Reply ONLY with ${SILENT_TOKEN} to subagent completion events.`,
  "Do NOT convert completions into user-facing messages.",
  "Do NOT summarize, paraphrase, or forward agent work to Telegram.",
  `Exceptions — reply normally (not ${SILENT_TOKEN}) ONLY when ALL of these are true:`,
  "  1. The user EXPLICITLY requested this work in THIS session (not a heartbeat/cron)",
  "  2. The work is FULLY complete (not an intermediate status update)",
  "  3. The user is actively waiting for the result",
  "If in doubt, reply ::silent::. Noise is worse than silence.",
].join("\n");

export default definePluginEntry({
  id: "announce-guard",
  name: "Announce Guard",
  description: "Suppresses subagent announce forwarding for coordinator agents via system-prompt override",

  register(api) {
    const cfg = api.pluginConfig ?? {};
    const guardedAgents = new Set(cfg.agents ?? ["main"]);
    const enabled = cfg.enabled !== false;

    if (!enabled) {
      api.logger.info("[announce-guard] disabled by config");
      return;
    }

    api.on("before_prompt_build", (event, ctx) => {
      // Only intercept for guarded agents
      if (!guardedAgents.has(ctx.agentId)) return;

      // Check if any message in the session has subagent_announce provenance
      const messages = event.messages;
      if (!Array.isArray(messages)) return;

      const hasAnnounce = messages.some((m) => {
        const prov = m?.inputProvenance ?? m?.message?.inputProvenance;
        return prov?.sourceTool === "subagent_announce";
      });

      if (!hasAnnounce) return;

      // Inject system-prompt-level override — outranks the runtime's
      // user-message instruction to forward completions
      api.logger.debug?.("[announce-guard] subagent_announce detected, injecting suppression");
      return { prependSystemContext: OVERRIDE_INSTRUCTION };
    });

    api.logger.info(`[announce-guard] guarding agents: ${[...guardedAgents].join(", ")}`);
  },
});
