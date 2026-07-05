#!/usr/bin/env bash
# ============================================================================
# Hermes Pterodactyl Skill — Configuration Validator
# ============================================================================
# Checks if the Pterodactyl API credentials are properly configured.
# Returns structured output for the AI agent to parse.
# ============================================================================

set -euo pipefail

CONFIG_DIR="${HOME}/.pterodactyl"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# Output format: JSON for machine parsing
output_json() {
    echo "$1"
}

# ============================================================================
# Check 1: Config file exists
# ============================================================================
if [[ ! -f "$CONFIG_FILE" ]]; then
    # Also check environment variables as fallback
    if [[ -n "${PTERODACTYL_PANEL_URL:-}" ]]; then
        panel_url="$PTERODACTYL_PANEL_URL"
        app_key="${PTERODACTYL_APP_KEY:-}"
        client_key="${PTERODACTYL_CLIENT_KEY:-}"
        source="environment"
    else
        output_json '{
  "configured": false,
  "error": "no_config",
  "message": "No configuration found. Neither config file (~/.pterodactyl/config.json) nor environment variables (PTERODACTYL_PANEL_URL) are set.",
  "action_required": "Run the setup wizard: bash scripts/setup.sh"
}'
        exit 1
    fi
else
    source="config_file"
    
    # Check file permissions
    file_perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%Lp" "$CONFIG_FILE" 2>/dev/null)
    if [[ "$file_perms" != "600" ]]; then
        permission_warning="Config file permissions are ${file_perms}, recommended: 600"
    else
        permission_warning=""
    fi
    
    # Parse config
    if ! command -v jq &>/dev/null; then
        # Fallback: parse with grep/sed if jq not available
        panel_url=$(grep -o '"panel_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
        app_key=$(grep -o '"application_api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
        client_key=$(grep -o '"client_api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
    else
        panel_url=$(jq -r '.panel_url // ""' "$CONFIG_FILE")
        app_key=$(jq -r '.application_api_key // ""' "$CONFIG_FILE")
        client_key=$(jq -r '.client_api_key // ""' "$CONFIG_FILE")
    fi
fi

# ============================================================================
# Check 2: Validate required fields
# ============================================================================
errors=()

if [[ -z "$panel_url" ]]; then
    errors+=("panel_url is empty")
fi

if [[ -z "$app_key" && -z "$client_key" ]]; then
    errors+=("No API keys configured (need at least one of: application_api_key, client_api_key)")
fi

if [[ ${#errors[@]} -gt 0 ]]; then
    error_list=$(printf ', "%s"' "${errors[@]}")
    error_list="[${error_list:2}]"
    output_json "{
  \"configured\": false,
  \"error\": \"invalid_config\",
  \"errors\": ${error_list},
  \"message\": \"Configuration is incomplete.\",
  \"action_required\": \"Run the setup wizard: bash scripts/setup.sh\"
}"
    exit 1
fi

# ============================================================================
# Check 3: Validate key formats
# ============================================================================
warnings=()

has_app_api=false
has_client_api=false

if [[ -n "$app_key" ]]; then
    if [[ "$app_key" =~ ^ptla_ ]]; then
        has_app_api=true
    else
        warnings+=("Application API key does not start with 'ptla_' prefix")
    fi
fi

if [[ -n "$client_key" ]]; then
    if [[ "$client_key" =~ ^ptlc_ ]]; then
        has_client_api=true
    else
        warnings+=("Client API key does not start with 'ptlc_' prefix")
    fi
fi

if [[ -n "${permission_warning:-}" ]]; then
    warnings+=("$permission_warning")
fi

# ============================================================================
# Output final status
# ============================================================================
warning_json="[]"
if [[ ${#warnings[@]} -gt 0 ]]; then
    warning_list=$(printf ', "%s"' "${warnings[@]}")
    warning_json="[${warning_list:2}]"
fi

# Mask keys for display
masked_app_key=""
masked_client_key=""
if [[ -n "$app_key" ]]; then
    masked_app_key="ptla_...${app_key: -6}"
fi
if [[ -n "$client_key" ]]; then
    masked_client_key="ptlc_...${client_key: -6}"
fi

output_json "{
  \"configured\": true,
  \"source\": \"${source}\",
  \"panel_url\": \"${panel_url}\",
  \"has_application_api\": ${has_app_api},
  \"has_client_api\": ${has_client_api},
  \"application_key_masked\": \"${masked_app_key}\",
  \"client_key_masked\": \"${masked_client_key}\",
  \"warnings\": ${warning_json},
  \"message\": \"Configuration OK. Panel: ${panel_url}\"
}"

exit 0
