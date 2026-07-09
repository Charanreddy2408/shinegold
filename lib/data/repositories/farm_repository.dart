import '../datasources/contracts.dart';
import '../models/farm.dart';

class FarmRepository {
  FarmRepository(this._dataSource);

  final FarmDataSource _dataSource;

  Future<List<Farm>> getFarms(
    FarmFilter filter, {
    double? userLat,
    double? userLng,
  }) =>
      _dataSource.getFarms(filter, userLat: userLat, userLng: userLng);

  Future<Farm?> getFarmById(String id) => _dataSource.getFarmById(id);

  Future<Farm> onboardFarm(
    OnboardFarmRequest request,
    String executiveId,
    String executiveName,
  ) =>
      _dataSource.onboardFarm(request, executiveId, executiveName);
}
