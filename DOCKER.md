# Docker Setup for Callagent (API + Bot)

## File Structure

Docker files live alongside each component:
- `api/Dockerfile` – API image
- `bot/Dockerfile` – Bot image
- `docker-compose.yml` – Runs `postgres`, `api`, and `bot` together

## Prerequisites
- Docker Desktop installed on Windows: https://www.docker.com/products/docker-desktop
- Docker CLI available in terminal

## Quick Start

From the project root:
```bash
cp .env.example .env
docker compose up --build
```

Stop containers:
```bash
docker compose down
```

**Access:**
- API: http://localhost:5000
- Health check: http://localhost:5000/health
- Bot: http://localhost:7860

## Building the Docker Image

### Build images manually
```bash
# API image (from project root)
docker build -f api/Dockerfile -t callagent-api .

# Bot image (context is `bot/`)
docker build -f bot/Dockerfile -t callagent-bot bot
```

### Run with Docker Compose
```bash
docker compose up --build
```

## Docker Compose Services

### `postgres` (PostgreSQL 17)
- Image: `postgres:17-alpine`
- Container name: `callagent-postgres`
- Ports: `5432:5432`
- Volumes: `postgres_data:/var/lib/postgresql/data`
- Credentials:
  - User: `postgres`
  - Password: `postgres`
  - Database: `callagent`

### `api` (Flask API)
- Ports: `5000:5000`
- Depends on: `postgres` service (waits for health check)
- Environment:
  - `PG_HOST`: postgres (Docker internal DNS)
  - `PG_PORT`: 5432
  - `FLASK_ENV`: development/production (via `.env`)

### `bot` (Pipecat Twilio bot)
- Ports: `7860:7860`
- Environment:
  - `GOOGLE_API_KEY` (or `GEMINI_API_KEY`)
  - `DEEPGRAM_API_KEY`
  - `CARTESIA_API_KEY`

## Environment Variables

You can override environment variables when running:

```bash
# Example: one-off override
FLASK_ENV=production docker compose up --build
```

To set variables permanently, copy `.env.example` to `.env` and edit it.

## Troubleshooting

### Port 5000 already in use
```bash
API_PORT=5001 docker compose up --build
# Then access at http://localhost:5001
```

### PostgreSQL fails to start
```bash
# Check service logs
docker compose logs postgres

# Reset database (removes all data!)
docker compose down -v
docker compose up --build
```

### Flask app can't connect to PostgreSQL
```bash
# Test PostgreSQL connectivity from API container
docker compose exec api \
  python -c "import psycopg2; psycopg2.connect('postgresql://postgres:postgres@postgres:5432/callagent')"

# If it fails, ensure postgres service has started:
docker compose logs postgres
```

### Reset everything
```bash
# Remove all containers, volumes, and networks
docker compose down -v
docker system prune -a
```

## Useful Docker Commands

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs callagent-api
docker logs callagent-bot
docker logs -f callagent-postgres  # Follow mode

# Execute command in running container
docker exec -it callagent-api bash

# Connect to PostgreSQL in container
docker exec -it callagent-postgres psql -U postgres -d callagent

# Remove container
docker rm callagent-api

# Remove image
docker rmi callagent-api
docker rmi callagent-bot

# Check resource usage
docker stats
```

## Testing the API

Once your containers are running, test the backend:

### Health Check
```bash
curl http://localhost:5000/health
```

### Get All Calls
```bash
curl http://localhost:5000/api/calls
```

### Create a New Call
```bash
curl -X POST http://localhost:5000/api/calls \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+491234567890",
    "chat_date": "2026-04-25",
    "call_time": "14:30"
  }'
```

### Using PowerShell (Windows)
```powershell
# Health check
Invoke-WebRequest http://localhost:5000/health

# Get all calls
Invoke-WebRequest http://localhost:5000/api/calls

# Create call
$body = @{
    phone_number = "+491234567890"
    chat_date = "2026-04-25"
    call_time = "14:30"
} | ConvertTo-Json

Invoke-WebRequest -Method POST `
  -Uri http://localhost:5000/api/calls `
  -ContentType "application/json" `
  -Body $body
```

## Production Deployment

This repo currently ships a single `docker-compose.yml` intended for development.

For a production deployment, start with:
- Set `FLASK_ENV=production` in `.env`
- Run the containers behind a reverse proxy (Nginx/Caddy) with TLS
- Use strong secrets (`SECRET_KEY`, DB password) and restrict exposed ports

### Production Checklist

- [ ] Change PostgreSQL password in `.env`
- [ ] Change Flask `SECRET_KEY` in `.env`
- [ ] Set up reverse proxy (Nginx/Apache) in front of Flask
- [ ] Enable SSL/HTTPS
- [ ] Configure proper logging and monitoring
- [ ] Set up database backups
- [ ] Use managed services for PostgreSQL if available (AWS RDS, Azure Database, etc.)
- [ ] Configure proper restart policies
- [ ] Set resource limits for containers

### Reverse Proxy Example (Nginx)

Create `nginx.conf`:
```nginx
upstream api {
    server api:5000;
}

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then add an Nginx service to `docker-compose.yml` (or run it separately) and update port mappings.

## Docker Hub Integration (Optional)

```bash
# Tag image for Docker Hub
docker tag callagent-api myusername/callagent-api:latest
docker tag callagent-bot myusername/callagent-bot:latest

# Push to Docker Hub
docker push myusername/callagent-api:latest
docker push myusername/callagent-bot:latest

# Pull from Docker Hub
docker pull myusername/callagent-api:latest
docker pull myusername/callagent-bot:latest
```

## Networking in Docker Compose

All services are connected to the default Compose bridge network, allowing them to communicate by service name:
- API can reach PostgreSQL at `postgres:5432`
- External clients access the API at `localhost:5000` and the bot at `localhost:7860`

## Volumes

### `postgres_data`
Persists PostgreSQL data between container restarts. Located at Docker's data directory.

---

For more information, see:
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
