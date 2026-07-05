#!/usr/bin/env bash
# ============================================================================
# Hermes Pterodactyl Skill — API Request Helper
# ============================================================================
# A wrapper for making authenticated API requests to Pterodactyl Panel.
# Handles configuration loading, authentication headers, and error handling.
#
# Usage:
#   ./api_request.sh <METHOD> <ENDPOINT> [JSON_BODY]
#
# Examples:
#   ./api_request.sh GET /api/application/users
#   ./api_request.sh GET /api/client/servers/abc123/resources
#   ./api_request.sh POST /api/application/users '{"username":"test","email":"test@example.com","first_name":"Test","last_name":"User"}'
#   ./api_request.sh PATCH /api/application/users/1 '{"email":"new@example.com"}'
#   ./api_request.sh DELETE /api/application/users/1
#   ./api_request.sh POST /api/client/servers/abc123/power '{"signal":"start"}'
# ============================================================================

set -euo pipefail

CONFIG_DIR="${HOME}/.pterodactyl"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# ============================================================================
# Load Configuration
# ============================================================================
load_config() {
    if [[ -n "${PTERODACTYL_PANEL_URL:-}" ]]; then
        PANEL_URL="$PTERODACTYL_PANEL_URL"
        APP_KEY="${PTERODACTYL_APP_KEY:-}"
        CLIENT_KEY="${PTERODACTYL_CLIENT_KEY:-}"
        return 0
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo '{"error": "not_configured", "message": "No configuration found. Run: bash scripts/setup.sh"}' >&2
        exit 1
    fi
    
    if command -v jq &>/dev/null; then
        PANEL_URL=$(jq -r '.panel_url // ""' "$CONFIG_FILE")
        APP_KEY=$(jq -r '.application_api_key // ""' "$CONFIG_FILE")
        CLIENT_KEY=$(jq -r '.client_api_key // ""' "$CONFIG_FILE")
    else
        PANEL_URL=$(grep -o '"panel_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
        APP_KEY=$(grep -o '"application_api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
        CLIENT_KEY=$(grep -o '"client_api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)"$/\1/')
    fi
    
    if [[ -z "$PANEL_URL" ]]; then
        echo '{"error": "invalid_config", "message": "panel_url is not set in configuration"}' >&2
        exit 1
    fi
}

# ============================================================================
# Determine API Key based on endpoint
# ============================================================================
get_api_key() {
    local endpoint="$1"
    
    if [[ "$endpoint" =~ ^/api/application ]]; then
        if [[ -z "${APP_KEY:-}" ]]; then
            echo '{"error": "no_app_key", "message": "Application API key is required for /api/application/* endpoints"}' >&2
            exit 1
        fi
        echo "$APP_KEY"
    elif [[ "$endpoint" =~ ^/api/client ]]; then
        if [[ -z "${CLIENT_KEY:-}" ]]; then
            echo '{"error": "no_client_key", "message": "Client API key is required for /api/client/* endpoints"}' >&2
            exit 1
        fi
        echo "$CLIENT_KEY"
    else
        echo '{"error": "invalid_endpoint", "message": "Endpoint must start with /api/application or /api/client"}' >&2
        exit 1
    fi
}

# ============================================================================
# Make API Request
# ============================================================================
make_request() {
    local method="$1"
    local endpoint="$2"
    local body="${3:-}"
    
    local api_key
    api_key=$(get_api_key "$endpoint")
    
    local url="${PANEL_URL}${endpoint}"
    
    local curl_args=(
        -s
        -w "\n%{http_code}"
        -X "$method"
        -H "Authorization: Bearer ${api_key}"
        -H "Accept: Application/vnd.pterodactyl.v1+json"
        -H "Content-Type: application/json"
        --connect-timeout 15
        --max-time 60
    )
    
    if [[ -n "$body" && "$method" != "GET" && "$method" != "DELETE" ]]; then
        curl_args+=(-d "$body")
    fi
    
    curl_args+=("$url")
    
    local response
    response=$(curl "${curl_args[@]}" 2>/dev/null) || {
        echo '{"error": "connection_failed", "message": "Failed to connect to panel at '"${PANEL_URL}"'"}' >&2
        exit 1
    }
    
    # Split response body and HTTP status code
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body_response
    body_response=$(echo "$response" | sed '$d')
    
    # Handle different HTTP codes
    case "$http_code" in
        200|201|202)
            echo "$body_response"
            ;;
        204)
            echo '{"success": true, "message": "Operation completed successfully (no content)"}'
            ;;
        401)
            echo '{"error": "unauthorized", "http_code": 401, "message": "Invalid API key or insufficient permissions"}' >&2
            exit 1
            ;;
        403)
            echo '{"error": "forbidden", "http_code": 403, "message": "Access denied. Check API key permissions"}' >&2
            exit 1
            ;;
        404)
            echo '{"error": "not_found", "http_code": 404, "message": "Resource not found", "response": '"${body_response:-null}"'}' >&2
            exit 1
            ;;
        422)
            echo '{"error": "validation_error", "http_code": 422, "message": "Validation failed", "details": '"${body_response:-null}"'}' >&2
            exit 1
            ;;
        429)
            echo '{"error": "rate_limited", "http_code": 429, "message": "Rate limit exceeded. Wait before retrying."}' >&2
            exit 1
            ;;
        500)
            echo '{"error": "server_error", "http_code": 500, "message": "Internal server error on the panel"}' >&2
            exit 1
            ;;
        *)
            echo '{"error": "unexpected", "http_code": '"${http_code}"', "message": "Unexpected HTTP response", "response": '"${body_response:-null}"'}' >&2
            exit 1
            ;;
    esac
}

# ============================================================================
# Main
# ============================================================================

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <METHOD> <ENDPOINT> [JSON_BODY]"
    echo ""
    echo "Methods: GET, POST, PUT, PATCH, DELETE"
    echo ""
    echo "Examples:"
    echo "  $0 GET /api/application/users"
    echo "  $0 POST /api/application/users '{\"username\":\"test\",\"email\":\"test@test.com\",\"first_name\":\"Test\",\"last_name\":\"User\"}'"
    echo "  $0 POST /api/client/servers/abc123/power '{\"signal\":\"start\"}'"
    exit 1
fi

METHOD="${1^^}"  # Uppercase
ENDPOINT="$2"
BODY="${3:-}"

load_config
make_request "$METHOD" "$ENDPOINT" "$BODY"
