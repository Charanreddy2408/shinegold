import 'dart:math';

import '../../../core/config/app_config.dart';
import '../../models/enums.dart';
import '../../models/farm.dart';
import '../../models/visit_form.dart';
import '../contracts.dart';
import 'mock_seed_data.dart';

class MockFarmDataSource implements FarmDataSource {
  MockFarmDataSource() : _farms = List.of(MockSeedData.farms);

  final List<Farm> _farms;
  final _random = Random();

  Future<List<Farm>> getFarms(
    FarmFilter filter, {
    double? userLat,
    double? userLng,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    var result = List<Farm>.from(_farms);

    if (filter.search.isNotEmpty) {
      final q = filter.search.toLowerCase();
      result = result
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.location.toLowerCase().contains(q) ||
                f.farmer.name.toLowerCase().contains(q) ||
                f.farmer.mobile.replaceAll(' ', '').contains(q.replaceAll(' ', '')),
          )
          .toList();
    }

    if (filter.quickFilter != null) {
      switch (filter.quickFilter!) {
        case QuickFarmFilter.nearby:
          break;
        case QuickFarmFilter.pending:
          result = result
              .where((f) => f.status == FarmVisitStatus.pending)
              .toList();
        case QuickFarmFilter.harvestSoon:
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final cutoff = today.add(const Duration(days: 14));
          result = result
              .where(
                (f) =>
                    !f.harvestDate.isBefore(today) &&
                    f.harvestDate.isBefore(cutoff),
              )
              .toList();
        case QuickFarmFilter.recentlyVisited:
          result = result
              .where(
                (f) =>
                    f.lastVisited != null &&
                    f.lastVisited!.isAfter(
                      DateTime.now().subtract(const Duration(days: 14)),
                    ),
              )
              .toList();
        case QuickFarmFilter.completed:
          result = result
              .where(
                (f) =>
                    f.status == FarmVisitStatus.visited ||
                    f.status == FarmVisitStatus.harvested,
              )
              .toList();
        case QuickFarmFilter.all:
          break;
      }
    }

    if (filter.assignedExecutiveId != null) {
      result = result
          .where((f) => f.assignedExecutiveId == filter.assignedExecutiveId)
          .toList();
    }

    if (filter.status != null) {
      result = result.where((f) => f.status == filter.status).toList();
    }

    if (userLat != null && userLng != null) {
      result = result
          .map(
            (f) => f.copyWith(
              distanceKm: _haversine(userLat, userLng, f.latitude, f.longitude),
            ),
          )
          .toList();
    }

    switch (filter.sortOrder) {
      case SortOrder.nearbyToFarthest:
        result.sort(
          (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
        );
      case SortOrder.farthestToNearby:
        result.sort(
          (a, b) => (b.distanceKm ?? 0).compareTo(a.distanceKm ?? 0),
        );
      case SortOrder.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  Future<Farm?> getFarmById(String id) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    try {
      return _farms.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Farm> onboardFarm(
    OnboardFarmRequest request,
    String executiveId,
    String executiveName, {
    List<String>? uploadedPhotoUrls,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    final id = 'farm-${_random.nextInt(9999)}';
    final farmerId = 'farmer-${_random.nextInt(9999)}';

    final farm = Farm(
      id: id,
      name: request.farmName,
      location: request.location,
      latitude: request.latitude,
      longitude: request.longitude,
      crop: request.crop,
      harvestDate: request.harvestDate,
      harvestType: request.harvestType,
      totalAcres: request.totalAcres,
      assignedExecutiveId: executiveId,
      assignedExecutiveName: executiveName,
      farmer: Farmer(
        id: farmerId,
        name: request.farmerName,
        mobile: request.farmerMobile,
        gender: request.farmerGender,
        age: request.farmerAge,
      ),
      status: FarmVisitStatus.pending,
      harvestStatus: HarvestStatus.upcoming,
    );

    _farms.add(farm);
    return farm;
  }

  @override
  Future<List<FarmInvitation>> getFarmInvitations({
    double? lat,
    double? lng,
    int page = 1,
    int pageSize = 50,
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return _farms
        .where((f) => f.assignedExecutiveId.isEmpty)
        .map(
          (f) => FarmInvitation(
            id: f.id,
            name: f.name,
            latitude: f.latitude,
            longitude: f.longitude,
            locationAddress: f.location,
            distanceKm: lat != null && lng != null
                ? _haversine(lat, lng, f.latitude, f.longitude)
                : null,
            farmerName: f.farmer.name,
            farmerMobile: f.farmer.mobile,
          ),
        )
        .toList();
  }

  @override
  Future<void> acceptFarmInvitation(String farmId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final index = _farms.indexWhere((f) => f.id == farmId);
    if (index < 0) return;
    final farm = _farms[index];
    _farms[index] = Farm(
      id: farm.id,
      name: farm.name,
      location: farm.location,
      latitude: farm.latitude,
      longitude: farm.longitude,
      crop: farm.crop,
      harvestDate: farm.harvestDate,
      harvestType: farm.harvestType,
      totalAcres: farm.totalAcres,
      assignedExecutiveId: 'exec-1',
      assignedExecutiveName: 'Rahul Sharma',
      assignedExecutives: const [
        AssignedExecutive(id: 'exec-1', name: 'Rahul Sharma'),
      ],
      farmer: farm.farmer,
      status: farm.status,
      healthStatus: farm.healthStatus,
      lastVisited: farm.lastVisited,
      harvestStatus: farm.harvestStatus,
      visitLogs: farm.visitLogs,
      distanceKm: farm.distanceKm,
      photoUrls: farm.photoUrls,
    );
  }

  @override
  Future<Farm> createFarmAsAdmin(
    OnboardFarmRequest request, {
    List<String> executiveIds = const [],
    List<String>? uploadedPhotoUrls,
  }) async {
    return onboardFarm(
      request,
      executiveIds.firstOrNull ?? '',
      'Admin',
      uploadedPhotoUrls: uploadedPhotoUrls,
    );
  }

  @override
  Future<List<String>> assignFarmExecutives(
    String farmId, {
    required List<String> executiveIds,
    String mode = 'replace',
  }) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return executiveIds;
  }

  Future<void> updateFarmStatus(String farmId, FarmVisitStatus status) async {
    final index = _farms.indexWhere((f) => f.id == farmId);
    if (index >= 0) {
      _farms[index] = _farms[index].copyWith(status: status);
    }
  }

  Future<void> addVisitLog(String farmId, VisitLog log) async {
    final index = _farms.indexWhere((f) => f.id == farmId);
    if (index >= 0) {
      final farm = _farms[index];
      _farms[index] = farm.copyWith(
        visitLogs: [...farm.visitLogs, log],
        lastVisited: log.date,
        status: FarmVisitStatus.visited,
      );
    }
  }

  int get totalFarms => _farms.length;

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
