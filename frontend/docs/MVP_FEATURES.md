# App-Dokumentation: Funktionen, MVP-Aufbau, Datenfluss

Diese Datei dokumentiert die gesamte App auf Code-Ebene:
- alle relevanten Funktionen/Methoden der primären Quellpfade
- Input/Output und Zweck je Funktion
- kompletter MVP-Aufbau
- Frontend-zu-DB Datenfluss (Laden und Anzeigen)

## 1) Geltungsbereich und Primärpfade

Primär dokumentiert:
- `apps/admin-web/lib/` (Flutter Frontend + Domain + Services + API-Adapter)
- `backend/app.py` (FastAPI Backend + DB-Zugriff)
- `apps/admin-web/assets/mock/admin/calls.json` (Mock-Daten)

Nicht im Fokus:
- `build/`, `.dart_tool/`, `.git/`, `.env*`
- `apps/marketing-site/` (öffentliche Next.js-Landing, eigene Doku unter `DEPLOYMENT.md`)

**Pfadkonvention in diesem Dokument:** Verweise auf `lib/...` und `assets/...` meinen **`apps/admin-web/lib/`** bzw. **`apps/admin-web/assets/`**, sofern nicht ausdrücklich ein anderer Root genannt ist.

## 2) Vollständige Funktionsliste (Input/Output/Zweck)

Hinweis: Bei Widget-Klassen sind `build(...)`-Methoden mit aufgeführt, weil sie zentrale Rendering-Funktionen sind.

### `lib/main.dart`

- `main() -> void`
  - Input: keiner
  - Output: startet App via `runApp`
  - Zweck: Einstiegspunkt.
- `createState() -> State<CallAgentApp>`
  - Input: keiner
  - Output: erzeugt `_CallAgentAppState`
  - Zweck: Stateful-Lebenszyklus.
- `initState() -> void`
  - Input: keiner
  - Output: lädt initiales Theme
  - Zweck: App-Initialisierung.
- `_loadThemeMode() -> Future<void>`
  - Input: keiner
  - Output: liest Theme aus `SharedPreferences`
  - Zweck: Persistente Theme-Wahl wiederherstellen.
- `_toggleThemeMode() -> void`
  - Input: keiner
  - Output: toggelt Theme + speichert es
  - Zweck: Dark/Light Umschaltung.
- `build(BuildContext context) -> Widget`
  - Input: Flutter `context`
  - Output: `MaterialApp` + Startseite
  - Zweck: Root-Widget und API-Adapter-Injektion (`LiveAdminApi`).

### `lib/backend/admin_api/admin_api_contract.dart`

- `getCalls() -> Future<List<CallSession>>`
- `getLiveCalls() -> Future<List<CallSession>>`
- `getHistoryCalls() -> Future<List<CallSession>>`
- `getVoiceApiSettings() -> Future<VoiceApiSettings>`
- `getVoiceApiConnectionStatus() -> Future<bool>`
- `verifyVoiceApiConnection(VoiceApiSettings settings) -> Future<bool>`
- `saveVoiceApiSettings(VoiceApiSettings settings) -> Future<void>`
- `blockNumber(String callId, String reason) -> Future<void>`
- `unblockNumber(String callId) -> Future<void>`
- `submitInternalReview({required String callId, required bool helpful, required int score, String? note}) -> Future<void>`
- `getServerStatus() -> Future<Map<String, dynamic>>`
- `getTwilioSourceStatus() -> Future<Map<String, dynamic>>`
- `pingHealth() -> Future<bool>`
- `requestServerStop() -> Future<void>`

Zweck aller Funktionen: stabiler Vertrags-Layer zwischen UI und konkreter Datenquelle (Live/Mock).

### `lib/backend/admin_api/live_admin_api.dart`

- `_persistVoiceSettings(VoiceApiSettings settings, bool connected) -> Future<void>`
  - Input: Settings + Connection-Status
  - Output: persistiert in `SharedPreferences`
  - Zweck: lokales Caching.
- `_loadSettings() -> Future<VoiceApiSettings>`
  - Input: keiner
  - Output: geladene Settings
  - Zweck: lokale Konfig lesen.
- `_loadConnectionStatus() -> Future<bool>`
  - Input: keiner
  - Output: letzter bekannter Verbindungsstatus
  - Zweck: UI-Status initialisieren.
- `_headers({bool withJson = false}) -> Map<String, String>`
  - Input: optional JSON-Flag
  - Output: HTTP Header
  - Zweck: Request-Setup.
