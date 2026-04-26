import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/admin_models.dart';
import 'admin_api_contract.dart';

class MockAdminApi implements AdminApiContract {
  List<CallSession>? _cache;
  VoiceApiSettings _voiceApiSettings = VoiceApiSettings.empty();
  bool _isVoiceApiConnected = false;

  Future<List<CallSession>> _loadCalls() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/mock/admin/calls.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final calls = list
        .map((item) => CallSession.fromJson(item as Map<String, dynamic>))
        .toList();
    _cache = _withAdditionalDemoAccounts(calls);
    return _cache!;
  }

  List<CallSession> _withAdditionalDemoAccounts(List<CallSession> source) {
    if (source.length >= 14) return source;
    final expanded = List<CallSession>.from(source);
    final templates = source.where((call) => !call.blocked).toList();
    if (templates.isEmpty) return expanded;

    final missing = 14 - expanded.length;
    for (var i = 0; i < missing; i++) {
      final template = templates[i % templates.length];
      final cloneIndex = i + 1;
      final startedAt = template.startedAt.subtract(Duration(minutes: 5 * cloneIndex));
      final transcript = template.transcript
          .asMap()
          .entries
          .map(
            (entry) => TranscriptTurn(
              role: entry.value.role,
              text: '${entry.value.text} [Demo ${cloneIndex.toString().padLeft(2, '0')}]',
              timestamp: startedAt.add(Duration(seconds: 4 + (entry.key * 18))),
            ),
          )
          .toList();
      expanded.add(
        CallSession(
          id: 'CALL-D${cloneIndex.toString().padLeft(3, '0')}',
          callerNumber: '+49157${(8000000 + cloneIndex).toString()}',
          status: cloneIndex % 3 == 0 ? 'live' : 'ended',
          startedAt: startedAt,
          endedAt: cloneIndex % 3 == 0
              ? null
              : startedAt.add(Duration(seconds: template.durationSec)),
          durationSec: template.durationSec + (cloneIndex * 7),
          assistantId: template.assistantId,
          metrics: CallMetrics(
            tokenInput: template.metrics.tokenInput + (cloneIndex * 20),
            tokenOutput: template.metrics.tokenOutput + (cloneIndex * 15),
            tokenTotal: template.metrics.tokenTotal + (cloneIndex * 35),
            avgLatencyMs: template.metrics.avgLatencyMs + (cloneIndex * 5),
            p95LatencyMs: template.metrics.p95LatencyMs + (cloneIndex * 8),
          ),
          userFeedback: UserFeedback(
            rating: template.userFeedback.rating.clamp(1, 5),
            comment: 'Demo-Account für UI-Tests',
          ),
          internalReview: InternalReview(
            helpful: true,
            score: (6 + (cloneIndex % 4)).clamp(0, 10),
            note: 'Automatisch generierter Demo-Account',
          ),
          blocked: false,
          transcript: transcript,
          recordingUrl: template.recordingUrl,
          marked: false,
          important: false,
          warningActive: false,
          forwardedTo: null,
          notes: const [],
          profile: CallerProfile.empty(),
        ),
      );
    }
    return expanded;
  }

  @override
  Future<List<CallSession>> getCalls() async => _loadCalls();

  @override
  Future<VoiceApiSettings> getVoiceApiSettings() async => _voiceApiSettings;

  @override
  Future<bool> getVoiceApiConnectionStatus() async => _isVoiceApiConnected;

  @override
  Future<bool> verifyVoiceApiConnection(VoiceApiSettings settings) async {
    final hasTwilioSid = settings.twilioAccountSid.startsWith('AC') &&
        settings.twilioAccountSid.length == 34;
    final hasTwilioToken =
        RegExp(r'^[A-Za-z0-9]{32}$').hasMatch(settings.twilioAuthToken);
    final uri = Uri.tryParse(settings.localServerUrl);
    final hasHttpsUrl = uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        uri.scheme == 'https';
    final hasPhoneNumber =
        RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(settings.twilioPhoneNumber);
    final hasDeepgramKey = settings.deepgramApiKey.length >= 20;

    _isVoiceApiConnected = hasTwilioSid &&
        hasTwilioToken &&
        hasHttpsUrl &&
        hasPhoneNumber &&
        hasDeepgramKey;
    return _isVoiceApiConnected;
  }

  @override
  Future<void> saveVoiceApiSettings(VoiceApiSettings settings) async {
    final sameAsCurrent =
        settings.twilioAccountSid == _voiceApiSettings.twilioAccountSid &&
            settings.twilioAuthToken == _voiceApiSettings.twilioAuthToken &&
            settings.localServerUrl == _voiceApiSettings.localServerUrl &&
            settings.twilioPhoneNumber == _voiceApiSettings.twilioPhoneNumber &&
            settings.deepgramApiKey == _voiceApiSettings.deepgramApiKey;
    if (!sameAsCurrent) {
      _isVoiceApiConnected = false;
    }
    _voiceApiSettings = settings;
  }

  @override
  Future<List<CallSession>> getHistoryCalls() async {
    final calls = await _loadCalls();
    return calls.where((c) => c.status == 'ended').toList();
  }

  @override
  Future<List<CallSession>> getLiveCalls() async {
    final calls = await _loadCalls();
    return calls.where((c) => c.status == 'live').toList();
  }

  @override
  Future<void> blockNumber(String callId, String reason) async {
    final calls = await _loadCalls();
    final call = calls.firstWhere((c) => c.id == callId);
    call.blocked = true;
    call.internalReview.note = reason;
  }

  @override
  Future<void> unblockNumber(String callId) async {
    final calls = await _loadCalls();
    final call = calls.firstWhere((c) => c.id == callId);
    call.blocked = false;
  }

  @override
  Future<void> submitInternalReview({
    required String callId,
    required bool helpful,
    required int score,
    required String note,
  }) async {
    final calls = await _loadCalls();
    final call = calls.firstWhere((c) => c.id == callId);
    call.internalReview.helpful = helpful;
    call.internalReview.score = score;
    call.internalReview.note = note;
  }

  @override
  Future<Map<String, dynamic>> getServerStatus() async {
    return {
      'running': true,
      'pid': 'mock',
      'uptimeSec': 0,
      'startedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> getTwilioSourceStatus() async {
    return {
      'enabled': false,
      'lastSyncAt': null,
      'lastError': 'Mock API aktiv',
      'lastFetchedCount': _cache?.length ?? 0,
    };
  }

  @override
  Future<bool> pingHealth() async => true;

  @override
  Future<void> requestServerStop() async {}
}
