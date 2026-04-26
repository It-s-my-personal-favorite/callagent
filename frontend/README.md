# CallAgent

Monorepo für **Voice-Operations**: Flutter-Web-**Admin**, FastAPI-**Backend**, PostgreSQL sowie eine optionale **Marketing-Site** (Next.js).

## Repository-Layout

| Pfad | Inhalt |
|------|--------|
| `apps/admin-web/` | Flutter-Web-Admin (Dashboard, Live Calls, Voice-API-Settings) |
| `apps/marketing-site/` | Öffentliche Landingpage (Next.js, Paketname `callagent-landing`) |
| `backend/` | FastAPI + Uvicorn, REST-API für Admin und Integrationen |
| `docker/` | nginx-Konfiguration für das Admin-Web-Image |
| `docs/` | Installationsanleitung, MVP-Funktionsdokumentation, Änderungsprotokoll |

Dieser **Monorepo-Teil** liegt im Repository unter `frontend/` (Branch `frontend`). Die Flutter-**Admin-App** liegt unter `apps/admin-web/`.

## Schnellstart (gesamter Stack mit Docker)

```powershell
cd <pfad-zum-repo>\frontend
copy .env.example .env
docker compose up -d --build
```

- **Admin-UI:** http://localhost:8080  
- **API:** http://localhost:8000  
- **Health:** `GET /health`  

Datenbankname in Compose: **`ifindappointments`** (gleiches Schema wie in `backend/.env.example`).

## Dokumentation

| Dokument | Zweck |
|----------|--------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | **Deployment & Installation** im Ordner `frontend/` (Hauptstack, Docker, Produktion, API-URL) |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Detaillierte Installation (Docker, lokal, Ports, Umgebungsvariablen) |
| [docs/MVP_FEATURES.md](docs/MVP_FEATURES.md) | MVP-Funktionen und Code-Pfade |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | Struktur- und Dokumentationsänderungen |
| [backend/README.md](backend/README.md) | Backend nur mit Postgres |
| [apps/admin-web/README.md](apps/admin-web/README.md) | Flutter-Admin lokal |
| [apps/marketing-site/DEPLOYMENT.md](apps/marketing-site/DEPLOYMENT.md) | Next.js-Build, Docker, Proxy |

## Architektur (Kurz)

```text
Admin-UI (Flutter) → AdminApiContract → LiveAdminApi / MockAdminApi → FastAPI → PostgreSQL
```

## Features (Admin)

- Live Calls, Call History, Moderation, Voice-API-Konfiguration  
- Metriken, Chatverlauf, interne Bewertungen, Blocklisten (Mock/Live je nach Adapter)  

Details und Voice-ENV-Variablen: [docs/MVP_FEATURES.md](docs/MVP_FEATURES.md).
