import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../models/enums.dart';
import '../../models/interaction.dart';
import '../contracts.dart';

class ApiInteractionDataSource implements InteractionDataSource {
  ApiInteractionDataSource(this._client);

  final DioClient _client;

  @override
  Future<List<FarmerInteraction>> listMine({
    String? search,
    InteractionStatus? status,
  }) async {
    final response = await _client.dio.get(
      ApiEndpoints.myInteractions,
      queryParameters: queryParams({
        'search': search,
        'status': status == null ? null : interactionStatusToApi(status),
        'page_size': 100,
      }),
    );
    return parseList(response.data, FarmerInteraction.fromJson);
  }

  @override
  Future<FarmerInteraction> create(CreateInteractionRequest request) async {
    final response = await _client.dio.post(
      ApiEndpoints.interactions,
      data: request.toJson(),
    );
    return FarmerInteraction.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<FarmerInteraction> update(
    String id,
    UpdateInteractionRequest request,
  ) async {
    final response = await _client.dio.patch(
      ApiEndpoints.interactionById(id),
      data: request.toJson(),
    );
    return FarmerInteraction.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<FarmerInteraction?> getById(String id) async {
    final response = await _client.dio.get(ApiEndpoints.interactionById(id));
    return FarmerInteraction.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
