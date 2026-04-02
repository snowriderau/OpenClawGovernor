import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, unlinkSync, existsSync } from "node:fs";

const ALERT_PATH = "/tmp/openclaw-governor-alerts.jsonl";

const DEFAULT_BLOCKED_TOOLS = ["write", "edit", "apply_patch"];

const EXEC_WRITE_PATTERNS = [
  /[^|]\s*>\s/,
  />>/,
  /\btee\s/,
  /\bsed\s+-i/,
  /\bpython3?\s.*open\(.*['"]w/,
  /\bmkdir\s/,
  /\btouch\s/,
  /\bcp\s/,
  /\bmv\s/,
  /\brm\s/,
];

function isWriteCommand(command) {
  if (typeof command !== "string") return false;
  return EXEC_WRITE_PATTERNS.some((p) => p.test(command));
}

function createMockApi(pluginConfig = {}) {
  const hooks = {};
  const logs = { debug: [], info: [], warn: [], error: [] };

  const api = {
    pluginConfig,
    logger: {
      debug: (msg) => logs.debug.push(msg),
      info: (msg) => logs.info.push(msg),
      warn: (msg) => logs.warn.push(msg),
      error: (msg) => logs.error.push(msg),
    },
    on(hookName, handler) {
      if (!hooks[hookName]) hooks[hookName] = [];
      hooks[hookName].push(handler);
    },
  };

  function fire(hookName, event = {}, ctx = {}) {
    const handlers = hooks[hookName] || [];
    let result;
    for (const h of handlers) {
      result = h(event, ctx);
    }
    return result;
  }

  return { api, hooks, logs, fire };
}

function loadPlugin(config = {}) {
  const { api, hooks, logs, fire } = createMockApi(config);
  const guardedAgents = new Set(config.agents ?? ["main"]);
  const blockedTools = new Set(config.blockedTools ?? DEFAULT_BLOCKED_TOOLS);

  api.on("before_tool_call", (event, ctx) => {
    if (!guardedAgents.has(ctx.agentId)) return;

    const tool = event.toolName;
    if (blockedTools.has(tool)) {
      const reason = `[role-guard] ${tool} blocked for ${ctx.agentId}. Delegate to PM.`;
      api.logger.warn(reason);
      return { block: true, blockReason: reason };
    }

    if (tool === "exec") {
      const command = event.params?.command ?? "";
      if (isWriteCommand(command)) {
        const reason = `[role-guard] exec write blocked for ${ctx.agentId}: ${command.slice(0, 100)}.`;
        api.logger.warn(reason);
        return { block: true, blockReason: reason };
      }
    }
  });

  api.on("before_prompt_build", (_event, ctx) => {
    if (!guardedAgents.has(ctx.agentId)) return;
    return { prependSystemContext: "ROLE CONSTRAINT" };
  });

  return { api, hooks, logs, fire };
}

describe("role-guard", () => {
  it("blocks write tool for guarded agent", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "write", params: {} }, { agentId: "main" });
    assert.ok(result?.block);
    assert.ok(result.blockReason.includes("write blocked"));
  });

  it("blocks edit tool for guarded agent", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "edit", params: {} }, { agentId: "main" });
    assert.ok(result?.block);
    assert.ok(result.blockReason.includes("edit blocked"));
  });

  it("allows write tool for non-guarded agent", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "write", params: {} }, { agentId: "forge" });
    assert.equal(result, undefined);
  });

  it("blocks exec with redirect", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "echo hello > /tmp/file.txt" } }, { agentId: "main" });
    assert.ok(result?.block);
    assert.ok(result.blockReason.includes("exec write blocked"));
  });

  it("blocks exec with append redirect", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "echo hello >> /tmp/file.txt" } }, { agentId: "main" });
    assert.ok(result?.block);
  });

  it("blocks exec with tee", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "ls | tee output.txt" } }, { agentId: "main" });
    assert.ok(result?.block);
  });

  it("blocks exec with sed -i", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "sed -i 's/old/new/' file.txt" } }, { agentId: "main" });
    assert.ok(result?.block);
  });

  it("blocks exec with mkdir", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "mkdir -p /tmp/newdir" } }, { agentId: "main" });
    assert.ok(result?.block);
  });

  it("blocks exec with cp", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "cp file1.txt file2.txt" } }, { agentId: "main" });
    assert.ok(result?.block);
  });

  it("allows exec with gog calendar", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "gog calendar list --days 7" } }, { agentId: "main" });
    assert.equal(result, undefined);
  });

  it("allows exec with systemctl", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "systemctl --user status openclaw-gateway" } }, { agentId: "main" });
    assert.equal(result, undefined);
  });

  it("allows exec with ls", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "ls -la /home/lowecloud" } }, { agentId: "main" });
    assert.equal(result, undefined);
  });

  it("allows exec with df", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "df -h / /media/lowecloud/aimodel" } }, { agentId: "main" });
    assert.equal(result, undefined);
  });

  it("allows exec with grep (pipe doesn't trigger redirect)", () => {
    const { fire } = loadPlugin();
    const result = fire("before_tool_call", { toolName: "exec", params: { command: "cat file.txt | grep pattern" } }, { agentId: "main" });
    assert.equal(result, undefined);
  });

  it("injects role guidance via before_prompt_build for guarded agent", () => {
    const { fire } = loadPlugin();
    const result = fire("before_prompt_build", {}, { agentId: "main" });
    assert.ok(result?.prependSystemContext?.includes("ROLE CONSTRAINT"));
  });

  it("does not inject guidance for non-guarded agent", () => {
    const { fire } = loadPlugin();
    const result = fire("before_prompt_build", {}, { agentId: "forge" });
    assert.equal(result, undefined);
  });
});
