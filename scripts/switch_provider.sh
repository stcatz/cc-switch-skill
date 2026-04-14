#!/bin/bash
# Switch active provider for a specific app

set -e

CONFIG_DIR="$HOME/.cc-switch-skill"
PROVIDERS_FILE="$CONFIG_DIR/providers.json"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Check if config exists
if [ ! -f "$PROVIDERS_FILE" ]; then
    echo "No providers found. Add a provider first."
    exit 1
fi

# Function to get provider details
get_provider() {
    local provider_id="$1"
    local field="$2"

    if command -v jq &>/dev/null; then
        jq -r ".providers[] | select(.id == \"$provider_id\") | .$field" "$PROVIDERS_FILE" 2>/dev/null
    else
        python3 -c "import json; d=json.load(open('$PROVIDERS_FILE')); p=[x for x in d['providers'] if x.get('id')=='$provider_id']; print(p[0].get('$field') if p else '')"
    fi
}

# Function to get current active provider
get_active_id() {
    local app_type="$1"
    if command -v jq &>/dev/null; then
        jq -r ".active_providers[\"$app_type\"] // empty" "$CONFIG_FILE" 2>/dev/null
    else
        python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('active_providers', {}).get('$app_type') or '')"
    fi
}

# Function to deactivate all providers for an app
deactivate_all() {
    local app_type="$1"

    if command -v jq &>/dev/null; then
        jq "(.providers |= map(select(.app_type == \"$app_type\") | .is_active = false))" "$PROVIDERS_FILE" > "${PROVIDERS_FILE}.tmp" && mv "${PROVIDERS_FILE}.tmp" "$PROVIDERS_FILE"
    else
        python3 << PYTHON_SCRIPT
import json
with open('$PROVIDERS_FILE', 'r') as f:
    data = json.load(f)
for p in data['providers']:
    if p.get('app_type') == '$app_type':
        p['is_active'] = False
with open('$PROVIDERS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
    fi
}

# Function to activate a provider
activate_provider() {
    local provider_id="$1"

    if command -v jq &>/dev/null; then
        jq "(.providers |= map(select(.id == \"$provider_id\") | .is_active = true)" "$PROVIDERS_FILE" > "${PROVIDERS_FILE}.tmp" && mv "${PROVIDERS_FILE}.tmp" "$PROVIDERS_FILE"
    else
        python3 << PYTHON_SCRIPT
import json
with open('$PROVIDERS_FILE', 'r') as f:
    data = json.load(f)
for p in data['providers']:
    if p.get('id') == '$provider_id':
        p['is_active'] = True
with open('$PROVIDERS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
    fi
}

# Function to update active provider in config
update_config() {
    local app_type="$1"
    local provider_id="$2"

    if command -v jq &>/dev/null; then
        jq ".active_providers[\"$app_type\"] = \"$provider_id\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    else
        python3 << PYTHON_SCRIPT
import json
with open('$CONFIG_FILE', 'r') as f:
    data = json.load(f)
if 'active_providers' not in data:
    data['active_providers'] = {}
data['active_providers']['$app_type'] = '$provider_id'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
    fi
}

# Parse arguments
app_type=""
provider_name=""
provider_id=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
                shift
                app_type="$1"
                ;;
        --name)
                shift
                provider_name="$1"
                ;;
        --id)
                shift
                provider_id="$1"
                ;;
        *)
                shift
                ;;
    esac
done

# Validate arguments
if [ -z "$app_type" ]; then
    echo "Error: --app is required (claude, codex, gemini, opencode, openclaw)"
    exit 1
fi

if [ -z "$provider_id" ] && [ -z "$provider_name" ]; then
    echo "Error: Either --id or --name is required"
    exit 1
fi

# If name provided, find ID
if [ -n "$provider_name" ] && [ -z "$provider_id" ]; then
    if command -v jq &>/dev/null; then
        provider_id=$(jq -r ".providers[] | select(.name == \"$provider_name\" and .app_type == \"$app_type\") | .id" "$PROVIDERS_FILE" 2>/dev/null)
    else
        provider_id=$(python3 -c "import json; d=json.load(open('$PROVIDERS_FILE')); p=[x for x in d['providers'] if x.get('name')=='$provider_name' and x.get('app_type')=='$app_type']; print(p[0]['id'] if p else '')" 2>/dev/null)
    fi

    if [ -z "$provider_id" ]; then
        echo "Error: Provider '$provider_name' not found for $app_type"
        exit 1
    fi
fi

# Verify provider exists
if [ -z "$(get_provider "$provider_id" "name")" ]; then
    echo "Error: Provider ID '$provider_id' not found"
    exit 1
fi

provider_name=$(get_provider "$provider_id" "name")

echo "Switching $app_type to $provider_name..."

# Deactivate all providers for the app
deactivate_all "$app_type"

# Activate the target provider
activate_provider "$provider_id"

# Update config
update_config "$app_type" "$provider_id"

echo "✅ Successfully switched $app_type provider to: $provider_name"
echo "Provider ID: $provider_id"

# Check if restart is needed
if [ "$app_type" = "claude" ]; then
    echo ""
    echo "ℹ️  Claude Code supports hot-switching - changes take effect immediately!"
else
    echo ""
    echo "⚠️  Please restart your terminal or CLI tool for changes to take effect."
fi
