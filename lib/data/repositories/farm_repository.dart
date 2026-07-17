import '../datasources/contracts.dart';
import '../models/enums.dart';
import '../models/farm.dart';
import '../models/harvest_date_change.dart';
import '../models/visit_form.dart';

class FarmRepository {
  FarmRepository(this._dataSource);

  final FarmDataSource _dataSource;

  Future<List<Farm>> getFarms(
    FarmFilter filter, {
    double? userLat,
    double? userLng,
  }) =>
      _dataSource.getFarms(filter, userLat: userLat, userLng: userLng);

  Future<List<Farm>> getNearbyFarms({
    required double lat,
    required double lng,
    double radiusKm = 25,
    int pageSize = 100,
  }) async {
    final farms = await getFarms(
      FarmFilter(
        sortOrder: SortOrder.nearbyToFarthest,
        pageSize: pageSize,
      ),
      userLat: lat,
      userLng: lng,
    );
    return farms
        .where((f) => f.distanceKm != null && f.distanceKm! <= radiusKm)
        .toList();
  }

  Future<Farm?> getFarmById(String id) => _dataSource.getFarmById(id);

  Future<Farm> onboardFarm(
    OnboardFarmRequest request,
    String executiveId,
    String executiveName, {
    List<String>? uploadedPhotoUrls,
  }) =>
      _dataSource.onboardFarm(
        request,
        executiveId,
        executiveName,
        uploadedPhotoUrls: uploadedPhotoUrls,
      );

  Future<List<FarmInvitation>> getFarmInvitations({
    double? lat,
    double? lng,
    int page = 1,
    int pageSize = 50,
  }) =>
      _dataSource.getFarmInvitations(
        lat: lat,
        lng: lng,
        page: page,
        pageSize: pageSize,
      );

  Future<void> acceptFarmInvitation(String farmId) =>
      _dataSource.acceptFarmInvitation(farmId);

  Future<Farm> createFarmAsAdmin(
    OnboardFarmRequest request, {
    List<String> executiveIds = const [],
    List<String>? uploadedPhotoUrls,
  }) =>
      _dataSource.createFarmAsAdmin(
        request,
        executiveIds: executiveIds,
        uploadedPhotoUrls: uploadedPhotoUrls,
      );

  Future<List<String>> assignFarmExecutives(
    String farmId, {
    required List<String> executiveIds,
    String mode = 'replace',
  }) =>
      _dataSource.assignFarmExecutives(
        farmId,
        executiveIds: executiveIds,
        mode: mode,
      );

  Future<HarvestDateChange> updateHarvestDate(
    String farmId, {
    required DateTime harvestDate,
    String? reason,
  }) =>
      _dataSource.updateHarvestDate(
        farmId,
        harvestDate: harvestDate,
        reason: reason,
      );

  Future<List<HarvestDateChange>> getHarvestDateHistory(String farmId) =>
      _dataSource.getHarvestDateHistory(farmId);
}
