import '../../../core/config/app_config.dart';
import '../../models/enums.dart';
import '../../models/executive.dart';
import '../../models/farm.dart';
import '../contracts.dart';
import 'mock_seed_data.dart';

class MockExecutiveDataSource implements ExecutiveDataSource {
  MockExecutiveDataSource() : _executives = List.of(MockSeedData.executives);

  final List<Executive> _executives;

  @override
  Future<List<Executive>> list() async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return List.unmodifiable(_executives);
  }

  @override
  Future<Executive> create(CreateExecutiveRequest request) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final exec = Executive(
      id: 'exec-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: request.employeeId,
      name: request.name,
      mobile: request.mobile,
    );
    _executives.add(exec);
    return exec;
  }

  @override
  Future<Executive> toggleBlock(String id) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final index = _executives.indexWhere((e) => e.id == id);
    if (index < 0) throw Exception('Executive not found');

    final exec = _executives[index];
    final updated = exec.copyWith(
      status: exec.status == ExecutiveStatus.active
          ? ExecutiveStatus.blocked
          : ExecutiveStatus.active,
    );
    _executives[index] = updated;
    return updated;
  }

  @override
  Future<List<Farm>> getVisitHistoryFarms(String executiveId) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return MockSeedData.farms
        .where((f) => f.assignedExecutiveId == executiveId)
        .toList();
  }

  int get totalExecutives => _executives.length;
}

class MockFarmerDataSource implements FarmerDataSource {
  MockFarmerDataSource(this._farmDataSource);

  final FarmDataSource _farmDataSource;

  @override
  Future<List<FarmerWithFarms>> list() async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final farms = await _farmDataSource.getFarms(const FarmFilter());
    final map = <String, FarmerWithFarms>{};
    for (final farm in farms) {
      final farmer = farm.farmer;
      if (map.containsKey(farmer.id)) {
        map[farmer.id] = FarmerWithFarms(
          farmer: farmer,
          farms: [...map[farmer.id]!.farms, farm],
        );
      } else {
        map[farmer.id] = FarmerWithFarms(farmer: farmer, farms: [farm]);
      }
    }
    return map.values.toList();
  }

  @override
  Future<FarmerWithFarms?> getById(String id) async {
    final all = await list();
    try {
      return all.firstWhere((f) => f.farmer.id == id);
    } catch (_) {
      return null;
    }
  }
}

class MockHarvestDataSource implements HarvestDataSource {
  @override
  Future<List<Harvest>> getByMonth(DateTime month) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return MockSeedData.harvests
        .where(
          (h) =>
              h.harvestDate.year == month.year &&
              h.harvestDate.month == month.month,
        )
        .toList();
  }

  @override
  Future<List<Harvest>> getAll() async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    return MockSeedData.harvests;
  }
}

class MockDashboardDataSource implements DashboardDataSource {
  MockDashboardDataSource({
    required this.farmCount,
    required this.executiveCount,
    required this.visitCount,
    required this.onboardedCount,
  });

  final int Function() farmCount;
  final int Function() executiveCount;
  final int Function() visitCount;
  final int Function() onboardedCount;

  @override
  Future<DashboardStats> getStats(DashboardFilter filter) async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);

    return DashboardStats(
      totalFarms: farmCount(),
      totalExecutives: executiveCount(),
      totalVisits: visitCount(),
      farmersOnboarded: onboardedCount(),
    );
  }

  @override
  Future<ExecutiveDashboard> getExecutiveDashboard() async {
    await Future<void>.delayed(AppConfig.mockNetworkDelay);
    final farms = MockSeedData.farms;
    return ExecutiveDashboard(
      greetingName: 'Rahul Sharma',
      dashboardDate: DateTime.now(),
      totalFarms: farms.length,
      visitedCount:
          farms.where((f) => f.status == FarmVisitStatus.visited).length,
      pendingCount: farms
          .where((f) =>
              f.status == FarmVisitStatus.pending ||
              f.status == FarmVisitStatus.ongoing)
          .length,
      harvestSoonCount: farms
          .where((f) => f.harvestDate
              .isBefore(DateTime.now().add(const Duration(days: 14))))
          .length,
      priorityFarms: farms
          .where((f) =>
              f.status == FarmVisitStatus.pending ||
              f.status == FarmVisitStatus.ongoing)
          .take(3)
          .toList(),
    );
  }
}
