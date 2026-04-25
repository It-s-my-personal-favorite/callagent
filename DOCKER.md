# Docker Setup for Callagent Backend

## File Structure

All Docker-related files are in the `backend/` directory:
- `backend/Dockerfile` – Development image
- `backend/Dockerfile.prod` – Production image with Gunicorn
- `backend/docker-compose.yml` – Development services
- `backend/docker-compose.prod.yml` – Production services
- `backend/requirements.txt` – Python dependencies
- `backend/.dockerignore` – Files excluded from Docker builds

## Prerequisites
- Docker Desktop installed on Windows: https://www.docker.com/products/docker-desktop
- Docker CLI available in terminal

## Quick Start

Navigate to the `backend/` directory first:
```bash
cd backend
```

### Option 1: SQLite (Lightweight Development)
```bash
docker-compose --profile sqlite up --build
```

Or run detached:
```bash
docker-compose --profile sqlite up -d --build
```

View logs:
```bash
docker-compose --profile sqlite logs -f backend-sqlite
```

Stop containers:
```bash
docker-compose --profile sqlite down
```

**Access:**
- API: http://localhost:5000
- Health check: http://localhost:5000/health
- SQLite database: `../data/callagent.db` (created automatically)

### Option 2: PostgreSQL (Full Stack)
```bash
docker-compose --profile postgres up --build
```

Or run detached:
```bash
docker-compose --profile postgres up -d --build
```

View logs:
```bash
docker-compose --profile postgres logs -f backend-postgres
```

Stop containers:
```bash
docker-compose --profile postgres down
```

**Access:**
- API: http://localhost:5000
- Health check: http://localhost:5000/health
- PostgreSQL: localhost:5432 (User: postgres, Password: postgres)

## Building the Docker Image

### Build the backend image manually
```bash
# From backend directory
docker build -t callagent-backend .

# Or from project root
docker build -f backend/Dockerfile -t callagent-backend .
```

### Run the built image (SQLite)
```bash
docker run -e DB_BACKEND=sqlite -p 5000:5000 callagent-backend
```

### Run the built image (PostgreSQL with Docker Compose)
```bash
cd backend
docker-compose --profile postgres up
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

### `backend-postgres` (Flask + PostgreSQL)
- Profiles: `postgres`
- Ports: `5000:5000`
- Depends on: `postgres` service (waits for health check)
- Environment:
  - `DB_BACKEND`: postgres
  - `PG_HOST`: postgres (Docker internal DNS)
  - `PG_PORT`: 5432
  - Flask debug mode enabled

### `backend-sqlite` (Flask + SQLite)
- Profiles: `sqlite`
- Ports: `5000:5000`
- Volumes: `./data:/app/data`
- Environment:
  - `DB_BACKEND`: sqlite
  - `SQLITE_PATH`: /app/data/callagent.db
  - Flask debug mode enabled

## Environment Variables

You can override environment variables when running:

```bash
# Example: Custom Flask environment
docker-compose --profile postgres -e FLASK_ENV=production up

# Example: Custom PostgreSQL password (requires updating compose file)
```

To set variables permanently, edit `docker-compose.yml` under the `environment` section.

## Troubleshooting

### Port 5000 already in use
```bash
# Change port in docker-compose.yml or use:
docker-compose -p myport --profile postgres -e PORT=5001 up
# Then access at http://localhost:5001
```

### PostgreSQL fails to start
```bash
# Check service logs
docker-compose --profile postgres logs postgres

# Reset database (removes all data!)
docker-compose --profile postgres down -v
docker-compose --profile postgres up --build
```

### Flask app can't connect to PostgreSQL
```bash
# Test PostgreSQL connectivity from backend
docker-compose --profile postgres exec backend-postgres \
  python -c "import psycopg2; psycopg2.connect('postgres://postgres:postgres@postgres:5432/callagent')"

# If it fails, ensure postgres service has started:
docker-compose --profile postgres logs postgres
```

### Reset everything
```bash
# Remove all containers, volumes, and networks
docker-compose --profile sqlite down -v
docker-compose --profile postgres down -v
docker system prune -a
```

## Useful Docker Commands

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs callagent-backend-sqlite
docker logs -f callagent-postgres  # Follow mode

# Execute command in running container
docker exec -it callagent-backend-sqlite bash

# Connect to PostgreSQL in container
docker exec -it callagent-postgres psql -U postgres -d callagent

# Remove container
docker rm callagent-backend-sqlite

# Remove image
docker rmi callagent-backend

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

### Using Production Dockerfile with Gunicorn

For production deployments, use `backend/Dockerfile.prod` which includes:
- Multi-stage build for smaller image size
- Gunicorn WSGI server (instead of Flask dev server)
- Non-root user for security
- Proper logging configuration
- 4 workers for concurrent requests

#### Build Production Image
```bash
# From project root
docker build -f backend/Dockerfile.prod -t callagent-backend:prod .

# Or from backend directory
docker build -f Dockerfile.prod -t callagent-backend:prod .
```

#### Run with Production Compose
```bash
# From backend directory
cd backend
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Or from project root
docker-compose -f backend/docker-compose.prod.yml up -d
```

#### Configure Production Environment
Create a `.env` file in the project root:
```bash
# Database
DB_BACKEND=postgres
PG_USER=postgres
PG_PASSWORD=your_secure_password_here
PG_DATABASE=callagent
PG_ADMIN_DATABASE=postgres
PG_PORT=5432

# Flask
SECRET_KEY=your_secret_key_here
FLASK_ENV=production

# Server
BACKEND_PORT=5000
```

Then run:
```bash
# From backend directory
cd backend
docker-compose -f docker-compose.prod.yml up -d

# Or from project root
docker-compose -f backend/docker-compose.prod.yml up -d
```

### Production Checklist

- [ ] Change PostgreSQL password in `.env`
- [ ] Change Flask `SECRET_KEY` in `.env`
- [ ] Use `docker-compose.prod.yml` instead of `docker-compose.yml`
- [ ] Build with `Dockerfile.prod` for Gunicorn
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
upstream backend {
    server backend:5000;
}

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then update `docker-compose.prod.yml` to include Nginx service and update port mappings.

## Docker Hub Integration (Optional)

```bash
# Tag image for Docker Hub
docker tag callagent-backend myusername/callagent-backend:latest

# Push to Docker Hub
docker push myusername/callagent-backend:latest

# Pull from Docker Hub
docker pull myusername/callagent-backend:latest
```

## Networking in Docker Compose

All services are connected to `callagent-network` bridge network, allowing them to communicate by service name:
- Flask service can reach PostgreSQL at `postgres:5432`
- External clients access Flask at `localhost:5000`

## Volumes

### `postgres_data`
Persists PostgreSQL data between container restarts. Located at Docker's data directory.

### `./data`
For SQLite mode, the database file is stored in the local `./data/` directory on your machine, making it easy to back up or inspect.

---

For more information, see:
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
