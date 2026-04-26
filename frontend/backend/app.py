from __future__ import annotations

import base64
import json
import os
import threading
from contextlib import contextmanager
from pathlib import Path
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from typing import Any, Callable, Iterator
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request as UrlRequest, urlopen

import psycopg2
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel, Field


def _resolve_database_url() -> str:
    """Laedt optional backend/.env, liest DATABASE_URL, normalisiert postgres:// fuer libpq/psycopg2."""
    try:
        from dotenv import load_dotenv

        load_dotenv(Path(__file__).resolve().parent / ".env", override=False)
    except ImportError:
        pass
    url = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/ifindappointments").strip()
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://") :]
    return url


SERVER_STARTED_AT = datetime.now(timezone.utc)
DATABASE_URL = _resolve_database_url()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _to_iso_datetime(value: Any) -> str:
    if isinstance(value, datetime):
        dt = value if value.tzinfo else value.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc).isoformat()
    return _now_iso()


def _status_to_dashboard(status: str | None) -> str:
    s = (status or "").strip().upper()
    if s in {"ACTIVE", "QUEUED", "RINGING", "IN-PROGRESS", "LIVE"}:
        return "live"
    if s in {"COMPLETED", "ENDED", "CANCELLED", "UNKNOWN"}:
        return "completed"
    return "completed"


def _map_call_record_to_session(record: dict[str, Any]) -> dict[str, Any]:
    started_at = record.get("call_start")
    ended_at = record.get("call_end")
    started_at_iso = _to_iso_datetime(started_at)
    ended_at_iso = _to_iso_datetime(ended_at) if ended_at else None
    duration_sec = 0
    if isinstance(started_at, datetime):
        end_for_duration = ended_at if isinstance(ended_at, datetime) else datetime.now(timezone.utc)
        if end_for_duration.tzinfo is None:
            end_for_duration = end_for_duration.replace(tzinfo=timezone.utc)
        start_for_duration = started_at if started_at.tzinfo else started_at.replace(tzinfo=timezone.utc)
        duration_sec = max(0, int((end_for_duration - start_for_duration).total_seconds()))

    call_id = str(record.get("call_sid") or f"CALL-FALLBACK-{int(datetime.now().timestamp())}")
    return {
        "id": call_id,
        "callerNumber": record.get("from_phone_number") or "Unbekannt",
        "status": _status_to_dashboard(record.get("status")),
        "startedAt": started_at_iso,
        "endedAt": ended_at_iso,
        "durationSec": duration_sec,
        "assistantId": "hackathon-callagent",
        "metrics": {
            "tokenInput": 0,
            "tokenOutput": 0,
            "tokenTotal": 0,
            "avgLatencyMs": 0,
            "p95LatencyMs": 0,
        },
        "userFeedback": {"rating": 0, "comment": ""},
        "internalReview": {"helpful": False, "score": 0, "note": ""},
        "blocked": False,
        "transcript": [{"role": "system", "text": "Anruf aus call_records geladen", "timestamp": _now_iso()}],
        "recordingUrl": record.get("recording_url") or None,
    }


def _fetch_call_records_mapped() -> list[dict[str, Any]]:
    try:
        with _db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT to_regclass('public.call_records')")
                if cur.fetchone()[0] is None:
                    return []
                cur.execute(
                    """
                    SELECT call_sid, from_phone_number, call_start, call_end, status, recording_url
                    FROM call_records
                    ORDER BY call_start DESC
                    LIMIT 200
                    """
                )
                rows = cur.fetchall()
                mapped = []
                for row in rows:
                    mapped.append(
                        _map_call_record_to_session(
                            {
                                "call_sid": row[0],
                                "from_phone_number": row[1],
                                "call_start": row[2],
                                "call_end": row[3],
                                "status": row[4],
                                "recording_url": row[5],
                            }
                        )
                    )
                return mapped
    except Exception:
        return []


def _db_health() -> dict[str, Any]:
    try:
        with _db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                _ = cur.fetchone()
        return {"connected": True, "error": None}
    except Exception as err:
        return {"connected": False, "error": str(err)}


