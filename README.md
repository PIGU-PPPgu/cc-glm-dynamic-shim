# CC-GLM Dynamic Workflow Shim

[中文说明](README.zh-CN.md) | English

Unofficial compatibility shim. This project is not affiliated with, endorsed
by, or sponsored by Anthropic, Claude Code, Z.ai, or BigModel.

Local compatibility shim for using GLM Coding Plan models, especially
`glm-5.1`, behind Claude Code's Anthropic Messages API surface.

It is useful when a tool expects Anthropic-compatible `/v1/messages` requests,
but your GLM Coding Plan access is exposed through an OpenAI-compatible
`chat/completions` endpoint.

## Status

Smoke-tested with Claude Code dynamic workflows:

- Claude Code v2.1.170
- Model id: `glm-5.1`
- `/effort ultracode`: accepted
- Real `Workflow(...)` tool invocation: accepted
- Minimal dynamic workflow: 1 agent, completed in 11 seconds, result `OK`

This confirms the runtime path works. Larger real-world workflows still need
broader testing across repositories, task shapes, and Coding Plan tiers.

It accepts Claude Code requests such as:

- `POST /v1/messages`
- `POST /anthropic/v1/messages`

Then forwards them to BigModel's OpenAI-compatible chat completions endpoint:

`https://open.bigmodel.cn/api/coding/paas/v4/chat/completions`

## Run

```bash
cd cc-glm-dynamic-shim
GLM_MODEL=glm-5.1 GLM_SHIM_THINKING=enabled PORT=8787 npm start
```

## Fastest Setup

For a local macOS user, the fastest path is:

```bash
git clone https://github.com/PIGU-PPPgu/cc-glm-dynamic-shim.git
cd cc-glm-dynamic-shim
./quickstart.sh
```

This checks Node.js, runs tests, installs the LaunchAgent, starts the shim, and
prints the Claude Code / ccswitch settings you need.

You still need to provide your own BigModel Coding Plan API key in Claude Code
or ccswitch. The shim does not store or need your API key; it forwards the key
Claude Code sends in the request.

## Run Automatically

Install the macOS user LaunchAgent:

```bash
cd cc-glm-dynamic-shim
./install-launchagent.sh
```

Check it later:

```bash
./status.sh
```

Uninstall:

```bash
./uninstall-launchagent.sh
```

To override the upstream endpoint:

```bash
GLM_UPSTREAM_URL=https://open.bigmodel.cn/api/coding/paas/v4/chat/completions ./run.sh
```

Claude Code / ccswitch base URL:

```text
http://127.0.0.1:8787/anthropic
```

Keep the same BigModel API key in `ANTHROPIC_AUTH_TOKEN`.

## Suggested ccswitch env

See [examples/ccswitch-config.json](examples/ccswitch-config.json).

For plain Claude Code settings without ccswitch, see
[examples/claude-settings.json](examples/claude-settings.json).

```json
{
  "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787/anthropic",
  "ANTHROPIC_AUTH_TOKEN": "<your BigModel API key>",
  "ANTHROPIC_MODEL": "glm-5.1",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5.1",
  "ANTHROPIC_DEFAULT_OPUS_MODEL_NAME": "glm-5.1",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5.1",
  "ANTHROPIC_DEFAULT_SONNET_MODEL_NAME": "glm-5.1",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-5.1",
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
  "CLAUDE_CODE_SUBAGENT_MODEL": "glm-5.1"
}
```

Do not set `CLAUDE_CODE_EFFORT_LEVEL=max` while testing `/effort ultracode`.
Also avoid adding `[1M]` to the actual GLM model id. In this local test,
Claude Code rejected `glm-5.1[1M]` before the request reached the workflow
runtime, while plain `glm-5.1` worked.

## Logs

Redacted request summaries are written to `logs/` by default, or to the
LaunchAgent log directory when installed as a macOS service. Set
`GLM_SHIM_LOG_BODIES=1` only when you need request/response body debugging.
Do not share body logs without reviewing them first.

## Compatibility knobs

- `GLM_SHIM_THINKING=enabled` (default): send `thinking: { "type": "enabled" }`
  to BigModel, regardless of Claude Code's incoming thinking flag.
- `GLM_SHIM_THINKING=disabled`: force disabled thinking.
- `GLM_SHIM_THINKING=passthrough`: forward Claude Code's incoming thinking flag.
- `GLM_SHIM_THINKING=strip`: do not send a thinking field.

The shim intentionally does not forward Anthropic-only `reasoning_effort` to
BigModel's OpenAI-compatible endpoint. This avoids the class of third-party
errors where `reasoning_effort` conflicts with a disabled thinking option.

## Why not use `glm-5.1[1M]`?

Use plain `glm-5.1` as the actual model id. In local testing, Claude Code
rejected `glm-5.1[1M]` before the workflow runtime completed negotiation, while
plain `glm-5.1` worked.

## Development

```bash
npm test
```

Verify Claude Code can reach the shim:

```bash
./verify-claude-code.sh
```

Or with an explicit settings file:

```bash
./verify-claude-code.sh examples/claude-settings.json
```
