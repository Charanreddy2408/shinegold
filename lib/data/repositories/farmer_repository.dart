import '../datasources/contracts.dart';
import '../models/executive.dart';

class FarmerRepository {
  FarmerRepository(this._dataSource);

  final FarmerDataSource _dataSource;

  Future<List<FarmerWithFarms>> list() => _dataSource.list();

  Future<FarmerWithFarms?> getById(String id) => _dataSource.getById(id);
}
