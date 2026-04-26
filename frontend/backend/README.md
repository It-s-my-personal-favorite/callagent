# Backend Setup (FastAPI + PostgreSQL via Docker)

## 1) PostgreSQL mit Docker Desktop starten

```powershell
cd ..
docker compose up -d postgres
```

## 2) Backend-Abhaengigkeiten installieren

```powershell
cd backend
python -m pip install -r requirements.txt
```

## 3) Server starten (mit DB-Verbindung)

```powershell
$env:DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ht_app"
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

## 4) Optional: ngrok auf den Backend-Port

```powershell
ngrok http 8000
```

Dann die ngrok-URL (oder lokal `http://localhost:8000`) in der App als `LOCAL_SERVER_URL` eintragen.

## Enthaltene Endpunkte

- `POST /admin/integrations/voice/verify`
- `POST /admin/integrations/voice/config`
- `GET /admin/calls/live`
- `GET /admin/calls/history`
- `POST /admin/moderation/block-number`
- `POST /admin/moderation/unblock-number`
- `POST /admin/calls/{call_id}/internal-rating`

## Hinweis

Die Voice-API-Konfiguration sowie Moderations-/Review-Daten werden jetzt in PostgreSQL gespeichert
und bleiben nach App-Neustart bestehen, solange das Docker-Volume erhalten bleibt.
