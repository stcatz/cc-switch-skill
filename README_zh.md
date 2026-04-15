# cc-switch Skill (独立版本)

[![许可证: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-green.svg)](https://claude.ai/code)

一个独立管理 AI provider 配置的 Claude Code 技能。**无需桌面应用**，纯 JSON 配置 + Shell 脚本实现。

支持在 **Claude Code**、**Codex**、**Gemini CLI**、**OpenCode** 和 **OpenClaw** 之间切换 provider。

---

## 🚀 快速开始

### 安装

#### 方式 1：一键安装（推荐）

```bash
# 下载并安装最新版本
curl -sSL https://raw.githubusercontent.com/stcatz/cc-switch-skill/main/install.sh | bash
```

#### 方式 2：手动安装

```bash
# 克隆仓库
git clone https://github.com/stcatz/cc-switch-skill.git ~/.claude/skills/cc-switch

# 或下载后手动复制
cp -r cc-switch ~/.claude/skills/

# 重启 Claude Code
```

### 首次使用

```bash
# 初始化配置目录和预设（自动执行）
~/.claude/skills/cc-switch/scripts/list_providers.sh

# 查看预设的 provider
jq '.presets[] | {name}' ~/.claude/skills/cc-switch/presets.json
```

---

## 📖 使用指南

### 添加 Provider

```bash
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "MiniMax" \
  --app claude \
  --key "sk-xxx" \
  --url "https://api.minimax.com/v1" \
  --sonnet "claude-3-5-sonnet-20241022"
```

### 列出 Provider

```bash
# 列出所有应用的 provider
~/.claude/skills/cc-switch/scripts/list_providers.sh

# 只列 Claude Code 的 provider
~/.claude/skills/cc-switch/scripts/list_providers.sh --app claude

# 只列 Codex 的 provider
~/.claude/skills/cc-switch/scripts/list_providers.sh --app codex
```

**输出示例：**
```
======================================
        Providers List
======================================

### claude
ID                                      | Name                        | Status
--------------------------------------+------------------------------+--------
a1b2c3d4-e5f6-7890-abcd-ef1234567890    | Anthropic Official         | [Active]
b2c3d4e5-f6a7-8901-bcde-fa2345678901    | MiniMax                  | |
c3d4e5f6-a7b8-9012-cdef-ab3456789012    | Zhipu AI                | |
```

### 切换 Provider

```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh \
  --app claude \
  --name "MiniMax"
```

**切换后：**
- **Claude Code**：立即生效，无需重启
- **其他应用**：需要重启终端

### 删除 Provider

```bash
~/.claude/skills/cc-switch/scripts/delete_provider.sh \
  --id provider-uuid
```

### 测试连通性

```bash
~/.claude/skills/cc-switch/scripts/test_connectivity.sh \
  --app claude \
  --name "MiniMax"
```

**输出示例：**
```
======================================
        Connectivity Test
======================================

Provider: MiniMax
App Type: claude
API Endpoint: https://api.minimax.com/v1

======================================
✅ Test Successful

| 指标        | 结果 |
|------------|------|
| HTTP 状态   | 200 OK |
| 响应时间    | 1.92s |
| 使用的模型    | claude-3-5-sonnet-20241022 |
```

---

## 🔧 预设 Provider

内置预设的 provider（在 `presets.json` 中）：

| 名称 | 应用 | 说明 |
|------|------|------|
| Anthropic Official | claude, gemini | Anthropic 官方 API |
| MiniMax Official | claude | MiniMax 官方 API |
| Zhipu AI Official | claude | Zhipu AI 官方 API |
| DeepSeek Official | claude | DeepSeek 官方 API |

### 使用预设添加

```bash
# 1. 查看预设 ID
jq '.presets[] | select(.name) | .id' ~/.claude/skills/cc-switch/presets.json

# 2. 使用预设添加（替换为你的 API 密钥）
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "我的 MiniMax" \
  --app claude \
  --key "your-api-key-here" \
  --url "https://api.minimax.com/v1"
```

---

## 📊 支持的应用

| 应用 | app_type | 热切换 |
|------|----------|------------|
| Claude Code | `claude` | ✅ 是 |
| Codex | `codex` | ❌ 否 |
| Gemini CLI | `gemini` | ❌ 否 |
| OpenCode | `opencode` | ❌ 否 |
| OpenClaw | `openclaw` | ❌ 否 |

---

## 💡 使用示例

### 示例 1：列出 Claude Code 的所有 provider

**你：**
```
"列出所有 Claude Code 的 provider"
```

**Claude：**
```
======================================
        Providers List
======================================

### claude
ID                                      | Name                        | Status
--------------------------------------+------------------------------+--------
xxx-xxxx-xxxx-xxxx | MiniMax                  | [Active]
xxx-xxxx-xxxx-xxxx | Zhipu GLM                 |
xxx-xxxx-xxxx-xxxx | 腾讯 Coding                | |
```

### 示例 2：切换 provider

**你：**
```
"切换到 Zhipu GLM"
```

**Claude：**
```
Switching claude to Zhipu GLM...

✅ Successfully switched claude provider to: Zhipu GLM
Provider ID: xxx-xxxx-xxxx-xxxx

ℹ️  Claude Code supports hot-switching - changes take effect immediately!
```

### 示例 3：测试连通性

**你：**
```
"测试一下 MiniMax 的连通性"
```

**Claude：**
```
======================================
        Connectivity Test
======================================

Provider: MiniMax
App Type: claude
API Endpoint: https://api.minimax.com/v1

======================================
✅ Test Successful

| 指标        | 结果 |
|------------|------|
| HTTP 状态   | 200 OK |
| 响应时间    | 1.92s |
| 使用的模型    | claude-3-5-sonnet-20241022 |
```

### 示例 4：从预设添加 provider

**你：**
```
"用 Anthropic 预设添加一个 provider"
```

**Claude：**
```
可用预设：
- Anthropic Official (anthropic-official)
- MiniMax Official (minimax-official)
- Zhipu AI Official (zhipuai-official)
- DeepSeek Official (deepseek-official)

请提供：
1. 预设名称
2. 你的 API 密钥
3. 想给这个 provider起个名字

例如：Anthropic Official + 你的密钥 = "我的 Anthropic"
```

---

## 🛠️ 配置结构

### config.json

```json
{
  "active_providers": {
    "claude": "provider-uuid-or-null",
    "codex": "provider-uuid-or-null",
    "gemini": "provider-uuid-or-null",
    "opencode": "provider-uuid-or-null",
    "openclaw": "provider-uuid-or-null"
  }
}
```

### providers.json

```json
{
  "providers": [
    {
      "id": "unique-uuid",
      "name": "Provider Name",
      "app_type": "claude",
      "api_key": "your-api-key",
      "base_url": "https://api.example.com/v1",
      "models": {
        "haiku": "model-id",
        "sonnet": "model-id",
        "opus": "model-id"
      },
      "is_active": false,
      "created_at": "2026-04-15T08:00:00Z"
    }
  ]
}
```

---

## ❓ 常见问题

### 技能安装后如何使用？

直接用自然语言和 Claude 对话即可：

```
"列出 provider"
"切换到 MiniMax"
"添加一个新的 provider"
"测试 MiniMax 的连通性"
```

### 切换后需要重启吗？

- **Claude Code**：不需要，支持热切换
- **其他应用**（Codex、Gemini 等）：需要重启终端

### 连通性测试失败怎么办？

检查以下几点：
1. API 密钥是否正确
2. Base URL 是否可访问
3. 模型名称是否有效
4. 网络连接是否正常

### 如何添加自定义 provider？

```bash
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "我的 Provider" \
  --app claude \
  --key "your-api-key" \
  --url "https://api.example.com/v1" \
  --opus "my-model-name"
```

---

## 🗗 相关链接

- [GitHub 仓库](https://github.com/stcatz/cc-switch-skill) - 本技能仓库
- [Claude Code](https://claude.ai/code) - Claude Code 官方页面

---

<div align="center">

为 AI 开发社区 ❤️ 制作

[English Documentation](README.md)

</div>
