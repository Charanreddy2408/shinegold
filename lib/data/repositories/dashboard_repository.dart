import '../datasources/contracts.dart';
import '../models/enums.dart';
import '../models/executive.dart';

class DashboardRepository {
  DashboardRepository(this._dataSource);

  final DashboardDataSource _dataSource;

  Future<DashboardStats> getStats(DashboardFilter filter) =>
      _dataSource.getStats(filter);

  Future<ExecutiveDashboard> getExecutiveDashboard() =>
      _dataSource.getExecutiveDashboard();
}
