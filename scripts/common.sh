#!/bin/bash
# Common functions for cc-switch skill
# Supports both cc-switch SQLite mode and standalone JSON mode

# Configuration paths
CC_SWITCH_DIR="$HOME/.cc-switch"
CC_SWITCH_DB="$CC_SWITCH_DIR/cc-switch.db"
STANDALONE_DIR="$HOME/.cc-switch-skill"
STANDALONE_PROVIDERS="$STANDALONE_DIR/providers.json"
STANDALONE_CONFIG="$STANDALONE_DIR/config.json"

# Detect which mode to use
# Returns "sqlite" or "standalone"
detect_mode() {
    if [ -f "$CC_SWITCH_DB" ]; then
        echo "sqlite"
    else
        echo "standalone"
    fi
}

MODE=$(detect_mode)

# SQLite mode functions
sqlite_list_providers() {
    local app_type="$1"

    if [ -z "$app_type" ]; then
        sqlite3 "$CC_SWITCH_DB" "SELECT id, name, app_type, is_current FROM providers ORDER BY app_type, name;"
    else
        sqlite3 "$CC_SWITCH_DB" "SELECT id, name, app_type, is_current FROM providers WHERE app_type='$app_type' ORDER BY name;"
    fi
}

sqlite_get_provider_by_name() {
    local name="$1"
    local app_type="$2"

    sqlite3 "$CC_SWITCH_DB" "SELECT id FROM providers WHERE name='$name' AND app_type='$app_type';"
}

sqlite_get_provider_by_id() {
    local id="$1"
    sqlite3 "$CC_SWITCH_DB" "SELECT name, app_type, api_key, base_url FROM providers WHERE id='$id';"
}

sqlite_get_current_provider() {
    local app_type="$1"
    sqlite3 "$CC_SWITCH_DB" "SELECT id FROM providers WHERE app_type='$app_type' AND is_current=1;"
}

sqlite_switch_provider() {
    local provider_id="$1"
    local app_type="$2"

    # First, deactivate all providers for this app
    sqlite3 "$CC_SWITCH_DB" "UPDATE providers SET is_current=0 WHERE app_type='$app_type';"

    # Then activate the target provider
    sqlite3 "$CC_SWITCH_DB" "UPDATE providers SET is_current=1 WHERE id='$provider_id';"
}

sqlite_add_provider() {
    local name="$1"
    local app_type="$2"
    local api_key="$3"
    local base_url="$4"
    local haiku_model="$5"
    local sonnet_model="$6"
    local opus_model="$7"
    local id="$8"

    if [ -z "$id" ]; then
        id=$(generate_uuid)
    fi

    sqlite3 "$CC_SWITCH_DB" << EOF
INSERT INTO providers (id, name, app_type, api_key, base_url, haiku_model, sonnet_model, opus_model, is_current)
VALUES ('$id', '$name', '$app_type', '$api_key', '$base_url', '$haiku_model', '$sonnet_model', '$opus_model', 0);
EOF

    echo "$id"
}

sqlite_delete_provider() {
    local provider_id="$1"
    sqlite3 "$CC_SWITCH_DB" "DELETE FROM providers WHERE id='$provider_id';"
}

sqlite_provider_exists() {
    local provider_id="$1"
    local count
    count=$(sqlite3 "$CC_SWITCH_DB" "SELECT COUNT(*) FROM providers WHERE id='$provider_id';")
    [ "$count" -gt 0 ]
}

# Standalone JSON mode functions
standalone_init_config() {
    if [ ! -d "$STANDALONE_DIR" ]; then
        mkdir -p "$STANDALONE_DIR"
    fi

    if [ ! -f "$STANDALONE_CONFIG" ]; then
        cat > "$STANDALONE_CONFIG" << 'EOF'
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
    fi

    if [ ! -f "$STANDALONE_PROVIDERS" ]; then
        cat > "$STANDALONE_PROVIDERS" << 'EOF'
{
  "providers": []
}
EOF
    fi
}

standalone_list_providers() {
    local app_type="$1"
    standalone_init_config

    if [ -z "$app_type" ]; then
        for app in claude codex gemini opencode openclaw; do
            echo "### $app"
            for at in $(jq -r ".providers[] | select(.app_type == \"$app\") | \"\(.id)|\(.name)|\(.is_active // false)\"" "$STANDALONE_PROVIDERS" 2>/dev/null); do
                IFS='|' read -r id name is_active <<< "$at"
                status=""
                if [ "$is_active" = "true" ]; then
                    status="[Active]"
                fi
                echo "$id|$name|$status"
            done
        done
    else
        for at in $(jq -r ".providers[] | select(.app_type == \"$app_type\") | \"\(.id)|\(.name)|\(.is_active // false)\"" "$STANDALONE_PROVIDERS" 2>/dev/null); do
            IFS='|' read -r id name is_active <<< "$at"
            status=""
            if [ "$is_active" = "true" ]; then
                status="[Active]"
            fi
            echo "$id|$name|$status"
        done
    fi
}

