---
name: cc-switch
description: Dual-mode provider management skill for Claude Code and compatible CLI tools. Works with cc-switch desktop app OR standalone (no desktop app required). Automatically detects mode: uses SQLite when cc-switch is present, otherwise uses JSON config. Pre-flight connectivity testing runs before switching with user confirmation on failure. For Claude Code, switching is endpoint-only: it reads the target provider's base URL but does not change cc-switch provider state, and only updates ~/.claude/settings.json.
---

# CC Switch - Dual-Mode Provider Management

A provider management skill that works in **two modes** automatically:

| Mode | When Active | Data Storage |
|------|-------------|---------------|
| **cc-switch mode** | cc-switch desktop app is installed (`~/.cc-switch/cc-switch.db` exists) | SQLite database |
| **standalone mode** | cc-switch is NOT installed | JSON files (`~/.cc-switch-skill/`) |

The skill automatically detects which mode to use - no manual configuration needed.

## Supported Apps

| Application | app_type | Hot-Switch |
|-------------|----------|------------|
| Claude Code | `claude` | Endpoint-only |
| Codex | `codex` | ❌ No |
| Gemini CLI | `gemini` | ❌ No |
| OpenCode | `opencode` | ❌ No |
| OpenClaw | `openclaw` | ❌ No |

## Mode Detection

The skill checks for `~/.cc-switch/cc-switch.db`:
- **Found** → Uses SQLite mode (reads from cc-switch database)
- **Not found** → Uses standalone mode (reads from `~/.cc-switch-skill/`)

You can install/remove cc-switch anytime and the skill will automatically adapt.

## Storage Locations

### cc-switch Mode
- Database: `~/.cc-switch/cc-switch.db`
- Managed by: cc-switch desktop application

### Standalone Mode
- Config: `~/.cc-switch-skill/config.json` — Active providers per app
- Providers: `~/.cc-switch-skill/providers.json` — All configured providers
- Presets: `~/.claude/skills/cc-switch/presets.json` — Built-in presets

## Core Operations

### 1. Add Provider

```bash
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "MiniMax" \
  --app claude \
  --key "sk-xxxx" \
  --url "https://api.minimax.com/v1" \
  --sonnet "claude-3-5-sonnet-20241022"
```

### 2. List Providers

```bash
~/.claude/skills/cc-switch/scripts/list_providers.sh
~/.claude/skills/cc-switch/scripts/list_providers.sh --app claude
```

Output shows the current mode:
```
======================================
        Providers List
======================================

Mode: [cc-switch mode]

### claude
ID                                      | Name                        | Status
--------------------------------------+------------------------------+--------
a1b2c3d4-e5f6-7890-abcd-ef1234567890    | Anthropic Official         | 🟢 [Active]
```

### 3. Switch Provider (with Pre-flight Connectivity Check)

```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh \
  --app claude \
  --name "MiniMax"
```

**Important: Switching runs a connectivity test first:**
- ✅ **Test passes** → Switch proceeds automatically
- ❌ **Test fails** → Error details shown, user asked to confirm before proceeding

To skip the connectivity check (advanced use):
```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh \
  --app claude \
  --name "MiniMax" \
  --skip-test
```

### 4. Delete Provider

```bash
~/.claude/skills/cc-switch/scripts/delete_provider.sh --id provider-uuid
```

Cannot delete currently active provider - must switch first.

### 5. Test Provider Connectivity

```bash
~/.claude/skills/cc-switch/scripts/test_connectivity.sh --app claude --name "MiniMax"
```

## Presets

Built-in provider presets in `presets.json` work in standalone mode:

| Name | App | Description |
|------|------|-------------|
| Anthropic Official | claude, gemini | Official Anthropic API |
| MiniMax Official | claude | Official MiniMax API |
| Zhipu AI Official | claude | Official Zhipu AI endpoint |
| DeepSeek Official | claude | Official DeepSeek API |

Presets are used as templates - you provide your own API key when adding.

## Hot-Switching Support

Only **Claude Code** supports hot-switching — changes take effect immediately without restarting the terminal.

For all other apps, you must restart the terminal or CLI tool after switching providers.

## Workflow

### Typical Usage

1. **Add provider** — Use `add_provider.sh` with your credentials
2. **Test** — Use `test_connectivity.sh` to verify
3. **Switch** — Use `switch_provider.sh` (auto-tests first)
4. **List** — Use `list_providers.sh` to see all options

### Example Session

