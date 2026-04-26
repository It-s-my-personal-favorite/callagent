class CallNote {
  CallNote({
    required this.id,
    required this.createdAt,
    required this.text,
  });

  final String id;
  final DateTime createdAt;
  final String text;

  factory CallNote.fromJson(Map<String, dynamic> json) {
    return CallNote(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'text': text,
      };
}

class CallerProfile {
  CallerProfile({
    this.displayName = '',
    this.email = '',
    this.company = '',
    this.street = '',
    this.zip = '',
    this.city = '',
    this.caseReference = '',
    this.birthDate = '',
    this.extraNotes = '',
  });

  final String displayName;
  final String email;
  final String company;
  final String street;
  final String zip;
  final String city;
  final String caseReference;
  final String birthDate;
  final String extraNotes;

  factory CallerProfile.empty() => CallerProfile();

  factory CallerProfile.fromJson(Map<String, dynamic> json) {
    return CallerProfile(
      displayName: (json['displayName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      company: (json['company'] ?? '') as String,
      street: (json['street'] ?? '') as String,
      zip: (json['zip'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      caseReference: (json['caseReference'] ?? '') as String,
      birthDate: (json['birthDate'] ?? '') as String,
      extraNotes: (json['extraNotes'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'company': company,
        'street': street,
        'zip': zip,
        'city': city,
        'caseReference': caseReference,
        'birthDate': birthDate,
        'extraNotes': extraNotes,
      };

  CallerProfile copyWith({
    String? displayName,
    String? email,
    String? company,
    String? street,
    String? zip,
    String? city,
    String? caseReference,
    String? birthDate,
    String? extraNotes,
  }) {
    return CallerProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      company: company ?? this.company,
      street: street ?? this.street,
      zip: zip ?? this.zip,
      city: city ?? this.city,
      caseReference: caseReference ?? this.caseReference,
      birthDate: birthDate ?? this.birthDate,
      extraNotes: extraNotes ?? this.extraNotes,
    );
  }
}

class CallSession {
  CallSession({
    required this.id,
    required this.callerNumber,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.durationSec,
    required this.assistantId,
    required this.metrics,
    required this.userFeedback,
    required this.internalReview,
    required this.blocked,
    required this.transcript,
    this.recordingUrl,
    this.marked = false,
    this.important = false,
    this.warningActive = false,
    this.forwardedTo,
    List<CallNote>? notes,
    CallerProfile? profile,
  })  : notes = notes ?? const [],
        profile = profile ?? CallerProfile.empty();

  final String id;
  final String callerNumber;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSec;
  final String assistantId;
  final CallMetrics metrics;
  final UserFeedback userFeedback;
  final InternalReview internalReview;
  bool blocked;
  final List<TranscriptTurn> transcript;
  final String? recordingUrl;
  bool marked;
  bool important;
  bool warningActive;
  String? forwardedTo;
  List<CallNote> notes;
  CallerProfile profile;

  bool get isForwarded => forwardedTo != null && forwardedTo!.isNotEmpty;

  factory CallSession.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'] as List<dynamic>?;
    return CallSession(
      id: json['id'] as String,
      callerNumber: json['callerNumber'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      durationSec: json['durationSec'] as int,
      assistantId: json['assistantId'] as String,
      metrics: CallMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      userFeedback:
          UserFeedback.fromJson(json['userFeedback'] as Map<String, dynamic>),
      internalReview: InternalReview.fromJson(
        json['internalReview'] as Map<String, dynamic>,
      ),
      blocked: json['blocked'] as bool,
      transcript: (json['transcript'] as List<dynamic>)
          .map((item) => TranscriptTurn.fromJson(item as Map<String, dynamic>))
          .toList(),
      recordingUrl: json['recordingUrl'] as String?,
      marked: json['marked'] as bool? ?? false,
      important: json['important'] as bool? ?? false,
      warningActive: json['warningActive'] as bool? ?? false,
      forwardedTo: json['forwardedTo'] as String?,
      notes: notesRaw
          ?.map((e) => CallNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      profile: json['profile'] != null
          ? CallerProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerNumber': callerNumber,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSec': durationSec,
      'assistantId': assistantId,
      'metrics': metrics.toJson(),
      'userFeedback': userFeedback.toJson(),
      'internalReview': internalReview.toJson(),
      'blocked': blocked,
      'transcript': transcript.map((e) => e.toJson()).toList(),
      'recordingUrl': recordingUrl,
      'marked': marked,
      'important': important,
      'warningActive': warningActive,
      'forwardedTo': forwardedTo,
      'notes': notes.map((e) => e.toJson()).toList(),
      'profile': profile.toJson(),
    };
  }

  CallSession copyWith({
    String? id,
    String? callerNumber,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    String? assistantId,
    CallMetrics? metrics,
    UserFeedback? userFeedback,
    InternalReview? internalReview,
    bool? blocked,
    List<TranscriptTurn>? transcript,
    String? recordingUrl,
    bool? marked,
    bool? important,
    bool? warningActive,
    String? forwardedTo,
    bool updateForwardedTo = false,
    List<CallNote>? notes,
    CallerProfile? profile,
  }) {
    return CallSession(
      id: id ?? this.id,
      callerNumber: callerNumber ?? this.callerNumber,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      assistantId: assistantId ?? this.assistantId,
      metrics: metrics ?? this.metrics,
      userFeedback: userFeedback ?? this.userFeedback,
      internalReview: internalReview ?? this.internalReview,
      blocked: blocked ?? this.blocked,
      transcript: transcript ?? this.transcript,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      marked: marked ?? this.marked,
      important: important ?? this.important,
      warningActive: warningActive ?? this.warningActive,
      forwardedTo: updateForwardedTo ? forwardedTo : this.forwardedTo,
      notes: notes ?? List<CallNote>.from(this.notes),
      profile: profile ?? this.profile,
    );
  }
}

enum CallOutcome { successful, failed, unknown }

/// Verschlanktes, persistence-freundliches Modell für DB-Use-Cases.
/// Kann später 1:1 in ein relationales Schema überführt werden.
class CallRecord {
  CallRecord({
    required this.number,
    required this.callTime,
    required this.protocol,
    required this.audioFile,
    required this.startAt,
    this.endAt,
    required this.location,
    required this.language,
    required this.rating,
    required this.outcome,
    required this.callTitle,
  });

  final String number;
  final DateTime callTime;
  final String protocol;
  final String audioFile;
  final DateTime startAt;
  final DateTime? endAt;
  final String location;
  final String language;
  final int rating;
  final CallOutcome outcome;
  final String callTitle;

  bool get successful => outcome == CallOutcome.successful;

  factory CallRecord.fromSession(CallSession session) {
    final hasPositiveReview = session.internalReview.helpful && session.internalReview.score >= 6;
    final hasPositiveUserRating = session.userFeedback.rating >= 3;
    final isSuccessful = hasPositiveReview || hasPositiveUserRating;
    return CallRecord(
      number: session.callerNumber,
      callTime: session.startedAt,
      protocol: 'voice',
      audioFile: session.recordingUrl ?? '',
      startAt: session.startedAt,
      endAt: session.endedAt,
      location: 'DE',
      language: 'de',
      rating: session.internalReview.score,
      outcome: isSuccessful ? CallOutcome.successful : CallOutcome.failed,
      callTitle: session.internalReview.note.isNotEmpty
          ? session.internalReview.note
          : 'Summarized call ${session.id}',
    );
  }

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      number: (json['number'] ?? '') as String,
      callTime: DateTime.parse(json['callTime'] as String),
      protocol: (json['protocol'] ?? 'voice') as String,
      audioFile: (json['audioFile'] ?? '') as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] == null ? null : DateTime.parse(json['endAt'] as String),
      location: (json['location'] ?? '') as String,
      language: (json['language'] ?? '') as String,
      rating: (json['rating'] ?? 0) as int,
      outcome: _outcomeFromString((json['outcome'] ?? 'unknown') as String),
      callTitle: (json['callTitle'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'callTime': callTime.toIso8601String(),
      'protocol': protocol,
      'audioFile': audioFile,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'location': location,
      'language': language,
      'rating': rating,
      'outcome': outcome.name,
      'callTitle': callTitle,
    };
  }

  static CallOutcome _outcomeFromString(String value) {
    switch (value) {
      case 'successful':
        return CallOutcome.successful;
      case 'failed':
        return CallOutcome.failed;
      default:
        return CallOutcome.unknown;
    }
  }
}

class CallMetrics {
  CallMetrics({
    required this.tokenInput,
    required this.tokenOutput,
    required this.tokenTotal,
    required this.avgLatencyMs,
    required this.p95LatencyMs,
  });

  final int tokenInput;
  final int tokenOutput;
  final int tokenTotal;
  final int avgLatencyMs;
  final int p95LatencyMs;

  factory CallMetrics.fromJson(Map<String, dynamic> json) {
    return CallMetrics(
      tokenInput: json['tokenInput'] as int,
      tokenOutput: json['tokenOutput'] as int,
      tokenTotal: json['tokenTotal'] as int,
      avgLatencyMs: json['avgLatencyMs'] as int,
      p95LatencyMs: json['p95LatencyMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenInput': tokenInput,
      'tokenOutput': tokenOutput,
      'tokenTotal': tokenTotal,
      'avgLatencyMs': avgLatencyMs,
      'p95LatencyMs': p95LatencyMs,
    };
  }
}

class UserFeedback {
  UserFeedback({
    required this.rating,
    required this.comment,
  });

  final int rating;
  final String comment;

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      rating: json['rating'] as int,
      comment: json['comment'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }
}

class InternalReview {
  InternalReview({
    required this.helpful,
    required this.score,
    required this.note,
  });

  bool helpful;
  int score;
  String note;

  factory InternalReview.fromJson(Map<String, dynamic> json) {
    return InternalReview(
      helpful: json['helpful'] as bool,
      score: json['score'] as int,
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'helpful': helpful,
      'score': score,
      'note': note,
    };
  }
}

class TranscriptTurn {
  TranscriptTurn({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String role;
  final String text;
  final DateTime timestamp;

  factory TranscriptTurn.fromJson(Map<String, dynamic> json) {
    return TranscriptTurn(
      role: json['role'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class VoiceApiSettings {
  VoiceApiSettings({
    required this.twilioAccountSid,
    required this.twilioAuthToken,
    required this.localServerUrl,
    required this.twilioPhoneNumber,
    required this.deepgramApiKey,
  });

  final String twilioAccountSid;
  final String twilioAuthToken;
  final String localServerUrl;
  final String twilioPhoneNumber;
  final String deepgramApiKey;

  factory VoiceApiSettings.empty() {
    return VoiceApiSettings(
      twilioAccountSid: '',
      twilioAuthToken: '',
      localServerUrl: '',
      twilioPhoneNumber: '',
      deepgramApiKey: '',
    );
  }

  factory VoiceApiSettings.fromJson(Map<String, dynamic> json) {
    return VoiceApiSettings(
      twilioAccountSid: (json['twilioAccountSid'] ?? '') as String,
      twilioAuthToken: (json['twilioAuthToken'] ?? '') as String,
      localServerUrl: (json['localServerUrl'] ?? '') as String,
      twilioPhoneNumber: (json['twilioPhoneNumber'] ?? '') as String,
      deepgramApiKey: (json['deepgramApiKey'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'twilioAccountSid': twilioAccountSid,
      'twilioAuthToken': twilioAuthToken,
      'localServerUrl': localServerUrl,
      'twilioPhoneNumber': twilioPhoneNumber,
      'deepgramApiKey': deepgramApiKey,
    };
  }

  VoiceApiSettings copyWith({
    String? twilioAccountSid,
    String? twilioAuthToken,
    String? localServerUrl,
    String? twilioPhoneNumber,
    String? deepgramApiKey,
  }) {
    return VoiceApiSettings(
      twilioAccountSid: twilioAccountSid ?? this.twilioAccountSid,
      twilioAuthToken: twilioAuthToken ?? this.twilioAuthToken,
      localServerUrl: localServerUrl ?? this.localServerUrl,
      twilioPhoneNumber: twilioPhoneNumber ?? this.twilioPhoneNumber,
      deepgramApiKey: deepgramApiKey ?? this.deepgramApiKey,
    );
  }
}
