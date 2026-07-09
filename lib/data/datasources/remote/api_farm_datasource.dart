import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/upload_service.dart';
import '../../models/enums.dart';
import '../../models/farm.dart';
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
      final cutoff = DateTime.now().add(const Duration(days: 14));
      farms = farms.where((f) => f.harvestDate.isBefore(cutoff)).toList();
    } else if (filter.quickFilter == QuickFarmFilter.recentlyVisited) {
      final cutoff = DateTime.now().subtract(const Duration(days: 14));
      farms = farms
          .where(
            (f) =>
                f.lastVisited != null && f.lastVisited!.isAfter(cutoff),
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
    String executiveName,
  ) async {
    List<String>? uploadedPhotos;
    if (request.photoPaths.isNotEmpty) {
      uploadedPhotos = await _uploads.uploadFiles(
        localPaths: request.photoPaths,
        context: 'farm_photo',
      );
    }

    final response = await _client.dio.post(
      ApiEndpoints.farms,
      data: request.toJson(uploadedPhotos: uploadedPhotos),
    );
    final data = response.data as Map<String, dynamic>;
    final farmId = data['id']?.toString();
    if (farmId != null) {
      return (await getFarmById(farmId))!;
    }
    return Farm.fromJson(data);
  }
}
