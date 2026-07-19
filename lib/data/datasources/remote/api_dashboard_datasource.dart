import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../models/enums.dart';
import '../../models/executive.dart';
import '../contracts.dart';

class ApiDashboardDataSource implements DashboardDataSource {
  ApiDashboardDataSource(this._client);

  final DioClient _client;

  @override
  Future<DashboardStats> getStats(DashboardFilter filter) async {
    final response = await _client.dio.get(ApiEndpoints.dashboardAdmin);
    final data = response.data as Map<String, dynamic>;
    return DashboardStats(
      totalFarms: data['total_farms'] as int? ?? 0,
      totalExecutives: data['total_executives'] as int? ?? 0,
      totalVisits: data['total_visits'] as int? ?? 0,
      farmersOnboarded: data['farmers_onboarded'] as int? ?? 0,
      totalAcres: (data['total_acres'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<ExecutiveDashboard> getExecutiveDashboard() async {
    final response = await _client.dio.get(ApiEndpoints.dashboardExecutive);
    return ExecutiveDashboard.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
