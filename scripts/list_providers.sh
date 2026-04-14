#!/bin/bash
# List all providers from cc-switch-skill configuration

set -e

CONFIG_DIR="$HOME/.cc-switch-skill"
PROVIDERS_FILE="$CONFIG_DIR/providers.json"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Check if config exists
if [ ! -f "$PROVIDERS_FILE" ]; then
    echo "No providers found. Add a provider first."
    exit 0
fi

# Read active providers
active_providers=$(cat "$CONFIG_FILE" 2>/dev/null || echo '{}')

# Function to get active provider ID for an app
get_active_id() {
    local app_type="$1"
    if command -v jq &>/dev/null; then
        jq -r ".active_providers[\"$app_type\"] // empty" "$CONFIG_FILE" 2>/dev/null
    else
        python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('active_providers', {}).get('$app_type') or '')"
    fi
}

# Function to display provider
display_provider() {
    local id name app_type is_active active_id
    id="$1"
    name="$2"
    app_type="$3"
    is_active="$4"
    active_id="$5"

    local status="[Inactive]"
    if [ "$is_active" = "true" ] || [ "$is_active" = "1" ]; then
        status="[Active]"
    fi

    local marker=""
    if [ "$id" = "$active_id" ]; then
        marker="🟢 "
    fi

    printf "%-40s | %-30s | %s\n" "$id" "$name ($app_type)" "$marker$status"
}

# Parse command line
app_filter=""
show_all="true"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
                shift
                app_filter="$1"
                show_all="false"
                ;;
        *)
                shift
                ;;
    esac
done

# Display providers
echo "======================================"
echo "        Providers List        "
echo "======================================"
echo ""

if [ "$show_all" = "true" ]; then
    # List all providers grouped by app
    for app_type in claude codex gemini opencode openclaw; do
        active_id=$(get_active_id "$app_type")

        if command -v jq &>/dev/null; then
            providers=$(jq -r ".providers[] | select(.app_type == \"$app_type\") | {id, name, is_active}" "$PROVIDERS_FILE" 2>/dev/null)
        else
            providers=$(python3 << PYTHON_SCRIPT
import json
data = json.load(open('$PROVIDERS_FILE'))
apps = [p for p in data['providers'] if p.get('app_type') == '$app_type']
for p in apps:
    print(f"{p['id']}|{p['name']}|{p.get('is_active', False)}")
PYTHON_SCRIPT
        fi

        if [ -n "$providers" ]; then
            echo "### $app_type"
            echo "ID                                      | Name                        | Status"
            echo "--------------------------------------+------------------------------+--------"
            echo "$providers" | while IFS='|' read -r id name is_active; do
                display_provider "$id" "$name" "$app_type" "$is_active" "$active_id"
            done
            echo ""
        fi
    done
else
    # List only specified app
    active_id=$(get_active_id "$app_filter")

    if command -v jq &>/dev/null; then
        providers=$(jq -r ".providers[] | select(.app_type == \"$app_filter\") | {id, name, is_active}" "$PROVIDERS_FILE" 2>/dev/null)
    else
        providers=$(python3 << PYTHON_SCRIPT
import json
data = json.load(open('$PROVIDERS_FILE'))
apps = [p for p in data['providers'] if p.get('app_type') == '$app_filter']
for p in apps:
    print(f"{p['id']}|{p['name']}|{p.get('is_active', False)}")
PYTHON_SCRIPT
        fi

    if [ -n "$providers" ]; then
        echo "### $app_filter"
        echo "ID                                      | Name                        | Status"
        echo "--------------------------------------+------------------------------+--------"
        echo "$providers" | while IFS='|' read -r id name is_active; do
            display_provider "$id" "$name" "$app_filter" "$is_active" "$active_id"
        done
    else
        echo "No providers found for $app_filter"
    fi
fi

echo "======================================"