- `_uri(String baseUrl, String path) -> Uri`
  - Input: Basis-URL + Pfad
  - Output: normalisierte URI
  - Zweck: sichere URL-Konstruktion.
- `_resolveBaseUrl(VoiceApiSettings settings) -> String`
  - Input: Voice-Settings
  - Output: effektive Backend-Basis-URL
  - Zweck: Target-Server bestimmen.
- `_absoluteRecordingUrl(String? recordingUrl, String baseUrl) -> String?`
  - Input: evtl. relative Recording-URL + Basis
  - Output: absolute URL
  - Zweck: Playback-kompatible URL.
- `_mapCallWithRecordingBase(Map<String, dynamic> json, String baseUrl) -> CallSession`
  - Input: API-JSON + Basis
  - Output: gemappter Call
  - Zweck: JSON->Domain inkl. Recording-URL-Normalisierung.
- `_getJsonList(Uri uri) -> Future<List<dynamic>>`
  - Input: Ziel-URI
  - Output: JSON-Liste
  - Zweck: GET Hilfsmethode mit Fehlerhandling.
- `_getJsonObject(Uri uri) -> Future<Map<String, dynamic>>`
  - Input: Ziel-URI
  - Output: JSON-Objekt
  - Zweck: GET Hilfsmethode.
- `_post(Uri uri, Map<String, dynamic> body) -> Future<Map<String, dynamic>>`
  - Input: URI + Body
  - Output: JSON-Antwort
  - Zweck: POST Hilfsmethode.
- `getCalls() -> Future<List<CallSession>>`
  - Input: keiner
  - Output: kombinierte, sortierte Calls
  - Zweck: zentrale Ladefunktion für UI.
- `getLiveCalls() -> Future<List<CallSession>>`
  - Input: keiner
  - Output: aktive Calls
  - Zweck: Endpoint `/admin/calls/live`.
- `getHistoryCalls() -> Future<List<CallSession>>`
  - Input: keiner
  - Output: Historien-Calls
  - Zweck: Endpoint `/admin/calls/history`.
- `getVoiceApiSettings() -> Future<VoiceApiSettings>`
- `getVoiceApiConnectionStatus() -> Future<bool>`
- `verifyVoiceApiConnection(VoiceApiSettings settings) -> Future<bool>`
- `saveVoiceApiSettings(VoiceApiSettings settings) -> Future<void>`
- `blockNumber(String callId, String reason) -> Future<void>`
- `unblockNumber(String callId) -> Future<void>`
- `submitInternalReview({required String callId, required bool helpful, required int score, String? note}) -> Future<void>`
- `getServerStatus() -> Future<Map<String, dynamic>>`
- `getTwilioSourceStatus() -> Future<Map<String, dynamic>>`
- `pingHealth() -> Future<bool>`
- `requestServerStop() -> Future<void>`

Zweck der öffentlichen Methoden: HTTP-Anbindung an FastAPI und Rückgabe als Domain-Objekte.

### `lib/backend/admin_api/mock_admin_api.dart`

- `_loadCalls() -> Future<List<CallSession>>`
  - Input: keiner
  - Output: Mock-Calls aus Asset + Cache
  - Zweck: lokale Testdatenquelle.
- `_withAdditionalDemoAccounts(List<CallSession> source) -> List<CallSession>`
  - Input: Basisliste
  - Output: angereicherte Demo-Liste
  - Zweck: zusätzliche Beispielkonten.
- `getCalls() -> Future<List<CallSession>>`
- `getLiveCalls() -> Future<List<CallSession>>`
- `getHistoryCalls() -> Future<List<CallSession>>`
- `getVoiceApiSettings() -> Future<VoiceApiSettings>`
- `getVoiceApiConnectionStatus() -> Future<bool>`
- `verifyVoiceApiConnection(VoiceApiSettings settings) -> Future<bool>`
- `saveVoiceApiSettings(VoiceApiSettings settings) -> Future<void>`
- `blockNumber(String callId, String reason) -> Future<void>`
- `unblockNumber(String callId) -> Future<void>`
- `submitInternalReview({required String callId, required bool helpful, required int score, String? note}) -> Future<void>`
- `getServerStatus() -> Future<Map<String, dynamic>>`
- `getTwilioSourceStatus() -> Future<Map<String, dynamic>>`
- `pingHealth() -> Future<bool>`
- `requestServerStop() -> Future<void>`

