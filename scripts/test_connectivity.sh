#!/bin/bash
# Test connectivity of a provider
# Supports both cc-switch SQLite mode and standalone JSON mode

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
app_type="claude"
provider_id=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
                shift
                app_type="$1"
                ;;
        --id)
                shift
                provider_id="$1"
                ;;
        --name)
                shift
                local provider_name="$1"
                provider_id=$(get_provider_by_name "$provider_name" "$app_type")
                if [ -z "$provider_id" ]; then
                    echo "Error: Provider '$provider_name' not found"
                    exit 1
                fi
                ;;
        *)
                shift
                ;;
    esac
done

# Default: test active provider
if [ -z "$provider_id" ]; then
    provider_id=$(get_active_provider_id "$app_type")
    if [ -z "$provider_id" ]; then
        echo "No active provider found for $app_type"
        exit 1
    fi
fi

# Get provider details
provider_name=$(get_provider_name "$provider_id")
credentials=$(get_provider_credentials "$provider_id")
IFS='|' read -r api_key base_url <<< "$credentials"

# Get model for testing
model=$(get_provider_model "$provider_id" "sonnet")
if [ -z "$model" ]; then
    model=$(get_provider_model "$provider_id" "opus")
fi
if [ -z "$model" ]; then
    model=$(get_provider_model "$provider_id" "haiku")
fi

# Default model if not specified
if [ -z "$model" ]; then
    model="claude-3-5-sonnet-20241022"
fi

mode_info=""
if [ "$MODE" = "sqlite" ]; then
    mode_info="[cc-switch mode]"
else
    mode_info="[standalone mode]"
fi

echo "======================================"
echo "        Connectivity Test        "
echo "======================================"
echo ""
echo "Mode: $mode_info"
echo "Provider: $provider_name"
echo "App Type: $app_type"
echo "API Endpoint: $base_url"
echo "Model: $model"
echo ""

# Build API request
api_endpoint="${base_url%/}/v1/messages"

# Test with curl
start_time=$(date +%s%3N)

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME:%{time_total}s\n" \
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

end_time=$(date +%s%3N)
duration=$((end_time - start_time))

# Parse response
http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d':' -f2)
time_total=$(echo "$response" | grep "TIME" | cut -d':' -f2)
body=$(echo "$response" | sed '/^HTTP_STATUS/d; /^TIME/d')

# Display results
echo "======================================"
echo "        Test Result             "
echo "======================================"
echo ""

if [ "$http_status" = "200" ]; then
    echo "✅ Test Successful"
    echo ""
    echo "| Metric        | Result |"
    echo "|---------------|--------|"
    echo "| HTTP Status   | 200 OK |"
    echo "| Response Time | ${time_total}s |"
    echo "| Model Used   | $model |"

    echo ""
    echo "Response preview:"
    echo "$body" | head -c 500
else
    echo "❌ Test Failed"
    echo ""
    echo "Error Details:"
    echo "HTTP Status: $http_status"
    echo "API Endpoint: $api_endpoint"
    echo ""
    echo "Response:"
    echo "$body" | head -20
fi

echo ""
echo "======================================"

# Return exit code based on result
if [ "$http_status" = "200" ]; then
    exit 0
else
    exit 1
fi
