#!/bin/bash
# Delete a provider from cc-switch-skill configuration

set -e

CONFIG_DIR="$HOME/.cc-switch-skill"
PROVIDERS_FILE="$CONFIG_DIR/providers.json"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Check if config exists
if [ ! -f "$PROVIDERS_FILE" ]; then
    echo "No providers found."
    exit 0
fi

# Function to delete provider
delete_provider() {
    local provider_id="$1"
    local app_type

    # Get provider app type
    if command -v jq &>/dev/null; then
        app_type=$(jq -r ".providers[] | select(.id == \"$provider_id\") | .app_type" "$PROVIDERS_FILE" 2>/dev/null)
    else
        app_type=$(python3 -c "import json; d=json.load(open('$PROVIDERS_FILE')); p=[x for x in d['providers'] if x.get('id')=='$provider_id']; print(p[0].get('app_type') if p else ''" 2>/dev/null)
    fi

    # Check if provider is currently active
    local active_id
    if command -v jq &>/dev/null; then
        active_id=$(jq -r ".active_providers[\"$app_type\"] // empty" "$CONFIG_FILE" 2>/dev/null)
    else
        active_id=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('active_providers', {}).get('$app_type') or '')" 2>/dev/null)
    fi

    if [ "$provider_id" = "$active_id" ]; then
        echo "Error: Cannot delete currently active provider. Switch to another provider first."
        return 1
    fi

    # Remove provider from list
    if command -v jq &>/dev/null; then
        jq "(.providers |= map(select(.id != \"$provider_id\"))" "$PROVIDERS_FILE" > "${PROVIDERS_FILE}.tmp" && mv "${PROVIDERS_FILE}.tmp" "$PROVIDERS_FILE"
    else
        python3 << PYTHON_SCRIPT
import json
with open('$PROVIDERS_FILE', 'r') as f:
    data = json.load(f)
data['providers'] = [p for p in data['providers'] if p.get('id') != '$provider_id']
with open('$PROVIDERS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
PYTHON_SCRIPT
    fi

    echo "✅ Provider deleted successfully"
}

# Parse arguments
provider_id=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)
                shift
                provider_id="$1"
                ;;
        --name)
                shift
                local provider_name="$1"
                # Find ID by name
                if command -v jq &>/dev/null; then
                    provider_id=$(jq -r ".providers[] | select(.name == \"$provider_name\") | .id" "$PROVIDERS_FILE" 2>/dev/null)
                else
                    provider_id=$(python3 -c "import json; d=json.load(open('$PROVIDERS_FILE')); p=[x for x in d['providers'] if x.get('name')=='$provider_name']; print(p[0]['id'] if p else ''" 2>/dev/null)
                fi
                if [ -z "$provider_id" ]; then
                    echo "Error: Provider '$provider_name' not found"
                    exit 1
                fi
                ;;
        --app)
                shift
                local app_filter="$1"
                if [ -n "$provider_id" ]; then
                    # ID already set, skip
                    :
                # List providers for app and let user choose
                fi
                ;;
        *)
                shift
                ;;
    esac
done

# Show usage if no arguments
if [ -z "$provider_id" ]; then
    echo "Usage: $0 --id <provider_id>"
    echo "       $0 --name <provider_name>"
    echo ""
    echo "Examples:"
    echo "  $0 --id provider-uuid"
    echo "  $0 --name 'MiniMax'"
    exit 0
fi

# Run delete function
delete_provider "$provider_id"
