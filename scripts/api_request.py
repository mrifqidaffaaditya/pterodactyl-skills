#!/usr/bin/env python3
# ============================================================================
# Pterodactyl Skill — API Request Helper
# ============================================================================
import os
import sys
import json
import urllib.request
import urllib.error

CONFIG_DIR = os.path.expanduser("~/.pterodactyl")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

def load_config():
    if os.environ.get("PTERODACTYL_PANEL_URL"):
        return {
            "panel_url": os.environ.get("PTERODACTYL_PANEL_URL"),
            "app_key": os.environ.get("PTERODACTYL_APP_KEY", ""),
            "client_key": os.environ.get("PTERODACTYL_CLIENT_KEY", "")
        }
    
    if not os.path.exists(CONFIG_FILE):
        print(json.dumps({"error": "not_configured", "message": "No configuration found. Run: python3 scripts/setup.py"}), file=sys.stderr)
        sys.exit(1)
        
    try:
        with open(CONFIG_FILE, 'r') as f:
            data = json.load(f)
            return {
                "panel_url": data.get("panel_url", ""),
                "app_key": data.get("application_api_key", ""),
                "client_key": data.get("client_api_key", "")
            }
    except Exception as e:
        print(json.dumps({"error": "config_error", "message": f"Failed to read config: {str(e)}"}), file=sys.stderr)
        sys.exit(1)

def get_api_key(endpoint, config):
    if endpoint.startswith("/api/application"):
        if not config["app_key"]:
            print(json.dumps({"error": "no_app_key", "message": "Application API key is required for /api/application/* endpoints"}), file=sys.stderr)
            sys.exit(1)
        return config["app_key"]
    elif endpoint.startswith("/api/client"):
        if not config["client_key"]:
            print(json.dumps({"error": "no_client_key", "message": "Client API key is required for /api/client/* endpoints"}), file=sys.stderr)
            sys.exit(1)
        return config["client_key"]
    else:
        print(json.dumps({"error": "invalid_endpoint", "message": "Endpoint must start with /api/application or /api/client"}), file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 api_request.py <METHOD> <ENDPOINT> [JSON_BODY]")
        print("\nExamples:")
        print("  python3 api_request.py GET /api/application/users")
        print("  python3 api_request.py POST /api/client/servers/abc123/power '{\"signal\":\"start\"}'")
        sys.exit(1)

    method = sys.argv[1].upper()
    endpoint = sys.argv[2]
    body = sys.argv[3] if len(sys.argv) > 3 else None

    config = load_config()
    if not config["panel_url"]:
        print(json.dumps({"error": "invalid_config", "message": "panel_url is not set in configuration"}), file=sys.stderr)
        sys.exit(1)

    api_key = get_api_key(endpoint, config)
    url = f"{config['panel_url'].rstrip('/')}{endpoint}"

    req = urllib.request.Request(url, method=method)
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Accept", "Application/vnd.pterodactyl.v1+json")
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    if body and method not in ("GET", "DELETE"):
        req.data = body.encode('utf-8')

    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            res_body = response.read().decode('utf-8')
            if not res_body and response.status == 204:
                print(json.dumps({"success": True, "message": "Operation completed successfully (no content)"}))
            else:
                print(res_body)
    except urllib.error.HTTPError as e:
        res_body = e.read().decode('utf-8') if e.fp else "null"
        try:
            res_json = json.loads(res_body)
        except:
            res_json = res_body
        
        err_map = {
            401: ("unauthorized", "Invalid API key or insufficient permissions"),
            403: ("forbidden", "Access denied. Check API key permissions"),
            404: ("not_found", "Resource not found"),
            422: ("validation_error", "Validation failed"),
            429: ("rate_limited", "Rate limit exceeded. Wait before retrying."),
            500: ("server_error", "Internal server error on the panel")
        }
        
        err_code, err_msg = err_map.get(e.code, ("unexpected", "Unexpected HTTP response"))
        
        out = {
            "error": err_code,
            "http_code": e.code,
            "message": err_msg,
            "response": res_json
        }
        print(json.dumps(out), file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(json.dumps({"error": "connection_failed", "message": f"Failed to connect to panel at {config['panel_url']}"}), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"error": "internal_error", "message": str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
