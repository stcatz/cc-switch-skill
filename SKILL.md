---
name: cc-switch
description: Standalone provider management skill for Claude Code and compatible CLI tools. No desktop app required. Add, list, switch, delete, and test providers for Claude Code, Codex, Gemini CLI, OpenCode, and OpenClaw. Use this skill whenever user wants to switch providers, add new API configurations, check current provider status, or manage provider settings. Trigger when users mention "switch provider", "change provider", "set provider", "add provider", "list providers", or wants to use a different API endpoint for Claude Code or other supported CLI tools.
---

# CC Switch - Standalone Provider Management

A standalone skill for managing AI provider configurations for Claude Code and compatible CLI tools. **No desktop application required** - everything is managed through JSON configuration files and shell scripts.

## Supported Apps

- **Claude Code** (`claude`) — Hot-switching supported (no restart needed)
- **Codex** (`codex`) — Requires restart after switching
- **Gemini CLI** (`gemini`) — Requires restart after switching
- **OpenCode** (`opencode`) — Requires restart after switching
- **OpenClaw** (`openclaw`) — Requires restart after switching

## Configuration Location

All configuration is stored in `~/.cc-switch-skill/`:
- `config.json` — Active providers per app
- `providers.json` — All configured providers
- `presets.json` — Built-in provider presets

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

### 3. Switch Provider

```bash
~/.claude/skills/cc-switch/scripts/switch_provider.sh \
  --app claude \
  --name "MiniMax"
```

### 4. Delete Provider

```bash
~/.claude/skills/cc-switch/scripts/delete_provider.sh \
  --id provider-uuid
```

### 5. Test Provider Connectivity

```bash
~/.claude/skills/cc-switch/scripts/test_connectivity.sh \
  --app claude \
  --name "MiniMax"
```

## Provider Format

Each provider requires:
- `id` — Unique identifier (auto-generated if not specified)
- `name` — Display name
- `app_type` — Which CLI tool (claude, codex, gemini, opencode, openclaw)
- `api_key` — API key or token
- `base_url` — API endpoint URL
- `models` — Model mappings (haiku, sonnet, opus)

## Presets

Built-in provider presets available in `presets.json`:
- Anthropic Official (all apps)
- MiniMax Official
- Zhipu AI Official
- DeepSeek Official

Import a preset:
```bash
# Read preset ID
jq '.presets[] | select(.name) | .id' ~/.claude/skills/cc-switch/presets.json

# Copy preset and add with your own API key
~/.claude/skills/cc-switch/scripts/add_provider.sh \
  --name "My MiniMax" \
  --app claude \
  --key "your-key" \
  --url "https://api.minimax.com/v1"
```

## Hot-Switching Support

Only **Claude Code** supports hot-switching — changes take effect immediately without restarting the terminal. For all other apps, you must restart the terminal or CLI tool after switching providers.

## Workflow

### Typical Usage

1. **Add provider** — Use `add_provider.sh` with your credentials
2. **Switch** — Use `switch_provider.sh` to activate
3. **Test** — Use `test_connectivity.sh` to verify
4. **List** — Use `list_providers.sh` to see all options

### Example Session

```
User: I want to switch to MiniMax
Claude: ~\.claude/skills/cc-switch/scripts/switch_provider.sh --app claude --name MiniMax

User: Test the connection
Claude: ~\.claude/skills/cc-switch/scripts/test_connectivity.sh --app claude --name MiniMax

User: Show me all Claude Code providers
Claude: ~\.claude/skills/cc-switch/scripts/list_providers.sh --app claude
```

## CLI Tool Integration

The skill manages provider configurations but does NOT directly modify CLI tool settings files. You'll need to:

### Claude Code

Update `~/.claude/settings.json`:
```bash
cat > ~/.claude/settings.json << EOF
{
  "ANTHROPIC_AUTH_TOKEN": "your-api-key",
  "ANTHROPIC_BASE_URL": "https://api.minimax.com/v1",
  "ANTHROPIC_MODEL": "claude-3-5-sonnet-20241022"
}
EOF
```

### Other CLI Tools

Research the configuration file locations for:
- Codex
- Gemini CLI
- OpenCode
- OpenClaw

Update them with the active provider's API key and base URL.

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

3. Switch to it:
   ```bash
   ~/.claude/skills/cc-switch/scripts/switch_provider.sh --app claude --name "My Provider"
   ```

### Testing Before Switching

Always test a provider before switching:
```bash
~/.claude/skills/cc-switch/scripts/test_connectivity.sh --app claude --name "Test Provider"
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

### Configuration File Corrupted

If JSON files are corrupted, restore from automatic backups (if enabled) or recreate:
```bash
# Create new empty config
cat > ~/.cc-switch-skill/config.json << 'EOF'
{
  "active_providers": {
    "claude": null,
    "codex": null,
    "gemini": null,
    "opencode": null,
    "openclaw": null
  }
}
EOF

cat > ~/.cc-switch-skill/providers.json << 'EOF'
{
  "providers": []
}
EOF
```

### Test Fails

If connectivity test fails, check:
1. API key is correct
2. Base URL is accessible
3. Model name is valid for the provider
4. Network connectivity

## Quick Reference

| Action | Script |
|--------|--------|
| Add provider | `add_provider.sh` |
| List all | `list_providers.sh` |
| List by app | `list_providers.sh --app <app>` |
| Switch provider | `switch_provider.sh` |
| Switch by ID | `switch_provider.sh --id <id>` |
| Delete provider | `delete_provider.sh` |
| Test connectivity | `test_connectivity.sh` |
| List presets | `jq '.presets[] | {name, id}' ~/.claude/skills/cc-switch/presets.json` |