def _status_snapshot() -> dict[str, Any]:
    records = _fetch_call_records_mapped()
    live_count = sum(1 for c in records if c.get("status") == "live")
    history_count = sum(1 for c in records if c.get("status") == "completed")
    latest_started = records[0].get("startedAt") if records else None

    settings = _get_voice_settings()
    sid = str(settings.get("twilioAccountSid", "")).strip()
    token = str(settings.get("twilioAuthToken", "")).strip()
    phone = str(settings.get("twilioPhoneNumber", "")).strip()
    deepgram = str(settings.get("deepgramApiKey", "")).strip()
    local_server_url = str(settings.get("localServerUrl", "")).strip()

    return {
        "updatedAt": _now_iso(),
        "db": _db_health(),
        "calls": {
            "totalFromCallRecords": len(records),
            "liveCount": live_count,
            "historyCount": history_count,
            "latestStartedAt": latest_started,
        },
        "voiceConfig": {
            "localServerUrl": local_server_url,
            "twilioSidSet": bool(sid),
            "twilioAuthTokenSet": bool(token),
            "twilioPhoneSet": bool(phone),
            "deepgramKeySet": bool(deepgram),
            "twilioSidHint": f"{sid[:6]}...{sid[-4:]}" if sid and len(sid) > 10 else sid,
        },
    }


def _fallback_live_call() -> list[dict[str, Any]]:
    return [_default_call()]


def _fallback_history_call() -> list[dict[str, Any]]:
    call = _default_call()
    call["id"] = "CALL-HISTORY-FALLBACK-1"
    call["status"] = "completed"
    call["endedAt"] = _now_iso()
    call["durationSec"] = 75
    return [call]


def _health_probe(url: str) -> dict[str, Any]:
    if not url:
        return {"configured": False, "running": False, "detail": "LOCAL_SERVER_URL fehlt"}
    endpoint = f"{url.rstrip('/')}/health"
    try:
        req = UrlRequest(endpoint)
        req.add_header("Accept", "application/json")
        with urlopen(req, timeout=4) as res:
            body = res.read().decode("utf-8")
            payload = json.loads(body) if body else {}
            status = str(payload.get("status", "")).lower()
            running = status in {"ok", "healthy"}
            return {
                "configured": True,
                "running": running,
                "url": url,
                "healthEndpoint": endpoint,
                "detail": payload if payload else "health response empty",
            }
    except Exception as err:
        return {
            "configured": True,
            "running": False,
            "url": url,
            "healthEndpoint": endpoint,
            "detail": str(err),
        }


def _default_call() -> dict[str, Any]:
    return {
        "id": "CALL-2001",
        "callerNumber": "+4915211112222",
        "status": "live",
        "startedAt": _now_iso(),
        "endedAt": None,
        "durationSec": 180,
        "assistantId": "pipecat-local-1",
        "metrics": {
            "tokenInput": 560,
            "tokenOutput": 420,
            "tokenTotal": 980,
            "avgLatencyMs": 850,
            "p95LatencyMs": 1600,
        },
        "userFeedback": {"rating": 0, "comment": ""},
        "internalReview": {"helpful": False, "score": 0, "note": ""},
        "blocked": False,
        "transcript": [{"role": "system", "text": "Anruf gestartet", "timestamp": _now_iso()}],
    }


@contextmanager
def _db_conn() -> Iterator[Any]:
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def _db_bootstrap() -> None:
    default_local_server_url = os.getenv("LOCAL_SERVER_URL", "").strip()
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS voice_settings (
                    id SMALLINT PRIMARY KEY,
                    payload JSONB NOT NULL DEFAULT '{}'::jsonb
                );
                CREATE TABLE IF NOT EXISTS twilio_sync (
                    id SMALLINT PRIMARY KEY,
                    payload JSONB NOT NULL DEFAULT '{}'::jsonb
                );
                CREATE TABLE IF NOT EXISTS calls (
                    id TEXT PRIMARY KEY,
                    payload JSONB NOT NULL
                );
                CREATE TABLE IF NOT EXISTS call_recordings (
                    call_id TEXT PRIMARY KEY,
                    audio BYTEA NOT NULL,
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                );
                """
            )
            cur.execute(
                """
                INSERT INTO voice_settings(id, payload)
                VALUES (1, %s::jsonb)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    json.dumps(
                        {
                            "twilioAccountSid": "",
                            "twilioAuthToken": "",
                            "localServerUrl": default_local_server_url,
                            "twilioPhoneNumber": "",
                            "deepgramApiKey": "",
                        }
                    ),
                ),
            )
            cur.execute(
                """
                INSERT INTO twilio_sync(id, payload)
                VALUES (1, %s::jsonb)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    json.dumps(
                        {
                            "enabled": False,
                            "lastSyncAt": None,
                            "lastError": None,
                            "lastFetchedCount": 0,
                        }
                    ),
                ),
            )
def _get_voice_settings() -> dict[str, Any]:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT payload FROM voice_settings WHERE id = 1")
            row = cur.fetchone()
            return row[0] if row and row[0] else {}


def _set_voice_settings(payload: dict[str, Any]) -> None:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO voice_settings(id, payload)
                VALUES (1, %s::jsonb)
                ON CONFLICT (id) DO UPDATE SET payload = EXCLUDED.payload
                """,
                (json.dumps(payload),),
            )


