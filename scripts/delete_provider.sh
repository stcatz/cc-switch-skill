#!/bin/bash
# Delete a provider
# Supports both cc-switch SQLite mode and standalone JSON mode

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
provider_id=""
provider_name=""
app_type=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)
                shift
                provider_id="$1"
                ;;
        --name)
                shift
                provider_name="$1"
                # Find ID by name (need app_type to be specific)
                ;;
        --app)
                shift
                app_type="$1"
                ;;
        *)
                shift
                ;;
    esac
done

# If name provided, find ID
if [ -n "$provider_name" ]; then
    if [ -z "$app_type" ]; then
        echo "Error: When using --name, --app is also required to uniquely identify the provider"
        exit 1
    fi
    provider_id=$(get_provider_by_name "$provider_name" "$app_type")
    if [ -z "$provider_id" ]; then
        echo "Error: Provider '$provider_name' not found for $app_type"
        exit 1
    fi
fi

# Validate provider ID
if [ -z "$provider_id" ]; then
    echo "Error: Either --id or (--name with --app) is required"
    echo ""
    echo "Usage: $0 --id <provider_id>"
    echo "       $0 --name <provider_name> --app <app_type>"
    exit 1
fi

# Check if provider exists
if ! provider_exists "$provider_id"; then
    echo "Error: Provider ID '$provider_id' not found"
    exit 1
fi

# Get provider details
provider_name=$(get_provider_name "$provider_id")
provider_app_type=""

if [ "$MODE" = "sqlite" ]; then
    provider_app_type=$(sqlite3 "$CC_SWITCH_DB" "SELECT app_type FROM providers WHERE id='$provider_id';")
else
    provider_app_type=$(jq -r ".providers[] | select(.id == \"$provider_id\") | .app_type" "$STANDALONE_PROVIDERS" 2>/dev/null)
fi

# Check if provider is currently active
if is_provider_active "$provider_id" "$provider_app_type"; then
    echo "======================================"
    echo "        Error                  "
    echo "======================================"
    echo ""
    echo "Cannot delete currently active provider."
    echo ""
    echo "Provider: $provider_name"
    echo "App: $provider_app_type"
    echo ""
    echo "Please switch to another provider first before deleting."
    echo ""
    echo "======================================"
    exit 1
fi

# Display mode info
mode_info=""
if [ "$MODE" = "sqlite" ]; then
    mode_info="[cc-switch mode]"
else
    mode_info="[standalone mode]"
fi

echo "======================================"
echo "        Deleting Provider       "
echo "======================================"
echo ""
echo "Mode: $mode_info"
echo "Provider: $provider_name"
echo "ID: $provider_id"
echo ""

# Delete provider
delete_provider "$provider_id"

echo "✅ Provider deleted successfully"
echo ""
echo "======================================"
