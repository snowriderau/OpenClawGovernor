import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const DEFAULT_LIMITS = {
  heartbeat: { maxToolCalls: 10, maxTokens: 50000 },
  cron:      { maxToolCalls: 30, maxTokens: 150000 },
  user:      { maxToolCalls: -1, maxTokens: -1 },
  memory:    { maxToolCalls: 20, maxTokens: 100000 },
  default:   { maxToolCalls: 50, maxTokens: 200000 },
};

const LOG_PATH = join(homedir(), ".openclaw", "logs", "heartbeat-guard.log");

export default definePluginEntry({
  id: "heartbeat-guard",
  name: "Heartbeat Guard",
  description: "Circuit breaker for runaway heartbeat and cron tool loops",

  register(api) {
    /** @type {Map<string, {trigger: string, agentId: string, toolCalls: number, tokens: number, blocked: boolean}>} */
    const runs = new Map();

    let pluginConfig = null;

    function getConfig() {
      if (pluginConfig) return pluginConfig;
      try {
        pluginConfig = api.getPluginConfig?.() ?? {};
      } catch {
        pluginConfig = {};
      }
      return pluginConfig;
    }

    function getLimits(trigger) {
      const cfg = getConfig();
      const cfgLimits = cfg?.limits ?? {};
      const triggerKey = trigger || "default";
      const merged = { ...DEFAULT_LIMITS[triggerKey], ...cfgLimits[triggerKey] };
      return merged.maxToolCalls != null ? merged : DEFAULT_LIMITS.default;
    }

    function shouldLog() {
      return getConfig()?.log !== false;
    }

    function log(msg) {
      if (!shouldLog()) return;
      try {
        const ts = new Date().toISOString();
        appendFileSync(LOG_PATH, `${ts} ${msg}\n`);
      } catch {
        // silent — logging should never crash the plugin
      }
    }

    function runKey(ctx) {
      return ctx.runId || ctx.sessionKey || "unknown";
    }

    function inferTrigger(sessionKey) {
      if (!sessionKey) return "default";
      if (sessionKey.includes(":heartbeat:")) return "heartbeat";
      if (sessionKey.includes(":cron:")) return "cron";
      if (sessionKey.includes(":telegram:") || sessionKey.includes(":direct:")) return "user";
      if (sessionKey.includes(":subagent:")) return "default";
      return "default";
    }

    api.on("before_agent_start", (_event, ctx) => {
      const key = runKey(ctx);
      const trigger = ctx.trigger || inferTrigger(ctx.sessionKey);
      runs.set(key, {
        trigger,
        agentId: ctx.agentId || "?",
        toolCalls: 0,
        tokens: 0,
        blocked: false,
      });
      log(`[start] run=${key} agent=${ctx.agentId} trigger=${trigger}`);
    });

    api.on("llm_output", (event, ctx) => {
      const key = runKey(ctx);
      const entry = runs.get(key);
      if (!entry) return;
      const usage = event.usage;
      if (usage) {
        entry.tokens += usage.total ?? ((usage.input ?? 0) + (usage.output ?? 0));
      }
    });

    api.on("before_tool_call", (event, ctx) => {
      const key = runKey(ctx);
      const entry = runs.get(key);
      if (!entry) return;

      entry.toolCalls++;
      const limits = getLimits(entry.trigger);

      if (limits.maxToolCalls > 0 && entry.toolCalls > limits.maxToolCalls) {
        entry.blocked = true;
        const reason = `[heartbeat-guard] Tool call limit exceeded: ${entry.toolCalls}/${limits.maxToolCalls} (trigger=${entry.trigger}, agent=${entry.agentId})`;
        log(`[BLOCKED] ${reason} tokens=${entry.tokens}`);
        return { block: true, blockReason: reason };
      }

      if (limits.maxTokens > 0 && entry.tokens > limits.maxTokens) {
        entry.blocked = true;
        const reason = `[heartbeat-guard] Token budget exceeded: ${entry.tokens}/${limits.maxTokens} (trigger=${entry.trigger}, agent=${entry.agentId})`;
        log(`[BLOCKED] ${reason} toolCalls=${entry.toolCalls}`);
        return { block: true, blockReason: reason };
      }
    });

    api.on("agent_end", (_event, ctx) => {
      const key = runKey(ctx);
      const entry = runs.get(key);
      if (entry) {
        log(`[end] run=${key} agent=${entry.agentId} trigger=${entry.trigger} tools=${entry.toolCalls} tokens=${entry.tokens} blocked=${entry.blocked}`);
        runs.delete(key);
      }
    });

    log("[init] heartbeat-guard plugin loaded");
  },
});
