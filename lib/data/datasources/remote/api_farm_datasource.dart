import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/upload_service.dart';
import '../../models/enums.dart';
import '../../models/farm.dart';
import '../../models/visit_form.dart';
import '../contracts.dart';

class ApiFarmDataSource implements FarmDataSource {
  ApiFarmDataSource(this._client, this._uploads);

  final DioClient _client;
  final UploadService _uploads;

  @override
  Future<List<Farm>> getFarms(
    FarmFilter filter, {
    double? userLat,
    double? userLng,
  }) async {
    final hasLocation = userLat != null && userLng != null;
    final sort = hasLocation ? sortOrderToApi(filter.sortOrder) : null;
    final params = queryParams({
      'search': filter.search,
      if (sort != null) 'sort': sort,
      if (filter.status != null)
        'harvest_status': farmVisitStatusToApi(filter.status!),
      if (filter.assignedExecutiveId != null)
        'assigned_to': filter.assignedExecutiveId,
      if (userLat != null) 'lat': userLat,
      if (userLng != null) 'lng': userLng,
      'page': filter.page,
      'page_size': filter.pageSize,
    });

    final response = await _client.dio.get(
      ApiEndpoints.farms,
      queryParameters: params,
    );

    var farms = parseList(response.data, Farm.fromJson);

    if (filter.quickFilter == QuickFarmFilter.pending) {
      farms = farms
          .where((f) => f.status == FarmVisitStatus.pending)
          .toList();
    } else if (filter.quickFilter == QuickFarmFilter.harvestSoon) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cutoff = today.add(const Duration(days: 14));
      farms = farms
          .where(
            (f) =>
                !f.harvestDate.isBefore(today) && f.harvestDate.isBefore(cutoff),
          )
          .toList();
    } else if (filter.quickFilter == QuickFarmFilter.recentlyVisited) {
      final cutoff = DateTime.now().subtract(const Duration(days: 14));
      farms = farms
          .where(
            (f) =>
                f.lastVisited != null && f.lastVisited!.isAfter(cutoff),
          )
          .toList();
    } else if (filter.quickFilter == QuickFarmFilter.completed) {
      farms = farms
          .where(
            (f) =>
                f.status == FarmVisitStatus.visited ||
                f.status == FarmVisitStatus.harvested,
          )
          .toList();
    }

    if (filter.sortOrder == SortOrder.nameAsc) {
      farms.sort((a, b) => a.name.compareTo(b.name));
    }

    return farms;
  }

  @override
  Future<Farm?> getFarmById(String id) async {
    final response = await _client.dio.get(ApiEndpoints.farmById(id));
    return Farm.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Farm> onboardFarm(
    OnboardFarmRequest request,
    String executiveId,
    String executiveName, {
    List<String>? uploadedPhotoUrls,
  }) async {
    List<String>? photos = uploadedPhotoUrls;
    if (photos == null && request.photoPaths.isNotEmpty) {
      photos = await _uploads.uploadFiles(
        localPaths: request.photoPaths,
        context: 'farm_photo',
      );
    }

    final response = await _client.dio.post(
      ApiEndpoints.farms,
      data: request.toJson(uploadedPhotos: photos),
    );
    final data = response.data as Map<String, dynamic>;
    final farmId = data['id']?.toString();
    if (farmId != null) {
      return (await getFarmById(farmId))!;
    }
    return Farm.fromJson(data);
  }

  @override
  Future<List<FarmInvitation>> getFarmInvitations({
    double? lat,
    double? lng,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _client.dio.get(
      ApiEndpoints.farmInvitations,
      queryParameters: queryParams({
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'page': page,
        'page_size': pageSize,
      }),
    );
    return parseList(response.data, FarmInvitation.fromJson);
  }

  @override
  Future<void> acceptFarmInvitation(String farmId) async {
    await _client.dio.post(ApiEndpoints.acceptFarm(farmId));
  }

  @override
  Future<Farm> createFarmAsAdmin(
    OnboardFarmRequest request, {
    List<String> executiveIds = const [],
    List<String>? uploadedPhotoUrls,
  }) async {
    List<String>? photos = uploadedPhotoUrls;
    if (photos == null && request.photoPaths.isNotEmpty) {
      photos = await _uploads.uploadFiles(
        localPaths: request.photoPaths,
        context: 'farm_photo',
      );
    }

    final body = request.toJson(uploadedPhotos: photos);
    if (executiveIds.isNotEmpty) {
      body['executive_ids'] = executiveIds;
    }

    final response = await _client.dio.post(ApiEndpoints.farmsAdmin, data: body);
    final data = response.data as Map<String, dynamic>;
    final farmId = data['id']?.toString();
    if (farmId != null) {
      return (await getFarmById(farmId))!;
    }
    return Farm.fromJson(data);
  }

  @override
  Future<List<String>> assignFarmExecutives(
    String farmId, {
    required List<String> executiveIds,
    String mode = 'replace',
  }) async {
    final response = await _client.dio.patch(
      ApiEndpoints.assignFarm(farmId),
      data: {
        'executive_ids': executiveIds,
        'mode': mode,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final ids = data['assigned_executive_ids'] as List<dynamic>?;
    return ids?.map((e) => e.toString()).toList() ?? executiveIds;
  }
}
