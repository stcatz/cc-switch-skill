# cc-switch Skill

[![许可证: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-green.svg)](https://claude.ai/code)
[![中文文档](https://img.shields.io/badge/中文文档--blue.svg)](README_zh.md)

一个用于通过 [cc-switch](https://github.com/farion1231/cc-switch) 桌面应用数据库管理 AI provider 配置的 Claude Code 技能。

在 **Claude Code**、**Codex**、**Gemini CLI**、**OpenCode** 和 **OpenClaw** 之间无缝切换 provider，无需手动编辑配置文件。

---

## 🚀 功能特性

- **多应用支持** — 从单个技能管理 5 个 CLI 工具的 provider
- **即时切换** — 使用简单的数据库查询在 provider 之间切换
- **热切换支持** — Claude Code provider 更改立即生效（无需重启）
- **Provider 发现** — 列出所有配置的 provider 及其状态
- **数据库查询** — 直接 SQLite 访问进行高级配置管理

---

## 📦 安装

### 前置条件

- 已安装 [cc-switch](https://github.com/farion1231/cc-switch) 桌面应用
- `sqlite3` 命令行工具
- `jq`（可选，用于 JSON 解析）

### 安装步骤

1. 将此技能目录复制或移动到 Claude Code 技能文件夹：
   ```bash
   cp -r cc-switch ~/.claude/skills/
   ```

2. 重启 Claude Code 以加载技能。

---

## 📖 使用指南

### 基础命令

#### 列出指定应用的所有 provider

```bash
# Claude Code
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'claude'"

# Codex
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'codex'"

# OpenClaw
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name, is_current FROM providers WHERE app_type = 'openclaw'"
```

**输出示例：**
```
id                                    | name          | is_current
--------------------------------------+---------------+------------
a1b2c3d4-e5f6-7890-abcd-ef1234567890 | 示例 Provider   | 1
f1e2d3c4-b5a6-7890-efab-cd1234567890 | 另一个 Provider| 0
```

#### 查看当前激活的 provider

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE app_type = 'claude' AND is_current = 1"
```

#### 切换 provider

```bash
# 步骤 1：禁用该应用的所有 provider
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = 'claude'"

# 步骤 2：启用目标 provider（替换 PROVIDER_ID）
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = 'PROVIDER_ID' AND app_type = 'claude'"
```

---

## 🎯 使用示例

### 示例 1：列出 Claude Code 的所有 provider

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT id, name,
  CASE WHEN is_current = 1 THEN '[激活]' ELSE '' END as status
FROM providers
WHERE app_type = 'claude'
"
```

**输出：**
```
id                                    | name            | status
--------------------------------------+-----------------+--------
a1b2c3d4-e5f6-7890-abcd-ef1234567890 | Provider A       | [激活]
b2c3d4e5-f6a7-8901-bcde-fa2345678901  | Provider B       |
c3d4e5f6-a7b8-9012-cdef-ab3456789012  | Provider C       |
```

### 示例 2：切换 Codex provider

```bash
# 列出可用的 Codex provider
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE app_type = 'codex'"

# 切换到 "备用 Provider"
PROVIDER_ID="alternative-codex-1234567890"
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = 'codex'"
sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = '$PROVIDER_ID' AND app_type = 'codex'"

# 验证切换
sqlite3 ~/.cc-switch/cc-switch.db "SELECT name FROM providers WHERE app_type = 'codex' AND is_current = 1"
```

### 示例 3：查看 provider 详细信息

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

### 示例 4：统计各应用的 provider 数量

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT
  app_type,
  COUNT(*) as 总数,
  SUM(is_current) as 激活
FROM providers
GROUP BY app_type
"
```

**输出：**
```
app_type  | 总数 | 激活
-----------+-------+--------
claude     | 4     | 1
codex      | 3     | 1
gemini     | 3     | 1
opencode    | 1     | 0
openclaw   | 1     | 0
```

---

## ⚙️ 配置说明

### 数据库结构

`providers` 表结构：

| 列名 | 类型 | 说明 |
|------|------|------|
| id | TEXT | provider 唯一标识符 |
| app_type | TEXT | CLI 工具（`claude`、`codex`、`gemini`、`opencode`、`openclaw`） |
| name | TEXT | provider 显示名称 |
| settings_config | TEXT (JSON) | provider 配置（API 密钥、端点） |
| website_url | TEXT | provider 网站 URL |
| category | TEXT | provider 类别 |
| is_current | BOOLEAN | 此 provider 是否当前激活（1 = 是，0 = 否） |
| sort_index | INTEGER | 显示顺序 |

### 文件位置

| 文件 | 位置 |
|-------|----------|
| 数据库 | `~/.cc-switch/cc-switch.db` |
| 设置 | `~/.cc-switch/settings.json` |
| 备份 | `~/.cc-switch/backups/` |

---

## 🔧 高级用法

### 按名称搜索 provider

```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT * FROM providers WHERE name LIKE '%关键词%'"
```

### 导出 provider 列表

```bash
sqlite3 ~/.cc-switch/cc-switch.db "
SELECT
  app_type,
  name,
  CASE WHEN is_current = 1 THEN '激活' ELSE '未激活' END as status,
  website_url
FROM providers
ORDER BY app_type, is_current DESC
" -header -csv > providers_export.csv
```

### 批量切换多个应用

```bash
#!/bin/bash
# 将所有应用切换到指定 provider ID

TARGET_PROVIDER="your-provider-id"
APPS=("claude" "codex" "gemini")

for app in "${APPS[@]}"; do
  sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 0 WHERE app_type = '$app'"
  sqlite3 ~/.cc-switch/cc-switch.db "UPDATE providers SET is_current = 1 WHERE id = '$TARGET_PROVIDER' AND app_type = '$app'"
  echo "已切换 $app 到 $TARGET_PROVIDER"
done
```

---

## ❓ 故障排除

### Provider 切换未生效

**问题：** 切换后，CLI 工具仍使用旧 provider。

**解决方案：**
- 对于 **Claude Code**：更改应立即生效（热切换）
- 对于 **Codex/Gemini/OpenCode/OpenClaw**：需要重启终端或 CLI 工具

### 数据库锁定错误

**问题：** 运行查询时出现 `database is locked` 错误。

**解决方案：** 运行手动查询前关闭 cc-switch 桌面应用，或使用：
```bash
sqlite3 ~/.cc-switch/cc-switch.db "PRAGMA busy_timeout=5000; <你的查询>"
```

### Provider ID 未找到

**问题：** `UPDATE` 查询影响 0 行。

**解决方案：** 验证 provider ID 是否存在：
```bash
sqlite3 ~/.cc-switch/cc-switch.db "SELECT id, name FROM providers WHERE id = 'PROVIDER_ID'"
```

---

## 📊 支持的应用

| 应用 | app_type | 热切换 |
|-------------|----------|------------|
| Claude Code | `claude` | ✅ 是 |
| Codex | `codex` | ❌ 否 |
| Gemini CLI | `gemini` | ❌ 否 |
| OpenCode | `opencode` | ❌ 否 |
| OpenClaw | `openclaw` | ❌ 否 |

---

## 🤝 贡献

欢迎贡献！请随时提交问题或拉取请求。

---

## 📄 许可证

MIT 许可证 — 详见 [LICENSE](LICENSE)。

---

## 🔗 相关链接

- [cc-switch 代码仓库](https://github.com/farion1231/cc-switch) — 主桌面应用
- [cc-switch 文档](https://github.com/farion1231/cc-switch#documentation) — 完整用户手册
- [Claude Code](https://claude.ai/code) — 官方 Claude Code CLI 工具

---

## 💡 小贴士

1. **批量更改前备份** — cc-switch 应用会在 `~/.cc-switch/backups/` 中自动创建备份
2. **使用唯— provider ID** — 手动添加新 provider 时避免冲突
3. **切换后测试** — 切换 provider 后始终用简单的 API 调用验证
4. **记录自定义 provider** — 在 `notes` 列中为自定义 provider 添加注释

---

<div align="center">

为 AI 开发社区用 ❤️ 制作

[English Documentation](README.md)

</div>
