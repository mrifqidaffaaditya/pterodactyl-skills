#!/usr/bin/env python3
# ============================================================================
# Hermes Pterodactyl Skill — Configuration Validator
# ============================================================================
import os
import json
import stat
import sys

CONFIG_DIR = os.path.expanduser("~/.pterodactyl")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

def output_json(data):
    print(json.dumps(data, indent=2))
    sys.exit(0 if data.get("configured") else 1)

def main():
    source = None
    panel_url = ""
    app_key = ""
    client_key = ""
    permission_warning = ""

    if not os.path.exists(CONFIG_FILE):
        if os.environ.get("PTERODACTYL_PANEL_URL"):
            panel_url = os.environ.get("PTERODACTYL_PANEL_URL")
            app_key = os.environ.get("PTERODACTYL_APP_KEY", "")
            client_key = os.environ.get("PTERODACTYL_CLIENT_KEY", "")
            source = "environment"
        else:
            output_json({
                "configured": False,
                "error": "no_config",
                "message": "No configuration found. Neither config file (~/.pterodactyl/config.json) nor environment variables (PTERODACTYL_PANEL_URL) are set.",
                "action_required": "Run the setup wizard: python3 scripts/setup.py"
            })
    else:
        source = "config_file"
        try:
            mode = os.stat(CONFIG_FILE).st_mode
            if stat.S_IMODE(mode) != 0o600:
                permission_warning = f"Config file permissions are {oct(stat.S_IMODE(mode))}, recommended: 600"
            
            with open(CONFIG_FILE, 'r') as f:
                data = json.load(f)
                panel_url = data.get("panel_url", "")
                app_key = data.get("application_api_key", "")
                client_key = data.get("client_api_key", "")
        except Exception as e:
            output_json({
                "configured": False,
                "error": "parse_error",
                "message": f"Failed to parse config file: {str(e)}",
                "action_required": "Fix or recreate config file."
            })

    errors = []
    if not panel_url:
        errors.append("panel_url is empty")
    if not app_key and not client_key:
        errors.append("No API keys configured (need at least one of: application_api_key, client_api_key)")

    if errors:
        output_json({
            "configured": False,
            "error": "invalid_config",
            "errors": errors,
            "message": "Configuration is incomplete.",
            "action_required": "Run the setup wizard: python3 scripts/setup.py"
        })

    warnings = []
    has_app_api = False
    has_client_api = False

    if app_key:
        if app_key.startswith("ptla_"):
            has_app_api = True
        else:
            warnings.append("Application API key does not start with 'ptla_' prefix")
    
    if client_key:
        if client_key.startswith("ptlc_"):
            has_client_api = True
        else:
            warnings.append("Client API key does not start with 'ptlc_' prefix")

    if permission_warning:
        warnings.append(permission_warning)

    masked_app_key = f"ptla_...{app_key[-6:]}" if app_key else ""
    masked_client_key = f"ptlc_...{client_key[-6:]}" if client_key else ""

    output_json({
        "configured": True,
        "source": source,
        "panel_url": panel_url,
        "has_application_api": has_app_api,
        "has_client_api": has_client_api,
        "application_key_masked": masked_app_key,
        "client_key_masked": masked_client_key,
        "warnings": warnings,
        "message": f"Configuration OK. Panel: {panel_url}"
    })

if __name__ == "__main__":
    main()
