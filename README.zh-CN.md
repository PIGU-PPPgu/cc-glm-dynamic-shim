# CC-GLM Dynamic Workflow Shim

中文 | [English](README.md)

非官方兼容层。本项目与 Anthropic、Claude Code、Z.ai、BigModel 没有关联，也不代表它们的官方认可、赞助或背书。

这是一个本地 Anthropic Messages API 兼容层，用来把 Claude Code 发出的 Anthropic 风格请求转换到智谱 BigModel Coding Plan 的 OpenAI 兼容接口。它的主要目标是让 `glm-5.1` 能在 Claude Code 里正常走 dynamic workflow / ultracode 这条路径。

## 当前状态

已经用 Claude Code dynamic workflow 做过最小烟测：

- Claude Code v2.1.170
- 模型 ID：`glm-5.1`
- `/effort ultracode`：可接受
- 真实 `Workflow(...)` 工具调用：可接受
- 最小 dynamic workflow：1 个 agent，约 11 秒完成，结果为 `OK`

这说明核心运行链路是通的。不过更大的真实项目、多 agent 并发、不同仓库形态、不同 Coding Plan 权限档位，仍然需要更多测试。

## 它解决什么问题

Claude Code 的 dynamic workflow 依赖 Anthropic Messages API 的请求形态、工具调用和流式响应格式。智谱 Coding Plan 目前给用户暴露的是 OpenAI 兼容的 `chat/completions` 接口，因此直接把 Claude Code 指到智谱接口时，可能会出现普通对话能跑、但 dynamic workflow 不触发或工具协商失败的情况。

这个 shim 做的事情是：

- 接收 Claude Code 的 `POST /v1/messages` 或 `POST /anthropic/v1/messages`
- 清理和转换 Claude Code 传来的工具 schema
- 把 Anthropic messages 转成 OpenAI chat messages
- 把 Anthropic tools 转成 OpenAI function tools
- 把 OpenAI tool calls 转回 Anthropic `tool_use`
- 把 OpenAI SSE 流式响应转回 Anthropic SSE
- 默认使用 `glm-5.1`

上游接口是：

```text
https://open.bigmodel.cn/api/coding/paas/v4/chat/completions
```

## 最快安装

macOS 用户建议直接用 quickstart：

```bash
git clone https://github.com/PIGU-PPPgu/cc-glm-dynamic-shim.git
cd cc-glm-dynamic-shim
./quickstart.sh
```

这个脚本会检查 Node.js、运行测试、安装 macOS LaunchAgent、启动本地 shim，并打印 Claude Code / ccswitch 需要填写的配置。

你仍然需要自己的 BigModel Coding Plan API key。shim 不保存 key，它只是转发 Claude Code 请求里带来的 key。

## 手动运行

如果你只是临时测试，可以直接跑：

```bash
GLM_MODEL=glm-5.1 GLM_SHIM_THINKING=enabled PORT=8787 npm start
```

健康检查：

```bash
curl http://127.0.0.1:8787/health
```

Claude Code / ccswitch 里的 Base URL 填：

```text
http://127.0.0.1:8787/anthropic
```

API key 仍然填你的 BigModel Coding Plan key。

## 开机自动运行

安装 macOS 用户级 LaunchAgent：

```bash
./install-launchagent.sh
```

查看状态：

```bash
./status.sh
```

卸载：

```bash
./uninstall-launchagent.sh
```

安装后，shim 会在后台监听：

```text
http://127.0.0.1:8787
```

日志默认在：

```text
~/Library/Logs/glm-anthropic-shim/
```

## ccswitch 配置

可以直接参考：

- [examples/ccswitch-config.json](examples/ccswitch-config.json)
- [examples/claude-settings.json](examples/claude-settings.json)

关键环境变量如下：