standalone_get_provider_by_name() {
    local name="$1"
    local app_type="$2"
    standalone_init_config

    jq -r ".providers[] | select(.name == \"$name\" and .app_type == \"$app_type\") | .id" "$STANDALONE_PROVIDERS" 2>/dev/null
}

standalone_get_provider_by_id() {
    local id="$1"
    standalone_init_config

    local result=$(jq -r ".providers[] | select(.id == \"$id\") | \"\(.name)|\(.app_type)|\(.api_key)|\(.base_url)\"" "$STANDALONE_PROVIDERS" 2>/dev/null)
    echo "$result"
}

standalone_get_current_provider() {
    local app_type="$1"
    standalone_init_config

    jq -r ".active_providers[\"$app_type\"] // empty" "$STANDALONE_CONFIG" 2>/dev/null
}

standalone_switch_provider() {
    local provider_id="$1"
    local app_type="$2"
    standalone_init_config

    # Deactivate all providers for this app
    jq "(.providers |= map(select(.app_type == \"$app_type\") | .is_active = false))" "$STANDALONE_PROVIDERS" > "${STANDALONE_PROVIDERS}.tmp" && mv "${STANDALONE_PROVIDERS}.tmp" "$STANDALONE_PROVIDERS"

    # Activate the target provider
    jq "(.providers |= map(select(.id == \"$provider_id\") | .is_active = true))" "$STANDALONE_PROVIDERS" > "${STANDALONE_PROVIDERS}.tmp" && mv "${STANDALONE_PROVIDERS}.tmp" "$STANDALONE_PROVIDERS"

    # Update config
    jq ".active_providers[\"$app_type\"] = \"$provider_id\"" "$STANDALONE_CONFIG" > "${STANDALONE_CONFIG}.tmp" && mv "${STANDALONE_CONFIG}.tmp" "$STANDALONE_CONFIG"
}

standalone_add_provider() {
    local name="$1"
    local app_type="$2"
    local api_key="$3"
    local base_url="$4"
    local haiku_model="$5"
    local sonnet_model="$6"
    local opus_model="$7"
    local id="$8"

    standalone_init_config

    if [ -z "$id" ]; then
        id=$(generate_uuid)
    fi

    # Build JSON for new provider
    local models_json
    models_json=$(jq -n --arg haiku "$haiku_model" --arg sonnet "$sonnet_model" --arg opus "$opus_model" \
        '{haiku: $haiku, sonnet: $sonnet, opus: $opus}')

    local new_provider
    new_provider=$(jq -n \
        --arg id "$id" \
        --arg name "$name" \
        --arg app_type "$app_type" \
        --arg api_key "$api_key" \
        --arg base_url "$base_url" \
        --argjson models "$models_json" \
        '{
            id: $id,
            name: $name,
            app_type: $app_type,
            api_key: $api_key,
            base_url: $base_url,
            models: $models,
            is_active: false,
            created_at: now | todate
        }')

    jq ".providers += [$new_provider]" "$STANDALONE_PROVIDERS" > "${STANDALONE_PROVIDERS}.tmp" && mv "${STANDALONE_PROVIDERS}.tmp" "$STANDALONE_PROVIDERS"

    echo "$id"
}

standalone_delete_provider() {
    local provider_id="$1"
    standalone_init_config

    jq ".providers |= map(select(.id != \"$provider_id\"))" "$STANDALONE_PROVIDERS" > "${STANDALONE_PROVIDERS}.tmp" && mv "${STANDALONE_PROVIDERS}.tmp" "$STANDALONE_PROVIDERS"

    # Also remove from config if active
    jq "(.active_providers |= with_entries(select(.value != \"$provider_id\")))" "$STANDALONE_CONFIG" > "${STANDALONE_CONFIG}.tmp" && mv "${STANDALONE_CONFIG}.tmp" "$STANDALONE_CONFIG"
}

standalone_provider_exists() {
    local provider_id="$1"
    standalone_init_config

    local count
    count=$(jq "[.providers[] | select(.id == \"$provider_id\")] | length" "$STANDALONE_PROVIDERS" 2>/dev/null)
    [ "$count" = "1" ]
}

# Unified functions - automatically use the correct mode
list_providers() {
    local app_type="$1"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_list_providers "$app_type"
    else
        standalone_list_providers "$app_type"
    fi
}

get_provider_by_name() {
    local name="$1"
    local app_type="$2"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_get_provider_by_name "$name" "$app_type"
    else
        standalone_get_provider_by_name "$name" "$app_type"
    fi
}

get_provider_by_id() {
    local id="$1"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_get_provider_by_id "$id"
    else
        standalone_get_provider_by_id "$id"
    fi
}

get_current_provider() {
    local app_type="$1"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_get_current_provider "$app_type"
    else
        standalone_get_current_provider "$app_type"
    fi
}

switch_provider() {
    local provider_id="$1"
    local app_type="$2"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_switch_provider "$provider_id" "$app_type"
    else
        standalone_switch_provider "$provider_id" "$app_type"
    fi
}

