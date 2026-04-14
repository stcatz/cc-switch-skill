# cc-switch Skill

[![许可证: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-green.svg)](https://claude.ai/code)

一个用于通过 [cc-switch](https://github.com/farion1231/cc-switch) 桌面应用管理 AI provider 配置的 Claude Code 技能。

在 **Claude Code**、**Codex**、**Gemini CLI**、**OpenCode** 和 **OpenClaw** 之间无缝切换 provider，无需手动编辑配置文件。

---

## 🚀 快速开始

### 安装

```bash
# 复制技能到 Claude Code 技能文件夹
cp -r cc-switch ~/.claude/skills/

# 重启 Claude Code
```

### 使用

安装后，直接用自然语言和 Claude 对话即可：

```
# 列出所有 Claude Code 的 provider
"列出 Claude Code 的所有 provider"

# 查看当前使用的 provider
"当前使用的是哪个 provider？"

# 切换 provider
"切换到 MiniMax"
"把 Claude Code 切换到其他 provider"

# 查看指定应用的 provider
"列出 Codex 的所有 provider"
"查看 OpenClaw 当前 provider"
```

---

## 📖 详细使用指南

### 列出所有 provider

用自然语言请求即可，例如：

```
"显示所有 Claude Code 的 provider"
```

Claude 会自动查询 cc-switch 数据库并以表格形式展示：
```
| ID | Name | 状态 |
|-----|------|--------|
| xxx | MiniMax | [激活] |
| xxx | Zhipu GLM | |
| xxx | 腾讯 Coding | |
```

### 查看当前 provider

```
"哪个 provider 当前是激活的？"
"我现在用的 provider 是哪个？"
```

Claude 会返回当前激活的 provider 名称和详细信息。

### 切换 Provider

```
"切换到 MiniMax"
"把 provider 改成 Zhipu GLM"
"I want to switch to 腾讯 Coding"
```

切换后：
- **Claude Code**：立即生效，无需重启
- **Codex/Gemini/OpenCode/OpenClaw**：需要重启终端或 CLI 工具

---

## 🔧 支持的应用

| 应用 | 描述 | 热切换 |
|------|------|--------|
| Claude Code | Anthropic 的官方编码助手 | ✅ 是 |
| Codex | OpenAI 的编码工具 | ❌ 否 |
| Gemini CLI | Google 的 Gemini CLI | ❌ 否 |
| OpenCode | OpenAI 兼容的编码工具 | ❌ 否 |
| OpenClaw | OpenAI 兼容的编码工具 | ❌ 否 |

---

## 💡 使用示例

### 示例 1：查看 Claude Code provider

**你：**
```
"列出所有 Claude Code 的 provider"
```

**Claude：**
```
| ID | Name | 状态 |
|-----|------|--------|
| xxx | MiniMax | [激活] |
| xxx | Zhipu GLM | |
| xxx | fusecode | |
```

### 示例 2：切换 provider

**你：**
```
"切换到 Zhipu GLM"
```

**Claude：**
```
✅ 已切换 Claude Code provider 到 Zhipu GLM

当前激活：Zhipu GLM
```

### 示例 3：查看 Codex provider

**你：**
```
"显示 Codex 的所有 provider"
```

**Claude：**
```
| ID | Name | 状态 |
|-----|------|--------|
| xxx | default | [激活] |
| xxx | Rayincode | |
| xxx | My Codex | |
```

### 示例 4：测试 provider 连通性

**你：**
```
"测试一下 Zhipu GLM 的连通性"
```

**Claude：**
```
✅ Zhipu GLM 连通性测试成功

| 指标 | 结果 |
|------|------|
| HTTP 状态 | 200 OK |
| 响应时间 | 1.92s |
| 使用的模型 | glm-5.1 |

API 端点：https://api.z.ai/api/anthropic
```

---

## ❓ 常见问题

### 技能安装后如何使用？

安装技能后，直接用自然语言和 Claude 对话即可，技能会自动识别相关请求。

```
"列出 provider"
"切换 provider"
"查看当前配置"
```

### 切换后需要重启吗？

- **Claude Code**：不需要，支持热切换
- **其他应用**（Codex、Gemini 等）：需要重启终端

### 切换失败怎么办？

确保 cc-switch 桌面应用已正确配置了你要切换的 provider。你可以：
1. 打开 cc-switch 桌面应用
2. 检查 "Provider" 标签页
3. 确认目标 provider 已添加

---

## 🔗 相关链接

- [cc-switch 主仓库](https://github.com/farion1231/cc-switch) - cc-switch 桌面应用
- [Claude Code](https://claude.ai/code) - Claude Code 官方页面
- [GitHub 仓库](https://github.com/stcatz/cc-switch-skill) - 本技能仓库

---

<div align="center">

为 AI 开发社区 ❤️ 制作

[English Documentation](README.md)

</div>
