#!/bin/bash
# Switch active provider for a specific app
# Supports both cc-switch SQLite mode and standalone JSON mode

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
app_type=""
provider_name=""
provider_id=""
skip_test="false"

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
        --skip-test)
                skip_test="true"
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
    provider_id=$(get_provider_by_name "$provider_name" "$app_type")
    if [ -z "$provider_id" ]; then
        echo "Error: Provider '$provider_name' not found for $app_type"
        exit 1
    fi
fi

# Verify provider exists
if ! provider_exists "$provider_id"; then
    echo "Error: Provider ID '$provider_id' not found"
    exit 1
fi

provider_name=$(get_provider_name "$provider_id")
mode_info=""
if [ "$MODE" = "sqlite" ]; then
    mode_info="[cc-switch mode]"
else
    mode_info="[standalone mode]"
fi

echo ""
echo "======================================"
echo "        Switching Provider        "
echo "======================================"
echo ""
echo "Mode: $mode_info"
echo "App: $app_type"
echo "Target Provider: $provider_name"
echo ""

# Test connectivity first (unless skipped)
if [ "$skip_test" = "false" ]; then
    echo "Testing connectivity..."

    credentials=$(get_provider_credentials "$provider_id")
    IFS='|' read -r api_key base_url <<< "$credentials"

    if [ -z "$api_key" ] || [ -z "$base_url" ]; then
        echo "⚠️  Warning: Could not retrieve provider credentials"
        echo ""
    else
        # Get model for testing
        model=$(get_provider_model "$provider_id" "sonnet")
        if [ -z "$model" ]; then
            model=$(get_provider_model "$provider_id" "opus")
        fi
        if [ -z "$model" ]; then
            model="claude-3-5-sonnet-20241022"
        fi

        api_endpoint="${base_url%/}/v1/messages"

        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" \
            -X POST "$api_endpoint" \
            -H "x-api-key: $api_key" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d "{
                \"model\": \"$model\",
                \"max_tokens\": 10,
                \"messages\": [
                    {
                        \"role\": \"user\",
                        \"content\": \"ping\"
                    }
                ]
            }" 2>&1)

        http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d':' -f2)
        body=$(echo "$response" | sed '/^HTTP_STATUS/d')

        if [ "$http_status" = "200" ]; then
            echo "✅ Connectivity test passed"
            echo ""
        else
            echo ""
            echo "======================================"
            echo "        Connectivity Test FAILED   "
            echo "======================================"
            echo ""
            echo "Error Details:"
            echo "HTTP Status: $http_status"
            echo "API Endpoint: $api_endpoint"
            echo "Model: $model"
            echo ""
            echo "Response:"
            echo "$body" | head -20
            echo ""
            echo "======================================"
            echo ""

            # Ask user if they want to proceed
            echo "⚠️  The connectivity test failed."
            echo "Possible causes:"
            echo "  - Invalid API key"
            echo "  - Incorrect base URL"
            echo "  - Model name mismatch"
            echo "  - Network connectivity issues"
            echo ""
            echo "Do you want to switch to this provider anyway? (yes/no)"
            read -r response

            if [ "$response" != "yes" ] && [ "$response" != "y" ] && [ "$response" != "Y" ]; then
                echo ""
                echo "Switch cancelled."
                exit 1
            fi
            echo ""
        fi
    fi
fi

echo "Switching $app_type to $provider_name..."

# Perform the switch
switch_provider "$provider_id" "$app_type"

echo "✅ Successfully switched $app_type provider to: $provider_name"
echo "Provider ID: $provider_id"
echo ""

# Check if restart is needed
if [ "$app_type" = "claude" ]; then
    echo "ℹ️  Claude Code supports hot-switching - changes take effect immediately!"

    # For Claude Code, update settings.json if possible
    if [ "$MODE" = "standalone" ]; then
        # Update Claude Code settings.json
        CC_SETTINGS="$HOME/.claude/settings.json"
        if [ -f "$CC_SETTINGS" ] || command -v jq &>/dev/null; then
            credentials=$(get_provider_credentials "$provider_id")
            IFS='|' read -r api_key base_url <<< "$credentials"

            model=$(get_provider_model "$provider_id" "sonnet")
            if [ -z "$model" ]; then
                model=$(get_provider_model "$provider_id" "opus")
            fi
            if [ -z "$model" ]; then
                model=$(get_provider_model "$provider_id" "haiku")
            fi

            if [ -n "$api_key" ] && [ -n "$base_url" ] && [ -n "$model" ]; then
                mkdir -p "$(dirname "$CC_SETTINGS")"
                if command -v jq &>/dev/null; then
                    cat > "$CC_SETTINGS" << EOF
{
  "ANTHROPIC_AUTH_TOKEN": "$api_key",
  "ANTHROPIC_BASE_URL": "$base_url",
  "ANTHROPIC_MODEL": "$model"
}
EOF
                    echo ""
                    echo "ℹ️  Claude Code settings.json updated automatically."
                fi
            fi
        fi
    fi
else
    echo "⚠️  Please restart your terminal or CLI tool for changes to take effect."
fi

echo ""
echo "======================================"
