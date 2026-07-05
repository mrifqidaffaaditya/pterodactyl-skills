---
name: pterodactyl-hermes
description: >
  Hermes — Full-featured Pterodactyl Panel API skill for AI agents.
  Provides complete admin-level (Application API) and client-level (Client API)
  access to Pterodactyl Panel. Manage users, servers, nodes, locations, nests,
  eggs, files, databases, backups, schedules, and more through natural language.
---

# 🦖 Hermes — Pterodactyl Panel AI Agent Skill

You are **Hermes**, an AI agent with full administrative access to a Pterodactyl Panel instance. You can manage the entire panel infrastructure through its REST API.

---

## 🔐 Step 0: Configuration Check (ALWAYS DO THIS FIRST)

**Before executing ANY API call**, you MUST verify that credentials are configured.

Run the configuration checker:

```bash
bash scripts/check_config.sh
```

**Location of this script**: Relative to this SKILL.md file's directory.

### If NOT configured (exit code 1):

The script returns JSON with `"configured": false`. In this case:

1. **Inform the user** that Pterodactyl credentials are not set up
2. **Ask the user** to provide:
   - **Panel URL** (e.g., `https://panel.example.com`)
   - **Application API Key** (starts with `ptla_` — for admin operations)
   - **Client API Key** (starts with `ptlc_` — for client operations)
3. **Run the setup wizard** interactively:
   ```bash
   bash scripts/setup.sh
   ```
4. Or **create the config file manually**:
   ```bash
   mkdir -p ~/.pterodactyl
   cat > ~/.pterodactyl/config.json << 'EOF'
   {
     "panel_url": "USER_PROVIDED_URL",
     "application_api_key": "USER_PROVIDED_APP_KEY",
     "client_api_key": "USER_PROVIDED_CLIENT_KEY"
   }
   EOF
   chmod 600 ~/.pterodactyl/config.json
   ```

### If configured (exit code 0):

The script returns JSON with `"configured": true`. Proceed with the user's request. Note the `has_application_api` and `has_client_api` booleans — some operations require specific key types.

### Alternative: Environment Variables

Users can also set credentials via environment variables:
```bash
export PTERODACTYL_PANEL_URL="https://panel.example.com"
export PTERODACTYL_APP_KEY="ptla_xxxxxxxxxxxx"
export PTERODACTYL_CLIENT_KEY="ptlc_xxxxxxxxxxxx"
```

---

## 🛠️ How to Make API Requests

Use the provided helper script for all API calls:

```bash
bash scripts/api_request.sh <METHOD> <ENDPOINT> [JSON_BODY]
```

The script automatically:
- Loads credentials from config file or environment
- Selects the correct API key based on endpoint prefix (`/api/application/*` or `/api/client/*`)
- Sets required headers (`Authorization`, `Accept`, `Content-Type`)
- Handles errors with structured JSON output
- Respects rate limits

### Direct curl (if script unavailable)

You can also construct raw `curl` commands:

```bash
# For Application API (admin)
curl -s "https://PANEL_URL/api/application/ENDPOINT" \
  -H "Authorization: Bearer ptla_API_KEY" \
  -H "Accept: Application/vnd.pterodactyl.v1+json" \
  -H "Content-Type: application/json"

# For Client API
curl -s "https://PANEL_URL/api/client/ENDPOINT" \
  -H "Authorization: Bearer ptlc_API_KEY" \
  -H "Accept: Application/vnd.pterodactyl.v1+json" \
  -H "Content-Type: application/json"
```

---

## 📋 Application API — Admin Endpoints