def _get_sync_status() -> dict[str, Any]:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT payload FROM twilio_sync WHERE id = 1")
            row = cur.fetchone()
            return row[0] if row and row[0] else {}


def _set_sync_status(payload: dict[str, Any]) -> None:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO twilio_sync(id, payload)
                VALUES (1, %s::jsonb)
                ON CONFLICT (id) DO UPDATE SET payload = EXCLUDED.payload
                """,
                (json.dumps(payload),),
            )


def _get_all_calls() -> list[dict[str, Any]]:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT payload FROM calls")
            return [row[0] for row in cur.fetchall()]


def _upsert_calls(calls: list[dict[str, Any]]) -> None:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM calls")
            for c in calls:
                cur.execute(
                    "INSERT INTO calls(id, payload) VALUES (%s, %s::jsonb) ON CONFLICT (id) DO UPDATE SET payload = EXCLUDED.payload",
                    (c["id"], json.dumps(c)),
                )


def _update_call(call_id: str, mutate: Callable[[dict[str, Any]], None]) -> bool:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT payload FROM calls WHERE id = %s", (call_id,))
            row = cur.fetchone()
            if not row:
                return False
            call = row[0]
            mutate(call)
            cur.execute("UPDATE calls SET payload = %s::jsonb WHERE id = %s", (json.dumps(call), call_id))
            return True


def _recording_call_ids() -> set[str]:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT call_id FROM call_recordings")
            return {row[0] for row in cur.fetchall()}


def _get_recording_bytes(call_id: str) -> bytes | None:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT audio FROM call_recordings WHERE call_id = %s", (call_id,))
            row = cur.fetchone()
            if not row or row[0] is None:
                return None
            raw = row[0]
            if isinstance(raw, memoryview):
                return raw.tobytes()
            return bytes(raw)


def _upsert_recording(call_id: str, audio: bytes) -> None:
    with _db_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO call_recordings(call_id, audio, updated_at)
                VALUES (%s, %s, NOW())
                ON CONFLICT (call_id) DO UPDATE SET
                    audio = EXCLUDED.audio,
                    updated_at = NOW()
                """,
                (call_id, audio),
            )


