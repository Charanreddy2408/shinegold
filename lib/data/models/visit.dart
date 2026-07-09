import 'enums.dart';

class Visit {
  const Visit({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.executiveId,
    required this.executiveName,
    required this.startedAt,
    this.endedAt,
    this.status = VisitStatus.ongoing,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.voiceNotePath,
    this.textNote,
    this.mcqAnswers = const {},
    this.condition,
    this.syncStatus = SyncStatus.synced,
    this.photoCount = 0,
    this.hasVoiceNote = false,
  });

  final String id;
  final String farmId;
  final String farmName;
  final String executiveId;
  final String executiveName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final VisitStatus status;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final String? voiceNotePath;
  final String? textNote;
  final Map<String, String> mcqAnswers;
  final FarmHealthStatus? condition;
  final SyncStatus syncStatus;
  final int photoCount;
  final bool hasVoiceNote;

  int? get durationMinutes {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt).inMinutes;
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    final farmObj = json['farm'];
    final startedRaw = json['checkin_time'] ??
        json['started_at'] ??
        json['checkin_at'] ??
        json['created_at'];
    final endedRaw = json['checkout_time'] ?? json['ended_at'];

    final visitedBy = json['visited_by'];
    final executiveName = json['executive_name'] as String? ??
        (visitedBy is Map ? visitedBy['name'] as String? : null) ??
        '';
    final executiveId = json['executive_id']?.toString() ??
        (visitedBy is Map ? visitedBy['id']?.toString() : null) ??
        '';

    return Visit(
      id: json['visit_id']?.toString() ?? json['id']?.toString() ?? '',
      farmId: json['farm_id']?.toString() ??
          (farmObj is Map ? farmObj['id']?.toString() : null) ??
          '',
      farmName: json['farm_name'] as String? ??
          (farmObj is Map ? farmObj['name'] as String? : null) ??
          '',
      executiveId: executiveId,
      executiveName: executiveName,
      startedAt: startedRaw != null
          ? DateTime.parse(startedRaw as String)
          : DateTime.now(),
      endedAt:
          endedRaw != null ? DateTime.parse(endedRaw as String) : null,
      status: json['status'] is String
          ? _parseStatus(json['status'] as String)
          : VisitStatus.ongoing,
      latitude: (json['checkin_lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble(),
      longitude: (json['checkin_lng'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble(),
      photos: _parsePhotoUrls(json),
      voiceNotePath: json['voice_note_url'] as String?,
      textNote: json['text_note'] as String? ??
          json['remarks_preview'] as String?,
      mcqAnswers: _parseMcqAnswers(json['mcq_answers']),
      condition: null,
      syncStatus: SyncStatus.synced,
      photoCount: json['photo_count'] as int? ?? _parsePhotoUrls(json).length,
      hasVoiceNote: json['has_voice_note'] as bool? ?? false,
    );
  }

  factory Visit.fromCheckin(
    Map<String, dynamic> json, {
    required String farmName,
    required double latitude,
    required double longitude,
  }) =>
      Visit(
        id: json['visit_id'].toString(),
        farmId: json['farm_id'].toString(),
        farmName: farmName,
        executiveId: '',
        executiveName: '',
        startedAt: DateTime.parse(json['checkin_time'] as String),
        status: _parseStatus(json['status'] as String),
        latitude: latitude,
        longitude: longitude,
      );

  static VisitStatus _parseStatus(String value) {
    switch (value) {
      case 'in_progress':
        return VisitStatus.ongoing;
      case 'completed':
        return VisitStatus.completed;
      case 'cancelled':
        return VisitStatus.cancelled;
      default:
        return VisitStatus.ongoing;
    }
  }

  static List<String> _parsePhotoUrls(Map<String, dynamic> json) {
    final raw = json['photos'];
    if (raw is List) {
      return raw.map((e) {
        if (e is String) return e;
        if (e is Map) {
          return e['photo_url']?.toString() ?? e['url']?.toString() ?? '';
        }
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  static Map<String, String> _parseMcqAnswers(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    if (raw is List) {
      final map = <String, String>{};
      for (final item in raw) {
        if (item is Map) {
          final key = item['question_key']?.toString() ??
              item['question_id']?.toString();
          final answer = item['answer']?.toString();
          if (key != null && answer != null) map[key] = answer;
        }
      }
      return map;
    }
    return {};
  }

  Visit copyWith({
    DateTime? endedAt,
    VisitStatus? status,
    List<String>? photos,
    String? voiceNotePath,
    String? textNote,
    Map<String, String>? mcqAnswers,
    FarmHealthStatus? condition,
    SyncStatus? syncStatus,
    double? latitude,
    double? longitude,
  }) =>
      Visit(
        id: id,
        farmId: farmId,
        farmName: farmName,
        executiveId: executiveId,
        executiveName: executiveName,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        status: status ?? this.status,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        photos: photos ?? this.photos,
        voiceNotePath: voiceNotePath ?? this.voiceNotePath,
        textNote: textNote ?? this.textNote,
        mcqAnswers: mcqAnswers ?? this.mcqAnswers,
        condition: condition ?? this.condition,
        syncStatus: syncStatus ?? this.syncStatus,
        photoCount: photos?.length ?? photoCount,
        hasVoiceNote: voiceNotePath != null || hasVoiceNote,
      );
}

class VisitFilter {
  const VisitFilter({
    this.search = '',
    this.fromDate,
    this.toDate,
    this.status,
    this.page = 1,
    this.pageSize = 50,
  });

  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VisitStatus? status;
  final int page;
  final int pageSize;
}

class McqQuestion {
  const McqQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  final String id;
  final String question;
  final List<String> options;
}
