# CallAgent — Deployment & Installation (`frontend/`-Ordner)

Dieses Dokument beschreibt die **Hauptanwendung** (Flutter-**Admin-Web**, FastAPI-**Backend**, **PostgreSQL**) sowie den Anschluss an die **Marketing-Site**. Pfade beziehen sich auf den Ordner **`frontend/`** im Gesamt-Repository. Für schrittweise lokale Einrichtung inkl. Marketing-Site siehe zusätzlich [docs/INSTALLATION.md](docs/INSTALLATION.md).

---

## 1. Architektur

| Teil | Pfad / Artefakt | Rolle |
|------|------------------|--------|
| **Admin-Web** | `apps/admin-web/` → Image `Dockerfile.admin-web` | Browser-UI (Live Calls, Historie, Voice-API, Moderation) |
| **Backend** | `backend/app.py` → `backend/Dockerfile` | REST-API, Twilio-Sync, Aufnahmen, Postgres-Persistenz |
| **Datenbank** | PostgreSQL 16 (Compose-Service `postgres`) | Tabellen u. a. `voice_settings`, `calls`, `call_recordings` |
| **Marketing** (optional) | `apps/marketing-site/` | Öffentliche Next.js-Landingpage, eigenes Image |

Datenfluss:

```text
Browser (Admin)  →  FastAPI (:8000)  →  PostgreSQL
      ↑
  nginx (:80 im Container, extern z. B. :8080)
```

Die Admin-App spricht das Backend über HTTP(S); die Basis-URL kommt aus den **Voice-API-Einstellungen** (`localServerUrl` in `LiveAdminApi`), nicht aus einer separaten Build-Variable.

---

## 2. Voraussetzungen

- **Docker Desktop** oder Docker Engine **mit Compose v2**
- Optional (nur ohne Container): **Flutter stable**, **Python 3.12+**, **Node 22** für Marketing lokal — siehe [docs/INSTALLATION.md](docs/INSTALLATION.md)

---

## 3. Schnellstart: gesamter Hauptstack (Docker)

Im Ordner **`frontend/`** (nach `cd …\frontend`):

```powershell
copy .env.example .env
docker compose up -d --build
```

Standard-Endpunkte:

| Dienst | URL |
|--------|-----|
| Admin-Web | http://localhost:8080 |
| FastAPI | http://localhost:8000 |
| Health | http://localhost:8000/health |
| PostgreSQL | `localhost:5432`, Datenbank `ifindappointments` |

Umgebungsvariablen: [.env.example](.env.example) (Root). Wichtig: `POSTGRES_PASSWORD` in Produktion ändern; `DATABASE_URL` im Compose ist an dieses Passwort gekoppelt.

Stoppen (Volume **behält** Daten):

```powershell
docker compose down
```

Alles inkl. DB-Volume löschen:

```powershell
docker compose down -v
```

---

## 4. Admin-Web ↔ Backend-URL (Pflicht zum Verständnis)

In [apps/admin-web/lib/backend/admin_api/live_admin_api.dart](apps/admin-web/lib/backend/admin_api/live_admin_api.dart) gilt:

- Ist in den Voice-Einstellungen eine **`localServerUrl`** gespeichert, wird **genau diese** Basis-URL für alle Admin-API-Aufrufe verwendet.
- **Ohne** gesetzte URL und bei Aufruf von `localhost` / `127.0.0.1` fällt die App auf **`http(s)://<host>:7860`** zurück — das Backend in Compose lauscht aber auf **Port 8000**.

**Konsequenz:** Nach dem ersten Öffnen von http://localhost:8080 unter **Voice-API / Server-URL** die Backend-Adresse eintragen, z. B.:

- Lokal mit Compose: `http://localhost:8000` oder `http://127.0.0.1:8000`
- Hinter HTTPS-Terminierung: `https://api.deine-domain.de`

Anschließend Verbindung testen bzw. speichern (wie in der UI vorgesehen).

Optional setzt das Backend beim ersten DB-Bootstrap einen Default aus der Umgebungsvariable **`LOCAL_SERVER_URL`** (siehe [backend/app.py](backend/app.py) und [.env.example](.env.example)); die Flutter-App liest diese URL aber **nicht direkt** — sie nutzt weiterhin die in den Voice-Einstellungen persistierte URL.

---

## 5. Einzelne Docker-Images (ohne Compose)

**Backend** (Kontext `backend/`):

```powershell
docker build -t callagent-backend:latest ./backend
docker run --rm -p 8000:8000 -e DATABASE_URL="postgresql://..." callagent-backend:latest
```

**Admin-Web** (Docker-Kontext **Ordner `frontend/`**, Pfade `apps/admin-web/`):