add_provider() {
    local name="$1"
    local app_type="$2"
    local api_key="$3"
    local base_url="$4"
    local haiku_model="$5"
    local sonnet_model="$6"
    local opus_model="$7"
    local id="$8"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_add_provider "$name" "$app_type" "$api_key" "$base_url" "$haiku_model" "$sonnet_model" "$opus_model" "$id"
    else
        standalone_add_provider "$name" "$app_type" "$api_key" "$base_url" "$haiku_model" "$sonnet_model" "$opus_model" "$id"
    fi
}

delete_provider() {
    local provider_id="$1"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_delete_provider "$provider_id"
    else
        standalone_delete_provider "$provider_id"
    fi
}

provider_exists() {
    local provider_id="$1"
    if [ "$MODE" = "sqlite" ]; then
        sqlite_provider_exists "$provider_id"
    else
        standalone_provider_exists "$provider_id"
    fi
}

# Utility functions
generate_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen
    elif command -v python3 &>/dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        echo "provider-$(date +%s)-$RANDOM"
    fi
}

# Get provider API key and base URL (unified)
get_provider_credentials() {
    local provider_id="$1"

    if [ "$MODE" = "sqlite" ]; then
        local settings_config=$(sqlite3 "$CC_SWITCH_DB" "SELECT settings_config FROM providers WHERE id='$provider_id';")
        local api_key=$(echo "$settings_config" | jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty')
        local base_url=$(echo "$settings_config" | jq -r '.env.ANTHROPIC_BASE_URL // empty')
        echo "$api_key|$base_url"
    else
        jq -r ".providers[] | select(.id == \"$provider_id\") | \"\(.api_key)|\(.base_url)\"" "$STANDALONE_PROVIDERS" 2>/dev/null
    fi
}

# Get provider name by ID
get_provider_name() {
    local provider_id="$1"

    if [ "$MODE" = "sqlite" ]; then
        sqlite3 "$CC_SWITCH_DB" "SELECT name FROM providers WHERE id='$provider_id';"
    else
        jq -r ".providers[] | select(.id == \"$provider_id\") | .name" "$STANDALONE_PROVIDERS" 2>/dev/null
    fi
}

# Get provider model (for standalone mode, return from JSON)
get_provider_model() {
    local provider_id="$1"
    local model_type="$2"  # haiku, sonnet, opus

    if [ "$MODE" = "sqlite" ]; then
        local settings_config=$(sqlite3 "$CC_SWITCH_DB" "SELECT settings_config FROM providers WHERE id='$provider_id';")
        case "$model_type" in
            haiku) echo "$settings_config" | jq -r '.env.ANTHROPIC_DEFAULT_HAIKU_MODEL // empty' ;;
            sonnet) echo "$settings_config" | jq -r '.env.ANTHROPIC_DEFAULT_SONNET_MODEL // empty' ;;
            opus) echo "$settings_config" | jq -r '.env.ANTHROPIC_DEFAULT_OPUS_MODEL // empty' ;;
        esac
    else
        jq -r ".providers[] | select(.id == \"$provider_id\") | .models.$model_type" "$STANDALONE_PROVIDERS" 2>/dev/null
    fi
}

# Check if provider is currently active
is_provider_active() {
    local provider_id="$1"
    local app_type="$2"

    if [ "$MODE" = "sqlite" ]; then
        local is_current
        is_current=$(sqlite3 "$CC_SWITCH_DB" "SELECT is_current FROM providers WHERE id='$provider_id';")
        [ "$is_current" = "1" ]
    else
        local is_active
        is_active=$(jq -r ".providers[] | select(.id == \"$provider_id\") | .is_active" "$STANDALONE_PROVIDERS" 2>/dev/null)
        [ "$is_active" = "true" ]
    fi
}

# Get current provider ID for an app
get_active_provider_id() {
    local app_type="$1"

    if [ "$MODE" = "sqlite" ]; then
        sqlite_get_current_provider "$app_type"
    else
        standalone_get_current_provider "$app_type"
    fi
}

# Merge only Claude Code's endpoint into ~/.claude/settings.json.
# This intentionally preserves the rest of the file and does not
# mutate cc-switch's provider state.
update_claude_settings_endpoint() {
    local base_url="$1"
    local settings_path="${2:-$HOME/.claude/settings.json}"
    local temp_file

    if [ -z "$base_url" ]; then
        echo "Error: base_url is required to update Claude settings" >&2
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required to update Claude settings safely" >&2
        return 1
    fi

    mkdir -p "$(dirname "$settings_path")"
    temp_file="${settings_path}.tmp"

    if [ -f "$settings_path" ] && [ -s "$settings_path" ]; then
        if ! jq --arg base_url "$base_url" \
            '.env = (.env // {}) | .env.ANTHROPIC_BASE_URL = $base_url' \
            "$settings_path" > "$temp_file"; then
            rm -f "$temp_file"
            echo "Error: Failed to merge endpoint into $settings_path" >&2
            return 1
        fi
    else
        if ! jq -n --arg base_url "$base_url" \
            '{env: {ANTHROPIC_BASE_URL: $base_url}}' > "$temp_file"; then
            rm -f "$temp_file"
            echo "Error: Failed to create $settings_path" >&2
            return 1
        fi
    fi

    chmod 600 "$temp_file" 2>/dev/null || true
    mv "$temp_file" "$settings_path"
}
