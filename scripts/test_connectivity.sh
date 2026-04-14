#!/bin/bash
# Test connectivity of a provider

set -e

CONFIG_DIR="$HOME/.cc-switch-skill"
PROVIDERS_FILE="$CONFIG_DIR/providers.json"
CONFIG_FILE="$CONFIG_DIR/config.json"

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

# Function to get active provider for an app
get_active_id() {
    local app_type="$1"
    if command -v jq &>/dev/null; then
        jq -r ".active_providers[\"$app_type\"] // empty" "$CONFIG_FILE" 2>/dev/null
    else
        python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('active_providers', {}).get('$app_type') or '')"
    fi
}

# Function to get model name
get_model() {
    local app_type="$1"
    local model_type="$2"  # haiku, sonnet, or opus
    local provider_id="$3"

    local base_url=$(get_provider "$provider_id" "base_url")

    # Map app_type to Anthropic models
    if [ "$app_type" = "claude" ]; then
        get_provider "$provider_id" "models" | jq -r ".$model_type" 2>/dev/null || echo ""
    else
        # For other apps, try to get model from provider
        get_provider "$provider_id" "models" | jq -r ".haiku // empty" 2>/dev/null || echo ""
    fi
}

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
                if command -v jq &>/dev/null; then
                    provider_id=$(jq -r ".providers[] | select(.name == \"$provider_name\") | .id" "$PROVIDERS_FILE" 2>/dev/null
                else
                    provider_id=$(python3 -c "import json; d=json.load(open('$PROVIDERS_FILE')); p=[x for x in d['providers'] if x.get('name')=='$provider_name']; print(p[0]['id'] if p else ''" 2>/dev/null)
                fi
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
    provider_id=$(get_active_id "$app_type")
    if [ -z "$provider_id" ]; then
        echo "No active provider found for $app_type"
        exit 1
    fi
fi

# Get provider details
provider_name=$(get_provider "$provider_id" "name")
base_url=$(get_provider "$provider_id" "base_url")
api_key=$(get_provider "$provider_id" "api_key")
model=$(get_provider "$provider_id" "models" | jq -r '.opus // .sonnet // empty' 2>/dev/null)

# Default model if not specified
if [ -z "$model" ]; then
    model="claude-3-5-sonnet-20241022"
fi

echo "Testing connectivity..."
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
echo "        Connectivity Test        "
echo "======================================"
echo ""

if [ "$http_status" = "200" ]; then
    echo "✅ Test Successful"
    echo ""
    echo "| Metric        | Result |"
    echo "|---------------|--------|"
    echo "| HTTP Status   | 200 OK |"
    echo "| Response Time | ${time_total}s |"

    # Extract some info from response if possible
    echo "| Model         | $model |"

    echo ""
    echo "Response preview:"
    echo "$body" | head -c 3
else
    echo "❌ Test Failed"
    echo ""
    echo "Error Details:"
    echo "HTTP Status: $http_status"
    echo "Response: $body"
fi

echo ""
echo "======================================"
