# Changelog

Alle nennenswerten strukturellen und dokumentationsbezogenen Änderungen an diesem Repository werden hier festgehalten.

## [Unreleased]

### Geändert

- Monorepo-Struktur: Flutter-Admin nach `apps/admin-web/`, Next.js-Landing nach `apps/marketing-site/`.
- Entfernt: doppelte Spiegelstruktur `frontend/` (inhaltlich identisch zum Admin-Web).
- Dokumentation gebündelt unter `docs/` (`INSTALLATION.md`, `MVP_FEATURES.md`, dieses `CHANGELOG.md`).
- Root: neue `.env.example` für Docker-Compose-Variablen; `README.md` als Einstieg mit Verweisen.
- Docker: `Dockerfile.admin-web` und `.dockerignore` an die Pfade `apps/admin-web` und `apps/marketing-site` angepasst.
- `docker-compose.yml`: ausführlichere Kommentare und Hinweis auf `--env-file`.
- Dart-Paketname: `callagent_admin` (ehemals `klaranspruch_admin`); Web-Manifest und PDF-Export-Dateiname an CallAgent angeglichen.
- Backend-/Root-README: Datenbankname auf **`ifindappointments`** vereinheitlicht (vorher teils veraltet `ht_app`).
- Marketing-Site: npm-Paketname `callagent-marketing-site`; `DEPLOYMENT.md` für Coolify/Next.js; alte Platzhalter-Assets und Marken-Icons entfernt bzw. neutral ersetzt.
- Dependabot: zentrale Konfiguration unter `.github/dependabot.yml` mit `directory: /apps/marketing-site` (alte Datei unter `apps/marketing-site/.github/` entfernt).
- Hilfsskripte `dev.cmd` und `install-node-portable.ps1` der Marketing-Site liegen wieder unter `apps/marketing-site/` (nach Bereinigung eines Restordners `landingpage/`).
