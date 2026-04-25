# PostgreSQL Setup for Windows

## Current Status
✅ PostgreSQL 17 installed and running as Windows service `postgresql-x64-17`  
✅ Flask app supports both SQLite and PostgreSQL backends  
✅ Default database is now SQLite (no installation required)

## Switching Between Databases

### Use SQLite (Default)
```powershell
# Clear PostgreSQL settings
Remove-Item Env:DB_BACKEND -ErrorAction SilentlyContinue
# Just run the app
python -m backend.app
```
Database file: `callagent.db` in project root

### Use PostgreSQL
```powershell
# Set PostgreSQL environment variables
$env:DB_BACKEND = "postgres"
$env:PG_HOST = "localhost"
$env:PG_PORT = "5432"
$env:PG_USER = "postgres"
$env:PG_PASSWORD = "postgres"
$env:PG_DATABASE = "callagent"
$env:PG_ADMIN_DATABASE = "postgres"

# Start the app
python -m backend.app
```

## PostgreSQL Service Management

### Check Service Status
```powershell
Get-Service postgresql-x64-17
```

### Start PostgreSQL (if stopped)
```powershell
Start-Service postgresql-x64-17
```

### Stop PostgreSQL
```powershell
Stop-Service postgresql-x64-17
```

### Connect Directly to PostgreSQL (for debugging)
```powershell
# Open PostgreSQL command line as superuser
psql -U postgres -d postgres
```

## Environment File (Optional)
Copy `.env.example` to `.env` and edit it:
```powershell
Copy-Item .env.example .env
```
Then modify values in `.env` as needed.

## API Testing

Once running, test the backend:
```powershell
# GET all calls
curl http://localhost:5000/api/calls

# Health check
curl http://localhost:5000/health

# POST a new call
$body = @{
    phone_number = "+491234567890"
    chat_date = "2026-04-25"
    call_time = "14:30"
} | ConvertTo-Json

curl -X POST http://localhost:5000/api/calls `
  -ContentType "application/json" `
  -Body $body
```