Zweck: identische Vertragsoberfläche wie Live, aber ohne externes Backend.

### `lib/services/call_local_store.dart`

- `loadAll() -> Future<Map<String, Map<String, dynamic>>>`
  - Input: keiner
  - Output: alle lokalen Call-Overrides
  - Zweck: lokale Persistenz laden.
- `saveAll(Map<String, Map<String, dynamic>> data) -> Future<void>`
  - Input: komplette Override-Map
  - Output: speichert nach `SharedPreferences`
  - Zweck: persistente Ablage.
- `patchCall(String callId, Map<String, dynamic> patch) -> Future<void>`
  - Input: Call-ID + Teiländerung
  - Output: merged/speichert Call-Override
  - Zweck: inkrementelles Updaten.
- `mergeWithMap(CallSession base, Map<String, Map<String, dynamic>>? all) -> CallSession`
  - Input: Backend-Call + Override-Map
  - Output: zusammengeführter Call
  - Zweck: lokale Änderungen auf Backend-Daten legen.
- `mergeCalls(List<CallSession> calls) -> Future<List<CallSession>>`
  - Input: Call-Liste
  - Output: Liste mit Overrides
  - Zweck: Bulk-Merge.

### `lib/services/pdf/pdf_export_service.dart`

- `_downloadBytes(Uint8List bytes, String filename) -> void`
  - Input: Byte-Daten + Dateiname
  - Output: Browser-Download
  - Zweck: Export in Flutter Web.
- `exportPrefilledPdf({required UserProfile profile, required EligibilityResult result, required List<FormAnswer> answers}) -> Future<void>`
  - Input: Profil + Ergebnis + Antworten
  - Output: PDF-Datei
  - Zweck: Claims-Export.
- `exportCallBriefing(CallSession call) -> Future<void>`
  - Input: Call
  - Output: PDF-Datei
  - Zweck: Call-Zusammenfassung exportieren.

### `lib/services/forms/guided_forms.dart`

- `questionsForClaim(String claimId) -> List<FormQuestion>`
  - Input: Claim-Typ
  - Output: geführte Fragenliste
  - Zweck: dynamischer Formularinhalt.

### `lib/services/ai/ai_helper.dart`

- `simplifyQuestion(String question, {bool enabled = false}) -> Future<String>`
  - Input: Frage + AI an/aus
  - Output: vereinfachter Text
  - Zweck: optionale KI-Hilfestellung.
- `_fallback(String question) -> String`
  - Input: Ursprungsfrage
  - Output: lokale Standardvereinfachung
  - Zweck: Fallback ohne externe AI.

### `lib/domain/rules/eligibility_engine.dart`

- `evaluate(UserProfile profile) -> List<EligibilityResult>`
  - Input: Benutzerprofil
  - Output: Liste möglicher Ansprüche inkl. Konfidenz
  - Zweck: Regelbasierte Eligibility-Engine.

### `lib/domain/admin_models.dart`

Model-Funktionen (pro Klasse, sofern vorhanden):
- `fromJson(Map<String, dynamic>) -> <Model>`
- `toJson() -> Map<String, dynamic>`
- `copyWith(...) -> <Model>`

Konkrete Modellklassen:
- `TranscriptTurn`
- `CallMetrics`
- `UserFeedback`
- `InternalReview`
- `CallSession`
- `CallRecord`
- `CallNote`
- `CallerProfile`
- `VoiceApiSettings`

Spezialfunktion:
- `_outcomeFromString(String value) -> CallOutcome`
  - Zweck: String-zu-Enum Mapping.

### `lib/domain/claims_models.dart`

Model-Funktionen analog:
- `fromJson(...)`, `toJson()`, `copyWith(...)` (abhängig von Klasse)

Konkrete Claims-Modelle:
- `UserProfile`
- `EligibilityResult`
- `FormQuestion`
- `FormAnswer`
- `EligibilityConfidence` (Enum)

### `lib/features/claims/claims_flow_page.dart`

- `createState() -> State<ClaimsFlowPage>`
- `dispose() -> void`
- `build(BuildContext context) -> Widget`
- `_buildOnboarding() -> Widget`
- `_buildResults() -> Widget`
- `_buildGuidedQuestions() -> Widget`
- `_buildFinish() -> Widget`
- `_buildTextField(TextEditingController controller, String label) -> Widget`
- `_evaluate() -> void`
- `_startGuidedForm(String claimId) -> void`
- `_nextQuestion() -> void`
- `_refreshHelpText() -> Future<void>`
- `_claimTitle(String claimId) -> String`
- `_confidenceText(EligibilityConfidence value) -> String`