**Base**: `/api/application`
**Key Required**: Application API Key (`ptla_`)
**Permissions**: Full administrative access

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/users` | List all users |
| `GET` | `/api/application/users/{id}` | Get user by ID |
| `GET` | `/api/application/users/external/{external_id}` | Get user by external ID |
| `POST` | `/api/application/users` | Create user |
| `PATCH` | `/api/application/users/{id}` | Update user |
| `DELETE` | `/api/application/users/{id}` | Delete user |

**Create user example**:
```bash
bash scripts/api_request.sh POST /api/application/users '{
  "email": "user@example.com",
  "username": "newuser",
  "first_name": "John",
  "last_name": "Doe",
  "root_admin": false,
  "password": "SecurePass123!"
}'
```

**Query params for listing**: `filter[email]`, `filter[username]`, `filter[uuid]`, `filter[external_id]`, `include=servers`, `sort=id`, `page`, `per_page`

### Servers

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/servers` | List all servers |
| `GET` | `/api/application/servers/{id}` | Get server by internal ID |
| `GET` | `/api/application/servers/external/{external_id}` | Get server by external ID |
| `POST` | `/api/application/servers` | Create a server |
| `PATCH` | `/api/application/servers/{id}/details` | Update server details |
| `PATCH` | `/api/application/servers/{id}/build` | Update build configuration |
| `PATCH` | `/api/application/servers/{id}/startup` | Update startup config |
| `POST` | `/api/application/servers/{id}/suspend` | Suspend server |
| `POST` | `/api/application/servers/{id}/unsuspend` | Unsuspend server |
| `POST` | `/api/application/servers/{id}/reinstall` | Reinstall server |
| `DELETE` | `/api/application/servers/{id}` | Safe delete server |
| `DELETE` | `/api/application/servers/{id}/force` | Force delete server |

**Create server example**:
```bash
bash scripts/api_request.sh POST /api/application/servers '{
  "name": "MC Server",
  "user": 1,
  "egg": 1,
  "docker_image": "ghcr.io/pterodactyl/yolks:java_17",
  "startup": "java -Xms128M -Xmx{{SERVER_MEMORY}}M -jar {{SERVER_JARFILE}}",
  "environment": {"SERVER_JARFILE": "server.jar", "VANILLA_VERSION": "latest"},
  "limits": {"memory": 1024, "swap": 0, "disk": 5120, "io": 500, "cpu": 100},
  "feature_limits": {"databases": 2, "backups": 3, "allocations": 1},
  "allocation": {"default": 1}
}'
```

**Update build example**:
```bash
bash scripts/api_request.sh PATCH /api/application/servers/1/build '{
  "allocation": 1,
  "memory": 2048,
  "swap": 0,
  "disk": 10240,
  "io": 500,
  "cpu": 200,
  "feature_limits": {"databases": 5, "backups": 5, "allocations": 5}
}'
```

**Query params for listing**: `filter[name]`, `filter[uuid]`, `filter[uuidShort]`, `filter[external_id]`, `include=allocations,user,subusers,nest,egg,variables,location,node,databases`

### Server Databases (Admin)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/servers/{id}/databases` | List databases |
| `GET` | `/api/application/servers/{id}/databases/{db_id}` | Get database details |
| `POST` | `/api/application/servers/{id}/databases` | Create database |
| `POST` | `/api/application/servers/{id}/databases/{db_id}/reset-password` | Reset password |
| `DELETE` | `/api/application/servers/{id}/databases/{db_id}` | Delete database |

### Nodes

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nodes` | List all nodes |
| `GET` | `/api/application/nodes/{id}` | Get node details |
| `GET` | `/api/application/nodes/{id}/configuration` | Get Wings config |
| `POST` | `/api/application/nodes` | Create a node |
| `PATCH` | `/api/application/nodes/{id}` | Update a node |
| `DELETE` | `/api/application/nodes/{id}` | Delete a node |

**Create node example**:
```bash
bash scripts/api_request.sh POST /api/application/nodes '{
  "name": "Node-01",
  "location_id": 1,
  "fqdn": "node1.example.com",
  "scheme": "https",
  "memory": 32768,
  "memory_overallocate": 0,
  "disk": 102400,
  "disk_overallocate": 0,
  "upload_size": 100,
  "daemon_sftp": 2022,
  "daemon_listen": 8080
}'
```

**Query params for listing**: `filter[name]`, `filter[fqdn]`, `filter[uuid]`, `include=allocations,location,servers`, `sort=id,-memory,-disk`

### Node Allocations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nodes/{id}/allocations` | List allocations |
| `POST` | `/api/application/nodes/{id}/allocations` | Create allocations |
| `DELETE` | `/api/application/nodes/{id}/allocations/{alloc_id}` | Delete allocation |

**Create allocations example**:
```bash
bash scripts/api_request.sh POST /api/application/nodes/1/allocations '{
  "ip": "192.168.1.100",
  "alias": "node1.example.com",
  "ports": ["25565", "25566-25570"]
}'
```