def _calls_with_db_recording_urls(calls: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Setzt recordingUrl auf den internen Streaming-Pfad, wenn Rohdaten in call_recordings liegen."""
    ids = _recording_call_ids()
    if not ids:
        return calls
    out: list[dict[str, Any]] = []
    for c in calls:
        cc = dict(c)
        cid = cc.get("id")
        if isinstance(cid, str) and cid in ids:
            cc["recordingUrl"] = f"/admin/calls/{cid}/recording"
        out.append(cc)
    return out


def _to_iso(value: str | None) -> str | None:
    if not value:
        return None
    try:
        dt = parsedate_to_datetime(value)
        return dt.astimezone(timezone.utc).isoformat()
    except Exception:
        return None


def _twilio_get_json(
    account_sid: str,
    auth_token: str,
    resource_path: str,
    params: dict[str, Any] | None = None,
) -> dict[str, Any]:
    base_url = f"https://api.twilio.com/2010-04-01/Accounts/{account_sid}"
    query = f"?{urlencode(params)}" if params else ""
    url = f"{base_url}{resource_path}{query}"

    token = f"{account_sid}:{auth_token}".encode("utf-8")
    auth_header = "Basic " + base64.b64encode(token).decode("ascii")
    req = UrlRequest(url)
    req.add_header("Authorization", auth_header)
    req.add_header("Accept", "application/json")

    with urlopen(req, timeout=12) as res:
        body = res.read().decode("utf-8")
        return json.loads(body)


def _sync_calls_from_twilio() -> None:
    settings = _get_voice_settings()
    sid = settings.get("twilioAccountSid", "")
    token = settings.get("twilioAuthToken", "")
    phone = settings.get("twilioPhoneNumber", "")
    if not sid or not token:
        status = _get_sync_status()
        status["enabled"] = False
        status["lastError"] = "Twilio-Credentials fehlen"
        status["lastSyncAt"] = _now_iso()
        _set_sync_status(status)
        return

    try:
        raw = _twilio_get_json(
            sid,
            token,
            "/Calls.json",
            {"PageSize": 50, "To": phone} if phone else {"PageSize": 50},
        )
        twilio_calls = raw.get("calls", [])
        existing = {c["id"]: c for c in _get_all_calls()}
        mapped: list[dict[str, Any]] = []

        for c in twilio_calls:
            call_id = c.get("sid")
            if not call_id:
                continue
            prev = existing.get(call_id, {})
            started = _to_iso(c.get("start_time")) or _to_iso(c.get("date_created")) or _now_iso()
            ended = _to_iso(c.get("end_time"))
            duration_raw = c.get("duration")
            try:
                duration = int(duration_raw) if duration_raw is not None else 0
            except Exception:
                duration = 0

            mapped.append(
                {
                    "id": call_id,
                    "callerNumber": c.get("from") or "Unbekannt",
                    "status": c.get("status", "completed"),
                    "startedAt": started,
                    "endedAt": ended,
                    "durationSec": duration,
                    "assistantId": "twilio-live",
                    "metrics": prev.get(
                        "metrics",
                        {
                            "tokenInput": 0,
                            "tokenOutput": 0,
                            "tokenTotal": 0,
                            "avgLatencyMs": 0,
                            "p95LatencyMs": 0,
                        },
                    ),
                    "userFeedback": prev.get("userFeedback", {"rating": 0, "comment": ""}),
                    "internalReview": prev.get(
                        "internalReview",
                        {"helpful": False, "score": 0, "note": ""},
                    ),
                    "blocked": prev.get("blocked", False),
                    "transcript": prev.get(
                        "transcript",
                        [{"role": "system", "text": "Call aus Twilio synchronisiert", "timestamp": _now_iso()}],
                    ),
                }
            )

        _upsert_calls(mapped)
        _set_sync_status(
            {
                "enabled": True,
                "lastSyncAt": _now_iso(),
                "lastError": None,
                "lastFetchedCount": len(mapped),
            }
        )
    except (HTTPError, URLError, TimeoutError, ValueError) as err:
        _set_sync_status(
            {
                "enabled": False,
                "lastError": str(err),
                "lastSyncAt": _now_iso(),
                "lastFetchedCount": 0,
            }
        )


_db_bootstrap()

app = FastAPI(title="Call Agent Backend", version="0.2.0")

# Hackathon-friendly CORS (Flutter Web localhost + ngrok + wildcard fallback)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class VoiceApiSettings(BaseModel):
    twilioAccountSid: str
    twilioAuthToken: str
    localServerUrl: str
    twilioPhoneNumber: str
    deepgramApiKey: str


class ModerationPayload(BaseModel):
    callId: str
    reason: str | None = "Manuell blockiert"


class RatingPayload(BaseModel):
    helpful: bool
    score: int = Field(ge=0, le=10)
    note: str = ""


@app.get("/")
def root() -> dict[str, str]:
    return {"ok": "true", "service": "call-agent-backend"}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.post("/admin/integrations/voice/config")
def save_voice_config(payload: VoiceApiSettings) -> dict[str, bool]:
    _set_voice_settings(payload.model_dump())
    return {"saved": True}


@app.post("/admin/integrations/voice/verify")
def verify_voice(payload: VoiceApiSettings) -> dict[str, Any]:
    sid_ok = payload.twilioAccountSid.startswith("AC") and len(payload.twilioAccountSid) == 34
    token_ok = len(payload.twilioAuthToken) >= 16
    phone_ok = payload.twilioPhoneNumber.startswith("+") and len(payload.twilioPhoneNumber) >= 8
    url_ok = payload.localServerUrl.startswith("https://") or payload.localServerUrl.startswith("http://")
    deepgram_ok = len(payload.deepgramApiKey) >= 20

    ok = sid_ok and token_ok and phone_ok and url_ok and deepgram_ok
    if not ok:
        return {"ok": False, "source": "validation", "detail": "Formatpruefung fehlgeschlagen"}
    try:
        _twilio_get_json(payload.twilioAccountSid, payload.twilioAuthToken, ".json")
        _set_voice_settings(payload.model_dump())
        return {"ok": True, "source": "twilio"}
    except Exception as err:
        return {"ok": False, "source": "twilio", "detail": str(err)}


@app.get("/admin/calls/live")
def live_calls() -> list[dict[str, Any]]:
    mapped = _fetch_call_records_mapped()
    if mapped:
        live = [c for c in mapped if c.get("status") == "live"]
        if live:
            return live
    _sync_calls_from_twilio()
    live_statuses = {"queued", "ringing", "in-progress", "live"}
    filtered = [c for c in _get_all_calls() if c.get("status") in live_statuses]
    if filtered:
        return _calls_with_db_recording_urls(filtered)
    return []


@app.get("/admin/calls/history")
def history_calls() -> list[dict[str, Any]]:
    mapped = _fetch_call_records_mapped()
    if mapped:
        history = [c for c in mapped if c.get("status") == "completed"]
        if history:
            return history
    _sync_calls_from_twilio()
    filtered = [c for c in _get_all_calls() if c.get("status") == "completed"]
    if filtered:
        return _calls_with_db_recording_urls(filtered)
    return []


@app.get("/admin/calls/{call_id}/recording")
def stream_call_recording(call_id: str) -> Response:
    """Liefert gespeicherte Audiodaten als MPEG-4-Audio (M4A) fuer Browser-<audio>-Elemente."""
    data = _get_recording_bytes(call_id)
    if not data:
        raise HTTPException(status_code=404, detail="Keine Aufnahme fuer diesen Anruf")
    safe_name = "".join(ch for ch in call_id if ch.isalnum() or ch in ("-", "_")) or "recording"
    return Response(
        content=data,
        media_type="audio/mp4",
        headers={
            "Content-Disposition": f'inline; filename="{safe_name}.m4a"',
            "Cache-Control": "private, max-age=3600",
        },
    )


@app.post("/admin/calls/{call_id}/recording")
async def upload_call_recording(call_id: str, request: Request) -> dict[str, Any]:
    """Rohbytes (z. B. fertiges M4A) in call_recordings speichern — fuer Tests oder Import-Pipelines."""
    body = await request.body()
    if not body:
        raise HTTPException(status_code=400, detail="Leerer Body")
    _upsert_recording(call_id, body)
    return {"saved": True, "bytes": len(body)}


@app.get("/admin/integrations/voice/source-status")
def source_status() -> dict[str, Any]:
    # Force a fresh check so the API status page reflects current Twilio connectivity.
    _sync_calls_from_twilio()
    return _get_sync_status()


@app.get("/admin/server/status")
def server_status() -> dict[str, Any]:
    uptime = int((datetime.now(timezone.utc) - SERVER_STARTED_AT).total_seconds())
    voice_settings = _get_voice_settings()
    callagent_url = str(voice_settings.get("localServerUrl", "")).strip()
    callagent_status = _health_probe(callagent_url)
    snapshot = _status_snapshot()
    return {
        "running": True,
        "pid": os.getpid(),
        "uptimeSec": uptime,
        "startedAt": SERVER_STARTED_AT.isoformat(),
        "callagentPython": callagent_status,
        "snapshot": snapshot,
    }


@app.post("/admin/server/stop")
def server_stop() -> dict[str, Any]:
    def _shutdown_later() -> None:
        os._exit(0)

    timer = threading.Timer(1.0, _shutdown_later)
    timer.daemon = True
    timer.start()
    return {"accepted": True, "message": "Server stop requested"}


@app.post("/admin/moderation/block-number")
def block_number(payload: ModerationPayload) -> dict[str, bool]:
    changed = _update_call(
        payload.callId,
        lambda call: (
            call.__setitem__("blocked", True),
            call.setdefault("internalReview", {}).__setitem__("note", payload.reason or "Blockiert"),
        ),
    )
    if not changed:
        raise HTTPException(status_code=404, detail="Call nicht gefunden")
    return {"blocked": True}


@app.post("/admin/moderation/unblock-number")
def unblock_number(payload: ModerationPayload) -> dict[str, bool]:
    changed = _update_call(payload.callId, lambda call: call.__setitem__("blocked", False))
    if not changed:
        raise HTTPException(status_code=404, detail="Call nicht gefunden")
    return {"blocked": False}


@app.post("/admin/calls/{call_id}/internal-rating")
def set_internal_rating(call_id: str, payload: RatingPayload) -> dict[str, bool]:
    changed = _update_call(call_id, lambda call: call.__setitem__("internalReview", payload.model_dump()))
    if not changed:
        raise HTTPException(status_code=404, detail="Call nicht gefunden")
    return {"saved": True}

