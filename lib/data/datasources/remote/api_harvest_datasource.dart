import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../models/enums.dart';
import '../../models/executive.dart';
import '../contracts.dart';

class ApiHarvestDataSource implements HarvestDataSource {
  ApiHarvestDataSource(this._client);

  final DioClient _client;

  @override
  Future<List<Harvest>> getByMonth(DateTime month) async {
    final monthParam =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final response = await _client.dio.get(
      ApiEndpoints.harvestsCalendar,
      queryParameters: {'month': monthParam},
    );
    return _parseCalendar(response.data);
  }

  @override
  Future<List<Harvest>> getAll() async {
    final response = await _client.dio.get(ApiEndpoints.harvestsCalendar);
    return _parseCalendar(response.data);
  }

  List<Harvest> _parseCalendar(dynamic data) {
    if (data is! Map<String, dynamic>) return [];

    final groups = data['harvests'] as List<dynamic>? ?? [];
    final harvests = <Harvest>[];

    for (final group in groups) {
      if (group is! Map<String, dynamic>) continue;
      final dateStr = group['date'] as String?;
      if (dateStr == null) continue;
      final harvestDate = DateTime.parse(dateStr);
      final farms = group['farms'] as List<dynamic>? ?? [];

      for (final farm in farms) {
        if (farm is! Map<String, dynamic>) continue;
        harvests.add(
          Harvest(
            id: farm['id']?.toString() ?? '',
            farmId: farm['id']?.toString() ?? '',
            farmName: farm['name'] as String? ?? '',
            crop: farm['crop'] as String? ?? '',
            harvestDate: harvestDate,
            harvestType: farm['harvest_type'] as String? ?? '',
            status: HarvestStatus.upcoming,
          ),
        );
      }
    }

    return harvests;
  }
}