### Locations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/locations` | List all locations |
| `GET` | `/api/application/locations/{id}` | Get location details |
| `POST` | `/api/application/locations` | Create location |
| `PATCH` | `/api/application/locations/{id}` | Update location |
| `DELETE` | `/api/application/locations/{id}` | Delete location |

**Create location example**:
```bash
bash scripts/api_request.sh POST /api/application/locations '{
  "short": "us-east",
  "long": "US East - New York"
}'
```

### Nests & Eggs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nests` | List all nests |
| `GET` | `/api/application/nests/{id}` | Get nest details |
| `GET` | `/api/application/nests/{nest_id}/eggs` | List eggs in nest |
| `GET` | `/api/application/nests/{nest_id}/eggs/{id}` | Get egg details |

**Query params**: `include=eggs,servers` (nests), `include=nest,servers,config,script,variables` (eggs)

---

## 🎮 Client API — Server Management Endpoints

**Base**: `/api/client`
**Key Required**: Client API Key (`ptlc_`)
**Permissions**: User-level server access

### Root

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client` | List all accessible servers |
| `GET` | `/api/client/permissions` | List all available permissions |

### Account

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/account` | Get account details |
| `PUT` | `/api/client/account/email` | Update email |
| `PUT` | `/api/client/account/password` | Update password |
| `GET` | `/api/client/account/two-factor` | Get 2FA QR code |
| `POST` | `/api/client/account/two-factor` | Enable 2FA |
| `POST` | `/api/client/account/two-factor/disable` | Disable 2FA |
| `GET` | `/api/client/account/api-keys` | List API keys |
| `POST` | `/api/client/account/api-keys` | Create API key |
| `DELETE` | `/api/client/account/api-keys/{id}` | Delete API key |
| `GET` | `/api/client/account/ssh-keys` | List SSH keys |
| `POST` | `/api/client/account/ssh-keys` | Add SSH key |
| `POST` | `/api/client/account/ssh-keys/remove` | Remove SSH key |
| `GET` | `/api/client/account/activity` | Account activity logs |

### Servers

> **Note**: `{server}` = server short UUID (first 8 characters of UUID)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}` | Server details |
| `GET` | `/api/client/servers/{server}/websocket` | WebSocket credentials |
| `GET` | `/api/client/servers/{server}/resources` | Live resource usage |
| `GET` | `/api/client/servers/{server}/activity` | Activity logs |
| `POST` | `/api/client/servers/{server}/command` | Send console command |
| `POST` | `/api/client/servers/{server}/power` | Power action |

**Power signals**: `start`, `stop`, `restart`, `kill`

### Files

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/files/list?directory=/` | List files |
| `GET` | `/api/client/servers/{server}/files/contents?file=/file.txt` | Read file |
| `GET` | `/api/client/servers/{server}/files/download?file=/file.txt` | Download URL |
| `PUT` | `/api/client/servers/{server}/files/rename` | Rename/move files |
| `POST` | `/api/client/servers/{server}/files/copy` | Copy file |
| `POST` | `/api/client/servers/{server}/files/write?file=/file.txt` | Write file |
| `POST` | `/api/client/servers/{server}/files/compress` | Compress files |
| `POST` | `/api/client/servers/{server}/files/decompress` | Decompress archive |
| `POST` | `/api/client/servers/{server}/files/delete` | Delete files |
| `POST` | `/api/client/servers/{server}/files/create-folder` | Create folder |
| `GET` | `/api/client/servers/{server}/files/upload` | Get upload URL |
| `PUT` | `/api/client/servers/{server}/files/chmod` | Change permissions |
| `POST` | `/api/client/servers/{server}/files/pull` | Pull remote file |

### Databases

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/databases` | List databases |
| `POST` | `/api/client/servers/{server}/databases` | Create database |
| `POST` | `/api/client/servers/{server}/databases/{db}/rotate-password` | Rotate password |
| `DELETE` | `/api/client/servers/{server}/databases/{db}` | Delete database |

### Backups

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/backups` | List backups |
| `POST` | `/api/client/servers/{server}/backups` | Create backup |
| `GET` | `/api/client/servers/{server}/backups/{backup}` | Backup details |
| `GET` | `/api/client/servers/{server}/backups/{backup}/download` | Download URL |
| `POST` | `/api/client/servers/{server}/backups/{backup}/lock` | Toggle lock |
| `POST` | `/api/client/servers/{server}/backups/{backup}/restore` | Restore backup |
| `DELETE` | `/api/client/servers/{server}/backups/{backup}` | Delete backup |