Zweck: End-to-End Claims-MVP-Flow (Onboarding -> Bewertung -> Guided Form -> Abschluss).

### `lib/frontend/admin/admin_shell_page.dart`

- `createState() -> State<AdminShellPage>`
- `_isCurrentlyActiveCall(CallSession call) -> bool`
- `_isEndedCall(CallSession call) -> bool`
- `initState() -> void`
- `dispose() -> void`
- `_loadCalls() -> Future<void>`
- `_refreshApiControl() -> Future<void>`
- `_selectedCall() -> CallSession?`
- `_toggleBlock(bool blocked) -> Future<void>`
- `_toggleArchivedForSelected() -> Future<void>`
- `_toggleImportantForSelected() -> Future<void>`
- `_toggleWarningForSelected() -> Future<void>`
- `_toggleForwardForSelected() -> Future<void>`
- `_addCallNoteForSelected(String text) -> Future<void>`
- `_deleteCallNoteForSelected(String noteId) -> Future<void>`
- `_addCallNoteForCall(String callId, String text) -> Future<void>`
- `_deleteCallNoteForCall(String callId, String noteId) -> Future<void>`
- `_openCustomerPageForCall(CallSession target) -> Future<void>`
- `_reloadCallsForCustomer(String callerNumber) -> Future<List<CallSession>>`
- `_saveReview(bool helpful, int score, String? note) -> Future<void>`
- `_maskNumber(String value) -> String`
- `_setPage(int index) -> void`
- `_openLiveCallFromDashboard(String callId) -> void`
- `_openHistoryCallFromDashboard(String callId) -> void`
- `build(BuildContext context) -> Widget`
- `_buildHeader() -> Widget`
- `_buildPageTab(int index, bool isDark) -> Widget`

Zweck: zentraler Orchestrator für Admin-State, Navigation und API-Aufrufe.

### `lib/frontend/admin/pages/dashboard/dashboard_page.dart`

- `createState() -> State<DashboardPage>`
- `_isCurrentlyActiveCall(CallSession call) -> bool`
- `_isEndedCall(CallSession call) -> bool`
- `_formatDuration(int totalSec) -> String`
- `build(BuildContext context) -> Widget`
- `_panelDecoration(bool isDark) -> BoxDecoration`

Zusätzliche interne Widget-`build(...)`-Funktionen in Teilkomponenten:
- `_EnterpriseOverviewPanel.build`
- `_LiveCallsPreview.build`
- `_HistoryPreview.build`
- `_ScoreTile.build`
- `_LoadBar.build`
- `_InfoBanner.build`

### `lib/frontend/admin/pages/live_calls/live_calls_page.dart`

- `createState() -> State<LiveCallsPage>`
- `_isCurrentlyActiveCall(CallSession call) -> bool`
- `_isEndedCall(CallSession call) -> bool`
- `_isArchivedCall(CallSession call) -> bool`
- `_displayCalls() -> List<CallSession>`
- `build(BuildContext context) -> Widget`
- `_toolbarActionButton(...) -> Widget`
- `_sortDropdown(BuildContext context) -> Widget`
- `_formatDuration(int totalSec) -> String`
- `_formatTime(DateTime value) -> String`
- `_formatDateTime(DateTime value) -> String`

Weitere Widget-`build(...)`-Funktionen:
- `_CallOverviewLayout.build`
- `_MetaPill.build`

### `lib/frontend/admin/pages/customer/customer_profile_page.dart`

- `createState() -> State<CustomerProfilePage>`
- `_sortedCalls() -> List<CallSession>`
- `_selectedCall() -> CallSession?`
- `_totalTokens() -> int`
- `_avgDurationSec() -> int`
- `initState() -> void`
- `dispose() -> void`
- `_formatDate(DateTime value) -> String`
- `_formatDuration(int totalSec) -> String`
- `_assistantDisplayName(String raw) -> String`
- `_reloadCalls() -> Future<void>`
- `_addNoteToSelectedCall(String note) -> Future<void>`
- `_deleteNoteFromSelectedCall(String noteId) -> Future<void>`
- `build(BuildContext context) -> Widget`
- `_buildHeader(bool isDark) -> Widget`
- `_buildStats(bool isDark) -> Widget`
- `_statCard(String label, String value, IconData icon, bool isDark) -> Widget`
- `_buildCallsTab(CallSession selected, bool isDark) -> Widget`
- `_buildCallListPanel(bool isDark, CallSession selected) -> Widget`
- `_buildCallDetailPanel(CallSession selected, bool isDark) -> Widget`
- `_metaPill(String text, bool isDark) -> Widget`