```json
{
  "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787/anthropic",
  "ANTHROPIC_AUTH_TOKEN": "<你的 BigModel Coding Plan API key>",
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

建议同时确认：

```json
{
  "disableWorkflows": false,
  "workflowKeywordTriggerEnabled": true
}
```

测试 `/effort ultracode` 时，不要设置：

```text
CLAUDE_CODE_EFFORT_LEVEL=max
```

这个变量可能会把 effort 锁死，导致你在 Claude Code 里切不到 ultracode。

## 为什么模型名要用 glm-5.1

请把实际模型 ID 写成：

```text
glm-5.1
```

不要写成：

```text
glm-5.1[1M]
```

本地测试里，`glm-5.1[1M]` 会在 Claude Code 侧提前被判定为模型不可用，workflow 还没完成协商就失败了。plain `glm-5.1` 可以正常触发 dynamic workflow。

如果你想让 workflow 子 agent 也用 5.1，记得设置：

```text
CLAUDE_CODE_SUBAGENT_MODEL=glm-5.1
ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-5.1
```

否则 UI 里可能会看到 worker 显示成 `glm-5`。

## 验证 Claude Code 是否能连上

先确认 shim 正常：

```bash
./status.sh
```

再跑：

```bash
./verify-claude-code.sh
```

如果你想用指定 settings 文件：

```bash
./verify-claude-code.sh examples/claude-settings.json
```

成功时应返回：

```text
OK
```

## 验证 dynamic workflow

进入 Claude Code 后执行：

```text
/effort ultracode
```

然后给一个尽可能小的真实 workflow 测试：

```text
ultracode: start the smallest possible real dynamic workflow. One workflow, one tiny agent, no file edits. Final answer exactly OK.
```

如果 Claude Code 弹出类似 “Run a dynamic workflow?” 的确认，或者之后在 `/workflows` 里看到工作流记录，就说明不是普通 Task，而是真正的 dynamic workflow 路径。

查看 workflow：

```text
/workflows
```

理想结果是能看到：

- workflow 名称
- phases / agents
- agent 模型名
- token 和耗时
- completed / done 状态

## Thinking 兼容选项

默认：

```text
GLM_SHIM_THINKING=enabled
```

可选值：

- `enabled`：默认值，固定给 BigModel 发送 `thinking: { "type": "enabled" }`
- `disabled`：固定关闭 thinking
- `passthrough`：透传 Claude Code 传入的 thinking 字段
- `strip`：不发送 thinking 字段

shim 不会把 Anthropic 专用的 `reasoning_effort` 转发给 BigModel 的 OpenAI 兼容接口，这样可以避开一些第三方兼容层里 `reasoning_effort` 和 thinking 状态冲突导致的 400 错误。

## 日志

默认只记录脱敏后的请求摘要。只有排查问题时才建议打开完整 body 日志：

```bash
GLM_SHIM_LOG_BODIES=1 npm start
```

不要直接公开分享 body 日志，里面可能包含提示词、路径、工具参数或其他敏感信息。

## 常见问题

### 普通聊天可以，dynamic workflow 不出现

检查：

- Claude Code 里是否执行了 `/effort ultracode`
- 提示词里是否明确包含 `ultracode`
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `disableWorkflows` 是否为 `false`
- `workflowKeywordTriggerEnabled` 是否为 `true`
- 是否误设置了 `CLAUDE_CODE_EFFORT_LEVEL=max`

### workflow 里 worker 显示 glm-5，不是 glm-5.1

检查：

```text
CLAUDE_CODE_SUBAGENT_MODEL=glm-5.1
ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-5.1
```

改完后重启 Claude Code。旧 workflow 记录不会变，新的 workflow 才会显示新模型。

### Claude Code 提示模型不存在或不可访问

先把所有实际模型 ID 改成：

```text
glm-5.1
```

不要使用 `glm-5.1[1M]` 作为请求模型名。

### 端口被占用

默认端口是 `8787`。如果要换端口：

```bash
PORT=8788 npm start
```

对应地，Claude Code / ccswitch 的 Base URL 也要改成：

```text
http://127.0.0.1:8788/anthropic
```

### 这个项目是不是官方的

不是。它是社区兼容层，目标是补齐 Claude Code 和 GLM Coding Plan OpenAI 兼容接口之间的协议差异。

## 开发

运行测试：

```bash
npm test
```

启动服务：

```bash
npm start
```

本地验证：

```bash
./verify-claude-code.sh
```

## License

MIT
