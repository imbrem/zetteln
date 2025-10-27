# 🗂️ Zetteln

A zettelkasten note-taking application with version-controlled database backend.

## Architecture

- **Frontend**: SvelteKit (static build)
- **Backend**: Rust with Axum
- **Database**: Dolt (version-controlled MySQL-compatible database)
- **Reverse Proxy**: Caddy with HTTP/3 support
- **Deployment**: Docker Compose

## Quick Start (Development)

```bash
# Clone the repository
git clone https://github.com/imbrem/zetteln.git
cd zetteln

# Start all services
docker compose up -d

# Visit http://localhost:8000
```

The application will:
1. Initialize the Dolt database with the `zetteln` schema
2. Build the SvelteKit frontend
3. Start the Rust API server
4. Configure Caddy as a reverse proxy

## Production Deployment

### Prerequisites

- Docker and Docker Compose installed

### One-Line Hetzner Deployment

Create a new Hetzner Cloud server with this cloud-init script (edit SSH key and optionally DOMAIN):

```bash
hcloud server create \
  --name zetteln \
  --type cpx22 \
  --image ubuntu-24.04 \
  --user-data-from-file cloud-init.yml \
  # --firewall my-firewall (recommended: block all ports except 22, 80, and 443 + ICMP for ping)
```

The `cloud-init.yml` file will automatically:
- Install Docker and Docker Compose
- Pull images from `imbrem/zetteln-api` and `imbrem/zetteln-client`
- Start all services
- Configure automatic log rotation

To enable HTTPS with a custom domain:
1. Point your domain's A record to your server's IP
2. SSH into the server and edit `/opt/zetteln/.env`
3. Set `DOMAIN=yourdomain.com`
4. Restart Caddy: `cd /opt/zetteln && docker compose restart caddy`

### Manual Production Deployment

```bash
# On your server
mkdir -p /opt/zetteln
cd /opt/zetteln

# Download production compose file
wget https://raw.githubusercontent.com/imbrem/zetteln/main/docker-compose.prod.yml -O docker-compose.yml
wget https://raw.githubusercontent.com/imbrem/zetteln/main/Caddyfile

# Create .env file
echo "DOMAIN=:80" > .env  # Or set to your domain for HTTPS

# Start services
docker compose up -d
```

## GitHub Actions Setup

To enable automatic Docker image builds:

1. Create Docker Hub access token at https://hub.docker.com/settings/security
2. Add GitHub repository secret:
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token
3. Push to `main` branch to trigger build

Images are built for both `linux/amd64` and `linux/arm64` platforms.

## Data Persistence & Backups

### Volume Locations

Docker volumes are stored in `/var/lib/docker/volumes/` by default:

- `zetteln_dolt-data`: Database files and version history (Dolt provides Git-like versioning)
- `zetteln_caddy-data`: Caddy TLS certificates
- `zetteln_caddy-config`: Caddy configuration state
- `zetteln_client-build`: Frontend static files
- `zetteln_dolt-socket`: UNIX socket for database connection (ephemeral)

### Version Control with Dolt

Dolt provides built-in Git-like version control for your database. No need for traditional backups!

**View database history:**
```bash
docker compose exec dolt dolt sql -q "SELECT * FROM dolt_log"
```

**Create a commit:**
```bash
docker compose exec dolt dolt sql -q "CALL DOLT_COMMIT('-Am', 'My commit message')"
```

**View diff between commits:**
```bash
docker compose exec dolt dolt sql -q "SELECT * FROM dolt_diff('HEAD~1', 'HEAD', 'notes')"
```

**Revert to previous version:**
```bash
docker compose exec dolt dolt sql -q "CALL DOLT_CHECKOUT('HEAD~1')"
```

**Create a branch:**
```bash
docker compose exec dolt dolt sql -q "CALL DOLT_BRANCH('my-branch')"
```

For more on Dolt's versioning capabilities, see: https://docs.dolthub.com/

### Traditional Backup (if needed)

If you still want traditional file-based backups:

```bash
# Stop the application
docker compose down

# Backup database volume
docker run --rm \
  -v zetteln_dolt-data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/dolt-data-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .

# Restart
docker compose up -d
```

### Restore from Backup