### `lib/frontend/admin/pages/moderation/moderation_page.dart`

- `build(BuildContext context) -> Widget`
  - Input: `context`
  - Output: Moderationsliste
  - Zweck: blockierte Nummern verwalten.

### `lib/frontend/admin/pages/api_control/api_control_page.dart`

- `createState() -> State<ApiControlPage>`
- `initState() -> void`
- `dispose() -> void`
- `_startAutoRefreshLoop() -> Future<void>`
- `build(BuildContext context) -> Widget`
- `_kv(String key, String value) -> Widget`
- `_chip({required String label, required String value, required Color color}) -> Widget`

Zweck: Monitoring/Server-Status inkl. periodischem Polling.

### `lib/frontend/admin/pages/voice_api/voice_api_page.dart`

- `build(BuildContext context) -> Widget`
  - Input: `context`
  - Output: Konfig-Form
  - Zweck: Voice/Twilio-Umgebungswerte pflegen + validieren.

### `lib/frontend/admin/widgets/admin_common_widgets.dart`

Komponenten-Funktionen:
- `MetricCard.build(BuildContext context) -> Widget`
- `StatusBadge.build(BuildContext context) -> Widget`
- `LatencyBadge.build(BuildContext context) -> Widget`
- `LoadingState.build(BuildContext context) -> Widget`
- `ConnectionStatusChip.build(BuildContext context) -> Widget`
- `EnvField.build(BuildContext context) -> Widget`

### `lib/frontend/admin/widgets/call_detail_panel.dart`

- `createState() -> State<CallDetailPanel>`
- `_normalizedTranscript(...) -> List<TranscriptTurn>`
- `initState() -> void`
- `didUpdateWidget(...) -> void`
- `dispose() -> void`
- `_hydrateReviewValues() -> void`
- `_initAudio() -> void`
- `_disposeAudio() -> void`
- `_timelineDurationSec() -> int`
- `_turnStartSec(int index) -> int`
- `_turnEndSec(int index) -> int`
- `_findActiveTurnIndex(double positionSec) -> int`
- `_startTicker() -> void`
- `_togglePlayback() -> void`
- `_showQuickActions(BuildContext context) -> Future<void>`
- `_handleQuickAction(String? action) -> Future<void>`
- `_seekTo(double seconds) -> void`
- `_timelineToAudioSec(double timelineSec) -> double`
- `_audioPositionToTimelineSec(double audioSec) -> double`
- `_formatClock(double totalSec) -> String`
- `_formatDateTime(DateTime value) -> String`
- `_assistantDisplayName(String raw) -> String`
- `build(BuildContext context) -> Widget`
- `_buildMainTabBody(BuildContext context, CallSession call, bool isDark) -> Widget`
- `_buildTranscriptAndAudio(BuildContext context, CallSession call, bool isDark) -> Widget`
- `_buildNotesTab(BuildContext context, CallSession call, bool isDark) -> Widget`
- `_buildAudioTrack(CallSession call, bool isDark, List<TranscriptTurn> transcript) -> Widget`
- `_buildTimelineMarkers(...) -> List<_TimelineMarker>`
- `_buildTabStrip(bool isDark, {bool compact = false}) -> Widget`
- `_waveformForCall(CallSession call, {int points = 220}) -> List<double>`
- `_stableHash(String input) -> int`
- `_buildSidePanel(BuildContext context, CallSession call, bool isDark) -> Widget`
- `_panelSection(...) -> Widget`
- `_metaRow(String label, String value, bool isDark) -> Widget`
- `_quickAction(...) -> Widget`
- `_buildLiveInfo(bool isDark) -> Widget`
- `_infoCard(String title, String value, bool isDark) -> Widget`
- `_toolButton(String label, Color color, VoidCallback onPressed) -> Widget`
- `_formatDuration(int totalSec) -> String`
- `_exportCallPdf() -> Future<void>`
- `_WaveformPainter.paint(Canvas canvas, Size size) -> void`
- `_WaveformPainter.shouldRepaint(covariant _WaveformPainter oldDelegate) -> bool`

