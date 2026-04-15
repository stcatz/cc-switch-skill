#!/bin/bash
# Add a new provider
# Supports both cc-switch SQLite mode and standalone JSON mode

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
id=""
name=""
app_type=""
api_key=""
base_url=""
haiku_model=""
sonnet_model=""
opus_model=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --id)
                shift
                id="$1"
                ;;
        --name)
                shift
                name="$1"
                ;;
        --app)
                shift
                app_type="$1"
                ;;
        --key)
                shift
                api_key="$1"
                ;;
        --url)
                shift
                base_url="$1"
                ;;
        --haiku)
                shift
                haiku_model="$1"
                ;;
        --sonnet)
                shift
                sonnet_model="$1"
                ;;
        --opus)
                shift
                opus_model="$1"
                ;;
        *)
                shift
                ;;
    esac
done

# Validate required fields
if [ -z "$name" ]; then
    echo "Error: --name is required"
    exit 1
fi

if [ -z "$app_type" ]; then
    echo "Error: --app is required (claude, codex, gemini, opencode, openclaw)"
    exit 1
fi

if [ -z "$api_key" ]; then
    echo "Error: --key is required"
    exit 1
fi

if [ -z "$base_url" ]; then
    echo "Error: --url is required"
    exit 1
fi

# Set default models if not specified
if [ -z "$haiku_model" ] && [ -z "$sonnet_model" ] && [ -z "$opus_model" ]; then
    haiku_model=""
    sonnet_model=""
    opus_model=""
fi

# Generate ID if not provided
if [ -z "$id" ]; then
    id=$(generate_uuid)
fi

# Display mode info
mode_info=""
if [ "$MODE" = "sqlite" ]; then
    mode_info="[cc-switch mode]"
else
    mode_info="[standalone mode]"
fi

echo "======================================"
echo "        Adding Provider         "
echo "======================================"
echo ""
echo "Mode: $mode_info"
echo "Name: $name"
echo "App Type: $app_type"
echo "Base URL: $base_url"
echo ""

# Add provider using unified function
new_id=$(add_provider "$name" "$app_type" "$api_key" "$base_url" "$haiku_model" "$sonnet_model" "$opus_model" "$id")

echo ""
echo "✅ Provider added successfully"
echo "ID: $new_id"
echo "Name: $name"
echo ""
echo "======================================"
