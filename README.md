# cc-switch Skill

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-green.svg)](https://claude.ai/code)
[![中文文档](https://img.shields.io/badge/中文文档--blue.svg)](README_zh.md)

A Claude Code skill for managing AI provider configurations through the [cc-switch](https://github.com/farion1231/cc-switch) desktop application database.

Seamlessly switch between providers for **Claude Code**, **Codex**, **Gemini CLI**, **OpenCode**, and **OpenClaw** without editing configuration files manually.

---

## 🚀 Features

- **Multi-App Support** — Manage providers for 5 CLI tools from a single skill
- **Instant Switching** — Toggle between providers with simple database queries
- **Hot-Switch Support** — Claude Code provider changes take effect immediately (no restart required)
- **Provider Discovery** — List all configured providers with their status
- **Database Queries** — Direct SQLite access for advanced configuration management

---

## 📦 Installation

### Prerequisites

- [cc-switch](https://github.com/farion1231/cc-switch) desktop application installed
- `sqlite3` command-line tool
- `jq` (optional, for JSON parsing)

### Setup

1. Clone or copy this skill directory to your Claude Code skills folder:
   ```bash
   cp -r cc-switch ~/.claude/skills/
   ```

2. Restart Claude Code to load the skill.

---

## 📖 Usage

### Basic Commands

#### List All Providers for an App

```bash
# Claude Code
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'claude'"

# Codex
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'codex'"

# OpenClaw
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'openclaw'"
```

**Output:**
```
id                                    | name          | is_current
--------------------------------------+---------------+------------
a1b2c3d4-e5f6-7890-abcd-ef1234567890 | Example Provider| 1
f1e2d3c4-b5a6-7890-efab-cd1234567890 | Another Provider| 0
```

#### Check Current Active Provider

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE app_type = 'claude' AND is_current = 1"
```

#### Switch Provider

```bash
# Step 1: Disable all providers for the app
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = 'claude'"

# Step 2: Enable the desired provider
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = 'PROVIDER_ID' AND app_type = 'claude'"
```

---

## 🎯 Examples

### Example 1: List Claude Code Providers

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT id, name,
  CASE WHEN is_current = 1 THEN '[ACTIVE]' ELSE '' END as status
FROM providers
WHERE app_type = 'claude'
"
```

**Output:**
```
id                                    | name            | status
--------------------------------------+-----------------+--------
a1b2c3d4-e5f6-7890-abcd-ef1234567890 | Provider A       | [ACTIVE]
b2c3d4e5-f6a7-8901-bcde-fa2345678901  | Provider B       |
c3d4e5f6-a7b8-9012-cdef-ab3456789012  | Provider C       |
```

### Example 2: Switch Codex Provider

```bash
# List available Codex providers
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE app_type = 'codex'"

# Switch to 'Alternative Provider'
PROVIDER_ID="alternative-codex-1234567890"
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = 'codex'"
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = '$PROVIDER_ID' AND app_type = 'codex'"

# Verify the switch
sqlite3 ~/.cc-switch/cc-switch.db "SELECT name FROM providers WHERE app_type = 'codex' AND is_current = 1"
```

### Example 3: View Provider Details

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT
  id,
  name,
  settings_config,
  website_url,
  category
FROM providers
WHERE id = 'PROVIDER_ID'
" | jq .
```

### Example 4: Count Providers per App

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT
  app_type,
  COUNT(*) as total,
  SUM(is_current) as active
FROM providers
GROUP BY app_type
"
```

**Output:**
```
app_type  | total | active
-----------+-------+--------
claude     | 4     | 1
codex      | 3     | 1
gemini     | 3     | 1
opencode    | 1     | 0
openclaw   | 1     | 0
```

---

## ⚙️ Configuration

### Database Schema

The `providers` table structure:

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Unique provider identifier |
| app_type | TEXT | CLI tool (`claude`, `codex`, `gemini`, `opencode`, `openclaw`) |
| name | TEXT | Display name of the provider |
| settings_config | TEXT (JSON) | Provider configuration (API keys, endpoints) |
| website_url | TEXT | Provider's website URL |
| category | TEXT | Provider category |
| is_current | BOOLEAN | Whether this provider is currently active (1 = yes, 0 = no) |
| sort_index | INTEGER | Display order |

### File Locations

| File | Location |
|-------|----------|
| Database | `~/.cc-switch/cc-switch.db` |
| Settings | `~/.cc-switch/settings.json` |
| Backups | `~/.cc-switch/backups/` |

---

## 🔧 Advanced Usage

### Search Providers by Name

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT * FROM providers WHERE name LIKE '%keyword%'"
```

### Export Provider List

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT
  app_type,
  name,
  CASE WHEN is_current = 1 THEN 'active' ELSE 'inactive' END as status,
  website_url
FROM providers
ORDER BY app_type, is_current DESC
" -header -csv > providers_export.csv
```

### Batch Switch Multiple Apps

```bash
#!/bin/bash
# Switch all apps to specified provider ID

TARGET_PROVIDER="your-provider-id"
APPS=("claude" "codex" "gemini")

for app in "${APPS[@]}"; do
  sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = '$app'"
  sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = '$TARGET_PROVIDER' AND app_type = '$app'"
  echo "Switched $app to $TARGET_PROVIDER"
done
```

---

## ❓ Troubleshooting

### Provider switch not taking effect

**Problem:** After switching, the CLI tool still uses the old provider.

**Solution:**
- For **Claude Code**: Changes should take effect immediately (hot-switching)
- For **Codex/Gemini/OpenCode/OpenClaw**: Restart your terminal or CLI tool

### Database locked error

**Problem:** `database is locked` error when running queries.

**Solution:** Close the cc-switch desktop application before running manual queries, or use:
```bash
sqlite3 ~/.cc-switch/cc-switch.db "PRAGMA busy_timeout=5000; <your_query>"
```

### Provider ID not found

**Problem:** `UPDATE` query affects 0 rows.

**Solution:** Verify the provider ID exists:
```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE id = 'PROVIDER_ID'"
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

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🔗 Related Links

- [cc-switch Repository](https://github.com/farion1231/cc-switch) - The main desktop application
- [cc-switch Documentation](https://github.com/farion1231/cc-switch#documentation) - Full user manual
- [Claude Code](https://claude.ai/code) - Official Claude Code CLI tool

---

## 💡 Tips

1. **Backup before bulk changes** — The cc-switch app creates automatic backups in `~/.cc-switch/backups/`
2. **Use unique provider IDs** — Avoid conflicts when adding new providers manually
3. **Test after switching** — Always verify with a simple API call after switching providers
4. **Document custom providers** — Add notes to the `notes` column for custom providers

---

<div align="center">

Made with ❤️ for the AI development community

[中文文档](README_zh.md)

</div>
