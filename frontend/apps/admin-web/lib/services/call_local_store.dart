import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/admin_models.dart';

const _prefsKey = 'call_agent_call_local_overrides_v1';
const _storeSchemaVersion = 'v2';

class CallLocalStore {
  Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    final payload = decoded['overrides'];
    final source = payload is Map<String, dynamic> ? payload : decoded;
    return source.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  Future<void> saveAll(Map<String, Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _storeSchemaVersion,
      'updatedAt': DateTime.now().toIso8601String(),
      'overrides': data,
    };
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  Future<void> patchCall(String callId, Map<String, dynamic> patch) async {
    final all = await loadAll();
    final prev = Map<String, dynamic>.from(all[callId] ?? {});
    prev.addAll(patch);
    all[callId] = prev;
    await saveAll(all);
  }

  static CallSession mergeWithMap(CallSession base, Map<String, Map<String, dynamic>>? all) {
    if (all == null || all.isEmpty) return base;
    final o = all[base.id];
    if (o == null || o.isEmpty) return base;

    final notesRaw = o['notes'] as List<dynamic>?;
    final notes = notesRaw == null
        ? base.notes
        : notesRaw.map((e) => CallNote.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    final profileRaw = o['profile'];
    final profile = profileRaw == null
        ? base.profile
        : CallerProfile.fromJson(Map<String, dynamic>.from(profileRaw as Map));

    return base.copyWith(
      status: o['status'] as String? ?? base.status,
      marked: o['marked'] as bool? ?? base.marked,
      important: o['important'] as bool? ?? base.important,
      warningActive: o['warningActive'] as bool? ?? base.warningActive,
      updateForwardedTo: o.containsKey('forwardedTo'),
      forwardedTo: o['forwardedTo'] as String?,
      notes: notes,
      profile: profile,
    );
  }

  Future<List<CallSession>> mergeCalls(List<CallSession> calls) async {
    final all = await loadAll();
    return calls.map((c) => mergeWithMap(c, all)).toList();
  }
}
