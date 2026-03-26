#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

// Configuration
// Set LM_STUDIO_URL env var to point to your LM Studio instance.
// If running on the same machine: http://127.0.0.1:1234/v1
// If accessing over Tailscale: http://{{TAILSCALE_IP}}:1234/v1
const LM_STUDIO_URL =
  process.env.LM_STUDIO_URL || "http://{{TAILSCALE_IP}}:1234/v1";

// Available models from LM Studio
// Update this list to match the models you have loaded in LM Studio.
// Run `openclaw models scan` or check the LM Studio UI for model IDs.
const MODELS = [
  "unsloth/qwen3.5-35b-a3b-gguf",
  "qwen3.5-35b-a3b",
  "qwen/qwen3-coder-30b",
  "google/gemma-3-4b",
];

// Initialize MCP server
const server = new Server({
  name: "lmstudio-local",
  version: "1.0.0",
});

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "inference",
      description:
        "Run inference on LM Studio local GPU. Efficient for token-heavy tasks like code analysis, document processing, and batch text operations.",
      inputSchema: {
        type: "object",
        properties: {
          model: {
            type: "string",
            enum: MODELS,
            description:
              "Model to use: qwen3.5-35b-a3b (fast/balanced), qwen3-coder-30b (code tasks), gemma-3-4b (lightweight)",
          },
          prompt: {
            type: "string",
            description: "Text prompt for inference",
          },
          temperature: {
            type: "number",
            default: 0.7,
            minimum: 0,
            maximum: 2,
            description: "Sampling temperature",
          },
          max_tokens: {
            type: "integer",
            default: 1024,
            minimum: 1,
            maximum: 32768,
            description: "Maximum tokens to generate",
          },
        },
        required: ["model", "prompt"],
      },
    },
    {
      name: "list-models",
      description: "List available models on LM Studio",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
  ],
}));

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request;

  if (name === "inference") {
    return await handleInference(args);
  } else if (name === "list-models") {
    return await handleListModels();
  }

  throw new Error(`Unknown tool: ${name}`);
});

async function handleInference(args) {
  const { model, prompt, temperature = 0.7, max_tokens = 1024 } = args;

  if (!model || !prompt) {
    throw new Error("model and prompt are required");
  }

  try {
    console.error(`[inference] model=${model} tokens=${max_tokens}`);

    const response = await fetch(`${LM_STUDIO_URL}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model,
        messages: [{ role: "user", content: prompt }],
        temperature,
        max_tokens,
        stream: false,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(
        `LM Studio error ${response.status}: ${error.substring(0, 200)}`
      );
    }

    const data = await response.json();
    const msg = data.choices?.[0]?.message;
    const content = msg?.content || msg?.reasoning_content || "";
    const tokensUsed = data.usage?.completion_tokens || 0;

    console.error(
      `[inference] completed tokens_used=${tokensUsed} cached_from_local_gpu=true`
    );

    return {
      content: [
        {
          type: "text",
          text: content,
        },
      ],
      isError: false,
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Inference failed: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
}

async function handleListModels() {
  try {
    const response = await fetch(`${LM_STUDIO_URL}/models`, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch models: ${response.statusText}`);
    }

    const data = await response.json();
    const models = data.data.map((m) => m.id);

    return {
      content: [
        {
          type: "text",
          text: `Available models on LM Studio (${LM_STUDIO_URL}):\n${models.map((m) => `  - ${m}`).join("\n")}`,
        },
      ],
      isError: false,
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Failed to list models: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
}

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);

console.error(`[lmstudio-mcp] Connected to LM Studio at ${LM_STUDIO_URL}`);
console.error(`[lmstudio-mcp] Ready for inference requests`);
