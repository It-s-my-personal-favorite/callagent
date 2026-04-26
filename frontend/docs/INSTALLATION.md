# CallAgent — Installations- und Betriebshandbuch

Dieses Dokument beschreibt die **komplette lokale und Docker-basierte Installation** des Monorepos (Admin-Web, Backend, Datenbank, optionale Marketing-Site).

**Deployment-Überblick (Hauptstack, Produktion, Backend-URL):** siehe [DEPLOYMENT.md](../DEPLOYMENT.md) im Ordner `frontend/`.

---

## 1. Voraussetzungen

| Komponente | Verwendung |
|------------|------------|
| **Docker Desktop** (oder Docker Engine + Compose v2) | Empfohlen für Postgres + Backend + Admin-Web |
| **Flutter SDK** (stable) | Nur wenn du `apps/admin-web` **ohne** Docker startest |
| **Python 3.12+** | Nur für lokales Backend **ohne** Backend-Container |
| **Node.js 22.x** + **npm** | Für `apps/marketing-site` (Next.js) |

---

## 2. Umgebungsvariablen

### 2.1 Ordner `frontend/` (Docker Compose)

1. Kopiere [`.env.example`](../.env.example) nach `.env` im Ordner **`frontend/`**.  
2. Passe mindestens `POSTGRES_PASSWORD` an, wenn du nicht die Defaults nutzt.  
3. `BACKEND_PORT`, `ADMIN_WEB_PORT`, `POSTGRES_PORT` sind optional überschreibbar.

Die Datenbank in Compose heißt **`ifindappointments`**. Die URL im Backend muss dazu passen:

`postgresql://postgres:DEIN_PASSWORT@localhost:5432/ifindappointments`

### 2.2 Backend (lokal / Container)

Siehe [backend/.env.example](../backend/.env.example) — vor allem `DATABASE_URL` und optional `LOCAL_SERVER_URL`.

### 2.3 Marketing-Site (Next.js)

Im Ordner `apps/marketing-site`:

- [`.env.example`](../apps/marketing-site/.env.example) — Referenz für `NEXT_PUBLIC_*`  
- Für lokale Entwicklung typischerweise Kopie als **`.env.local`** (siehe [`.env.local.example`](../apps/marketing-site/.env.local.example)).

**Hinweis:** Variablen mit Präfix `NEXT_PUBLIC_*` werden beim **Build** in den Client gebunden. Für Docker-Images siehe [apps/marketing-site/DEPLOYMENT.md](../apps/marketing-site/DEPLOYMENT.md).

---

## 3. Gesamter Stack mit Docker Compose

Im Ordner `frontend/`:

```powershell
docker compose up -d --build
```

Erreichbarkeit (Standardports):

| Dienst | URL / Port |
|--------|------------|
| Admin-Web (nginx) | http://localhost:8080 |
| FastAPI | http://localhost:8000 |
| PostgreSQL | localhost:5432 |

Logs:

```powershell
docker compose logs -f backend
```

Stoppen:

```powershell
docker compose down
```

Volume `callagent_pgdata` bleibt erhalten, bis du `docker compose down -v` ausführst.

---

## 4. Nur PostgreSQL (lokal entwickeln)

```powershell
docker compose up -d postgres
```

Dann Backend wie in [backend/README.md](../backend/README.md) mit passender `DATABASE_URL` starten.

---

## 5. Flutter Admin-Web ohne Docker-Image

```powershell
cd apps\admin-web
flutter pub get
flutter run -d chrome
```

Stelle sicher, dass das Backend läuft und die App die richtige API-Basis-URL verwendet (Konfiguration in der Flutter-App bzw. Umgebung).

---

## 6. Marketing-Site (Next.js) lokal

```powershell
cd apps\marketing-site
npm ci
npm run dev
```

Standard: http://localhost:3000  

Unter Windows optional:

- `.\run-dev.ps1` — sucht `npm`, führt `npm install` und `npm run dev` aus.
- `.\dev.cmd` — nutzt portables Node unter `%LOCALAPPDATA%\Programs\nodejs-portable\` oder die systemweite Installation.
- `.\install-node-portable.ps1` — lädt Node LTS ohne Admin-Rechte (siehe Skriptkopf).

---

## 7. Einzelne Docker-Images

- **Backend:** Build-Kontext `./backend`, siehe `backend/Dockerfile`.  
- **Admin-Web:** Build-Kontext **Ordner `frontend/`**, `Dockerfile.admin-web` (kopiert `apps/admin-web/`).  
- **Marketing-Site:** Build-Kontext `./apps/marketing-site`, siehe `apps/marketing-site/Dockerfile`.

---

## 8. Häufige Probleme

| Symptom | Prüfen |
|---------|--------|
| Backend verbindet nicht mit DB | `DATABASE_URL`, Datenbankname `ifindappointments`, Postgres healthy? |
| Admin-Web zeigt keine Daten | Backend-URL / CORS / gleicher Host wie konfiguriert |
| Falsche Links auf der Marketing-Site | `NEXT_PUBLIC_*` gesetzt? Bei Docker-Build **neu bauen** |

---

## 9. Verweise

- nginx-Admin: `docker/nginx-admin.conf`  
- API-Endpunkte (Auszug): [backend/README.md](../backend/README.md)  
