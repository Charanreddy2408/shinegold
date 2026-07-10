import 'enums.dart';
import 'visit_form.dart';

class Farmer {
  const Farmer({
    required this.id,
    required this.name,
    required this.mobile,
    this.gender,
    this.age,
    this.photoUrl,
    this.farmsCount = 0,
  });

  final String id;
  final String name;
  final String mobile;
  final Gender? gender;
  final int? age;
  final String? photoUrl;
  final int farmsCount;

  String get displayName => name.trim().isNotEmpty ? name.trim() : 'Unnamed farmer';

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        mobile: json['mobile'] as String? ??
            json['mobile_number'] as String? ??
            '',
        gender: _parseGender(json['gender']),
        age: json['age'] as int?,
        photoUrl: json['photo_url'] as String?,
        farmsCount: json['farms_count'] as int? ?? 0,
      );

  static Gender? _parseGender(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return Gender.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'mobile_number': mobile,
        if (gender != null) 'gender': gender!.name,
        if (age != null) 'age': age,
        if (photoUrl != null) 'photo_url': photoUrl,
      };
}

class VisitLog {
  const VisitLog({
    required this.id,
    required this.farmId,
    required this.date,
    required this.durationMinutes,
    required this.visitedBy,
    this.report,
    this.photoUrls = const [],
    this.voiceNoteUrl,
  });

  final String id;
  final String farmId;
  final DateTime date;
  final int durationMinutes;
  final String visitedBy;
  final String? report;
  final List<String> photoUrls;
  final String? voiceNoteUrl;

