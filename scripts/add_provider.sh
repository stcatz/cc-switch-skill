#!/bin/bash
# Add a new provider to cc-switch-skill configuration

set -e

CONFIG_DIR="$HOME/.cc-switch-skill"
CONFIG_FILE="$CONFIG_DIR/config.json"
PROVIDERS_FILE="$CONFIG_DIR/providers.json"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
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

# Create providers file if it doesn't exist
if [ ! -f "$PROVIDERS_FILE" ]; then
    cat > "$PROVIDERS_FILE" << 'EOF'
{
  "providers": []
}
EOF
fi

# Function to generate UUID
generate_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen
    elif command -v python3 &>/dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        # Fallback: generate timestamp-based ID
        echo "provider-$(date +%s)-$RANDOM"
    fi
}

# Function to add provider
add_provider() {
    local id name app_type api_key base_url haiku_model sonnet_model opus_model

    # Parse arguments
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
        return 1
    fi

    if [ -z "$app_type" ]; then
        echo "Error: --app is required (claude, codex, gemini, opencode, openclaw)"
        return 1
    fi

    if [ -z "$api_key" ]; then
        echo "Error: --key is required"
        return 1
    fi

    if [ -z "$base_url" ]; then
        echo "Error: --url is required"
        return 1
    fi

    # Generate ID if not provided
    if [ -z "$id" ]; then
        id=$(generate_uuid)
    fi

    # Create provider object
    provider_json=$(cat << EOF
{
  "id": "$id",
  "name": "$name",
  "app_type": "$app_type",
  "api_key": "$api_key",
  "base_url": "$base_url",
  "models": {
    "haiku": "${haiku_model:-}",
    "sonnet": "${sonnet_model:-}",
    "opus": "${opus_model:-}"
  },
  "is_active": false,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)

    # Add to providers file
    if command -v jq &>/dev/null; then
        # Use jq if available
        jq --argjson new_provider '.providers += [$new_provider]' "$PROVIDERS_FILE" > "${PROVIDERS_FILE}.tmp" && mv "${PROVIDERS_FILE}.tmp" "$PROVIDERS_FILE"
    else
        # Fallback: use Python
        python3 << PYTHON_SCRIPT
import json

providers_file = "$PROVIDERS_FILE"
new_provider = json.loads('''$provider_json''')

with open(providers_file, 'r') as f:
    data = json.load(f)

data['providers'].append(new_provider)

with open(providers_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f"Added provider: {new_provider['name']} ({new_provider['id']})")
PYTHON_SCRIPT
    fi

    echo "✅ Provider added successfully"
    echo "ID: $id"
    echo "Name: $name"
    echo "App Type: $app_type"
}

# Show usage if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 --name <name> --app <claude|codex|gemini|opencode|openclaw> --key <api_key> --url <base_url> [--id <id>] [--haiku <model>] [--sonnet <model>] [--opus <model>]"
    echo ""
    echo "Examples:"
    echo "  $0 --name 'MiniMax' --app claude --key 'sk-xxx' --url 'https://api.minimax.com/v1'"
    echo "  $0 --name 'Anthropic Official' --app claude --key 'sk-ant-xxx' --url 'https://api.anthropic.com/v1'"
    exit 0
fi

# Run add function
add_provider "$@"
