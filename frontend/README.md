# Call Agent (Flutter Web)

Admin-Dashboard-Plattform fuer Voice-Operations (Twilio-ready, Mock-Driven).

## Enthaltene Features

- Reines Admin-Dashboard ohne Endnutzer-Profilseite
- Linke Sidebar: `Live Calls`, `Call History`, `Moderation`
- Neuer Reiter `Voice API` zum Setzen und Pruefen von Telephony-ENV-Werten
- Liste laufender und beendeter Calls
- Call-Detailansicht mit AI-Chatverlauf
- Metriken pro Telefonat: Tokenverbrauch und Latenz
- User-Feedback-Anzeige
- Internes Admin-Bewertungssystem (hilfreich, Score, Notiz)
- Nummer blockieren/entsperren (Mock-State)

## Projektstruktur

- `lib/main.dart`: App-Start und Admin (`/admin`)
- `lib/frontend/admin/admin_shell_page.dart`: Admin-Shell (Navigation + State)
- `lib/frontend/admin/pages/dashboard`: Dashboard-Seite
- `lib/frontend/admin/pages/live_calls`: Live-Anrufe-Seite
- `lib/frontend/admin/pages/call_history`: Anrufverlauf-Seite
- `lib/frontend/admin/pages/moderation`: Moderation-Seite
- `lib/frontend/admin/pages/voice_api`: Voice-API-Seite
- `lib/frontend/admin/widgets`: Wiederverwendbare UI-Komponenten
- `lib/backend/admin_api/admin_api_contract.dart`: API-Vertrag
- `lib/backend/admin_api/live_admin_api.dart`: Live-Backend-Anbindung
- `lib/backend/admin_api/mock_admin_api.dart`: Mock-Adapter
- `lib/domain/admin_models.dart`: Datenmodelle
- `assets/mock/admin/calls.json`: Demo-Datensaetze

## Starten (nach Flutter-Installation)

```bash
flutter pub get
flutter run -d chrome
```

## Lokale Datenbank (Docker Desktop)

Die Backend-Daten (u. a. Voice-API-Konfiguration) werden persistent in PostgreSQL gespeichert.

```powershell
docker compose up -d postgres
cd backend
python -m pip install -r requirements.txt
$env:DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ht_app"
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

## Architekturuebersicht

```text
Admin-UI -> AdminApiContract -> MockAdminApi (spaeter Twilio/Backend Adapter)
```

## Spaetere Backend-Anbindung

Der Mock-Adapter ist bewusst als austauschbare Schicht gebaut. Fuer Twilio/LLM:

1. Neue Klasse `TwilioAdminApi` erstellen, die `AdminApiContract` implementiert.
2. API-Aufrufe an echtes Backend mappen (`/calls/live`, `/calls/history`, `/calls/{id}` etc.).
3. In `main.dart` den Adapter tauschen: `MockAdminApi()` -> `TwilioAdminApi()`.

## Voice API Variablen (Admin UI)

Im Reiter `Voice API` koennen folgende Variablen gepflegt werden:

- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `LOCAL_SERVER_URL`
- `TWILIO_PHONE_NUMBER`
- `DEEPGRAM_API_KEY`

Die Eingaben werden in der UI auf Pflichtfelder und typische Formatfehler geprueft.

## Fokus

Die App ist als reine Admin-Dashboard-Plattform ausgelegt:
- Live-Anrufe
- Anrufverlauf
- Moderation
- Voice-API-Konfiguration inkl. Verbindungsprüfung
