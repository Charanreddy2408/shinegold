import 'enums.dart';
import 'farm.dart';

class Executive {
  const Executive({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.mobile,
    this.profilePhotoUrl,
    this.status = ExecutiveStatus.active,
    this.farmsAssigned = 0,
    this.totalVisits = 0,
  });

  final String id;
  final String employeeId;
  final String name;
  final String mobile;
  final String? profilePhotoUrl;
  final ExecutiveStatus status;
  final int farmsAssigned;
  final int totalVisits;

  factory Executive.fromJson(Map<String, dynamic> json) => Executive(
        id: json['id']?.toString() ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        mobile: json['mobile_number'] as String? ??
            json['mobile'] as String? ??
            '',
        profilePhotoUrl: json['profile_photo_url'] as String?,
        status: json['is_blocked'] == true || json['status'] == 'blocked'
            ? ExecutiveStatus.blocked
            : ExecutiveStatus.active,
        farmsAssigned: json['farms_assigned_count'] as int? ??
            json['farms_assigned'] as int? ??
            json['assigned_farms_count'] as int? ??
            0,
        totalVisits: json['total_farms_visited'] as int? ??
            json['total_visits'] as int? ??
            json['visits_count'] as int? ??
            0,
      );

  Executive copyWith({ExecutiveStatus? status}) => Executive(
        id: id,
        employeeId: employeeId,
        name: name,
        mobile: mobile,
        profilePhotoUrl: profilePhotoUrl,
        status: status ?? this.status,
        farmsAssigned: farmsAssigned,
        totalVisits: totalVisits,
      );
}

class FarmerWithFarms {
  const FarmerWithFarms({
    required this.farmer,
    required this.farms,
  });

  final Farmer farmer;
  final List<Farm> farms;
}

class Harvest {
  const Harvest({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.crop,
    required this.harvestDate,
    required this.harvestType,
    required this.status,
  });

  final String id;
  final String farmId;
  final String farmName;
  final String crop;
  final DateTime harvestDate;
  final String harvestType;
  final HarvestStatus status;

  factory Harvest.fromJson(Map<String, dynamic> json) => Harvest(
        id: json['id'] as String? ?? json['farm_id'] as String,
        farmId: json['farm_id'] as String,
        farmName: json['farm_name'] as String,
        crop: json['crop'] as String,
        harvestDate: DateTime.parse(json['harvest_date'] as String),
        harvestType: json['harvest_type'] as String? ?? '',
        status: json['status'] is String
            ? _parseHarvestStatus(json['status'] as String)
            : HarvestStatus.upcoming,
      );

  static HarvestStatus _parseHarvestStatus(String value) {
    switch (value) {
      case 'in_progress':
        return HarvestStatus.inProgress;
      default:
        return HarvestStatus.values.byName(value);
    }
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalFarms,
    required this.totalExecutives,
    required this.totalVisits,
    required this.farmersOnboarded,
  });

  final int totalFarms;
  final int totalExecutives;
  final int totalVisits;
  final int farmersOnboarded;
}

class ExecutiveDashboard {
  const ExecutiveDashboard({
    required this.greetingName,
    required this.dashboardDate,
    required this.totalFarms,
    required this.visitedCount,
    required this.pendingCount,
    required this.harvestSoonCount,
    this.priorityFarms = const [],
  });

  final String greetingName;
  final DateTime dashboardDate;
  final int totalFarms;
  final int visitedCount;
  final int pendingCount;
  final int harvestSoonCount;
  final List<Farm> priorityFarms;

  factory ExecutiveDashboard.fromJson(Map<String, dynamic> json) {
    final pending = json['pending_farms_count'] as int? ??
        json['pending_count'] as int? ??
        0;
    final visited = json['farms_visited_count'] as int? ??
        json['visited_count'] as int? ??
        0;
    final upcoming = json['upcoming_harvests'];
    final harvestSoon = upcoming is List ? upcoming.length : 0;

    final priorityFarms = upcoming is List
        ? upcoming
            .map((e) {
              final item = e as Map<String, dynamic>;
              return Farm.fromUpcomingHarvest(item);
            })
            .toList()
        : const <Farm>[];

    final dateRaw = json['date'] as String?;
    final dashboardDate = dateRaw != null
        ? DateTime.tryParse(dateRaw) ?? DateTime.now()
        : DateTime.now();

    // Backend sets total_farms_to_visit = pending only; UI needs assigned workload.
    final assignedTotal = pending + visited;

    return ExecutiveDashboard(
      greetingName: json['greeting_name'] as String? ?? '',
      dashboardDate: dashboardDate,
      totalFarms: assignedTotal > 0
          ? assignedTotal
          : (json['total_farms_to_visit'] as int? ?? pending),
      visitedCount: visited,
      pendingCount: pending,
      harvestSoonCount: json['harvest_soon_count'] as int? ?? harvestSoon,
      priorityFarms: priorityFarms,
    );
  }
}

class CreateExecutiveRequest {
  const CreateExecutiveRequest({
    required this.name,
    required this.mobile,
    required this.password,
    required this.address,
  });

  final String name;
  final String mobile;
  final String password;
  final String address;
}