```
User: I want to switch to MiniMax
Claude: Running switch_provider.sh --app claude --name MiniMax

[Connectivity test runs...]
✅ Connectivity test passed

Switching claude to MiniMax...
✅ Successfully switched claude provider to: MiniMax
ℹ️ Claude Code supports hot-switching - changes take effect immediately!

User: Test the connection
Claude: test_connectivity.sh --app claude --name MiniMax
[Shows detailed test results]
```

### When Connectivity Fails

```
User: Switch to TestProvider
Claude: Running switch_provider.sh...

======================================
        Connectivity Test FAILED
======================================

Error Details:
HTTP Status: 401
API Endpoint: https://api.test.com/v1
Model: test-model

Response:
{"error": {"type": "authentication_error", "message": "Invalid API key"}}

======================================

⚠️ The connectivity test failed.
Possible causes:
  - Invalid API key
  - Incorrect base URL
  - Model name mismatch
  - Network connectivity issues

Do you want to switch to this provider anyway? (yes/no)
```

## CLI Tool Integration

The skill manages provider configurations but updates to CLI tool settings vary:

### Claude Code

`switch_provider.sh` treats Claude specially:
- It reads the selected provider's `base_url`
- It does **not** change cc-switch's active provider state or SQLite rows
- It only merges `~/.claude/settings.json` and updates `.env.ANTHROPIC_BASE_URL`
- It preserves the rest of `settings.json`

Resulting shape:
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.minimax.com/v1"
  }
}
```

### Other CLI Tools

Research the configuration file locations for:
- Codex
- Gemini CLI
- OpenCode
- OpenClaw

Update them with the active provider's API key and base URL manually.

## Quick Reference

| Action | Script | Connectivity Check |
|--------|--------|-------------------|
| Add provider | `add_provider.sh` | No |
| List all | `list_providers.sh` | No |
| List by app | `list_providers.sh --app <app>` | No |
| Switch provider | `switch_provider.sh` | **Yes** (pre-flight) |
| Switch (skip test) | `switch_provider.sh --skip-test` | No |
| Delete provider | `delete_provider.sh` | No |
| Test connectivity | `test_connectivity.sh` | Yes (explicit) |

## Common Patterns

### Adding a New Provider

1. List available presets:
   ```bash
   jq '.presets[] | select(.name)' ~/.claude/skills/cc-switch/presets.json
   ```

2. Add your credentials:
   ```bash
   ~/.claude/skills/cc-switch/scripts/add_provider.sh \
     --name "My Provider" \
     --app claude \
     --key "sk-xxxx" \
     --url "https://api.example.com/v1"
   ```

3. Test before switching:
   ```bash
   ~/.claude/skills/cc-switch/scripts/test_connectivity.sh --app claude --name "My Provider"
   ```

4. Switch (with automatic test):
   ```bash
   ~/.claude/skills/cc-switch/scripts/switch_provider.sh --app claude --name "My Provider"
   ```

### Managing Multiple Apps

List all providers across all apps:
```bash
~/.claude/skills/cc-switch/scripts/list_providers.sh
```

Switch different providers for different apps:
```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh --app claude --name MiniMax
~/.claude/skills/cc-switch/scripts/switch_provider.sh --app codex --name AnotherProvider
```

## Troubleshooting

### Script Not Found

Ensure the skill is installed in `~/.claude/skills/cc-switch/` and scripts are executable:
```bash
chmod +x ~/.claude/skills/cc-switch/scripts/*.sh
```

### Provider Not Found

Double-check the provider name when using `--name` flag:
```bash
~/.claude/skills/cc-switch/scripts/list_providers.sh
```

### Mode Detection Issues

If you see unexpected mode:
```bash
# Check if cc-switch database exists
ls -la ~/.cc-switch/cc-switch.db

# Or check standalone directory
ls -la ~/.cc-switch-skill/
```

### Connectivity Test Always Fails

Check:
1. API key is correct and active
2. Base URL is accessible from your network
3. Model name is valid for the provider
4. Network/firewall allows the connection

### Test Fails But Provider Works

If you want to switch despite test failure, use `--skip-test` flag:
```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh --app claude --name Provider --skip-test
```

## Architecture Notes

### common.sh

All scripts source `scripts/common.sh` which provides:
- Mode detection (`detect_mode()`)
- Unified functions (`list_providers()`, `get_provider_by_name()`, etc.)
- SQLite-specific functions (`sqlite_*`)
- Standalone-specific functions (`standalone_*`)
- Utility functions (`generate_uuid()`, `get_provider_credentials()`)

### Mode Auto-Switching

You can install or uninstall cc-switch at any time:
- **Install cc-switch** → Skill automatically switches to SQLite mode on next operation
- **Uninstall cc-switch** → Skill automatically falls back to standalone mode

No migration needed - the skill adapts to whatever is available.
