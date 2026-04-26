abstract class AiHelper {
  Future<String> simplifyQuestion({
    required String question,
    required bool enabled,
  });
}

class OptionalAiHelper implements AiHelper {
  @override
  Future<String> simplifyQuestion({
    required String question,
    required bool enabled,
  }) async {
    if (!enabled) {
      return _fallback(question);
    }

    // Hackathon-safe mock for optional AI mode.
    return 'KI-Hilfe: $question\n'
        'Einfach erklärt: Antworte kurz und konkret in Alltagssprache.';
  }

  String _fallback(String question) {
    return 'Ohne KI: $question\n'
        'Tipp: Gib nur die Information ein, die direkt gefragt ist.';
  }
}