```powershell
docker build -f Dockerfile.admin-web -t callagent-admin-web:latest .
docker run --rm -p 8080:80 callagent-admin-web:latest
```

**Marketing-Site** (Next.js):

```powershell
docker build -t callagent-marketing:latest ./apps/marketing-site
```

Build-Argumente und `NEXT_PUBLIC_*`: [apps/marketing-site/DEPLOYMENT.md](apps/marketing-site/DEPLOYMENT.md).

---

## 6. Produktion (Kurzleitfaden)

1. **TLS** am Ingress / Reverse-Proxy (Traefik, Caddy, Nginx, Cloudflare) terminieren; nur HTTPS nach außen.
2. **Backend** öffentlich unter stabiler URL (z. B. `https://api.example.com`) erreichbar; CORS ist im Backend aktuell sehr liberal (`allow_origins=["*"]`) — für Produktion ggf. auf konkrete Admin-Origins einschränken.
3. **Admin-Web** ausliefern (eigenes Image oder statisches `build/web` nach `flutter build web`); nginx-Beispiel: [docker/nginx-admin.conf](docker/nginx-admin.conf) (`try_files` für SPA).
4. In der Admin-UI die **Backend-Basis-URL** (`localServerUrl`) auf die öffentliche API setzen.
5. **Postgres** nicht unnötig nach außen portieren; Passwort/Secrets über Secret-Store oder Compose-`.env`, nicht im Git.

### 6.1 Lighthouse (Admin-Web)

Der **Entwicklungsserver** (`flutter run`, z. B. Port `18091`) liefert **kein** Release-Bundle. Sehr hoher **TBT**, **Speed Index** und große JS-Nutzlast sind dort **normal** — keine sinnvolle Basis für „alle Kategorien 100“.

**Sinnvoll messen**

1. **Docker-Stack**: `docker compose up -d --build`, Lighthouse gegen `http://localhost:8080` (Admin) — inkl. gzip und Header aus [docker/nginx-admin.conf](docker/nginx-admin.conf).
2. **Nur Admin-Release lokal**: [scripts/lighthouse-admin-release.ps1](scripts/lighthouse-admin-release.ps1) ausführen und die angezeigte URL in Chrome Lighthouse verwenden.

Das Image [Dockerfile.admin-web](Dockerfile.admin-web) baut mit `-O4`, `--tree-shake-icons`, `--no-web-resources-cdn` und `--source-maps`.

**Erwartung:** Volle **100/100** in **allen** Kategorien ist bei **Flutter Web** praktisch **nicht garantierbar** — u. a. weil Lighthouse u. a. **veraltete APIs** in der Engine meldet, **Trusted Types** mit Flutter-Bootstrap kollidiert, und **`http://127.0.0.1`** ohne TLS **HSTS** nicht sinnvoll setzen kann. Mit **Release + `--csp` + ohne Service-Worker-Register + nginx** (dieses Repo) verbessern sich vor allem **Leistung** (gegenüber `flutter run` / Port wie `18091`), **BFCache**-Chancen und **CSP-/Header-bezogene Best Practices** — messen Sie gegen **`http://127.0.0.1:8787`** (Skript/Batch) oder **`docker compose`** auf Port **8080**, nicht gegen den reinen Debug-Port.

---

## 7. Relevante Dateien

| Datei | Zweck |
|--------|--------|
| [docker-compose.yml](docker-compose.yml) | Postgres + Backend + Admin-Web |
| [Dockerfile.admin-web](Dockerfile.admin-web) | Flutter Web-Build (`--csp`, Source Maps, lokales CanvasKit) + Service-Worker-Strippen + nginx |
| [scripts/strip_flutter_service_worker.py](scripts/strip_flutter_service_worker.py) | Entfernt `serviceWorkerSettings` aus `flutter_bootstrap.js` nach dem Build |
| [backend/Dockerfile](backend/Dockerfile) | Python 3.12 + Uvicorn |
| [docker/nginx-admin.conf](docker/nginx-admin.conf) | SPA-Routing für Admin |
| [scripts/lighthouse-admin-release.ps1](scripts/lighthouse-admin-release.ps1) | Release-Build + lokaler Static-Server für Lighthouse |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Erweiterte lokale Installation, Marketing-Site, Troubleshooting-Tabelle |

---

## 8. Marketing-Site (optional)

Lokal und per Docker: [apps/marketing-site/DEPLOYMENT.md](apps/marketing-site/DEPLOYMENT.md). Sie ist **nicht** Teil der Standard-`docker-compose.yml` am Root; sie kann separat deployed oder später als weiterer Service ergänzt werden.