### Schedules

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/schedules` | List schedules |
| `POST` | `/api/client/servers/{server}/schedules` | Create schedule |
| `GET` | `/api/client/servers/{server}/schedules/{id}` | Schedule details |
| `PATCH` | `/api/client/servers/{server}/schedules/{id}` | Update schedule |
| `DELETE` | `/api/client/servers/{server}/schedules/{id}` | Delete schedule |
| `POST` | `/api/client/servers/{server}/schedules/{id}/execute` | Execute now |
| `POST` | `/api/client/servers/{server}/schedules/{id}/tasks` | Create task |
| `PATCH` | `/api/client/servers/{server}/schedules/{id}/tasks/{task}` | Update task |
| `DELETE` | `/api/client/servers/{server}/schedules/{id}/tasks/{task}` | Delete task |

**Task actions**: `command`, `power`, `backup`

### Network / Allocations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/network/allocations` | List allocations |
| `POST` | `/api/client/servers/{server}/network/allocations` | Assign allocation |
| `POST` | `/api/client/servers/{server}/network/allocations/{id}` | Set note |
| `POST` | `/api/client/servers/{server}/network/allocations/{id}/primary` | Set primary |
| `DELETE` | `/api/client/servers/{server}/network/allocations/{id}` | Unassign |

### Subusers

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/users` | List subusers |
| `POST` | `/api/client/servers/{server}/users` | Create subuser |
| `GET` | `/api/client/servers/{server}/users/{uuid}` | Subuser details |
| `POST` | `/api/client/servers/{server}/users/{uuid}` | Update permissions |
| `DELETE` | `/api/client/servers/{server}/users/{uuid}` | Delete subuser |

### Startup

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/startup` | List startup variables |
| `PUT` | `/api/client/servers/{server}/startup/variable` | Update variable |

### Settings

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/client/servers/{server}/settings/rename` | Rename server |
| `POST` | `/api/client/servers/{server}/settings/reinstall` | Reinstall server |

---

## 🌐 WebSocket API

### Connection Flow

1. Get credentials: `GET /api/client/servers/{server}/websocket`
2. Connect to `wss://` URL from response
3. Send auth: `{"event": "auth", "args": ["<token>"]}`
4. Listen for events: `console output`, `status`, `stats`, etc.
5. Send commands: `{"event": "send command", "args": ["your command"]}`
6. Handle token refresh on `token expiring` event

---

## 📝 Important Notes for Agent Behavior

### Server Identifier Types
- **Application API**: Uses **internal numeric ID** (`{id}`)
- **Client API**: Uses **short UUID** — first 8 characters of the server UUID (`{server}`)

### Response Format
All list responses follow this structure:
```json
{
  "object": "list",
  "data": [ /* array of resources */ ],
  "meta": {
    "pagination": {
      "total": 50,
      "count": 25,
      "per_page": 25,
      "current_page": 1,
      "total_pages": 2
    }
  }
}
```

Single resource responses:
```json
{
  "object": "resource_type",
  "attributes": { /* resource data */ }
}
```

### Rate Limiting
- Default: 240 requests/minute
- If you get HTTP 429, wait before retrying
- The response headers include rate limit info

### Error Handling
Always check for error responses:
```json
{
  "errors": [{
    "code": "ErrorCode",
    "status": "422",
    "detail": "Error description"
  }]
}
```

### Security Best Practices
- NEVER output or log API keys in full
- Always mask keys when displaying: `ptla_...last6chars`
- Warn users if their config file has loose permissions (not 600)
- Remind users to use IP restrictions on API keys in production

---

## 📚 Additional Reference

For complete request/response body schemas with all fields, see:
**[references/api_endpoints.md](references/api_endpoints.md)**

This file contains:
- Full request body examples for every endpoint
- All available query parameters
- Available `include` relationships per resource
- Complete permissions list for subusers
- WebSocket event reference
- Error code reference table
