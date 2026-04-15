#!/bin/bash
# List all providers
# Supports both cc-switch SQLite mode and standalone JSON mode

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

# Function to format provider list for display
format_provider_list() {
    local app_type="$1"
    local active_id

    if [ "$MODE" = "sqlite" ]; then
        active_id=$(get_active_provider_id "$app_type")
        sqlite3 "$CC_SWITCH_DB" "SELECT id, name, app_type, is_current FROM providers WHERE app_type='$app_type' ORDER BY name;" | while IFS='|' read -r id name app_type is_current; do
            display_provider "$id" "$name" "$app_type" "$is_current" "$active_id"
        done
    else
        standalone_init_config
        active_id=$(get_active_provider_id "$app_type")

        for at in $(jq -r ".providers[] | select(.app_type == \"$app_type\") | \"\(.id)|\(.name)|\(.is_active // false)\"" "$STANDALONE_PROVIDERS" 2>/dev/null); do
            IFS='|' read -r id name is_active <<< "$at"
            display_provider "$id" "$name" "$app_type" "$is_active" "$active_id"
        done
    fi
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

if [ "$MODE" = "sqlite" ]; then
    echo ""
    echo "Mode: [cc-switch SQLite]"
else
    echo ""
    echo "Mode: [standalone JSON]"
fi

echo ""

if [ "$show_all" = "true" ]; then
    # List all providers grouped by app
    for app_type in claude codex gemini opencode openclaw; do
        has_providers="false"

        if [ "$MODE" = "sqlite" ]; then
            count=$(sqlite3 "$CC_SWITCH_DB" "SELECT COUNT(*) FROM providers WHERE app_type='$app_type';" 2>/dev/null || echo "0")
            [ "$count" -gt 0 ] && has_providers="true"
        else
            count=$(jq "[.providers[] | select(.app_type == \"$app_type\")] | length" "$STANDALONE_PROVIDERS" 2>/dev/null || echo "0")
            [ "$count" -gt 0 ] && has_providers="true"
        fi

        if [ "$has_providers" = "true" ]; then
            echo "### $app_type"
            echo "ID                                      | Name                        | Status"
            echo "--------------------------------------+------------------------------+--------"
            format_provider_list "$app_type"
            echo ""
        fi
    done
else
    # List only specified app
    echo "### $app_filter"
    echo "ID                                      | Name                        | Status"
    echo "--------------------------------------+------------------------------+--------"
    format_provider_list "$app_filter"
    echo ""
fi

echo "======================================"