```bash
# Stop services
docker compose down

# Restore database
docker run --rm \
  -v zetteln_dolt-data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar xzf /backup/dolt-data-YYYYMMDD-HHMMSS.tar.gz -C /data

# Restart
docker compose up -d
```

## Upgrading

### Upgrade Application (keeping data)

```bash
# Pull latest images from imbrem/zetteln-*
docker compose -f docker-compose.prod.yml pull

# Recreate containers
docker compose -f docker-compose.prod.yml up -d
```

### Upgrade Dolt Version

```bash
# Backup first!
docker compose down
docker pull dolthub/dolt-sql-server:latest
docker compose up -d
```

### Clear Frontend Cache (after client updates)

```bash
docker compose down
docker volume rm zetteln_client-build
docker compose up -d
```

## Security

- **Database**: Accessible only via UNIX socket (not exposed to network)
- **API**: Internal-only communication with Caddy
- **Ports**: Only 80 and 443 exposed to host
- **TLS**: Automatic HTTPS via Caddy (Let's Encrypt)

## Development

### Project Structure

```
zetteln/
├── server/              # Rust API
│   ├── src/
│   │   └── main.rs
│   ├── Cargo.toml
│   └── Dockerfile
├── client/              # SvelteKit frontend
│   ├── src/
│   │   └── routes/
│   │       └── +page.svelte
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml   # Development compose file
├── docker-compose.prod.yml  # Production compose file
├── Caddyfile           # Reverse proxy config
└── .github/
    └── workflows/
        └── docker-build.yml
```

### Local Development

```bash
# Start Docker services (API, database, reverse proxy)
docker compose up -d

# Option 1: Use built frontend in Docker (slower iteration)
# Frontend is served at http://localhost:8000
docker compose logs -f api

# Option 2: Local frontend development with hot reload (faster iteration)
cd client
npm install
npm run dev
# Frontend with hot reload at http://localhost:5173
# API requests automatically proxied to http://localhost:8000

# Option 3: Develop against remote/staging API
# Create .env file in project root:
echo "VITE_API_URL=https://staging.example.com" > ../.env
cd client && npm run dev
# API requests now proxied to staging server
# Supports WebSocket connections too!

# Access Dolt CLI
docker compose exec dolt dolt sql

# Rebuild API after changes
docker compose build api
docker compose up -d api

# Rebuild frontend in Docker after changes (IMPORTANT: must remove volume)
make rebuild-client-fast
# Or manually:
# docker compose down
# docker volume rm zetteln_client-build
# docker compose build client
# docker compose up -d
```

### Development Proxy Configuration

The local dev server (`npm run dev`) supports proxying API requests:

- **Default**: Proxies to `http://localhost:8000` (local Docker)
- **Custom Port**: Respects `HOST_HTTP_PORT` env var
- **Remote API**: Set `VITE_API_URL` to proxy to any URL
- **WebSocket Support**: Automatically proxies WebSocket connections (`ws: true`)

Examples:
```bash
# Develop against local Docker (default)
npm run dev

# Develop against custom port
HOST_HTTP_PORT=9000 npm run dev

# Develop against staging server
VITE_API_URL=https://staging.example.com npm run dev

# Develop against production (read-only operations!)
VITE_API_URL=https://api.production.com npm run dev
```

### API Endpoints

- `GET /api/version` - Returns API and database version

## Monitoring

### Check Service Health

````

## Monitoring

### Check Service Health

```bash
docker compose ps
docker compose logs api
docker compose logs dolt
```

### Database Health

```bash
# Connect to Dolt
docker compose exec dolt dolt sql

# Check tables
mysql> USE zetteln;
mysql> SHOW TABLES;
mysql> SELECT * FROM notes;

# View Dolt history
mysql> SELECT * FROM dolt_log;
```

## Troubleshooting

### "Database not found" error
The API automatically creates the database on startup. If you see this error, check the API logs:
```bash
docker compose logs api
```

### Stale frontend content
Clear the client build volume:
```bash
docker compose down
docker volume rm zetteln_client-build
docker compose up -d
```

### Database connection issues
Verify the UNIX socket is mounted:
```bash
docker compose exec api ls -la /var/run/mysqld/
```

### Port conflicts
If ports 8000 or 8443 are in use, edit `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Change 8000 to 8080
  - "8444:443" # Change 8443 to 8444
```