Zweck: tiefste Detailansicht eines Calls mit Transcript, Audio, Timeline, Notes, Review, PDF-Export.

### `backend/app.py`

Hilfs-/DB-Funktionen:
- `_resolve_database_url() -> str`
- `_now_iso() -> str`
- `_to_iso_datetime(value: Any) -> str`
- `_status_to_dashboard(status: str | None) -> str`
- `_map_call_record_to_session(record: dict[str, Any]) -> dict[str, Any>`
- `_fetch_call_records_mapped() -> list[dict[str, Any]]`
- `_db_health() -> dict[str, Any>`
- `_status_snapshot() -> dict[str, Any>`
- `_fallback_live_call() -> list[dict[str, Any]]`
- `_fallback_history_call() -> list[dict[str, Any]]`
- `_health_probe(url: str) -> dict[str, Any>`
- `_default_call() -> dict[str, Any>`
- `_db_conn() -> Iterator[Any>`
- `_db_bootstrap() -> None`
- `_get_voice_settings() -> dict[str, Any>`
- `_set_voice_settings(payload: dict[str, Any]) -> None`
- `_get_sync_status() -> dict[str, Any>`
- `_set_sync_status(payload: dict[str, Any]) -> None`
- `_get_all_calls() -> list[dict[str, Any]]`
- `_upsert_calls(calls: list[dict[str, Any]]) -> None`
- `_update_call(call_id: str, mutate: Callable[[dict[str, Any]], None]) -> bool`
- `_recording_call_ids() -> set[str>`
- `_get_recording_bytes(call_id: str) -> bytes | None`
- `_upsert_recording(call_id: str, audio: bytes) -> None`
- `_calls_with_db_recording_urls(calls: list[dict[str, Any]]) -> list[dict[str, Any]]`
- `_to_iso(value: str | None) -> str | None`
- `_twilio_get_json(...) -> dict[str, Any]`
- `_sync_calls_from_twilio() -> None`

HTTP-Endpunkte:
- `root() -> dict[str, str]` (`GET /`)
- `health() -> dict[str, str]` (`GET /health`)
- `save_voice_config(payload: VoiceApiSettings) -> dict[str, bool]` (`POST /admin/integrations/voice/config`)
- `verify_voice(payload: VoiceApiSettings) -> dict[str, Any]` (`POST /admin/integrations/voice/verify`)
- `live_calls() -> list[dict[str, Any]]` (`GET /admin/calls/live`)
- `history_calls() -> list[dict[str, Any]]` (`GET /admin/calls/history`)
- `stream_call_recording(call_id: str) -> Response` (`GET /admin/calls/{call_id}/recording`)
- `upload_call_recording(call_id: str, file: UploadFile) -> dict[str, bool]` (`POST /admin/calls/{call_id}/recording`)
- `source_status() -> dict[str, Any]` (`GET /admin/integrations/voice/source-status`)
- `server_status() -> dict[str, Any]` (`GET /admin/server/status`)
- `server_stop() -> dict[str, Any]` (`POST /admin/server/stop`)
- `_shutdown_later() -> None` (interner Thread-Helfer in `server_stop`)
- `block_number(payload: ModerationPayload) -> dict[str, bool]` (`POST /admin/moderation/block-number`)
- `unblock_number(payload: ModerationPayload) -> dict[str, bool]` (`POST /admin/moderation/unblock-number`)
- `set_internal_rating(call_id: str, payload: RatingPayload) -> dict[str, bool]` (`POST /admin/calls/{call_id}/internal-rating`)

## 3) Kompletter MVP-Aufbau der App

### Frontend (Flutter Web, Root `apps/admin-web/`)

- Root: `lib/main.dart`
- Admin Shell: `lib/frontend/admin/admin_shell_page.dart`
- Seiten (unter `lib/frontend/admin/pages/`):
  - `dashboard/dashboard_page.dart` (KPIs, Live/History Preview)
  - `live_calls/live_calls_page.dart` (aktive/historische Calls + Detailpanel)
  - `moderation/moderation_page.dart` (Moderationsansicht)
  - `api_control/api_control_page.dart` (Monitoring + Control)
  - `voice_api/voice_api_page.dart` (Twilio/Voice Konfiguration)
  - `customer/customer_profile_page.dart` (Kundenhistorie)
