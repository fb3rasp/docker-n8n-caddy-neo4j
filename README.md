# n8n-docker-caddy

A Docker Compose setup to self-host n8n behind Caddy with automatic HTTPS, plus Neo4j graph database. This provides both a production configuration (Let's Encrypt) and a local development mode (Caddy's internal CA).

## Features

- Workflow automation with n8n
- Neo4j graph database with APOC plugins
- Caddy reverse-proxy with automatic TLS
- Persistent storage via Docker volumes
- Local file mounting for binary data
- **🛡️ Enhanced Security Features:**
  - Isolated Docker network for container communication
  - Resource limits and security constraints
  - Localhost-only Neo4j access
  - No direct port exposure for n8n (Caddy proxy only)
  - Specific image versions (no `:latest` tags)

## Prerequisites

- Docker & Docker Compose installed
- A `.env` file in the project root containing:

  ```dotenv
  DATA_FOLDER=/Users/rainer/Projects/n8n-setup
  SUBDOMAIN=n8n
  DOMAIN_NAME=local.dev
  GENERIC_TIMEZONE=Pacific/Auckland
  ```

> **🔐 Security Note**: Passwords are managed securely via the setup script, not stored in `.env` files.

## Setup Instructions

### 1. Quick Setup (Recommended)

Run the automated security setup script:

```bash
./setup-security.sh
```

This script will:

- Generate secure passwords
- Create required directories
- Configure `.env` file template
- Set proper file permissions
- Add secrets to `.gitignore`

### 2. Create Docker Volumes

Create all required external volumes for persistent data storage:

```bash
# Core application volumes
docker volume create caddy_data
docker volume create n8n_data

# Neo4j volumes
docker volume create neo4j_data
docker volume create neo4j_logs
docker volume create neo4j_conf
docker volume create neo4j_import
```

### 3. Configure Local DNS

Edit `/etc/hosts` to point your hostname to localhost:

```text
127.0.0.1   n8n.local.dev
```

### 4. Flush DNS Cache (macOS)

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

### 5. Launch the Stack

Start all services:

```bash
docker-compose up -d
```

This will start:

- **Caddy** (reverse proxy with HTTPS)
- **n8n** (workflow automation)
- **Neo4j** (graph database)

### 6. Trust Caddy's Internal CA

For HTTPS to work without browser warnings:

```bash
# Export the root certificate
docker run --rm \
  -v caddy_data:/data \
  caddy:latest \
  cat /data/caddy/pki/authorities/local/root.crt > ~/caddy_internal_root.crt

# Trust it on macOS
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ~/caddy_internal_root.crt
```

### 7. Access the Services

- **n8n**: <https://n8n.local.dev>
- **Neo4j Browser**: <http://localhost:7474>

## Connecting n8n to Neo4j

When creating Neo4j nodes in n8n workflows, use these connection settings:

- **Connection URL**: `bolt://neo4j:7687`
- **Username**: `neo4j`
- **Password**: Check `secrets/neo4j_password.txt` for the generated password

The `neo4j` hostname works because both containers are on the same isolated Docker network, allowing secure internal service discovery.

## Service Architecture

```text
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Browser       │    │    Caddy     │    │      n8n        │
│ n8n.local.dev   │───▶│ :80, :443    │───▶│ :5678           │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                     │
┌─────────────────┐                                  │
│   Browser       │                                  │
│ localhost:7474  │                                  ▼
└─────────────────┘                           ┌─────────────────┐
        │                                     │     Neo4j       │
        └────────────────────────────────────▶│ :7474, :7687    │
                                              └─────────────────┘
```

## Production

To use real Let's Encrypt certificates, remove the `tls internal` directive from the Caddyfile. Caddy will then automatically obtain and renew valid HTTPS certificates.

## Security Features

This setup includes several production-ready security enhancements:

### 🔐 **Secret Management**

- Passwords stored in `secrets/` directory, not environment variables
- Automatic password generation via setup script
- Proper file permissions (600) for secret files

### 🌐 **Network Security**

- Isolated Docker network (`n8n_network`) for container communication
- Neo4j accessible only from localhost (`127.0.0.1:7474`, `127.0.0.1:7687`)
- n8n has no direct external ports (access via Caddy proxy only)

### 🛡️ **Container Hardening**

- Resource limits on all containers (CPU/Memory)
- `no-new-privileges` security option
- Specific image versions (no `:latest` tags)
- Minimal Alpine-based images where possible

## Troubleshooting

### Neo4j Connection Issues

- Verify Neo4j is running: `docker-compose logs neo4j`
- Test connection: `docker-compose exec neo4j cypher-shell -a bolt://localhost:7687 -u neo4j -p $(cat secrets/neo4j_password.txt)`
- If containers restart frequently, check: `docker-compose ps`

### n8n Access Issues

- Check Caddy logs: `docker-compose logs caddy`
- Verify hosts file: `ping n8n.local.dev`
- Trust Caddy CA if seeing SSL errors
- Ensure n8n container is healthy: `docker-compose logs n8n`

### Common Issues

- **"Connection refused"**: Check if all containers are running with `docker-compose ps`
- **"Invalid password"**: Verify password in `secrets/neo4j_password.txt`
- **"Network not found"**: Run `docker-compose down && docker-compose up -d`

## Attribution

This project is based on the original [n8n-docker-caddy](https://github.com/n8n-io/n8n-docker-caddy) setup by n8n with significant modifications and additions including:

- **Neo4j integration** with APOC plugins for graph database workflows
- **Enhanced security** with isolated networks, secret management, and container hardening
- **Local development configuration** with `.local.dev` domains and internal CA
- **Production-ready architecture** with resource limits and security constraints
- **Automated setup scripts** for easy deployment and configuration
- **Comprehensive documentation** with troubleshooting guides

## License

MIT License - see [LICENSE](LICENSE) file for details.
