import '../../domain/admin_models.dart';

abstract class AdminApiContract {
  Future<List<CallSession>> getCalls();
  Future<List<CallSession>> getLiveCalls();
  Future<List<CallSession>> getHistoryCalls();
  Future<VoiceApiSettings> getVoiceApiSettings();
  Future<bool> getVoiceApiConnectionStatus();
  Future<bool> verifyVoiceApiConnection(VoiceApiSettings settings);
  Future<void> saveVoiceApiSettings(VoiceApiSettings settings);
  Future<void> blockNumber(String callId, String reason);
  Future<void> unblockNumber(String callId);
  Future<void> submitInternalReview({
    required String callId,
    required bool helpful,
    required int score,
    required String note,
  });
  Future<Map<String, dynamic>> getServerStatus();
  Future<Map<String, dynamic>> getTwilioSourceStatus();
  Future<bool> pingHealth();
  Future<void> requestServerStop();
}
