#!/usr/bin/env python3
# ============================================================================
# Pterodactyl Skill — Interactive Setup Wizard
# ============================================================================
import os
import json
import urllib.request
import urllib.error
import datetime

CONFIG_DIR = os.path.expanduser("~/.pterodactyl")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")

# Colors
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
CYAN = '\033[0;36m'
NC = '\033[0m'
BOLD = '\033[1m'

def print_banner():
    print(f"{CYAN}")
    print("  ╔═══════════════════════════════════════════════╗")
    print("  ║        🦖 Pterodactyl Setup Wizard          ║")
    print("  ╚═══════════════════════════════════════════════╝")
    print(f"{NC}")

def print_step(step, title):
    print(f"\n{BLUE}[{step}]{NC} {BOLD}{title}{NC}")

def print_success(msg):
    print(f"{GREEN}✓{NC} {msg}")

def print_warning(msg):
    print(f"{YELLOW}⚠{NC} {msg}")

def print_error(msg):
    print(f"{RED}✗{NC} {msg}")

def validate_url(url):
    url = url.strip().rstrip('/')
    if url.startswith("http://") or url.startswith("https://"):
        return url
    return None

def test_connection(url, key, endpoint):
    req_url = f"{url}{endpoint}"
    req = urllib.request.Request(req_url)
    req.add_header("Authorization", f"Bearer {key}")
    req.add_header("Accept", "Application/vnd.pterodactyl.v1+json")
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    try:
        urllib.request.urlopen(req, timeout=10)
        return True
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            print_error(f"Authentication failed (HTTP {e.code}). Check your API key.")
        else:
            print_error(f"Unexpected response (HTTP {e.code}).")
        return False
    except urllib.error.URLError:
        print_error("Could not connect to panel. Check the URL.")
        return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def main():
    print_banner()
    
    if os.path.exists(CONFIG_FILE):
        print_warning(f"Configuration already exists at: {CONFIG_FILE}")
        ans = input("Do you want to overwrite it? (y/N): ")
        if ans.lower() != 'y':
            print(f"\n{GREEN}Setup cancelled. Existing configuration preserved.{NC}")
            return

    # Step 1: Panel URL
    print_step("1/4", "Panel URL")
    print("Enter your Pterodactyl Panel URL (e.g., https://panel.example.com)\n")
    while True:
        panel_url = input("Panel URL: ").strip()
        validated = validate_url(panel_url)
        if validated:
            panel_url = validated
            print_success(f"URL accepted: {panel_url}")
            break
        print_error("Invalid URL. Must start with http:// or https://")

    # Step 2: Application API Key
    print_step("2/4", "Application API Key (Admin)")
    print(f"Generate an Application API key from:\n  {CYAN}{panel_url}/admin/api{NC}\n")
    print("The key should start with 'ptla_'")
    print("(Leave blank to skip if you only need client-level access)\n")
    while True:
        app_key = input("Application API Key: ").strip()
        if not app_key:
            print_warning("Skipped. Application API (admin) features will be unavailable.")
            break
        if app_key.startswith("ptla_"):
            print_success("Application API key accepted")
            break
        print_error("Invalid key format. Application keys start with 'ptla_'")

    # Step 3: Client API Key
    print_step("3/4", "Client API Key")
    print(f"Generate a Client API key from:\n  {CYAN}{panel_url}/account/api{NC}\n")
    print("The key should start with 'ptlc_'")
    print("(Leave blank to skip if you only need admin-level access)\n")
    while True:
        client_key = input("Client API Key: ").strip()
        if not client_key:
            print_warning("Skipped. Client API features will be unavailable.")
            break
        if client_key.startswith("ptlc_"):
            print_success("Client API key accepted")
            break
        print_error("Invalid key format. Client keys start with 'ptlc_'")

    if not app_key and not client_key:
        print_error("At least one API key (Application or Client) is required.")
        return

    # Step 4: Test Connection
    print_step("4/4", "Testing Connection")
    connection_ok = True

    if app_key:
        print("Testing Application API... ", end="", flush=True)
        if test_connection(panel_url, app_key, "/api/application/users?per_page=1"):
            print_success("Application API connected successfully!")
        else:
            connection_ok = False

    if client_key:
        print("Testing Client API... ", end="", flush=True)
        if test_connection(panel_url, client_key, "/api/client"):
            print_success("Client API connected successfully!")
        else:
            connection_ok = False

    if not connection_ok:
        ans = input("\nSome tests failed. Save configuration anyway? (y/N): ")
        if ans.lower() != 'y':
            print_error("Setup cancelled.")
            return

    # Save
    os.makedirs(CONFIG_DIR, exist_ok=True)
    os.chmod(CONFIG_DIR, 0o700)
    
    config_data = {
        "panel_url": panel_url,
        "application_api_key": app_key,
        "client_api_key": client_key,
        "created_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "version": "1.0"
    }
    
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config_data, f, indent=2)
    os.chmod(CONFIG_FILE, 0o600)

    print("\n" + GREEN + "╔═══════════════════════════════════════════════╗" + NC)
    print(GREEN + "║           ✓ Setup Complete!                   ║" + NC)
    print(GREEN + "╚═══════════════════════════════════════════════╝" + NC + "\n")
    print(f"Configuration saved to: {CYAN}{CONFIG_FILE}{NC}")
    print(f"Permissions set to:     {CYAN}600 (owner read/write only){NC}\n")
    print(f"{BOLD}The AI agent is ready to manage your Pterodactyl Panel! 🦖{NC}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nSetup cancelled.")
