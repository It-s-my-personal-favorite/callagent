# Backend Setup (FastAPI + PostgreSQL)

Python-Backend für Admin-APIs, Voice-Konfiguration und Aufrufdaten — mit PostgreSQL als Speicher.

## 1) PostgreSQL starten (Docker)

Vom Ordner **`frontend/`** (eine Ebene über `backend/`):

```powershell
docker compose up -d postgres
```

Die Compose-Datei legt die Datenbank **`ifindappointments`** an (Benutzer `postgres`, Passwort aus `.env` bzw. Default `postgres`).

## 2) Abhängigkeiten installieren

```powershell
cd backend
python -m pip install -r requirements.txt
```

## 3) Server starten (mit DB-Verbindung)

```powershell
$env:DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ifindappointments"
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

Passe Benutzer, Passwort und Host an deine `.env` / Docker-Ports an. Details zu allen Variablen: [.env.example](.env.example).

## 4) Optional: ngrok auf den Backend-Port

```powershell
ngrok http 8000
```

Die öffentliche HTTPS-URL als `LOCAL_SERVER_URL` in den Voice-Settings bzw. in der Admin-UI eintragen.

## Endpunkte (Auszug)

- `POST /admin/integrations/voice/verify`
- `POST /admin/integrations/voice/config`
- `GET /admin/calls/live`
- `GET /admin/calls/history`
- `POST /admin/moderation/block-number`
- `POST /admin/moderation/unblock-number`
- `POST /admin/calls/{call_id}/internal-rating`

## Hinweis

Voice-API-Konfiguration und Moderations-/Review-Daten liegen in PostgreSQL und bleiben erhalten, solange das Docker-Volume `callagent_pgdata` nicht gelöscht wird.
