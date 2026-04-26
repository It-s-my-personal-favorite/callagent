# CallAgent — Admin-Web (Flutter)

Flutter-Web-Oberfläche für Live Calls, Verlauf, Moderation und Voice-API-Einstellungen.

## Voraussetzungen

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Laufendes FastAPI-Backend (siehe [backend/README.md](../../backend/README.md)) mit PostgreSQL

## Lokaler Start

```powershell
cd apps\admin-web
flutter pub get
flutter run -d chrome
```

## Wichtige Pfade

- Einstieg: `lib/main.dart`
- Admin-Shell: `lib/frontend/admin/admin_shell_page.dart`
- API-Vertrag: `lib/backend/admin_api/admin_api_contract.dart`
- Live-Adapter: `lib/backend/admin_api/live_admin_api.dart`
- Mock: `lib/backend/admin_api/mock_admin_api.dart`

## Docker

Das Image wird vom Ordner **`frontend/`** gebaut (`Dockerfile.admin-web`, Kontext `.`), nicht aus diesem Unterordner. Siehe [README.md](../../README.md), [DEPLOYMENT.md](../../DEPLOYMENT.md) und [docs/INSTALLATION.md](../../docs/INSTALLATION.md).
