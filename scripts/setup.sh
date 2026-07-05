#!/usr/bin/env bash
# ============================================================================
# Hermes Pterodactyl Skill — Interactive Setup Wizard
# ============================================================================
# Creates and configures the credential file for Pterodactyl API access.
# Supports both Application (admin) and Client API keys.
# ============================================================================

set -euo pipefail

CONFIG_DIR="${HOME}/.pterodactyl"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║     🦖 Hermes — Pterodactyl Setup Wizard     ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}[${1}]${NC} ${BOLD}${2}${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

validate_url() {
    local url="$1"
    # Remove trailing slash
    url="${url%/}"
    
    if [[ "$url" =~ ^https?:// ]]; then
        echo "$url"
        return 0
    else
        return 1
    fi
}

validate_app_key() {
    local key="$1"
    if [[ "$key" =~ ^ptla_ ]]; then
        return 0
    else
        return 1
    fi
}

validate_client_key() {
    local key="$1"
    if [[ "$key" =~ ^ptlc_ ]]; then
        return 0
    else
        return 1
    fi
}

test_connection() {
    local url="$1"
    local key="$2"
    local endpoint="$3"
    
    local response
    local http_code
    
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${key}" \
        -H "Accept: Application/vnd.pterodactyl.v1+json" \
        -H "Content-Type: application/json" \
        --connect-timeout 10 \
        "${url}${endpoint}" 2>/dev/null || echo "000")
    
    if [[ "$http_code" == "200" ]]; then
        return 0
    elif [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
        print_error "Authentication failed (HTTP ${http_code}). Check your API key."
        return 1
    elif [[ "$http_code" == "000" ]]; then
        print_error "Could not connect to panel. Check the URL."
        return 1
    else
        print_error "Unexpected response (HTTP ${http_code})."
        return 1
    fi
}

# ============================================================================
# Main Setup Flow
# ============================================================================

print_banner

# Check if config already exists
if [[ -f "$CONFIG_FILE" ]]; then
    print_warning "Configuration already exists at: ${CONFIG_FILE}"
    echo ""
    read -rp "Do you want to overwrite it? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo -e "\n${GREEN}Setup cancelled. Existing configuration preserved.${NC}"
        exit 0
    fi
fi

# Step 1: Panel URL
print_step "1/4" "Panel URL"
echo "Enter your Pterodactyl Panel URL (e.g., https://panel.example.com)"
echo ""

while true; do
    read -rp "Panel URL: " panel_url
    
    if validated_url=$(validate_url "$panel_url"); then
        panel_url="$validated_url"
        print_success "URL accepted: ${panel_url}"
        break
    else
        print_error "Invalid URL. Must start with http:// or https://"
    fi
done

# Step 2: Application API Key
print_step "2/4" "Application API Key (Admin)"
echo "Generate an Application API key from:"
echo -e "  ${CYAN}${panel_url}/admin/api${NC}"
echo ""
echo "The key should start with 'ptla_'"
echo "(Leave blank to skip if you only need client-level access)"
echo ""

app_key=""
while true; do
    read -rp "Application API Key: " app_key
    
    if [[ -z "$app_key" ]]; then
        print_warning "Skipped. Application API (admin) features will be unavailable."
        break
    elif validate_app_key "$app_key"; then
        print_success "Application API key accepted"
        break
    else
        print_error "Invalid key format. Application keys start with 'ptla_'"
    fi
done

# Step 3: Client API Key
print_step "3/4" "Client API Key"
echo "Generate a Client API key from:"
echo -e "  ${CYAN}${panel_url}/account/api${NC}"
echo ""
echo "The key should start with 'ptlc_'"
echo "(Leave blank to skip if you only need admin-level access)"
echo ""

client_key=""
while true; do
    read -rp "Client API Key: " client_key
    
    if [[ -z "$client_key" ]]; then
        print_warning "Skipped. Client API features will be unavailable."
        break
    elif validate_client_key "$client_key"; then
        print_success "Client API key accepted"
        break
    else
        print_error "Invalid key format. Client keys start with 'ptlc_'"
    fi
done

# Check that at least one key was provided
if [[ -z "$app_key" && -z "$client_key" ]]; then
    print_error "At least one API key (Application or Client) is required."
    exit 1
fi

# Step 4: Test Connection
print_step "4/4" "Testing Connection"

connection_ok=true

if [[ -n "$app_key" ]]; then
    echo -n "Testing Application API... "
    if test_connection "$panel_url" "$app_key" "/api/application/users?per_page=1"; then
        print_success "Application API connected successfully!"
    else
        connection_ok=false
    fi
fi

if [[ -n "$client_key" ]]; then
    echo -n "Testing Client API... "
    if test_connection "$panel_url" "$client_key" "/api/client"; then
        print_success "Client API connected successfully!"
    else
        connection_ok=false
    fi
fi

if [[ "$connection_ok" == false ]]; then
    echo ""
    read -rp "Some tests failed. Save configuration anyway? (y/N): " save_anyway
    if [[ ! "$save_anyway" =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled."
        exit 1
    fi
fi

# Save configuration
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" << EOF
{
  "panel_url": "${panel_url}",
  "application_api_key": "${app_key}",
  "client_api_key": "${client_key}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "version": "1.0"
}
EOF

chmod 600 "$CONFIG_FILE"
chmod 700 "$CONFIG_DIR"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✓ Setup Complete!                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Configuration saved to: ${CYAN}${CONFIG_FILE}${NC}"
echo -e "Permissions set to:     ${CYAN}600 (owner read/write only)${NC}"
echo ""
echo -e "${BOLD}Hermes is ready to manage your Pterodactyl Panel! 🦖${NC}"
