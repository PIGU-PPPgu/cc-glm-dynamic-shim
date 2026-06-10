import assert from "node:assert/strict";
import { anthropicToOpenAI, normalizeModel, openAIToAnthropic } from "./server.mjs";

assert.equal(normalizeModel("glm-5.1[1M]"), "glm-5.1");
assert.equal(normalizeModel("claude-opus-4-6"), "glm-5.1");

const converted = anthropicToOpenAI({
  model: "glm-5.1[1M]",
  system: "You are terse.",
  stream: true,
  max_tokens: 1000,
  thinking: { type: "enabled", budget_tokens: 1024 },
  tools: [
    {
      name: "Workflow",
      description: "Run a dynamic workflow",
      input_schema: { type: "object", properties: { task: { type: "string" } } },
    },
  ],
  messages: [
    { role: "user", content: [{ type: "text", text: "Use workflow." }] },
    {
      role: "assistant",
      content: [
        { type: "text", text: "Calling." },
        { type: "tool_use", id: "toolu_1", name: "Workflow", input: { task: "OK" } },
      ],
    },
    {
      role: "user",
      content: [
        { type: "tool_result", tool_use_id: "toolu_1", content: "OK" },
        { type: "text", text: "finish" },
      ],
    },
  ],
});

assert.equal(converted.model, "glm-5.1");
assert.deepEqual(converted.thinking, { type: "enabled" });
assert.equal(converted.tools[0].function.name, "Workflow");
assert.equal(converted.messages[0].role, "system");
assert.equal(converted.messages[2].tool_calls[0].function.name, "Workflow");
assert.equal(converted.messages[3].role, "tool");

const anthropic = openAIToAnthropic(
  {
    id: "chatcmpl_1",
    choices: [
      {
        finish_reason: "tool_calls",
        message: {
          content: "",
          tool_calls: [
            {
              id: "call_1",
              type: "function",
              function: { name: "Workflow", arguments: "{\"task\":\"OK\"}" },
            },
          ],
        },
      },
    ],
    usage: { prompt_tokens: 10, completion_tokens: 5 },
  },
  "glm-5.1[1M]",
);

assert.equal(anthropic.stop_reason, "tool_use");
assert.equal(anthropic.content[0].type, "tool_use");
assert.deepEqual(anthropic.content[0].input, { task: "OK" });

console.log("ok");
