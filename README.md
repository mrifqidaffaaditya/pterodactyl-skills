# 🦖 Hermes — Pterodactyl Panel AI Agent Skill

<p align="center">
  <img src="https://pterodactyl.io/logos/pterry.svg" alt="Pterodactyl" width="120"/>
</p>

<p align="center">
  <strong>Full-featured Pterodactyl Panel API skill for AI coding agents</strong><br>
  Admin-level API control • Complete endpoint documentation • Secure credential management
</p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#features">Features</a> •
  <a href="#api-coverage">API Coverage</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#usage">Usage</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## Overview

**Hermes** is an AI agent skill that provides full administrative API access to [Pterodactyl Panel](https://pterodactyl.io/) — the open-source game server management platform. Named after the Greek messenger god, Hermes acts as the bridge between your AI assistant and your Pterodactyl Panel, enabling complete server infrastructure management through natural language.

## Features

- 🔐 **Secure Credential Management** — Encrypted config storage with setup validation
- 🛡️ **Full Admin API** — Complete Application API (admin-level) access
- 🎮 **Client API** — Full server management from the user perspective
- 📖 **Complete Documentation** — Every endpoint documented with parameters and examples
- ⚡ **Ready-to-use Scripts** — Pre-built `curl`-based API wrapper scripts
- 🔍 **Auto-setup Detection** — Automatically checks if credentials are configured
- 🌐 **WebSocket Support** — Real-time console access documentation

## API Coverage

### Application API (Admin Level)
| Resource | Endpoints | Operations |
|----------|-----------|------------|
| **Users** | 6 | List, Get, Get by External ID, Create, Update, Delete |
| **Servers** | 10 | List, Get, Get by External ID, Create, Update Details, Update Build, Update Startup, Suspend, Unsuspend, Reinstall, Delete, Force Delete |
| **Nodes** | 9 | List, Get, Get Configuration, Create, Update, Delete, List Allocations, Create Allocations, Delete Allocation |
| **Locations** | 5 | List, Get, Create, Update, Delete |
| **Nests** | 2 | List, Get Details |
| **Eggs** | 2 | List per Nest, Get Details |
| **Databases** | 3 | List per Server, Create, Delete |

### Client API (Server Level)
| Resource | Endpoints | Operations |
|----------|-----------|------------|
| **Account** | 8 | Details, Update Email, Update Password, 2FA Setup/Enable/Disable, API Keys, SSH Keys |
| **Servers** | 6 | List, Details, Resources, WebSocket, Send Command, Power Actions |
| **Files** | 12 | List, Read, Download URL, Rename, Copy, Write, Compress, Decompress, Delete, Create Folder, Upload, Pull Remote |
| **Databases** | 4 | List, Create, Rotate Password, Delete |
| **Backups** | 5 | List, Create, Details, Download, Delete, Restore |
| **Schedules** | 7 | List, Create, Details, Update, Delete, Create Task, Delete Task |
| **Network** | 4 | List, Assign, Set Note/Primary, Delete |
| **Subusers** | 4 | List, Create, Update, Delete |
| **Startup** | 2 | List Variables, Update Variable |
| **Settings** | 2 | Rename, Reinstall |

## Installation

### For Antigravity / Gemini CLI

```bash
# Clone into your skills directory
git clone https://github.com/YOUR_USERNAME/pterodactyl-skills.git ~/.gemini/skills/pterodactyl-hermes

# Or symlink if developing locally
ln -s /path/to/pterodactyl-skills ~/.gemini/skills/pterodactyl-hermes
```

### For Other AI Agent Frameworks

Copy the `SKILL.md` file and `scripts/` directory into your agent's skill/plugin directory following your framework's conventions.

## Configuration

### First-Time Setup

When Hermes is first activated, it will detect that credentials are not configured and guide you through setup:

1. **Panel URL** — Your Pterodactyl Panel URL (e.g., `https://panel.example.com`)
2. **Application API Key** — Admin API key (prefix: `ptla_`)
3. **Client API Key** — Client API key (prefix: `ptlc_`)

### Manual Setup

Create the config file at `~/.pterodactyl/config.json`:

```json
{
  "panel_url": "https://panel.example.com",
  "application_api_key": "ptla_xxxxxxxxxxxxxxxxxxxx",
  "client_api_key": "ptlc_xxxxxxxxxxxxxxxxxxxx"
}
```

Then set secure permissions:

```bash
chmod 600 ~/.pterodactyl/config.json
```

### Environment Variables (Alternative)

```bash
export PTERODACTYL_PANEL_URL="https://panel.example.com"
export PTERODACTYL_APP_KEY="ptla_xxxxxxxxxxxxxxxxxxxx"
export PTERODACTYL_CLIENT_KEY="ptlc_xxxxxxxxxxxxxxxxxxxx"
```

## Usage

Once installed, simply ask your AI agent to perform Pterodactyl operations:

```
"List all servers on the panel"
"Create a new Minecraft server with 4GB RAM"
"Show me all users"
"Suspend server ID 5"
"Create a backup for server abc123"
"Add a new node in US-East location"
```

## Security Notes

- ⚠️ **Never commit** your `config.json` with real API keys
- 🔒 Config files are stored with `600` permissions (owner-only read/write)
- 🔑 Application API keys grant **full admin access** — use with caution
- 🌐 Use IP restrictions on your API keys when possible
- 🔄 Rotate API keys regularly in production

## Project Structure

```
pterodactyl-skills/
├── SKILL.md                    # Main skill instructions (required)
├── README.md                   # This file
├── LICENSE                     # MIT License
├── .gitignore                  # Git ignore rules
├── scripts/
│   ├── setup.sh                # Interactive setup wizard
│   ├── check_config.sh         # Configuration validator
│   └── api_request.sh          # Core API request helper
└── references/
    └── api_endpoints.md        # Complete API endpoint reference
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Pterodactyl Panel](https://pterodactyl.io/) — The amazing open-source game server management platform
- [NETVPX API Documentation](https://pterodactyl-api-docs.netvpx.com/) — Community-maintained API reference
- [Pterodactyl GitHub](https://github.com/pterodactyl/panel) — Official source code

---

<p align="center">
  Made with ❤️ for the Pterodactyl community
</p>
