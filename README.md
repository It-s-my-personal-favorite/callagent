# Callagent - A project at the Hackerton Kassel 2026
Callagent is a agent for elderly person to access AI and Internet via the phone.

## Installation guide
First of all you need a python interpreter on your system.
Create a virtual environment to prevent package conflicts.
Run this command in the top level folder:
```shell
python -m venv .venv
```
Activate it:
```shell
.venv\Scripts\Activate.ps1
```
Now you are good to go to install the required packages:
```shell
pip install -r requirements.txt
```

## Running the Backend

### SQLite Mode (Default - No Installation Required)
```shell
python -m backend.app
```
The database file `callagent.db` will be created in the project root automatically.

### PostgreSQL Mode (Optional)
First, install PostgreSQL 17 on Windows:
```powershell
winget install --id PostgreSQL.PostgreSQL.17 -e --accept-package-agreements --accept-source-agreements
```

After installation, set environment variables and run:
```powershell
$env:DB_BACKEND = "postgres"
$env:PG_HOST = "localhost"
$env:PG_PORT = "5432"
$env:PG_USER = "postgres"
$env:PG_PASSWORD = "postgres"
$env:PG_DATABASE = "callagent"
$env:PG_ADMIN_DATABASE = "postgres"
python -m backend.app
```

Or copy the `.env.example` file and edit it for convenience.

## Running with Docker

### Prerequisites
- Install Docker Desktop: https://www.docker.com/products/docker-desktop

### SQLite Mode (Lightweight Development)
```bash
cd backend
docker-compose --profile sqlite up --build
```
- Access at http://localhost:5000
- Database file: `../data/callagent.db`

### PostgreSQL Mode (Full Stack)
```bash
cd backend
docker-compose --profile postgres up --build
```
- Access at http://localhost:5000
- PostgreSQL service runs at localhost:5432

### Stop Containers
```bash
cd backend
docker-compose down
```

For detailed Docker documentation, troubleshooting, and production setup, see [DOCKER.md](DOCKER.md).