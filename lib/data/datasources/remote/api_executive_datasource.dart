import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import '../../models/enums.dart';
import '../../models/executive.dart';
import '../../models/farm.dart';
import '../contracts.dart';

class ApiExecutiveDataSource implements ExecutiveDataSource {
  ApiExecutiveDataSource(this._client);

  final DioClient _client;

  @override
  Future<List<Executive>> list() async {
    final response = await _client.dio.get(
      ApiEndpoints.users,
      queryParameters: {'page_size': 100},
    );
    return parseList(response.data, Executive.fromJson);
  }

  @override
  Future<Executive> create(CreateExecutiveRequest request) async {
    final response = await _client.dio.post(
      ApiEndpoints.users,
      data: {
        'name': request.name,
        'mobile_number': request.mobile,
        'password': request.password,
        'address': request.address,
        'role': 'executive',
      },
    );
    final data = response.data as Map<String, dynamic>;
    return Executive(
      id: data['id']?.toString() ?? '',
      employeeId: data['employee_id'] as String? ?? '',
      name: data['name'] as String? ?? request.name,
      mobile: request.mobile,
    );
  }

  @override
  Future<Executive> toggleBlock(String id) async {
    final detail = await _client.dio.get(ApiEndpoints.userById(id));
    final isBlocked =
        (detail.data as Map<String, dynamic>)['is_blocked'] as bool? ?? false;

    await _client.dio.patch(
      ApiEndpoints.blockUser(id),
      data: {'is_blocked': !isBlocked},
    );

    final executives = await list();
    return executives.firstWhere(
      (e) => e.id == id,
      orElse: () => Executive(
        id: id,
        employeeId: '',
        name: '',
        mobile: '',
        status: !isBlocked ? ExecutiveStatus.blocked : ExecutiveStatus.active,
      ),
    );
  }

  @override
  Future<List<Farm>> getVisitHistoryFarms(String executiveId) async {
    final response = await _client.dio.get(ApiEndpoints.userById(executiveId));
    final data = response.data as Map<String, dynamic>;
    final farms = data['assigned_farms'] as List<dynamic>? ?? [];
    return farms
        .map((e) => Farm.fromSummaryJson(e as Map<String, dynamic>))
        .toList();
  }
}
