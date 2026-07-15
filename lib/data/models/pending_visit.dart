import 'visit_form.dart';

/// A farm visit captured while offline, waiting to be replayed to the API.
///
/// The visit lives in RAM during capture; once the executive submits it is
/// persisted to disk and synced (check-in -> form -> media -> submit) when
/// the device is back online.
class PendingVisit {
  const PendingVisit({
    required this.localId,
    required this.farmId,
    required this.farmName,
    required this.checkinLat,
    required this.checkinLng,
    required this.checkinAt,
    required this.checkoutLat,
    required this.checkoutLng,
    required this.checkoutAt,
    this.formAnswers = const [],
    this.photoPaths = const [],
    this.voiceNotePath,
    this.textNote,
    this.serverVisitId,
    this.attempts = 0,
    this.lastError,
  });

  /// Client-side UUID that identifies this visit until the server assigns one.
  final String localId;
  final String farmId;
  final String farmName;
  final double checkinLat;
  final double checkinLng;
  final DateTime checkinAt;
  final double checkoutLat;
  final double checkoutLng;
  final DateTime checkoutAt;
  final List<FormAnswerEntry> formAnswers;

  /// Local file paths (or URLs when already uploaded).
  final List<String> photoPaths;
  final String? voiceNotePath;
  final String? textNote;

  /// Set once the check-in step has been replayed successfully so retries
  /// resume from the form/submit steps instead of double-checking-in.
  final String? serverVisitId;
  final int attempts;
  final String? lastError;

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'farm_id': farmId,
        'farm_name': farmName,
        'checkin_lat': checkinLat,
        'checkin_lng': checkinLng,
        'checkin_at': checkinAt.toIso8601String(),
        'checkout_lat': checkoutLat,
        'checkout_lng': checkoutLng,
        'checkout_at': checkoutAt.toIso8601String(),
        'form_answers': formAnswers.map((e) => e.toJson()).toList(),
        'photo_paths': photoPaths,
        if (voiceNotePath != null) 'voice_note_path': voiceNotePath,
        if (textNote != null) 'text_note': textNote,
        if (serverVisitId != null) 'server_visit_id': serverVisitId,
        'attempts': attempts,
        if (lastError != null) 'last_error': lastError,
      };

  factory PendingVisit.fromJson(Map<String, dynamic> json) => PendingVisit(
        localId: json['local_id'] as String,
        farmId: json['farm_id'] as String,
        farmName: json['farm_name'] as String? ?? '',
        checkinLat: (json['checkin_lat'] as num).toDouble(),
        checkinLng: (json['checkin_lng'] as num).toDouble(),
        checkinAt: DateTime.parse(json['checkin_at'] as String),
        checkoutLat: (json['checkout_lat'] as num).toDouble(),
        checkoutLng: (json['checkout_lng'] as num).toDouble(),
        checkoutAt: DateTime.parse(json['checkout_at'] as String),
        formAnswers: (json['form_answers'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(FormAnswerEntry.fromJson)
            .toList(),
        photoPaths: (json['photo_paths'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        voiceNotePath: json['voice_note_path'] as String?,
        textNote: json['text_note'] as String?,
        serverVisitId: json['server_visit_id'] as String?,
        attempts: json['attempts'] as int? ?? 0,
        lastError: json['last_error'] as String?,
      );

  PendingVisit copyWith({
    List<String>? photoPaths,
    String? voiceNotePath,
    String? serverVisitId,
    int? attempts,
    String? lastError,
    bool clearError = false,
  }) =>
      PendingVisit(
        localId: localId,
        farmId: farmId,
        farmName: farmName,
        checkinLat: checkinLat,
        checkinLng: checkinLng,
        checkinAt: checkinAt,
        checkoutLat: checkoutLat,
        checkoutLng: checkoutLng,
        checkoutAt: checkoutAt,
        formAnswers: formAnswers,
        photoPaths: photoPaths ?? this.photoPaths,
        voiceNotePath: voiceNotePath ?? this.voiceNotePath,
        textNote: textNote,
        serverVisitId: serverVisitId ?? this.serverVisitId,
        attempts: attempts ?? this.attempts,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}