- Spezielle Features:
  - `lib/frontend/admin/widgets/call_detail_panel.dart` (Audio/Transcript/Review/Notizen/PDF)
  - `lib/features/claims/claims_flow_page.dart` (MVP-Flow für Anspruchsprüfung)

### Domain und Services

- Datenmodelle in `lib/domain/admin_models.dart` und `lib/domain/claims_models.dart`
- Rule Engine in `lib/domain/rules/eligibility_engine.dart`
- Services:
  - `lib/services/call_local_store.dart` (lokale Overrides)
  - `lib/services/pdf/pdf_export_service.dart` (Export)
  - `lib/services/forms/guided_forms.dart` (Fragenlogik)
  - `lib/services/ai/ai_helper.dart` (optionale KI-Vereinfachung)

### API-Abstraktion

- Vertragsinterface: `lib/backend/admin_api/admin_api_contract.dart` (`AdminApiContract`)
- Implementierung:
  - `lib/backend/admin_api/live_admin_api.dart` (`LiveAdminApi`, HTTP/FastAPI)
  - `lib/backend/admin_api/mock_admin_api.dart` (`MockAdminApi`, Asset + In-Memory)

### Backend (FastAPI)

- API in `backend/app.py`
- Persistenz über PostgreSQL-Tabellen:
  - `voice_settings`
  - `twilio_sync`
  - `calls`
  - `call_recordings`
  - optional `call_records` (wenn vorhanden als Primärquelle)

## 4) Wie das Frontend auf die DB zugreift (Laden + Anzeigen)

### Ablauf A: Calls laden und anzeigen

1. `main.dart` instanziiert `AdminShellPage(api: LiveAdminApi())`.
2. `AdminShellPage._loadCalls()` ruft `api.getCalls()`.
3. `LiveAdminApi.getCalls()` lädt parallel:
   - `GET /admin/calls/live`
   - `GET /admin/calls/history`
4. Backend-Endpunkte `live_calls()`/`history_calls()` lesen Daten aus DB:
   - bevorzugt `call_records` (falls verfügbar)
   - sonst Sync aus externer Voice-Quelle via `_sync_calls_from_twilio()` und Cache in `calls`
5. Antwort wird in `LiveAdminApi` zu `CallSession` gemappt.
6. Flutter rendert die Daten in:
   - `DashboardPage` (KPIs/Previews)
   - `LiveCallsPage` + `CallDetailPanel` (Liste + Detail)
   - `CustomerProfilePage` (kundenbezogene Historie)

### Ablauf B: Moderation und interne Bewertung

- Block/Unblock:
  - UI-Action -> `AdminShellPage._toggleBlock`
  - API-Call -> `/admin/moderation/block-number` oder `/admin/moderation/unblock-number`
  - Backend mutiert DB (`calls`), UI lädt neu.
- Review speichern:
  - UI-Action -> `AdminShellPage._saveReview`
  - API-Call -> `/admin/calls/{id}/internal-rating`
  - Backend schreibt `internalReview` in DB, UI lädt neu.

### Ablauf C: Voice-Config und Health

- Konfiguration:
  - `saveVoiceApiSettings` -> `/admin/integrations/voice/config` -> DB `voice_settings`
- Verifizieren:
  - `verifyVoiceApiConnection` -> `/admin/integrations/voice/verify`
- Monitoring:
  - `getServerStatus` -> `/admin/server/status`
  - `getTwilioSourceStatus` -> `/admin/integrations/voice/source-status`
  - `pingHealth` -> `/health`

## 5) Mock vs Live (wichtig für MVP-Betrieb)

- Live ist aktiv, weil in `main.dart` `LiveAdminApi()` genutzt wird.
- Mock ist vorhanden (`MockAdminApi`) und nutzt `apps/admin-web/assets/mock/admin/calls.json`.
- Wechsel erfolgt zentral in `main.dart` durch Austausch des API-Adapters.

## 6) Offene technische Beobachtung

- Lokale Overrides über `CallLocalStore` (archiviert, wichtig, Warnung, Notizen etc.) sind implementiert.
- Für die Gesamtanzeige wird in `AdminShellPage._loadCalls()` aktuell direkt `api.getCalls()` geladen; ein globaler Merge-Schritt mit `mergeCalls(...)` ist nicht überall sichtbar.
- Falls gewünscht, kann als nächster Schritt ein konsistenter Merge-Pfad dokumentiert und/oder implementiert werden.

