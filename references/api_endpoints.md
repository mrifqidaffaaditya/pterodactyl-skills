# 📖 Pterodactyl Panel API v1 — Complete Endpoint Reference

> **Source**: Based on [Pterodactyl Panel v1.x](https://github.com/pterodactyl/panel) source code and [NETVPX community documentation](https://pterodactyl-api-docs.netvpx.com/).
> **Last Updated**: 2025-12-27

---

## Table of Contents

- [Authentication](#authentication)
- [Rate Limiting](#rate-limiting)
- [Application API (Admin)](#application-api-admin)
  - [Users](#users)
  - [Servers](#servers)
  - [Server Databases](#server-databases-admin)
  - [Nodes](#nodes)
  - [Node Allocations](#node-allocations)
  - [Locations](#locations)
  - [Nests](#nests)
  - [Eggs](#eggs)
- [Client API](#client-api)
  - [Account](#account)
  - [Servers (Client)](#servers-client)
  - [Files](#files)
  - [Databases (Client)](#databases-client)
  - [Backups](#backups)
  - [Schedules](#schedules)
  - [Schedule Tasks](#schedule-tasks)
  - [Network / Allocations](#network--allocations)
  - [Subusers](#subusers)
  - [Startup](#startup)
  - [Settings](#settings)
- [WebSocket API](#websocket-api)
- [Common Query Parameters](#common-query-parameters)
- [Error Codes](#error-codes)

---

## Authentication

All requests require a Bearer token in the `Authorization` header:

```
Authorization: Bearer <API_KEY>
Accept: Application/vnd.pterodactyl.v1+json
Content-Type: application/json
```

| Key Type | Prefix | Generated From | Scope |
|----------|--------|----------------|-------|
| Application API | `ptla_` | Admin Panel → Application API | Full admin access |
| Client API | `ptlc_` | Account Settings → API Credentials | User-level server access |

---

## Rate Limiting

- **Default**: 240 requests per minute per API key
- **Burst**: Up to 10 requests per second
- **Headers in response**:
  - `X-RateLimit-Limit` — Maximum requests per window
  - `X-RateLimit-Remaining` — Remaining requests
  - `X-RateLimit-Reset` — Unix timestamp when limit resets

---

## Application API (Admin)

**Base URL**: `{panel_url}/api/application`

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/users` | List all users with pagination |
| `GET` | `/api/application/users/{id}` | Get specific user details |
| `GET` | `/api/application/users/external/{external_id}` | Get user by external ID |
| `POST` | `/api/application/users` | Create a new user |
| `PATCH` | `/api/application/users/{id}` | Update an existing user |
| `DELETE` | `/api/application/users/{id}` | Delete a user |

**List Users — Query Parameters**:
- `filter[email]` — Filter by email address
- `filter[uuid]` — Filter by UUID
- `filter[username]` — Filter by username
- `filter[external_id]` — Filter by external ID
- `include` — Comma-separated: `servers`
- `sort` — Sort field (prefix `-` for descending): `id`, `-id`

**Create User — Request Body**:
```json
{
  "email": "user@example.com",
  "username": "example_user",
  "first_name": "John",
  "last_name": "Doe",
  "language": "en",
  "root_admin": false,
  "password": "securePassword123",
  "external_id": "ext-123"
}
```

**Update User — Request Body** (all fields required):
```json
{
  "email": "user@example.com",
  "username": "example_user",
  "first_name": "John",
  "last_name": "Doe",
  "language": "en",
  "root_admin": false,
  "password": "newPassword123",
  "external_id": "ext-123"
}
```

---

### Servers

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/servers` | List all servers |
| `GET` | `/api/application/servers/{id}` | Get server details by internal ID |
| `GET` | `/api/application/servers/external/{external_id}` | Get server by external ID |
| `POST` | `/api/application/servers` | Create a new server |
| `PATCH` | `/api/application/servers/{id}/details` | Update server details |
| `PATCH` | `/api/application/servers/{id}/build` | Update server build config |
| `PATCH` | `/api/application/servers/{id}/startup` | Update server startup config |
| `POST` | `/api/application/servers/{id}/suspend` | Suspend a server |
| `POST` | `/api/application/servers/{id}/unsuspend` | Unsuspend a server |
| `POST` | `/api/application/servers/{id}/reinstall` | Reinstall a server |
| `DELETE` | `/api/application/servers/{id}` | Delete a server (safe) |
| `DELETE` | `/api/application/servers/{id}/force` | Force delete a server |

**List Servers — Query Parameters**:
- `filter[name]` — Filter by server name
- `filter[uuid]` — Filter by UUID
- `filter[uuidShort]` — Filter by short UUID
- `filter[external_id]` — Filter by external ID
- `filter[image]` — Filter by Docker image
- `include` — Comma-separated: `allocations`, `user`, `subusers`, `nest`, `egg`, `variables`, `location`, `node`, `databases`
- `sort` — Sort field: `id`, `-id`, `uuid`, `-uuid`

**Create Server — Request Body**:
```json
{
  "name": "My Minecraft Server",
  "description": "A test server",
  "user": 1,
  "egg": 1,
  "docker_image": "ghcr.io/pterodactyl/yolks:java_17",
  "startup": "java -Xms128M -Xmx{{SERVER_MEMORY}}M -jar {{SERVER_JARFILE}}",
  "environment": {
    "SERVER_JARFILE": "server.jar",
    "VANILLA_VERSION": "latest",
    "BUILD_NUMBER": "latest"
  },
  "limits": {
    "memory": 1024,
    "swap": 0,
    "disk": 5120,
    "io": 500,
    "cpu": 100,
    "threads": null
  },
  "feature_limits": {
    "databases": 2,
    "backups": 3,
    "allocations": 1
  },
  "allocation": {
    "default": 1,
    "additional": []
  },
  "deploy": {
    "locations": [1],
    "dedicated_ip": false,
    "port_range": []
  },
  "start_on_completion": true,
  "skip_scripts": false,
  "oom_disabled": true,
  "external_id": "ext-server-1"
}
```

**Update Server Details — Request Body**:
```json
{
  "name": "Updated Server Name",
  "description": "Updated description",
  "user": 1,
  "external_id": "ext-server-1"
}
```

**Update Server Build — Request Body**:
```json
{
  "allocation": 1,
  "memory": 2048,
  "swap": 0,
  "disk": 10240,
  "io": 500,
  "cpu": 200,
  "threads": null,
  "feature_limits": {
    "databases": 5,
    "backups": 5,
    "allocations": 5
  },
  "add_allocations": [2, 3],
  "remove_allocations": [4],
  "oom_disabled": true
}
```

**Update Server Startup — Request Body**:
```json
{
  "startup": "java -Xms128M -Xmx{{SERVER_MEMORY}}M -jar {{SERVER_JARFILE}}",
  "environment": {
    "SERVER_JARFILE": "server.jar",
    "VANILLA_VERSION": "1.20.4"
  },
  "egg": 1,
  "image": "ghcr.io/pterodactyl/yolks:java_17",
  "skip_scripts": false
}
```

---

### Server Databases (Admin)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/servers/{id}/databases` | List databases for a server |
| `GET` | `/api/application/servers/{id}/databases/{database_id}` | Get database details |
| `POST` | `/api/application/servers/{id}/databases` | Create a database for server |
| `POST` | `/api/application/servers/{id}/databases/{database_id}/reset-password` | Reset database password |
| `DELETE` | `/api/application/servers/{id}/databases/{database_id}` | Delete a database |

**Create Database — Request Body**:
```json
{
  "database": "my_database",
  "remote": "%",
  "host": 1
}
```

---

### Nodes

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nodes` | List all nodes |
| `GET` | `/api/application/nodes/{id}` | Get node details |
| `GET` | `/api/application/nodes/{id}/configuration` | Get Wings configuration for node |
| `POST` | `/api/application/nodes` | Create a new node |
| `PATCH` | `/api/application/nodes/{id}` | Update a node |
| `DELETE` | `/api/application/nodes/{id}` | Delete a node |

**List Nodes — Query Parameters**:
- `filter[name]` — Filter by node name
- `filter[fqdn]` — Filter by FQDN
- `filter[uuid]` — Filter by UUID
- `filter[daemon_token_id]` — Filter by daemon token ID
- `include` — Comma-separated: `allocations`, `location`, `servers`
- `sort` — Sort field: `id`, `-id`, `uuid`, `-uuid`, `memory`, `-memory`, `disk`, `-disk`

**Create Node — Request Body**:
```json
{
  "name": "US-Node-01",
  "description": "US East Node",
  "location_id": 1,
  "fqdn": "node1.example.com",
  "scheme": "https",
  "memory": 32768,
  "memory_overallocate": 0,
  "disk": 102400,
  "disk_overallocate": 0,
  "upload_size": 100,
  "daemon_sftp": 2022,
  "daemon_listen": 8080,
  "maintenance_mode": false,
  "behind_proxy": false
}
```

**Update Node — Request Body** (same fields as create):
```json
{
  "name": "US-Node-01-Updated",
  "description": "Updated US East Node",
  "location_id": 1,
  "fqdn": "node1.example.com",
  "scheme": "https",
  "memory": 65536,
  "memory_overallocate": 10,
  "disk": 204800,
  "disk_overallocate": 5,
  "upload_size": 256,
  "daemon_sftp": 2022,
  "daemon_listen": 8080,
  "maintenance_mode": false,
  "behind_proxy": false
}
```

---

### Node Allocations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nodes/{id}/allocations` | List allocations for a node |
| `POST` | `/api/application/nodes/{id}/allocations` | Create allocations for a node |
| `DELETE` | `/api/application/nodes/{id}/allocations/{allocation_id}` | Delete an allocation |

**List Allocations — Query Parameters**:
- `filter[ip]` — Filter by IP address
- `filter[port]` — Filter by port
- `filter[server_id]` — Filter by assigned server ID
- `page` — Page number
- `per_page` — Results per page

**Create Allocations — Request Body**:
```json
{
  "ip": "192.168.1.100",
  "alias": "node1.example.com",
  "ports": ["25565", "25566", "25567-25570"]
}
```

> **Note**: The `ports` array supports individual ports and ranges (e.g., `"25567-25570"`).

---

### Locations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/locations` | List all locations |
| `GET` | `/api/application/locations/{id}` | Get location details |
| `POST` | `/api/application/locations` | Create a new location |
| `PATCH` | `/api/application/locations/{id}` | Update a location |
| `DELETE` | `/api/application/locations/{id}` | Delete a location |

**List Locations — Query Parameters**:
- `filter[short]` — Filter by short code
- `filter[long]` — Filter by long name
- `include` — Comma-separated: `nodes`, `servers`
- `sort` — Sort field: `id`, `-id`

**Create Location — Request Body**:
```json
{
  "short": "us-east",
  "long": "US East - New York"
}
```

**Update Location — Request Body**:
```json
{
  "short": "us-east-1",
  "long": "US East - Virginia"
}
```

---

### Nests

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nests` | List all nests |
| `GET` | `/api/application/nests/{id}` | Get nest details |

**List Nests — Query Parameters**:
- `include` — Comma-separated: `eggs`, `servers`

---

### Eggs

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/application/nests/{nest_id}/eggs` | List all eggs in a nest |
| `GET` | `/api/application/nests/{nest_id}/eggs/{id}` | Get egg details |

**List/Get Eggs — Query Parameters**:
- `include` — Comma-separated: `nest`, `servers`, `config`, `script`, `variables`

---

## Client API

**Base URL**: `{panel_url}/api/client`

### Root Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client` | List all servers the user has access to |
| `GET` | `/api/client/permissions` | List all available permissions |

**List Servers — Query Parameters**:
- `type` — Filter by: `admin` (admin-owned), `admin-all` (all as admin), `owner` (owned by user)
- `filter[*]` — Filter by server attributes
- `page` — Page number
- `per_page` — Results per page

---

### Account

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/account` | Get account details |
| `PUT` | `/api/client/account/email` | Update account email |
| `PUT` | `/api/client/account/password` | Update account password |
| `GET` | `/api/client/account/two-factor` | Get 2FA setup QR code / secret |
| `POST` | `/api/client/account/two-factor` | Enable 2FA |
| `POST` | `/api/client/account/two-factor/disable` | Disable 2FA |
| `GET` | `/api/client/account/api-keys` | List API keys |
| `POST` | `/api/client/account/api-keys` | Create an API key |
| `DELETE` | `/api/client/account/api-keys/{id}` | Delete an API key |
| `GET` | `/api/client/account/ssh-keys` | List SSH keys |
| `POST` | `/api/client/account/ssh-keys` | Add an SSH key |
| `POST` | `/api/client/account/ssh-keys/remove` | Remove an SSH key |
| `GET` | `/api/client/account/activity` | Get account activity logs |

**Update Email — Request Body**:
```json
{
  "email": "new@example.com",
  "password": "current_password"
}
```

**Update Password — Request Body**:
```json
{
  "current_password": "old_password",
  "password": "new_password",
  "password_confirmation": "new_password"
}
```

**Enable 2FA — Request Body**:
```json
{
  "code": "123456"
}
```

**Disable 2FA — Request Body**:
```json
{
  "password": "current_password"
}
```

**Create API Key — Request Body**:
```json
{
  "description": "My automation key",
  "allowed_ips": ["192.168.1.0/24"]
}
```

**Add SSH Key — Request Body**:
```json
{
  "name": "My Laptop",
  "public_key": "ssh-ed25519 AAAA..."
}
```

**Remove SSH Key — Request Body**:
```json
{
  "fingerprint": "SHA256:..."
}
```

---

### Servers (Client)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}` | Get server details |
| `GET` | `/api/client/servers/{server}/websocket` | Get WebSocket auth credentials |
| `GET` | `/api/client/servers/{server}/resources` | Get live resource usage |
| `GET` | `/api/client/servers/{server}/activity` | Get server activity logs |
| `POST` | `/api/client/servers/{server}/command` | Send console command |
| `POST` | `/api/client/servers/{server}/power` | Change power state |

> **Note**: `{server}` uses the server's **short UUID** (first 8 chars), not internal ID.

**Send Command — Request Body**:
```json
{
  "command": "say Hello World!"
}
```

**Power Action — Request Body**:
```json
{
  "signal": "start"
}
```

Valid signals: `start`, `stop`, `restart`, `kill`

---

### Files

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/files/list` | List files in directory |
| `GET` | `/api/client/servers/{server}/files/contents` | Get file contents |
| `GET` | `/api/client/servers/{server}/files/download` | Get file download URL |
| `PUT` | `/api/client/servers/{server}/files/rename` | Rename/move files |
| `POST` | `/api/client/servers/{server}/files/copy` | Copy a file |
| `POST` | `/api/client/servers/{server}/files/write` | Write/create file contents |
| `POST` | `/api/client/servers/{server}/files/compress` | Compress files into archive |
| `POST` | `/api/client/servers/{server}/files/decompress` | Decompress an archive |
| `POST` | `/api/client/servers/{server}/files/delete` | Delete files |
| `POST` | `/api/client/servers/{server}/files/create-folder` | Create a new folder |
| `GET` | `/api/client/servers/{server}/files/upload` | Get upload URL |
| `PUT` | `/api/client/servers/{server}/files/chmod` | Change file permissions |
| `POST` | `/api/client/servers/{server}/files/pull` | Pull file from remote URL |

**List Files — Query Parameters**:
- `directory` — Directory path (default: `/`)

**Get File Contents — Query Parameters**:
- `file` — Full file path (e.g., `/server.properties`)

**Get Download URL — Query Parameters**:
- `file` — Full file path

**Rename Files — Request Body**:
```json
{
  "root": "/",
  "files": [
    {
      "from": "old_name.txt",
      "to": "new_name.txt"
    }
  ]
}
```

**Copy File — Request Body**:
```json
{
  "location": "/server.properties"
}
```

**Write File — Query Parameters & Body**:
- Query: `file=/path/to/file.txt`
- Body: Raw file content (Content-Type: `text/plain`)

**Compress Files — Request Body**:
```json
{
  "root": "/",
  "files": ["file1.txt", "folder1"]
}
```

**Decompress File — Request Body**:
```json
{
  "root": "/",
  "file": "archive.tar.gz"
}
```

**Delete Files — Request Body**:
```json
{
  "root": "/",
  "files": ["file1.txt", "folder1"]
}
```

**Create Folder — Request Body**:
```json
{
  "root": "/",
  "name": "new_folder"
}
```

**Change Permissions — Request Body**:
```json
{
  "root": "/",
  "files": [
    {
      "file": "start.sh",
      "mode": 755
    }
  ]
}
```

**Pull Remote File — Request Body**:
```json
{
  "url": "https://example.com/file.zip",
  "directory": "/",
  "filename": "downloaded.zip",
  "use_header": false,
  "foreground": false
}
```

---

### Databases (Client)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/databases` | List server databases |
| `POST` | `/api/client/servers/{server}/databases` | Create a database |
| `POST` | `/api/client/servers/{server}/databases/{database}/rotate-password` | Rotate password |
| `DELETE` | `/api/client/servers/{server}/databases/{database}` | Delete a database |

**Create Database — Request Body**:
```json
{
  "database": "my_database",
  "remote": "%"
}
```

---

### Backups

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/backups` | List all backups |
| `POST` | `/api/client/servers/{server}/backups` | Create a new backup |
| `GET` | `/api/client/servers/{server}/backups/{backup}` | Get backup details |
| `GET` | `/api/client/servers/{server}/backups/{backup}/download` | Get backup download URL |
| `POST` | `/api/client/servers/{server}/backups/{backup}/lock` | Toggle backup lock |
| `POST` | `/api/client/servers/{server}/backups/{backup}/restore` | Restore from backup |
| `DELETE` | `/api/client/servers/{server}/backups/{backup}` | Delete a backup |

**Create Backup — Request Body**:
```json
{
  "name": "Pre-update backup",
  "ignored": "*.log\n*.tmp",
  "is_locked": false
}
```

**Restore Backup — Request Body**:
```json
{
  "truncate": true
}
```

> `truncate: true` will delete all files before restoring.

---

### Schedules

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/schedules` | List all schedules |
| `POST` | `/api/client/servers/{server}/schedules` | Create a schedule |
| `GET` | `/api/client/servers/{server}/schedules/{schedule}` | Get schedule details |
| `PATCH` | `/api/client/servers/{server}/schedules/{schedule}` | Update a schedule |
| `DELETE` | `/api/client/servers/{server}/schedules/{schedule}` | Delete a schedule |
| `POST` | `/api/client/servers/{server}/schedules/{schedule}/execute` | Execute schedule now |

**Create Schedule — Request Body**:
```json
{
  "name": "Daily Restart",
  "is_active": true,
  "minute": "0",
  "hour": "3",
  "day_of_month": "*",
  "month": "*",
  "day_of_week": "*",
  "only_when_online": false
}
```

---

### Schedule Tasks

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/client/servers/{server}/schedules/{schedule}/tasks` | Create a task |
| `PATCH` | `/api/client/servers/{server}/schedules/{schedule}/tasks/{task}` | Update a task |
| `DELETE` | `/api/client/servers/{server}/schedules/{schedule}/tasks/{task}` | Delete a task |

**Create/Update Task — Request Body**:
```json
{
  "action": "command",
  "payload": "say Server restarting in 5 minutes!",
  "time_offset": "0",
  "sequence_id": 1,
  "continue_on_failure": false
}
```

Valid actions: `command`, `power`, `backup`

For power action:
```json
{
  "action": "power",
  "payload": "restart",
  "time_offset": "300"
}
```

---

### Network / Allocations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/network/allocations` | List server allocations |
| `POST` | `/api/client/servers/{server}/network/allocations` | Assign a new allocation |
| `POST` | `/api/client/servers/{server}/network/allocations/{allocation}` | Set allocation note |
| `POST` | `/api/client/servers/{server}/network/allocations/{allocation}/primary` | Set as primary allocation |
| `DELETE` | `/api/client/servers/{server}/network/allocations/{allocation}` | Unassign allocation |

**Set Allocation Note — Request Body**:
```json
{
  "notes": "Dynmap web server port"
}
```

---

### Subusers

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/users` | List all subusers |
| `POST` | `/api/client/servers/{server}/users` | Create a subuser |
| `GET` | `/api/client/servers/{server}/users/{uuid}` | Get subuser details |
| `POST` | `/api/client/servers/{server}/users/{uuid}` | Update subuser permissions |
| `DELETE` | `/api/client/servers/{server}/users/{uuid}` | Delete a subuser |

**Create Subuser — Request Body**:
```json
{
  "email": "subuser@example.com",
  "permissions": [
    "control.console",
    "control.start",
    "control.stop",
    "control.restart",
    "file.read",
    "file.create",
    "file.update"
  ]
}
```

**Available Permissions**:
| Category | Permissions |
|----------|------------|
| **Control** | `control.console`, `control.start`, `control.stop`, `control.restart` |
| **User** | `user.create`, `user.read`, `user.update`, `user.delete` |
| **File** | `file.create`, `file.read`, `file.read-content`, `file.update`, `file.delete`, `file.archive`, `file.sftp` |
| **Backup** | `backup.create`, `backup.read`, `backup.delete`, `backup.download`, `backup.restore` |
| **Allocation** | `allocation.read`, `allocation.create`, `allocation.update`, `allocation.delete` |
| **Startup** | `startup.read`, `startup.update`, `startup.docker-image` |
| **Database** | `database.create`, `database.read`, `database.update`, `database.delete`, `database.view_password` |
| **Schedule** | `schedule.create`, `schedule.read`, `schedule.update`, `schedule.delete` |
| **Settings** | `settings.rename`, `settings.reinstall` |
| **Activity** | `activity.read` |
| **Websocket** | `websocket.connect` |

---

### Startup

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/client/servers/{server}/startup` | List all startup variables |
| `PUT` | `/api/client/servers/{server}/startup/variable` | Update a startup variable |

**Update Startup Variable — Request Body**:
```json
{
  "key": "SERVER_JARFILE",
  "value": "paper-1.20.4.jar"
}
```

---

### Settings

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/client/servers/{server}/settings/rename` | Rename a server |
| `POST` | `/api/client/servers/{server}/settings/reinstall` | Reinstall a server |

**Rename Server — Request Body**:
```json
{
  "name": "My Awesome Server",
  "description": "Updated server description"
}
```

---

## WebSocket API

### Connection Flow

1. **Get WebSocket credentials**:
```
GET /api/client/servers/{server}/websocket
```

Response:
```json
{
  "data": {
    "token": "eyJ...",
    "socket": "wss://node.example.com:8080/api/servers/{uuid}/ws"
  }
}
```

2. **Connect to WebSocket** at the provided `socket` URL

3. **Authenticate** by sending:
```json
{
  "event": "auth",
  "args": ["<token>"]
}
```

### Events (Server → Client)

| Event | Description |
|-------|-------------|
| `auth success` | Authentication successful |
| `status` | Server power status change |
| `console output` | Console log output line |
| `stats` | Live resource usage (CPU, memory, disk, network) |
| `token expiring` | Token is about to expire (request new one) |
| `token expired` | Token has expired |
| `daemon error` | Wings daemon error message |
| `install output` | Installation script output |
| `install started` | Server installation started |
| `install completed` | Server installation completed |
| `transfer logs` | Server transfer log output |
| `transfer status` | Server transfer status change |
| `backup completed` | Backup process completed |
| `backup restore completed` | Backup restore completed |
| `daemon message` | Generic daemon message |

### Events (Client → Server)

| Event | Description |
|-------|-------------|
| `auth` | Send authentication token |
| `set state` | Change power state (`start`, `stop`, `restart`, `kill`) |
| `send command` | Send console command |
| `send logs` | Request console log history |
| `send stats` | Request current resource stats |

---

## Common Query Parameters

These parameters work across most `GET` list endpoints:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `page` | Page number for pagination | `?page=2` |
| `per_page` | Results per page (max varies) | `?per_page=50` |
| `filter[field]` | Filter by field value | `?filter[name]=test` |
| `sort` | Sort by field (prefix `-` for desc) | `?sort=-created_at` |
| `include` | Include related resources | `?include=user,node` |

---

## Error Codes

| HTTP Code | Error | Description |
|-----------|-------|-------------|
| `400` | Bad Request | Malformed request or invalid parameters |
| `401` | Unauthorized | Invalid or missing API key |
| `403` | Forbidden | API key lacks required permissions |
| `404` | Not Found | Resource does not exist |
| `405` | Method Not Allowed | Wrong HTTP method for endpoint |
| `409` | Conflict | Resource conflict (e.g., duplicate) |
| `422` | Unprocessable Entity | Validation error in request body |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Server Error | Server-side error |
| `502` | Bad Gateway | Wings daemon unreachable |
| `504` | Gateway Timeout | Wings daemon timeout |

**Error Response Format**:
```json
{
  "errors": [
    {
      "code": "ValidationException",
      "status": "422",
      "detail": "The email field is required.",
      "meta": {
        "source_field": "email",
        "rule": "required"
      }
    }
  ]
}
```
