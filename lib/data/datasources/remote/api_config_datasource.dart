import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../models/app_remote_config.dart';

class ApiConfigDataSource {
  ApiConfigDataSource(this._client);

  final DioClient _client;

  Future<AppRemoteConfig> fetch() async {
    final response = await _client.dio.get(ApiEndpoints.appConfig);
    return AppRemoteConfig.fromJson(response.data as Map<String, dynamic>);
  }
}
