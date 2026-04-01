# Hook Reference — heartbeat-guard

Quick reference for the four hooks this plugin uses. Extracted from Openclaw Plugin SDK and docs.

## 1. before_agent_start (Sequential)

**When:** Before every agent run begins.
**Context:** `PluginHookAgentContext` — includes `trigger`, `runId`, `agentId`, `sessionKey`, `config`
**Returns:** `{ modelOverride?, providerOverride? }` or void

**Our use:** Capture `trigger` type and `runId`. Initialize counter entry in the Map.

```javascript
api.on("before_agent_start", (event, ctx) => {
  runs.set(ctx.runId, {
    trigger: ctx.trigger,  // "heartbeat" | "cron" | "user" | "memory"
    agentId: ctx.agentId,
    toolCalls: 0,
    tokens: 0
  });
});
```

## 2. llm_output (Parallel, observe-only)

**When:** After every LLM inference call completes.
**Context:** includes `runId`, `agentId`, `sessionKey`
**Event:** includes `usage: { input?, output?, cacheRead?, cacheWrite?, total? }`
**Returns:** void

**Our use:** Accumulate token usage on the run's counter entry.

## 3. before_tool_call (Sequential, CAN BLOCK)

**When:** Before every tool call executes.
**Context:** `PluginHookToolContext` — includes `runId`, `agentId`, `sessionKey`, `toolCallId`
**Event:** includes `toolName`, `params`
**Returns:** `{ block?: boolean, blockReason?: string }` or void

**Our use:** Increment tool call counter. Check against limits. Block if exceeded.

```javascript
api.on("before_tool_call", (event, ctx) => {
  const entry = runs.get(ctx.runId);
  if (!entry) return;
  
  entry.toolCalls++;
  const limits = getLimitsForTrigger(entry.trigger);
  
  if (limits.maxToolCalls > 0 && entry.toolCalls > limits.maxToolCalls) {
    return { block: true, blockReason: `[heartbeat-guard] Tool call limit (${limits.maxToolCalls}) exceeded` };
  }
});
```

**Precedence:** Once any plugin returns `{block: true}`, remaining handlers are skipped and the tool call is aborted. The agent sees a tool error with `blockReason` as the message.

## 4. agent_end (Parallel, observe-only)

**When:** After agent run completes (success or failure).
**Context:** includes `runId`, `agentId`, `sessionKey`
**Event:** includes `messages[]`, `success`, `durationMs`
**Returns:** void

**Our use:** Delete the run's counter entry from the Map. Log summary if configured.

## Fallback: runId unavailable

If `runId` is not present on `PluginHookToolContext`, use `sessionKey` as the Map key instead. Both `before_agent_start` and `before_tool_call` have `sessionKey`.
