# cc-switch Skill (Standalone)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-green.svg)](https://claude.ai/code)

A standalone provider management skill for Claude Code and compatible CLI tools. **No desktop application required** — everything is managed through JSON configuration files and shell scripts.

Seamlessly switch between providers for **Claude Code**, **Codex**, **Gemini CLI**, **OpenCode**, and **OpenClaw**.

---

## 🚀 Quick Start

### Installation

#### Option 1: One-line Installation (Recommended)

```bash
# Download and install the latest version
curl -sSL https://raw.githubusercontent.com/stcatz/cc-switch-skill/main/install.sh | bash
```

#### Option 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/stcatz/cc-switch-skill.git ~/.claude/skills/cc-switch

# Or download and copy manually
cp -r cc-switch ~/.claude/skills/

# Restart Claude Code
```

### First Time Setup

```bash
# Initialize config directory and presets (auto-runs)
~/.claude/skills/cc-switch/scripts/list_providers.sh

# View available presets
jq '.presets[] | {name}' ~/.claude/skills/cc-switch/presets.json
```

---

## 📖 Usage Guide

### Add Provider

```bash
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "MiniMax" \
  --app claude \
  --key "sk-xxxx" \
  --url "https://api.minimax.com/v1" \
  --sonnet "claude-3-5-sonnet-20241022"
```

### List Providers

```bash
# List all providers for all apps
~/.claude/skills/cc-switch/scripts/list_providers.sh

# List providers for Claude Code only
~/.claude/skills/cc-switch/scripts/list_providers.sh --app claude

# List providers for Codex only
~/.claude/skills/cc-switch/scripts/list_providers.sh --app codex
```

**Output:**
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

### Switch Provider

```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh \
  --app claude \
  --name "MiniMax"
```

**After switching:**
- **Claude Code**: Changes take effect immediately (hot-switching)
- **Other apps**: Requires restarting your terminal or CLI tool

### Delete Provider

```bash
~/.claude/skills/cc-switch/scripts/delete_provider.sh \
  --id provider-uuid
```

### Test Provider Connectivity

```bash
~/.claude/skills/cc-switch/scripts/test_connectivity.sh \
  --app claude \
  --name "MiniMax"
```

**Output:**
```
======================================
        Connectivity Test
======================================

Provider: MiniMax
App Type: claude
API Endpoint: https://api.minimax.com/v1

======================================
✅ Test Successful

| Metric        | Result |
|---------------|--------|
| HTTP Status   | 200 OK |
| Response Time | 1.92s |
| Model Used   | claude-3-5-sonnet-20241022 |
```

---

## 🔧 Built-in Presets

Available presets in `presets.json`:

| Name | App | Description |
|------|-----|-------------|
| Anthropic Official | claude, gemini | Official Anthropic API |
| MiniMax Official | claude | Official MiniMax API |
| Zhipu AI Official | claude | Official Zhipu AI endpoint |
| DeepSeek Official | claude | Official DeepSeek API |

### Add from Preset

```bash
# 1. View preset IDs
jq '.presets[] | select(.name) | .id' ~/.claude/skills/cc-switch/presets.json

# 2. Add using preset with your API key
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "My MiniMax" \
  --app claude \
  --key "your-api-key-here" \
  --url "https://api.minimax.com/v1"
```

---

## 📊 Supported Applications

| Application | app_type | Hot-Switch |
|-------------|----------|------------|
| Claude Code | `claude` | ✅ Yes |
| Codex | `codex` | ❌ No |
| Gemini CLI | `gemini` | ❌ No |
| OpenCode | `opencode` | ❌ No |
| OpenClaw | `openclaw` | ❌ No |

---

## 💡 Usage Examples

### Example 1: List All Claude Code Providers

**You:**
```
"List all Claude Code providers"
```

**Claude:**
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

### Example 2: Switch Provider

**You:**
```
"Switch to Zhipu GLM"
```

**Claude:**
```
Switching claude to Zhipu GLM...

✅ Successfully switched claude provider to: Zhipu GLM
Provider ID: xxx-xxxx-xxxx-xxxx

ℹ️ Claude Code supports hot-switching - changes take effect immediately!
```

### Example 3: Test Provider Connectivity

**You:**
```
"Test connectivity of MiniMax"
```

**Claude:**
```
======================================
        Connectivity Test
======================================

Provider: MiniMax
App Type: claude
API Endpoint: https://api.minimax.com/v1

======================================
✅ Test Successful

| Metric        | Result |
|---------------|--------|
| HTTP Status   | 200 OK |
| Response Time | 1.92s |
| Model Used   | claude-3-5-sonnet-20241022 |
```

### Example 4: Add Provider from Preset

**You:**
```
"Add Anthropic Official as a preset"
```

**Claude:**
```
Available presets:
- Anthropic Official (anthropic-official)
- MiniMax Official (minimax-official)
- Zhipu AI Official (zhipuai-official)
- DeepSeek Official (deepseek-official)

Please provide:
1. Your API key
2. A name for this provider

Example: Anthropic Official + your key → "My Anthropic"
```

---

## 🛠️ Configuration Structure

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

## ❓ FAQ

### How do I use the skill after installation?

Simply talk to Claude using natural language. The skill will recognize relevant requests and execute the appropriate shell scripts:

```
"List providers"
"Switch provider to MiniMax"
"Add a new provider"
"Test connectivity of MiniMax"
```

### Do I need to restart after switching?

- **Claude Code**: No, hot-switching is supported
- **Other apps** (Codex, Gemini, etc.): Yes, restart your terminal

### What if connectivity test fails?

Check:
1. Your API key is correct
2. Base URL is accessible
3. Model name is valid for the provider
4. Network connectivity is working

### How do I add a custom provider?

```bash
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "My Provider" \
  --app claude \
  --key "your-api-key" \
  --url "https://api.example.com/v1" \
  --opus "my-model-name"
```

---

## 🔗 Related Links

- [GitHub Repository](https://github.com/stcatz/cc-switch-skill) - This skill repository
- [Claude Code](https://claude.ai/code) - Official Claude Code page

---

<div align="center">

Made with ❤️ for AI development community

[中文文档](README_zh.md)

</div>
