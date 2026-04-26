# Marketing-Site (Next.js) — Installation & Deployment

Dieses Dokument beschreibt das **Next.js-16-Frontend** im Ordner **`apps/marketing-site`** (npm-Paketname **`callagent-landing`**): lokale Entwicklung, produktionsrechter Docker-Build und sinnvolle Konfiguration hinter einem Reverse-Proxy.

Das Monorepo-Überblicks-README liegt unter [`../../README.md`](../../README.md), die gesamte Stack-Installation unter [`../../docs/INSTALLATION.md`](../../docs/INSTALLATION.md).

---

## 1. Voraussetzungen

| Komponente | Version / Hinweis |
|------------|-------------------|
| **Node.js** | 22.x (analog `Dockerfile`, `package.json` / `@types/node`) |
| **npm** | kommt mit Node; im Projekt `package-lock.json` → bevorzugt `npm ci` |
| **Docker** (optional) | Docker Engine oder Docker Desktop für Image-Build und Container-Lauf |

---

## 2. Lokale Entwicklung (ohne Docker)

Im Projektordner **`apps/marketing-site`** (vom Ordner `frontend/` aus):

```bash
cd apps/marketing-site
npm ci
npm run dev
```

Die App läuft standardmäßig unter `http://localhost:3000`.

Weitere Skripte:

- `npm run build` – Produktionsbuild
- `npm run start` – Produktionsserver (nach `build`)
- `npm run lint` – ESLint

---

## 3. Docker-Image bauen

Das `Dockerfile` in **`apps/marketing-site`** erzeugt ein **mehrstufiges Image**: Abhängigkeiten mit `npm ci`, `next build` mit `output: 'standalone'`, Laufzeit nur mit Node und dem **standalone**-Artefakt (schlanker als ein voller `node_modules`-Copy).

**Build immer mit Build-Kontext auf diesen Ordner:**

```bash
cd apps/marketing-site
docker build -t callagent-marketing:latest .
```

Vom Ordner `frontend/` (gleicher Effekt):

```bash
docker build -f apps/marketing-site/Dockerfile -t callagent-marketing:latest apps/marketing-site
```

### 3.1 Build-Argumente (wichtig für `NEXT_PUBLIC_*` und Rewrites)

Variablen mit Präfix **`NEXT_PUBLIC_`** werden bei `next build` in den **Client-Code** eingebettet. Wenn du sie setzen willst, **musst** du sie **beim `docker build`** per `--build-arg` (oder in Compose unter `build.args`) übergeben – ein reines `docker run -e` reicht dafür **nicht** (außer du baust danach neu).

| Build-ARG | Bedeutung |
|-----------|-----------|
| `NEXT_PUBLIC_SITE_URL` | Öffentliche Basis-URL der Site (z. B. `https://deine-domain.de`) |
| `NEXT_PUBLIC_APP_URL` | Link zur App/Registrierung (siehe `lib/site-config.ts`) |
| `NEXT_PUBLIC_SUPPORT_EMAIL` | Support-E-Mail |
| `NEXT_PUBLIC_HELP_PHONE` | Anzeige der Hotline |
| `NEXT_PUBLIC_HELP_PHONE_TEL` | `tel:`-Link, optional mit `tel:`-Präfix |
| `NEXT_PUBLIC_HELP_HOURS` | Text zur Erreichbarkeit |
| `CALLAGENT_APP_UPSTREAM` | Optional: Ziel-URL für Reverse-Proxy-Rewrite in `next.config.mjs` (ohne abschließendes `/`) |
| `CALLAGENT_APP_PROXY_HOST` | Optional: **Host-Header** (z. B. `app.deine-firma.de`), unter dem der Rewrite greift – siehe `next.config.mjs` |

**Beispiel mit sinnvollen Build-Args:**

