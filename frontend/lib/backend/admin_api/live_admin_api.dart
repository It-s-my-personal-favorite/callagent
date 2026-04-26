import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/admin_models.dart';
import 'admin_api_contract.dart';

class LiveAdminApi implements AdminApiContract {
  static const _voiceSettingsStorageKey = 'call_agent_voice_settings';
  static const _voiceConnectionStorageKey = 'call_agent_voice_connected';

  final http.Client _client;

  LiveAdminApi({http.Client? client}) : _client = client ?? http.Client();

  Future<void> _persistVoiceSettings(VoiceApiSettings settings, bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceSettingsStorageKey, jsonEncode(settings.toJson()));
    await prefs.setBool(_voiceConnectionStorageKey, connected);
  }

  Future<VoiceApiSettings> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_voiceSettingsStorageKey);
    if (raw == null || raw.isEmpty) return VoiceApiSettings.empty();
    return VoiceApiSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> _loadConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceConnectionStorageKey) ?? false;
  }

  Future<Map<String, String>> _headers({bool withJson = true}) async {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    };
    if (withJson) headers['Content-Type'] = 'application/json';
    return headers;
  }

  Uri _uri(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  String _resolveBaseUrl(VoiceApiSettings settings) {
    final configured = settings.localServerUrl.trim();
    if (configured.isNotEmpty) return configured;

    final host = Uri.base.host;
    final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
    const localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
    if (localHosts.contains(host)) {
      return '$scheme://$host:7860';
    }
    return 'http://127.0.0.1:7860';
  }

  /// Backend liefert DB-Aufnahmen als Pfad `/admin/calls/.../recording` — für [html.AudioElement] absolut machen.
  String? _absoluteRecordingUrl(String? recordingUrl, String baseUrl) {
    if (recordingUrl == null || recordingUrl.isEmpty) return recordingUrl;
    final u = recordingUrl.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/')) {
      final b = baseUrl.trim();
      if (b.isEmpty) return u;
      final normalized = b.endsWith('/') ? b.substring(0, b.length - 1) : b;
      return '$normalized$u';
    }
    return u;
  }

  CallSession _mapCallWithRecordingBase(Map<String, dynamic> json, String baseUrl) {
    final c = CallSession.fromJson(json);
    final resolved = _absoluteRecordingUrl(c.recordingUrl, baseUrl);
    if (resolved == c.recordingUrl) return c;
    return c.copyWith(recordingUrl: resolved);
  }

  Future<List<dynamic>> _getJsonList(Uri uri) async {
    final res = await _client
        .get(uri, headers: await _headers(withJson: false))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET ${uri.path} fehlgeschlagen (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _getJsonObject(Uri uri) async {
    final res = await _client
        .get(uri, headers: await _headers(withJson: false))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET ${uri.path} fehlgeschlagen (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      return await _client
          .post(uri, headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
    } on http.ClientException catch (e) {
      throw Exception(
        'Request blockiert (CORS/Ngrok/Endpoint): ${e.message}. '
        'Prüfe CORS am Backend und ngrok-Route.',
      );
    }
  }

  @override
  Future<List<CallSession>> getCalls() async {
    await _loadSettings();
    final live = await getLiveCalls();
    final history = await getHistoryCalls();
    final merged = <String, CallSession>{};
    for (final c in [...live, ...history]) {
      merged[c.id] = c;
    }
    return merged.values.toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  @override
  Future<List<CallSession>> getLiveCalls() async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final list = await _getJsonList(_uri(base, '/admin/calls/live'));
    return list
        .map((item) => _mapCallWithRecordingBase(item as Map<String, dynamic>, base))
        .toList();
  }

  @override
  Future<List<CallSession>> getHistoryCalls() async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final list = await _getJsonList(_uri(base, '/admin/calls/history'));
    return list
        .map((item) => _mapCallWithRecordingBase(item as Map<String, dynamic>, base))
        .toList();
  }

  @override
  Future<VoiceApiSettings> getVoiceApiSettings() => _loadSettings();

  @override
  Future<bool> getVoiceApiConnectionStatus() => _loadConnectionStatus();

  @override
  Future<bool> verifyVoiceApiConnection(VoiceApiSettings settings) async {
    if (settings.localServerUrl.isEmpty) return false;
    final res = await _post(
      _uri(settings.localServerUrl, '/admin/integrations/voice/verify'),
      settings.toJson(),
    );
    final statusOk = res.statusCode >= 200 && res.statusCode < 300;
    bool payloadOk = false;
    if (statusOk) {
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        payloadOk = data['ok'] == true;
      } catch (_) {
        payloadOk = false;
      }
    }
    final ok = statusOk && payloadOk;
    await _persistVoiceSettings(settings, ok);
    if (!ok) {
      throw Exception('Verify Endpoint Fehler (${res.statusCode}): ${res.body}');
    }
    return true;
  }

  @override
  Future<void> saveVoiceApiSettings(VoiceApiSettings settings) async {
    await _persistVoiceSettings(settings, false);
    if (settings.localServerUrl.isEmpty) return;
    final res = await _post(
      _uri(settings.localServerUrl, '/admin/integrations/voice/config'),
      settings.toJson(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Konfiguration konnte nicht gespeichert werden (${res.statusCode})');
    }
  }

  @override
  Future<void> blockNumber(String callId, String reason) async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final res = await _post(
      _uri(base, '/admin/moderation/block-number'),
      {'callId': callId, 'reason': reason},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Nummer blockieren fehlgeschlagen (${res.statusCode})');
    }
  }

  @override
  Future<void> unblockNumber(String callId) async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final res = await _post(
      _uri(base, '/admin/moderation/unblock-number'),
      {'callId': callId},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Nummer entsperren fehlgeschlagen (${res.statusCode})');
    }
  }

  @override
  Future<void> submitInternalReview({
    required String callId,
    required bool helpful,
    required int score,
    required String note,
  }) async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final res = await _post(
      _uri(base, '/admin/calls/$callId/internal-rating'),
      {'helpful': helpful, 'score': score, 'note': note},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Interne Bewertung fehlgeschlagen (${res.statusCode})');
    }
  }

  @override
  Future<Map<String, dynamic>> getServerStatus() async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    return _getJsonObject(_uri(base, '/admin/server/status'));
  }

  @override
  Future<Map<String, dynamic>> getTwilioSourceStatus() async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    return _getJsonObject(_uri(base, '/admin/integrations/voice/source-status'));
  }

  @override
  Future<bool> pingHealth() async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final obj = await _getJsonObject(_uri(base, '/health'));
    return obj['status'] == 'healthy';
  }

  @override
  Future<void> requestServerStop() async {
    final settings = await _loadSettings();
    final base = _resolveBaseUrl(settings);
    final res = await _post(_uri(base, '/admin/server/stop'), {});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Server-Stop fehlgeschlagen (${res.statusCode})');
    }
  }
}
