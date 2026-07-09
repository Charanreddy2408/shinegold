import '../datasources/contracts.dart';
import '../models/executive.dart';

class HarvestRepository {
  HarvestRepository(this._dataSource);

  final HarvestDataSource _dataSource;

  Future<List<Harvest>> getByMonth(DateTime month) =>
      _dataSource.getByMonth(month);

  Future<List<Harvest>> getAll() => _dataSource.getAll();
}
