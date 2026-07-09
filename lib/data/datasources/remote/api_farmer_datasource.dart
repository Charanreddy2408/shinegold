import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../models/executive.dart';
import '../../models/farm.dart';
import '../contracts.dart';

class ApiFarmerDataSource implements FarmerDataSource {
  ApiFarmerDataSource(this._client);

  final DioClient _client;

  @override
  Future<List<FarmerWithFarms>> list() async {
    final response = await _client.dio.get(
      ApiEndpoints.farmers,
      queryParameters: {'page_size': 100},
    );
    return parseList(response.data, _fromListItem);
  }

  @override
  Future<FarmerWithFarms?> getById(String id) async {
    final response = await _client.dio.get(ApiEndpoints.farmerById(id));
    return _fromDetail(response.data as Map<String, dynamic>);
  }

  FarmerWithFarms _fromListItem(Map<String, dynamic> json) => FarmerWithFarms(
        farmer: Farmer.fromJson(json),
        farms: const [],
      );

  FarmerWithFarms _fromDetail(Map<String, dynamic> json) {
    final farmsRaw = json['farms'] as List<dynamic>? ?? [];
    return FarmerWithFarms(
      farmer: Farmer.fromJson(json),
      farms: farmsRaw
          .map((e) => Farm.fromSummaryJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
