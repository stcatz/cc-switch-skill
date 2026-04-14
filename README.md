# cc-switch Skill

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-green.svg)](https://claude.ai/code)
[![中文文档](https://img.shields.io/badge/中文文档--blue.svg)](README_zh.md)

A Claude Code skill for managing AI provider configurations through the [cc-switch](https://github.com/farion1231/cc-switch) desktop application.

Seamlessly switch between providers for **Claude Code**, **Codex**, **Gemini CLI**, **OpenCode**, and **OpenClaw** without editing configuration files manually.

---

## 🚀 Quick Start

### Installation

```bash
# Copy the skill to your Claude Code skills folder
cp -r cc-switch ~/.claude/skills/

# Restart Claude Code
```

### Usage

After installation, simply talk to Claude using natural language:

```
# List all Claude Code providers
"List all Claude Code providers"

# Check current provider
"Which provider am I using now?"

# Switch provider
"Switch to MiniMax"
"Change Claude Code provider to something else"

# List providers for other apps
"List all Codex providers"
"Show OpenClaw current provider"
```

---

## 📖 Usage Guide

### List All Providers

Just ask naturally:

```
"Show me all Claude Code providers"
```

Claude will automatically query the cc-switch database and display results in a table:
```
| ID | Name | Status |
|-----|------|--------|
| xxx | MiniMax | [Active] |
| xxx | Zhipu GLM | |
| xxx | 腾讯 Coding | |
```

### Check Current Provider

```
"Which provider is currently active?"
"What provider am I using right now?"
```

Claude will return the name and details of the currently active provider.

### Switch Provider

```
"Switch to MiniMax"
"Change provider to Zhipu GLM"
"I want to switch to 腾讯 Coding"
```

After switching:
- **Claude Code**: Changes take effect immediately (hot-switching)
- **Codex/Gemini/OpenCode/OpenClaw**: Requires restarting your terminal or CLI tool

---

## 🔧 Supported Applications

| Application | Description | Hot-Switch |
|-------------|-------------|------------|
| Claude Code | Anthropic's official coding assistant | ✅ Yes |
| Codex | OpenAI's coding tool | ❌ No |
| Gemini CLI | Google's Gemini CLI | ❌ No |
| OpenCode | OpenAI-compatible coding tool | ❌ No |
| OpenClaw | OpenAI-compatible coding tool | ❌ No |

---

## 💡 Usage Examples

### Example 1: List Claude Code Providers

**You:**
```
"List all Claude Code providers"
```

**Claude:**
```
| ID | Name | Status |
|-----|------|--------|
| xxx | MiniMax | [Active] |
| xxx | Zhipu GLM | |
| xxx | fusecode | |
```

### Example 2: Switch Provider

**You:**
```
"Switch to Zhipu GLM"
```

**Claude:**
```
✅ Switched Claude Code provider to Zhipu GLM

Current active: Zhipu GLM
```

### Example 3: List Codex Providers

**You:**
```
"Show all Codex providers"
```

**Claude:**
```
| ID | Name | Status |
|-----|------|--------|
| xxx | default | [Active] |
| xxx | Rayincode | |
| xxx | My Codex | |
```

---

## ❓ FAQ

### How do I use the skill after installation?

Simply talk to Claude using natural language. The skill will automatically recognize related requests.

```
"List providers"
"Switch provider"
"Check current configuration"
```

### Do I need to restart after switching?

- **Claude Code**: No, hot-switching is supported
- **Other apps** (Codex, Gemini, etc.): Yes, restart your terminal

### What if switching fails?

Ensure the cc-switch desktop application has the provider you want to switch to configured:
1. Open the cc-switch desktop app
2. Check the "Providers" tab
3. Confirm the target provider is added

---

## 🔗 Related Links

- [cc-switch Repository](https://github.com/farion1231/cc-switch) - cc-switch desktop application
- [Claude Code](https://claude.ai/code) - Official Claude Code page
- [GitHub Repository](https://github.com/stcatz/cc-switch-skill) - This skill's repository

---

<div align="center">

Made with ❤️ for AI development community

[中文文档](README_zh.md)

</div>
