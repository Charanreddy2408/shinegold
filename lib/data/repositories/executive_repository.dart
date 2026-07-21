import '../datasources/contracts.dart';
import '../models/executive.dart';
import '../models/farm.dart';

class ExecutiveRepository {
  ExecutiveRepository(this._dataSource);

  final ExecutiveDataSource _dataSource;

  Future<List<Executive>> list() => _dataSource.list();

  Future<Executive> getById(String id) => _dataSource.getById(id);

  Future<Executive> create(CreateExecutiveRequest request) =>
      _dataSource.create(request);

  Future<Executive> toggleBlock(String id) => _dataSource.toggleBlock(id);

  Future<List<Farm>> getVisitHistoryFarms(String executiveId) =>
      _dataSource.getVisitHistoryFarms(executiveId);
}