  factory VisitLog.fromJson(Map<String, dynamic> json) {
    final visitedByRaw = json['visited_by'];
    final visitedBy = visitedByRaw is Map
        ? visitedByRaw['name'] as String? ?? ''
        : visitedByRaw as String? ?? '';

    final durationSeconds = json['duration_seconds'] as int?;
    final durationMinutes = json['duration_minutes'] as int? ??
        (durationSeconds != null ? (durationSeconds / 60).round() : 0);

    return VisitLog(
      id: json['id']?.toString() ??
          json['visit_id']?.toString() ??
          '',
      farmId: json['farm_id']?.toString() ?? '',
      date: DateTime.parse(
        (json['date'] ?? json['checkin_time']) as String,
      ),
      durationMinutes: durationMinutes,
      visitedBy: visitedBy,
      report: json['report'] as String?,
      photoUrls: (json['photos'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e.toString())
              .toList() ??
          (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      voiceNoteUrl: json['voice_note'] as String? ??
          json['voice_note_url'] as String?,
    );
  }
}

class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.crop,
    required this.harvestDate,
    required this.harvestType,
    required this.totalAcres,
    required this.assignedExecutiveId,
    required this.assignedExecutiveName,
    required this.farmer,
    required this.status,
    this.assignedExecutives = const [],
    this.healthStatus = FarmHealthStatus.healthy,
    this.lastVisited,
    this.harvestStatus = HarvestStatus.upcoming,
    this.visitLogs = const [],
    this.distanceKm,
    this.photoUrls = const [],
  });

  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String crop;
  final DateTime harvestDate;
  final String harvestType;
  final double totalAcres;
  final String assignedExecutiveId;
  final String assignedExecutiveName;
  final List<AssignedExecutive> assignedExecutives;
  final Farmer farmer;
  final FarmVisitStatus status;
  final FarmHealthStatus healthStatus;
  final DateTime? lastVisited;
  final HarvestStatus harvestStatus;
  final List<VisitLog> visitLogs;
  final double? distanceKm;
  final List<String> photoUrls;

  factory Farm.fromUpcomingHarvest(Map<String, dynamic> json) {
    final harvestDateRaw = json['harvest_date'];
    final harvestDate = harvestDateRaw is String
        ? DateTime.parse(harvestDateRaw)
        : DateTime.now();
  final harvestLabel = harvestDateRaw is String
        ? 'Harvest: ${harvestDateRaw.split('T').first}'
        : '';
    return Farm(
      id: json['farm_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['farm_name'] as String? ?? json['name'] as String? ?? '',
      location: harvestLabel,
      latitude: 0,
      longitude: 0,
      crop: json['crop'] as String? ?? '',
      harvestDate: harvestDate,
      harvestType: json['harvest_type'] as String? ?? '',
      totalAcres: 0,
      assignedExecutiveId: '',
      assignedExecutiveName: '',
      farmer: const Farmer(id: '', name: '—', mobile: ''),
      status: FarmVisitStatus.pending,
    );
  }

  factory Farm.fromSummaryJson(Map<String, dynamic> json) => Farm(
        id: json['farm_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['farm_name'] as String? ?? json['name'] as String? ?? '',
        location: '',
        latitude: 0,
        longitude: 0,
        crop: json['crop'] as String? ?? '',
        harvestDate: DateTime.now(),
        harvestType: json['harvest_type'] as String? ?? '',
        totalAcres: 0,
        assignedExecutiveId: '',
        assignedExecutiveName: '',
        farmer: const Farmer(id: '', name: '—', mobile: ''),
        status: json['status'] is String
            ? _parseFarmVisitStatus(json['status'] as String)
            : FarmVisitStatus.pending,
      );

  factory Farm.fromJson(Map<String, dynamic> json) {
    final locationObj = json['location'];
    double latitude = 0;
    double longitude = 0;
    String locationAddress = '';

    if (locationObj is Map<String, dynamic>) {
      latitude = (locationObj['lat'] as num?)?.toDouble() ?? 0;
      longitude = (locationObj['lng'] as num?)?.toDouble() ?? 0;
      locationAddress = locationObj['address'] as String? ?? '';
    } else {
      latitude = (json['latitude'] as num?)?.toDouble() ??
          (json['location_lat'] as num?)?.toDouble() ??
          0;
      longitude = (json['longitude'] as num?)?.toDouble() ??
          (json['location_lng'] as num?)?.toDouble() ??
          0;
      locationAddress = json['location'] as String? ??
          json['location_address'] as String? ??
          '';
    }

    final assignedExecutive = json['assigned_executive'];
    final assignedExecutivesRaw = json['assigned_executives'] as List<dynamic>?;
    final assignedExecutives = assignedExecutivesRaw
            ?.map((e) => AssignedExecutive.fromJson(e as Map<String, dynamic>))
            .toList() ??
        (assignedExecutive is Map
            ? [
                AssignedExecutive.fromJson(
                  assignedExecutive as Map<String, dynamic>,
                ),
              ]
            : <AssignedExecutive>[]);

    final assignedExecutiveId = json['assigned_executive_id']?.toString() ??
        assignedExecutives.firstOrNull?.id ??
        (assignedExecutive is Map
            ? assignedExecutive['id']?.toString()
            : null) ??
        '';
    final assignedExecutiveName = json['assigned_executive_name'] as String? ??
        assignedExecutives.firstOrNull?.name ??
        (assignedExecutive is Map
            ? assignedExecutive['name'] as String?
            : null) ??
        '';

    final farmerJson = json['farmer'];
    final farmer = farmerJson is Map<String, dynamic>
        ? Farmer.fromJson(farmerJson)
        : const Farmer(id: '', name: '—', mobile: '');

    final harvestDateRaw = json['harvest_date'];
    final harvestDate = harvestDateRaw is String
        ? DateTime.parse(harvestDateRaw)
        : DateTime.now();

    return Farm(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      location: locationAddress,
      latitude: latitude,
      longitude: longitude,
      crop: json['crop'] as String? ?? '',
      harvestDate: harvestDate,
      harvestType: json['harvest_type'] as String? ?? '',
      totalAcres: (json['total_acres'] as num?)?.toDouble() ?? 0,
      assignedExecutiveId: assignedExecutiveId,
      assignedExecutiveName: assignedExecutiveName,
      assignedExecutives: assignedExecutives,
      farmer: farmer,
      status: json['status'] is String
          ? _parseFarmVisitStatus(json['status'] as String)
          : FarmVisitStatus.pending,
      healthStatus: json['health_status'] is String
          ? FarmHealthStatus.values.byName(json['health_status'] as String)
          : FarmHealthStatus.healthy,
      lastVisited: json['last_visited'] != null
          ? DateTime.parse(json['last_visited'] as String)
          : null,
      harvestStatus: HarvestStatus.upcoming,
      visitLogs: (json['visit_logs'] as List<dynamic>?)
              ?.map((e) => VisitLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      photoUrls: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static FarmVisitStatus _parseFarmVisitStatus(String value) {
    switch (value) {
      case 'pending_visit':
      case 'pending':
        return FarmVisitStatus.pending;
      case 'ongoing':
      case 'in_progress':
        return FarmVisitStatus.ongoing;
      case 'visited':
        return FarmVisitStatus.visited;
      case 'harvested':
        return FarmVisitStatus.harvested;
      case 'blocked':
        return FarmVisitStatus.blocked;
      default:
        return FarmVisitStatus.pending;
    }
  }

  Farm copyWith({
    FarmVisitStatus? status,
    DateTime? lastVisited,
    List<VisitLog>? visitLogs,
    double? distanceKm,
    HarvestStatus? harvestStatus,
    FarmHealthStatus? healthStatus,
  }) =>
      Farm(
        id: id,
        name: name,
        location: location,
        latitude: latitude,
        longitude: longitude,
        crop: crop,
        harvestDate: harvestDate,
        harvestType: harvestType,
        totalAcres: totalAcres,
        assignedExecutiveId: assignedExecutiveId,
        assignedExecutiveName: assignedExecutiveName,
        assignedExecutives: assignedExecutives,
        farmer: farmer,
        status: status ?? this.status,
        healthStatus: healthStatus ?? this.healthStatus,
        lastVisited: lastVisited ?? this.lastVisited,
        harvestStatus: harvestStatus ?? this.harvestStatus,
        visitLogs: visitLogs ?? this.visitLogs,
        distanceKm: distanceKm ?? this.distanceKm,
        photoUrls: photoUrls,
      );
}

class FarmFilter {
  const FarmFilter({
    this.search = '',
    this.sortOrder = SortOrder.nearbyToFarthest,
    this.assignedExecutiveId,
    this.status,
    this.quickFilter,
    this.page = 1,
    this.pageSize = 50,
  });

  final String search;
  final SortOrder sortOrder;
  final String? assignedExecutiveId;
  final FarmVisitStatus? status;
  final QuickFarmFilter? quickFilter;
  final int page;
  final int pageSize;

  FarmFilter copyWith({
    String? search,
    SortOrder? sortOrder,
    String? assignedExecutiveId,
    FarmVisitStatus? status,
    QuickFarmFilter? quickFilter,
    bool clearStatus = false,
    bool clearQuickFilter = false,
    int? page,
    int? pageSize,
  }) =>
      FarmFilter(
        search: search ?? this.search,
        sortOrder: sortOrder ?? this.sortOrder,
        assignedExecutiveId: assignedExecutiveId ?? this.assignedExecutiveId,
        status: clearStatus ? null : (status ?? this.status),
        quickFilter:
            clearQuickFilter ? null : (quickFilter ?? this.quickFilter),
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}

class OnboardFarmRequest {
  const OnboardFarmRequest({
    required this.farmName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.crop,
    required this.harvestDate,
    required this.harvestType,
    required this.totalAcres,
    required this.farmerName,
    required this.farmerMobile,
    required this.farmerGender,
    required this.farmerAge,
    this.boundaryGeojson,
    this.photoPaths = const [],
  });

  final String farmName;
  final String location;
  final double latitude;
  final double longitude;
  final String crop;
  final DateTime harvestDate;
  final String harvestType;
  final double totalAcres;
  final String farmerName;
  final String farmerMobile;
  final Gender farmerGender;
  final int farmerAge;
  final Map<String, dynamic>? boundaryGeojson;
  final List<String> photoPaths;

  Map<String, dynamic> toJson({List<String>? uploadedPhotos}) => {
        'name': farmName,
        'location_lat': latitude,
        'location_lng': longitude,
        'location_address': location,
        'crop': crop,
        'harvest_date': harvestDate.toIso8601String().split('T').first,
        'harvest_type': harvestType,
        'total_acres': totalAcres,
        if (boundaryGeojson != null) 'boundary_geojson': boundaryGeojson,
        if (uploadedPhotos != null && uploadedPhotos.isNotEmpty)
          'photos': uploadedPhotos,
        'farmer': {
          'name': farmerName,
          'mobile_number': farmerMobile,
          'gender': farmerGender.name,
          'age': farmerAge,
        },
      };
}