```bash
docker build -t callagent-marketing:latest \
  --build-arg NEXT_PUBLIC_SITE_URL="https://www.beispiel.de" \
  --build-arg NEXT_PUBLIC_APP_URL="https://app.beispiel.de" \
  --build-arg NEXT_PUBLIC_SUPPORT_EMAIL="support@beispiel.de" \
  .
```

Hinweis: Die optionalen `CALLAGENT_APP_*` Rewrites gelten nur, wenn **beide** Werte zum Build-Zeitpunkt gesetzt sind. Sonst liefert `rewrites` ein leeres Array (normale statische/SSR-Routen der Marketing-Site).

---

## 4. Container starten

**Minimal:**

```bash
docker run --rm -p 3000:3000 callagent-marketing:latest
```

Standard im Image:

- `PORT=3000`
- `HOSTNAME=0.0.0.0` (in allen Containern erreichbar)
- Prozess: `node server.js` (Next.js-Standalone)

Anderen Host-Port:

```bash
docker run --rm -p 8080:3000 callagent-marketing:latest
```

---

## 5. Laufzeit-Umgebungsvariablen (Runtime)

- **`PORT`:** Listener-Port im Container (Standard `3000`).
- **`NODE_ENV`:** Wird im Image auf `production` gesetzt; normalerweise nicht überschreiben.

Server-Middleware (siehe `lib/https.ts`):

- In **Produktion** leitet die Middleware HTTP→HTTPS um, **wenn** der Request als HTTP erkannt wird (`x-forwarded-proto: http`) und der Host **nicht** lokal ist.
- Hinter **TLS-Terminierung** (Nginx, Traefik, Caddy, Cloudflare, …) müssen **korrekte Forwarded-Header** an den Container weitergegeben werden, sonst fehlt ggf. die Umwandlung bzw. Host-Erkennung:
  - `X-Forwarded-Proto: https` (vom Terminator)
  - `X-Forwarded-Host` oder sinnvoller `Host` (Client-Host)

Dokumentation zu Headern: je nach Load-Balancer; wichtig ist konsistente Weiterleitung an den Node-Prozess.

---

## 6. Optional: docker compose

Eine beispielhafte Definition liegt in **`docker-compose.example.yml`** (in diesem Ordner). Datei nach `docker-compose.yml` kopieren, Werte anpassen, dann im Ordner `apps/marketing-site`:

```bash
docker compose build
docker compose up -d
```

---

## 7. Sicherheit & Betrieb (Kurz)

- Keine **Geheimnisse** in `NEXT_PUBLIC_*` legen (sind im Browser sichtbar).
- **HTTPS** am Proxy terminieren; Zertifikate (Let’s Encrypt, Managed TLS) am Ingress/Proxy pflegen.
- Regelmäßig **Basis-Image** und **Abhängigkeiten** aktualisieren (`npm audit`, `docker pull`).

---

## 8. Relevante Projektdateien

| Datei | Zweck |
|--------|--------|
| `Dockerfile` | Multi-Stage Build, `standalone` |
| `.dockerignore` | Schnellere, kleinere Build-Kontexte |
| `next.config.mjs` | u. a. `output: 'standalone'`, Security-Header, optionale Rewrites |
| `lib/site-config.ts` | `NEXT_PUBLIC_*` Defaults und Hilfsfunktionen |
| `package.json` | Skripte und Abhängigkeiten |

---

## 9. Wenn etwas schiefgeht

- **Build fehlgeschlagen:** Zuerst lokal `npm run build` im Ordner **`apps/marketing-site`** prüfen.
- **Falsche URLs im Browser:** `NEXT_PUBLIC_*` nachgetragen? → Image **neu bauen**, nicht nur Container-Env ändern.
- **Endlosschleifen oder Redirects hinter Proxy:** `X-Forwarded-Proto` / `Host` prüfen; ggf. HTTPS-Redirect nur am Proxy oder konsistente Header bis Node.

Bei Anpassungen an `next.config.mjs` (z. B. Rewrites) immer **neu bauen**, da die Config in den Build einfließt.
