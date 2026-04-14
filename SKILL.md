---
name: cc-switch
description: Manages AI provider switching for Claude Code, Codex, Gemini CLI, OpenCode, and OpenClaw through the cc-switch desktop app configuration database. Use this skill whenever the user wants to switch providers, change API configurations, check current provider status, or manage cc-switch provider settings. Trigger when users mention "switch provider", "change provider", "set provider", "cc-switch", or when they want to use a different API endpoint for Claude Code or other supported CLI tools.
---

# CC Switch - Provider Management

CC Switch is a cross-platform desktop application that manages provider configurations for AI CLI tools. This skill helps you interact with your cc-switch configuration database to switch providers, list available options, and check current status.

## Supported Apps

- **Claude Code** (`claude`)
- **Codex** (`codex`)
- **Gemini CLI** (`gemini`)
- **OpenCode** (`opencode`)
- **OpenClaw** (`openclaw`)

## Database Location

The cc-switch database is stored at:
- **Database**: `~/.cc-switch/cc-switch.db` (SQLite)
- **Settings**: `~/.cc-switch/settings.json` (JSON)

## Key Operations

### 1. List Available Providers

Show all configured providers for a specific app:

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'claude'"
```

Replace `'claude'` with `'codex'`, `'gemini'`, `'opencode'`, or `'openclaw'` as needed.

The `is_current` column shows which provider is currently active (1 = active, 0 = inactive).

### 2. Check Current Provider

Query the current active provider for an app:

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE app_type = 'claude' AND is_current = 1"
```

Alternatively, check the settings.json file:

```bash
cat ~/.cc-switch/settings.json | jq '.currentProviderClaude'
```

### 3. Switch Provider

To switch to a different provider, you need to update the database:

```bash
# First, disable all providers for the app
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = 'claude'"

# Then enable the desired provider (replace PROVIDER_ID with actual ID)
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = 'PROVIDER_ID' AND app_type = 'claude'"
```

After switching, you may need to restart the CLI tool for changes to take effect (Claude Code supports hot-switching without restart).

### 4. Add a New Provider

Adding a provider requires inserting into the database. The most reliable way is to use the cc-switch GUI, but if needed:

```bash
sqlite3 ~/.cc-switch/cc-switch.db "INSERT INTO providers (id, app_type, name, settings_config, meta, is_current)
VALUES ('unique-id', 'claude', 'Provider Name', '{\"api_key\":\"...\",\"base_url\":\"...\"}', '{}', 0)"
```

The `settings_config` field contains JSON with the provider-specific configuration.

### 5. View Provider Details

Get full configuration for a provider:

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT * FROM providers WHERE id = 'PROVIDER_ID'"
```

## Common Workflows

### Switching Between Claude Code Providers

When the user wants to switch Claude Code providers:

1. List available providers for Claude
2. Identify the target provider ID
3. Update `is_current` flag
4. Inform the user whether restart is needed

### Checking Current Configuration

When the user asks about current provider:

1. Query for the active provider for the specified app
2. Display the provider name and key configuration details
3. Show the API endpoint if available

### Listing All Available Providers

When the user wants to see all options:

1. Query all providers for the specified app
2. Display in a readable format (ID, Name, Status)
3. Mark which one is currently active

## Important Notes

- **Claude Code hot-switching**: Only Claude Code supports hot-switching without terminal restart
- **Database integrity**: cc-switch uses SQLite with atomic writes; be careful with direct database modifications
- **Provider IDs**: These are unique identifiers (UUIDs or custom strings) used to reference specific providers
- **App types**: Always verify you're operating on the correct `app_type` for the CLI tool the user is asking about

## Example Query Patterns

```bash
# Get all providers for Claude Code with their current status
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, CASE WHEN is_current = 1 THEN '[ACTIVE]' ELSE '' END as status FROM providers WHERE app_type = 'claude'"

# Get provider count per app
sqlite3 ~/.cc-switch/cc-switch.db "SELECT app_type, COUNT(*) as count FROM providers GROUP BY app_type"

# Search for a provider by name (partial match)
sqlite3 ~/.cc-switch/cc-switch.db "SELECT * FROM providers WHERE name LIKE '%ProviderName%'"
```

## Related Tools

- `jq` - For parsing JSON from settings_config fields
- `sqlite3` - For direct database queries
- `cat` - For reading settings.json

When the user mentions cc-switch, provider switching, or changing API configurations for Claude Code and related tools, use this skill to help them manage their provider settings through the cc-switch database.
