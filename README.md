# n8n-docker-caddy

A Docker Compose setup to self-host n8n and Neo4j graph database with direct port exposure for local development.

## Features

- Workflow automation with n8n
- Neo4j graph database with APOC plugins
- Direct port exposure for n8n (5678) and Neo4j (7475 & 7688)
- Persistent storage via Docker volumes
- Local file mounting for binary data
- **🛡️ Enhanced Security Features:**
  - Isolated Docker network for container communication
  - Resource limits and security constraints
  - Specific image versions (no `:latest` tags)

## Prerequisites

- Docker & Docker Compose installed
- A `.env` file in the project root containing:

  ```dotenv
  DATA_FOLDER=/Users/rainer/Projects/n8n-setup
  SUBDOMAIN=n8n
  DOMAIN_NAME=local.dev
  GENERIC_TIMEZONE=Pacific/Auckland
  NEO4J_PASSWORD=your_secure_password_here
  ```

## Setup Instructions

### 1. Create Docker Volumes

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

### 2. Flush DNS Cache (macOS)

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

### 4. Launch the Stack

Start all services:

```bash
docker-compose up -d
```

This will start:

- **Caddy** (reverse proxy with HTTPS)
- **n8n** (workflow automation)
- **Neo4j** (graph database)

### 6. Access the Services

- **n8n**: <http://localhost:5678>
- **Neo4j Browser**: <http://localhost:7475>

## Connecting n8n to Neo4j

When creating Neo4j nodes in n8n workflows, use these connection settings:

- **Connection URL (Bolt)**: `bolt://localhost:7688`
- **Username**: `neo4j`
- **Password**: Use the password from your `.env` file (`NEO4J_PASSWORD`)

The `neo4j` hostname works because both containers are on the same isolated Docker network, allowing secure internal service discovery.

## Service Architecture

```text
┌───────────────┐    ┌──────────┐
│   Browser     │    │    n8n   │
│ localhost:5678│───▶│ :5678    │
└───────────────┘    └──────────┘
      │
      ▼
┌─────────────────┐
│   Neo4j Browser │
│ localhost:7475  │
└─────────────────┘

┌───────────────┐
│ n8n Workflows │
│ bolt://localhost:7688 │
└───────────────┘        │
                        ▼
                   ┌──────────┐
                   │  Neo4j   │
                   │ :7474, :7687 │
                   └──────────┘
```

## Production

To use real Let's Encrypt certificates, remove the `tls internal` directive from the Caddyfile. Caddy will then automatically obtain and renew valid HTTPS certificates.

## Security Features

This setup includes several production-ready security enhancements:

### 🔐 **Secret Management**

- Neo4j password stored in `.env` file for easy configuration
- Proper environment variable isolation between containers

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
- Test connection: `docker-compose exec neo4j cypher-shell -a bolt://localhost:7687 -u neo4j -p $NEO4J_PASSWORD`
- If containers restart frequently, check: `docker-compose ps`

### n8n Access Issues

- Check Caddy logs: `docker-compose logs caddy`
- Verify hosts file: `ping n8n.local.dev`
- Trust Caddy CA if seeing SSL errors
- Ensure n8n container is healthy: `docker-compose logs n8n`

### Common Issues

- **"Connection refused"**: Check if all containers are running with `docker-compose ps`
- **"Invalid password"**: Verify password in your `.env` file (`NEO4J_PASSWORD`)
- **"Network not found"**: Run `docker-compose down && docker-compose up -d`

## Attribution

This project is based on the original [n8n-docker-caddy](https://github.com/n8n-io/n8n-docker-caddy) setup by n8n with significant modifications and additions including:

- **Neo4j integration** with APOC plugins for graph database workflows
- **Enhanced security** with isolated networks, environment variable management, and container hardening
- **Local development configuration** with `.local.dev` domains and internal CA
- **Production-ready architecture** with resource limits and security constraints
- **Comprehensive documentation** with troubleshooting guides

## License

MIT License - see [LICENSE](LICENSE) file for details.
